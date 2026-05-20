extends Node

var player: PlayerController
var current_state: State
@export var initial_state: State

func initialize(p: PlayerController):
	player = p
	await get_tree().process_frame

	for child in get_children():
		if child is State:
			child.Transitioned.connect(_on_state_transition)

	if initial_state:
		current_state = initial_state
		current_state.enter(player)
	else:
		push_error("Initial state is not assigned!")

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _on_state_transition(from_state: State, to_state_name: String):
	if from_state != current_state:
		return

	var new_state = get_node_or_null(to_state_name)
	if new_state and new_state is State:
		current_state.exit()
		current_state = new_state
		current_state.enter(player)
	else:
		push_warning("State '%s' not found!" % to_state_name)
