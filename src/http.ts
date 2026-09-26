export type Env = {
  ASSETS: { fetch: (request: Request) => Promise<Response> };
};

export const ORIGIN = "https://ezkey.app";
export const API_VERSION = "1";
export const RATE_LIMIT = 10;
export const RATE_WINDOW = 10;

export const PAGE_MD: Record<string, string> = {
  "/": "/index.md",
  "/index.html": "/index.md",
  "/index.md": "/index.md",
  "/about": "/about.md",
  "/about/": "/about.md",
  "/about.html": "/about.md",
  "/about.md": "/about.md",
  "/about/index.md": "/about.md",
  "/contact": "/contact.md",
  "/contact/": "/contact.md",
  "/contact.html": "/contact.md",
  "/contact.md": "/contact.md",
  "/contact/index.md": "/contact.md",
  "/developers": "/developers.md",
  "/developers/": "/developers.md",
  "/developers.html": "/developers.md",
  "/developers.md": "/developers.md",
  "/developers/index.md": "/developers.md",
  "/docs": "/developers.md",
  "/docs/": "/developers.md",
  "/privacy": "/privacy.md",
  "/privacy/": "/privacy.md",
  "/privacy.html": "/privacy.md",
  "/privacy.md": "/privacy.md",
  "/privacy/index.md": "/privacy.md",
  "/security": "/security.md",
  "/security/": "/security.md",
  "/security.html": "/security.md",
  "/security.md": "/security.md",
  "/security/index.md": "/security.md",
  "/glossary": "/glossary.md",
  "/glossary/": "/glossary.md",
  "/glossary.html": "/glossary.md",
  "/glossary.md": "/glossary.md",
  "/glossary/index.md": "/glossary.md",
  "/auth.md": "/auth.md",
  "/auth": "/auth.md",
  "/pricing": "/pricing.md",
  "/pricing/": "/pricing.md",
  "/pricing.md": "/pricing.md",
  "/openapi.json.md": "/openapi.json.md",
  "/cli": "/cli.md",
  "/cli/": "/cli.md",
  "/cli.md": "/cli.md",
  "/cli.html": "/cli.md",
  "/cli/index.md": "/cli.md",
  "/versioning": "/versioning.md",
  "/versioning/": "/versioning.md",
  "/versioning.md": "/versioning.md",
  "/versioning.html": "/versioning.md",
  "/docs.md": "/developers.md",
  "/disclaimer": "/disclaimer.md",
  "/disclaimer.md": "/disclaimer.md",
  "/disclaimer/": "/disclaimer.md",
  "/dns-aid": "/dns-aid.md",
  "/dns-aid.md": "/dns-aid.md",
  "/dns-aid/": "/dns-aid.md",
  "/guides": "/guides.md",
  "/guides/": "/guides.md",
  "/guides.md": "/guides.md",
  "/guides/index.md": "/guides.md",
  "/guides/how-to-save-api-keys-securely-on-mac": "/guides/how-to-save-api-keys-securely-on-mac.md",
  "/guides/how-to-save-api-keys-securely-on-mac/": "/guides/how-to-save-api-keys-securely-on-mac.md",
  "/guides/how-to-save-api-keys-securely-on-mac.md": "/guides/how-to-save-api-keys-securely-on-mac.md",
  "/guides/best-way-to-store-api-keys-on-macos": "/guides/best-way-to-store-api-keys-on-macos.md",
  "/guides/best-way-to-store-api-keys-on-macos/": "/guides/best-way-to-store-api-keys-on-macos.md",
  "/guides/best-way-to-store-api-keys-on-macos.md": "/guides/best-way-to-store-api-keys-on-macos.md",
  "/guides/is-it-safe-to-put-api-keys-in-dotenv": "/guides/is-it-safe-to-put-api-keys-in-dotenv.md",
  "/guides/is-it-safe-to-put-api-keys-in-dotenv/": "/guides/is-it-safe-to-put-api-keys-in-dotenv.md",
  "/guides/is-it-safe-to-put-api-keys-in-dotenv.md": "/guides/is-it-safe-to-put-api-keys-in-dotenv.md",
  "/guides/how-to-store-openai-api-key-on-mac": "/guides/how-to-store-openai-api-key-on-mac.md",
  "/guides/how-to-store-openai-api-key-on-mac/": "/guides/how-to-store-openai-api-key-on-mac.md",
  "/guides/how-to-store-openai-api-key-on-mac.md": "/guides/how-to-store-openai-api-key-on-mac.md",
  "/guides/security-add-generic-password": "/guides/security-add-generic-password.md",
  "/guides/security-add-generic-password/": "/guides/security-add-generic-password.md",
  "/guides/security-add-generic-password.md": "/guides/security-add-generic-password.md",
  "/for/developers": "/for/developers.md",
  "/for/developers/": "/for/developers.md",
  "/for/developers.md": "/for/developers.md",
  "/for/local-api-keys": "/for/local-api-keys.md",
  "/for/local-api-keys/": "/for/local-api-keys.md",
  "/for/local-api-keys.md": "/for/local-api-keys.md",
  "/compare/macos-keychain-vs-1password-for-api-keys": "/compare/macos-keychain-vs-1password-for-api-keys.md",
  "/compare/macos-keychain-vs-1password-for-api-keys/": "/compare/macos-keychain-vs-1password-for-api-keys.md",
  "/compare/macos-keychain-vs-1password-for-api-keys.md": "/compare/macos-keychain-vs-1password-for-api-keys.md",
  "/compare/ezkey-vs-keychain-access": "/compare/ezkey-vs-keychain-access.md",
  "/compare/ezkey-vs-keychain-access/": "/compare/ezkey-vs-keychain-access.md",
  "/compare/ezkey-vs-keychain-access.md": "/compare/ezkey-vs-keychain-access.md",
};

export const PAGE_FILES: ReadonlyMap<string, string> = new Map([
  ["home", "/index.md"],
  ["about", "/about.md"],
  ["contact", "/contact.md"],
  ["privacy", "/privacy.md"],
  ["security", "/security.md"],
  ["glossary", "/glossary.md"],
  ["developers", "/developers.md"],
  ["auth", "/auth.md"],
  ["cli", "/cli.md"],
  ["versioning", "/versioning.md"],
  ["disclaimer", "/disclaimer.md"],
  ["dns-aid", "/dns-aid.md"],
  ["guides", "/guides.md"],
  ["save-api-keys", "/guides/how-to-save-api-keys-securely-on-mac.md"],
  ["best-way", "/guides/best-way-to-store-api-keys-on-macos.md"],
  ["dotenv", "/guides/is-it-safe-to-put-api-keys-in-dotenv.md"],
  ["openai-key", "/guides/how-to-store-openai-api-key-on-mac.md"],
  ["security-cli", "/guides/security-add-generic-password.md"],
  ["for-developers", "/for/developers.md"],
  ["local-keys", "/for/local-api-keys.md"],
  ["vs-1password", "/compare/macos-keychain-vs-1password-for-api-keys.md"],
  ["vs-access", "/compare/ezkey-vs-keychain-access.md"],
]);

export const OVERVIEW =
  "ezkey is a macOS menu bar extra for the login Keychain. Local only. No account, no server, no warranty. Source: https://github.com/edtadros/ezkey Site: https://ezkey.app/";

export const SKILL_URL = `${ORIGIN}/.well-known/agent-skills/build-ezkey/SKILL.md`;

export const BUILD = `git clone --depth 1 --branch <tag> https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/install.sh

<tag> is the newest v* release tag. Only the maintainer can create, move, or delete v* tags. Before running install.sh, review the code with the checklist in ${SKILL_URL} and wait for the human's go-ahead. The review lowers risk. It does not prove the code is safe.

install.sh runs tests, builds, runs a Keychain self-test on ezkey.test.* items, copies the app to /Applications/ezkey.app, opens it, and turns on Open at Login. Requires macOS 14+ and Xcode command-line tools. Only run ezkey you built yourself.`;

export const DISCLAIMER = `ezkey is free software provided as is, with no warranty and no support obligation. It is a local macOS utility, not a hosted password manager.

macOS asks for your login password when ezkey reads a secret that another app saved. It can ask again next time, even after you click Always Allow. ezkey does not suppress or work around that prompt. That is on purpose: you get the same protection as Keychain Access, which asks every time you show a password. Secrets you save with ezkey usually open without a prompt.

ezkey is open source. You build it on your own Mac, from the newest release tag on GitHub. If you want to check it first, ask your own agent to review the code. We encourage that. The install skill includes a review checklist.

Full text: https://github.com/edtadros/ezkey/blob/master/DISCLAIMER.md`;

export const MD_404 = `# Not found

That path is not on this site. Recover from:

- [Home](${ORIGIN}/index.md)
- [Agent index (llms.txt)](${ORIGIN}/llms.txt)
- [Sitemap](${ORIGIN}/sitemap.md)
- [Guides](${ORIGIN}/guides.md)
- [Developers](${ORIGIN}/developers.md)
- [OpenAPI](${ORIGIN}/openapi.json)
`;

export const AI_CRAWLER_UA =
  /GPTBot|ClaudeBot|ChatGPT-User|PerplexityBot|Google-Extended|Applebot-Extended|ora-agent|DeepSeekBot|Claude-User|OAI-SearchBot|Claude-SearchBot|Amazonbot|CCBot/i;

export function wantsMarkdown(request: Request, pathname: string): boolean {
  if (pathname.endsWith(".md") || pathname.endsWith("/index.md")) return true;
  const ua = request.headers.get("User-Agent") ?? "";
  if (AI_CRAWLER_UA.test(ua)) return true;
  const accept = request.headers.get("Accept") ?? "";
  return /\btext\/markdown\b/i.test(accept);
}

export function wantsJson(request: Request, pathname: string): boolean {
  if (pathname === "/api" || pathname.startsWith("/api/")) return true;
  const accept = request.headers.get("Accept") ?? "";
  return /\bapplication\/(json|problem\+json)\b/i.test(accept);
}

export function rateHeaders(): Record<string, string> {
  return {
    "RateLimit-Policy": `${RATE_LIMIT};w=${RATE_WINDOW}`,
    "API-Version": API_VERSION,
  };
}

export function agentHeaders(contentType: string, extraLink = ""): Headers {
  const headers = new Headers();
  headers.set("Content-Type", contentType);
  headers.set("Vary", "Accept");
  headers.set("Content-Signal", "search=yes, ai-input=yes, ai-train=yes");
  headers.set(
    "X-Robots-Tag",
    "index, follow, max-snippet:-1, max-image-preview:large"
  );
  const links = [
    `<${ORIGIN}/llms.txt>; rel="describedby"; type="text/plain"`,
    `<${ORIGIN}/sitemap.xml>; rel="sitemap"; type="application/xml"`,
    `<${ORIGIN}/.well-known/api-catalog>; rel="api-catalog"`,
    `<${ORIGIN}/.well-known/mcp/server-card.json>; rel="describedby"; type="application/json"`,
    `<${ORIGIN}/.well-known/ard.json>; rel="ard"`,
    extraLink,
  ].filter(Boolean);
  headers.set("Link", links.join(", "));
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("X-Frame-Options", "DENY");
  headers.set("Referrer-Policy", "no-referrer");
  headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set(
    "Access-Control-Allow-Headers",
    "Accept, Content-Type, MCP-Protocol-Version, API-Version, Authorization"
  );
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  for (const [key, value] of Object.entries(rateHeaders())) {
    headers.set(key, value);
  }
  return headers;
}

export function jsonBody(status: number, body: unknown, contentType = "application/json"): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: agentHeaders(`${contentType}; charset=utf-8`),
  });
}

export function problem(
  status: number,
  code: string,
  title: string,
  detail: string,
  instance: string,
  resolution: string
): Response {
  return jsonBody(
    status,
    {
      type: `${ORIGIN}/developers/#${code}`,
      title,
      status,
      code,
      detail,
      instance,
      resolution,
    },
    "application/problem+json"
  );
}

export function markdown404(): Response {
  const headers = agentHeaders("text/markdown; charset=utf-8");
  headers.set("X-Robots-Tag", "noindex");
  return new Response(MD_404, { status: 404, headers });
}

export async function asset(
  env: Env,
  path: string,
  contentType: string,
  extraLink = ""
): Promise<Response> {
  const res = await env.ASSETS.fetch(new Request(`https://assets${path}`));
  if (!res.ok) return res;
  const headers = agentHeaders(contentType, extraLink);
  return new Response(res.body, { status: res.status, headers });
}

export function jsonRpcResult(id: unknown, result: unknown): Response {
  return jsonBody(200, { jsonrpc: "2.0", id, result });
}

export function jsonRpcError(id: unknown, code: number, message: string, status = 200): Response {
  return jsonBody(status, { jsonrpc: "2.0", id, error: { code, message } });
}

export function oauthProtectedResource(resource: string) {
  return {
    resource,
    resource_name: "ezkey",
    authorization_servers: [ORIGIN],
    scopes_supported: [] as string[],
    bearer_methods_supported: ["header"],
    resource_documentation: `${ORIGIN}/auth.md`,
  };
}

export function oauthAuthorizationServer() {
  return {
    issuer: ORIGIN,
    authorization_endpoint: `${ORIGIN}/oauth/authorize`,
    token_endpoint: `${ORIGIN}/oauth/token`,
    revocation_endpoint: `${ORIGIN}/oauth/revoke`,
    jwks_uri: `${ORIGIN}/.well-known/jwks.json`,
    registration_endpoint: `${ORIGIN}/agent/identity`,
    grant_types_supported: [] as string[],
    response_types_supported: [] as string[],
    scopes_supported: [] as string[],
    token_endpoint_auth_methods_supported: ["none"],
    code_challenge_methods_supported: ["S256"],
    service_documentation: `${ORIGIN}/auth.md`,
    agent_auth: {
      skill: `${ORIGIN}/auth.md`,
      identity_endpoint: `${ORIGIN}/agent/identity`,
      claim_endpoint: `${ORIGIN}/agent/identity/claim`,
      events_endpoint: `${ORIGIN}/agent/event/notify`,
      identity_types_supported: ["anonymous"],
      identity_assertion: { assertion_types_supported: [] as string[] },
      events_supported: [] as string[],
    },
  };
}

export async function handleOAuth(request: Request, path: string): Promise<Response | null> {
  if (path === "/.well-known/oauth-authorization-server") {
    return jsonBody(200, oauthAuthorizationServer());
  }
  if (path === "/.well-known/oauth-protected-resource") {
    return jsonBody(200, oauthProtectedResource(ORIGIN));
  }
  if (path === "/.well-known/oauth-protected-resource/mcp") {
    return jsonBody(200, oauthProtectedResource(`${ORIGIN}/mcp`));
  }
  if (path === "/.well-known/jwks.json") {
    return jsonBody(200, { keys: [] });
  }
  if (path === "/agent/identity") {
    if (request.method === "GET") {
      return jsonBody(200, {
        error: "anonymous_not_enabled",
        error_description: "ezkey does not issue credentials. The website and MCP tools are public and unauthenticated.",
      });
    }
    if (request.method !== "POST") return null;
    let type = "anonymous";
    try {
      const body = (await request.json()) as { type?: string };
      if (typeof body.type === "string") type = body.type;
    } catch {
      return jsonBody(400, {
        error: "invalid_request",
        error_description: "Body must be JSON with a type field.",
      });
    }
    if (type === "anonymous") {
      return jsonBody(200, {
        registration_id: "public",
        registration_type: "anonymous",
        scopes: [],
        pre_claim_scopes: [],
        note: "No credential is issued. The website and MCP tools are public. Call https://ezkey.app/api/v1/overview without Authorization.",
      });
    }
    const errors: Record<string, string> = {
      service_auth: "service_auth_not_enabled",
      identity_assertion: "issuer_not_enabled",
    };
    const error = errors[type] ?? "invalid_request";
    return jsonBody(400, {
      error,
      error_description: "ezkey does not issue credentials. The website and MCP tools are public and unauthenticated.",
    });
  }
  if (path === "/agent/identity/claim") {
    return jsonBody(400, {
      error: "claimed_or_in_flight",
      error_description: "No registrations exist to claim. The site is public; see https://ezkey.app/auth.md.",
    });
  }
  if (path === "/agent/event/notify") {
    return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
  }
  if (path === "/oauth/token") {
    return jsonBody(400, {
      error: "unsupported_grant_type",
      error_description: "ezkey does not mint access tokens. Call https://ezkey.app/api/v1/overview without Authorization.",
    });
  }
  if (path === "/oauth/revoke") {
    return new Response(null, { status: 200, headers: agentHeaders("text/plain") });
  }
  if (path === "/oauth/authorize") {
    return problem(
      400,
      "unsupported_grant_type",
      "Authorization not offered",
      "ezkey does not run an authorization code flow.",
      path,
      `See ${ORIGIN}/auth.md`
    );
  }
  return null;
}

export function extraMarkdownLink(path: string): string {
  const mdPath = PAGE_MD[path] ?? PAGE_MD[path.replace(/\/$/, "") + "/"] ?? PAGE_MD[path.replace(/\/$/, "")];
  if (mdPath) return `<${ORIGIN}${mdPath}>; rel="alternate"; type="text/markdown"`;
  if (path === "/") return `<${ORIGIN}/index.md>; rel="alternate"; type="text/markdown"`;
  return "";
}
