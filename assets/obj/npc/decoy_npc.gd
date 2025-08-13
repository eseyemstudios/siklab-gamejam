extends Area2D

signal decoy

var _player_inside := false
var _alarm_started := false

@onready var _ui_screen = $ui_screen

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_ui_screen.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_ui_screen.hide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		if _player_inside and not _alarm_started:
			_alarm_started = true
			_ui_screen.hide()
			$npc.play("idle_red")
			$activate.play()
			$timer.start()

func _on_timer_timeout() -> void:
	_alarm_started = false
	$decoy.play()
	$npc.play("idle_red")
	decoy.emit()
	await get_tree().create_timer(5).timeout
	$npc.play("idle")
	$decoy.stop()
