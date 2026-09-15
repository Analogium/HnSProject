class_name Cibles

## Qui un coup atteint quand il ne naît pas d'une collision : la chaîne, le nuage,
## l'aura, le serpent, l'épée en orbite, l'explosion. Une seule requête pour les
## six — écrite chez chacune, l'une aurait fini par viser un autre calque.

## Layer 5, « enemy_hurtbox » : celui que la hitbox et les tirs du joueur masquent
## déjà dans leurs scènes.
const ENNEMIS := 1 << 4
## Layer 1, « decor ».
const DECOR := 1

## Au-delà, la requête tronque en silence. Soixante-quatre hurtbox dans un rayon de
## cinquante pixels est un paquet que le jeu ne produit pas.
const MAXIMUM := 64


## Les hurtbox ennemies qui touchent ce cercle.
##
## **Jamais depuis un rappel de collision** : l'espace physique y est verrouillé, et
## la requête ne rend qu'une erreur (invariant 4).
static func dans_le_cercle(monde: World2D, centre: Vector2, rayon: float) -> Array[Hurtbox]:
	var out: Array[Hurtbox] = []
	if monde == null or rayon <= 0.0:
		return out
	var cercle := CircleShape2D.new()
	cercle.radius = rayon
	var requete := PhysicsShapeQueryParameters2D.new()
	requete.shape = cercle
	requete.transform = Transform2D(0.0, centre)
	requete.collision_mask = ENNEMIS
	requete.collide_with_areas = true
	requete.collide_with_bodies = false
	for resultat in monde.direct_space_state.intersect_shape(requete, MAXIMUM):
		var hurtbox := resultat["collider"] as Hurtbox
		if hurtbox != null:
			out.append(hurtbox)
	return out


## Aucun mur entre les deux points : une décharge qui traverse la pierre se lit
## comme un bug.
static func a_vue(monde: World2D, de: Vector2, vers: Vector2) -> bool:
	var rayon := PhysicsRayQueryParameters2D.create(de, vers, DECOR)
	return monde.direct_space_state.intersect_ray(rayon).is_empty()


## Par `Hurtbox.take_damage()`, comme tous les coups du jeu (invariant 5). Les parts
## sont recopiées par `en_parts()` : la mitigation écrit dans les siennes, et la
## cible suivante recevrait sinon ce qui reste après l'armure de la première.
##
## L'auteur voyage avec le coup : ses états changent ce qu'il inflige.
static func frapper(cible: Hurtbox, parts: Array[float], depuis: Vector2, auteur: Etats) -> void:
	if is_instance_valid(cible):
		var info := DamageInfo.en_parts(parts, depuis)
		info.auteur = auteur
		cible.take_damage(info)


## Qui a été touché et quand il pourra l'être à nouveau, pour ce qui frappe au
## contact : un contact dure plusieurs images, et ne doit compter qu'une fois par
## période.
##
## Sur l'horloge de la présence et non sur l'horloge réelle : pendant un gel
## d'impact, la période s'arrête avec le jeu.
class Contacts:
	var _periode: float
	var _age := 0.0
	var _prochain := {}

	func _init(periode: float) -> void:
		_periode = periode

	func avancer(delta: float) -> void:
		_age += delta

	## Vrai si la cible peut être frappée maintenant, et elle est alors marquée : la
	## question et le marquage vont ensemble, sinon un appelant frapperait sans
	## marquer.
	func accepte(cible: Object) -> bool:
		var id := cible.get_instance_id()
		if _age < float(_prochain.get(id, -1.0)):
			return false
		_prochain[id] = _age + _periode
		return true
