class_name GameConstants
extends RefCounted
## Static configuration for the Tetris game: layout, shapes, colors, keys.
## Pure data — no behavior lives here.

# --- Layout -------------------------------------------------------------

const COLS := 10
const ROWS := 20
const CELL := 32.0
const ORIGIN := Vector2(120.0, 60.0)
const FIELD_W := COLS * CELL
const FIELD_H := ROWS * CELL
const WIN_W := 560.0
const WIN_H := 760.0

# --- Pieces -------------------------------------------------------------

const PIECE_NAMES := ["I", "O", "T", "S", "Z", "J", "L"]

const SHAPES := {
	"I": [[0, 1], [1, 1], [2, 1], [3, 1]],
	"O": [[0, 0], [1, 0], [0, 1], [1, 1]],
	"T": [[1, 0], [0, 1], [1, 1], [2, 1]],
	"S": [[1, 0], [2, 0], [0, 1], [1, 1]],
	"Z": [[0, 0], [1, 0], [1, 1], [2, 1]],
	"J": [[0, 0], [0, 1], [1, 1], [2, 1]],
	"L": [[2, 0], [0, 1], [1, 1], [2, 1]],
}

const SIZES := {"I": 4, "O": 2, "T": 3, "S": 3, "Z": 3, "J": 3, "L": 3}

const COLORS := {
	"I": Color(0.0, 0.94, 0.94),
	"O": Color(0.94, 0.94, 0.0),
	"T": Color(0.63, 0.0, 0.94),
	"S": Color(0.0, 0.94, 0.0),
	"Z": Color(0.94, 0.0, 0.0),
	"J": Color(0.0, 0.0, 0.94),
	"L": Color(0.94, 0.63, 0.0),
}

const LINE_SCORES := [0, 100, 300, 500, 800]

# --- Input (raw key codes, no input map needed) --------------------------

const KEY_LEFT := 4194319
const KEY_RIGHT := 4194321
const KEY_UP := 4194320
const KEY_DOWN := 4194322
const KEY_SPACE := 32
const KEY_ESCAPE := 4194305
const KEY_P := 80
const KEY_R := 82
const KEY_Z := 90

# --- Game states ----------------------------------------------------------

enum State { READY, PLAYING, PAUSED, GAME_OVER }
