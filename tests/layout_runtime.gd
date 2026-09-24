extends Node

const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")
const Reader = preload("res://addons/sokoban_layout/map_reader.gd")

func _ready() -> void:
	var map := Reader.validate(PackedStringArray(["  #####", "###   #", "#.@$  #", "### $.#", "#.##$ #", "# # . ##", "#$ *$$.#", "#   .  #", "########"]))
	assert(not map.has("error"))
	assert(map.width == 8 and map.height == 9 and map.crates == 7)
	assert(Reader.read_level("res://levels/tutorials.txt", 2).crates == 2)
	assert(Reader.read_level("res://levels/tutorials.txt", 3).has("error"))
	for rows in [PackedStringArray(["###", "#@$", "#.#"]), PackedStringArray(["#####", "#@@$#", "# . #", "#####"]), PackedStringArray(["#####", "#@x.#", "#####"]), PackedStringArray(["#####", "#@$ #", "#####"])]:
		assert(Reader.validate(rows).has("error"))
	assert(not Reader.validate(PackedStringArray(["#####", "#+$ #", "#####"])).has("error"))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var layout := main.get_node("LevelLayout")
	var saved_map := Reader.read_level(layout.collection, layout.level_number)
	assert(not saved_map.has("error"))
	var saved := layout.get_node("Generated")
	assert(saved.get_node("Crates").get_child_count() == saved_map.crates)
	assert(saved.get_node("Targets").get_child_count() == saved_map.targets)
	layout.remove_child(saved)
	saved.free()
	var generated := Builder.build(map)
	layout.add_child(generated)
	main.get_node("Player").position = Builder.cell_position(map.player, map)
	add_child(main)
	var score_hud := main.get_node("ScoreHUD")
	assert(score_hud.move_count == 0 and score_hud.is_tracking, "Score tracking must start at zero")
	score_hud._process(65.0)
	assert(score_hud.get_node("Panel/Margin/Stats/TimerLabel").text == "Time  01:05", "Timer must use minutes and seconds")
	score_hud.reset()
	get_tree().paused = true
	assert(not score_hud.can_process(), "Score timer must not process while the game is paused")
	get_tree().paused = false
	assert(generated.get_node("Walls").get_child_count() == 35)
	assert(generated.get_node("Crates").get_child_count() == 7)
	assert(generated.get_node("Targets").get_child_count() == 7)
	assert(main.get_node("Player").position == Vector3(-2, 0, -2))
	for i in 10:
		await get_tree().physics_frame
	var target := generated.get_node("Targets/Target_3_6")
	assert(target.has_block_on_target(), "Crate initially on target must register")
	var crate := generated.get_node("Crates/Crate_3_2/RigidBody3D")
	assert(not crate._is_push_path_blocked(Vector3.RIGHT), "Open destination must allow pushing")
	assert(generated.get_node("Crates/Crate_4_3/RigidBody3D")._is_push_path_blocked(Vector3.BACK), "Adjacent crate must block pushing")
	crate.player = main.get_node("Player")
	crate.push_direction = Vector3.RIGHT
	crate.player.set_push_ready(true, Vector3.RIGHT, crate.player.global_position, true, crate)
	Input.action_press("move_right")
	crate.push_speed = 20
	crate.push(Vector3.RIGHT)
	Input.action_release("move_right")
	for i in 30:
		await get_tree().physics_frame
	assert(crate.global_position.is_equal_approx(Vector3(0, 0.5, -2)), "Crate must travel exactly one cell")
	assert(score_hud.move_count == 1, "A successful crate push must count as one move")
	for child in generated.get_node("Crates").get_children():
		child.get_node("RigidBody3D").global_position = Vector3(20, 0.5, 20)
	for i in 7:
		generated.get_node("Crates").get_child(i).get_node("RigidBody3D").global_position = generated.get_node("Targets").get_child(i).global_position + Vector3(0, 0.5, 0)
	for i in 10:
		await get_tree().physics_frame
	assert(main.get_node("LevelGoal").is_level_completed, "Generated targets must complete the level")
	assert(not score_hud.is_tracking, "Score timer must stop when the level is complete")
	print("PASS: parsing, score tracking, pause behavior, pushes, one-cell movement, completion")
	get_tree().quit()
