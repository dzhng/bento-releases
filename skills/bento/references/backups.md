# Google Drive backup through the CLI

Follow the [Google Drive backup workflow](https://docs.bento.ing/workspaces.md#back-up-to-google-drive)
for connection consent, folder selection, status interpretation, and recovery. Select the API
origin as installed `bento --help` describes.
That workflow owns the setup semantics; the installed CLI help owns current flags.

Use the person's existing login and the intended workspace. Read
`bento cloud-backup get --help` and `bento integration connect --help` before acting.
If help omits these operations, follow the setup reference's upgrade recovery
before retrying.

```bash
bento cloud-backup get --workspace acme --cloud-backup-id google-drive --json
```

If no active Google connection is present, inspect
`bento integration connection list --workspace acme --json` and follow its continuation cursor.
Keep an in-progress consent attempt; calling connect again invalidates its existing link.
If the workflow requires a new connection, save its connection JSON example as
`google-drive-connection.json`, with `redirectTo` naming the selected workspace, then run:

```bash
bento integration connect --workspace acme \
  --body-file google-drive-connection.json --json
```

Give `authorizeUrl` to the person and read backup state again after they approve. Do not
enable backup while connection consent is pending. If a connection is already active, reuse it.

For a new backup, save the workflow's target JSON example as `google-drive-backup.json`,
adjusting the folders to the user's choice. To reconnect or disable an existing backup, keep
the saved `sourcePath` and use `remote: { "kind": "existing", "folderId": "<target.remoteRootId>" }`
as the workflow describes; the default-folder example may change its destination.
Browse destinations when needed, then save and verify:

```bash
bento cloud-backup folder list --workspace acme --cloud-backup-id google-drive --json
bento cloud-backup update --workspace acme --cloud-backup-id google-drive \
  --body-file google-drive-backup.json --json
bento cloud-backup get --workspace acme --cloud-backup-id google-drive --json
```

For another folder page, pass `--parent <folder-id> --cursor <nextCursor>`
with the same parent, provider, and workspace; omit `parent` if the listing used the root default.
When entering another folder, omit the old cursor. Inspect failures with
`bento cloud-backup failure list --workspace acme --cloud-backup-id google-drive --json`;
continue with `--cursor <nextCursor>`. Keep exit status and returned receipts; failures retain HTTP details on stderr.
Use the canonical workflow's verification criteria before reporting success.
