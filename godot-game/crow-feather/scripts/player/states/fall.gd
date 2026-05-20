extends State
class_name PlayerFallState

func enter(p: PlayerController):
	super.enter(p)
	print("Entered Fall")

func physics_update(delta):
	player.apply_gravity(delta)
	player.move_horizontally(delta)

	if player.is_on_floor():
		if player.move_input.length() > 0.1:
			Transitioned.emit(self, "Move")
		else:
			Transitioned.emit(self, "Idle")
