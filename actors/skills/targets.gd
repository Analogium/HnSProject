class_name Targets

## Qui un coup atteint quand il ne naît pas d'une collision : la chaîne, le nuage,
## l'aura, le serpent, l'épée en orbite, l'explosion, le faisceau. Une seule requête
## pour toutes — écrite chez chacune, l'une aurait fini par viser un autre calque.

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
	if world == null or radius <= 0.0:
		return [] as Array[Hurtbox]
	var circle := CircleShape2D.new()
	circle.radius = radius
	return _touched(world, circle, Transform2D(0.0, center))


## Celles qui touchent un segment épais : ce que frappe un faisceau, sur toute sa
## ligne. Mêmes règles qu'`in_circle()`.
static func in_capsule(
	world: World2D, of: Vector2, toward: Vector2, width: float
) -> Array[Hurtbox]:
	var length := of.distance_to(toward)
	if world == null or length <= 0.0 or width <= 0.0:
		return [] as Array[Hurtbox]
	var capsule := CapsuleShape2D.new()
	capsule.radius = width * 0.5
	# La hauteur de Godot compte les deux calottes : le segment, plus un rayon de chaque
	# bout. Et la capsule est debout, d'où le quart de tour.
	capsule.height = length + width
	return _touched(
		world, capsule,
		Transform2D((toward - of).angle() + PI * 0.5, (of + toward) * 0.5)
	)


## La requête elle-même, partagée : deux copies auraient fini par viser deux calques.
static func _touched(world: World2D, shape: Shape2D, at: Transform2D) -> Array[Hurtbox]:
	var out: Array[Hurtbox] = []
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = at
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
## L'auteur et le lancer voyagent avec le coup : ses états et ses dégâts contre un état
## changent ce qu'il inflige.
static func strike(
	target: Hurtbox, parts: Array[float], from_value: Vector2, author: StatusEffects, cast: SkillStats
) -> void:
	if is_instance_valid(target):
		var info := DamageInfo.roll(cast, from_value, parts)
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
