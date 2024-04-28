class_name Creature

extends Node2D

@export var speed := 1.0

var startingCell: Vector2i
var direction: Vector2i
var maze: TileMap
var rng := RandomNumberGenerator.new()

var cell: Vector2i
var depthMap := Dictionary()
var untilTarget := 1.0
var targetCell: Vector2i
var directionOrder: Array[Vector2i] = []

@onready var sprite := get_node("Sprite2D") as Sprite2D

const INFINITY := 1000000

# Called when the node enters the scene tree for the first time.
func _ready():
	start_movement(startingCell - direction, startingCell)

func _physics_process(delta: float) -> void:
	if cell != targetCell:
		untilTarget -= speed * delta
		if untilTarget <= 0.0:
			cell = targetCell
			if cell == startingCell:
				depthMap = {cell: 0}
				randomize_directions()
			pick_target_cell()
			global_position = maze.to_global(maze.map_to_local(cell))

func randomize_directions() -> void:
	directionOrder = []
	var directions = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
	] as Array[Vector2i]
	while directions:
		var index = rng.randi_range(0, directions.size() - 1)
		directionOrder.append(directions.pop_at(index))
		print(directions.size())

func pick_target_cell() -> void:
	var bestDepth := INFINITY
	var bestCell: Vector2i
	var mazeRect := maze.get_used_rect()
	for direction in directionOrder:
		var neighbor := cell + direction
		if maze.get_cell_tile_data(0, neighbor) or not mazeRect.has_point(neighbor):
			continue
		var candidateDepth = depthMap.get(neighbor, -1)
		if candidateDepth < bestDepth:
			bestDepth = candidateDepth
			bestCell = neighbor
	if bestDepth < INFINITY:
		start_movement(cell, bestCell)
		depthMap[bestCell] = depthMap.get(cell, 0) + 1
	else:
		print("Huh, creature is stuck?! Refreshing depth map...")
		depthMap = {startingCell: 0}
		

func start_movement(from: Vector2i, to: Vector2i) -> void:
	cell = from
	global_position = maze.to_global(maze.map_to_local(cell))
	targetCell = to
	global_rotation = Vector2(to - from).angle()
	untilTarget = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cell != targetCell:
		global_position = maze.to_global(maze.map_to_local(targetCell)).lerp(maze.to_global(maze.map_to_local(cell)), untilTarget)
