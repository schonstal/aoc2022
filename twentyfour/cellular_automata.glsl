#[compute]

#version 450
#define ELF   16
#define LEFT  8
#define DOWN  4
#define UP    2
#define	RIGHT 1

#define WIDTH 6
#define HEIGHT 4

#define INDEX(vector) (vector.x + vector.y * HEIGHT)
#define POSITION uvec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y + gl_WorkGroupID.y * 10)
#define OUT_OF_BOUNDS(p) (p.x > WIDTH || p.y > HEIGHT)

layout(local_size_x = 100, local_size_y = 10, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer InputBuffer {
	uint data[];
}
input_buffer;

layout(set = 0, binding = 1, std430) buffer OutputBuffer {
	uint data[];
}
output_buffer;

uvec2 neighbor_at(int x, int y) {
	ivec2 p = ivec2(POSITION);

	p.x = p.x + x;
	p.y = p.y + y;

	if (p.x < 0) {
		p.x += WIDTH;
	}
	if (p.y < 0) {
		p.y += HEIGHT;
	}

	p.x %= WIDTH;
	p.y %= HEIGHT;

	return uvec2(p);
}

void main() {
	uvec2 position = POSITION;
	if (OUT_OF_BOUNDS(position)) return;

	uint index = INDEX(position);
	uint result = 0;

	if (index == 0) {
		result |= ELF;
	}
	// make sure to preserve ELF
	result |= input_buffer.data[index] & ELF;

	uvec2 left = neighbor_at(-1, 0);
	result |= input_buffer.data[INDEX(left)] & RIGHT;
	if (position.x > 0) {
		result |= input_buffer.data[INDEX(left)] & ELF;
	}

	uvec2 down = neighbor_at(0, 1);
	result |= input_buffer.data[INDEX(down)] & UP;
	if (position.y < HEIGHT - 1) {
		result |= input_buffer.data[INDEX(down)] & ELF;
	}

	uvec2 up = neighbor_at(0, -1);
	result |= input_buffer.data[INDEX(up)] & DOWN;
	if (position.y > 0) {
		result |= input_buffer.data[INDEX(up)] & ELF;
	}

	uvec2 right = neighbor_at(1, 0);
	result |= input_buffer.data[INDEX(right)] & LEFT;
	if (position.x < WIDTH - 1) {
		result |= input_buffer.data[INDEX(right)] & ELF;
	}

	// if any direction is present, unset ELF
	if ((result & 15) > 0) {
		result &= 15;
	}

	output_buffer.data[index] = result;
}