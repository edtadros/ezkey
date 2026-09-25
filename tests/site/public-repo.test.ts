import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { join } from "node:path";
import test from "node:test";

const root = join(import.meta.dirname, "../..");

test("tracked tree has no secrets or personal data", () => {
  const out = execFileSync("zsh", [join(root, "scripts/scan-public.sh")], {
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
  ];
  const out = execFileSync("git", ["check-ignore", "-v", ...paths], {
    cwd: root,
    encoding: "utf8",
  });
  for (const path of paths) {
    assert.match(out, new RegExp(path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  }
});
