class_name Creature

extends Node2D

signal moved(cell: Vector2i)
signal ate_through(cell: Vector2i)

@export var speed := 2.0

var clockPos: Vector2i
var startingCell: Vector2i
var direction: Vector2i
var maze: TileMap
var rng := RandomNumberGenerator.new()
var wire: Wire

var cell: Vector2i
var depthMap := Dictionary()
var untilTarget := 1.0
var targetCell: Vector2i
var directionOrder: Array[Vector2i] = []
var gnawing := false

const CREATURE_GROUP = "creature"

@onready var sprite := get_node("Sprite2D") as Sprite2D
@onready var gnawTimer := get_node("GnawTimer") as Timer
@onready var gnawSprite := get_node("GnawTimerSprite") as Sprite2D
@onready var gnawChance := 0.15
@onready var deadWireGnawChance := 0.05

const INFINITY := 1000000
const ACTIVE_WIRE_INTEREST := INFINITY
const UNEXPLORED_WIRE_INTEREST := INFINITY * 2
const WIRE_ORIGIN_INTEREST := INFINITY * 3

# Called when the node enters the scene tree for the first time.
func _ready():
	start_movement(startingCell - direction, startingCell)
	add_to_group(CREATURE_GROUP, true)
	gnawSprite.visible = false

func _physics_process(delta: float) -> void:
	if cell != targetCell:
		var lastUntilTarget = untilTarget
		untilTarget -= speed * delta
		if untilTarget <= 0.5 and lastUntilTarget > 0.5:
			emit_signal("moved", targetCell)
		if untilTarget <= 0.0:
			cell = targetCell
			global_position = maze.to_global(maze.map_to_local(cell))
			if cell == startingCell:
				depthMap = {cell: 0}
				randomize_directions()
			if cell == wire.originPos or \
					cell == clockPos or \
					(wire.has_active_wire(cell) and not cell_has_gnawing_creatures(cell) and gnawChance > rng.randf()) or \
					(wire.has_inactive_wire(cell) and not cell_has_gnawing_creatures(cell) and deadWireGnawChance > rng.randf()):
				gnawing = true
				gnawSprite.visible = true
				gnawTimer.start()
			else:
				pick_target_cell()

func cell_has_gnawing_creatures(at: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group(CREATURE_GROUP):
		if node is Creature:
			if node.gnawing and node.cell == at:
				return true
	return false

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

func pick_target_cell() -> void:
	var bestDepth := INFINITY
	var bestCell: Vector2i
	var mazeRect := maze.get_used_rect()
	for direction in directionOrder:
		var neighbor := cell + direction
		if maze.get_cell_tile_data(0, neighbor) or not mazeRect.has_point(neighbor):
			continue
		var candidateDepth = depthMap.get(neighbor, -1)
		# If exploring, gravitate towards wire
		if wire.get_cell_tile_data(0, neighbor):
			if neighbor == wire.originPos:
				candidateDepth -= WIRE_ORIGIN_INTEREST
			elif candidateDepth == -1:
				candidateDepth -= UNEXPLORED_WIRE_INTEREST
			elif wire.get_cell_atlas_coords(0, neighbor).x & Wire.IS_LIT_UP_BIT:
				candidateDepth -= ACTIVE_WIRE_INTEREST
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
	sprite.global_rotation = Vector2(to - from).angle()
	untilTarget = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cell != targetCell:
		global_position = maze.to_global(maze.map_to_local(targetCell)).lerp(maze.to_global(maze.map_to_local(cell)), untilTarget)

func _on_gnaw_timer_timeout():
	if gnawSprite.frame == gnawSprite.hframes * gnawSprite.vframes - 1:
		emit_signal("ate_through", cell)
		gnawSprite.frame = 0
		gnawSprite.visible = false
		gnawing = false
		gnawTimer.stop()
		pick_target_cell()
	else:
		gnawSprite.frame += 1
