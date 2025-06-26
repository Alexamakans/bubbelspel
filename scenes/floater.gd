extends Node3D
class_name Floater

@export var water_drag: float = 0.99
@export var water_angular_drag: float = 0.5
@export var force_multiplier: float = 1.0

@export var enabled: bool = true

@onready var world: World = World.find_world_from_parent(self)
@onready var body: RigidBody3D = find_rigidbody()

var depth_before_submerged: float = 1.0
var floater_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# var parent_weight = $"../".weight
	# How many floater children does the parent have?
	for c in get_parent().get_children():
		if c.get_script() == get_script():
			floater_count += 1

func find_rigidbody() -> RigidBody3D:
	var node: Node = self
	while node != null:
		node = node.get_parent()
		if node is RigidBody3D:
			return node
	return null

func _physics_process(_delta: float) -> void:
	if not enabled:
		return

	# It had to be a world coord offset.... not just relative to the parent...
	# reeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
	var world_coord_offset = global_position - (body.center_of_mass + body.global_position)

	var wave = world.water.get_wave(global_position.x, global_position.z)
	var wave_height = wave.y
	var height = global_position.y

	# Gravity
	body.apply_force(Vector3.DOWN * 9.8, world_coord_offset)

	if height < wave_height:
		var buoyancy = clamp((wave_height - height) / depth_before_submerged, 0, 1) * 2 * force_multiplier
		body.apply_force(Vector3(0, 9.8 * buoyancy, 0), world_coord_offset)
		body.apply_central_force(buoyancy * -body.linear_velocity * water_drag)
		body.apply_torque(buoyancy * -body.angular_velocity * water_angular_drag)
	if $Marker:
		$Marker.global_position = Vector3(global_position.x, wave_height, global_position.z)
