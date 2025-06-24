extends Node3D
class_name Binoculars

@export_group("Control settings")
@export var sensitivity := 1.0

@export_group("Settings")
@export var target_fov := 30.0

@export_group("Lerp")
@export var lerp_time_seconds := 1.5
@export var lerp_error_threshold_percentage := 0.00001

@export_group("Vignette")
@export var target_radius := 0.35

var old_camera: Camera3D
var old_mouse_mode: Input.MouseMode
var transitioning := false

@onready var original_local_position := position
@onready var camera: Camera3D = $Camera
@onready var vignette: ColorRect = $Camera/Vignette
var invisible_vignette_radius := 2.0
var current_vignette_radius := 2.0

var mouse_delta := Vector2(0, 0)
var current_pitch_degrees := 0.0

func _process(delta: float) -> void:
	var lerp_speed := -log(lerp_error_threshold_percentage) / lerp_time_seconds
	if Input.is_action_pressed("look_binoculars"):
		if not camera.current:
			old_camera = get_viewport().get_camera_3d()
			old_mouse_mode = Input.get_mouse_mode()
			
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			global_transform = old_camera.global_transform
		
		camera.current = true
		
		var cur_pos := camera.global_position
		var target_pos: Vector3 = get_parent().global_position + original_local_position
		transitioning = cur_pos.distance_to(target_pos) > 0.5

		if cur_pos.distance_to(target_pos) < 20.0:
			_update_mouselook()

		if transitioning:
			# Rotation
			camera.look_at(target_pos)

			# Position
			camera.global_position = Vector3(
				lerpf(cur_pos.x, target_pos.x, 1.0 - exp(-lerp_speed * delta)),
				lerpf(cur_pos.y, target_pos.y, 1.0 - exp(-lerp_speed * delta * 1.05)),
				lerpf(cur_pos.z, target_pos.z, 1.0 - exp(-lerp_speed * delta))
			)

			# fov
			camera.fov = lerpf(
				camera.fov,
				target_fov,
				1.0 - exp(-lerp_speed * delta * 0.6))

			current_vignette_radius = lerpf(current_vignette_radius, target_radius, 1.0 - exp(-lerp_speed * delta));
			vignette.set_instance_shader_parameter("radius", current_vignette_radius)
		else:
			camera.global_position = target_pos
			# fov
			camera.fov = lerpf(
				camera.fov,
				target_fov,
				1.0 - exp(-lerp_speed * delta))

			vignette.set_instance_shader_parameter("radius", target_radius)

			_update_mouselook()
			old_camera.global_rotation = camera.global_rotation
	elif camera.current:
		# Transition back to old camera
		var cur_pos := camera.global_position
		var target_pos: Vector3 = old_camera.global_position

		transitioning = cur_pos.distance_to(target_pos) > 2.0

		if transitioning:
			# fov
			camera.fov = lerpf(
				camera.fov,
				old_camera.fov,
				1.0 - exp(-lerp_speed * delta * 0.9))

			# Rotation
			var cur_global_rotation := camera.global_basis.get_rotation_quaternion()
			var target_global_rotation := old_camera.global_basis.get_rotation_quaternion()
			camera.global_basis = Basis(cur_global_rotation.slerp(target_global_rotation, 1.0 - exp(-lerp_speed * delta * 1.1)))

			# Position
			camera.global_position = Vector3(
				lerpf(cur_pos.x, target_pos.x, 1.0 - exp(-lerp_speed * delta)),
				lerpf(cur_pos.y, target_pos.y, 1.0 - exp(-lerp_speed * delta * 1.15)),
				lerpf(cur_pos.z, target_pos.z, 1.0 - exp(-lerp_speed * delta))
			)

			current_vignette_radius = lerpf(current_vignette_radius, invisible_vignette_radius, 1.0 - exp(-lerp_speed * delta));
			vignette.set_instance_shader_parameter("radius", current_vignette_radius)
			current_pitch_degrees = 0.0
		else:
			Input.set_mouse_mode(old_mouse_mode)
			old_camera.current = true

			camera.fov = old_camera.fov
			camera.rotation = Vector3.ZERO
			current_pitch_degrees = 0.0
			camera.position = original_local_position
			vignette.set_instance_shader_parameter("radius", invisible_vignette_radius)

func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				# TODO: disable cannon moving thing
				pass

func _update_mouselook():
	mouse_delta *= sensitivity * 0.1
	var yaw = mouse_delta.x
	var pitch = mouse_delta.y
	mouse_delta = Vector2(0, 0)
	
	pitch = clamp(pitch, -90 - current_pitch_degrees, 90 - current_pitch_degrees)
	current_pitch_degrees += pitch
	
	camera.global_rotate(Vector3.UP, deg_to_rad(-yaw))
	camera.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
