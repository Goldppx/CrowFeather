extends Node
class_name State

signal Transitioned(state: State, new_state: String)

var player: PlayerController

func enter(p: PlayerController): player = p
func exit(): pass
func update(_delta): pass
func physics_update(_delta): pass
