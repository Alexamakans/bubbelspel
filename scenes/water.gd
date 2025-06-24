extends MeshInstance3D
class_name Water

var time = 0

var mat: ShaderMaterial

var wave_a: Vector3
var wave_a_dir: Vector2
var wave_b: Vector3
var wave_b_dir: Vector2
var wave_c: Vector3
var wave_c_dir: Vector2
#var wave_d: Vector3
#var wave_d_dir: Vector2
#var wave_e: Vector3
#var wave_e_dir: Vector2


func _ready():
	print("setting mat of water")
	mat = get_surface_override_material(0)
	print("finished setting mat of water")
	print(mat)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	mat.set_shader_parameter("time", time) 

func _physics_process(delta: float) -> void:
	wave_a = mat.get_shader_parameter("wave_a")
	wave_a_dir = mat.get_shader_parameter("wave_a_dir")
	wave_b = mat.get_shader_parameter("wave_b")
	wave_b_dir = mat.get_shader_parameter("wave_b_dir")
	wave_c = mat.get_shader_parameter("wave_c")
	wave_c_dir = mat.get_shader_parameter("wave_c_dir")
	#wave_d = mat.get_shader_parameter("wave_d")
	#wave_d_dir = mat.get_shader_parameter("wave_d_dir")
	#wave_e = mat.get_shader_parameter("wave_e")
	#wave_e_dir = mat.get_shader_parameter("wave_e_dir")

func dot(a: Vector2, b: Vector2):
	return (a.x * b.x) + (a.y * b.y)

func P(wave: Vector3, wave_dir: Vector2, p: Vector2, t: float) -> Vector3:
	var amplitude = wave.x
	var steepness = wave.y
	var wavelength = wave.z
	var k = 2.0 * PI / wavelength
	var c = sqrt(9.8 / k)
	var d = wave_dir.normalized()
	var f = k * (dot(d, p) - (c * t))
	var a = steepness / k
	
	var dx = d.x * a * cos(f)
	var dy = amplitude * a * sin(f)
	var dz = d.y * a * cos(f)
	
	return Vector3(dx, dy, dz)

func _get_wave(x: float, z: float):
	var v := Vector3(x, 0, z)
	v += P(wave_a, wave_a_dir, Vector2(x, z), time)
	v += P(wave_b, wave_b_dir, Vector2(x, z), time)
	v += P(wave_c, wave_c_dir, Vector2(x, z), time)
	#v += P(wave_d, wave_d_dir, Vector2(x, z), time)
	#v += P(wave_e, wave_e_dir, Vector2(x, z), time)
	return v

func get_wave(x: float, z: float):
	var v0 = _get_wave(x, z)
	var offset = Vector2(x - v0.x, z - v0.z)
	var v1 = _get_wave(x+offset.x/4.0, z+offset.y/4.0)
	
	return v1
