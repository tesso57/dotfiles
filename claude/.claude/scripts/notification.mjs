#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";
import os from "node:os";

try {
  const input = JSON.parse(readFileSync(0, "utf8"));
  if (!input.transcript_path) process.exit(0);
  const home = os.homedir();
  const allowedBase = path.join(home, ".claude", "projects");
  let p = path.resolve(input.transcript_path.replace(/^~\//, `${home}/`));
  if (!p.startsWith(allowedBase + path.sep)) process.exit(1);
  const last = readFileSync(p, "utf8").trim().split(/\r?\n/).at(-1);
  if (!last) process.exit(0);
  const msg = JSON.parse(last).message.content[0].input.description ?? "unknown";
  if (!msg) process.exit(0);
  execFileSync(
    "osascript",
    [
      "-e",
      `on run argv\n         display notification (item 2 of argv) with title (item 1 of argv)\n       end run`,
      "Claude Code",
      msg.replace(/[\r\n]+/g, " ").replace(/"/g, "'").slice(0, 250),
    ],
    { stdio: "inherit" }
  );
} catch {
  process.exit(1);
}
