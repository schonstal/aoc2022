extends Control
@onready var input_box = %Input
@onready var output = %Output
@export var y = 2000000

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
    return Geometry2D.intersect_polyline_with_polygon(
      PackedVector2Array([
        Vector2(5000000, y),
        Vector2(-5000000, y)
      ]),
      polygon
    )[0]
  
func _ready():
  execute()
  
func execute():
  var polylines = parse_input().map(func(s):
    if abs(s.position.y - y) <= s.radius:
      return s.y_intersections(y)
  ).filter(func(s): return s != null)
  
  polylines.sort_custom(func(a,b): return a[0].x < b[0].x)
  var sum = 0
  for i in polylines.size():
    sum += polylines[i][1].x - polylines[i][0].x + 1
    if i > 0 && polylines[i-1][1].x >= polylines[i][0].x:
      sum -= polylines[i-1][1].x - polylines[i][0].x + 1
  
  output.text = "%d" % (round(sum) - 1)

func parse_input():
  var sensors = []
  var regex = RegEx.new()
  regex.compile("-?\\d+")

  for line in input_box.text.split("\n"):
    var result = regex.search_all(line).map(
      func(s): return s.get_string().to_int()
    )
    if result.size() == 4:
      sensors.push_front(Sensor.new(
        Vector2(result[0], result[1]),
        Vector2(result[2], result[3])
      ))
  return sensors
