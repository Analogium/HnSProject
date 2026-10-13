class_name Reactions
extends RefCounted

## Les réactions de la sorcière (jalon 41, ex-Catalyse) : deux états élémentaires sur un même
## ennemi **sont consommés** et réagissent. Le Précipité du Projectile élémentaire et le
## Palimpseste des Glyphes (jalon 49) passent par `react()`.

## Vapeur : le rayon de son explosion. Arc ardent : combien de voisins, jusqu'où. Givre
## conducteur : jusqu'où le transi gagne.
const VAPOR_RADIUS := 26.0
const ARCS := 3
const ARC_REACH := 64.0
const SPREAD_REACH := 48.0

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


## Ce que font réagir ces états sur cet ennemi : `held`, ceux qu'il porte, sont consommés ;
## `reacting` y ajoute un état prêté. Le transi se propage avant d'être retiré : `pass_on()`
## recopie l'état présent. `part` : ce que porte une réaction, en part d'un coup de `cast`.
## Faux sous la garde : il a réagi il y a moins de `SkillStats.REACTION_GUARD`.
static func react(
	parent: Node, target: Hurtbox, held: Array[int], reacting: Array[int], cast: SkillStats,
	author: StatusEffects, part: float
) -> bool:
	var now := Engine.get_physics_frames()
	if now - int(target.get_meta(&"reacted", -1_000_000)) < roundi(SkillStats.REACTION_GUARD * Engine.physics_ticks_per_second):
		return false
	target.set_meta(&"reacted", now)
	var at := target.global_position
	var reactions := reactions_of(reacting)
	if Reaction.CONDUCTION in reactions:
		for other in Targets.in_circle(target.get_world_2d(), at, SPREAD_REACH):
			if other != target and other.states != null:
				# Prêté, le transi n'est pas sur l'ennemi : il se pose sur ses voisins.
				if StatusEffects.Kind.CHILL in held:
					target.states.pass_on(StatusEffects.Kind.CHILL, other.states)
				else:
					other.states.put(
						StatusEffects.Kind.CHILL, 0.0, author, cast.skill_id,
						cast.strength_of(StatusEffects.Kind.CHILL)
					)
	for kind: int in held:
		target.states.remove(kind)
	for reaction: Reaction in reactions:
		_trigger(parent, reaction, target, at, cast, author, part)
	return true


## Le Précipité (jalon 49) : un trait qui touche un ennemi portant les deux autres états les
## fait réagir. Différé : l'impact est un rappel de collision (invariant 4) ; les états ont
## été lus avant le coup, qui pose le sien.
static func precipitate(
	parent: Node, target, held: Array[int], cast: SkillStats, author: StatusEffects
) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(target):
		return
	var still: Array[int] = []
	for kind: int in held:
		if (target as Hurtbox).has_state(kind):
			still.append(kind)
	if still.size() >= 2:
		# Sans les +200 % de chance d'état du trait : elle reposerait aussitôt ce qu'elle consomme.
		var reaction := cast.echoed(1.0)
		reaction.status_chance_increase = 0.0
		react(parent, target, still, still, reaction, author, cast.precipitate * 0.01)


## Les états élémentaires que porte ce corps.
static func held_by(states: StatusEffects) -> Array[int]:
	var out: Array[int] = []
	if states == null:
		return out
	for kind: int in StatusEffects.ELEMENTAL:
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
static func _trigger(
	parent: Node, reaction: Reaction, target: Hurtbox, at: Vector2, cast: SkillStats,
	author: StatusEffects, part: float
) -> void:
	var parts := _parts(reaction, cast, part)
	match reaction:
		Reaction.VAPOR:
			Explosion.put(parent, at, parts, VAPOR_RADIUS, null, _color(reaction), author, cast)
		Reaction.ARC:
			Targets.strike(target, parts, at, author, cast)
			var struck := {target.get_instance_id(): true}
			for i in ARCS:
				var next := Targets.nearest(target.get_world_2d(), at, ARC_REACH, struck)
				if next == null:
					break
				struck[next.get_instance_id()] = true
				Targets.strike(next, parts, at, author, cast)
				ChainLightning.trace(parent, PackedVector2Array([at, next.global_position]), _color(reaction))
		Reaction.CONDUCTION:
			Targets.strike(target, parts, at, author, cast)


## Un coup de `cast` à `part`, moitié dans chaque nature de la paire. Un tirage par réaction
## (invariant 3).
static func _parts(reaction: Reaction, cast: SkillStats, part: float) -> Array[float]:
	var total := DamageType.total(cast.roll(Game.rng))
	var out := DamageType.empty_parts()
	for kind: int in PAIRS[reaction]:
		out[StatusEffects.NATURES[kind]] += total * part * 0.5
	return out


static func _color(reaction: Reaction) -> Color:
	var pair: Array = PAIRS[reaction]
	return StatusEffects.color(pair[0]).lerp(StatusEffects.color(pair[1]), 0.5)
