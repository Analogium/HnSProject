extends RefCounted

## Le geste joué d'un trait (jalon 47) : un lancer ne pose son coup qu'à l'impact et garde le
## corps jusqu'à la fin. Les tests des formes vérifient ce que le coup pose, pas quand —
## `test_shapes.gd`, section « Le geste », tient le quand.


## Lance la case, puis porte le geste jusqu'au bout : impact compris, corps rendu.
static func cast(player: Player, slot: int) -> bool:
	var cast_ok := player.cast_slot(slot)
	land(player)
	return cast_ok


static func land(player: Player) -> void:
	if player._gesture != null:
		player._tick_gesture(player._gesture.left)
