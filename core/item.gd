class_name Item
extends RefCounted

## Un exemplaire d'objet : une base partagée, et les affixes qui n'appartiennent
## qu'à lui. Deux épées ramassées à cinq secondes d'écart sont deux Item
## différents autour du même ItemBase.
##
## C'est la raison d'être de la classe. Avant elle, le butin rendait directement
## la ressource du disque : toutes les épées du jeu étaient **le même objet**, et
## y écrire un affixe l'aurait écrit dans `epee.tres`, donc dans toutes les
## parties suivantes.
##
## RefCounted et non Resource : un objet tiré au hasard n'a pas à savoir
## s'enregistrer sur le disque. Le jour où il faudra sauvegarder une partie,
## c'est un dictionnaire de quelques nombres à écrire — pas un fichier par épée.

enum Rarity { COMMUN, MAGIQUE, RARE }

## Blanc, bleu, or : les couleurs du genre, et l'or est déjà celle des critiques
## et des élites dans ce jeu — partout, elle veut dire « ça compte plus que
## d'habitude ».
const RARITY_COLORS := [
	Color(0.85, 0.85, 0.88),
	Color(0.42, 0.62, 0.98),
	Color(0.95, 0.82, 0.30),
]

var base: ItemBase
## Les affixes tirés à la création, déjà résolus en valeurs, **et leur
## provenance** : quel affixe, quel palier. Ils ne changent plus ensuite — un
## objet est ce qu'il est.
var explicits: Array[RolledAffix] = []

## Le niveau de l'objet : celui de la zone où il est tombé, posé **une fois** et
## jamais rejoué. C'est lui qui décidera des tiers d'affixes qu'il a pu recevoir
## (étape 3), et lui qui permettra un jour à l'artisanat de relancer un objet
## dans la réserve de *son* niveau plutôt que dans celle de la zone où l'on se
## trouve.
##
## Le niveau du personnage n'y entre pas. Adossé à lui, le butin s'améliorerait
## en jouant longtemps ; adossé à la zone, il s'améliore en allant là où c'est
## dangereux — et c'est la seule des deux règles qui laisse une décision à
## prendre.
##
## 1 par défaut : c'est ce que vaut un objet dont personne n'a dit d'où il
## venait — un objet de test, ou un objet rechargé d'une sauvegarde écrite avant
## que ce champ existe.
var item_level: int = 1


## `p_explicits` accepte les deux formes : des RolledAffix, ou de simples StatMod
## qui deviennent alors des affixes **sans provenance**. Ce n'est pas une
## complaisance envers les appelants — c'est exactement l'état d'un objet relu
## d'une sauvegarde écrite avant les paliers, et il fallait bien le représenter.
func _init(p_base: ItemBase, p_explicits: Array = [], p_level: int = 1) -> void:
	base = p_base
	explicits = []
	for e in p_explicits:
		explicits.append(e if e is RolledAffix else RolledAffix.orphelin(e))
	item_level = maxi(p_level, 1)


## La rareté se **déduit** du nombre d'affixes au lieu d'être tirée à part :
## deux sources pour la même information finiraient par se contredire, et un
## objet doré sans affixe serait un mensonge.
func rarity() -> Rarity:
	if explicits.is_empty():
		return Rarity.COMMUN
	if explicits.size() <= 2:
		return Rarity.MAGIQUE
	return Rarity.RARE


func color() -> Color:
	return RARITY_COLORS[rarity()]


func display_name() -> String:
	return base.display_name


## Tout ce que l'objet donne, implicite compris — c'est cette liste que le
## calcul des statistiques du joueur consommera.
func mods() -> Array[StatMod]:
	var all: Array[StatMod] = []
	var imp := base.implicit()
	if imp != null:
		all.append(imp)
	for r in explicits:
		all.append(r.mod)
	return all


## La ligne d'implicite de l'infobulle, à part et en premier : c'est ce que la
## base garantit, le reste est le fruit du tirage. Les explicites, eux, se
## dessinent depuis `explicits` — l'infobulle a besoin de leur provenance, pas
## seulement de leur texte.
func implicit_line() -> String:
	var imp := base.implicit()
	return "" if imp == null else imp.label()



