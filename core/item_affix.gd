class_name ItemAffix
extends Resource

## La *définition* d'un affixe d'objet : quelle statistique, dans quelle
## fourchette. Le tirage, lui, donne un StatMod — un affixe sur le disque, mille
## exemplaires différents en jeu.
##
## Une fourchette et non une valeur fixe : c'est elle qui fait qu'on regarde
## deux épées « acérées » avant de choisir. Sans elle, un affixe est un
## interrupteur et deux objets du même type sont interchangeables.

@export var id: String = ""

## Le champ de CharacterStats touché. Doit exister : voir StatMod.LABELS.
@export var stat: String = "attack_damage"

## Pourcentage plutôt que valeur absolue. Les deux existent pour la même
## statistique — « +6 dégâts » sur une arme de début vaut mieux que « +10 % »,
## l'inverse en fin de partie.
@export var percent: bool = false

## Fourchette du tirage, bornes comprises. Peut être négative : un temps de
## recharge qui baisse est un bon affixe.
@export var min_value: float = 1.0
@export var max_value: float = 1.0

## Poids dans la réserve. Un affixe rare n'est pas un affixe fort — c'est un
## affixe qu'on est content de voir.
@export var weight: int = 10


func roll(rng: RandomNumberGenerator) -> StatMod:
	var mode := StatMod.Mode.PERCENT if percent else StatMod.Mode.FLAT
	var v := rng.randf_range(min_value, max_value)
	# Arrondi à l'unité pour les valeurs entières et au centième pour les
	# fractions : « +7 dégâts » se lit, « +7.3184 dégâts » non, et l'infobulle
	# n'a pas à mentir sur ce qui est réellement appliqué.
	v = roundf(v) if absf(max_value) >= 1.0 else snappedf(v, 0.01)
	return StatMod.new(stat, mode, v)
