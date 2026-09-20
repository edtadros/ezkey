---
title: Versioning — ezkey.app
description: URL versioning and deprecation policy for the ezkey.app site API.
---

# Versioning and deprecation

The ezkey.app site API uses **URL path versioning**. The current major version is `1` at `https://ezkey.app/api/v1` and in the `API-Version` response header.

## Compatibility

- Additive JSON fields may appear in a major version.
- Breaking changes require a new major path such as `/api/v2`.
- Clients should ignore unknown fields.

## Deprecation

No route is deprecated today. When a route is deprecated it will send RFC 9745 `Deprecation` and `Sunset` headers with at least 90 days of notice, plus `Link` with `rel="deprecation"` pointing at this page.

MCP and A2A follow the same calendar. The native macOS app is not versioned through this website.

See [developers](https://ezkey.app/developers.md) and [OpenAPI](https://ezkey.app/openapi.json).
