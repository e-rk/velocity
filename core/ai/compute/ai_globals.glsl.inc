
layout(set = 0, binding = 0, std430) restrict readonly buffer PathPointBuffer {
	float points[];
} path_point_buffer;

layout(set = 0, binding = 1, std430) restrict readonly buffer PathTargetBuffer {
	float x[];
} path_target_buffer;

layout(set = 0, binding = 2, std430) restrict readonly buffer PathLeftWallBuffer {
	float x[];
} path_left_wall_buffer;

layout(set = 0, binding = 3, std430) restrict readonly buffer PathRightWallBuffer {
	float x[];
} path_right_wall_buffer;

layout(set = 0, binding = 4, std430) restrict readonly buffer PathNormalBuffer {
	float x[];
} path_normal_buffer;
