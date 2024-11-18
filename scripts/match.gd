extends TextureRect

var showing = false
var elapsed = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if showing:
		modulate.a = 1.0 - elapsed
	elapsed += delta * 1.0
	
	if elapsed >= 1.0:
		showing = false


func display():
	showing = true
	elapsed = 0.0
