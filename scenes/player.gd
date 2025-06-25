extends RigidBody3D

# Units are m/s
@export_group("Movement (mps)")
@export var speed_forward_max: float = 10.0
@export var speed_reverse_max: float = 3.0
@export var speed_acceleration: float = 1.0
var speed_current: float = 0

@export_group("Rotation (deg-p-s)")
@export var rot_angular_velocity_max: float = rad_to_deg(PI/16.0)
@export var rot_acceleration: float = rad_to_deg(PI/32.0)
@export var rot_scale_curve: Curve
var rot_current: float = 0.0

@export_group("UI")
@export var speed_forward_bar: ProgressBar
@export var speed_reverse_bar: ProgressBar
@export var rot_starboard_bar: ProgressBar
@export var rot_portside_bar: ProgressBar

@onready var pid_x: PIDController = $PIDController_X
@onready var pid_z: PIDController = $PIDController_Z

func _process(delta: float) -> void:
	var input_forward: float = Input.get_action_strength("move_forward") * delta * speed_acceleration
	var input_backward: float = Input.get_action_strength("move_backward") * delta * speed_acceleration

	if input_forward > 0:
		speed_current = min(speed_forward_max, speed_current + input_forward)
	if input_backward > 0:
		speed_current = max(-speed_reverse_max, speed_current - input_backward)
	if input_forward < 0.0001 and input_backward < 0.0001 and absf(speed_current) < 0.05:
		speed_current = move_toward(speed_current, 0, delta)

	speed_forward_bar.value = maxf(0, speed_current / speed_forward_max)
	speed_reverse_bar.value = maxf(0, -speed_current / speed_reverse_max)

	var input_rot = Input.get_axis("move_starboard", "move_portside") * delta * rot_acceleration
	rot_current = clampf(rot_current + input_rot, -rot_angular_velocity_max, rot_angular_velocity_max)

	rot_portside_bar.value = maxf(0, rot_current / rot_angular_velocity_max)
	rot_starboard_bar.value = maxf(0, -rot_current / rot_angular_velocity_max)


func _physics_process(delta: float) -> void:
	movement()
	stay_upright(delta)

func movement() -> void:
	var f = -global_transform.basis.z * speed_current
	linear_velocity = Vector3(f.x, linear_velocity.y, f.z)
	
	var speed_factor: float = 1
	if speed_current > 0:
		speed_factor = speed_current / speed_forward_max
	else:
		speed_factor = abs(speed_current / speed_reverse_max)
	
	var rot_influenced = rot_current * rot_scale_curve.sample(speed_factor)
	angular_velocity.y = deg_to_rad(rot_influenced)

func stay_upright(delta: float) -> void:
	var x_torque: float = pid_x.update(global_basis.get_euler().x, 0, delta)
	var z_torque: float = pid_z.update(global_basis.get_euler().z, 0, delta)
	var torque := Vector3(x_torque, 0, z_torque)
	apply_torque(torque * 100)
