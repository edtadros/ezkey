---
title: Developers — ezkey
description: Public site API, MCP, A2A, and discovery metadata for ezkey. The macOS app has no network API.
---

# Developers

ezkey is a local macOS menu bar extra. The native app has no network API. This page describes the **public website** interfaces agents can use to read product docs.

## When to use these interfaces

Use them to explain ezkey, fetch build steps, or retrieve a Markdown page. Do not use them to store, retrieve, or sync Keychain secrets. Secrets never leave the Mac.

## REST API

Base URL: `https://ezkey.app/api/v1`

| Method | Path | operationId |
| --- | --- | --- |
| GET | `/health` | `getHealth` |
| GET | `/overview` | `getOverview` |
| GET | `/build` | `getBuildInstructions` |
| GET | `/pages/{page}` | `getPage` |

Example:

```http
GET /api/v1/overview HTTP/1.1
Host: ezkey.app
Accept: application/json
```

Errors use RFC 9457 `application/problem+json` with `code`, `detail`, and `resolution`. Unknown `/api/v1/*` paths return HTTP 404 in that shape.

### Versioning

The current major version is `1`, in the URL path and the `API-Version` response header. Breaking changes require a new major path (`/api/v2`). Deprecated routes will carry RFC 9745 `Deprecation` and `Sunset` headers with at least 90 days of notice. There is no scheduled deprecation today.

### Rate limits

60 requests per minute per client IP on REST, MCP, and A2A. Responses include `RateLimit` and `RateLimit-Policy`. HTTP 429 includes `Retry-After`.

OpenAPI: https://ezkey.app/openapi.json

## MCP

Streamable HTTP at https://ezkey.app/mcp (alias https://ezkey.app/api/v1/mcp). Read-only tools: `get_overview`, `get_build_instructions`, `get_page`. No authentication.

Server card: https://ezkey.app/.well-known/mcp/server-card.json

## A2A

JSON-RPC at https://ezkey.app/a2a. Agent card: https://ezkey.app/.well-known/agent-card.json

`message/send` answers from the public site text. Tasks are not persisted.

## Authentication

None. See [auth.md](https://ezkey.app/auth.md). Protected-resource metadata: https://ezkey.app/.well-known/oauth-protected-resource

## Discovery

- https://ezkey.app/llms.txt
- https://ezkey.app/.well-known/api-catalog
- https://ezkey.app/.well-known/ard.json
- https://ezkey.app/.well-known/agent-skills/index.json

## Command-line

There is no npm/Homebrew CLI for the macOS app. Agents can call the public API with curl:

```
curl -sS https://ezkey.app/api/v1/overview
curl -sS https://ezkey.app/api/v1/pages/security
```

The Keychain itself is reached with Apple's `security` tool after you build ezkey locally, not through this website.
