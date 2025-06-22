shader_type spatial;

render_mode unshaded, cull_back, depth_draw_opaque;

uniform float time_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 500.0) = 1.0;
uniform float wave_frequency : hint_range(0.0, 20.0) = 8.0;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

uniform vec3 shallow_color : source_color = vec3(0.0, 0.5, 0.7);
uniform vec3 deep_color : source_color = vec3(0.0, 0.1, 0.4);
uniform vec3 foam_color : source_color = vec3(0.8, 0.9, 1.0);

uniform float foam_threshold : hint_range(0.0, 1.0) = 0.9;
uniform float foam_blend : hint_range(0.01, 1.0) = 0.1;

uniform sampler2D noise_tex;

varying float wave_height;
varying vec3 world_pos;

void vertex() {
    float time = TIME * time_speed;
    vec3 vpos = VERTEX;

    // Base wave from sin/cos
    float wave = sin(vpos.x * wave_frequency + time * wave_speed) * 0.5
               + cos(vpos.z * wave_frequency * 0.7 + time * wave_speed * 1.2) * 0.5;

    // Optional noise-based perturbation
    //vec2 noise_uv = (vpos.xz / noise_scale);
    //float noise = texture(noise_tex, noise_uv).r;

    //wave += (noise - 0.5);

    wave *= wave_amplitude;
    VERTEX.y += wave;
    
    wave_height = wave;
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float depth_factor = clamp((wave_height / wave_amplitude + 1.0) * 0.5, 0.0, 1.0);
    vec3 base_color = mix(deep_color, shallow_color, depth_factor);

    // Simulate fresnel effect
    //vec3 view_dir = normalize(CAMERA_POSITION - world_pos);
    //float fresnel = pow(1.0 - dot(NORMAL, view_dir), 3.0);

    vec3 color = base_color;// + fresnel * 0.2;

    // Optional foam on peaks
    float foam_mask = smoothstep(foam_threshold - foam_blend, foam_threshold + foam_blend, depth_factor);
    color = mix(color, foam_color, foam_mask);

    ALBEDO = color;
}
