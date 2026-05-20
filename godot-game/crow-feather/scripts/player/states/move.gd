extends State
class_name PlayerMoveState

func enter(p: PlayerController):
	super.enter(p)
	print("Entered Move")

func physics_update(delta):
	var speed_scale := 1.0
	player.apply_gravity(delta)
	if player.crouch_pressed:
		speed_scale = player.crouch_multiplier
		
	elif player.run_pressed:
		speed_scale = player.run_multiplier 
	player.move_horizontally(delta, speed_scale)

	if player.move_input.length() <= 0.1:
		Transitioned.emit(self, "Idle")
	elif player.jump_pressed:
		Transitioned.emit(self, "Jump")
	elif !player.is_on_floor() and player.velocity.y <= 0:
		Transitioned.emit(self, "Fall")
