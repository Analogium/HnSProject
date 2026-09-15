class_name Hurtbox
extends Area2D

## **Le seul point de passage de tous les coups** : l'esquive, la mitigation, les états
## et le retour visuel s'y déclenchent, et non chez chaque acteur.

signal damaged(info: DamageInfo)

## Layer 4, « player_hurtbox » : ne sert qu'à teinter le retour visuel.
const PLAYER_LAYER := 1 << 3

## Plancher d'un coup : sans lui, assez d'armure rendrait invincible.
const MIN_DAMAGE := 1.0

@export var invulnerable: bool = false

## La fiche de l'acteur, par référence. Null — le mannequin — encaisse tout brut.
var stats: CharacterStats

## Ses états. Null — le mannequin — n'en prend aucun et ne tire rien.
var states: StatusEffects


func take_damage(info: DamageInfo) -> void:
	if invulnerable:
		return

	var on_player := (collision_layer & PLAYER_LAYER) != 0

	# La bénédiction de l'auteur d'abord : c'est **son** coup qui est plus faible,
	# et l'armure doit le voir comme tel.
	if info.author != null:
		info.multiplier(info.author.damage_dealt_factor)

	if stats != null:
		# L'esquive d'abord : un coup évité n'a pas eu lieu, pas de signal. Le test `> 0.0`
		# évite un tirage quand personne n'esquive (invariant 3).
		var evade := stats.evade_chance()
		if evade > 0.0 and Game.rng.randf() < evade:
			if HitFeedback.current != null:
				HitFeedback.current.miss(global_position, on_player)
			return
		mitigate_part(info)

	if HitFeedback.current != null:
		HitFeedback.current.hit(global_position, info, on_player)
	damaged.emit(info)
	# Après le signal, et même sur un coup qui vient de tuer : le nombre de tirages
	# ne dépend que de ce que le coup porte (invariant 3).
	if states != null:
		states.suffer(info.parts, info.author, Game.rng, stats.max_health if stats != null else 0.0)


## Chaque part par sa défense (règles dans CharacterStats). L'armure se calcule sur la
## part physique seule ; le plancher porte sur le total, versé à la part dominante.
## Publique : le banc d'équilibrage atténue un coup moyen, sans esquive ni tirage.
func mitigate_part(info: DamageInfo) -> void:
	for kind in info.parts.size():
		info.parts[kind] = stats.mitigate(kind, info.parts[kind])
	# L'engourdissement après les défenses : « +10 % de dégâts reçus » se lit sur ce
	# qui passe. Avant l'armure, elle en absorberait une part.
	if states != null:
		info.multiplier(states.damage_taken_factor)
	var total := info.amount
	if total < MIN_DAMAGE:
		info.parts[info.type] += MIN_DAMAGE - total
