class_name SwingArc
extends Node3D

## Où se pose la trace du coup (`SteelFx.swing`) : sous l'AttackPivot, qui tourne avec la
## visée. La portée se règle en même temps que la hitbox.
##
## Le temps n'est volontairement pas dé-scalé : pendant le hit-stop, la lame se fige avec le
## reste du jeu.

## Le dessin, que la forme de la compétence choisit. La hitbox, elle, est la même
## pour les trois : chaque dessin reste dans sa capsule.
enum Style { ARC, STRIKE, CROSS }

## La trace vit un peu plus longtemps que la hitbox : 0.12 s de fenêtre de coup
## ne fait que 7 images, trop peu pour que l'œil lise le balayage.
@export var duration_scale: float = 1.5

## La lenteur de la frappe lourde est celle du dessin seulement — la hitbox garde la
## durée du coup, sinon le coup lourd deviendrait aussi un coup plus long.
const STRIKE_SLOWNESS := 1.3

## Où tombe l'impact de la frappe lourde : le centre de la hitbox, posé par
## `Player._reach_out()` d'après l'allonge.
var impact_reach := 20.0


func play(duration: float, style := Style.ARC, nature := DamageType.Kind.PHYSICAL) -> void:
	var shown := maxf(duration * duration_scale * (STRIKE_SLOWNESS if style == Style.STRIKE else 1.0), 0.01)
	SteelFx.swing(self, nature, impact_reach, shown, style)
