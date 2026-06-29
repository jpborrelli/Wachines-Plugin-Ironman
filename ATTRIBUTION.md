# Attribution & Third-Party Licenses

This repository bundles skills authored by third parties. Each is redistributed under its
own license, which permits redistribution with attribution. Original authorship and
licenses are preserved below and in each skill's frontmatter.

## Bundled (vendored) skills

| Skill | Author | License | Source |
|-------|--------|---------|--------|
| `supabase-postgres-best-practices` | Supabase | MIT | [supabase/agent-skills](https://github.com/supabase/agent-skills) |
| `vercel-react-best-practices` | Vercel | MIT | Vercel Engineering agent skills |
| `web-design-guidelines` | Vercel | MIT | [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) (the skill fetches the live guidelines at run time) |
| `next-best-practices` | Compiled from the official [Next.js documentation](https://nextjs.org/docs) and community best practices | MIT (this compilation) | — |
| `frontend-design` | Anthropic, PBC | Apache-2.0 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) — redistributed **unmodified**; the original `LICENSE.txt` is included in the skill folder |
| `eve` | Vercel | Apache-2.0 | [vercel/eve](https://github.com/vercel/eve) — pointer skill that defers to the package's version-locked `node_modules/eve/docs`; only `metadata`/`license` frontmatter added, body unmodified |

## First-party skills & agents

| Item | Author | License |
|------|--------|---------|
| `db-reviewer` (skill + agent) | Perennia-Regeneracion | MIT |
| `docs-architect` (skill + agent) | Perennia-Regeneracion | MIT |
| `security-reviewer` (skill + agent) | Perennia-Regeneracion | MIT |
| `tanstack-query-hooks` (skill) | Perennia-Regeneracion | MIT |
| `html-perennia` (skill) | Perennia-Regeneracion | MIT |
| `agent-readiness` (skill) | Perennia-Regeneracion | MIT — methodology © [Factory.ai](https://factory.ai/news/agent-readiness) (Agent Readiness), credited in-skill; scanner is original |

Most were generalized from internal tools — references to private domains, table names, people,
and infrastructure were removed so they are reusable in any project. `html-perennia` is the one
deliberately **opinionated** skill: it keeps the Perennia brand palette and typography on
purpose (that's its whole point), but internal URLs, repo paths, and team names were stripped.
`db-reviewer` and `docs-architect` additionally ship an explicit, opt-in Perennia BackOffice
overlay under their `references/` folder (architecture names only, no secrets). `db-reviewer` and
`docs-architect` additionally ship an explicit, opt-in Perennia BackOffice overlay under their
`references/` folder (architecture names only, no secrets) so the team can use them in that
repo with zero configuration.

## Referenced, NOT bundled

### gstack

[gstack](https://github.com/gstack) (by Garry Tan, MIT) is **not** vendored in this repo.
Although its license permits redistribution, its skills (`browse`, `qa`, `ship`, `review`,
`investigate`, `plan-*`, `office-hours`, `codex`, `context-save/restore`, etc.) are **not
standalone** — they depend on the gstack runtime (the `gstack` binaries, the browse daemon,
its TypeScript sources). Copying only the `SKILL.md` files would produce broken skills.

Install gstack directly instead — see the README for instructions. This repo intentionally
does not redistribute it.

### Kapso (WhatsApp)

Kapso's WhatsApp skills (`integrate-whatsapp`, `automate-whatsapp`, `observe-whatsapp`) live
in [gokapso/agent-skills](https://github.com/gokapso/agent-skills) and are **not** vendored
here. They require a Kapso account + API key and are maintained upstream — install them from
the source with `npx skills add gokapso/agent-skills`. (No license is declared on that repo,
which is an additional reason not to redistribute it.)

### Chat SDK (Vercel)

Vercel's Chat SDK skill (`chat-sdk`) lives in [vercel/chat](https://github.com/vercel/chat)
(MIT). It is **not** vendored here: the skill is a thin pointer to docs and resources that ship
inside the `chat` npm package (`node_modules/chat/…`), so copying only the `SKILL.md` would
leave a skill whose references don't resolve. Install it from the source with
`npx skills add vercel/chat` — maintained upstream, stays in sync with the package.
