extends Node2D

@onready var energyBar := get_node("BottomBar/EnergyBar") as Line2D
@onready var energyBarLength := energyBar.points[1].x - energyBar.points[0].x
@onready var energyCostBar := get_node("BottomBar/EnergyCostBar") as Line2D

@onready var maze := get_node("Maze") as TileMap
@onready var wire := get_node("Wire") as Wire

var energy: int = 0
@export var maxEnergy: int = 20

@onready var bottomBarParticlesContainer := get_node("BottomBar/EnergyParticles") as Node2D
@export var energyUsedParticlesScene: PackedScene

@export var creatureOriginScene: PackedScene
@onready var creatureOrigin = get_node("CreatureOrigin") as Node2D

var creatureOrigins: Array[Vector2i] = []
var creatureOriginDirections: Array[Vector2i] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	set_energy(5)
	wire.maxGrowth = energy
	
	var mazeRect := maze.get_used_rect()
	for x in range(mazeRect.position.x + 1, mazeRect.end.x - 1):
		check_for_creature_origin(mazeRect, Vector2i(x, mazeRect.position.y), Vector2i.DOWN)
		check_for_creature_origin(mazeRect, Vector2i(x, mazeRect.end.y - 1), Vector2i.UP)
	for y in range(mazeRect.position.y + 1, mazeRect.end.y - 1):
		check_for_creature_origin(mazeRect, Vector2i(mazeRect.position.x, y), Vector2i.RIGHT)
		check_for_creature_origin(mazeRect, Vector2i(mazeRect.end.x - 1, y), Vector2i.LEFT)

func check_for_creature_origin(mazeRect: Rect2i, cell: Vector2i, direction: Vector2i) -> void:
	if not maze.get_cell_tile_data(0, cell):
		print("Found creature origin at ", cell, " with direction ", direction)
		creatureOrigins.append(cell)
		creatureOriginDirections.append(direction)
		var origin := creatureOriginScene.instantiate() as Node2D
		add_child(origin)
		origin.global_position = maze.to_global(maze.map_to_local(cell))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_energy(newEnergy: int) -> void:
	if newEnergy < energy:
		var energyUsed := energy - newEnergy
		var particles := energyUsedParticlesScene.instantiate() as CPUParticles2D
		var particlesPerPixel := particles.amount / (particles.emission_rect_extents.x * 2)
		var pixels := (float(energyUsed) / maxEnergy) * energyBarLength
		particles.amount = particlesPerPixel * pixels
		particles.emission_rect_extents.x = pixels / 2
		var particlesCenter := energyBar.points[0] + Vector2(energyBarLength * (float(energy + newEnergy) / 2) / maxEnergy, 0)
		particles.position = bottomBarParticlesContainer.to_local(energyBar.to_global(particlesCenter))
		particles.emitting = true
		particles.finished.connect(_on_particles_done.bind(particles))
		bottomBarParticlesContainer.add_child(particles)
	energy = newEnergy
	refresh_energy()
	wire.maxGrowth = energy
	wire.lastPreviewPos = wire.NONEXISTENT_MOUSE_POS

func _on_particles_done(particles: Node) -> void:
	particles.queue_free()
	print("Particles done!")

func refresh_energy() -> void:
	energyBar.points = [
		energyBar.points[0],
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy) / maxEnergy)
	]
	energyCostBar.points = [
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy - wire.previewLength) / maxEnergy),
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy) / maxEnergy)
	]

func _on_wire_grow(amount: int) -> void:
	print("Wire grew by [", amount, "]!")
	set_energy(energy - amount)


func _on_wire_preview_changed() -> void:
	refresh_energy()

func _on_drain_timer_timeout() -> void:
	for battery in wire.batteries:
		if energy >= maxEnergy:
			break
		if battery.withWire and battery.frame > 0:
			battery.frame -= 1
			set_energy(energy + 1)
