class_name PlayerInput
extends MultiplayerSynchronizer

@export var input_forward: float
@export var input_backward: float
@export var input_rot: float
@export var input_zoom_in_just_pressed: bool
@export var input_zoom_out_just_pressed: bool

func _ready() -> void:
	set_process(is_multiplayer_authority())

func _process(_delta: float) -> void:
	input_forward = Input.get_action_strength("move_forward")
	input_backward = Input.get_action_strength("move_backward")
	input_rot = Input.get_axis("move_starboard", "move_portside")

	input_zoom_in_just_pressed = Input.is_action_just_pressed("look_zoom_in")
	input_zoom_out_just_pressed = Input.is_action_just_pressed("look_zoom_out")
