# Security policy

## Reporting a problem

Please don't open a public issue for a security problem. Use GitHub's private reporting instead: **Security → Report a vulnerability** on this repo. I'll reply within a week and credit you in the release notes if you'd like.

Useful things to include: what you found, how to reproduce it, and which Muster version you tested.

## What's covered

- The addon in `Muster/` and the release zips published on this repo's Releases page.
- The GitHub Actions workflows and the scripts in `scripts/`.

The game client is Blizzard's software, and the server side is AzerothCore and mod-playerbots. Problems there go to those projects.

## Supported versions

| Version | Supported |
| ------- | --------- |
| 0.1.x   | ✅ |

## How the project keeps itself safe

- Muster only talks to the server through normal chat: `.playerbot bot ...` commands, party/raid chat and whispers to your own bots. It never reads or sends passwords, never loads code from anywhere, and stores nothing but its own settings in `WTF/.../SavedVariables/Muster.lua`.
- Download releases from this repo only. Each release zip is built by the release workflow from the tagged commit, not uploaded by hand.
- Every push and pull request runs luacheck, the test suite, CodeQL, gitleaks (secret scanning) and Trivy. Findings go to the repo's code scanning page.
- Dependabot opens weekly updates for the GitHub Actions the workflows use.
