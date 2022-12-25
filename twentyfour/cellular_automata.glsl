#[compute]

#version 450
#define ELF   16
#define LEFT  8
#define DOWN  4
#define UP    2
#define	RIGHT 1

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer InputBuffer {
	uint data[];
}
input_buffer;

layout(set = 0, binding = 1, std430) buffer OutputBuffer {
	uint data[];
}
output_buffer;

void main() {
	uint result = 0;
	uint offset_y = (gl_NumWorkGroups.x * gl_WorkGroupID.y);
	uint index = gl_WorkGroupID.x + offset_y;

	// create an elf at the zero index
	if (index == 0) {
		result |= ELF;
	}

	// check left
	uint offset_x = gl_WorkGroupID.x > 0 ? gl_WorkGroupID.x - 1 : gl_NumWorkGroups.x - 1;
	uint offset_index = offset_x + offset_y;
	result |= input_buffer.data[offset_index] & RIGHT;
	if (gl_WorkGroupID.x > 0) {
		result |= input_buffer.data[offset_index] & ELF;
	}

	// check down
	uint new_y = (gl_WorkGroupID.y + 1) % gl_NumWorkGroups.y;
	uint new_offset_y = (gl_NumWorkGroups.x * new_y);
	offset_index = gl_WorkGroupID.x + new_offset_y;
	result |= input_buffer.data[offset_index] & UP;
	if (gl_WorkGroupID.y < gl_NumWorkGroups.y - 1) {
		result |= input_buffer.data[offset_index] & ELF;
	}

	// check up
	new_y = gl_WorkGroupID.y > 0 ? gl_WorkGroupID.y - 1 : gl_NumWorkGroups.y - 1;
	new_offset_y = (gl_NumWorkGroups.x * new_y);
	offset_index = gl_WorkGroupID.x + new_offset_y;
	result |= input_buffer.data[offset_index] & DOWN;
	if (gl_WorkGroupID.y > 0) {
		result |= input_buffer.data[offset_index] & ELF;
	}

	// check right
	offset_x = (gl_WorkGroupID.x + 1) % gl_NumWorkGroups.x;
	offset_index = offset_x + offset_y;
	result |= input_buffer.data[offset_index] & LEFT;
	if (gl_WorkGroupID.x < gl_NumWorkGroups.x - 1) {
		result |= input_buffer.data[offset_index] & ELF;
	}

	// check for existing elf
	result |= input_buffer.data[index] & ELF;

	// if any direction is present, unset ELF
	if ((result & 15) > 0) {
		result &= 15;
	}

	output_buffer.data[index] = result;
}