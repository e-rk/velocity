shader_type spatial;
render_mode blend_add, depth_draw_never, unshaded, depth_test_disabled;

uniform vec3 color : source_color = vec3(1.0, 1.0, 1.0);
uniform float intensity : hint_range(0.1, 20.0) = 5.0;
uniform float core_size : hint_range(0.001, 0.5) = 0.06;

uniform int spike_count : hint_range(2, 12) = 7;
uniform float spike_sharpness : hint_range(1.0, 50.0) = 10.5;
uniform float star_strength : hint_range(0.0, 1.0) = 0.16;

uniform float shrink_amount : hint_range(0.0, 10.0) = 1.8;
uniform float proximity_range : hint_range(0.1, 5.0) = 0.58;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying float v_angle_factor;

void vertex() {
	vec3 view_space_plane_normal = normalize(MODELVIEW_NORMAL_MATRIX * vec3(0.0, 0.0, 1.0));

	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
        INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	float position_angle_factor = dot(view_space_plane_normal, normalize(NODE_POSITION_VIEW));
	v_angle_factor = max(position_angle_factor, 0.0);
}

void fragment() {
	float size_scale = mix(1.0 + shrink_amount, 1.0, v_angle_factor);
	vec2 coord_from_center = (UV - vec2(0.5)) * size_scale;
	float angle = atan(coord_from_center.x, coord_from_center.y);
	float distance_from_center = length(coord_from_center);
	float spikes = pow(abs(cos(0.5 * float(spike_count) * angle)), spike_sharpness);
	float halo = core_size / (distance_from_center + core_size);
	float shape = halo + (spikes * star_strength);
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float glare_depth = -VERTEX.z;
	float depth_from_obstacle = linear_depth - glare_depth;
	float depth_mask = clamp(depth_from_obstacle + proximity_range, 0.0, 1.0);
	ALBEDO = color * intensity;
	EMISSION = color * intensity;
	ALPHA = v_angle_factor * shape * smoothstep(0.5, 0.0, distance_from_center) * depth_mask;
}