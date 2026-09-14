extends Node2D
## TETRIS - complete single-file implementation for Godot 4.
##
## Controls:
##   <- / ->   Move
##   Up / Z    Rotate clockwise / counter-clockwise
##   Down      Soft drop
##   Space     Hard drop
##   P / Esc   Pause / resume
##   R         Restart

const COLS := 10
const ROWS := 20
const CELL := 32.0
const ORIGIN := Vector2(120.0, 60.0)
const FIELD_W := COLS * CELL
const FIELD_H := ROWS * CELL
const WIN_W := 560.0
const WIN_H := 760.0

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

# Key codes (direct, no input map needed)
const KEY_LEFT := 4194319
const KEY_RIGHT := 4194321
const KEY_UP := 4194320
const KEY_DOWN := 4194322
const KEY_SPACE := 32
const KEY_ESCAPE := 4194305
const KEY_P := 80
const KEY_R := 82
const KEY_Z := 90

enum State { READY, PLAYING, PAUSED, GAME_OVER }

var state: int = State.READY
var grid: Array = []          # grid[row][col] = "" or piece name
var current: Dictionary = {}  # {name, cells, x, y}
var bag: Array = []           # 7-bag queue of upcoming pieces
var next_piece: String = ""
var score: int = 0
var lines_cleared: int = 0
var level: int = 1
var fall_timer: float = 0.0
var lock_timer: float = 0.0
var resting: bool = false
var flash_time: float = 0.0
var flash_rows: Array = []


func _ready() -> void:
	_build_grid()
	_fill_bag()
	next_piece = bag[0]
	queue_redraw()


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			flash_time = 0.0
			flash_rows = []
			spawn_piece()
	else:
		var soft := Input.is_key_pressed(KEY_DOWN)
		var interval := 0.05 if soft else fall_interval()
		fall_timer += delta
		if fall_timer >= interval:
			fall_timer = 0.0
			if _try_move(0, 1):
				resting = false
				if soft:
					score += 1
			else:
				resting = true
		if resting:
			lock_timer += delta
			if lock_timer >= 0.5:
				_lock_piece()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var code := key.keycode
	match state:
		State.READY:
			reset_game()
		State.PLAYING:
			if code == KEY_LEFT:
				_try_move(-1, 0)
			elif code == KEY_RIGHT:
				_try_move(1, 0)
			elif not key.echo:
				if code == KEY_UP:
					_rotate(1)
				elif code == KEY_Z:
					_rotate(-1)
				elif code == KEY_SPACE:
					_hard_drop()
				elif code == KEY_P or code == KEY_ESCAPE:
					state = State.PAUSED
				elif code == KEY_R:
					reset_game()
		State.PAUSED:
			if not key.echo and (code == KEY_P or code == KEY_ESCAPE or code == KEY_R):
				if code == KEY_R:
					reset_game()
				else:
					state = State.PLAYING
		State.GAME_OVER:
			if not key.echo and (code == KEY_R or code == KEY_P or code == KEY_ESCAPE):
				reset_game()
	queue_redraw()


func fall_interval() -> float:
	return maxf(0.1, 0.8 - float(level - 1) * 0.06)


func reset_game() -> void:
	_build_grid()
	bag = []
	_fill_bag()
	next_piece = bag[0]
	score = 0
	lines_cleared = 0
	level = 1
	fall_timer = 0.0
	lock_timer = 0.0
	resting = false
	flash_time = 0.0
	flash_rows = []
	state = State.PLAYING
	spawn_piece()


func spawn_piece() -> void:
	if bag.size() < 2:
		_fill_bag()
	var name: String = bag.pop_front()
	next_piece = bag[0]
	var size: int = SIZES[name]
	current = {
		"name": name,
		"cells": SHAPES[name].duplicate(true),
		"x": (COLS - size) / 2,
		"y": 0,
	}
	resting = false
	lock_timer = 0.0
	if not _valid_cells(_absolute_cells(current["cells"], current["x"], current["y"])):
		_game_over()


func _hard_drop() -> void:
	var dropped := 0
	while _try_move(0, 1):
		dropped += 1
	score += dropped * 2
	_lock_piece()


func _rotate(dir: int) -> void:
	if current.is_empty():
		return
	var size: int = SIZES[current["name"]]
	var rotated: Array = _rotate_cells(current["cells"], size, dir)
	for kick in [0, -1, 1, -2, 2]:
		var cells := _absolute_cells(rotated, current["x"] + kick, current["y"])
		if _valid_cells(cells):
			current["cells"] = rotated
			current["x"] += kick
			lock_timer = 0.0
			resting = false
			return


func _try_move(dx: int, dy: int) -> bool:
	if current.is_empty():
		return false
	var cells := _absolute_cells(current["cells"], current["x"] + dx, current["y"] + dy)
	if _valid_cells(cells):
		current["x"] += dx
		current["y"] += dy
		if resting:
			resting = false
			lock_timer = 0.0
		return true
	return false


func _lock_piece() -> void:
	var name: String = current["name"]
	var cells := _absolute_cells(current["cells"], current["x"], current["y"])
	for c in cells:
		if c[1] >= 0 and c[1] < ROWS:
			grid[c[1]][c[0]] = name
	current = {}
	resting = false
	lock_timer = 0.0
	var full := _find_full_rows()
	if full.size() > 0:
		for r in full:
			grid.remove_at(r)
		for i in range(full.size()):
			grid.push_front(_empty_row())
		lines_cleared += full.size()
		score += LINE_SCORES[full.size()] * level
		level = lines_cleared / 10 + 1
		flash_rows = full
		flash_time = 0.25
	else:
		spawn_piece()


func _game_over() -> void:
	state = State.GAME_OVER
	current = {}


func _fill_bag() -> void:
	var names := PIECE_NAMES.duplicate()
	names.shuffle()
	bag.append_array(names)


func _build_grid() -> void:
	grid = []
	for r in range(ROWS):
		grid.append(_empty_row())


func _empty_row() -> Array:
	var row: Array = []
	for c in range(COLS):
		row.append("")
	return row


func _find_full_rows() -> Array:
	var full: Array = []
	for r in range(ROWS):
		var filled := true
		for c in range(COLS):
			if grid[r][c] == "":
				filled = false
				break
		if filled:
			full.append(r)
	return full


func _absolute_cells(cells: Array, ox: int, oy: int) -> Array:
	var out: Array = []
	for c in cells:
		out.append([ox + c[0], oy + c[1]])
	return out


func _valid_cells(cells: Array) -> bool:
	for c in cells:
		var col: int = c[0]
		var row: int = c[1]
		if col < 0 or col >= COLS or row >= ROWS:
			return false
		if row >= 0 and grid[row][col] != "":
			return false
	return true


func _rotate_cells(cells: Array, size: int, dir: int) -> Array:
	var out: Array = []
	for c in cells:
		if dir > 0:
			out.append([size - 1 - c[1], c[0]])
		else:
			out.append([c[1], size - 1 - c[0]])
	return out


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIN_W, WIN_H)), Color(0.07, 0.08, 0.12))

	# Title
	draw_string(font, Vector2(ORIGIN.x, 42.0), "T E T R I S", HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 28, Color(0.8, 0.85, 1.0))

	var field := Rect2(ORIGIN, Vector2(FIELD_W, FIELD_H))

	# Playfield background
	draw_rect(field, Color(0.03, 0.04, 0.08))

	# Grid lines
	for i in range(COLS + 1):
		var p := ORIGIN + Vector2(float(i) * CELL, 0.0)
		draw_line(p, p + Vector2(0.0, FIELD_H), Color(1, 1, 1, 0.05))
	for j in range(ROWS + 1):
		var p := ORIGIN + Vector2(0.0, float(j) * CELL)
		draw_line(p, p + Vector2(FIELD_W, 0.0), Color(1, 1, 1, 0.05))

	# Locked cells
	for row in range(ROWS):
		for col in range(COLS):
			var v: String = grid[row][col]
			if v != "":
				_draw_cell(col, row, COLORS[v], false)

	# Line-clear flash
	if flash_time > 0.0:
		for r in flash_rows:
			draw_rect(Rect2(ORIGIN + Vector2(0.0, float(r) * CELL), Vector2(FIELD_W, CELL)), Color(1, 1, 1, 0.85))

	# Ghost + current piece
	if not current.is_empty():
		var color: Color = COLORS[current["name"]]
		var ghost_y: int = current["y"]
		while _valid_cells(_absolute_cells(current["cells"], current["x"], ghost_y + 1)):
			ghost_y += 1
		if ghost_y > current["y"]:
			for c in _absolute_cells(current["cells"], current["x"], ghost_y):
				if c[1] >= 0:
					_draw_cell(c[0], c[1], color, true)
		for c in _absolute_cells(current["cells"], current["x"], current["y"]):
			if c[1] >= 0:
				_draw_cell(c[0], c[1], color, false)

	# Playfield border
	draw_rect(field, Color(0.4, 0.5, 0.7, 0.8), false, 2.0)

	# HUD - left panel
	var lx := 28.0
	_hud_label(font, lx, 110.0, "SCORE")
	draw_string(font, Vector2(lx, 140.0), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	_hud_label(font, lx, 200.0, "LEVEL")
	draw_string(font, Vector2(lx, 228.0), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.94, 0.63, 0.0))
	_hud_label(font, lx, 286.0, "LINES")
	draw_string(font, Vector2(lx, 314.0), str(lines_cleared), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.0, 0.94, 0.94))

	# HUD - right panel (next piece)
	_hud_label(font, 488.0, 110.0, "NEXT")
	if next_piece != "":
		_draw_preview(next_piece, Vector2(452.0, 130.0))

	# Controls help
	var ctrl := "<- / -> move      Up / Z rotate"
	var ctrl2 := "Down soft drop    Space hard drop"
	var ctrl3 := "P pause      R restart"
	draw_string(font, Vector2(ORIGIN.x, WIN_H - 56.0), ctrl, HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 15, Color(0.55, 0.6, 0.75))
	draw_string(font, Vector2(ORIGIN.x, WIN_H - 36.0), ctrl2, HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 15, Color(0.55, 0.6, 0.75))
	draw_string(font, Vector2(ORIGIN.x, WIN_H - 16.0), ctrl3, HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 15, Color(0.55, 0.6, 0.75))

	# Overlays
	match state:
		State.READY:
			_draw_overlay(font, "PRESS ANY KEY", "to start")
		State.PAUSED:
			_draw_overlay(font, "PAUSED", "P to resume")
		State.GAME_OVER:
			_draw_overlay(font, "GAME OVER", "Score %d - press R to restart" % score)


func _hud_label(font: Font, x: float, y: float, text: String) -> void:
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.6, 0.75))


func _draw_overlay(font: Font, line1: String, line2: String) -> void:
	var field := Rect2(ORIGIN, Vector2(FIELD_W, FIELD_H))
	draw_rect(field, Color(0.0, 0.0, 0.0, 0.65))
	draw_string(font, Vector2(ORIGIN.x, 300.0), line1, HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 34, Color.WHITE)
	draw_string(font, Vector2(ORIGIN.x, 350.0), line2, HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 18, Color(0.7, 0.75, 0.9))


func _draw_cell(col: int, row: int, color: Color, ghost: bool) -> void:
	var r := Rect2(ORIGIN + Vector2(float(col) * CELL, float(row) * CELL), Vector2(CELL, CELL))
	if ghost:
		draw_rect(r, Color(color.r, color.g, color.b, 0.2))
		draw_rect(r, color, false, 1.5)
	else:
		draw_rect(r, color)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), Color(1, 1, 1, 0.28))
		draw_rect(Rect2(r.position + Vector2(0.0, r.size.y - 3.0), Vector2(r.size.x, 3.0)), Color(0, 0, 0, 0.32))
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)


func _draw_preview(name: String, at: Vector2) -> void:
	var s := 18.0
	var cells: Array = SHAPES[name]
	var min_x := 99
	var max_x := -1
	var min_y := 99
	var max_y := -1
	for c in cells:
		min_x = mini(min_x, c[0])
		max_x = maxi(max_x, c[0])
		min_y = mini(min_y, c[1])
		max_y = maxi(max_y, c[1])
	var w := (max_x - min_x + 1) * s
	var h := (max_y - min_y + 1) * s
	var ox := at.x + (104.0 - w) / 2.0
	var oy := at.y + (90.0 - h) / 2.0
	for c in cells:
		var r := Rect2(Vector2(ox + (float(c[0]) - float(min_x)) * s, oy + (float(c[1]) - float(min_y)) * s), Vector2(s, s))
		draw_rect(r, COLORS[name])
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
