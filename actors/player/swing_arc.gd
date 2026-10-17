class_name SwingArc
extends Node3D

## Trace du coup, **dessinée en pixels** et fabriquée au cap de la visée par
## `Slash` : la portée se règle en même temps que la hitbox. Se place sous
## l'AttackPivot, qui tourne avec la visée — le dessin, lui, défait cette rotation
## et prend le dessin fabriqué au cap le plus proche, parce qu'une planche tournée
## se rééchantillonne.
##
## Rien n'y pâlit — une lame à demi transparente sur un sol sombre sort grise. Le
## croissant finit en se résorbant, l'entaille et l'impact en se dissolvant.
##
## Le delta n'est volontairement pas dé-scalé : pendant le hit-stop, la lame se
## fige avec le reste du jeu.

## Le dessin, que la forme de la compétence choisit. La hitbox, elle, est la même
## pour les trois : chaque dessin reste dans sa capsule.
enum Style { ARC, STRIKE, CROSS }

## La trace vit un peu plus longtemps que la hitbox : 0.12 s de fenêtre de coup
## ne fait que 7 images, trop peu pour que l'œil lise le balayage.
@export var duration_scale: float = 1.5

## La lenteur de la frappe lourde est celle du dessin seulement — la hitbox garde la
## durée du coup, sinon le coup lourd deviendrait aussi un coup plus long.
const STRIKE_SLOWNESS := 1.3

var _t := 1.0          # progression 0 → 1, 1 = terminé
## Où tombe l'impact de la frappe lourde : le centre de la hitbox, posé par
## `Player._reach_out()` d'après l'allonge.
var impact_reach := 20.0
var _duration := 0.12
var _style := Style.ARC


func _ready() -> void:
	visible = false
	set_process(false)


func play(duration: float, style := Style.ARC) -> void:
	_style = style
	_duration = maxf(duration * duration_scale * (STRIKE_SLOWNESS if style == Style.STRIKE else 1.0), 0.01)
	_t = 0.0
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_t += delta / _duration
	if _t >= 1.0:
		_t = 1.0
		visible = false
		set_process(false)
