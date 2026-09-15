class_name DeferredTree

## Ajouter un nœud depuis un rappel de physique, où l'arbre refuse d'être modifié : en
## différé, position comprise. Un parent libéré entre-temps libère aussi le nœud,
## sinon il reste hors de l'arbre, en fuite avec tout ce qu'il porte.
static func add_deferred(parent: Node, node: Node2D, at: Vector2) -> void:
	_enter.call_deferred(parent, node, at)


## `parent` sans type : libéré, il ferait échouer la conversion avant le test.
static func _enter(parent, node: Node2D, at: Vector2) -> void:
	if not is_instance_valid(parent):
		node.free()
		return
	(parent as Node).add_child(node)
	node.global_position = at
