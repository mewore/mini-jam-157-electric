class_name  Wire

extends TileMap

signal grow(newCells: Vector2i)
signal preview_changed()

@export var maze: TileMap
@export var fog: TileMap
@export var origin: Node2D
@onready var originPos := local_to_map(to_local(origin.global_position)) if origin else Vector2i.ZERO
@export var clock: Clock
@onready var clockPos = local_to_map(to_local(clock.global_position))
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

const IS_LIT_UP_BIT = 1 << 2
var cellLightUpEvents
var cellGroupsToLightUp: Array = []

var poweredCells: Array[Vector2i] = []
var poweredCellsDict := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_cell(LAYER, originPos, 0, Vector2i.ZERO)
	refresh_powered_cells()
	
	batteries = []
	for child in batteryContainer.get_children():
		batteries.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	preview_growth_to(local_to_map(get_local_mouse_position()))
	pass

func has_battery_supply() -> bool:
	for battery in batteries:
		if battery.withWire:
			return true
	return false

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
		refresh_powered_cells()
		emit_signal("grow", pathToPos)

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
	if has_cell_at(maze, target) or has_cell_at(fog, target):
		return []
	var parents := Dictionary()
	var distance := Dictionary()
	var queue: Array[Vector2i] = poweredCells
	for cell in queue:
		parents[cell] = false
		distance[cell] = 0
	
	var cellBatteryLevels := Dictionary()
	for battery in batteries:
		if battery.frame <= 0:
			continue
		var cell = local_to_map(to_local(battery.global_position))
		cellBatteryLevels[cell] = cellBatteryLevels.get(cell, 0) + battery.frame
	
	var mazeRect := maze.get_used_rect()
	while queue:
		var oldQueue := queue
		queue = []
		for cell in oldQueue:
			var neighborsByEnergy := Dictionary()
			for direction in NEIGHBOR_DIRECTIONS:
				var neighbor = cell + direction
				if neighbor not in parents and mazeRect.has_point(neighbor) and not (has_cell_at(maze, neighbor) or has_cell_at(fog, neighbor)):
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

func remove_wire_at(at: Vector2i) -> void:
	set_wire_cell(self, at, false)
	previewMap.clear()
	lastPreviewPos = NONEXISTENT_MOUSE_POS
	refresh_powered_cells()
	for cell in get_used_cells(LAYER):
		if cell not in poweredCells:
			var coords = get_cell_atlas_coords(LAYER, cell)
			if coords.x & IS_LIT_UP_BIT:
				coords.x ^= IS_LIT_UP_BIT
				set_cell(LAYER, cell, 0, coords)

func has_cell_at(map: TileMap, at: Vector2i) -> bool:
	if not map:
		return false
	if map.get_cell_tile_data(LAYER, at):
		return true
	return false

func set_wire_cell(map: TileMap, at: Vector2i, present: bool = true) -> void:
	if present:
		map.set_cell(LAYER, at, 0, Vector2i.ZERO)
	else:
		map.set_cell(LAYER, at, -1)
	update_wire_cell(map, at)
	for direction in NEIGHBOR_DIRECTIONS:
		update_wire_cell(map, at + direction)

func update_wire_cell(map: TileMap, at: Vector2i) -> void:
	if not has_cell_at(map, at):
		return
	var atlasCol: int = int(has_cell_at(map, at + Vector2i.RIGHT)) | (int(has_cell_at(map, at + Vector2i.LEFT)) << 1)
	var atlasRow: int = int(has_cell_at(map, at + Vector2i.DOWN)) | (int(has_cell_at(map, at + Vector2i.UP)) << 1)
	var atlasCoords := map.get_cell_atlas_coords(LAYER, at)
	map.set_cell(LAYER, at, 0, Vector2i(atlasCol | (atlasCoords.x & IS_LIT_UP_BIT), atlasRow))

func refresh_powered_cells() -> void:
	var queue: Array[Vector2i] = [originPos]
	var visited := Dictionary()
	poweredCells = []
	poweredCellsDict = {}
	cellGroupsToLightUp = []
	while queue:
		poweredCells.append_array(queue)
		var oldQueue = queue
		var cellsToLightUp: Array[Vector2i] = []
		queue = []
		for cell in oldQueue:
			for direction in NEIGHBOR_DIRECTIONS:
				var neighbor = cell + direction
				if neighbor not in visited and has_cell_at(self, neighbor):
					var atlasCoords := get_cell_atlas_coords(LAYER, neighbor)
					if not (atlasCoords.x & IS_LIT_UP_BIT):
						cellsToLightUp.append(neighbor)
					visited[neighbor] = true
					queue.append(neighbor)
		if cellsToLightUp:
			cellGroupsToLightUp.append(cellsToLightUp)
	
	cellGroupsToLightUp.reverse()
	for cell in poweredCells:
		poweredCellsDict[cell] = true
	
	for battery in batteries:
		battery.withWire = has_active_wire(local_to_map(to_local(battery.global_position)))
	
	if has_active_wire(clockPos):
		clock.wake_up()
	else:
		clock.go_to_sleep()
	

func has_active_wire(cell: Vector2i) -> bool:
	return cell in poweredCellsDict

func has_inactive_wire(cell: Vector2i) -> bool:
	return cell not in poweredCellsDict and has_cell_at(self, cell)

func _on_light_up_timer_timeout() -> void:
	if cellGroupsToLightUp.is_empty():
		return
	for cell in cellGroupsToLightUp.pop_back() as Array[Vector2i]:
		var atlasCoords := get_cell_atlas_coords(LAYER, cell)
		set_cell(LAYER, cell, 0, Vector2i(atlasCoords.x | IS_LIT_UP_BIT, atlasCoords.y))
