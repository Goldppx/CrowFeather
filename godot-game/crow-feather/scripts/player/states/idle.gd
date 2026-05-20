extends State
class_name PlayerIdleState

func enter(p: PlayerController):
	super.enter(p)
	print("Entered Idle")

func physics_update(delta):
	player.apply_gravity(delta)
	player.stop_horizontal_movement(delta)

	if player.move_input.length() > 0.1:
		Transitioned.emit(self, "Move")
	elif player.jump_pressed:
		Transitioned.emit(self, "Jump")
	elif !player.is_on_floor() and player.velocity.y <= 0:
		Transitioned.emit(self, "Fall")
