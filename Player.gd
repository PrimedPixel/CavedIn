extends CharacterBody2D


const spd_ground: int = 100
const spd_air: int = 130
const jump_vel: int = -200
const accel: int = 400
const ladder_accel: int = 800
const frict: int = 200
const ladder_frict: int = 250
const grav: int = 500

var level_transition: bool = false
var on_ladder: bool = false
var ladder: bool = false

@onready var player_animations = $PlayerAnimations
@onready var player_sprite = $PlayerSprite
@onready var jump_sound = $JumpSound

func _physics_process(delta) -> void:
	if level_transition:
		player_animations.play("Idle")
		return

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ladder):
		jump_sound.play()
		velocity.y = jump_vel
		ladder = false
		player_animations.speed_scale = 1
	
	# Variable jump height
	# Checks that jump button isn't pressed and moving up quickly											
	if Input.is_action_just_released("jump") and velocity.y < (jump_vel * 0.5):
		# Halves the jump force, making the player land quickly
		velocity.y = jump_vel * 0.5

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_axis("left", "right")
	
	if input_dir:
		var max_spd = spd_ground if is_on_floor() else spd_air
		
		velocity.x = move_toward(velocity.x, input_dir * max_spd, accel * delta)
	
	velocity.x = move_toward(velocity.x, 0, frict * delta)
	
	if !ladder:
		if abs(velocity.x) > 0:
			player_animations.play("Run")
			player_sprite.flip_h = velocity.x < 0
		else:
			player_animations.play("Idle")
	
	# Add the gravity.
	if !is_on_floor() && !ladder:
		velocity.y += grav * delta
		
		player_animations.play("Jump")
	
	if on_ladder:
		if Input.is_action_pressed("up") && !ladder:
			player_animations.play("Ladder")
			ladder = true
			velocity = Vector2.ZERO
	else:
		ladder = false
		
		player_animations.speed_scale = 1
		
	if ladder:
		var ladder_input_dir = Input.get_axis("up", "down")
		
		if ladder_input_dir:			
			velocity.y = move_toward(velocity.y, ladder_input_dir * spd_ground, accel * delta)
		
		velocity.y = move_toward(velocity.y, 0, ladder_frict * delta)
		
		player_animations.speed_scale = sign(velocity.y)
	
	move_and_slide()
