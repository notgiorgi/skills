# Skills

Personal agent skills.

## Install

Just this repo's skills:

```bash
npx skills add notgiorgi/skills -g
```

Everything I use on a new machine (this repo + external skills + global agent instructions):

```bash
git clone git@github.com:notgiorgi/skills.git ~/develop/skills && ~/develop/skills/install.sh
```

- `install.sh` is the source of truth for external skills. Add new ones there.
- `global/AGENTS.md` is the global instruction file, symlinked to `~/.agents/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`. Edit it in the repo.
