extends CharacterBody2D

@export var speed := 100.0
@export var gravity := 980.0
@export var can_move = false

# Defiance level: 0 = normal, 1 = defiant
var defiance_level := 0

# Internal tracking of last played animation
var _last_animation := ""

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	
	if can_move:
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
			$texture.flip_h = true
			_play_animation("walk")
		elif Input.is_action_pressed("move_right"):
			direction.x += 1
			$texture.flip_h = false
			_play_animation("walk")
		else:
			_play_animation("idle")
		
		velocity.x = direction.x * speed
	
	# Gravity
	velocity.y += gravity * delta
	
	move_and_slide()

# Automatically update the player's defiance level
func set_defiance_level(level: int) -> void:
	defiance_level = level

# Internal helper to choose animation based on defiance
func _play_animation(base_name: String) -> void:
	var anim_name := "%s_%d" % [base_name, defiance_level]
	if _last_animation != anim_name:
		$texture.play(anim_name)
		_last_animation = anim_name
