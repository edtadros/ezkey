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
| GET | `/` | `getCatalog` |
| GET | `/agent-brief` | `getAgentBrief` |
| GET | `/disclaimer` | `getDisclaimer` |
| GET | `/install` | `getInstall` |
| GET | `/auth` | `getAuth` |
| GET | `/cli` | `getCli` |
| GET | `/version` | `getVersion` |

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

10 requests per 10 seconds per client IP on REST, MCP, and A2A, enforced by Cloudflare. Responses include `RateLimit-Policy`. HTTP 429 includes `Retry-After`.

OpenAPI: https://ezkey.app/openapi.json

## MCP

Streamable HTTP at https://ezkey.app/mcp (alias https://ezkey.app/api/v1/mcp). Read-only tools: `get_overview`, `get_build_instructions`, `get_agent_brief`, `get_disclaimer`, `get_page`. No authentication.

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

There is no ezkey CLI package. Agents install ezkey by following the [build-ezkey skill](https://ezkey.app/.well-known/agent-skills/build-ezkey/SKILL.md): disclaimer, clone of the newest release tag, code review, then `./scripts/install.sh` after the human says go. The install copies `/Applications/ezkey.app` and turns on Open at Login. See [CLI](https://ezkey.app/cli.md).

```
curl -sS https://ezkey.app/api/v1/agent-brief
curl -sS https://ezkey.app/api/v1/overview
```

## Onboarding

No API keys. Production is the sandbox. Authentication is none. See [auth.md](https://ezkey.app/auth.md) and `GET /api/v1/auth`.

## Versioning and deprecation

See [versioning](https://ezkey.app/versioning.md). Current major version is 1. No route is deprecated.

The Keychain itself is reached with Apple's `security` tool after you build ezkey locally, not through this website.
