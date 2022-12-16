extends Camera2D

var click_position = Vector2.ZERO
var original_position = Vector2.ZERO

func _input(event):
  if event is InputEventMouseButton:
    if event.is_pressed():
      if event.button_index == MOUSE_BUTTON_WHEEL_UP:
        zoom += Vector2(1,1)
      if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        zoom -= Vector2(1,1)
      else:
        click_position = event.position
        original_position = position
    else:
      click_position = Vector2.ZERO
  elif event is InputEventMouseMotion:
    if click_position != Vector2.ZERO:
      position = original_position + click_position - event.position
