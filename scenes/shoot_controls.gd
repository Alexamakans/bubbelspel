extends Node3D
class_name ShootControls

@export_group("Settings")
@export var cannon: Node3D
@export var shots_per_second := 1.0

@onready var binoculars: Binoculars = $"../Binoculars"

var shot_cooldown_seconds: float:
	get():
		return 1.0 / shots_per_second

var can_shoot: bool:
	get():
		return (Time.get_ticks_msec() / 1000.0) - last_shot_seconds >= shot_cooldown_seconds

enum State {
	IDLE,
	SHOOTING,
	RELOADING
}

var state := State.IDLE
var last_shot_seconds := 0.0

func _process(delta: float) -> void:
	if state == State.RELOADING and can_shoot:
		state = State.IDLE

func _physics_process(delta: float) -> void:
	if state == State.SHOOTING:
		print("physics process")
		var camera := get_viewport().get_camera_3d()
		var bullet := preload("res://scenes/bullet.tscn")
		var from = camera.project_ray_origin(Vector2(0, 0))
		var to = from + -camera.global_basis.z * 50.0

		var collision_mask := 1
		var query = PhysicsRayQueryParameters3D.create(from, to,
			collision_mask, [get_parent()])
		var result = get_world_3d().direct_space_state.intersect_ray(query)

		print("result = ", result)
		var target: Vector3
		if result:
			target = result.position
		else:
			target = to

		print("waow")
		# TODO: What do if no result?
		var bullet_instance := bullet.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = cannon.global_position
		print("created bullet")

		var angle_and_speed := calculate_angle_and_speed(1.0, target)
		var angle := angle_and_speed.x
		var speed := angle_and_speed.y
		assert(speed >= 0)
		var forward := -camera.global_basis.z
		var yaw := atan2(forward.x, -forward.z)
		var dir := Vector3.FORWARD.rotated(Vector3.RIGHT, angle).rotated(Vector3.UP, -yaw)
		bullet_instance.apply_impulse(dir * speed, Vector3.ZERO)

		last_shot_seconds = Time.get_ticks_msec() / 1000.0
		state = State.RELOADING

func calculate_angle_and_speed(flight_time: float, target: Vector3) -> Vector2:
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	assert(g >= 0)
	var y0 := cannon.global_position.y - target.y
	print("y0 = ", y0)
	var speed := 0.5 * g * flight_time**2 - y0
	var R := ((target - cannon.global_position) * Vector3(1, 0, 1)).length()
	var angle := atan(speed/R)
	if speed < 0:
		return -Vector2(angle, speed)
	return Vector2(angle, speed)

func _input(event: InputEvent) -> void:
	if not can_shoot:
		state = State.RELOADING
		print("RELOADING")
	elif event.is_action_pressed("shoot"):
		state = State.SHOOTING
		print("SHOOOOOOOOOOOTING")
	else:
		state = State.IDLE
		print("IDLE")
