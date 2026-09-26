import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { handleRequest } from "../../src/worker.ts";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");

function mockEnv(files: Record<string, { body: string; type?: string; status?: number }>) {
  return {
    ASSETS: {
      async fetch(request: Request): Promise<Response> {
        const url = new URL(request.url);
        const path = url.pathname;
        const hit = files[path];
        if (!hit) return new Response("missing " + path, { status: 404, headers: { "Content-Type": "text/plain" } });
        return new Response(hit.body, {
          status: hit.status ?? 200,
          headers: { "Content-Type": hit.type ?? "text/plain" },
        });
      },
    },
  };
}

const env = mockEnv({
  "/index.md": { body: "# ezkey\n", type: "text/markdown" },
  "/developers.md": { body: "# Developers\n", type: "text/markdown" },
  "/cli.md": { body: "# CLI\n", type: "text/markdown" },
  "/disclaimer.md": { body: "# Disclaimer\n", type: "text/markdown" },
});

test("markdown 404 has recovery links", async () => {
  const res = await handleRequest(
    new Request("https://ezkey.app/__no-such-path", { headers: { Accept: "text/markdown" } }),
    env
  );
  assert.equal(res.status, 404);
  assert.match(res.headers.get("Content-Type") ?? "", /text\/markdown/);
  const body = await res.text();
  assert.ok(body.length > 20);
  assert.match(body, /llms\.txt/);
});

test("json 404 is RFC 9457 problem details", async () => {
  const res = await handleRequest(
    new Request("https://ezkey.app/__no-such-path", { headers: { Accept: "application/json" } }),
    env
  );
  assert.equal(res.status, 404);
  assert.match(res.headers.get("Content-Type") ?? "", /problem\+json/);
  const body = (await res.json()) as { code: string; resolution: string; detail: string };
  assert.equal(body.code, "not_found");
  assert.match(body.resolution, /llms\.txt/);
  assert.ok(body.detail.length > 8);
});

test("agent-brief includes repo, disclaimer, and build commands", async () => {
  const res = await handleRequest(new Request("https://ezkey.app/api/v1/agent-brief"), env);
  assert.equal(res.status, 200);
  const body = (await res.json()) as {
    repository: string;
    disclaimer: string;
    install: { commands: string };
    present_to_user: string[];
  };
  assert.equal(body.repository, "https://github.com/edtadros/ezkey");
  assert.match(body.disclaimer, /no warranty/i);
  assert.match(body.install.commands, /install\.sh/);
  assert.match(body.install.commands, /\/Applications\/ezkey\.app/);
  assert.ok(body.present_to_user.length >= 3);
});

test("GET /api/v1 is a catalog", async () => {
  const res = await handleRequest(new Request("https://ezkey.app/api/v1"), env);
  assert.equal(res.status, 200);
  const body = (await res.json()) as { authentication: string; endpoints: Array<{ operationId: string }> };
  assert.equal(body.authentication, "none");
  const ids = body.endpoints.map((e) => e.operationId);
  assert.ok(ids.includes("getAgentBrief"));
});

test("auth endpoint says no keys", async () => {
  const res = await handleRequest(new Request("https://ezkey.app/api/v1/auth"), env);
  const body = (await res.json()) as { api_keys: boolean; sandbox: boolean };
  assert.equal(body.api_keys, false);
  assert.equal(body.sandbox, true);
});

test("MCP get_agent_brief", async () => {
  const res = await handleRequest(
    new Request("https://ezkey.app/mcp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "get_agent_brief" } }),
    }),
    env
  );
  const body = (await res.json()) as { result: { content: Array<{ text: string }>; isError: boolean } };
  assert.equal(body.result.isError, false);
  assert.match(body.result.content[0].text, /edtadros\/ezkey/);
});

test("OpenAPI operations have operationId and Problem 4xx/5xx", () => {
  const spec = JSON.parse(readFileSync(join(root, "site/openapi.json"), "utf8"));
  for (const [path, item] of Object.entries(spec.paths as Record<string, { get?: { operationId?: string; responses?: Record<string, unknown> } }>)) {
    const get = item.get;
    assert.ok(get?.operationId, path);
    for (const code of ["400", "404", "429", "500"]) {
      assert.ok(get?.responses?.[code], `${path} missing ${code}`);
    }
  }
});

test("CLI binary prints disclaimer and clone command", async () => {
  const { execFileSync } = await import("node:child_process");
  const out = execFileSync(process.execPath, [join(root, "cli/ezkey.mjs")], { encoding: "utf8" });
  assert.match(out, /DISCLAIMER|no warranty/i);
  assert.match(out, /install\.sh/);
  assert.match(out, /\/Applications/);
  assert.match(out, /github.com\/edtadros\/ezkey/);
});

test("every response carries the security headers", async () => {
  const requests = [
    new Request("https://ezkey.app/index.md"),
    new Request("https://ezkey.app/api/v1/overview"),
    new Request("https://ezkey.app/__no-such-path", { headers: { Accept: "application/json" } }),
  ];
  for (const request of requests) {
    const res = await handleRequest(request, env);
    assert.equal(res.headers.get("X-Content-Type-Options"), "nosniff", request.url);
    assert.equal(res.headers.get("X-Frame-Options"), "DENY", request.url);
    assert.equal(res.headers.get("Referrer-Policy"), "no-referrer", request.url);
    assert.equal(res.headers.get("Permissions-Policy"), "camera=(), microphone=(), geolocation=()", request.url);
  }
});

test("inherited object keys are unknown pages, not 500s", async () => {
  for (const page of ["constructor", "__proto__", "toString"]) {
    const rest = await handleRequest(new Request(`https://ezkey.app/api/v1/pages/${page}`), env);
    assert.equal(rest.status, 404, page);
    const mcp = await handleRequest(
      new Request("https://ezkey.app/mcp", {
        method: "POST",
        body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "get_page", arguments: { page } } }),
      }),
      env
    );
    const body = (await mcp.json()) as { result: { isError: boolean; content: { text: string }[] } };
    assert.equal(body.result.isError, true, page);
    assert.match(body.result.content[0].text, /^Unknown page/, page);
  }
});
