import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const root = join(import.meta.dirname, "../..");

test("tracked tree has no secrets or personal data", () => {
  const out = execFileSync(join(root, "scripts/scan-public.sh"), {
    cwd: root,
    encoding: "utf8",
  });
  assert.match(out, /clean: no secrets or personal data/);
  assert.doesNotMatch(out, /^HIT /m);
});

test("gitignore blocks credential and local-state files", () => {
  const paths = [
    ".env",
    ".env.local",
    "secrets.pem",
    "cert.p12",
    "service-account.json",
    "app-credentials.json",
    ".wrangler/state.json",
    ".dev.vars",
    "build/ezkey.app",
    ".build",
    "node_modules/left-pad/index.js",
    "id_rsa",
    "id_dsa",
    "id_ecdsa",
    "id_ed25519",
    ".netrc",
    "production.env",
  ];
  const out = execFileSync("git", ["check-ignore", "-v", ...paths], {
    cwd: root,
    encoding: "utf8",
  });
  for (const path of paths) {
    assert.match(out, new RegExp(path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  }
});

test("classifier flags a second address and an OpenAI token outside the tree", () => {
  const dir = mkdtempSync(join(tmpdir(), "ezkey-scan-"));
  const file = join(dir, "fixture.txt");
  const allowed = "hello" + "@" + "ezkey.app";
  const personal = "edward" + "." + "tadros" + "@" + "proticom.com";
  const token = "sk-" + "proj-" + "a".repeat(32);
  writeFileSync(file, allowed + " " + personal + "\nOPENAI_API_KEY=" + token + "\n");
  const script = join(root, "scripts/scan-public.sh");
  let out = "";
  let code = 0;
  try {
    out = execFileSync(script, ["--extra", file], { cwd: root, encoding: "utf8" });
  } catch (err) {
    const failed = err as { status?: number; stdout?: string };
    code = failed.status ?? 1;
    out = failed.stdout ?? "";
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  assert.equal(code, 1);
  assert.match(out, /HIT email/);
  assert.equal(out.includes(personal), true);
  assert.match(out, /HIT secret/);
  assert.equal(out.includes(token), true);
});

test("user-facing copy never mentions Developer ID, notarization, or Gatekeeper", () => {
  let out = "";
  try {
    out = execFileSync(
      "git",
      ["grep", "-n", "-i", "-E", "developer id|notariz|gatekeeper", "--", "site", "src", "README.md", "SECURITY.md", "DISCLAIMER.md", "CONTRIBUTING.md", "RELEASING.md", "scripts/render_guides.py"],
      { cwd: root, encoding: "utf8" },
    );
  } catch (error) {
    if ((error as { status?: number }).status !== 1) throw error;
  }
  assert.equal(out, "");
});
