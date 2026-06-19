#!/usr/bin/env node
/**
 * gen-docs.mjs — generador determinístico de documentación de referencia.
 *
 * Produce las secciones GENERATED de la taxonomía AutoWiki (By the Numbers,
 * mapa del repo, inventarios) a partir del código. Zero dependencias, salida
 * 100% determinística (sin fechas ni SHAs) para que el check de CI sea estable:
 * si el código cambió y nadie regeneró, `git diff --exit-code docs/reference` falla.
 *
 * Config por repo: `docs-gen.config.json` en la raíz (ver assets/docs-gen.config.example.json).
 * Uso: `node scripts/gen-docs.mjs`  (o `npm run docs:gen`)
 *
 * NO edites a mano los archivos de salida: se sobreescriben en cada corrida.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, extname, sep } from 'node:path';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const CONFIG_PATH = join(ROOT, 'docs-gen.config.json');
if (!existsSync(CONFIG_PATH)) {
  console.error('✗ Falta docs-gen.config.json en la raíz del repo (' + ROOT + ').');
  process.exit(1);
}
const cfg = JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
const exclude = new Set(cfg.exclude || ['node_modules', 'dist', 'build', 'coverage', '.next', '.turbo']);
const outDir = (cfg.outDir || 'docs/reference').split('/').join(sep);

const BANNER =
  '<!-- GENERADO por scripts/gen-docs.mjs — NO editar a mano. Regenerar: `npm run docs:gen` -->';

// ── Enumerar archivos TRACKEADOS por git ─────────────────────────────────────
// Determinístico entre entornos: ignora archivos no trackeados/gitignored, así
// CI (checkout limpio) y local dan el MISMO resultado sin importar el cruft local.
// Excluye además el outDir (no contar la salida generada) y la lista `exclude`.
function listTrackedFiles() {
  let out;
  try {
    out = execSync('git ls-files -z', { cwd: ROOT, maxBuffer: 256 * 1024 * 1024 }).toString('utf8');
  } catch {
    console.error('✗ No pude listar archivos con git (¿estás dentro de un repo git?).');
    process.exit(1);
  }
  const outPrefix = outDir.split(sep).join('/').replace(/\/+$/, '') + '/';
  return out.split('\0').filter(Boolean)
    .filter((rel) => !rel.startsWith(outPrefix))                  // no contar lo generado
    .filter((rel) => !rel.split('/').some((s) => exclude.has(s))) // exclude por segmento de path
    .map((rel) => rel.split('/').join(sep))
    .sort();
}
const files = listTrackedFiles();

// ── Helpers ─────────────────────────────────────────────────────────────────
const norm = (p) => p.split('/').join(sep);
const hasExt = (f, exts) => exts.includes(extname(f).toLowerCase());
const underRoot = (f, root) => f === norm(root) || f.startsWith(norm(root) + sep);
function lineCount(f) {
  try {
    const s = readFileSync(join(ROOT, f), 'utf8');
    return s.length === 0 ? 0 : s.split('\n').length;
  } catch { return 0; }
}
const fmt = (n) => n.toLocaleString('es-AR');

// ── By the Numbers ────────────────────────────────────────────────────────────
const locExts = cfg.loc?.exts || ['.ts', '.tsx', '.js', '.jsx', '.sql'];
const locExclude = new Set((cfg.loc?.excludeFiles || []).map(norm));
let loc = 0, locFiles = 0;
for (const f of files) {
  if (hasExt(f, locExts) && !locExclude.has(f)) { loc += lineCount(f); locFiles++; }
}
function countMetric(item) {
  if (item.type === 'ext') return files.filter((f) => hasExt(f, item.exts)).length;
  if (item.type === 'name-suffix') return files.filter((f) => item.suffixes.some((s) => f.endsWith(s))).length;
  if (item.type === 'filename') return files.filter((f) => f.split(sep).pop() === item.name).length;
  return 0;
}
const metrics = (cfg.byTheNumbers || []).map((m) => ({ label: m.label, value: countMetric(m) }));

let byNumbers = `---\nclase: reference\ngenerado: true\n---\n\n${BANNER}\n\n# By the Numbers — ${cfg.project || 'repo'}\n\n`;
byNumbers += `Métricas del codebase, computadas del árbol de archivos.\n\n| Métrica | Valor |\n|---|---:|\n`;
byNumbers += `| Líneas de código (${locExts.join(', ')}) | ${fmt(loc)} |\n`;
byNumbers += `| Archivos de código | ${fmt(locFiles)} |\n`;
byNumbers += `| Archivos totales (sin deps) | ${fmt(files.length)} |\n`;
for (const m of metrics) byNumbers += `| ${m.label} | ${fmt(m.value)} |\n`;

// ── Inventarios ───────────────────────────────────────────────────────────────
function buildInventory(inv) {
  if (inv.type === 'files') {
    const list = files
      .filter((f) => underRoot(f, inv.root) && (!inv.ext || extname(f).toLowerCase() === inv.ext))
      .map((f) => f.split(sep).pop())
      .sort();
    return { count: list.length, items: list };
  }
  if (inv.type === 'dirs') {
    const root = norm(inv.root);
    const set = new Set();
    for (const f of files) {
      if (f.startsWith(root + sep)) {
        const rest = f.slice(root.length + 1);
        if (rest.includes(sep)) set.add(rest.split(sep)[0]);
      }
    }
    return { count: set.size, items: [...set].sort() };
  }
  if (inv.type === 'grep') {
    const re = new RegExp(inv.pattern, 'gi');
    const scope = files.filter(
      (f) => (inv.roots || []).some((r) => underRoot(f, r)) && (!inv.ext || extname(f).toLowerCase() === inv.ext)
    );
    let total = 0, fileHits = 0;
    for (const f of scope) {
      const m = readFileSync(join(ROOT, f), 'utf8').match(re);
      if (m) { total += m.length; fileHits++; }
    }
    return { count: total, fileHits, scanned: scope.length };
  }
  if (inv.type === 'routes') {
    // Rutas reales de Next.js App Router (route.ts → URL), no el basename.
    const root = norm(inv.root);
    const items = [];
    for (const f of files) {
      const base = f.split(sep).pop();
      if (!/^route\.(ts|tsx|js|jsx)$/.test(base)) continue;
      if (!(f === root || f.startsWith(root + sep))) continue;
      const relDir = f.slice(root.length + 1).split(sep).slice(0, -1);
      if (relDir.some((s) => s.startsWith('_'))) continue;                              // carpetas privadas
      const segs = relDir.filter((s) => !(s.startsWith('(') && s.endsWith(')')));        // route groups no rutean
      const path = '/' + segs.join('/');
      const src = readFileSync(join(ROOT, f), 'utf8');
      const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS']
        .filter((mth) => new RegExp(`export\\s+(?:async\\s+function|const)\\s+${mth}\\b`).test(src));
      items.push(`\`${path}\`${methods.length ? ' — ' + methods.join(', ') : ''}`);
    }
    return { count: items.length, items: items.sort() };
  }
  if (inv.type === 'functions') {
    // Funciones SQL DISTINTAS (no ocurrencias DDL) + su COMMENT ON FUNCTION.
    // Filtro opcional por schema (ej. "api") → catálogo de RPCs para agentes.
    // Las FIRMAS/params NO se documentan acá: viven en el OpenAPI vivo de PostgREST.
    const scope = files.filter((f) => (inv.roots || []).some((r) => underRoot(f, r)) && extname(f).toLowerCase() === '.sql');
    const defRe = /create\s+(?:or\s+replace\s+)?function\s+(?:"?([a-z0-9_]+)"?\.)?"?([a-z0-9_]+)"?\s*\(/gi;
    const comRe = /comment\s+on\s+function\s+(?:"?([a-z0-9_]+)"?\.)?"?([a-z0-9_]+)"?\s*\([^;]*?\)\s+is\s+(?:\$([a-z0-9_]*)\$([\s\S]*?)\$\3\$|'((?:[^']|'')*)')/gi;
    const names = new Set();
    const comments = new Map();
    for (const f of scope) {
      const s = readFileSync(join(ROOT, f), 'utf8');
      let m;
      while ((m = defRe.exec(s))) {
        const sch = m[1] || null, nm = m[2];
        if (inv.schema && sch !== inv.schema) continue;
        if (!inv.schema && sch === 'pg_catalog') continue;
        names.add((sch ? sch + '.' : '') + nm);
      }
      let c;
      while ((c = comRe.exec(s))) {
        const sch = c[1] || null, nm = c[2];
        const txt = (c[4] ?? c[5] ?? '').replace(/''/g, "'").trim().split('\n')[0].slice(0, 160);
        if (txt) { comments.set((sch ? sch + '.' : '') + nm, txt); comments.set(nm, txt); }
      }
    }
    const items = [...names].sort().map((k) => {
      const com = comments.get(k) || comments.get(k.includes('.') ? k.split('.').pop() : k);
      return `\`${k}\`${com ? ' — ' + com : ''}`;
    });
    return { count: items.length, items };
  }
  return { count: 0, items: [] };
}

let invDoc = `---\nclase: reference\ngenerado: true\n---\n\n${BANNER}\n\n# Inventarios — ${cfg.project || 'repo'}\n\n`;
invDoc += `Inventarios derivados del código. Cada conteo traza a archivos reales del repo.\n\n`;
for (const inv of cfg.inventories || []) {
  const r = buildInventory(inv);
  invDoc += `## ${inv.title}\n\n`;
  if (inv.type === 'grep') {
    invDoc += `**${fmt(r.count)}** coincidencias en ${fmt(r.fileHits)} de ${fmt(r.scanned)} archivos escaneados.\n\n`;
  } else {
    const label = inv.type === 'dirs' ? 'directorios'
      : inv.type === 'routes' ? 'rutas'
      : inv.type === 'functions' ? 'funciones (únicas)'
      : 'archivos';
    invDoc += `**${fmt(r.count)}** ${label}.\n\n`;
    const raw = inv.type === 'routes' || inv.type === 'functions'; // items ya vienen formateados
    const cap = inv.limit ?? 200;
    const shown = r.items.slice(0, cap);
    if (shown.length) invDoc += shown.map((i) => (raw ? `- ${i}` : `- \`${i}\``)).join('\n') + '\n';
    if (r.items.length > cap) invDoc += `\n_… +${fmt(r.items.length - cap)} más._\n`;
    invDoc += '\n';
  }
}

// ── Mapa del repo ─────────────────────────────────────────────────────────────
const describe = (cfg.repoMap?.describe) || {};
const topCounts = new Map();
for (const f of files) {
  const parts = f.split(sep);
  if (parts.length > 1) topCounts.set(parts[0], (topCounts.get(parts[0]) || 0) + 1);
}
let mapDoc = `---\nclase: reference\ngenerado: true\n---\n\n${BANNER}\n\n# Mapa del repo — ${cfg.project || 'repo'}\n\n`;
mapDoc += `Directorios de primer nivel, con conteo de archivos y qué vas a encontrar.\n\n`;
mapDoc += `| Directorio | Archivos | Qué contiene |\n|---|---:|---|\n`;
for (const [dir, n] of [...topCounts.entries()].sort((a, b) => (a[0] < b[0] ? -1 : 1))) {
  mapDoc += `| \`${dir}/\` | ${fmt(n)} | ${describe[dir] || '—'} |\n`;
}

// ── Índice ────────────────────────────────────────────────────────────────────
const indexDoc = `---\nclase: reference\ngenerado: true\n---\n\n${BANNER}\n\n# Referencia generada — ${cfg.project || 'repo'}\n\n` +
  `Estas páginas son **GENERATED** (clase \`reference\`): se computan del código con \`scripts/gen-docs.mjs\`.\n` +
  `**No las edites a mano** — se sobreescriben. Para refrescarlas: \`npm run docs:gen\`.\n\n` +
  `- [By the Numbers](by-the-numbers.md) — métricas del codebase\n` +
  `- [Mapa del repo](repo-map.md) — directorios de primer nivel\n` +
  `- [Inventarios](inventories.md) — funciones, migraciones, edge functions, rutas\n\n` +
  `> El *por qué* (arquitectura, decisiones) es AUTHORED y vive en \`docs/\`. Acá solo va el *qué hay*.\n`;

// ── Escribir ──────────────────────────────────────────────────────────────────
mkdirSync(join(ROOT, outDir), { recursive: true });
const out = (name, body) => writeFileSync(join(ROOT, outDir, name), body.replace(/\n+$/, '') + '\n', 'utf8');
out('README.md', indexDoc);
out('by-the-numbers.md', byNumbers);
out('inventories.md', invDoc);
out('repo-map.md', mapDoc);

console.log(`✓ docs/reference regenerado: ${fmt(files.length)} archivos analizados, ${fmt(loc)} LOC.`);
console.log(`  → ${outDir}/{README,by-the-numbers,inventories,repo-map}.md`);
