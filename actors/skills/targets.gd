class_name Targets

## Qui un coup atteint quand il ne naît pas d'une collision : la chaîne, le nuage,
## l'aura, le serpent, l'épée en orbite, l'explosion. Une seule requête pour les
## six — écrite chez chacune, l'une aurait fini par viser un autre calque.

## Layer 5, « enemy_hurtbox » : celui que la hitbox et les tirs du joueur masquent
## déjà dans leurs scènes.
const ENEMIES := 1 << 4
## Layer 1, « decor ».
const DECOR := 1

## Au-delà, la requête tronque en silence. Soixante-quatre hurtbox dans un rayon de
## cinquante pixels est un paquet que le jeu ne produit pas.
const MAXIMUM := 64


## Les hurtbox ennemies qui touchent ce cercle.
##
## **Jamais depuis un rappel de collision** : l'espace physique y est verrouillé, et
## la requête ne rend qu'une erreur (invariant 4).
static func in_circle(world: World2D, center: Vector2, radius: float) -> Array[Hurtbox]:
	var out: Array[Hurtbox] = []
	if world == null or radius <= 0.0:
		return out
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center)
	query.collision_mask = ENEMIES
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in world.direct_space_state.intersect_shape(query, MAXIMUM):
		var hurtbox := result["collider"] as Hurtbox
		if hurtbox != null:
			out.append(hurtbox)
	return out


## Aucun mur entre les deux points : une décharge qui traverse la pierre se lit
## comme un bug.
static func in_sight(world: World2D, of: Vector2, toward: Vector2) -> bool:
	var radius := PhysicsRayQueryParameters2D.create(of, toward, DECOR)
	return world.direct_space_state.intersect_ray(radius).is_empty()


## Par `Hurtbox.take_damage()`, comme tous les coups du jeu (invariant 5). Les parts
## sont recopiées par `as_parts()` : la mitigation écrit dans les siennes, et la
## cible suivante recevrait sinon ce qui reste après l'armure de la première.
##
## L'auteur voyage avec le coup : ses états changent ce qu'il inflige.
static func strike(target: Hurtbox, parts: Array[float], from_value: Vector2, author: StatusEffects) -> void:
	if is_instance_valid(target):
		var info := DamageInfo.as_parts(parts, from_value)
		info.author = author
		target.take_damage(info)


## Qui a été touché et quand il pourra l'être à nouveau, pour ce qui frappe au
## contact : un contact dure plusieurs images, et ne doit compter qu'une fois par
## période.
##
## Sur l'horloge de la présence et non sur l'horloge réelle : pendant un gel
## d'impact, la période s'arrête avec le jeu.
class Contacts:
	var _period: float
	var _age := 0.0
	var _next_one := {}

	func _init(period: float) -> void:
		_period = period

	func advance(delta: float) -> void:
		_age += delta

	## Vrai si la cible peut être frappée maintenant, et elle est alors marquée : la
	## question et le marquage vont ensemble, sinon un appelant frapperait sans
	## marquer.
	func accepts(target: Object) -> bool:
		var id := target.get_instance_id()
		if _age < float(_next_one.get(id, -1.0)):
			return false
		_next_one[id] = _age + _period
		return true
