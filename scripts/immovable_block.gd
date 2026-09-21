extends "res://scripts/push_block.gd"

func _create_wood_material() -> Material:
	var shader := load("res://shaders/immovable_block_steel.gdshader") as Shader
	if shader != null:
		var material := ShaderMaterial.new()
		material.shader = shader
		return material

	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.36, 0.39, 0.38, 1.0)
	fallback.metallic = 0.65
	fallback.roughness = 0.58
	return fallback

func _add_block_face(_parent: Node3D, _normal: Vector3, _up: Vector3) -> void:
	pass

func _can_player_push_block() -> bool:
	return false

func push(_direction: Vector3) -> void:
	pass
