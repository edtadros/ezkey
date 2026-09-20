type Env = {
  ASSETS: { fetch: (request: Request) => Promise<Response> };
};

const ORIGIN = "https://ezkey.app";

const PAGE_MD: Record<string, string> = {
  "/": "/index.md",
  "/index.html": "/index.md",
  "/index.md": "/index.md",
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
};

const WELL_KNOWN_JSON: Record<string, string> = {
  "/.well-known/api-catalog": "/.well-known/api-catalog",
  "/.well-known/mcp.json": "/.well-known/mcp.json",
  "/.well-known/mcp/server-card.json": "/.well-known/mcp/server-card.json",
  "/.well-known/agent-skills/index.json": "/.well-known/agent-skills/index.json",
};

function wantsMarkdown(request: Request, pathname: string): boolean {
  if (pathname.endsWith(".md") || pathname.endsWith("/index.md")) return true;
  const accept = request.headers.get("Accept") ?? "";
  return /\btext\/markdown\b/i.test(accept);
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
    extraLink,
  ].filter(Boolean);
  headers.set("Link", links.join(", "));
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Headers", "Accept, Content-Type, MCP-Protocol-Version");
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  return headers;
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

const OVERVIEW = `ezkey is a macOS menu bar extra for the login Keychain. Local only. No account, no server, no warranty. Source: https://github.com/edtadros/ezkey Site: https://ezkey.app/`;

const BUILD = `git clone https://github.com/edtadros/ezkey.git
cd ezkey
./scripts/build-and-run.sh

Requires macOS 14+ and Xcode command-line tools. Do not grant Keychain access to a binary you did not compile unless it is a notarized GitHub Release.`;

const PAGE_FILES: Record<string, string> = {
  home: "/index.md",
  privacy: "/privacy.md",
  security: "/security.md",
  glossary: "/glossary.md",
};

function jsonRpcResult(id: unknown, result: unknown): Response {
  return new Response(JSON.stringify({ jsonrpc: "2.0", id, result }), {
    headers: agentHeaders("application/json"),
  });
}

function jsonRpcError(id: unknown, code: number, message: string): Response {
  return new Response(JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } }), {
    status: 200,
    headers: agentHeaders("application/json"),
  });
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
    return new Response("Method Not Allowed", { status: 405, headers: agentHeaders("text/plain") });
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
          inputSchema: { type: "object", properties: {}, additionalProperties: false },
          annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true },
        },
        {
          name: "get_build_instructions",
          description: "Return commands to clone and build ezkey on macOS.",
          inputSchema: { type: "object", properties: {}, additionalProperties: false },
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
                description: "One of home, privacy, security, glossary",
                enum: ["home", "privacy", "security", "glossary"],
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
          content: [{ type: "text", text: "Unknown page. Use home, privacy, security, or glossary." }],
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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (path === "/mcp") {
      return handleMcp(request, env);
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: agentHeaders("text/plain") });
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
    }

    const extraMd = PAGE_MD[path.replace(/\/$/, "") + "/"]
      ? `<${ORIGIN}${PAGE_MD[path.replace(/\/$/, "") + "/"]}>; rel="alternate"; type="text/markdown"`
      : PAGE_MD[path]
        ? `<${ORIGIN}${PAGE_MD[path]}>; rel="alternate"; type="text/markdown"`
        : path === "/"
          ? `<${ORIGIN}/index.md>; rel="alternate"; type="text/markdown"`
          : "";

    const assetRequest = new Request(url.toString(), request);
    const res = await env.ASSETS.fetch(assetRequest);
    const contentType = res.headers.get("Content-Type") ?? "application/octet-stream";
    const headers = agentHeaders(contentType, extraMd);
    const originType = res.headers.get("Content-Type");
    if (originType) headers.set("Content-Type", originType);
    if (path.endsWith("llms.txt") || path.endsWith("llms-full.txt") || path.endsWith("robots.txt") || path.endsWith("AGENTS.md") || path.endsWith("sitemap.md")) {
      headers.set("Content-Type", "text/plain; charset=utf-8");
    }
    if (path.endsWith("sitemap.xml")) {
      headers.set("Content-Type", "application/xml; charset=utf-8");
    }
    if (path.endsWith(".json") || path.endsWith("api-catalog")) {
      headers.set("Content-Type", path.endsWith("api-catalog") ? "application/linkset+json" : "application/json; charset=utf-8");
    }
    return new Response(res.body, { status: res.status, headers });
  },
};
