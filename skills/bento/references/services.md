# Services

Bento's service catalog provides paid third-party APIs without vendor keys.

Discover with `bento service list --q audio --limit 1 --json`,
then inspect `bento service get --service-id elevenlabs --json` and its linked
vendor documentation. Keep the complete page and follow `nextCursor` with the
same search/category filters; the cursor is opaque. Calls use
the method-specific subcommands under `bento service proxy --help` with
`--service-id` and `--path`; `--workspace <slug>` selects a workspace other than
the default.

Read installed help for input representations. JSON bodies accept a file or
stdin; raw text and binary files remain separate body sources. Queries accept
ordered name/value pairs to retain repeated keys, and repeated multipart fields
stay repeated. `--out` writes exact response bytes, including HTTP error bytes.
Keep the exit status and returned file receipt: file delivery
does not make a vendor refusal successful. Failures retain HTTP details on stderr.
Inspect status, headers, the complete
JSON body and any returned vendor job handle; finish asynchronous vendor work
through its documented allowlisted poll operation. Never infer success from a
fixture response or a successful transport alone.

An unlisted route returns 404. Vendor errors pass through; Bento blocks identify
payment or workspace problems. Shared resources may be usable by everyone but
changes are limited to the workspace that created them and temporary resources
expire according to the service's pool rules.

## Operations

A resource service (a sandbox, for example) returns `{data,bento}` for JSON,
while bytes and NDJSON stay native. Its ids are private to the owning
workspace, and `funded`/`included` billing describes lease authorization, not
free compute. Observe an uncertain operation by its id rather than replaying
the request:

```bash
bento service operation get --service-id "$SERVICE_ID" --operation-id "$OPERATION_ID" --json
```

Hosted MCP exposes the same observation as `service_operation_get` with
`{workspaceSlug, serviceId, operationId}`. Calls retain complete JSON, including
a nonzero workload `exitCode` under HTTP 200, or a byte resource for native
output.

Bento's own capability references, listed in the skill's entrypoint, teach
specific services in depth: voice, media, scraping, social data, sales
research, integrations and sandboxes.
