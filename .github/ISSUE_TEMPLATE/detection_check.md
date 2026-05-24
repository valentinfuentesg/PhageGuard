---
name: New detection check
about: Propose a new read-only triage check (Phase 1 = Linux)
title: "[check] <short description>"
labels: ["enhancement", "good first issue"]
---

## Category

<!-- inventory | network | persistence | integrity | recent_changes | suid | ... -->

## What it detects

<!-- One or two sentences. What signal does this surface? -->

## What's normal vs suspicious

<!-- This becomes the entry in references/linux_indicators.md -->

## Tools required

<!-- Must already be in docs/dependencies.md, or note that a new dependency is needed (requires discussion). -->

## Checklist

- [ ] Read-only (no system changes)
- [ ] No network calls
- [ ] Emits JSON to stdout
- [ ] Stays within Phase 1 (Linux) scope
