extends Node2D

@onready var energyBar: Line2D = get_node("BottomBar/EnergyBar")
@onready var energyBarLength = energyBar.points[1].x - energyBar.points[0].x

var energy: int = 0
@export var maxEnergy: int = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	energyBar.points = [
		energyBar.points[0],
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy) / maxEnergy)
	]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
