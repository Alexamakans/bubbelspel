extends Node
class_name World

@export var water: Water

static func find_world_from_parent(node: Node) -> World:
	while node != null:
		node = node.get_parent()
		if node is World:
			return node
	return null
