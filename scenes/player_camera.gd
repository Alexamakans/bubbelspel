extends Camera3D

@export var focus_point: Node3D
@export var distance_min: float = 10
@export var distance_max: float = 100
@export var zoom_speed: float = 5
@export var y_look_speed: float = 10
@export var x_look_curve: Curve
@export var x_look_deg_close: float = 15
@export var x_look_deg_far: float = 30

@onready var input: PlayerInput = $"../PlayerInput"

var distance_current: float
var y_rad_current: float # aka yaw

func _ready() -> void:
	set_process(input.get_multiplayer_authority() == multiplayer.get_unique_id())

	var vector: Vector3 = focus_point.global_position - global_position
	distance_current = clampf(vector.length(), distance_min, distance_max)

	var camera_forward: Vector3 = -global_basis.z
	y_rad_current = atan2(camera_forward.x, -camera_forward.z)
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	if not current:
		var camera_forward: Vector3 = -global_basis.z
		y_rad_current = atan2(camera_forward.x, -camera_forward.z)
		update()
		return

	if input.input_zoom_in_just_pressed:
		distance_current -= zoom_speed * delta
		distance_current = clampf(distance_current, distance_min, distance_max)
	if input.input_zoom_out_just_pressed:
		distance_current += zoom_speed * delta
		distance_current = clampf(distance_current, distance_min, distance_max)

	update()


func update() -> void:
	var dist_01 = inverse_lerp(distance_min, distance_max, distance_current)
	var curved_t = x_look_curve.sample(dist_01)
	var x_rad = deg_to_rad(lerpf(x_look_deg_close, x_look_deg_far, curved_t))

	var x_rot = Quaternion.from_euler(Vector3(x_rad, 0, 0))
	var y_rot = Quaternion.from_euler(Vector3(0, y_rad_current, 0))
	var forward = Vector3.FORWARD * x_rot * y_rot
	#forward.y -= 0.5
	#forward = forward.normalized()

	global_position = focus_point.global_position - forward * distance_current
	look_at(focus_point.global_position)

func _input(event: InputEvent) -> void:
	if not current:
		return
	if event is InputEventMouseMotion:
		y_rad_current += deg_to_rad(event.relative.x * y_look_speed)

	elif event is InputEventMagnifyGesture:
		# TODO: i don't know if this even works
		distance_current += event.factor * zoom_speed
		distance_current = clampf(distance_current, distance_min, distance_max)
