extends Node2D
## TETRIS - game orchestrator: state machine, input, gravity and
## lock timers, 7-bag spawner, scoring.
##
## Split out of the original single file:
##   scripts/game_constants.gd - layout, shapes, colors, keys, states
##   scripts/piece.gd          - active piece data + rotation math
##   scripts/board.gd          - grid, collision, line clearing
##   scripts/renderer.gd       - all drawing (fed by _draw below)
##
## Controls:
##   <- / ->   Move
##   Up / Z    Rotate clockwise / counter-clockwise
##   Down      Soft drop
##   Space     Hard drop
##   P / Esc   Pause / resume
##   R         Restart

var state: int = GameConstants.State.READY
var board: Board = Board.new()
var current: Piece = null     # the active falling piece
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
var renderer: Renderer = null


func _ready() -> void:
	renderer = Renderer.new(self)
	_fill_bag()
	next_piece = bag[0]
	queue_redraw()


func _process(delta: float) -> void:
	if state != GameConstants.State.PLAYING:
		return
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			flash_time = 0.0
			flash_rows = []
			spawn_piece()
	else:
		var soft := Input.is_key_pressed(GameConstants.KEY_DOWN)
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
	if state == GameConstants.State.READY:
		reset_game()
	elif state == GameConstants.State.PLAYING:
		if code == GameConstants.KEY_LEFT:
			_try_move(-1, 0)
		elif code == GameConstants.KEY_RIGHT:
			_try_move(1, 0)
		elif not key.echo:
			if code == GameConstants.KEY_UP:
				_rotate(1)
			elif code == GameConstants.KEY_Z:
				_rotate(-1)
			elif code == GameConstants.KEY_SPACE:
				_hard_drop()
			elif code == GameConstants.KEY_P or code == GameConstants.KEY_ESCAPE:
				state = GameConstants.State.PAUSED
			elif code == GameConstants.KEY_R:
				reset_game()
	elif state == GameConstants.State.PAUSED:
		if not key.echo and (code == GameConstants.KEY_P or code == GameConstants.KEY_ESCAPE or code == GameConstants.KEY_R):
			if code == GameConstants.KEY_R:
				reset_game()
			else:
				state = GameConstants.State.PLAYING
	elif state == GameConstants.State.GAME_OVER:
		if not key.echo and (code == GameConstants.KEY_R or code == GameConstants.KEY_P or code == GameConstants.KEY_ESCAPE):
			reset_game()
	queue_redraw()


func fall_interval() -> float:
	return maxf(0.1, 0.8 - float(level - 1) * 0.06)


func reset_game() -> void:
	board.build()
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
	current = null
	state = GameConstants.State.PLAYING
	spawn_piece()


func spawn_piece() -> void:
	if bag.size() < 2:
		_fill_bag()
	var pname: String = bag.pop_front()
	next_piece = bag[0]
	var size: int = GameConstants.SIZES[pname]
	current = Piece.new(pname, GameConstants.SHAPES[pname].duplicate(true), (GameConstants.COLS - size) / 2, 0)
	resting = false
	lock_timer = 0.0
	if not board.is_valid_cells(current.current_absolute()):
		_game_over()


## Row the current piece would land on (for the ghost preview).
func ghost_y() -> int:
	if current == null:
		return 0
	var gy: int = current.y
	while board.is_valid_cells(current.absolute_cells(current.cells, current.x, gy + 1)):
		gy += 1
	return gy


func _hard_drop() -> void:
	var dropped := 0
	while _try_move(0, 1):
		dropped += 1
	score += dropped * 2
	_lock_piece()


func _rotate(dir: int) -> void:
	if current == null:
		return
	var rotated: Array = current.rotated_cells(dir)
	for kick in [0, -1, 1, -2, 2]:
		if board.is_valid_cells(current.absolute_cells(rotated, current.x + kick, current.y)):
			current.cells = rotated
			current.x += kick
			lock_timer = 0.0
			resting = false
			return


func _try_move(dx: int, dy: int) -> bool:
	if current == null:
		return false
	if board.is_valid_cells(current.absolute_cells(current.cells, current.x + dx, current.y + dy)):
		current.x += dx
		current.y += dy
		if resting:
			resting = false
			lock_timer = 0.0
		return true
	return false


func _lock_piece() -> void:
	board.lock_cells(current.name, current.current_absolute())
	current = null
	resting = false
	lock_timer = 0.0
	var full := board.find_full_rows()
	if full.size() > 0:
		board.clear_rows(full)
		lines_cleared += full.size()
		score += GameConstants.LINE_SCORES[full.size()] * level
		level = lines_cleared / 10 + 1
		flash_rows = full
		flash_time = 0.25
	else:
		spawn_piece()


func _game_over() -> void:
	state = GameConstants.State.GAME_OVER
	current = null


func _fill_bag() -> void:
	var names: Array = GameConstants.PIECE_NAMES.duplicate()
	names.shuffle()
	bag.append_array(names)


func _draw() -> void:
	renderer.render(self)
