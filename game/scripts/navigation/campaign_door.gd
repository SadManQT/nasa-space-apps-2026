extends StaticBody3D
class_name CampaignDoor

## A named physical door. Campaign logic owns whether a transition is legal;
## this node only mirrors the legal open/closed state into collision.

@export var boundary_id := ""
var closed := true
var collision_shape: CollisionShape3D

func setup(id: String, starts_open: bool) -> void:
	boundary_id = id
	closed = not starts_open
	collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.disabled = not closed

func set_open(is_open: bool) -> void:
	closed = not is_open
	if collision_shape != null:
		collision_shape.disabled = not closed
