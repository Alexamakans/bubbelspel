extends Node3D
class_name Binoculars

@export_group("Settings")
@export var mount_location: RemoteTransform3D
@export var target_fov := 30.0

@export_group("Control settings")
@export var pitch_sensitivity := 1.0
@export var yaw_sensitivity := 1.0

@export_group("Lerp")
@export var curve: Curve
@export var lerp_time_seconds := 1.5

@export_group("Vignette")
@export var target_vignette_radius := 0.6

var old_camera: Camera3D
var old_mouse_mode: Input.MouseMode
var transitioning := false

@onready var parent := get_parent()
@onready var camera: Camera3D = $Camera
@onready var compass: TextureRect = $Camera/GUI/CenterContainer/Compass
@onready var vignette: ColorRect = $Camera/GUI/Vignette
const invisible_vignette_radius := 2.0
var current_vignette_radius := invisible_vignette_radius

var mouse_delta := Vector2(0, 0)
var zoomed_seconds := 0.0

enum State {
	ZOOMED_OUT,
	ZOOMED_IN,
	ZOOMING_IN,
	ZOOMING_OUT,
}
var state := State.ZOOMED_OUT

func _ready() -> void:
	compass.hide()
	mount_location.remote_path = get_path()

func _process(delta: float) -> void:
	if state == State.ZOOMED_OUT and Input.is_action_just_pressed("look_binoculars"):
		old_camera = get_viewport().get_camera_3d()
		old_mouse_mode = Input.get_mouse_mode()

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		global_transform = old_camera.global_transform
		mount_location.update_position = false

	if state == State.ZOOMING_IN or Input.is_action_pressed("look_binoculars"):
		zoom_in(delta)
	elif camera.current:
		zoom_out(delta)

func zoom_in(delta: float) -> void:
	zoomed_seconds = min(lerp_time_seconds, zoomed_seconds + delta)
	var t := curve.sample(zoomed_seconds / lerp_time_seconds)
	camera.current = true
	transitioning = t < 1

	if transitioning:
		state = State.ZOOMING_IN
		mount_location.update_position = false
		lerp_camera(t)
	else:
		state = State.ZOOMED_IN
		compass.show()
		mount_location.update_position = true
		camera.global_position = mount_location.global_position

		_update_mouselook(delta)
		old_camera.global_rotation = camera.global_rotation

func zoom_out(delta: float) -> void:
	zoomed_seconds = max(0, zoomed_seconds - delta)
	var t := curve.sample(zoomed_seconds / lerp_time_seconds)
	compass.hide()

	transitioning = t > 0

	if transitioning:
		state = State.ZOOMING_OUT
		mount_location.update_position = false
		lerp_camera(t)
	else:
		state = State.ZOOMED_OUT
		Input.set_mouse_mode(old_mouse_mode)
		old_camera.current = true
		camera.rotation = Vector3.ZERO

func lerp_camera(t: float) -> void:
	var orig_pos := old_camera.global_position
	var target_pos := mount_location.global_position

	# fov
	camera.fov = lerpf(old_camera.fov, target_fov, t)

	# Rotation
	camera.look_at(target_pos)

	# Position
	camera.global_position = Vector3(
		lerpf(orig_pos.x, target_pos.x, t),
		lerpf(orig_pos.y, target_pos.y, min(1, t * 1.08)), # makes it so we look horizontally when zoomed in
		lerpf(orig_pos.z, target_pos.z, t)
	)

	current_vignette_radius = lerpf(invisible_vignette_radius, target_vignette_radius, t);
	vignette.set_instance_shader_parameter("radius", current_vignette_radius)


func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				# TODO: disable cannon moving thing that doesn't exist yet
				pass

func _update_mouselook(delta: float) -> void:
	var yaw_delta_deg := mouse_delta.x * yaw_sensitivity * 0.1
	var pitch_delta_deg := -mouse_delta.y * pitch_sensitivity * 0.1
	mouse_delta.x = 0
	mouse_delta.y = 0

	var old_yaw_deg := get_yaw_degrees(-camera.global_basis.z)
	var target_yaw_deg := old_yaw_deg + yaw_delta_deg

	var old_pitch_deg := get_pitch_degrees(-camera.global_basis.z)
	var target_pitch_deg := old_pitch_deg + pitch_delta_deg
	pitch_delta_deg = clamp(pitch_delta_deg, -90 - target_pitch_deg, 90 - target_pitch_deg)
	target_pitch_deg += pitch_delta_deg

	var yaw_deg := target_yaw_deg
	var pitch_deg := target_pitch_deg
	#var yaw_deg := lerpf(old_yaw_deg, target_yaw_deg, 1.0 - exp(-lerp_speed * delta ))
	#var pitch_deg := lerpf(old_pitch_deg, target_pitch_deg, 1.0 - exp(-lerp_speed * delta))

	set_local_pitch_yaw_degrees(pitch_deg, yaw_deg)

func set_local_pitch_yaw_degrees(pitch: float, yaw: float) -> void:
	# pitch then yaw
	var offset := Vector3.FORWARD.rotated(Vector3.RIGHT, deg_to_rad(pitch)).rotated(Vector3.UP, deg_to_rad(-yaw))
	var target := camera.global_position + offset
	camera.look_at(target, Vector3.UP)

func get_yaw_degrees(forward: Vector3) -> float:
	return rad_to_deg(atan2(forward.x, -forward.z))

func get_pitch_degrees(forward: Vector3) -> float:
	forward = forward.normalized()
	return rad_to_deg(asin(forward.y))
