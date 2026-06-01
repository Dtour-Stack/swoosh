# Swoosh — Product Requirements Document

## Target user

Swift/Mac developers who want a local-first, permissioned agent that understands their environment.

## Product Promise

> Swoosh is a permissioned, local-first Mac agent that learns your environment during setup and turns that into useful memory and workflows.

## Setup flow

```
Install Swoosh
→ choose personalization depth (minimal / recommended / deep)
→ grant selected permissions
→ scan apps / files / calendar / dev environment
→ generate memory candidates
→ user approves / rejects / edits memories
→ produce personal setup report
→ run first useful personalized task
→ offer "Make this repeatable"
```

## First task

"Create a playable Cartridge starter and a test plan for my local game."

Output: project starter, provider route, CLI driver, asset plan, playtest checklist, and first generated character/content pack.

## Product Surface

Swoosh ships the Cartridge game harness spine and keeps adjacent capabilities visible only when they support game creation, testing, playing, provider routing, plugins, or local laptop/game control.

## Success criteria

- [ ] Swoosh CLI `setup quick` completes end-to-end
- [ ] Cartridge game CLI starter generation completes end-to-end
- [ ] Local game URL loading creates an inspectable session
- [ ] NitroGen, provider LLM, hybrid, and scripted policies are selectable
- [ ] 2D/3D asset provider catalogs are queryable by the agent
- [ ] Setup report generated and saved
- [ ] `swoosh doctor` reports system health
- [ ] Audit log records all scan/memory/permission actions
- [ ] First personalized agent task runs using approved memories
- [ ] `swooshd` serves bearer-gated chat to the iOS client over LAN
- [ ] Skills can be installed, reviewed, searched, and loaded with support files
- [ ] Cron jobs can be created, paused, resumed, run, and audited
- [ ] Terminal backend options can be listed and configured
- [ ] Chat SDK platform and state adapters can be toggled on or off
