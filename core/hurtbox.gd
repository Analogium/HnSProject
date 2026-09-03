class_name Hurtbox
extends Area2D

## La zone qui encaisse. C'est le seul point par lequel passent tous les coups
## du jeu — ceux du joueur, ceux des ennemis, ceux des projectiles — donc c'est
## ici que se déclenche le retour visuel, et non chez chaque acteur : sinon il
## faudrait y penser à chaque nouvel archétype.

signal damaged(info: DamageInfo)

## Layer 4 du projet, « player_hurtbox » (voir project.godot). Sert uniquement à
## teinter le nombre de dégâts : encaisser et infliger doivent se distinguer au
## coin de l'œil, sans lire le chiffre.
const PLAYER_LAYER := 1 << 3

@export var invulnerable: bool = false


func take_damage(info: DamageInfo) -> void:
	if invulnerable:
		return
	if HitFeedback.current != null:
		HitFeedback.current.hit(
			global_position, info, (collision_layer & PLAYER_LAYER) != 0
		)
	damaged.emit(info)
