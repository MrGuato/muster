---
title: Security
nav_order: 8
---

# Security

Muster is a client addon: it runs inside your game and can only do what any addon can. It talks to the server through normal chat, the same lines you could type yourself. The full list is on the [Commands]({{ '/commands' | relative_url }}#what-muster-sends) page.

- It never reads or sends passwords or account data.
- It never downloads or runs code.
- It stores only its own settings, in `WTF/Account/<account>/SavedVariables/Muster.lua`.

Download Muster only from the [Releases page](https://github.com/MrGuato/muster/releases). Each release zip is built by the release workflow from the tagged commit, not uploaded by hand.

To report a security problem privately, use **Security → Report a vulnerability** on the [repository](https://github.com/MrGuato/muster/security). The full policy is in [SECURITY.md](https://github.com/MrGuato/muster/blob/main/SECURITY.md).
