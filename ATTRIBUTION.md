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

## First-party skills & agents

| Item | Author | License |
|------|--------|---------|
| `db-reviewer` (skill + agent) | perennia-regen | MIT |
| `docs-architect` (skill + agent) | perennia-regen | MIT |

These two were generalized from project-specific internal tools — all references to private
domains, table names, and infrastructure were removed so they are reusable in any project.

## Referenced, NOT bundled

### gstack

[gstack](https://github.com/gstack) (by Garry Tan, MIT) is **not** vendored in this repo.
Although its license permits redistribution, its skills (`browse`, `qa`, `ship`, `review`,
`investigate`, `plan-*`, `office-hours`, `codex`, `context-save/restore`, etc.) are **not
standalone** — they depend on the gstack runtime (the `gstack` binaries, the browse daemon,
its TypeScript sources). Copying only the `SKILL.md` files would produce broken skills.

Install gstack directly instead — see the README for instructions. This repo intentionally
does not redistribute it.
