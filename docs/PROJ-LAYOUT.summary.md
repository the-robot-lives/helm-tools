# Project Layout — Summary

```
helm-utils/
├── bin/                        # Executables → ~/.local/bin
│   ├── helm-upgrade            #   Tiered upgrade w/ change detection
│   ├── helm-rollback           #   Reverse-tier rollback
│   └── helm-publish            #   OCI chart publish
├── docs/                       # PROJ-ARCH + PROJ-LAYOUT (+ summaries)
├── .gitignore                  # swap files, .env, .envrc.local
├── Makefile                    # make install
└── README.md                   # Start here
```
