class_name Renderer
extends RefCounted
## All Tetris drawing. The game node hands itself in as `canvas` (its
## draw_* calls do the work); `game` is duck-typed to avoid a circular
## class reference between game.gd and renderer.gd.

var canvas: CanvasItem


func _init(target: CanvasItem) -> void:
	canvas = target


func render(game) -> void:
	var font: Font = ThemeDB.fallback_font

	# Background
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(GameConstants.WIN_W, GameConstants.WIN_H)), Color(0.07, 0.08, 0.12))

	# Title
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, 42.0), "T E T R I S", HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 28, Color(0.8, 0.85, 1.0))

	var field := Rect2(GameConstants.ORIGIN, Vector2(GameConstants.FIELD_W, GameConstants.FIELD_H))

	# Playfield background
	canvas.draw_rect(field, Color(0.03, 0.04, 0.08))

	# Grid lines
	for i in range(GameConstants.COLS + 1):
		var p := GameConstants.ORIGIN + Vector2(float(i) * GameConstants.CELL, 0.0)
		canvas.draw_line(p, p + Vector2(0.0, GameConstants.FIELD_H), Color(1, 1, 1, 0.05))
	for j in range(GameConstants.ROWS + 1):
		var p := GameConstants.ORIGIN + Vector2(0.0, float(j) * GameConstants.CELL)
		canvas.draw_line(p, p + Vector2(GameConstants.FIELD_W, 0.0), Color(1, 1, 1, 0.05))

	# Locked cells
	var grid: Array = game.board.grid
	for row in range(GameConstants.ROWS):
		for col in range(GameConstants.COLS):
			var v: String = grid[row][col]
			if v != "":
				draw_cell(col, row, GameConstants.COLORS[v], false)

	# Line-clear flash
	if game.flash_time > 0.0:
		for r in game.flash_rows:
			canvas.draw_rect(Rect2(GameConstants.ORIGIN + Vector2(0.0, float(r) * GameConstants.CELL), Vector2(GameConstants.FIELD_W, GameConstants.CELL)), Color(1, 1, 1, 0.85))

	# Ghost + current piece
	var current = game.current
	if current != null:
		var color: Color = GameConstants.COLORS[current.name]
		var gy: int = game.ghost_y()
		if gy > current.y:
			for c in current.absolute_cells(current.cells, current.x, gy):
				if c[1] >= 0:
					draw_cell(c[0], c[1], color, true)
		for c in current.current_absolute():
			if c[1] >= 0:
				draw_cell(c[0], c[1], color, false)

	# Playfield border
	canvas.draw_rect(field, Color(0.4, 0.5, 0.7, 0.8), false, 2.0)

	draw_hud(font, game)
	draw_controls_help(font)

	# Overlays
	if game.state == GameConstants.State.READY:
		draw_overlay(font, "PRESS ANY KEY", "to start")
	elif game.state == GameConstants.State.PAUSED:
		draw_overlay(font, "PAUSED", "P to resume")
	elif game.state == GameConstants.State.GAME_OVER:
		draw_overlay(font, "GAME OVER", "Score %d - press R to restart" % game.score)


func draw_hud(font: Font, game) -> void:
	# Left panel: score / level / lines
	var lx := 28.0
	hud_label(font, lx, 110.0, "SCORE")
	canvas.draw_string(font, Vector2(lx, 140.0), str(game.score), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	hud_label(font, lx, 200.0, "LEVEL")
	canvas.draw_string(font, Vector2(lx, 228.0), str(game.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.94, 0.63, 0.0))
	hud_label(font, lx, 286.0, "LINES")
	canvas.draw_string(font, Vector2(lx, 314.0), str(game.lines_cleared), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.0, 0.94, 0.94))

	# Right panel: next piece
	hud_label(font, 488.0, 110.0, "NEXT")
	if game.next_piece != "":
		draw_preview(game.next_piece, Vector2(452.0, 130.0))


func draw_controls_help(font: Font) -> void:
	var ctrl := "<- / -> move      Up / Z rotate"
	var ctrl2 := "Down soft drop    Space hard drop"
	var ctrl3 := "P pause      R restart"
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, GameConstants.WIN_H - 56.0), ctrl, HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 15, Color(0.55, 0.6, 0.75))
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, GameConstants.WIN_H - 36.0), ctrl2, HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 15, Color(0.55, 0.6, 0.75))
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, GameConstants.WIN_H - 16.0), ctrl3, HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 15, Color(0.55, 0.6, 0.75))


func hud_label(font: Font, x: float, y: float, text: String) -> void:
	canvas.draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.6, 0.75))


func draw_overlay(font: Font, line1: String, line2: String) -> void:
	var field := Rect2(GameConstants.ORIGIN, Vector2(GameConstants.FIELD_W, GameConstants.FIELD_H))
	canvas.draw_rect(field, Color(0.0, 0.0, 0.0, 0.65))
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, 300.0), line1, HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 34, Color.WHITE)
	canvas.draw_string(font, Vector2(GameConstants.ORIGIN.x, 350.0), line2, HORIZONTAL_ALIGNMENT_CENTER, GameConstants.FIELD_W, 18, Color(0.7, 0.75, 0.9))


func draw_cell(col: int, row: int, color: Color, ghost: bool) -> void:
	var r := Rect2(GameConstants.ORIGIN + Vector2(float(col) * GameConstants.CELL, float(row) * GameConstants.CELL), Vector2(GameConstants.CELL, GameConstants.CELL))
	if ghost:
		canvas.draw_rect(r, Color(color.r, color.g, color.b, 0.2))
		canvas.draw_rect(r, color, false, 1.5)
	else:
		canvas.draw_rect(r, color)
		canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), Color(1, 1, 1, 0.28))
		canvas.draw_rect(Rect2(r.position + Vector2(0.0, r.size.y - 3.0), Vector2(r.size.x, 3.0)), Color(0, 0, 0, 0.32))
		canvas.draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)


func draw_preview(pname: String, at: Vector2) -> void:
	var s := 18.0
	var cells: Array = GameConstants.SHAPES[pname]
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
		canvas.draw_rect(r, GameConstants.COLORS[pname])
		canvas.draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
