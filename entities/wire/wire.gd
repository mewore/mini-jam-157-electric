class_name  Wire

extends TileMap

signal grow
signal preview_changed

@export var maze: TileMap
@export var origin: Node2D
@onready var originPos = local_to_map(to_local(origin.global_position)) if origin else Vector2i.ZERO
@onready var previewMap: TileMap = get_node("WirePreview")
@export var batteryContainer: Node
var batteries: Array[Battery] = []

const LAYER := 0

const NONEXISTENT_MOUSE_POS := Vector2i(-1000000, -1000000)
var lastPreviewPos: Vector2i = NONEXISTENT_MOUSE_POS
var previewLength := 0

var maxGrowth = 0

var NEIGHBOR_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_cell(LAYER, originPos, 0, Vector2i.ZERO)
	
	batteries = []
	for child in batteryContainer.get_children():
		batteries.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	preview_growth_to(local_to_map(get_local_mouse_position()))
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grow"):
		var pathToPos = search_path_to(local_to_map(get_local_mouse_position()))
		if not pathToPos:
			return
		for cell in pathToPos:
			set_wire_cell(self, cell)
		previewMap.clear()
		lastPreviewPos = NONEXISTENT_MOUSE_POS
		previewLength = 0
		for battery in batteries:
			if has_cell_at(self, local_to_map(battery.global_position)):
				battery.withWire = true
		emit_signal("grow", pathToPos.size())

func preview_growth_to(at: Vector2i) -> void:
	if at == lastPreviewPos:
		return
	previewMap.clear()
	for cell in get_used_cells(LAYER):
		set_wire_cell(previewMap, cell)
	var previewPath := search_path_to(at)
	for cell in	previewPath:
		set_wire_cell(previewMap, cell)
	previewLength = previewPath.size()
	lastPreviewPos = at
	emit_signal("preview_changed")

func search_path_to(target: Vector2i) -> Array[Vector2i]:
	if has_cell_at(maze, target):
		return []
	var parents := Dictionary()
	var distance := Dictionary()
	var queue: Array[Vector2i] = get_used_cells(LAYER)
	for cell in queue:
		parents[cell] = false
		distance[cell] = 0
	
	var cellBatteryLevels := Dictionary()
	for battery in batteries:
		if battery.frame <= 0:
			continue
		var cell = local_to_map(to_local(battery.global_position))
		cellBatteryLevels[cell] = cellBatteryLevels.get(cell, 0) + battery.frame
	
	while queue:
		var oldQueue := queue
		queue = []
		for cell in oldQueue:
			var neighborsByEnergy := Dictionary()
			for direction in NEIGHBOR_DIRECTIONS:
				var neighbor = cell + direction
				if neighbor not in parents and not has_cell_at(maze, neighbor):
					var energy = cellBatteryLevels.get(neighbor, 0)
					if not neighborsByEnergy.has(energy):
						neighborsByEnergy[energy] = []
					neighborsByEnergy[energy].append(neighbor)
			
			var energyKeys := neighborsByEnergy.keys()
			energyKeys.sort()
			energyKeys.reverse()
			for energy in energyKeys:
				for neighbor in neighborsByEnergy[energy]:
					parents[neighbor] = cell
					distance[neighbor] = distance[cell] + 1
					queue.append(neighbor)
	
	if not parents.has(target):
		return []
	var currentPos = target
	while distance[currentPos] > maxGrowth:
		currentPos = parents[currentPos]
	var result: Array[Vector2i] = []
	while parents[currentPos]:
		result.append(currentPos)
		currentPos = parents[currentPos]
	result.reverse()
	return result

func has_cell_at(map: TileMap, at: Vector2i) -> bool:
	if not map:
		return false
	if map.get_cell_tile_data(LAYER, at):
		return true
	return false

func set_wire_cell(map: TileMap, at: Vector2i) -> void:
	map.set_cell(LAYER, at, 0, Vector2i.ZERO)
	update_wire_cell(map, at)
	for direction in NEIGHBOR_DIRECTIONS:
		update_wire_cell(map, at + direction)

func update_wire_cell(map: TileMap, at: Vector2i) -> void:
	if not has_cell_at(map, at):
		return
	var atlasCol: int = int(has_cell_at(map, at + Vector2i.RIGHT)) | (int(has_cell_at(map, at + Vector2i.LEFT)) << 1)
	var atlasRow: int = int(has_cell_at(map, at + Vector2i.DOWN)) | (int(has_cell_at(map, at + Vector2i.UP)) << 1)
	map.set_cell(LAYER, at, 0, Vector2i(atlasCol, atlasRow))
