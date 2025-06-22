extends CharacterBody3D

# Units are m/s
@export_group("Movement (mps)")
@export var speed_forward_max: float = 10
@export var speed_reverse_max: float = 3
@export var speed_acceleration: float = 1
var speed_current: float = 0

@export_group("Rotation (deg-p-s)")
@export var rot_angle_max: float = 30
@export var rot_acceleration: float = 1
var rot_current: float = 0

func _process(delta: float) -> void:
	var input_forward = Input.get_action_strength("move_forward") * delta * speed_acceleration
	var input_backward = Input.get_action_strength("move_backward") * delta * speed_acceleration

	if input_forward > 0:
		speed_current = min(speed_forward_max, speed_current + input_forward)
	if input_backward > 0:
		speed_current = min(speed_forward_max, speed_current - input_backward)
	if input_forward < 0.0001 and input_backward < 0.0001 and absf(speed_current) < 0.05:
		speed_current = move_toward(speed_current, 0, delta)

	var input_rot = Input.get_axis("move_starboard", "move_portside") * delta * rot_acceleration
	rot_current = clampf(rot_current + input_rot, -rot_angle_max, rot_angle_max)

func _physics_process(delta: float) -> void:
	position += Vector3.FORWARD * speed_current * delta
	var rot_delta = rot_current * delta

	var speed_factor = 1
	if speed_current > 0:
		speed_factor = 1 - speed_current / speed_forward_max
	else:
		speed_factor = 1 - speed_current / speed_reverse_max

	var rot_influenced = lerpf(rot_delta, 0, speed_factor)
	rotation.y += deg_to_rad(rot_influenced)

	move_and_slide()
