class_name Arbre

## Ajouter un nœud depuis un rappel de physique, où l'arbre refuse d'être modifié : en
## différé, position comprise. Un parent libéré entre-temps libère aussi le nœud,
## sinon il reste hors de l'arbre, en fuite avec tout ce qu'il porte.
static func ajouter_en_differe(parent: Node, noeud: Node2D, at: Vector2) -> void:
	_entrer.call_deferred(parent, noeud, at)


## `parent` sans type : libéré, il ferait échouer la conversion avant le test.
static func _entrer(parent, noeud: Node2D, at: Vector2) -> void:
	if not is_instance_valid(parent):
		noeud.free()
		return
	(parent as Node).add_child(noeud)
	noeud.global_position = at
