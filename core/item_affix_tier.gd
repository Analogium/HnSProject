class_name ItemAffixTier
extends Resource

## Un palier d'un affixe : à partir de quel niveau d'objet il peut sortir, et
## dans quelle fourchette il tire alors.
##
## C'est le contenu du jalon 5, pas sa plomberie. Un affixe n'est plus une
## fourchette mais une **échelle** de fourchettes, et c'est le niveau de l'objet
## qui décide de celles qui sont ouvertes.
##
## Une Resource imbriquée, contrairement à l'implicite d'une base — qui est trois
## champs à plat parce qu'il y en a exactement un. Ici il y en a cinq à neuf par
## affixe et ils *sont* l'affixe : les mettre à plat demanderait vingt-sept
## champs numérotés à la main.

## Le niveau d'objet minimum. Le palier le plus bas d'une échelle exige toujours
## 1 : sans cette règle, l'affixe n'existerait pas dans les premières zones et sa
## première sortie ressemblerait à un ajout de contenu plutôt qu'à une
## progression. Le test de la réserve l'exige.
@export var niveau_requis: int = 1

## Fourchette du tirage, bornes comprises. Peut être négative : un temps de
## recharge qui baisse est un bon affixe.
@export var min_value: float = 1.0
@export var max_value: float = 1.0

## Poids de ce palier parmi ceux qui sont ouverts. **Égal par défaut**, et c'est
## voulu : tous les paliers atteints peuvent sortir, le meilleur comme les moins
## bons, sinon le niveau d'objet ne serait plus une chance mais une garantie et
## il n'y aurait plus rien à espérer en regardant tomber un objet.
##
## Le champ existe pour l'exception — un palier qu'on veut voir plus souvent que
## les autres — et pour le réglage, quand la générosité de la première
## calibration se verra en jouant.
@export var poids: int = 10
