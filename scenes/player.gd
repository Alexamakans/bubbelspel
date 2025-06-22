extends CharacterBody3D

@export var speed_forward_max: float = 10;
@export var speed_reverse_max: float = 3;
@export var speed_acceleration: float = 1;
var speed_current: float = 0;

func _process(delta: float) -> void:
    var input_forward = Input.get_action_strength("move_forward") * delta * speed_acceleration
    var input_backward = Input.get_action_strength("move_backward") * delta * speed_acceleration
    print(input_forward)

    if input_forward > 0:
        speed_current = min(speed_forward_max, speed_current + input_forward)
    if input_backward > 0:
        speed_current = min(speed_forward_max, speed_current - input_backward)

func _physics_process(_delta: float) -> void:
    position += Vector3.FORWARD * speed_current
    move_and_slide()
