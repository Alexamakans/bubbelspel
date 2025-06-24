extends Node3D
class_name Floater

var depth_before_submerged = 1.0

var floater_count = 0

@export var water_drag = 0.99
@export var water_angular_drag = 0.5
@export var force_multiplier = 1.0

@export var enabled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	# var parent_weight = $"../".weight
	# How many floater children does the parent have?
	for c in get_parent().get_children():
		if c.get_script() == get_script():
			floater_count += 1

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	
	var p := get_parent()
	
	# It had to be a world coord offset.... not just relative to the parent...
	# reeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
	var world_coord_offset = global_position - (p.center_of_mass + p.global_position)
	
	var wave = Globals.instance.water.get_wave(global_position.x, global_position.z)
	var wave_height = wave.y
	var height = global_position.y
	
	# Gravity
	p.apply_force(Vector3.DOWN * 9.8, world_coord_offset)
	
	if height < wave_height:
		var buoyancy = clamp((wave_height - height) / depth_before_submerged, 0, 1) * 2 * force_multiplier
		p.apply_force(Vector3(0, 9.8 * buoyancy, 0), world_coord_offset)
		p.apply_central_force(buoyancy * -p.linear_velocity * water_drag)
		p.apply_torque(buoyancy * -p.angular_velocity * water_angular_drag)
	if $Marker:
		$Marker.global_position = Vector3(global_position.x, wave_height, global_position.z)
