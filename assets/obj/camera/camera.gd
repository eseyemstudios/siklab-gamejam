extends Node2D

enum CameraState {
	PATROL,
	WATCH,
	DEFIANCE
}

var state = CameraState.PATROL
var patrol_direction = -1
var patrol_speed = 0.15
var left_angle = 0.0
var right_angle = deg_to_rad(-180)
var current_angle = 0.0

var follow_target: Node2D = null

func _ready() -> void:
	current_angle = left_angle
	$main_camera/camera.rotation = current_angle

func _process(delta: float) -> void:
	match state:
		CameraState.PATROL:
			_process_patrol(delta)
		CameraState.WATCH:
			_process_watch(delta)

func _process_patrol(delta: float) -> void:
	current_angle += patrol_speed * patrol_direction * delta
	if current_angle <= right_angle:
		current_angle = right_angle
		patrol_direction = 1
	elif current_angle >= left_angle:
		current_angle = left_angle
		patrol_direction = -1
	$main_camera/camera.rotation = current_angle

func _process_watch(delta: float) -> void:
	var cam = $main_camera/camera
	var desired_angle = (follow_target.global_position - cam.global_position).angle()
	desired_angle += PI  # offset 180 degrees
	cam.rotation = lerp_angle(cam.rotation, desired_angle, 5 * delta)

# Call when player is detected suspiciously or fails task while patrolling
func start_watching(player: Node2D) -> void:
	if player.is_in_group("player"):
		create_tween().tween_property($fx/camera, "self_modulate:a", 1.0, 1)
	else:
		create_tween().tween_property($fx/camera, "self_modulate:a", 0.0, 1)
	follow_target = player
	state = CameraState.WATCH

# Call when player completes task properly while watching
func finish_task() -> void:
	# sync patrol angle with last watch rotation
	current_angle = $main_camera/camera.rotation
	state = CameraState.PATROL
	follow_target = null
	
	create_tween().tween_property($fx/camera, "self_modulate:a", 0.0, 1)
	
	# determine correct patrol direction
	if abs(current_angle - left_angle) < abs(current_angle - right_angle):
		patrol_direction = -1
	else:
		patrol_direction = 1

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_watching(body)
