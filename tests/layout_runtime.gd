extends Node

const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")
const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const StartMenu = preload("res://scripts/start_menu.gd")

func _ready() -> void:
	var map := Reader.validate(PackedStringArray(["  #####", "###   #", "#.@$  #", "### $.#", "#.##$ #", "# # . ##", "#$ *$$.#", "#   .  #", "########"]))
	assert(not map.has("error"))
	assert(map.width == 8 and map.height == 9 and map.crates == 7)
	assert(Reader.read_level("res://levels/tutorials.txt", 2).crates == 2)
	assert(Reader.read_level("res://levels/tutorials.txt", 3).has("error"))
	for level_number in range(1, 138):
		var loma_map := Reader.read_level("res://levels/loma.txt", level_number)
		assert(not loma_map.has("error"), "LOMA level %d failed to load: %s" % [level_number, loma_map.get("error", "")])
	assert(Reader.read_level("res://levels/loma.txt", 138).has("error"))
	var start_menu := StartMenu.new()
	var expected_collection_labels := {
		"tutorials.txt": "Tutorials (tutorial)",
		"microban.txt": "Microban I (easy)",
		"microban_ii.txt": "Microban II (easy)",
		"microban_iii.txt": "Microban III (easy)",
		"microban_iv.txt": "Microban IV (easy)",
		"sasquatch.txt": "Sasquatch I (medium)",
		"sasquatch_ii.txt": "Sasquatch II (hard)",
		"sasquatch_iii.txt": "Sasquatch III (medium-very hard)",
		"sasquatch_iv.txt": "Sasquatch IV (medium-very hard)",
		"loma.txt": "LOMA (easy-hard)",
		"wikipedia.txt": "Math Is Fun Sokoban (easy - hard)",
	}
	for file_name in expected_collection_labels:
		var path: String = "res://levels/" + str(file_name)
		assert(start_menu._collection_option_label(path) == expected_collection_labels[file_name])
	var expected_collection_order := PackedStringArray([
		"tutorials.txt",
		"microban.txt",
		"microban_ii.txt",
		"microban_iii.txt",
		"microban_iv.txt",
		"sasquatch.txt",
		"sasquatch_ii.txt",
		"sasquatch_iii.txt",
		"sasquatch_iv.txt",
		"wikipedia.txt",
		"loma.txt",
	])
	var actual_collection_order := PackedStringArray()
	for collection_path in start_menu._collections():
		actual_collection_order.append(collection_path.get_file())
	assert(actual_collection_order == expected_collection_order, "Expected %s, got %s" % [expected_collection_order, actual_collection_order])
	start_menu.free()
	var start_menu_scene: Control = load("res://scenes/start_menu.tscn").instantiate()
	var start_background_material := start_menu_scene.get_node("DesignRoot/Background").material as ShaderMaterial
	assert(start_background_material != null)
	assert(start_background_material.get_shader_parameter("pixel_block_size") == 6.0)
	var main_panel: VBoxContainer = start_menu_scene.get_node("DesignRoot/Shell/Content/MainPanel")
	var main_button_order := PackedStringArray()
	for child in main_panel.get_children():
		if child is Button:
			main_button_order.append(child.text)
	assert(main_button_order == PackedStringArray(["Level Select", "High Scores", "Instructions", "Options"]))
	var start_options: VBoxContainer = start_menu_scene.get_node("DesignRoot/Shell/Content/OptionsPanel")
	var pause_menu_scene: CanvasLayer = load("res://scenes/pause_menu.tscn").instantiate()
	var pause_options: VBoxContainer = pause_menu_scene.get_node("Overlay/Panel/Margin/Content/OptionsPanel")
	var pause_button: Button = pause_menu_scene.get_node("PauseButton")
	var pause_button_style := pause_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(pause_button_style != null and is_equal_approx(pause_button_style.bg_color.a, 0.86))
	var pause_background: TextureRect = pause_menu_scene.get_node("Overlay/Panel/Background")
	var pause_background_material := pause_background.material as ShaderMaterial
	assert(pause_background.texture.get_size() == Vector2(628, 662))
	assert(pause_background_material != null)
	assert(pause_background_material.get_shader_parameter("pixel_block_size") == 6.0)
	for control_name in ["OptionsTitle", "MusicLabel", "SfxLabel", "OptionsBackButton"]:
		assert(start_options.get_node(control_name).text == pause_options.get_node(control_name).text)
	for slider_name in ["MusicSlider", "SfxSlider"]:
		var start_slider: HSlider = start_options.get_node(slider_name)
		var pause_slider: HSlider = pause_options.get_node(slider_name)
		assert(start_slider.max_value == pause_slider.max_value and start_slider.step == pause_slider.step)
	add_child(start_menu_scene)
	main_panel.get_node("OptionsButton").pressed.emit()
	assert(start_options.visible and not main_panel.visible, "Options button must open the start-menu options panel")
	start_options.get_node("OptionsBackButton").pressed.emit()
	assert(main_panel.visible and not start_options.visible, "Options Back button must return to the start menu")
	remove_child(start_menu_scene)
	start_menu_scene.free()
	pause_menu_scene.free()
	for rows in [PackedStringArray(["###", "#@$", "#.#"]), PackedStringArray(["#####", "#@@$#", "# . #", "#####"]), PackedStringArray(["#####", "#@x.#", "#####"]), PackedStringArray(["#####", "#@$ #", "#####"])]:
		assert(Reader.validate(rows).has("error"))
	assert(not Reader.validate(PackedStringArray(["#####", "#+$ #", "#####"])).has("error"))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var character_model: CharacterModel = main.get_node("Player/Pivot/CharacterModel")
	var character_animation_player: AnimationPlayer = main.get_node("Player/Pivot/CharacterModel/rat-albert-animated/AnimationPlayer")
	assert(character_animation_player.has_animation(&"chicken_dance"))
	var chicken_dance := character_animation_player.get_animation(&"chicken_dance")
	assert(is_equal_approx(chicken_dance.length, 4.8))
	assert(chicken_dance.get_track_count() == 34 and chicken_dance.loop_mode == Animation.LOOP_NONE)
	var character_animation_tree: AnimationTree = main.get_node("Player/Pivot/CharacterModel/AnimationTree")
	var movement_transition := character_animation_tree.tree_root.get_node("movement") as AnimationNodeTransition
	assert(movement_transition.get_input_count() == 7)
	assert(movement_transition.get_input_name(6) == "chicken_dance")
	assert(main.get("completion_reach_release_duration") >= 0.75, "Raised-arm pose must overlap and ease into the dance")
	var cheese_reward: Node3D = load("res://scenes/cheese_reward.tscn").instantiate()
	var cheese_mesh_instance := cheese_reward.get_node("Mesh") as MeshInstance3D
	assert(cheese_mesh_instance.mesh != null, "Cheese reward must contain the imported OBJ mesh")
	var cheese_material := cheese_mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
	assert(cheese_material != null and cheese_material.albedo_texture != null, "Cheese reward must retain its texture")
	cheese_reward.free()
	for backdrop_name in ["NorthLabWall", "EastBenchWall", "SouthRatCageWall", "WestDoorWall"]:
		var backdrop: MeshInstance3D = main.get_node("LabBackdrop/" + backdrop_name)
		var backdrop_material := backdrop.mesh.material as ShaderMaterial
		assert(backdrop_material != null, "%s must use the pixelated backdrop shader" % backdrop_name)
		assert(backdrop_material.get_shader_parameter("pixel_block_size") == 6.0)
	var level_complete_background: TextureRect = main.get_node("LevelCompletePopup/Overlay/DesignRoot/Background")
	var level_complete_material := level_complete_background.material as ShaderMaterial
	assert(level_complete_material != null)
	assert(level_complete_material.get_shader_parameter("pixel_block_size") == 6.0)
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
	var block_letters := generated.get_node("Crates/Crate_3_2/RigidBody3D").find_children("Letter", "Label3D", true, false)
	assert(block_letters.size() == 5, "Movable blocks must show a letter on every visible face")
	var pixel_letter := block_letters[0] as Label3D
	assert(pixel_letter.font_size == 32 and is_equal_approx(pixel_letter.pixel_size, 0.024), "Block letters must render at a visibly pixelated resolution")
	assert(pixel_letter.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Block letters must use nearest-neighbor filtering")
	assert(pixel_letter.alpha_cut == Label3D.ALPHA_CUT_DISCARD, "Block letters must use crisp one-bit edges")
	assert(pixel_letter.outline_size == 2 and pixel_letter.outline_modulate == Color.BLACK, "Block letters must have a thin black border")
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
	main.set("completion_idle_settle_duration", 0.05)
	main.set("completion_turn_duration", 0.0)
	main.set("completion_cheese_descent_duration", 0.12)
	main.set("completion_cheese_disappear_duration", 0.0)
	main.set("completion_reach_blend_duration", 0.0)
	main.set("completion_reach_release_duration", 0.12)
	main.set("completion_camera_return_duration", 0.0)
	main.set("completion_dance_duration_override", 0.25)
	var completion_popup: CanvasLayer = main.get_node("LevelCompletePopup")
	completion_popup.set("entrance_duration", 0.08)
	main.get_node("CloudflareLeaderboardClient").api_base_url = ""
	for child in generated.get_node("Crates").get_children():
		child.get_node("RigidBody3D").global_position = Vector3(20, 0.5, 20)
	for i in 7:
		generated.get_node("Crates").get_child(i).get_node("RigidBody3D").global_position = generated.get_node("Targets").get_child(i).global_position + Vector3(0, 0.5, 0)
	for i in 10:
		await get_tree().physics_frame
		if main.get_node("LevelGoal").is_level_completed:
			break
	assert(main.get_node("LevelGoal").is_level_completed, "Generated targets must complete the level")
	assert(not score_hud.is_tracking, "Score timer must stop when the level is complete")
	assert(not completion_popup.visible, "Completion popup must wait until the reward sequence finishes")
	assert(not main.get_node("Player").is_physics_processing(), "Player movement must lock during the completion sequence")
	await get_tree().process_frame
	assert(main.get("completion_phase") == "idle", "Player must transition to idle before turning toward the camera")
	assert(character_animation_tree["parameters/movement/current_state"] == "idle")
	await get_tree().create_timer(0.06).timeout
	assert(main.get("completion_phase") == "cheese", "Cheese must descend before the chicken dance")
	var reward_cheese := main.get("active_reward_cheese") as Node3D
	assert(is_instance_valid(reward_cheese), "Cheese reward must be visible during its descent")
	assert(main.get("completion_camera_active"), "Completion camera must activate for the cheese descent")
	assert(not main.get_node("Player/CameraPivot/Camera3D").is_processing(), "Normal camera follow must pause during the cheese shot")
	assert(main.get("completion_cheese_contact_height") < 1.48, "Cheese contact point must reach lower than the original descent")
	assert(reward_cheese.global_position.y > main.get_node("Player").global_position.y + main.get("completion_cheese_contact_height"), "Cheese must begin above the player's head")
	assert(is_equal_approx(character_model.get("cheese_reach_weight"), 1.0), "Head and arms must blend into the cheese-reaching pose")
	assert(character_animation_tree.active, "Animation tree must remain active beneath the procedural reach pose")
	var reach_modifier: SkeletonModifier3D = character_model.get_node("rat-albert-animated/Armature/Skeleton3D/CheeseReachModifier")
	assert(reach_modifier.active and is_equal_approx(reach_modifier.influence, 1.0), "Local-bone reach modifier must fully preserve the raised-arm pose")
	assert(reach_modifier.get("target_rotations").size() == 6, "Reach modifier must control the neck, head, and both arm chains")
	var camera_direction: Vector3 = main.get_node("Player/CameraPivot/Camera3D").global_position - main.get_node("Player").global_position
	camera_direction.y = 0.0
	var player_forward: Vector3 = main.get_node("Player/Pivot").global_transform.basis.z
	player_forward.y = 0.0
	var camera_facing_dot := player_forward.normalized().dot(camera_direction.normalized())
	assert(camera_facing_dot > 0.95, "Player must face the camera before the cheese descends (dot=%f)" % camera_facing_dot)
	await get_tree().create_timer(0.14).timeout
	assert(main.get("completion_phase") == "dance", "Chicken dance must start after the cheese touches the player")
	assert(not is_instance_valid(main.get("active_reward_cheese")), "Cheese must disappear before the chicken dance")
	assert(not main.get("completion_camera_active"), "Completion camera must return before the dance")
	var completion_camera_target: Node3D = main.get_node("Player/CameraPivot/CameraPosition")
	assert(completion_camera_target.position.is_equal_approx(main.get("default_camera_target_position") * main.get("completion_camera_distance_ratio")), "Returned camera must keep the previous view one-third closer")
	assert(character_animation_tree["parameters/movement/current_state"] == "chicken_dance")
	assert(character_animation_tree.active and character_model.get("cheese_reach_weight") > 0.0, "Raised-arm pose must overlap the start of the dance")
	assert(is_equal_approx(movement_transition.xfade_time, CharacterModel.CELEBRATION_CROSSFADE), "Chicken dance must use the smoother celebration crossfade")
	assert(movement_transition.xfade_time >= 0.75, "Celebration crossfade must be long enough to avoid a snappy arm transition")
	await get_tree().create_timer(0.14).timeout
	assert(is_zero_approx(character_model.get("cheese_reach_weight")), "Raised-arm overlay must finish fading during the dance")
	assert(not reach_modifier.active, "Reach modifier must deactivate after its blend into the dance")
	await get_tree().create_timer(0.22).timeout
	assert(completion_popup.visible, "Completion popup must appear after the dance")
	assert(not completion_popup.get("is_entering"), "Completion popup entrance must finish")
	assert(completion_popup.get("entrance_start_position").y > get_viewport().get_visible_rect().size.y)
	var completion_design_root: Control = completion_popup.get_node("Overlay/DesignRoot")
	assert(completion_design_root.position.is_equal_approx(completion_popup.get("resting_position")))
	print("PASS: parsing, animations, score tracking, pause behavior, pushes, cheese reward, completion dance and popup entrance")
	get_tree().quit()
