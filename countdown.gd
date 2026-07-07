extends MarginContainer


func _process(delta):
	if !$Timer.is_stopped():
		$HBoxContainer2/Label.text = str(int($Timer.time_left) + 1)
		$HBoxContainer2/Label2.text = str(int($Timer.time_left) + 1)

func _on_timer_timeout():
	Events.start.emit()
	$HBoxContainer2/Label.text = "GO!"
	$HBoxContainer2/Label2.text = "GO!"
	await get_tree().create_timer(2.0).timeout
	hide()
