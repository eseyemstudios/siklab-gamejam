extends Node2D

var left_angle := 0.0             # 0 radians (looking left)
var right_angle := deg_to_rad(-180)  # -π radians (looking right)
var patrol_speed := 0.25           # radians per second
var direction := -1               # moving from 0 to -π initially
var current_angle := 0.0

func _ready() -> void:
	current_angle = left_angle
	$main_camera/camera.rotation = current_angle

func _process(delta: float) -> void:
	current_angle += patrol_speed * direction * delta

	if current_angle <= right_angle:
		current_angle = right_angle
		direction = 1   # reverse to move back towards 0
	elif current_angle >= left_angle:
		current_angle = left_angle
		direction = -1  # reverse to move towards -π

	$main_camera/camera.rotation = current_angle
