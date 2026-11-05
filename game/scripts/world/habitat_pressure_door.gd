## Mirrors WorldRoute's legal door state into the approved sliding kit leaf.
## Pressure checks, cancellation and save receipts remain owned by WorldRoute.
extends "res://scripts/navigation/campaign_door.gd"

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
var module: Node3D

## Connects the visible module; its moving leaf retains imported collision.
func bind_module(value: Node3D) -> void:
	module = value
	Kit.set_door_open(module, 0.0 if closed else 1.0)

## Applies the same state to collision and both visual LODs, without side effects.
func set_open(is_open: bool) -> void:
	super.set_open(is_open)
	if module != null:
		Kit.set_door_open(module, 1.0 if is_open else 0.0)
