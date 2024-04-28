class_name Battery

extends Sprite2D

@onready var particles: CPUParticles2D = get_node("CPUParticles2D")

@export var shakeOffset := Vector2(0, 0.7)
@export var blinkInterval := 2
@export var blinkOpacityMin := 0.3
@export var blinkOpacityMax := 0.6
@export var opacityInactive = 0.3
var now := 0.0

var withWire := false

var COLOR_DEPLETED := Color(Color.WHITE, 0.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	now += delta
	if frame == 0:
		if self_modulate != COLOR_DEPLETED:
			self_modulate = COLOR_DEPLETED
			particles.emitting = true
	elif withWire:
		self_modulate = Color.WHITE
		offset = (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shakeOffset).round()
	else:
		var blinkCoefficient := int(now / blinkInterval * 2) % 2
		self_modulate = Color(Color.WHITE,
			blinkOpacityMin * blinkCoefficient + blinkOpacityMax * (1 - blinkCoefficient))
