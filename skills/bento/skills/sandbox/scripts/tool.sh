#!/usr/bin/env bash
# Run one of Bento's Pi tools in a funded sandbox.
#
#   tool.sh <read|write|edit|bash> --sandbox <id> '<params-json>' [--json]
#   tool.sh --follow <processId> --sandbox <id> [--json]
#
# The normal call is buffered. --follow attaches to the native command stream
# for a bash call that reached the 600 second ceiling.
set -euo pipefail

usage() {
  echo 'usage: tool.sh <read|write|edit|bash> --sandbox <id> <params-json> [--json]' >&2
  echo '       tool.sh --follow <processId> --sandbox <id> [--json]' >&2
  exit 64
}

fail() {
  echo "tool.sh: $*" >&2
  exit 1
}

json_output=
follow=
sandbox_id=
tool=
params=

while [ $# -gt 0 ]; do
  case "$1" in
    --json) json_output=1; shift ;;
    --sandbox)
      sandbox_id=${2:-}
      [ -n "$sandbox_id" ] || usage
      shift 2
      ;;
    --follow)
      [ -z "$follow" ] || usage
      follow=${2:-}
      [ -n "$follow" ] || usage
      shift 2
      ;;
    read|write|edit|bash)
      [ -z "$tool" ] || usage
      tool=$1
      shift
      ;;
    -h|--help) usage ;;
    *)
      [ -z "$params" ] || usage
      params=$1
      shift
      ;;
  esac
done

[ -n "$sandbox_id" ] || usage
if [ -n "$follow" ]; then
  [ -z "$tool" ] && [ -z "$params" ] || usage
else
  [ -n "$tool" ] && [ -n "$params" ] || usage
  jq -e 'type == "object"' >/dev/null <<<"$params" || fail 'params must be a JSON object'
fi

service=$(bento service list --q sandbox --limit 1 --json | jq -er '.items[0].id') ||
  fail 'could not discover a sandbox service'

scratch=$(mktemp -d "${TMPDIR:-/tmp}/bento-tool.XXXXXX")
trap 'rm -rf "$scratch"' EXIT

# The CLI's --json error is structured as {error,message,apiError:{message}}.
# Pull the provider's Pi message out of that wrapper; other failures retain the
# CLI's own diagnostic.
report_cli_error() {
  local error_file=$1
  local message
  message=$(jq -er '.apiError.message // .message // empty' "$error_file" 2>/dev/null || true)
  if [ -n "$message" ]; then
    printf '%s\n' "$message" >&2
  elif [ -s "$error_file" ]; then
    cat "$error_file" >&2
  else
    echo 'sandbox service request failed' >&2
  fi
}

run_cli() {
  local output=$1 error=$2
  shift 2
  set +e
  bento "$@" >"$output" 2>"$error"
  local status=$?
  set -e
  return "$status"
}

# Like run_cli, but returns 124 once SECONDS reaches the given deadline.
run_cli_until() {
  local deadline=$1 output=$2 error=$3
  shift 3
  (( SECONDS < deadline )) || return 124
  set +e
  bento "$@" >"$output" 2>"$error" &
  local child=$!
  while kill -0 "$child" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      kill "$child" 2>/dev/null || true
      wait "$child" 2>/dev/null || true
      set -e
      return 124
    fi
    sleep 1
  done
  wait "$child"
  local status=$?
  set -e
  return "$status"
}

print_content() {
  local content=$1
  jq -c '.[]?' <<<"$content" | while IFS= read -r part; do
    case "$(jq -r '.type // empty' <<<"$part")" in
      text) jq -r '.text // empty' <<<"$part" ;;
      image) echo '[image content omitted]' ;;
    esac
  done
}

emit_result() {
  local frame=$1
  if [ -n "$json_output" ]; then
    printf '%s\n' "$frame"
  else
    print_content "$(jq -c '.data.content // .content // []' <<<"$frame")"
  fi
}

report_running() {
  printf '%s; processId: %s\n' "$1" "$2" >&2
  printf 'Follow with: tool.sh --follow %s --sandbox %s%s\n' "$2" "$sandbox_id" \
    "${json_output:+ --json}" >&2
}

normal_call() {
  local body=$1 output=$2 error=$3
  if ! run_cli "$output" "$error" service proxy post \
      --service-id "$service" --path "/sandboxes/$sandbox_id/tools/$tool" \
      --body-file "$body" --headers '{"content-type":"application/json"}' --json; then
    report_cli_error "$error"
    return 1
  fi
  local response
  response=$(cat "$output")
  if jq -e '.data.running == true' <<<"$response" >/dev/null 2>&1; then
    local process_id
    process_id=$(jq -r '.data.processId // empty' <<<"$response")
    report_running 'Sandbox tool reached the 600 second ceiling' "$process_id"
    return 124
  fi
  if ! jq -e '.data != null' <<<"$response" >/dev/null 2>&1; then
    report_cli_error "$error"
    return 1
  fi
  emit_result "$response"
}

# The runner's last result or error frame in a file of runner output. A line
# that isn't JSON (such as a status tail cut mid-line) is skipped.
last_terminal() {
  jq -cR 'fromjson? | select(.type == "result" or .type == "error")' "$1" | tail -n 1
}

follow_call() {
  local output=$1 error=$2 query='{}' runner="$scratch/runner" deadline=$((SECONDS + 600))
  local reconnect status terminal
  : >"$runner"
  while :; do
    run_cli_until "$deadline" "$output" "$error" service proxy get \
      --service-id "$service" --path "/sandboxes/$sandbox_id/commands/$follow/stream" \
      --query "$query" --json && status=0 || status=$?
    if [ "$status" -eq 124 ]; then
      report_running 'Follow reached its 600 second ceiling' "$follow"
      return 124
    elif [ "$status" -ne 0 ]; then
      report_cli_error "$error"
      return 1
    fi
    # Native stdout frames carry the runner's own frames as text.
    jq -rjR 'fromjson? | select(.type == "stdout") | .data // empty' "$output" >>"$runner"
    # The proxy's query values are strings.
    reconnect=$(jq -cR 'fromjson? | select(.type == "reconnect")
      | {stdoutOffset: (.stdoutOffset // 0 | tostring),
         stderrOffset: (.stderrOffset // 0 | tostring)}' "$output" |
      tail -n 1)
    [ -n "$reconnect" ] || break
    query=$reconnect
  done

  terminal=$(last_terminal "$runner")
  # A stream can close without the runner's final line. Status keeps the end
  # of the runner's output, which ends with that frame, and says whether the
  # command still runs.
  if [ -z "$terminal" ]; then
    run_cli_until "$deadline" "$output" "$error" service proxy get \
      --service-id "$service" --path "/sandboxes/$sandbox_id/commands/$follow" --json &&
      status=0 || status=$?
    if [ "$status" -eq 124 ]; then
      report_running 'Follow reached its 600 second ceiling' "$follow"
      return 124
    elif [ "$status" -eq 0 ] && jq -e '.data.running == true' "$output" >/dev/null; then
      report_running 'Sandbox command is still running' "$follow"
      return 124
    fi
    if [ "$status" -eq 0 ]; then
      jq -r '.data.stdout // empty' "$output" >"$runner"
      terminal=$(last_terminal "$runner")
    fi
  fi
  if [ -z "$terminal" ]; then
    echo 'sandbox tool stream ended without a terminal frame' >&2
    return 1
  fi
  if [ "$(jq -r '.type' <<<"$terminal")" = error ]; then
    jq -r '.message // "sandbox tool failed"' <<<"$terminal" >&2
    return 1
  fi
  emit_result "$(jq -c '{data: del(.type)}' <<<"$terminal")"
}

if [ -n "$follow" ]; then
  follow_call "$scratch/output" "$scratch/error"
else
  printf '%s\n' "$params" >"$scratch/params.json"
  normal_call "$scratch/params.json" "$scratch/output" "$scratch/error"
fi
