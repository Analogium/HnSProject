class_name Explosion
extends Node3D

## L'explosion d'une boule de feu : elle frappe une fois ce qui est dans son rayon,
## sauf la cible directe qui a déjà reçu le coup, puis s'efface.
##
## **Elle naît en différé et frappe à sa première image de physique** : l'impact
## arrive dans un rappel de collision, où rien ne doit entrer dans l'arbre et où
## l'espace physique refuse les requêtes (invariant 4).

const LIFETIME := 0.3
## Le brasier dure **moitié moins** que les autres souffles. Tenue trois dixièmes
## de seconde, sa couronne de langues se mettait à ressembler à un feu de camp
## posé là — c'est un coup, pas un foyer. La nova de glace garde les trois
## dixièmes : le froid ne souffle pas, il prend, et ce qu'il gèle doit se voir.
const BLAZE_LIFE := 0.16

var _parts: Array[float] = []
var _author: StatusEffects
var _cast: SkillStats
var _radius := 0.0
## L'identifiant et non la référence : la cible directe peut être libérée avant que
## l'explosion ne frappe, et une référence libérée ne se compare plus.
var _excluded := 0
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false
## La nova seule les pose (jalon 44) : le Repoussoir, et le Grand froid, le « plus » par
## transi dans le cercle, `DEEP_COLD_MOST` au plus.
var knockback := 0.0
var crowd := 0.0
## La Succion de la Déferlante (jalon 45) : les PV que rend chaque flétri frappé.
var drink := 0.0
## Qui elle frappe : les ennemis, ou le camp du joueur quand c'est un ennemi qui explose.
var _mask := Targets.ENEMIES
## Celle d'une boule de feu (jalon 54) : ses flammes (`FlameFx.blast`) au lieu de la gerbe générique.
var flames := false


static func put(
	parent: Node, point: Vector3, parts: Array[float], radius: float, excluded: Hurtbox, tint: Color,
	author: StatusEffects, cast: SkillStats, mask := Targets.ENEMIES
) -> Explosion:
	var e := Explosion.new()
	e._mask = mask
	e._author = author
	e._cast = cast
	e._parts = parts.duplicate()
	e._radius = radius
	e._excluded = excluded.get_instance_id() if excluded != null else 0
	e._tint = tint
	# Ce que le souffle frappe dit à qui il est : le joueur, c'est une attaque ennemie.
	Settings.veil(e, Settings.ENEMY_ATTACKS if mask == Targets.PLAYER_SIDE else Settings.SPELLS)
	DeferredTree.add_deferred(parent, e, point)
	return e


## Celle d'un lancer tel quel : un tirage neuf, la couleur de sa nature. Neuf gestes
## l'écrivaient en entier.
static func of_cast(
	parent: Node, point: Vector3, cast: SkillStats, radius: float, author: StatusEffects
) -> Explosion:
	return put(
		parent, point, cast.roll(Game.rng), radius, null, DamageType.COLORS[cast.nature], author, cast
	)


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		if flames:
			FlameFx.blast(self, global_position, _nature(), _radius)
		elif _nature() == DamageType.Kind.LIGHTNING:
			BoltFx.crown(self, global_position, _radius, _nature())
		else:
			ElementFx.burst(self, global_position, _tint, _radius)
		var targets := Targets.in_circle(get_world_3d(), global_position, _radius, _mask)
		if crowd > 0.0:
			_crowded(targets)
		for target in targets:
			if target.get_instance_id() != _excluded:
				# Flétri **avant** le coup : celui que ce souffle flétrit ne rend rien encore.
				var wilted := target.has_state(StatusEffects.Kind.WILTING)
				Targets.strike(target, _parts, global_position, _author, _cast, knockback)
				if drink > 0.0 and _author != null and wilted:
					_author.heal.emit(drink)
	_age += delta
	if _age >= _life_span():
		queue_free()


func _crowded(targets: Array[Hurtbox]) -> void:
	var chilled := 0
	for target in targets:
		if target.has_state(StatusEffects.Kind.CHILL):
			chilled += 1
	var factor := 1.0 + crowd * 0.01 * float(mini(chilled, SkillStats.DEEP_COLD_MOST))
	_parts = DamageType.scaled(_parts, factor)


## Combien de temps ce souffle s'affiche.
func _life_span() -> float:
	return BLAZE_LIFE if _nature() == DamageType.Kind.FIRE else LIFETIME


## Sans lancer, la part la plus forte : l'obus du mortier et l'éclatement du gonfle
## soufflent dans leur nature eux aussi.
func _nature() -> int:
	return _cast.nature if _cast != null else DamageType.dominant(_parts)
