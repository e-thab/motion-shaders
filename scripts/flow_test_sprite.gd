extends Sprite2D

var speed = 250
var leftX = 1152*(1.0/4.0)
var rightX = 1152*(3.0/4.0)
var topY = 648*(1.0/4.0)
var botY = 648*(3.0/4.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	## Move the sprite along the path when visible
	if visible:
		var x = position.x
		var y = position.y
		# Top left -> Top right
		if x < rightX and y == topY:
			position.x = clamp(x + delta*speed, leftX, rightX)
		# Top right -> Bottom right
		elif x == rightX and y < botY:
			position.y = clamp(y + delta*speed, topY, botY)
		# Bottom right -> Top left (diagonal)
		else:
			position.x = clamp(x - delta*speed, leftX, rightX)
			position.y = clamp(y - delta*speed, topY, botY)
