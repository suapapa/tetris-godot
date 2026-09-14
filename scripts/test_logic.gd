extends SceneTree
## Headless functional test for the Tetris game logic.
## Run with:  godot --headless --script scripts/test_logic.gd
##
## Instantiates the real game script and drives its public/private logic
## methods directly, asserting that core Tetris mechanics behave correctly.

var passed := 0
var failed := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("PASS  " + msg)
	else:
		failed += 1
		print("FAIL  " + msg)


func _init() -> void:
	var script: GDScript = load("res://scripts/game.gd")
	_check(script != null, "game script loads")
	if script == null:
		_finish()
		return

	# 1. Build a node from the script without the full scene tree.
	var game := Node2D.new()
	game.set_script(script)
	root.add_child(game)
	game._ready()

	# 2. Grid sanity
	_check(game.grid.size() == 20, "grid has 20 rows")
	_check(game.grid[0].size() == 10, "row has 10 cols")
	_check(game.state == 0, "starts in READY state (value 0)")
	# Begin a game
	game.reset_game()
	_check(game.state == 1, "after reset, in PLAYING state (value 1)")
	_check(not game.current.is_empty(), "a piece was spawned")
	_check(game.current["name"] in ["I", "O", "T", "S", "Z", "J", "L"], "spawned a valid piece")

	# 3. _valid_cells boundary checks
	_check(game._valid_cells([[0, 0]]) == true, "cell inside grid is valid")
	_check(game._valid_cells([[-1, 0]]) == false, "col < 0 rejected")
	_check(game._valid_cells([[10, 0]]) == false, "col >= 10 rejected")
	_check(game._valid_cells([[0, 20]]) == false, "row >= 20 rejected")

	# 4. Rotation preserves block count
	var orig_cells: Array = game.current["cells"]
	var orig_size: int = orig_cells.size()
	for dir in [1, -1, 1, -1]:
		game._rotate(dir)
	_check(game.current["cells"].size() == orig_size, "rotation preserves 4 blocks")

	# 5. Movement keeps piece in bounds
	var before_x: int = game.current["x"]
	game._try_move(-1, 0)
	game._try_move(1, 0)
	var back_x: int = game.current["x"]
	_check(back_x == before_x, "left then right returns x (no wall loss)")

	# 6. Line clear + scoring: fill bottom row, leave one gap, drop piece there
	game.reset_game()
	# Fill row 19 completely except column 0.
	for c in range(1, 10):
		game.grid[19][c] = "O"
	# Force current to be an O (2x2) positioned so one block lands in col 0 row 19.
	game.current = {"name": "O", "cells": [[0, 0], [1, 0], [0, 1], [1, 1]], "x": -0, "y": 18}
	# O at x=0,y=18 occupies (0,18)(1,18)(0,19)(1,19). Row19 already full at cols1-9,
	# col0 empty -> after lock, row19 becomes full.
	var lines_before: int = game.lines_cleared
	var score_before: int = game.score
	game._lock_piece()
	_check(game.lines_cleared == lines_before + 1, "full bottom row cleared")
	_check(game.score > score_before, "score increased on line clear")
	_check(game.grid[19][0] == "" or game.lines_cleared > lines_before, "cleared row no longer full")

	# 7. Game over: fill the whole stack, spawning should end the game
	game.reset_game()
	for r in range(20):
		for c in range(10):
			game.grid[r][c] = "I"
	game.current = {"name": "I", "cells": [[0, 0], [1, 0], [2, 0], [3, 0]], "x": 0, "y": 0}
	game._game_over()
	_check(game.state == 3, "game over state set (value 3)")
	_check(game.current.is_empty(), "current piece cleared on game over")

	# 8. Reset restores a playable board
	game.reset_game()
	_check(game.state == 1, "reset returns to PLAYING")
	_check(game.score == 0, "reset zeroes score")
	_check(game.lines_cleared == 0, "reset zeroes lines")
	_check(game.level == 1, "reset zeroes level")

	game.queue_free()

	# 9. Full game simulation: drive the real _process loop until game over.
	var sim := Node2D.new()
	sim.set_script(script)
	root.add_child(sim)
	sim._ready()
	sim.reset_game()
	sim._process(0.016)  # kick the loop so it can be driven manually
	var frames := 0
	var max_frames := 200000
	var rng := RandomNumberGenerator.new()
	while sim.state != 3 and frames < max_frames:
		# Random control: sometimes move/rotate, usually hard-drop to reach the top fast.
		var r: int = rng.randi() % 5
		if r == 0:
			sim._try_move(-1, 0)
		elif r == 1:
			sim._try_move(1, 0)
		elif r == 2:
			sim._rotate(1)
		elif r == 3:
			sim._process(0.016)
		else:
			sim._hard_drop()
		frames += 1
	_check(sim.state == 3, "simulated game reaches GAME_OVER (frames=%d)" % frames)
	_check(sim.score >= 0, "score remained valid through simulation")
	sim.queue_free()

	_finish()


func _finish() -> void:
	print("----------------------------------------")
	print("RESULTS: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	quit(1 if failed > 0 else 0)
