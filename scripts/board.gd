class_name Board
extends RefCounted
## The playfield grid: stores locked cells, answers collision queries,
## detects and clears full rows.

var grid: Array = []  # grid[row][col] = "" or piece name


func _init() -> void:
	build()


## Reset to an empty grid.
func build() -> void:
	grid = []
	for r in range(GameConstants.ROWS):
		grid.append(empty_row())


func empty_row() -> Array:
	var row: Array = []
	for c in range(GameConstants.COLS):
		row.append("")
	return row


## True if every absolute cell is inside the walls and not overlapping
## an already-locked block (cells above the top edge are allowed).
func is_valid_cells(cells: Array) -> bool:
	for c in cells:
		var col: int = c[0]
		var row: int = c[1]
		if col < 0 or col >= GameConstants.COLS or row >= GameConstants.ROWS:
			return false
		if row >= 0 and grid[row][col] != "":
			return false
	return true


## Stamp a piece's absolute cells into the grid (cells above the top
## edge are clipped, matching standard Tetris behavior).
func lock_cells(piece_name: String, cells: Array) -> void:
	for c in cells:
		if c[1] >= 0 and c[1] < GameConstants.ROWS:
			grid[c[1]][c[0]] = piece_name


## Row indices that are completely filled.
func find_full_rows() -> Array:
	var full: Array = []
	for r in range(GameConstants.ROWS):
		var filled := true
		for c in range(GameConstants.COLS):
			if grid[r][c] == "":
				filled = false
				break
		if filled:
			full.append(r)
	return full


## Remove the given rows and insert empty rows on top.
func clear_rows(rows: Array) -> void:
	for r in rows:
		grid.remove_at(r)
	for i in range(rows.size()):
		grid.push_front(empty_row())
