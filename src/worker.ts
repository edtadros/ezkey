type Env = {
  ASSETS: { fetch: (request: Request) => Promise<Response> };
};

const ORIGIN = "https://ezkey.app";
const API_VERSION = "1";
const RATE_LIMIT = 60;
const RATE_WINDOW = 60;

const PAGE_MD: Record<string, string> = {
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

const PAGE_FILES: Record<string, string> = {
  home: "/index.md",
  about: "/about.md",
  contact: "/contact.md",
  privacy: "/privacy.md",
  security: "/security.md",
  glossary: "/glossary.md",
  developers: "/developers.md",
  auth: "/auth.md",
  guides: "/guides.md",
  "save-api-keys": "/guides/how-to-save-api-keys-securely-on-mac.md",
  "best-way": "/guides/best-way-to-store-api-keys-on-macos.md",
  dotenv: "/guides/is-it-safe-to-put-api-keys-in-dotenv.md",
  "openai-key": "/guides/how-to-store-openai-api-key-on-mac.md",
  "security-cli": "/guides/security-add-generic-password.md",
  "for-developers": "/for/developers.md",
  "local-keys": "/for/local-api-keys.md",
  "vs-1password": "/compare/macos-keychain-vs-1password-for-api-keys.md",
  "vs-access": "/compare/ezkey-vs-keychain-access.md",
};

const OVERVIEW =
  "ezkey is a macOS menu bar extra for the login Keychain. Local only. No account, no server, no warranty. Source: https://github.com/edtadros/ezkey Site: https://ezkey.app/";

const BUILD = `git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh

Requires macOS 14+ and Xcode command-line tools. Do not grant Keychain access to a binary you did not compile unless it is a notarized GitHub Release.`;

const MD_404 = `# Not found

That path is not on this site. Recover from:

- [Home](${ORIGIN}/index.md)
- [Agent index (llms.txt)](${ORIGIN}/llms.txt)
- [Sitemap](${ORIGIN}/sitemap.md)
- [Guides](${ORIGIN}/guides.md)
- [Developers](${ORIGIN}/developers.md)
- [OpenAPI](${ORIGIN}/openapi.json)
`;

const AI_CRAWLER_UA =
  /GPTBot|ClaudeBot|ChatGPT-User|PerplexityBot|Google-Extended|Applebot-Extended|ora-agent|DeepSeekBot|Claude-User|OAI-SearchBot|Claude-SearchBot|Amazonbot|CCBot/i;

function wantsMarkdown(request: Request, pathname: string): boolean {
  if (pathname.endsWith(".md") || pathname.endsWith("/index.md")) return true;
  const ua = request.headers.get("User-Agent") ?? "";
  if (AI_CRAWLER_UA.test(ua)) return true;
  const accept = request.headers.get("Accept") ?? "";
  return /\btext\/markdown\b/i.test(accept);
}

function wantsJson(request: Request, pathname: string): boolean {
  if (pathname === "/api" || pathname.startsWith("/api/")) return true;
  const accept = request.headers.get("Accept") ?? "";
  return /\bapplication\/(json|problem\+json)\b/i.test(accept);
}

function rateHeaders(): Record<string, string> {
  return {
    "RateLimit": `"per-minute";r=${RATE_LIMIT};t=${RATE_WINDOW}`,
    "RateLimit-Policy": `${RATE_LIMIT};w=${RATE_WINDOW}`,
    "RateLimit-Limit": String(RATE_LIMIT),
    "RateLimit-Remaining": String(RATE_LIMIT),
    "RateLimit-Reset": String(RATE_WINDOW),
    "API-Version": API_VERSION,
  };
}

function agentHeaders(contentType: string, extraLink = ""): Headers {
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

function jsonBody(status: number, body: unknown, contentType = "application/json"): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: agentHeaders(`${contentType}; charset=utf-8`),
  });
}

function problem(
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

function markdown404(): Response {
  const headers = agentHeaders("text/markdown; charset=utf-8");
  headers.set("X-Robots-Tag", "noindex");
  return new Response(MD_404, { status: 404, headers });
}

async function asset(
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

function jsonRpcResult(id: unknown, result: unknown): Response {
  return jsonBody(200, { jsonrpc: "2.0", id, result });
}

function jsonRpcError(id: unknown, code: number, message: string, status = 200): Response {
  return jsonBody(status, { jsonrpc: "2.0", id, error: { code, message } });
}

async function handleMcp(request: Request, env: Env): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
  }
  if (request.method === "GET") {
    return new Response("ezkey MCP. POST JSON-RPC to this URL.", {
      headers: agentHeaders("text/plain; charset=utf-8"),
    });
  }
  if (request.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: agentHeaders("text/plain"),
    });
  }
  let body: { jsonrpc?: string; id?: unknown; method?: string; params?: Record<string, unknown> };
  try {
    body = await request.json();
  } catch {
    return jsonRpcError(null, -32700, "Parse error");
  }
  const id = body.id ?? null;
  const method = body.method ?? "";
  if (method === "initialize") {
    return jsonRpcResult(id, {
      protocolVersion: "2025-06-18",
      capabilities: { tools: {} },
      serverInfo: { name: "ezkey", version: "1.0.0" },
      instructions:
        "Read-only documentation for ezkey, a local macOS login-Keychain extra. Use get_overview, get_build_instructions, or get_page. Do not expect Keychain access or OAuth tokens.",
    });
  }
  if (method === "notifications/initialized" || method === "notifications/cancelled") {
    return new Response(null, { status: 202, headers: agentHeaders("text/plain") });
  }
  if (method === "ping") {
    return jsonRpcResult(id, {});
  }
  if (method === "tools/list") {
    return jsonRpcResult(id, {
      tools: [
        {
          name: "get_overview",
          description: "Return a short description of ezkey and where to get the source.",
          inputSchema: {
            type: "object",
            properties: {
              verbose: { type: "boolean", description: "If true, include extra documentation links." },
            },
            additionalProperties: false,
          },
          annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true },
        },
        {
          name: "get_build_instructions",
          description: "Return commands to clone and build ezkey on macOS.",
          inputSchema: {
            type: "object",
            properties: {
              verbose: { type: "boolean", description: "If true, include extra documentation links." },
            },
            additionalProperties: false,
          },
          annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true },
        },
        {
          name: "get_page",
          description: "Return Markdown for a site page.",
          inputSchema: {
            type: "object",
            properties: {
              page: {
                type: "string",
                description: "Page id: home, about, contact, privacy, security, glossary, developers, auth, guides, save-api-keys, best-way, dotenv, openai-key, security-cli, for-developers, local-keys, vs-1password, vs-access",
                enum: Object.keys(PAGE_FILES),
              },
            },
            required: ["page"],
            additionalProperties: false,
          },
          annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true },
        },
      ],
    });
  }
  if (method === "tools/call") {
    const params = (body.params ?? {}) as { name?: string; arguments?: Record<string, string> };
    const name = params.name ?? "";
    if (name === "get_overview") {
      return jsonRpcResult(id, {
        content: [{ type: "text", text: OVERVIEW }],
        isError: false,
      });
    }
    if (name === "get_build_instructions") {
      return jsonRpcResult(id, {
        content: [{ type: "text", text: BUILD }],
        isError: false,
      });
    }
    if (name === "get_page") {
      const page = params.arguments?.page ?? "home";
      const file = PAGE_FILES[page];
      if (!file) {
        return jsonRpcResult(id, {
          content: [{ type: "text", text: "Unknown page. Use home, about, contact, privacy, security, glossary, developers, or auth." }],
          isError: true,
        });
      }
      const res = await env.ASSETS.fetch(new Request(`https://assets${file}`));
      const text = await res.text();
      return jsonRpcResult(id, {
        content: [{ type: "text", text }],
        isError: !res.ok,
      });
    }
    return jsonRpcError(id, -32601, `Unknown tool: ${name}`);
  }
  return jsonRpcError(id, -32601, `Unknown method: ${method}`);
}

async function handleRest(request: Request, env: Env, path: string): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
  }
  if (request.method !== "GET") {
    return problem(
      405,
      "method_not_allowed",
      "Method Not Allowed",
      "Use GET on /api/v1 resources.",
      path,
      `See ${ORIGIN}/openapi.json`
    );
  }
  if (path === "/api/v1/health" || path === "/api/v1/health/") {
    return jsonBody(200, { ok: true, name: "ezkey", version: "1.0.0" });
  }
  if (path === "/api/v1/overview" || path === "/api/v1/overview/") {
    return jsonBody(200, {
      name: "ezkey",
      summary: OVERVIEW,
      source: "https://github.com/edtadros/ezkey",
      site: `${ORIGIN}/`,
    });
  }
  if (path === "/api/v1/build" || path === "/api/v1/build/") {
    return jsonBody(200, { commands: BUILD, requires: "macOS 14+ and Xcode command-line tools" });
  }
  const pageMatch = path.match(/^\/api\/v1\/pages\/([^/]+)\/?$/);
  if (pageMatch) {
    const page = decodeURIComponent(pageMatch[1]);
    const file = PAGE_FILES[page];
    if (!file) {
      return problem(
        404,
        "not_found",
        "Not Found",
        `Unknown page '${page}'.`,
        path,
        "Use home, about, contact, privacy, security, glossary, developers, or auth. See https://ezkey.app/openapi.json"
      );
    }
    const res = await env.ASSETS.fetch(new Request(`https://assets${file}`));
    const markdown = await res.text();
    if (!res.ok) {
      return problem(
        404,
        "not_found",
        "Not Found",
        "That page could not be loaded.",
        path,
        `See ${ORIGIN}/llms.txt`
      );
    }
    return jsonBody(200, { page, markdown });
  }
  return problem(
    404,
    "not_found",
    "Not Found",
    "That API path is not on ezkey.app.",
    path,
    `Use OpenAPI at ${ORIGIN}/openapi.json or the catalog at ${ORIGIN}/.well-known/api-catalog`
  );
}

async function handleA2A(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
  }
  if (request.method === "GET") {
    return new Response("ezkey A2A. POST JSON-RPC message/send to this URL.", {
      headers: agentHeaders("text/plain; charset=utf-8"),
    });
  }
  if (request.method !== "POST") {
    return jsonRpcError(null, -32600, "Method Not Allowed", 405);
  }
  let body: { id?: unknown; method?: string; params?: Record<string, unknown> };
  try {
    body = await request.json();
  } catch {
    return jsonRpcError(null, -32700, "Parse error");
  }
  const id = body.id ?? null;
  const method = body.method ?? "";
  if (method === "message/send") {
    const message = (body.params?.message ?? {}) as { parts?: Array<{ kind?: string; text?: string }>; messageId?: string; contextId?: string };
    const text = (message.parts ?? [])
      .filter((part) => part && part.kind === "text" && typeof part.text === "string")
      .map((part) => part.text as string)
      .join("\n")
      .trim()
      .toLowerCase();
    const answer = text.includes("build") || text.includes("install") || text.includes("clone")
      ? BUILD
      : OVERVIEW;
    const taskId = crypto.randomUUID();
    const contextId = typeof message.contextId === "string" && message.contextId ? message.contextId : crypto.randomUUID();
    return jsonRpcResult(id, {
      kind: "task",
      id: taskId,
      contextId,
      status: { state: "completed", timestamp: new Date().toISOString() },
      artifacts: [
        {
          artifactId: crypto.randomUUID(),
          parts: [{ kind: "text", text: answer }],
        },
      ],
    });
  }
  if (method === "tasks/get" || method === "tasks/cancel") {
    return jsonRpcError(id, -32001, "TaskNotFound: this agent does not persist tasks.");
  }
  if (method === "agent/getAuthenticatedExtendedCard") {
    return jsonRpcError(id, -32007, "Authenticated extended card is not configured.");
  }
  return jsonRpcError(id, -32601, `Unknown method: ${method}`);
}

function oauthProtectedResource(resource: string) {
  return {
    resource,
    resource_name: "ezkey",
    authorization_servers: [ORIGIN],
    scopes_supported: [] as string[],
    bearer_methods_supported: ["header"],
    resource_documentation: `${ORIGIN}/auth.md`,
  };
}

function oauthAuthorizationServer() {
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

async function handleOAuth(request: Request, path: string): Promise<Response | null> {
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

function extraMarkdownLink(path: string): string {
  const mdPath = PAGE_MD[path] ?? PAGE_MD[path.replace(/\/$/, "") + "/"] ?? PAGE_MD[path.replace(/\/$/, "")];
  if (mdPath) return `<${ORIGIN}${mdPath}>; rel="alternate"; type="text/markdown"`;
  if (path === "/") return `<${ORIGIN}/index.md>; rel="alternate"; type="text/markdown"`;
  return "";
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
    }

    if (path === "/mcp" || path === "/api/v1/mcp" || path === "/v1/mcp") {
      return handleMcp(request, env);
    }
    if (path === "/a2a") {
      return handleA2A(request);
    }
    if (path === "/api" || path.startsWith("/api/")) {
      return handleRest(request, env, path);
    }

    const oauth = await handleOAuth(request, path);
    if (oauth) return oauth;

    if (path === "/docs" || path === "/docs/") {
      return Response.redirect(`${ORIGIN}/developers/`, 301);
    }

    if (path === "/.well-known/api-catalog") {
      return asset(env, "/.well-known/api-catalog", "application/linkset+json");
    }

    if (wantsMarkdown(request, path)) {
      const mdPath = PAGE_MD[path] ?? (path.endsWith(".md") ? path : PAGE_MD[path.replace(/\/$/, "")]);
      if (mdPath) {
        const extra = `<${ORIGIN}${mdPath}>; rel="alternate"; type="text/markdown"`;
        const res = await asset(env, mdPath, "text/markdown; charset=utf-8", extra);
        if (res.ok) return res;
      }
      if (!path.startsWith("/.") && !path.endsWith(".css") && !path.endsWith(".js") && !path.endsWith(".png") && !path.endsWith(".svg") && !path.endsWith(".xml") && !path.endsWith(".json") && !path.endsWith(".txt")) {
        return markdown404();
      }
    }

    const extraMd = extraMarkdownLink(path);
    const assetRequest = new Request(url.toString(), request);
    const res = await env.ASSETS.fetch(assetRequest);

    if (res.status === 404) {
      if (wantsJson(request, path)) {
        return problem(
          404,
          "not_found",
          "Not Found",
          "That path is not on ezkey.app.",
          path,
          `See ${ORIGIN}/llms.txt, ${ORIGIN}/sitemap.xml, or ${ORIGIN}/openapi.json`
        );
      }
      if (wantsMarkdown(request, path)) return markdown404();
    }

    const contentType = res.headers.get("Content-Type") ?? "application/octet-stream";
    const headers = agentHeaders(contentType, extraMd);
    const originType = res.headers.get("Content-Type");
    if (originType) headers.set("Content-Type", originType);
    for (const name of ["Location", "Cache-Control", "ETag", "Last-Modified", "Content-Encoding"]) {
      const value = res.headers.get(name);
      if (value) headers.set(name, value);
    }
    if (
      path.endsWith("llms.txt") ||
      path.endsWith("llms-full.txt") ||
      path.endsWith("robots.txt") ||
      path.endsWith("AGENTS.md") ||
      path.endsWith("sitemap.md") ||
      path === "/.well-known/agent"
    ) {
      headers.set("Content-Type", "text/plain; charset=utf-8");
    }
    if (path.endsWith("sitemap.xml")) {
      headers.set("Content-Type", "application/xml; charset=utf-8");
    }
    if (path.endsWith(".json") || path.endsWith("api-catalog")) {
      headers.set(
        "Content-Type",
        path.endsWith("api-catalog") ? "application/linkset+json" : "application/json; charset=utf-8"
      );
    }
    if (path.endsWith(".md") || path.endsWith("auth.md")) {
      headers.set("Content-Type", "text/markdown; charset=utf-8");
    }
    return new Response(res.body, { status: res.status, headers });
  },
};
