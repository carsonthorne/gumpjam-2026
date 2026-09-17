extends State
class_name Motion

@export var camera: Camera3D

signal velocity_updated(vel: Vector3)
signal animation_state_changed(state: String)

const SPEED: float = 1.0
const RUN_SPEED: float = 1.75
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 9.8
const ACCELERATION: float = 12

static var input_dir: Vector2 = Vector2.ZERO
static var direction: Vector3 = Vector3.ZERO
static var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	velocity_updated.connect(owner.set_velocity_from_motion)

func set_direction() -> void:
	input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	direction = (Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)


func calculate_velocity(_speed: float, _direction: Vector3, delta: float) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, _direction.x * _speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, _direction.z * _speed, ACCELERATION * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	velocity_updated.emit(velocity)

func calculate_gravity(delta: float) -> void:
	if not owner.is_on_floor():
		velocity.y += GRAVITY * delta
