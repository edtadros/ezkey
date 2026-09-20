# ezkey.app OpenAPI

Machine-readable OpenAPI 3.1 description: [openapi.json](https://ezkey.app/openapi.json)

Base URL: `https://ezkey.app/api/v1`

- `GET /health` — liveness (`getHealth`)
- `GET /overview` — product summary (`getOverview`)
- `GET /build` — clone and build commands (`getBuildInstructions`)
- `GET /pages/{page}` — Markdown for a named page (`getPage`)

Errors use RFC 9457 `application/problem+json`. Rate limit: 60 requests per minute per IP. No authentication. See [auth.md](https://ezkey.app/auth.md) and [developers](https://ezkey.app/developers.md).
