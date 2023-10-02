extends Sprite2D


const rock_spd: int = 30

var target_offset: Vector2 = offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	offset = offset.lerp(target_offset, rock_spd * delta)
