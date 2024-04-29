class_name Clock

extends Node2D

signal second_passed

@onready var animationPlayer := get_node("AnimationPlayer") as AnimationPlayer
@onready var secondTimer := get_node("Second") as Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func ring() -> void:
	if animationPlayer.assigned_animation != "ring":
		z_index = 7
		z_as_relative = false
		animationPlayer.play("ring")
		secondTimer.stop()

func go_to_sleep() -> void:
	if not animationPlayer or not secondTimer:
		return
	animationPlayer.play("sleep")
	secondTimer.stop()

func wake_up() -> void:
	if animationPlayer.assigned_animation not in ["ring", "woke"]:
		animationPlayer.play("woke")
		secondTimer.start()


func _on_second_timeout() -> void:
	if animationPlayer.assigned_animation == "woke" and animationPlayer.current_animation == "woke":
		animationPlayer.seek(0)
		emit_signal("second_passed")
	else:
		secondTimer.stop()
