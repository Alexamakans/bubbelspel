class_name Spinner3D
extends Node3D

@export var angular_velocity: Vector3
@export var speed_multiplier: float = 1

func _process(delta: float) -> void:
	rotation_degrees += angular_velocity * delta * speed_multiplier
