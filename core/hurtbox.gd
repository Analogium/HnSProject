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

## Un coup ne descend jamais en dessous : sinon un ennemi suffisamment blindé
## deviendrait invincible, ce qui est une impasse et non une difficulté.
const MIN_DAMAGE := 1.0

@export var invulnerable: bool = false

## Points retranchés à chaque coup, posés par l'acteur d'après ses affixes.
## Ici et non dans _on_damaged de l'acteur : le nombre flottant est calculé
## juste en dessous, et il doit annoncer les dégâts réellement subis.
var damage_reduction := 0.0


func take_damage(info: DamageInfo) -> void:
	if invulnerable:
		return
	if damage_reduction > 0.0:
		info.amount = maxf(info.amount - damage_reduction, MIN_DAMAGE)
	if HitFeedback.current != null:
		HitFeedback.current.hit(
			global_position, info, (collision_layer & PLAYER_LAYER) != 0
		)
	damaged.emit(info)
