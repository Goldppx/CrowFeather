extends State
class_name PlayerJumpState

func enter(p: PlayerController):
	super.enter(p)
	player.jump()
	print("Entered Jump")

func physics_update(delta):
	player.apply_gravity(delta)
	player.move_horizontally(delta)

	if player.is_on_floor() and player.velocity.y <= 0:
		if player.move_input.length() > 0.1:
			Transitioned.emit(self, "Move")
		else:
			Transitioned.emit(self, "Idle")
	elif !player.is_on_floor() and player.velocity.y <= 0:
		Transitioned.emit(self, "Fall")
