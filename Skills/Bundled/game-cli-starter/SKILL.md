---
name: game-cli-starter
description: Create a voice/text driven CLI starter for a Cartridge game agent, character, or local game harness session.
category: gaming
tags:
  - cartridge
  - cli
  - game
  - voice
triggerPatterns:
  - game cli
  - voice prompt
  - create game agent cli
  - local game harness
platforms:
  - macOS
metadata:
  hermes:
    requires_toolsets:
      - game
      - files
---

# Game CLI Starter

Use this when a user wants Cartridge to create a command-line entrypoint for a game, character, playtester, or harness session.

1. Confirm the target game surface: local URL, project folder, engine integration, or generated prototype.
2. Use `game.list_cli_starters` to pick the closest starter: Three.js/WebGPU, Unity, Unreal, Roblox, Minecraft, Blender/3D, or generic automation.
3. Use `game.init_cli_starter` when an output directory is approved.
4. Include both text and voice prompt modes when the starter supports them.
5. Add commands for loading a local URL, recording observations, recording actions, generating content, and evaluating the session.
6. Keep laptop navigation behind explicit permissions: screen capture needs `gameCaptureEnabled`; input dispatch needs `autonomousGameControlEnabled`.

The resulting CLI should make the first run obvious: configure provider, load game, start observation, then execute a bounded playtest or generation task.
