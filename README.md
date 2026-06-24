# Rowbase Skills

Reusable agent skills for Gabe / Rowbase — writing, proposals, and copy.

Works with **OpenClaw** (`npx skills`) and **Claude Code** (plugin marketplace).

## Skills in this repo

| Skill | What it does |
| --- | --- |
| `writing-style` | Spoken, direct, low-fluff prose. Write like you talk; cut anything that sounds AI-generated. |
| `rowbase-proposal-style` | Warm, persuasive, specific writing for proposals, exec comms, and client-facing business writing. |
| `ogilvy-copywriting` | David Ogilvy's advertising principles for copy that sells (MIT, attributed). |

## Install on OpenClaw

```bash
# All skills in this repo, installed globally:
npx skills add gabehrwitz/rowbase-skills -g --all --full-depth

# Or one skill:
npx skills add gabehrwitz/rowbase-skills -g -s writing-style --full-depth
```

## Install in Claude Code

```bash
/plugin marketplace add gabehrwitz/rowbase-skills
/plugin install rowbase-skills@rowbase-skills
```

Or just clone the `skills/*` folders into `~/.claude/skills/`.

## External skills

This repo does **not** vendor third-party skills that lack a redistribution
license. See [`EXTERNAL_SKILLS.md`](EXTERNAL_SKILLS.md) for the Gooseworks GTM
skills we use and how to install them from source in one command.

## Conventions

- Each skill lives in `skills/<skill-name>/SKILL.md` with `name` + `description`
  frontmatter.
- Skills capture reusable voice and method only — no client names, pricing, or
  internal specifics (this repo is public).
