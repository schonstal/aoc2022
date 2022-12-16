extends Control
@onready var input_box = %Input
@onready var output = %Output
@export var y = 2_000_000
@export_multiline var input = ""

var sensors = []

class Sensor:
  var position:Vector2
  var target:Vector2
  
  var radius:int:
    get:
      return abs(position.x - target.x) + abs(position.y - target.y)

  var polygon:PackedVector2Array:
    get:
      return PackedVector2Array([
        Vector2(position.x - radius, position.y),
        Vector2(position.x, position.y - radius),
        Vector2(position.x + radius, position.y),
        Vector2(position.x, position.y + radius)
      ])
  
  func _init(position:Vector2, target:Vector2):
    self.position = position
    self.target = target
    
  func y_intersections(y:int) -> PackedVector2Array:
    var result = Geometry2D.intersect_polyline_with_polygon(
      PackedVector2Array([
        Vector2(500000000, y),
        Vector2(-500000000, y)
      ]),
      polygon
    )[0]
    result[1].x += 1
    return result
  
func _ready():
  execute()
  
func execute():
  var polylines = parse_input().map(func(s):
    if abs(s.position.y - y) <= s.radius:
      return s.y_intersections(y)
  ).filter(func(s): return s != null)
  
  # The line is contiguous in this case so just taking the endpoints works
  polylines.sort_custom(func(a,b): return a[0].x < b[0].x)
  var sum = polylines[polylines.size() - 1][1].x - polylines[0][0].x
  output.text = "%d" % (round(sum) - 1)
  print(output.text)

func parse_input():
  var regex = RegEx.new()
  regex.compile("-?\\d+")

  for line in input.split("\n"):
    var result = regex.search_all(line).map(
      func(s): return s.get_string().to_int()
    )
    if result.size() == 4:
      sensors.push_front(Sensor.new(
        Vector2(result[0], result[1]),
        Vector2(result[2], result[3])
      ))
  return sensors

func _draw():
  var scale = 10_000
  for sensor in sensors:
    var smallygon = []
    for vertex in sensor.polygon:
      smallygon.push_back(vertex / scale)
      draw_colored_polygon(PackedVector2Array(smallygon), Color(Color.MEDIUM_SPRING_GREEN, 0.2))

  draw_polyline(PackedVector2Array([
      Vector2(500000000, y) / scale,
      Vector2(-500000000, y) / scale
    ]), Color.CRIMSON)
