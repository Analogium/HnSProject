class_name Item
extends RefCounted

## Un exemplaire d'objet : une base partagée, et les affixes qui n'appartiennent
## qu'à lui. Deux épées ramassées à cinq secondes d'écart sont deux Item
## différents autour du même ItemBase.
##
## C'est la raison d'être de la classe : sans elle, le butin rendrait la
## ressource du disque, toutes les épées du jeu seraient **le même objet**, et y
## écrire un affixe l'écrirait dans `epee.tres`.
##
## RefCounted et non Resource : un objet tiré au hasard n'a pas à savoir
## s'enregistrer sur le disque. La sauvegarde en fait un dictionnaire de quelques
## nombres, pas un fichier par épée.

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
## provenance**. Ils ne changent plus ensuite — un objet est ce qu'il est.
var explicits: Array[RolledAffix] = []

## Le niveau de l'objet : celui de la zone où il est tombé, posé **une fois** et
## jamais rejoué. C'est lui qui décide des tiers d'affixes qu'il a pu recevoir.
##
## Le niveau du personnage n'y entre pas. Adossé à lui, le butin s'améliorerait
## en jouant longtemps ; adossé à la zone, il s'améliore en allant là où c'est
## dangereux — et c'est la seule des deux règles qui laisse une décision à
## prendre.
##
## 1 par défaut : c'est ce que vaut un objet dont personne n'a dit d'où il
## venait — un objet de test, ou un objet d'une sauvegarde de version 1.
var item_level: int = 1

## L'état de ce manuel, quand cet objet en est un : son expérience et les points
## qu'on y a placés. Null pour tout le reste, c'est-à-dire pour tout le catalogue
## sauf les manuels.
##
## Sur l'exemplaire et **jamais sur l'archétype**, qui est un `.tres` partagé :
## y écrire donnerait à tous les manuels de foudre du jeu les points du dernier
## ouvert (invariant 2).
var manuel: Manuel


## `p_explicits` accepte les deux formes : des RolledAffix, ou de simples StatMod
## qui deviennent alors des affixes **sans provenance**. C'est exactement l'état
## d'un objet relu d'une sauvegarde écrite avant les paliers.
func _init(p_base: ItemBase, p_explicits: Array = [], p_level: int = 1) -> void:
	base = p_base
	explicits = []
	for e in p_explicits:
		explicits.append(e if e is RolledAffix else RolledAffix.orphelin(e))
	item_level = maxi(p_level, 1)
	# Un exemplaire de manuel naît avec son état vierge. Le créer ici plutôt qu'au
	# premier point placé évite d'écrire le même « si null » dans les cinq
	# endroits qui le liront.
	if base != null and base.manuel != null:
		manuel = Manuel.new()


## La rareté se **déduit** du nombre d'affixes au lieu d'être tirée à part : deux
## sources pour la même information finiraient par se contredire, et un objet
## doré sans affixe serait un mensonge.
func rarity() -> Rarity:
	# Un manuel n'a pas d'affixes : sa rareté est celle de sa **version**, que
	# porte le palier de sa lignée — le livre de départ est commun, ses versions
	# plus rares viendront au-dessus. Deux branches, mais **une seule fonction** :
	# le jour où la seconde se recopiera ailleurs, la rareté se mettra à dire deux
	# choses différentes selon l'endroit où on la regarde.
	if manuel != null:
		if base.palier <= 1:
			return Rarity.COMMUN
		return Rarity.MAGIQUE if base.palier == 2 else Rarity.RARE
	if explicits.is_empty():
		return Rarity.COMMUN
	if explicits.size() <= 2:
		return Rarity.MAGIQUE
	return Rarity.RARE


func color() -> Color:
	return RARITY_COLORS[rarity()]


## Le nom tel que le joueur le lit. Celui de la base est la clé française : c'est
## par cet accesseur, et pas par `base.display_name`, que passe tout affichage.
func display_name() -> String:
	return Textes.t(base.display_name)


## Ce livre enseigne-t-il cette compétence ? Faux pour tout ce qui n'est pas un
## manuel.
##
## **La question était posée à deux endroits** — le joueur, pour savoir combien de
## points on y a mis ; le chargement d'une sauvegarde, pour décider quels points
## garder. Deux réponses qui divergeraient donneraient des points relus qu'aucune
## case ne saurait dépenser, ou l'inverse, et rien ne le dirait avant la partie
## suivante.
func enseigne(id_competence: String) -> bool:
	if base == null or base.manuel == null:
		return false
	return base.manuel.case_de(id_competence) != null


## Ce livre reconnaît-il cet identifiant, case, passif ou nœud d'arbre confondus ?
##
## Distinct d'`enseigne()`, qui ne répond que des compétences : c'est cette
## question-là que se pose la relecture d'une sauvegarde, où les points des trois
## sortes arrivent mélangés dans le même dictionnaire.
func connait(identifiant: String) -> bool:
	if base == null or base.manuel == null:
		return false
	return base.manuel.connait(identifiant)


## Les nœuds investis de cette compétence, pour la résolution d'un lancer. Vide
## pour ce qui n'est pas un manuel, et pour une compétence que ce livre
## n'enseigne pas.
func talents_investis(id_competence: String) -> Array[TalentInvesti]:
	if manuel == null or base.manuel == null:
		return [] as Array[TalentInvesti]
	return manuel.talents_investis(base.manuel, id_competence)


## Ce que les passifs de ce livre donnent au personnage qui l'étudie.
func mods_de_passifs() -> Array[StatMod]:
	if manuel == null or base.manuel == null:
		return [] as Array[StatMod]
	return manuel.mods_de_passifs(base.manuel)


## Tout ce que l'objet donne, implicite compris : c'est cette liste que le calcul
## des statistiques du joueur consomme.
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
## dessinent depuis `explicits` — l'infobulle a besoin de leur provenance.
func implicit_line() -> String:
	var imp := base.implicit()
	return "" if imp == null else imp.label()
