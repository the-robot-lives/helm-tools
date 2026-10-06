# Project Layout — Summary

```
helm-utils/
├── bin/                        # Executables → ~/.local/bin
│   ├── helm-upgrade            #   Tiered upgrade w/ change detection
│   ├── helm-rollback           #   Reverse-tier rollback
│   └── helm-publish            #   OCI chart publish
├── completions/                # bash + zsh completions (installed by make install)
├── docs/                       # PROJ-ARCH, PROJ-LAYOUT, PROJ-SCHEMA, PROJ-HOWTO, PROJ-FAQ, THREAT-MODEL (+ summaries), howto/ guides
├── .gitignore                  # swap files, .DS_Store, .env, .envrc.local, .claude/worktrees/
├── AGENT.md / AGENTS.md        # agent guidance (kept aligned)
├── CHANGELOG.md                # Release history
├── CLAUDE.md                   # Claude Code guidance
├── Makefile                    # make install (bin + completions)
├── README.md                   # Start here
└── merge-notes.md              # Historical merge working notes
```

Runtime state: `.helm-state/` created in the working directory of the repo being deployed (checksums + publish markers); not tracked here.
