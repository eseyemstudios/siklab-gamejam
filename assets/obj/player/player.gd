extends CharacterBody2D

@export var speed := 100.0
@export var gravity := 980.0

var can_move = false

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	# Character Movement
	if can_move:
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
			$texture.flip_h = true
			$texture.play("walk")
		elif Input.is_action_pressed("move_right"):
			direction.x += 1
			$texture.flip_h = false
			$texture.play("walk")
		else:
			$texture.play("idle")
		
		velocity.x = direction.x * speed
	
	# Gravity
	velocity.y += gravity * delta
	
	move_and_slide()
