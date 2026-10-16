shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// Cheap stylised water used for the canal in the Riverbank biome.
// Two crossed sine waves give vertical motion; a scrolling stripe pattern adds
// surface ripple without needing a normal map.

uniform vec3 shallow_color : source_color = vec3(0.30, 0.47, 0.40);
uniform vec3 deep_color : source_color = vec3(0.09, 0.24, 0.29);
uniform float wave_speed = 1.1;
uniform float wave_scale = 1.7;
uniform float wave_height = 0.05;
uniform float flow_speed = 0.18;
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.35;
uniform float water_roughness : hint_range(0.0, 1.0) = 0.16;
uniform float water_alpha : hint_range(0.0, 1.0) = 0.9;

varying float wave_offset;

void vertex() {
	float t = TIME * wave_speed;
	float w = sin(VERTEX.x * wave_scale + t) * wave_height
		+ sin(VERTEX.z * wave_scale * 0.72 - t * 1.35) * wave_height * 0.9;
	VERTEX.y += w;
	wave_offset = w;
}

void fragment() {
	vec2 uv = UV + vec2(0.0, TIME * flow_speed);
	float ripple = sin(uv.x * 38.0 + uv.y * 15.0) * 0.5 + 0.5;
	float blend = clamp(ripple * ripple_strength + wave_offset * 5.0 + 0.35, 0.0, 1.0);
	ALBEDO = mix(deep_color, shallow_color, blend);
	ROUGHNESS = water_roughness;
	METALLIC = 0.06;
	SPECULAR = 0.6;
	ALPHA = water_alpha;
}
