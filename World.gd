extends Node2D

@onready var cave_in_timer = $CaveInTimer
@onready var color_rect = $GUI/ColorRect
@onready var music_player = get_node("../MusicPlayer")
@onready var time_label = $GUI/TimeLabel
@onready var screen_count_label = $GUI/ScreenCountLabel
@onready var grumble_audio = $GrumbleAudio
@onready var particle_gen = $ParticleGen
@onready var cave_in_rocks = $GUI/CaveInRocks

@onready var exit = $Level/Exit
@onready var tilemap = $Level/TileMap
@onready var current_level = $Level

@onready var game = get_node("..")

@onready var new_level_point: Vector2 = $Level/NewLevelPoint.position
@onready var player_spawn_point: Vector2 = $Level/PlayerSpawnPoint.position
var old_level_point: Vector2

var levels: Array = []
@onready var player = $Player

var level_move_spd: int = 200
var previous_level

var player_locked_pos: Vector2

const cave_in_min_min: int = 3
const cave_in_min_default: int = 10
const cave_in_max_default: int = 15

var cave_in_min: int = cave_in_min_default
var cave_in_max: int = cave_in_max_default

var cave_in_timer_prev: int = cave_in_min_min

var screen_count: int = 0

func _ready():
	exit.body_entered.connect(_on_exit_body_entered)
	
	var up_levels = access_levels("res://Levels/Enter Up")
	var down_levels = access_levels("res://Levels/Enter Down")
	var left_levels = access_levels("res://Levels/Enter Left")
	var right_levels = access_levels("res://Levels/Enter Right")
	
	levels = [up_levels, down_levels, left_levels, right_levels]

func _on_exit_body_entered(_body):
	# Adjust cave in rocks
	reset_cave_in_rocks()
	
	if !cave_in_timer.is_stopped():
		screen_count += 1
		screen_count_label.text = str(screen_count)
		
		cave_in_timer.stop()
		cave_in_min = max(cave_in_min - [0, 0, 0, 0, 1].pick_random(), cave_in_min_min)
		cave_in_max = max(cave_in_max - [0, 0, 0, 0, 0, 0, 1, 1, 1, 2].pick_random(), cave_in_min)
		
		var particle_amount: float = (1 / float(cave_in_min)) *  60
		particle_gen.amount = roundi(particle_amount)
		
		cave_in_timer.wait_time = randi_range(cave_in_min, cave_in_max)
		
		# Default direction to left, just in case
		var enter_dir = 2
		
		if !(previous_level is Object):
			# Look at this shitty code
			match new_level_point:
				Vector2(0, 180):
					# Exit down -> up
					enter_dir = 0
				Vector2(0, -180):
					# Exit up -> down
					enter_dir = 1
				Vector2(-320, 0):
					# Exit left -> right
					enter_dir = 3
			
			var chosen_level = levels[enter_dir].pick_random()
			
			# Add the level outside of the signal function because of reasons
			call_deferred("add_and_update_levels", chosen_level)

func _process(delta):
	if previous_level is Object:
		
		if !player.level_transition:
			player.level_transition = true
			grumble_audio.play()
			
			player_locked_pos = player.position
		
		current_level.position = current_level.position.move_toward(Vector2.ZERO, level_move_spd * delta)
		previous_level.position = current_level.position - old_level_point
		player.position = previous_level.position + player_locked_pos
	
		if current_level.position == Vector2.ZERO:
			previous_level.queue_free()
			previous_level = null
			
			player.level_transition = false
			grumble_audio.stop()
			
			cave_in_timer.start()
#			reset_cave_in_rocks()
	
	# Player tile detection
	var tile = tilemap.local_to_map(tilemap.to_local(player.global_position))
	var tile_data = tilemap.get_cell_tile_data(0, tile)
	if tile_data:
		player.on_ladder = tile_data.get_custom_data("is_ladder")
	
	# GUI Functionality
	color_rect.size.x = 320 * (cave_in_timer.time_left / cave_in_timer.wait_time)
	
	# Player fall detection
	if new_level_point != Vector2(0, 180) && player.global_position.y > 220:
		gameover("You fell and hit your head, which isn't good.")
	
	# Cave in animation - this code is shitefest
	if !cave_in_timer.is_stopped() && cave_in_timer.time_left <= cave_in_min_min:
		if floor(cave_in_timer.time_left + 0.7) != cave_in_timer_prev:
			cave_in_timer_prev = floor(cave_in_timer.time_left + 0.7)
			
			cave_in_rocks.visible = true
			
			match new_level_point:
				Vector2(320, 0):
					# Exit right -> rocks left
					cave_in_rocks.target_offset = Vector2((106 * (3 - cave_in_timer_prev)) - 320, 0)
				
				Vector2(-320, 0):
					# Exit left -> rocks right
					cave_in_rocks.target_offset = Vector2(320 - (106 * (3 - cave_in_timer_prev)), 0)
				
				Vector2(0, 180):
					# Exit down -> rocks up
					cave_in_rocks.target_offset = Vector2(0, 60 * (3 - cave_in_timer_prev) - 180)
				
				Vector2(0, -180):
					# Exit up -> rocks down
					cave_in_rocks.target_offset = Vector2(0, 180 - (60 * (3 - cave_in_timer_prev)))
	else:
		reset_cave_in_rocks()

func access_levels(path) -> Array:
	var dir = DirAccess.open(path)
	
	if dir:
		var arr = dir.get_files()
		
		var level_arr: Array = []
		
		for i in arr:
			var file_name: String = path + "/" + i
			
			# HTML5 does some weird shit, adding .remap to the end of file names
			# Unfortunately, such .remap files do not exist, so let's remove it
			if ".remap" in file_name:
				file_name = file_name.trim_suffix(".remap")
			
			var loaded_level = load(file_name)
			level_arr.append(loaded_level)
		
		return level_arr
	else:
		printerr("oopsies")
		
		return[]

func add_and_update_levels(level) -> void:
	var new_level = level.instantiate()
	
	add_child(new_level)
	new_level.position = new_level_point

	previous_level = current_level
	current_level = new_level

	exit = current_level.get_node("Exit")
	exit.body_entered.connect(_on_exit_body_entered)
	
	tilemap = current_level.get_node("TileMap")

	old_level_point = new_level_point
	new_level_point = current_level.get_node("NewLevelPoint").position
	
	player_spawn_point = current_level.get_node("PlayerSpawnPoint").position


func _on_cave_in_timer_timeout():
	gameover("The cave collapsed on you!")


func start():
	if !music_player.is_playing():
		music_player.play()
	
	cave_in_timer.wait_time = randi_range(cave_in_min, cave_in_max)
	cave_in_timer.start()
	
	time_label.elapsed_time = 0.0
	time_label.stopped = false
	
	screen_count = 0
	screen_count_label.text = str(screen_count)


func gameover(text):
	cave_in_min = cave_in_min_default
	cave_in_max = cave_in_max_default
	
	reset_cave_in_rocks()
	
	player.position = player_spawn_point
	player.velocity = Vector2.ZERO
	
	particle_gen.amount = 4
	
	cave_in_timer.stop()
	
	time_label.stopped = true
	
	color_rect.size.x = 0
	
	game.gameover(text + "\nYou lasted " + time_label.text + " through " + screen_count_label.text + " levels!")
	
	time_label.text = ""
	screen_count_label.text = ""

func reset_cave_in_rocks():
	match new_level_point:
		Vector2(320, 0):
			# Exit right -> rocks left
			cave_in_rocks.offset = Vector2(-350, 0)
		
		Vector2(-320, 0):
			# Exit left -> rocks right
			cave_in_rocks.offset = Vector2(350, 0)
		
		Vector2(0, 180):
			# Exit down -> rocks up
			cave_in_rocks.offset = Vector2(0, -220)
		
		Vector2(0, -180):
			# Exit up -> rocks down
			cave_in_rocks.offset = Vector2(0, 220)
		
	cave_in_rocks.target_offset = cave_in_rocks.offset
