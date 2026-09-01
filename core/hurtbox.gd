class_name Hurtbox
extends Area2D

signal damaged(info: DamageInfo)

@export var invulnerable: bool = false


func take_damage(info: DamageInfo) -> void:
	if invulnerable:
		return
	damaged.emit(info)
