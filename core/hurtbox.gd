class_name Hurtbox
extends Area2D

## La zone qui encaisse. C'est le seul point par lequel passent tous les coups
## du jeu — ceux du joueur, ceux des ennemis, ceux des projectiles — donc c'est
## ici que se déclenchent l'esquive, la mitigation et le retour visuel, et non
## chez chaque acteur : sinon il faudrait y penser à chaque nouvel archétype.

signal damaged(info: DamageInfo)

## Layer 4 du projet, « player_hurtbox » (voir project.godot). Sert uniquement à
## teinter le retour visuel : encaisser et infliger doivent se distinguer au
## coin de l'œil, sans lire le chiffre.
const PLAYER_LAYER := 1 << 3

## Un coup ne descend jamais en dessous : sinon une armure suffisante rendrait
## invincible, ce qui est une impasse et non une difficulté.
const MIN_DAMAGE := 1.0

@export var invulnerable: bool = false

## La fiche de l'acteur qui porte cette zone, posée par lui. Une référence et non
## une copie des champs défensifs : sept valeurs à recopier, et à ne pas oublier
## de remettre à jour à chaque objet équipé.
##
## Laissée à null, la zone encaisse tout brut — ce qu'il faut pour un mannequin
## de test, qui doit mesurer les dégâts et non les absorber.
var stats: CharacterStats


func take_damage(info: DamageInfo) -> void:
	if invulnerable:
		return

	var on_player := (collision_layer & PLAYER_LAYER) != 0

	if stats != null:
		# L'esquive d'abord : un coup évité n'est pas un coup à zéro, il n'a pas
		# eu lieu. Pas de signal damaged, donc ni recul, ni flash, ni vol de vie
		# pour l'attaquant.
		#
		# Le test `> 0.0` n'est pas une optimisation : sans lui, chaque coup du
		# jeu consommerait un tirage de Game.rng même quand personne n'a
		# d'esquive, ce qui décalerait toutes les graines de zone tirées ensuite.
		var evade := stats.evade_chance()
		if evade > 0.0 and Game.rng.randf() < evade:
			if HitFeedback.current != null:
				HitFeedback.current.miss(global_position, on_player)
			return
		info.amount = maxf(_mitigate(info), MIN_DAMAGE)

	if HitFeedback.current != null:
		HitFeedback.current.hit(global_position, info, on_player)
	damaged.emit(info)


## Le physique passe par l'armure, tout le reste par sa résistance. La règle de
## chacune vit dans CharacterStats, qui est aussi ce que lit la fiche de
## personnage — ici on ne fait que choisir laquelle s'applique.
func _mitigate(info: DamageInfo) -> float:
	if info.type == DamageType.Kind.PHYSICAL:
		return info.amount * (1.0 - stats.armor_reduction(info.amount))
	return info.amount * (1.0 - stats.resistance(info.type) * 0.01)
