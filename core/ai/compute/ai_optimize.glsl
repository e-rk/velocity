#[compute]
#version 450

#include "ai_globals.glsl.inc"

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(push_constant) uniform Params {
	uint num_points; // Offset 0
	uint num_obstacles; // Offset 4
	float distance_scale; // Offset 8
	float obstacle_scale; // Offset 12
	float curvature_scale; // Offset 16
	float walls_scale; // Offset 20
	float obstacle_separation; // Offset 24
	float wall_separation; // Offset 28
	float alpha; // Offset 32
	float beta; // Offset 36
	float radius; // Offset 40
	uint iteration;
} params;

layout(set = 1, binding = 0, std430) buffer PathOffsetBuffer {
	float x[];
} path_offset_buffer;

struct Obstacle {
	uint idx;
	float offset;
	float radius;
};

layout(set = 1, binding = 1, std430) buffer ObstaclesBuffer {
	Obstacle x[];
} obstacles_buffer;

layout(set = 1, binding = 2, std430) buffer MomentumBuffer {
	float x[];
} momentum_buffer;

shared vec3 sh_pos[64 + 4];

float hinge_penalty_sq_gradient(float t, float y) {
	return -2.0 * max(0.0, t - y);
}

float distance_penalty_sq_gradient(float t, float y) {
	return 2.0 * (y - t);
}

float barrier_penalty_gradient(float margin) {
	return -1.0 / margin;
}

float epsilon_insensitive_sq_gradient(float epsilon, float y, float x) {
	float gap = y - x;
	return sign(gap) * max(0.0, abs(gap) - epsilon);
}

uint idx_wrapped(uint i, int diff) {
	int added = int(i) + diff;
	if (added < 0) {
		return uint(added + params.num_points);
	} else if (added >= params.num_points) {
		return uint(added - params.num_points);
	}
	return uint(added);
}

vec3 get_position(uint i) {
	uint base = i * 3;
	vec3 wp = vec3(
			path_point_buffer.points[base],
			path_point_buffer.points[base + 1],
			path_point_buffer.points[base + 2]
		);
	vec3 n = vec3(
			path_normal_buffer.x[base],
			path_normal_buffer.x[base + 1],
			path_normal_buffer.x[base + 2]
		);
	return wp + path_offset_buffer.x[i] * n;
}

void main() {
	uint i = gl_GlobalInvocationID.x;
	uint local_i = gl_LocalInvocationID.x;
	float x = path_offset_buffer.x[i];
	float left_wall = path_left_wall_buffer.x[i] - params.wall_separation;
	float right_wall = path_right_wall_buffer.x[i] - params.wall_separation;
	float left_wall_eps = left_wall - 1e-3;
	float right_wall_eps = right_wall - 1e-3;

	sh_pos[local_i + 2] = get_position(i);

	if (local_i == 0) {
		uint idx = idx_wrapped(i, -2);
		sh_pos[0] = get_position(idx);
		idx = idx_wrapped(i, -1);
		sh_pos[1] = get_position(idx);
	}
	if (local_i == (gl_WorkGroupSize.x - 1) || i == (params.num_points - 1)) {
		uint idx = idx_wrapped(i, 1);
		sh_pos[local_i + 3] = get_position(idx);
		idx = idx_wrapped(i, 2);
		sh_pos[local_i + 4] = get_position(idx);
	}

	vec3 n_i = vec3(
			path_normal_buffer.x[i * 3],
			path_normal_buffer.x[i * 3 + 1],
			path_normal_buffer.x[i * 3 + 2]
		);

	barrier();

	float g_curvature = 0.0;
	for (uint j = 0; j < 3; j++) {
		vec3 C = sh_pos[local_i + j]
				- 2.0 * sh_pos[local_i + j + 1]
				+ sh_pos[local_i + j + 2];

		float weight = (j == 1) ? -4.0 : 2.0;
		g_curvature += weight * dot(C, n_i);
	}

	float middle = (-left_wall + right_wall) / 2.0;
	float epsilon = (right_wall + left_wall) / 2.0;
	float distance_gap = 0 - x;
	float g_distance = -epsilon_insensitive_sq_gradient(epsilon, middle, x);

	float g_obstacles = 0.0;

	for (uint j = 0; j < params.num_obstacles; j++) {
		int distance = int(i) - int(obstacles_buffer.x[j].idx);
		if (abs(distance) > 1) {
			continue;
		}
		float weight = 1.0 - 0.5 * abs(distance);
		float required_separation = obstacles_buffer.x[j].radius + params.obstacle_separation;
		float gap = x - obstacles_buffer.x[j].offset;
		float g_penalty = sign(gap) * hinge_penalty_sq_gradient(required_separation, abs(gap)) * weight;
		g_obstacles += g_penalty;
	}

	float g_walls = barrier_penalty_gradient(x + left_wall)
			- barrier_penalty_gradient(right_wall - x);

	float g = params.distance_scale * g_distance
			+ params.obstacle_scale * g_obstacles
			+ params.curvature_scale * g_curvature
			+ params.walls_scale * g_walls;

	float previous_momentum = momentum_buffer.x[i];

	if (params.iteration == 0) {
		previous_momentum = 0.0;
	}

	float next_momentum = params.beta * previous_momentum - params.alpha * g;

	float x_new = x + next_momentum;
	x_new = clamp(x_new, -left_wall_eps, right_wall_eps);
	path_offset_buffer.x[i] = x_new;
	momentum_buffer.x[i] = next_momentum;
}
