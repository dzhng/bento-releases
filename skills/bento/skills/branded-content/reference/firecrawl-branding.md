# Firecrawl Branding Format Reference

## Endpoint

`POST /v2/scrape` on the `firecrawl` service with `formats: ["branding"]`,
through the Bento CLI's service proxy (it supplies the Firecrawl credential):

```bash
bento service proxy post --service-id firecrawl --path /v2/scrape --body-file - <<'JSON'
{"url": "<url>", "formats": ["branding"]}
JSON
```

## Response Schema

The response wraps this object as `{success, data: {branding, metadata, ...}}`.

```json
{
  "branding": {
    "colorScheme": "light|dark",
    "colors": {
      "primary": "#HEX",
      "accent": "#HEX",
      "background": "#HEX",
      "textPrimary": "#HEX",
      "link": "#HEX"
    },
    "fonts": [{"family": "string", "role": "heading|body|unknown"}],
    "typography": {
      "fontFamilies": {"primary": "string", "heading": "string"},
      "fontStacks": {"heading": [...], "body": [...], "paragraph": [...]},
      "fontSizes": {"h1": "px", "h2": "px", "body": "px"}
    },
    "spacing": {"baseUnit": number, "borderRadius": "px"},
    "components": {
      "buttonPrimary": {"background": "#HEX", "textColor": "#HEX", "borderRadius": "px"},
      "buttonSecondary": {"background": "string", "textColor": "#HEX"}
    },
    "images": {
      "logo": "URL",
      "favicon": "URL",
      "ogImage": "URL",
      "logoAlt": "string"
    },
    "personality": {
      "tone": "modern|professional|playful|etc",
      "energy": "low|medium|high",
      "targetAudience": "description"
    },
    "designSystem": {"framework": "tailwind|bootstrap|etc", "componentLibrary": "string"},
    "confidence": {"buttons": 0-1, "colors": 0-1, "overall": 0-1}
  }
}
```

## Cost

1 credit per scrape with branding format.

## Notes

- Logo detection uses an LLM internally — confidence scores indicate reliability
- Combine with a `json` format prompt for tagline/voice extraction (5 credits)
- For deeper analysis, use the `agent` endpoint (2-5 min, variable credits)
