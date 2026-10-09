class_name Catalysis
extends Node2D

## La Catalyse (jalon 41) : au point visé, chaque ennemi du cercle qui porte au moins deux
## des trois états élémentaires les **perd**, et chaque paire réagit ; puis le cercle est
## frappé une fois, dans la nature du tour, qui sème l'état de la suivante. Les états se
## lisent **avant** la frappe : elle fait réagir ce qu'on a posé, pas ce qu'elle pose.

## Ce que porte une réaction, en part d'un coup de la Catalyse, moitié dans chaque nature
## de sa paire. Premier réglage : les réactions sont ce qu'on vient chercher.
const REACTION_PART := 1.5
## Vapeur : le rayon de son explosion. Arc ardent : combien de voisins, jusqu'où. Givre
## conducteur : jusqu'où le transi gagne. Leur arbre les hausse (`arcs()`, `spread_reach()`).
const VAPOR_RADIUS := 26.0
const ARCS := 3
const ARC_REACH := 64.0
const SPREAD_REACH := 48.0
const LIFETIME := 0.45

enum Reaction { VAPOR, ARC, CONDUCTION }
## La paire d'états qui déclenche chaque réaction : **le seul endroit** qui les lie, que le
## coup et la fiche lisent.
const PAIRS := {
	Reaction.VAPOR: [StatusEffects.Kind.IGNITE, StatusEffects.Kind.CHILL],
	Reaction.ARC: [StatusEffects.Kind.IGNITE, StatusEffects.Kind.NUMB],
	Reaction.CONDUCTION: [StatusEffects.Kind.CHILL, StatusEffects.Kind.NUMB],
}
const NAMES := {
	Reaction.VAPOR: "Vapeur", Reaction.ARC: "Arc ardent", Reaction.CONDUCTION: "Givre conducteur",
}
const ELEMENTAL := [StatusEffects.Kind.IGNITE, StatusEffects.Kind.CHILL, StatusEffects.Kind.NUMB]

var _cast: SkillStats
var _author: StatusEffects
var _age := 0.0


static func burst(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> Catalysis:
	var c := Catalysis.new()
	c._cast = cast
	c._author = author
	parent.add_child(c)
	Settings.veil(c, Settings.SPELLS)
	c.global_position = point
	c._react()
	Targets.strike_circle(c.get_world_2d(), point, cast.radius, cast, author)
	return c


## Les réactions de chaque ennemi du cercle. Le transi se propage avant d'être retiré :
## `pass_on()` recopie l'état présent. L'Amorce prête l'état du tour, qui réagit sans être posé.
func _react() -> void:
	var world := get_world_2d()
	var lent := lent_by(_cast)
	for target in Targets.in_circle(world, global_position, _cast.radius):
		var held := held_by(target.states)
		var reacting := held.duplicate()
		if lent >= 0 and not lent in reacting:
			reacting.append(lent)
		if reacting.size() < 2:
			continue
		var at := target.global_position
		var reactions := reactions_of(reacting)
		if Reaction.CONDUCTION in reactions:
			for other in Targets.in_circle(world, at, spread_reach(_cast)):
				if other != target and other.states != null:
					# Prêté, le transi n'est pas sur l'ennemi : il se pose sur ses voisins.
					if StatusEffects.Kind.CHILL in held:
						target.states.pass_on(StatusEffects.Kind.CHILL, other.states)
					else:
						other.states.put(
							StatusEffects.Kind.CHILL, 0.0, _author, _cast.skill_id,
							_cast.strength_of(StatusEffects.Kind.CHILL)
						)
		for kind: int in held:
			target.states.remove(kind)
		for reaction: Reaction in reactions:
			_trigger(reaction, target, at)


## L'état que l'Amorce prête : celui de la nature du tour, s'il est élémentaire ; -1 sinon.
static func lent_by(cast: SkillStats) -> int:
	if cast.primer <= 0.0:
		return -1
	for kind: int in ELEMENTAL:
		if StatusEffects.NATURES[kind] == cast.nature:
			return kind
	return -1


## Ce que porte une réaction, en part d'un coup ; combien de voisins l'arc gagne ; jusqu'où
## le transi gagne. **Les seuls calculs**, que la fiche lit aussi.
static func reaction_part(cast: SkillStats) -> float:
	return REACTION_PART * (1.0 + cast.reaction_power * 0.01)


static func arcs(cast: SkillStats) -> int:
	return ARCS + maxi(cast.target_count() - 1, 0)


static func spread_reach(cast: SkillStats) -> float:
	return SPREAD_REACH + cast.contagion


## Les états élémentaires que porte ce corps.
static func held_by(states: StatusEffects) -> Array[int]:
	var out: Array[int] = []
	if states == null:
		return out
	for kind: int in ELEMENTAL:
		if states.active(kind):
			out.append(kind)
	return out


## Chaque paire présente réagit ; les trois états, les trois réactions.
static func reactions_of(held: Array[int]) -> Array[Reaction]:
	var out: Array[Reaction] = []
	for reaction: Reaction in PAIRS:
		if (PAIRS[reaction] as Array).all(func(k: int) -> bool: return k in held):
			out.append(reaction)
	return out


## Chaque réaction frappe l'ennemi qui réagit ; la Vapeur souffle autour de lui, l'Arc
## ardent gagne ses voisins.
func _trigger(reaction: Reaction, target: Hurtbox, at: Vector2) -> void:
	var parts := _parts(reaction)
	match reaction:
		Reaction.VAPOR:
			Explosion.put(get_parent(), at, parts, VAPOR_RADIUS, null, _color(reaction), _author, _cast)
			if _cast.ground_duration > 0.0:
				# Une nappe de la Vapeur : ses deux natures, sous son souffle.
				var natures: Array[int] = []
				for kind: int in PAIRS[reaction]:
					natures.append(StatusEffects.NATURES[kind])
				var mist := _cast.ground(VAPOR_RADIUS)
				mist.blend(natures)
				mist.nature = DamageType.Kind.FIRE
				DashTrail.patch(get_parent(), at, mist, _author)
		Reaction.ARC:
			Targets.strike(target, parts, at, _author, _cast)
			var struck := {target.get_instance_id(): true}
			for i in arcs(_cast):
				var next := Targets.nearest(get_world_2d(), at, ARC_REACH, struck)
				if next == null:
					break
				struck[next.get_instance_id()] = true
				Targets.strike(next, parts, at, _author, _cast)
				ChainLightning.trace(get_parent(), PackedVector2Array([at, next.global_position]), _color(reaction))
		Reaction.CONDUCTION:
			Targets.strike(target, parts, at, _author, _cast)


## Un coup de la Catalyse à `REACTION_PART`, moitié dans chaque nature de la paire. Un
## tirage par réaction (invariant 3).
func _parts(reaction: Reaction) -> Array[float]:
	var total := DamageType.total(_cast.roll(Game.rng))
	var out := DamageType.empty_parts()
	for kind: int in PAIRS[reaction]:
		out[StatusEffects.NATURES[kind]] += total * reaction_part(_cast) * 0.5
	return out


static func _color(reaction: Reaction) -> Color:
	var pair: Array = PAIRS[reaction]
	return StatusEffects.color(pair[0]).lerp(StatusEffects.color(pair[1]), 0.5)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


## Le sceau (`Witchcraft.sigil()`), ses quatre temps sur sa vie, puis il se coupe. Les
## réactions se dessinent par ce qu'elles posent : l'explosion, l'arc, l'icône du transi.
func _draw() -> void:
	var step := mini(int(_age / LIFETIME * float(Witchcraft.STEPS)), Witchcraft.STEPS - 1)
	Witchcraft.sigil(_cast.radius, step).put(self, Vector2.ZERO)
