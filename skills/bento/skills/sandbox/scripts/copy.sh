#!/usr/bin/env bash
# Copy a file or folder between this machine and a funded sandbox.
#
#   bash copy.sh <from> <to> [--sandbox <id>]
#
# Exactly one side is sandbox:/absolute/path. A folder's contents land in <to>,
# which is created when missing; existing files are overwritten and nothing is
# deleted. Without --sandbox, copying in creates a sandbox (default type, one
# hour); the same command run again reuses it. Copying out needs --sandbox, and
# after the sandbox's lease ends it reads the sandbox's last snapshot instead.
# Everything here may cross: .env files, keys and .git included.
# Prints one JSON line. To change the behaviour, copy this script and edit it.
set -euo pipefail

usage() {
  echo 'usage: copy.sh <from> <to> [--sandbox <id>]  (one side is sandbox:/absolute/path)' >&2
  exit 64
}
fail() {
  echo "copy.sh: $*" >&2
  exit 1
}

paths=()
id=
while [ $# -gt 0 ]; do
  case "$1" in
    --sandbox) id=${2:-}; [ -n "$id" ] || usage; shift 2 ;;
    -h | --help) usage ;;
    *) paths+=("$1"); shift ;;
  esac
done
[ ${#paths[@]} -eq 2 ] || usage
from=${paths[0]}
to=${paths[1]}
case "$from" in sandbox:*) from_sandbox=1 ;; *) from_sandbox= ;; esac
case "$to" in sandbox:*) to_sandbox=1 ;; *) to_sandbox= ;; esac
if [ -n "$to_sandbox" ] && [ -z "$from_sandbox" ]; then
  direction=in
  remote=${to#sandbox:}
  [ -e "$from" ] || fail "$from does not exist"
  from=$(cd "$(dirname "$from")" && pwd)/$(basename "$from")
elif [ -n "$from_sandbox" ] && [ -z "$to_sandbox" ]; then
  direction=out
  remote=${from#sandbox:}
  [ -n "$id" ] || fail 'copying out of a sandbox needs --sandbox <id>'
else
  usage
fi
case "$remote" in /*) ;; *) fail "sandbox paths are absolute: $remote" ;; esac

state=${SANDBOX_COPY_HOME:-$HOME/.sandbox-copy}
mkdir -p "$state"
started=$(date +%s)
service=$(bento service list --q sandbox --limit 1 --json | jq -er '.items[0].id')
sandbox() { bento service proxy "$@" --service-id "$service" --json; }
digest() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi | cut -d' ' -f1; }

created=false
if [ -z "$id" ]; then
  # One persisted identity per (source, destination): a rerun replays the same
  # create instead of paying for a second sandbox.
  job="$state/creates/$(printf '%s\n%s\n' "$from" "$to" | digest)"
  mkdir -p "$job"
  [ -f "$job/key" ] || { uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid; } > "$job/key"
  printf '{"type":"default","ttlSeconds":3600}\n' > "$job/body.json"
  sandbox post --path /sandboxes --body-file "$job/body.json" \
    --headers "$(jq -cn --arg key "$(cat "$job/key")" '{"Idempotency-Key":$key}')" > "$job/create.json"
  id=$(jq -r '.data.sandbox.id // .bento.resourceIds[0] // empty' "$job/create.json")
  operation=$(jq -r '.bento.operationId // empty' "$job/create.json")
  for _ in $(seq 60); do
    [ -z "$id" ] || break
    bento service operation get --service-id "$service" --operation-id "$operation" --json > "$job/operation.json"
    jq -e '.data.state == "repair_required" or .data.state == "failed"' "$job/operation.json" >/dev/null &&
      fail "sandbox creation failed; see $job/operation.json"
    id=$(jq -r '.data.resourceIds[0] // empty' "$job/operation.json")
    [ -n "$id" ] || sleep 2
  done
  [ -n "$id" ] || fail "sandbox creation is still pending; rerun the same command to resume it"
  created=true
  ready=
  for _ in $(seq 120); do
    sandbox get --path "/sandboxes/$id" > "$job/sandbox.json"
    jq -e '.data.sandbox | .state == "error" or .state == "cancelled" or .setupStatus == "failed"' \
      "$job/sandbox.json" >/dev/null && fail "sandbox $id failed to start; see $job/sandbox.json"
    jq -e '.data.sandbox | (.state | IN("ready", "idle", "running")) and (.setupStatus | IN(null, "done"))' \
      "$job/sandbox.json" >/dev/null && { ready=1; break; }
    sleep 2
  done
  [ -n "$ready" ] || fail "sandbox $id is not ready after four minutes; see $job/sandbox.json"
fi

receipt() {
  jq -cn --arg id "$id" --argjson created "$created" --arg from "$1" --arg to "$2" \
    --arg transport "$3" --argjson seconds "$(($(date +%s) - started))" \
    '{sandboxId: $id, created: $created, from: $from, to: $to, transport: $transport, seconds: $seconds}'
}

# The snapshot keeps /home/user only, so only paths under it can be recovered.
from_snapshot() {
  case "$remote" in
    /home/user/?*) relative=${remote#/home/user/} relative=${relative%/} ;;
    *) fail "the lease has ended and the snapshot keeps only folders under /home/user; $remote is not recoverable" ;;
  esac
  snapshot=$(sandbox get --path "/sandboxes/$id/snapshots/latest" | jq -er '.data.snapshot.id')
  scratch=$(mktemp -d "$state/snapshot.XXXXXX")
  trap 'rm -rf "$scratch"' EXIT
  sandbox get --path "/snapshots/$snapshot/files" --query "$(jq -cn --arg path "$relative" '{path: $path}')" \
    --out "$scratch/download" > "$scratch/http.json"
  if [ "$(jq -r '.headers["x-snapshot-entry-kind"]' "$scratch/http.json")" = dir ]; then
    # Folder entries carry the full requested path.
    mkdir -p "$scratch/tree" "$to"
    tar -xf "$scratch/download" -C "$scratch/tree"
    cp -a "$scratch/tree/$relative/." "$to/"
  else
    mkdir -p "$(dirname "$to")"
    mv "$scratch/download" "$to"
  fi
  receipt "sandbox:$remote" "$to" snapshot
}

# SSH is authorized per sandbox and its host key pinned on every run, because a
# resumed sandbox has a new host key.
keys="$state/$id"
mkdir -p "$keys"
[ -f "$keys/key" ] || ssh-keygen -q -t ed25519 -N '' -f "$keys/key"
jq -cn --arg key "$(cat "$keys/key.pub")" '{key: $key}' > "$keys/ssh-key.json"
if ! sandbox post --path "/sandboxes/$id/sshkey" --body-file "$keys/ssh-key.json" > "$keys/ssh.json" 2> "$keys/ssh.err"; then
  if grep -q lease_expired_or_stopping "$keys/ssh.err" && [ "$direction" = out ]; then
    from_snapshot
    exit 0
  fi
  fail "sandbox $id refused SSH access: $(cat "$keys/ssh.err")"
fi
endpoint=$(jq -r '.data.sshEndpoint // empty' "$keys/ssh.json")
if [ -n "$endpoint" ]; then host=${endpoint%:*} port=${endpoint##*:}; else host=$(jq -er '.data.machineIp' "$keys/ssh.json") port=22; fi
user=$(jq -er '.data.sshUser' "$keys/ssh.json")
printf 'sandbox %s\n' "$(jq -er '.data.hostKey' "$keys/ssh.json")" > "$keys/known_hosts"
ssh_command="ssh -i $keys/key -p $port -o HostName=$host -o HostKeyAlias=sandbox -o UserKnownHostsFile=$keys/known_hosts -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=4"

if [ "$direction" = in ]; then
  if [ -d "$from" ]; then source="$from/" parent=$remote; else source=$from parent=$(dirname "$remote"); fi
  rsync -a --partial -e "$ssh_command" --rsync-path="mkdir -p '$parent' && rsync" \
    "$source" "$user@sandbox:$remote"
  receipt "$from" "sandbox:$remote" rsync
else
  if $ssh_command "$user@sandbox" "test -d '$remote'"; then
    mkdir -p "$to"
    rsync -a --partial -e "$ssh_command" "$user@sandbox:$remote/" "$to/"
  else
    mkdir -p "$(dirname "$to")"
    rsync -a --partial -e "$ssh_command" "$user@sandbox:$remote" "$to"
  fi
  receipt "sandbox:$remote" "$to" rsync
fi
