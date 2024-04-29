extends Node2D

@onready var energyBar := get_node("BottomBar/EnergyBar") as Line2D
@onready var energyBarLength := energyBar.points[1].x - energyBar.points[0].x
@onready var energyCostBar := get_node("BottomBar/EnergyCostBar") as Line2D
@onready var shockChargeBar := get_node("BottomBar/ShockChargeBar") as Line2D

@onready var maze := get_node("Maze") as TileMap
@onready var wire := get_node("Wire") as Wire
@onready var clock := get_node("Clock") as Sprite2D
@onready var clockPos := maze.local_to_map(maze.to_local(clock.global_position))
@onready var camera := get_node("Camera2D") as Camera2D

var energy: int = 0
@export var maxEnergy: int = 20
@export var shockCost := 10
var currentShockCharge: float = 0.0
@export var shockChargeSpeed := 2.0
@export var cameraShakeAmount := 1.0
@export var cameraShakeAmplitude := 3.0
@export var cameraShakeSpeedX := 500
@export var cameraShakeSpeedY := 350

@onready var energyLabel = get_node("BottomBar/Control/EnergyLabel") as Label

@onready var bottomBarParticlesContainer := get_node("BottomBar/EnergyParticles") as Node2D
@export var energyUsedParticlesScene: PackedScene
@export var creatureExplosionParticlesScene: PackedScene

@export var creatureOriginScene: PackedScene

var creatureSeedRng := RandomNumberGenerator.new()

var creatureOrigins: Array[Vector2i] = []
var creatureOriginDirections: Array[Vector2i] = []

@export var creatureScene: PackedScene
var nextCreatureOrigin = 0

@export var fogRevealParticleScene: PackedScene
@onready var fog := get_node("Fog") as TileMap
@export var REVEAL_RADIUS_AROUND_CREATURE_ORIGINS := 1
@export var REVEAL_RADIUS_AROUND_CREATURES := 0
@export var REVEAL_RADIUS_AROUND_WIRE := 2
@export var REVEAL_RADIUS_AROUND_CLOCK := 1

@export var ENERGY_PER_BATTERY_TICK := 2
@export var INITIAL_ENERGY := 5

# Called when the node enters the scene tree for the first time.
func _ready():
	set_energy(INITIAL_ENERGY)
	wire.maxGrowth = energy
	shockChargeBar.points = []
	
	print("scene_file_path = ", scene_file_path)
	print("root scene_file_path = ", get_tree().current_scene.scene_file_path)
	creatureSeedRng.seed = get_tree().current_scene.scene_file_path.hash()
	
	var mazeRect := maze.get_used_rect()
	
	for x in range(mazeRect.position.x - 1, mazeRect.end.x + 1):
		for y in range(mazeRect.position.y - 1, mazeRect.end.y + 4):
			fog.set_cell(0, Vector2i(x, y), 0, Vector2i.ZERO)
	
	for x in range(mazeRect.position.x + 1, mazeRect.end.x - 1):
		check_for_creature_origin(mazeRect, Vector2i(x, mazeRect.position.y), Vector2i.DOWN)
		check_for_creature_origin(mazeRect, Vector2i(x, mazeRect.end.y - 1), Vector2i.UP)
	for y in range(mazeRect.position.y + 1, mazeRect.end.y - 1):
		check_for_creature_origin(mazeRect, Vector2i(mazeRect.position.x, y), Vector2i.RIGHT)
		check_for_creature_origin(mazeRect, Vector2i(mazeRect.end.x - 1, y), Vector2i.LEFT)
	if creatureOrigins.is_empty():
		get_node("CreatureTimer").queue_free()
	
	var originPos := (get_node("WireOrigin") as Node2D).global_position
	reveal_fog(fog.local_to_map(fog.to_local(originPos)), REVEAL_RADIUS_AROUND_WIRE)
	reveal_fog(clockPos, REVEAL_RADIUS_AROUND_CLOCK)

func check_for_creature_origin(mazeRect: Rect2i, cell: Vector2i, direction: Vector2i) -> void:
	if not maze.get_cell_tile_data(0, cell):
		print("Found creature origin at ", cell, " with direction ", direction)
		creatureOrigins.append(cell)
		creatureOriginDirections.append(direction)
		var origin := creatureOriginScene.instantiate() as Node2D
		add_child(origin)
		origin.global_position = maze.to_global(maze.map_to_local(cell))
		reveal_fog(cell, REVEAL_RADIUS_AROUND_CREATURE_ORIGINS)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("charge"):
		shockChargeBar.visible = true
		currentShockCharge = min(currentShockCharge + delta * shockChargeSpeed, min(shockCost, energy))
		shockChargeBar.points = [
			energyBar.points[0],
			energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(currentShockCharge) / maxEnergy)
		]
		shockChargeBar.default_color = Color.BLACK if currentShockCharge < shockCost else Color.WHITE
		cameraShakeAmount = max(cameraShakeAmount, currentShockCharge / shockCost * .25)
	else:
		shockChargeBar.visible = false
		cameraShakeAmount = max(cameraShakeAmount - delta, 0.0)
	var now := Time.get_ticks_msec() * .1
	camera.offset = Vector2(cos(now * cameraShakeSpeedX), sin(now * cameraShakeSpeedY)) * (cameraShakeAmplitude * cameraShakeAmount * cameraShakeAmount)

func _unhandled_key_input(event) -> void:
	if event.is_action_released("charge"):
		if currentShockCharge >= shockCost - .00001:
			kill_wire_gnawers()
			cameraShakeAmount = 1.0
			set_energy(energy - shockCost)
		currentShockCharge = 0.0
		
func kill_wire_gnawers():
	for node in get_tree().get_nodes_in_group(Creature.CREATURE_GROUP):
		if node is Creature:
			if node.gnawing and node.wire.has_active_wire(node.cell):
				var particles := creatureExplosionParticlesScene.instantiate() as CPUParticles2D
				particles.emitting = true
				particles.position = node.position
				particles.finished.connect(_on_particles_finished.bind(particles))
				add_child(particles)
				node.queue_free()

func set_energy(newEnergy: int) -> void:
	if newEnergy <= 0 and not wire.has_battery_supply():
		print("YOW! Out of power...")
		get_tree().reload_current_scene()
		return
		
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
		particles.finished.connect(_on_particles_finished.bind(particles))
		bottomBarParticlesContainer.add_child(particles)
	energy = newEnergy
	refresh_energy()
	wire.maxGrowth = energy
	wire.lastPreviewPos = wire.NONEXISTENT_MOUSE_POS

func refresh_energy() -> void:
	energyBar.points = [
		energyBar.points[0],
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy) / maxEnergy)
	]
	energyCostBar.points = [
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy - wire.previewLength) / maxEnergy),
		energyBar.points[0] + Vector2.RIGHT * (energyBarLength * float(energy) / maxEnergy)
	]
	energyLabel.text = str(energy) + " / " + str(maxEnergy)

func _on_wire_grow(newCells: Array[Vector2i]) -> void:
	set_energy(energy - newCells.size())
	for cell in newCells:
		reveal_fog(cell, REVEAL_RADIUS_AROUND_WIRE)

func _on_wire_preview_changed() -> void:
	refresh_energy()

func _on_drain_timer_timeout() -> void:
	for battery in wire.batteries:
		if energy + ENERGY_PER_BATTERY_TICK > maxEnergy:
			break
		if battery.withWire and battery.frame > 0:
			battery.frame -= 1
			set_energy(energy + ENERGY_PER_BATTERY_TICK)

func reveal_fog(around: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var cell := around + Vector2i(dx, dy)
			if fog.get_cell_tile_data(0, cell):
				fog.erase_cell(0, cell)
				if fogRevealParticleScene:
					var particles := fogRevealParticleScene.instantiate() as CPUParticles2D
					particles.color = fog.self_modulate
					particles.position = fog.map_to_local(cell)
					particles.emitting = true
					particles.finished.connect(_on_particles_finished.bind(particles))
					fog.add_child(particles)

func _on_creature_timer_timeout():
	var creature := creatureScene.instantiate() as Creature
	creature.clockPos = clockPos
	creature.rng.seed = creatureSeedRng.randi()
	creature.startingCell = creatureOrigins[nextCreatureOrigin]
	creature.direction = creatureOriginDirections[nextCreatureOrigin]
	creature.maze = maze
	creature.wire = wire
	creature.moved.connect(_on_creature_moved)
	creature.ate_through.connect(_on_creature_ate_through)
	add_child(creature)
	nextCreatureOrigin = (nextCreatureOrigin + 1) % creatureOrigins.size()


func _on_creature_moved(cell: Vector2i) -> void:
	reveal_fog(cell, REVEAL_RADIUS_AROUND_CREATURES)

func _on_creature_ate_through(cell: Vector2i) -> void:
	if cell == clockPos:
		print("YOW! Ate through the clock...")
		get_tree().reload_current_scene()
		return

	if cell == wire.originPos:
		print("YOW! Ate through the origin...")
		get_tree().reload_current_scene()
		return
	
	wire.remove_wire_at(cell)

func _on_particles_finished(particles: Node) -> void:
	particles.queue_free()
