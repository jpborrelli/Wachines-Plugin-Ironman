#!/usr/bin/env node
// release-bump.mjs — bump del plugin derivado de Conventional Commits.
//
// Lee los commits desde el último tag `wachines-skills--v*`, decide el bump
// (feat → minor, fix → patch, BREAKING/`!` → major), actualiza la `version` en
// `.claude-plugin/plugin.json` y prepende una entrada al `CHANGELOG.md`.
//
// Sin dependencias (solo Node + git). Idempotente: si no hay commits relevantes
// desde el último tag, no hace nada (exit 0, sin output de versión).
//
// Uso:
//   node bin/release-bump.mjs            # aplica el bump (escribe archivos)
//   node bin/release-bump.mjs --dry-run  # solo reporta qué haría
//
// En CI escribe `version=X.Y.Z` y `bumped=true|false` a $GITHUB_OUTPUT.

import { execSync } from "node:child_process";
import { readFileSync, writeFileSync, appendFileSync } from "node:fs";

const DRY = process.argv.includes("--dry-run");
const TAG_PREFIX = "wachines-skills--v";
const PLUGIN_JSON = ".claude-plugin/plugin.json";
const CHANGELOG = "CHANGELOG.md";

const sh = (cmd) => execSync(cmd, { encoding: "utf8" }).trim();
const shOk = (cmd) => { try { return sh(cmd); } catch { return ""; } };

// 1. Último tag de release (si existe).
const lastTag = shOk(`git tag --list '${TAG_PREFIX}*' --sort=-v:refname`).split("\n")[0] || "";
const baseVersion = lastTag ? lastTag.slice(TAG_PREFIX.length) : null;

// 2. Commits desde ese tag (o todos si es el primer release).
const range = lastTag ? `${lastTag}..HEAD` : "HEAD";
const log = shOk(`git log ${range} --format=%s%x00%b%x1e`);
const commits = log
  .split("\x1e")
  .map((c) => c.trim())
  .filter(Boolean)
  .map((c) => {
    const [subject, body = ""] = c.split("\x00");
    return { subject: subject.trim(), body: body.trim() };
  })
  // Ignorá los commits que genera este mismo workflow.
  .filter((c) => !/\[skip release\]/i.test(c.subject) && !/^chore\(release\)/i.test(c.subject));

const out = (k, v) => {
  if (process.env.GITHUB_OUTPUT) appendFileSync(process.env.GITHUB_OUTPUT, `${k}=${v}\n`);
};

// 3. Primer run (sin tag previo): fijá el baseline al `version` actual y salí.
//    Así el primer bump real ocurre en el próximo merge, sin sorpresas.
const pluginRaw = readFileSync(PLUGIN_JSON, "utf8");
const plugin = JSON.parse(pluginRaw);
const currentVersion = plugin.version;

if (!lastTag) {
  console.log(`Sin tag previo → fijo baseline en v${currentVersion} (no bump este run).`);
  out("bumped", "false");
  out("version", currentVersion);
  out("baseline", "true");
  process.exit(0);
}

if (commits.length === 0) {
  console.log("No hay commits relevantes desde el último tag → no-op.");
  out("bumped", "false");
  out("version", baseVersion);
  process.exit(0);
}

// 4. Derivá el tipo de bump del peso máximo entre los commits.
const isBreaking = (c) =>
  /!:/.test(c.subject.split(":")[0] + ":") || /^BREAKING CHANGE/im.test(c.body);
const isFeat = (c) => /^feat(\(|!|:)/i.test(c.subject);

let bump = "patch";
if (commits.some(isBreaking)) bump = "major";
else if (commits.some(isFeat)) bump = "minor";

const [maj, min, pat] = baseVersion.split(".").map(Number);
const next =
  bump === "major" ? `${maj + 1}.0.0` : bump === "minor" ? `${maj}.${min + 1}.0` : `${maj}.${min}.${pat + 1}`;

console.log(`Bump ${bump}: v${baseVersion} → v${next} (${commits.length} commit/s)`);
out("bumped", "true");
out("version", next);
out("bump", bump);

if (DRY) {
  console.log("\n--dry-run: no escribo archivos. Commits considerados:");
  commits.forEach((c) => console.log(`  • ${c.subject}`));
  process.exit(0);
}

// 5. Escribí plugin.json (preservando el formato de 2 espacios).
plugin.version = next;
writeFileSync(PLUGIN_JSON, JSON.stringify(plugin, null, 2) + "\n");

// 6. Prependé la entrada al CHANGELOG bajo el header.
const date = new Date().toISOString().slice(0, 10);
const bullets = commits.map((c) => `- ${c.subject}`).join("\n");
const entry = `## ${next} — ${date}\n\n${bullets}\n\n`;
const changelog = readFileSync(CHANGELOG, "utf8");
// Inserta después del primer bloque de encabezado (primera línea en blanco tras el intro).
const marker = changelog.indexOf("\n## ");
const insertAt = marker === -1 ? changelog.length : marker + 1;
const updated = changelog.slice(0, insertAt) + entry + changelog.slice(insertAt);
writeFileSync(CHANGELOG, updated);

console.log(`Escrito plugin.json v${next} + CHANGELOG.`);
