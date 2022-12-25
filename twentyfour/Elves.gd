extends Node2D

enum cell_state {
	ELF   = 0b10000,
	LEFT  = 0b01000,
	DOWN  = 0b00100,
	UP    = 0b00010,
	RIGHT = 0b00001
}

var parse_map = {
	"<": cell_state.LEFT,
	">": cell_state.RIGHT,
	"v": cell_state.DOWN,
	"^": cell_state.UP,
	".": 0,
	"E": cell_state.ELF
}

var shader_file = preload("res://cellular_automata.glsl")
var x_groups = 0
var y_groups = 0
var buffer_size = 0
var content = """#.######
#>>.<^<#
#.<..<<#
#>v.><>#
#<^v^^>#
######.#
"""
var lines:PackedStringArray

var compute_thread:Thread
var rd:RenderingDevice

func _ready():
	compute_thread = Thread.new()
	compute_thread.start(find_generation)
	
func find_generation():
	var generation = 0
	var buffer = parse_input()
	var start = Time.get_ticks_msec()
	rd = RenderingServer.create_local_rendering_device()
	while buffer.decode_u32(buffer_size-4) != cell_state.ELF:
		buffer = compute_generation(buffer)
		generation += 1
	var end = Time.get_ticks_msec()
	print("completed in ", end - start, "ms")
	print(generation + 1)
	
func parse_input():
	var file = FileAccess.open("res://input.txt", FileAccess.READ)
	content = file.get_as_text()
	lines = content.split("\n")
	x_groups = lines[0].length() - 2
	y_groups = lines.size() - 3
	buffer_size = x_groups * y_groups * 4
	
	var buffer = PackedByteArray()
	buffer.resize(buffer_size)
	
	for y in y_groups:
		for x in x_groups:
			var index = (x + x_groups * y)
			# Add 1 to the indices in lines because of walls
			buffer.encode_u32(index * 4, parse_map[lines[y+1][x+1]])
			
	return buffer
	
func compute_generation(input_buffer:PackedByteArray) -> PackedByteArray:
	# Create shader and pipeline
	var shader_spirv = shader_file.get_spirv()
	var shader = rd.shader_create_from_spirv(shader_spirv)
	var pipeline = rd.compute_pipeline_create(shader)
	
	# Create storage buffers
	var output_buffer = PackedByteArray()
	output_buffer.resize(buffer_size)
	for i in range(buffer_size/4):
		output_buffer.encode_u32(i*4,0)
	
	var input_storage_buffer = rd.storage_buffer_create(buffer_size, input_buffer)
	var output_storage_buffer = rd.storage_buffer_create(buffer_size, output_buffer)
	
	# Create uniform set using the storage buffers
	var input_uniform = RDUniform.new()
	input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	input_uniform.binding = 0
	input_uniform.add_id(input_storage_buffer)
	
	var output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	output_uniform.binding = 1
	output_uniform.add_id(output_storage_buffer)
	
	var uniform_set = rd.uniform_set_create([input_uniform, output_uniform], shader, 0)

	# Perform computation and sync
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1, 4, 1)
	#rd.compute_list_add_barrier(compute_list)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	
	# Retrieve data
	var byte_data = rd.buffer_get_data(output_storage_buffer)
	return byte_data

func print_buffer(byte_data):
	var results = []
	for i in range(0, buffer_size, 4):
		var bits = byte_data.decode_u32(i)
		var result = "."
		for key in parse_map.keys():
			if bits & parse_map[key] > 0:
				if result == ".":
					result = key
				else:
					result = "2"
		results.push_back(result)
	for y in y_groups:
		var s = ""
		for x in x_groups:
			s += results[x + y*x_groups]
		print(s)
