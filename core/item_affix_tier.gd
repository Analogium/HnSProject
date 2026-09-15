class_name ItemAffixTier
extends Resource

## Un palier d'affixe : son niveau d'objet minimum et sa fourchette. Une Resource
## imbriquée : les paliers *sont* l'affixe.

## Le plus bas d'une échelle exige 1 (test de la réserve) : l'affixe doit exister dès
## les premières zones.
@export var required_level: int = 1

## Fourchette du tirage, bornes comprises. Peut être négative : un temps de
## recharge qui baisse est un bon affixe.
@export var min_value: float = 1.0
@export var max_value: float = 1.0

## La fourchette de la **borne haute** d'un affixe de dégâts ajoutés, au-dessus de la
## basse (test) ; zéro pour les autres.
@export var min_top: float = 0.0
@export var max_top: float = 0.0

## Égal par défaut : tout palier ouvert peut sortir, sinon le niveau serait une
## garantie et plus une chance.
@export var weight: int = 10
