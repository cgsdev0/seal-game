extends MarginContainer

var number = 4
var boost_frame = 0

func _ready():
	$Music.play()
	await get_tree().process_frame
	$Music.stop()

	hide()

func _on_timer_timeout():
	show()
	number -= 1
	$HBoxContainer2/Label.text = str(number)
	$HBoxContainer2/Label2.text = str(number)

	if number == 2:
		boost_frame = Engine.get_frames_drawn()
		Events.boost.emit(boost_frame)

	if number > 0:
		$Beep.play()
	else:
		$Boop.play()
		$HBoxContainer2/Label.text = "GO!"
		$HBoxContainer2/Label2.text = "GO!"
		$Music.play()
		Events.start.emit()
		$Timer.stop()
		await get_tree().create_timer(2.0).timeout
		hide()
