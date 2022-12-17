extends Control
@onready var input_box = %Input
@onready var output = %Output
@export var y = 2_000_000
@export var width = 4_000_000
@export_multiline var input = ""

var sensors = []
var iter = 0
var solution:Vector2

var boundaries = [PackedVector2Array([
  Vector2.ZERO,
  Vector2(width, 0),
  Vector2(width, width),
  Vector2(0,width)
])]
  
func _ready():
  parse_input()
  part_one()
  part_two()
  
func part_one():
  var polylines = sensors.map(func(s):
    if abs(s.position.y - y) <= s.radius:
      return s.y_intersections(y)
  ).filter(func(s): return s != null)
  
  polylines.sort_custom(func(a,b): return a[0].x < b[0].x)
  var sum = polylines[polylines.size() - 1][1].x - polylines[0][0].x
  output.text = "%d" % (round(sum) - 1)
  print(output.text)

func part_two():
  var square_transform = Transform2D(-PI/4, Vector2.ZERO)
  boundaries[0] *= square_transform
  for sensor in sensors:
    sensor.transform = square_transform
    iter += 1
    var results = []
    
    for polygon in boundaries:
      for clip in Geometry2D.clip_polygons(polygon, sensor.polygon):
        if !Geometry2D.is_polygon_clockwise(clip):
          results.push_back(clip)
          
    boundaries = results
    sensor.transform = Transform2D.IDENTITY
    queue_redraw()    
    await get_tree().create_timer(0.1).timeout
    
  iter += 1
  var result = boundaries[0] * Transform2D(PI/4, Vector2.ZERO)
  for vertex in result:
    solution += vertex
  solution /= float(result.size())
    
  queue_redraw()
  print(solution)
  print(4000000 * int(round(solution.x)) + int(round(solution.y)))

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
  sensors.sort_custom(func(a,b): return a.position.x < b.position.x)

func _draw():
  var scale = 0.0001
  var projection = Transform2D(0, Vector2(scale, scale), 0, Vector2.ZERO)
  var index = 0

  for sensor in sensors:
    index += 1
    var color = Color(Color.CORNFLOWER_BLUE, 0.05)
    if iter == index:
      color = Color(Color.CRIMSON, 0.4)
    draw_colored_polygon(PackedVector2Array(sensor.polygon * projection), color)
  
  draw_polyline(PackedVector2Array([
    Vector2.ZERO,
    Vector2(width, 0),
    Vector2(width, width),
    Vector2(0, width),
    Vector2.ZERO
  ]) * projection, Color.WHITE, 3)  
  
  for boundary in boundaries:
    draw_colored_polygon(
      PackedVector2Array(boundary * Transform2D(PI/4, Vector2.ZERO)) * projection,
      Color.MEDIUM_SPRING_GREEN
    )
    
  if solution != null:
    draw_circle(solution * projection, 1, Color.MEDIUM_SPRING_GREEN)

class Sensor:
  var position:Vector2
  var target:Vector2
  var transform:Transform2D = Transform2D.IDENTITY
  
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
      ]) * transform
  
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
