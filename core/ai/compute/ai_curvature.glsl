#[compute]
#version 450

#include "ai_globals.glsl.inc"

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(push_constant) uniform Params {
    uint num_points; // Offset 0
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

layout(set = 2, binding = 0, std430) restrict buffer PathCurvatureBuffer {
    float x[];
} path_curvature_buffer;

float curvature(vec3 p1, vec3 p2, vec3 p3) {
    vec3 p21 = p2 - p1;
    vec3 p31 = p3 - p1;
    float area = 0.5 * length(cross(p21, p31));
    return (4 * area) / (length(p21) * length(p31) * length(p3 - p2));
}

vec3 get_point(uint i) {
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
    vec3 p = wp + path_offset_buffer.x[i] * n;
    p.y = 0.0;
    return p;
}

void main() {
    uint i = gl_GlobalInvocationID.x;

    if (i >= params.num_points) {
        return;
    }

    uint prev_idx = (i - 1) % params.num_points;
    uint next_idx = (i + 1) % params.num_points;

    vec3 prev = get_point(prev_idx);
    vec3 curr = get_point(i);
    vec3 next = get_point(next_idx);

    vec3 diff = next - curr;
    float d = dot(diff, diff);
    path_curvature_buffer.x[i] = curvature(prev, curr, next);
}
