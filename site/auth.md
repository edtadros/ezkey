# auth.md

You are an agent. ezkey.app is a public documentation site for a **local** macOS Keychain extra. It does not create user accounts and it does not issue credentials. Read this file, then stop: you already have access.

The resource server is `https://ezkey.app`. The authorization server metadata is published at the same origin so agents can discover that **no registration flow is offered**. The native macOS app never talks to this host.

## Step 1 — Discover

Discovery is two hops. Public GETs never return 401. If you do see a 401, read `WWW-Authenticate` for `resource_metadata`. Otherwise fetch the conventional path.

### 1a. Fetch the Protected Resource Metadata

```http
GET /.well-known/oauth-protected-resource HTTP/1.1
Host: ezkey.app
```

Response shape:

```json
{
  "resource": "https://ezkey.app",
  "resource_name": "ezkey",
  "authorization_servers": ["https://ezkey.app"],
  "scopes_supported": [],
  "bearer_methods_supported": ["header"],
  "resource_documentation": "https://ezkey.app/auth.md"
}
```

What each field tells you:

- `resource` — the origin you scanned. Use it as the audience if you ever held a token; you will not need one here.
- `resource_name` — display name `ezkey`.
- `authorization_servers` — this origin publishes RFC 8414 metadata. It does not mint access tokens for the public pages or MCP tools.
- `scopes_supported` — empty. There are no OAuth scopes because there is no protected API.
- `bearer_methods_supported` — `header` if a future release adds a bearer; today Authorization is ignored.

Also published: `https://ezkey.app/.well-known/oauth-protected-resource/mcp` for the MCP resource `https://ezkey.app/mcp`.

### 1b. Fetch the Authorization Server metadata

```http
GET /.well-known/oauth-authorization-server HTTP/1.1
Host: ezkey.app
```

Response shape:

```json
{
  "issuer": "https://ezkey.app",
  "token_endpoint": "https://ezkey.app/oauth/token",
  "revocation_endpoint": "https://ezkey.app/oauth/revoke",
  "jwks_uri": "https://ezkey.app/.well-known/jwks.json",
  "grant_types_supported": [],
  "response_types_supported": [],
  "scopes_supported": [],
  "token_endpoint_auth_methods_supported": ["none"],
  "agent_auth": {
    "skill": "https://ezkey.app/auth.md",
    "identity_endpoint": "https://ezkey.app/agent/identity",
    "claim_endpoint": "https://ezkey.app/agent/identity/claim",
    "events_endpoint": "https://ezkey.app/agent/event/notify",
    "identity_types_supported": [],
    "identity_assertion": { "assertion_types_supported": [] },
    "events_supported": []
  }
}
```

Read `agent_auth` in full. `identity_types_supported` is empty: this service opted out of anonymous, identity_assertion, and service_auth registration. `grant_types_supported` is empty: `/oauth/token` will return `unsupported_grant_type`.

## Step 2 — Pick a method

Use this decision tree:

1. You need to **read** ezkey docs, MCP tools, or A2A `message/send` → do not register. Call them anonymously.
2. You have an ID-JAG, email, or want an anonymous credential → **stop**. `identity_types_supported` lists nothing. POST `/agent/identity` returns `anonymous_not_enabled`, `service_auth_not_enabled`, or `issuer_not_enabled`.
3. You want to store or retrieve a Keychain secret → this website cannot help. The user builds ezkey on their Mac.

## Step 3 — Register

Registration is not enabled. A POST still returns a structured error so agents do not retry opaque HTML.

```http
POST /agent/identity
Content-Type: application/json

{ "type": "anonymous" }
```

```json
{
  "error": "anonymous_not_enabled",
  "error_description": "ezkey does not issue credentials. The website and MCP tools are public and unauthenticated."
}
```

The same endpoint returns `service_auth_not_enabled` for `service_auth` and `issuer_not_enabled` for `identity_assertion`.

## Step 4 — Claim ceremony

There is no claim ceremony. `POST /agent/identity/claim` returns `claimed_or_in_flight` with an explanation that no registration exists.

## Step 5 — Exchange the assertion

```http
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
```

```json
{
  "error": "unsupported_grant_type",
  "error_description": "ezkey does not mint access tokens. Call https://ezkey.app/api/v1/overview without Authorization."
}
```

## Step 6 — Use the access_token

Do not send a bearer token. Call:

```http
GET /api/v1/overview HTTP/1.1
Host: ezkey.app
Accept: application/json
```

MCP: `POST https://ezkey.app/mcp`. A2A: `POST https://ezkey.app/a2a`. Rate limit: 10 requests per 10 seconds per IP, advertised in `RateLimit-Policy`.

## Errors

| Code | Where | What to do |
| --- | --- | --- |
| `anonymous_not_enabled` | `/agent/identity` | Do not register. Use the public API. |
| `service_auth_not_enabled` | `/agent/identity` | Email-based registration is disabled. |
| `issuer_not_enabled` | `/agent/identity` | ID-JAG registration is disabled. |
| `invalid_request` | `/agent/identity` | Body was not JSON or `type` was missing. |
| `claimed_or_in_flight` | `/agent/identity/claim` | No registrations exist to claim. |
| `unsupported_grant_type` | `/oauth/token` | No grant types are supported. |
| `invalid_client` | `/oauth/token` | No clients are registered. |
| `rate_limited` (429) | any | Honor `Retry-After`. |

## Revocation

`POST /oauth/revoke` returns HTTP 200 and does nothing (RFC 7009 idempotent success). There are no tokens to kill. `agent_auth.events_endpoint` accepts RFC 8935 POSTs and returns 204; nothing is stored.

Protected Resource Metadata remains the runtime source of truth if this file ever disagrees with it.
