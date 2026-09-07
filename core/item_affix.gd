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

## Les étiquettes qu'une base doit porter pour recevoir cet affixe : **une seule
## suffit**. Une armure ne donne pas d'allonge, une épée ne donne pas de PV —
## sans ce filtre, tous les objets se valent et le type de base ne veut plus rien
## dire.
##
## Des étiquettes et non des familles ; le champ s'appelait `families` jusqu'au
## jalon 5. Une épée et une baguette sont toutes deux de famille `weapon`, et il
## fallait pouvoir donner les dégâts d'attaque à l'une seulement. Voir
## `ItemBase.tags`.
##
## Vide = partout, sous réserve d'`exclut`. Utile pour un affixe volontairement
## universel — les résistances — et ça évite d'énumérer trente bases.
@export var tags: PackedStringArray = PackedStringArray()

## Les étiquettes qui interdisent cet affixe, quoi qu'en dise `tags` : une seule
## suffit à refuser, et **elle l'emporte**.
##
## C'est elle qui écrit « partout sauf sur les armes » en une ligne au lieu de
## neuf, et surtout : une base ajoutée plus tard hérite du refus sans qu'on ait
## à y penser, là où une liste d'autorisations l'aurait oubliée en silence.
@export var exclut: PackedStringArray = PackedStringArray()

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


## Le refus d'abord : `exclut` l'emporte sur `tags`, sinon « partout sauf les
## armes » se lirait « partout, y compris les armes qui portent une étiquette
## autorisée ».
func fits(base: ItemBase) -> bool:
	if base == null:
		return false
	for t in exclut:
		if base.tags.has(t):
			return false
	if tags.is_empty():
		return true
	for t in tags:
		if base.tags.has(t):
			return true
	return false


func roll(rng: RandomNumberGenerator) -> StatMod:
	var mode := StatMod.Mode.PERCENT if percent else StatMod.Mode.FLAT
	var v := rng.randf_range(min_value, max_value)
	# Arrondi à l'unité pour les valeurs entières et au centième pour les
	# fractions : « +7 dégâts » se lit, « +7.3184 dégâts » non, et l'infobulle
	# n'a pas à mentir sur ce qui est réellement appliqué.
	v = roundf(v) if absf(max_value) >= 1.0 else snappedf(v, 0.01)
	return StatMod.new(stat, mode, v)
