class_name Piece
extends RefCounted
## The active falling tetromino: shape + board position, plus the
## rotation and coordinate math that operates on it.

var name: String = ""
var cells: Array = []  # relative [col, row] offsets within the bounding box
var x: int = 0         # bounding-box left edge, in board columns
var y: int = 0         # bounding-box top edge, in board rows (can be < 0)


func _init(p_name: String = "", p_cells: Array = [], p_x: int = 0, p_y: int = 0) -> void:
	name = p_name
	cells = p_cells
	x = p_x
	y = p_y


## Bounding-box side length for this piece's shape.
func size() -> int:
	return GameConstants.SIZES[name]


## Convert relative cells to absolute board coordinates.
func absolute_cells(at_cells: Array, ox: int, oy: int) -> Array:
	var out: Array = []
	for c in at_cells:
		out.append([ox + c[0], oy + c[1]])
	return out


## Absolute board coordinates of the piece at its current position.
func current_absolute() -> Array:
	return absolute_cells(cells, x, y)


## Cells of this piece rotated 90° (dir > 0 clockwise, dir < 0 counter-clockwise).
func rotated_cells(dir: int) -> Array:
	var s := size()
	var out: Array = []
	for c in cells:
		if dir > 0:
			out.append([s - 1 - c[1], c[0]])
		else:
			out.append([c[1], s - 1 - c[0]])
	return out
