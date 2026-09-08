class_name ItemAffixTier
extends Resource

## Un palier d'un affixe : à partir de quel niveau d'objet il peut sortir, et
## dans quelle fourchette il tire alors.
##
## Une Resource imbriquée, là où l'implicite d'une base est trois champs à plat :
## il y a cinq à neuf paliers par affixe et ils *sont* l'affixe. À plat, ce
## serait vingt-sept champs numérotés à la main.

## Le niveau d'objet minimum. Le palier le plus bas d'une échelle exige toujours
## 1 — le test de la réserve l'impose : sans cette règle, l'affixe n'existerait
## pas dans les premières zones et sa première sortie ressemblerait à un ajout
## de contenu plutôt qu'à une progression.
@export var niveau_requis: int = 1

## Fourchette du tirage, bornes comprises. Peut être négative : un temps de
## recharge qui baisse est un bon affixe.
@export var min_value: float = 1.0
@export var max_value: float = 1.0

## Poids de ce palier parmi ceux qui sont ouverts. **Égal par défaut**, et c'est
## voulu : tous les paliers atteints peuvent sortir, sinon le niveau d'objet ne
## serait plus une chance mais une garantie et il n'y aurait plus rien à espérer
## en regardant tomber un objet. Le champ existe pour l'exception.
@export var poids: int = 10
