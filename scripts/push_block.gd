extends RigidBody3D

@export var push_impulse := 4.0

@onready var front_zone: Area3D = $PushZones/FrontZone
@onready var back_zone: Area3D = $PushZones/BackZone
@onready var left_zone: Area3D = $PushZones/LeftZone
@onready var right_zone: Area3D = $PushZones/RightZone

var player: Node = null
var push_direction := Vector3.ZERO

func _ready() -> void:
	front_zone.body_entered.connect(_on_front_zone_body_entered)
	front_zone.body_exited.connect(_on_zone_body_exited)

	back_zone.body_entered.connect(_on_back_zone_body_entered)
	back_zone.body_exited.connect(_on_zone_body_exited)

	left_zone.body_entered.connect(_on_left_zone_body_entered)
	left_zone.body_exited.connect(_on_zone_body_exited)

	right_zone.body_entered.connect(_on_right_zone_body_entered)
	right_zone.body_exited.connect(_on_zone_body_exited)

func _on_front_zone_body_entered(body: Node3D) -> void:
	_register_player(body, -global_transform.basis.z)

func _on_back_zone_body_entered(body: Node3D) -> void:
	_register_player(body, global_transform.basis.z)

func _on_left_zone_body_entered(body: Node3D) -> void:
	_register_player(body, global_transform.basis.x)

func _on_right_zone_body_entered(body: Node3D) -> void:
	_register_player(body, -global_transform.basis.x)

func _on_zone_body_exited(body: Node3D) -> void:
	if body == player:
		if player.interact_pressed.is_connected(_on_player_interact_pressed):
			player.interact_pressed.disconnect(_on_player_interact_pressed)

		player = null
		push_direction = Vector3.ZERO

		print("player exited")

func _register_player(body: Node3D, direction: Vector3) -> void:
	if not body.is_in_group("player"):
		return
	
	print("player entered")
	
	player = body
	push_direction = direction

	if not player.interact_pressed.is_connected(_on_player_interact_pressed):
		player.interact_pressed.connect(_on_player_interact_pressed)

func _on_player_interact_pressed() -> void:
	push(push_direction)

func push(direction: Vector3) -> void:
	direction.y = 0

	if direction.length_squared() == 0:
		return

	apply_central_impulse(direction.normalized() * push_impulse)
