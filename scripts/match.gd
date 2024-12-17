extends PanelContainer

var showing = false
var elapsed = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	## Fade to transparent by lowering alpha each frame while visible
	if showing:
		modulate.a = 1.0 - elapsed
	elapsed += delta * 1.0
	
	if elapsed >= 1.0:
		showing = false


func display():
	## Begin showing
	showing = true
	elapsed = 0.0
