---
title: DNS-AID — ezkey.app
description: DNS for AI Discovery records agents should look up for ezkey.app.
---

# DNS for AI Discovery (DNS-AID)

Agents should query these names with DNS-over-HTTPS (SVCB/HTTPS, type 64/65). Until the records are published in Cloudflare DNS, this file is the HTTP catalog.

## Records to publish

```
_index._agents.ezkey.app. 3600 IN SVCB 1 ezkey.app. alpn="h2,h3" port=443
_mcp._agents.ezkey.app. 3600 IN SVCB 1 ezkey.app. alpn="h2" port=443
_a2a._agents.ezkey.app. 3600 IN SVCB 1 ezkey.app. alpn="h2" port=443
```

Cloudflare dashboard: DNS → Add record → type HTTPS (or SVCB).

| Name | Priority | Target | Value |
| --- | --- | --- | --- |
| `_index._agents` | 1 | `ezkey.app` | `alpn="h2,h3" port=443` |
| `_mcp._agents` | 1 | `ezkey.app` | `alpn="h2" port=443` |
| `_a2a._agents` | 1 | `ezkey.app` | `alpn="h2" port=443` |

Enable DNSSEC on the zone and add the DS record at the registrar so validating resolvers return authenticated data.

JSON catalog: https://ezkey.app/.well-known/dns-aid.json

See [draft-mozleywilliams-dnsop-dnsaid](https://datatracker.ietf.org/doc/draft-mozleywilliams-dnsop-dnsaid/) and [RFC 9460](https://www.rfc-editor.org/rfc/rfc9460).
