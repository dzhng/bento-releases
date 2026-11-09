# Screenshot Format Options

Firecrawl's scrape format `screenshot` supports the following options when sent as an object inside the `formats` array. Pass `"screenshot"` as a bare string for default settings.

## Options

- **fullPage** (boolean): capture the full scrollable page. When false, captures the viewport only.
- **quality** (number): image quality (0–100). Higher is larger file size.
- **viewport** (object): set the viewport size, e.g. `{ "width": 1200, "height": 630 }`.

## Example (API object format)

```json
{
  "type": "screenshot",
  "fullPage": true,
  "quality": 80,
  "viewport": { "width": 1200, "height": 630 }
}
```

## Example request

```bash
bento service proxy post --service-id firecrawl --path /v2/scrape --body-file - \
  > .firecrawl/screenshot.json <<'JSON'
{
  "url": "https://example.com",
  "formats": [{
    "type": "screenshot",
    "fullPage": true,
    "quality": 80,
    "viewport": {"width": 1200, "height": 630}
  }]
}
JSON
```

Source: Firecrawl scrape format docs.
