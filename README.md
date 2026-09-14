# Tetris — Godot 4

A complete, single-file Tetris built on Godot 4.7.

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
- `scripts/game.gd` — entire game (logic + rendering, all `_draw()`-based)
- `scripts/test_logic.gd` — headless functional test (run via `--script`)
