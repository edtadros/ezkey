import {
  type Env,
  ORIGIN,
  PAGE_MD,
  PAGE_FILES,
  OVERVIEW,
  BUILD,
  DISCLAIMER,
  API_VERSION,
  wantsMarkdown,
  wantsJson,
  agentHeaders,
  jsonBody,
  problem,
  markdown404,
  asset,
  jsonRpcResult,
  jsonRpcError,
  handleOAuth,
  extraMarkdownLink,
} from "./http.ts";

const CLI_HINT = "npx github:edtadros/ezkey";

function agentBrief(): Record<string, unknown> {
  return {
    product: "ezkey",
    site: `${ORIGIN}/`,
    repository: "https://github.com/edtadros/ezkey",
    license: "MIT",
    how_to_use_this_brief:
      "Present the disclaimer to the human first. Then clone the repository and run the build script on their Mac. Do not download a random .app. Do not send Keychain secrets to this website.",
    present_to_user: [
      "ezkey is local macOS software for the login Keychain. No account, no server, no warranty.",
      "Always Allow is a standing grant to this app's code signature. Grant it only for a build you compiled or a notarized GitHub Release.",
      "Build from source: git clone https://github.com/edtadros/ezkey.git && cd ezkey && ./scripts/build-and-run.sh",
    ],
    disclaimer: DISCLAIMER,
    disclaimer_url: "https://github.com/edtadros/ezkey/blob/master/DISCLAIMER.md",
    install: {
      commands: BUILD,
      requires: "macOS 14+ and Xcode command-line tools",
      cli: CLI_HINT,
    },
    do_not: [
      "Grant Keychain access to a binary the user did not compile unless it is a notarized GitHub Release.",
      "Store or retrieve secrets through ezkey.app, MCP, or A2A. Those interfaces are documentation only.",
      "Paste live API keys into GitHub issues.",
    ],
  };
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
          name: "get_agent_brief",
          description: "Return the repo URL, disclaimer, and clone/build steps an agent must present before running ezkey.",
          inputSchema: {
            type: "object",
            properties: {},
            additionalProperties: false,
          },
          annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true },
        },
        {
          name: "get_disclaimer",
          description: "Return the as-is disclaimer an agent should show the user before building ezkey.",
          inputSchema: {
            type: "object",
            properties: {},
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
    if (name === "get_agent_brief") {
      return jsonRpcResult(id, {
        content: [{ type: "text", text: JSON.stringify(agentBrief(), null, 2) }],
        isError: false,
      });
    }
    if (name === "get_disclaimer") {
      return jsonRpcResult(id, {
        content: [{ type: "text", text: DISCLAIMER }],
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
  if (path === "/api/v1/build" || path === "/api/v1/build/" || path === "/api/v1/install" || path === "/api/v1/install/") {
    return jsonBody(200, { commands: BUILD, requires: "macOS 14+ and Xcode command-line tools", cli: CLI_HINT });
  }
  if (path === "/api" || path === "/api/" || path === "/api/v1" || path === "/api/v1/") {
    return jsonBody(200, {
      name: "ezkey site API",
      version: "1.0.0",
      authentication: "none",
      sandbox: "This public API is the sandbox. No keys are issued.",
      openapi: `${ORIGIN}/openapi.json`,
      documentation: `${ORIGIN}/developers/`,
      endpoints: [
        { method: "GET", path: "/api/v1/health", operationId: "getHealth" },
        { method: "GET", path: "/api/v1/overview", operationId: "getOverview" },
        { method: "GET", path: "/api/v1/build", operationId: "getBuildInstructions" },
        { method: "GET", path: "/api/v1/install", operationId: "getInstall" },
        { method: "GET", path: "/api/v1/agent-brief", operationId: "getAgentBrief" },
        { method: "GET", path: "/api/v1/disclaimer", operationId: "getDisclaimer" },
        { method: "GET", path: "/api/v1/auth", operationId: "getAuth" },
        { method: "GET", path: "/api/v1/cli", operationId: "getCli" },
        { method: "GET", path: "/api/v1/version", operationId: "getVersion" },
        { method: "GET", path: "/api/v1/pages/{page}", operationId: "getPage" },
      ],
    });
  }
  if (path === "/api/v1/agent-brief" || path === "/api/v1/agent-brief/") {
    return jsonBody(200, agentBrief());
  }
  if (path === "/api/v1/disclaimer" || path === "/api/v1/disclaimer/") {
    return jsonBody(200, {
      disclaimer: DISCLAIMER,
      url: "https://github.com/edtadros/ezkey/blob/master/DISCLAIMER.md",
    });
  }
  if (path === "/api/v1/auth" || path === "/api/v1/auth/") {
    return jsonBody(200, {
      authentication: "none",
      api_keys: false,
      oauth: false,
      sandbox: true,
      note: "The public site API is the sandbox. Call it without Authorization. See https://ezkey.app/auth.md",
    });
  }
  if (path === "/api/v1/cli" || path === "/api/v1/cli/") {
    return jsonBody(200, {
      npm: CLI_HINT,
      homebrew_formula: "https://github.com/edtadros/ezkey/blob/master/Formula/ezkey.rb",
      note: "The CLI prints disclaimer and build steps. It does not access the Keychain.",
    });
  }
  if (path === "/api/v1/version" || path === "/api/v1/version/") {
    return jsonBody(200, {
      version: "1.0.0",
      api_version: API_VERSION,
      policy_url: `${ORIGIN}/versioning/`,
      deprecation: "No route is deprecated. Breaking changes require /api/v2 and RFC 9745 Deprecation/Sunset headers with at least 90 days of notice.",
    });
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
    const answer =
      text.includes("disclaim") || text.includes("warranty")
        ? DISCLAIMER
        : text.includes("build") || text.includes("install") || text.includes("clone")
          ? BUILD
          : JSON.stringify(agentBrief());
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

export async function handleRequest(request: Request, env: Env): Promise<Response> {
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
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    return handleRequest(request, env);
  },
};
