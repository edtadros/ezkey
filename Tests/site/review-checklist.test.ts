import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

const root = join(import.meta.dirname, "../..");
const skill = readFileSync(join(root, "site/.well-known/agent-skills/build-ezkey/SKILL.md"), "utf8");

// Agents run these commands against a release tag. If the code drifts from
// what the skill promises, CI fails here instead of an agent reporting a
// false finding (or a false pass).
const expectedFiles: Record<number, string[]> = {
  1: [],
  2: [],
  3: ["Sources/ezkey/EZKeyMain.swift"],
  4: ["Sources/ezkey/EZKeyMain.swift", "Sources/ezkey/MarketingRender.swift"],
  5: ["Sources/EZKeyCore/LoginKeychainStore.swift"],
  6: [],
};

function reviewCommands(): Map<number, string> {
  const block = skill.split("## 3. Review before building")[1].split("```")[1];
  const commands = new Map<number, string>();
  const lines = block.trim().split("\n");
  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(/^# (\d+)\. /);
    if (match) commands.set(Number(match[1]), lines[i + 1]);
  }
  return commands;
}

function run(command: string): string[] {
  try {
    return execFileSync("bash", ["-c", command], { cwd: root, encoding: "utf8" }).trim().split("\n").filter(Boolean);
  } catch (error) {
    const status = (error as { status?: number }).status;
    if (status === 1) return [];
    throw error;
  }
}

test("skill lists exactly the six review commands", () => {
  assert.deepEqual([...reviewCommands().keys()], [1, 2, 3, 4, 5, 6]);
});

test("review commands produce what the skill says they produce", () => {
  for (const [n, command] of reviewCommands()) {
    const files = [...new Set(run(command).map((line) => line.split(":")[0]))].sort();
    assert.deepEqual(files, expectedFiles[n], `check ${n}: ${command}`);
  }
});

test("check 3 has exactly one hit and check 5 uses only the five listed calls", () => {
  const commands = reviewCommands();
  assert.equal(run(commands.get(3)!).length, 1);
  const calls = new Set(run(commands.get(5)!).map((line) => line.split(":").pop()));
  assert.deepEqual([...calls].sort(), ["SecItemAdd(", "SecItemCopyMatching(", "SecItemDelete(", "SecItemUpdate(", "SecKeychainOpen("]);
});

test("agent-skills index digest matches SKILL.md, and the flat copy is identical", async () => {
  const { createHash } = await import("node:crypto");
  const index = JSON.parse(readFileSync(join(root, "site/.well-known/agent-skills/index.json"), "utf8"));
  const digest = "sha256:" + createHash("sha256").update(skill).digest("hex");
  assert.equal(index.skills[0].digest, digest);
  assert.equal(readFileSync(join(root, "site/.well-known/agent-skills/build-ezkey.md"), "utf8"), skill);
});
