# Tetris — Godot 4

A complete Tetris built on Godot 4.7, organized across small single-responsibility scripts.

## Run

Open the project in the Godot editor (project root = this folder) and press **F5**, or run:

```sh
cd ~/ws/tetris
godot                       # launches the game
```

## Test

A headless functional test exercises the core logic (spawn, movement, rotation,
line-clear, scoring, game-over, and a full simulated game):

```sh
godot --headless --path . --script res://scripts/test_logic.gd
```

Expected: `RESULTS: 24 passed, 0 failed` → `ALL TESTS PASSED`.

## Features

- 7-bag randomizer, ghost piece, next-piece preview
- SRS-style rotation with wall/floor kicks
- Lock delay, soft drop, hard drop
- Scoring (line clears scale with level), level-up every 10 lines
- Pause, restart, game-over detection

## Controls

| Key | Action |
|---|---|
| ← / → | Move |
| ↑ / Z | Rotate clockwise / counter-clockwise |
| ↓ | Soft drop |
| Space | Hard drop |
| P / Esc | Pause / resume |
| R | Restart |

## Structure

- `project.godot` — project + display/window settings
- `scenes/main.tscn` — main scene
- `scripts/game.gd` — orchestrator: state machine, input, gravity/lock timers, 7-bag, scoring
- `scripts/game_constants.gd` — layout, shapes, colors, key codes, states (pure data)
- `scripts/piece.gd` — active piece: shape + position + rotation math
- `scripts/board.gd` — grid: collision checks, locking cells, line detection/clearing
- `scripts/renderer.gd` — all `_draw()`-based rendering (field, HUD, ghost, overlays)
- `scripts/test_logic.gd` — headless functional test (run via `--script`)
