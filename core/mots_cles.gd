class_name MotsCles

## Les mots-clés de compétence : la liste fermée, et ce que le joueur en lit.
##
## Un mot-clé n'est pas un rangement mais une **prise** : il n'existe que parce
## qu'un modificateur peut dire « ceci s'applique aux compétences qui le
## portent ». La liste est fermée parce qu'une chaîne libre dans un `.tres`
## donnerait un `projectiles` au pluriel que rien ne viserait jamais — le sort
## marcherait, il ne recevrait simplement pas son bonus, et rien ne le dirait.
##
## Et elle est **honnête** : le joueur les lit sur la fiche d'une compétence, et
## chacun lui promet que ce qui en parle l'améliorera. Un mot-clé que plus rien ne
## vise se retire ; il ne s'en ajoute pas « pour plus tard ». Le test de la réserve
## d'affixes le vérifie.
##
## Ne pas confondre avec `ItemBase.tags`, qui dit ce qu'un objet **est** pour
## filtrer ses affixes. Ceux-ci disent ce qu'une compétence **fait**.
##
## Une feuille : `StatMod` y lit les libellés et `Competence` les identifiants, et
## ces deux-là se connaissent déjà.

const PROJECTILE := "projectile"
const FOUDRE := "foudre"
const SORT := "sort"
const ATTAQUE := "attaque"

## Chaque identifiant et son libellé, dans l'ordre où la fiche les écrit : ce que
## la compétence fait, sa nature, sa famille.
##
## **Les identifiants ne changent jamais** : la portée d'un affixe en nomme un, et
## elle part dans les sauvegardes (invariant 1). Le libellé se change librement.
const LIBELLES := {
	PROJECTILE: "Projectile",
	FOUDRE: "Foudre",
	SORT: "Sort",
	ATTAQUE: "Attaque",
}


## À qui s'adresse une ligne qui le dit en toutes lettres : « ajoute 3 à 7 dégâts
## de froid **aux sorts** ». Un mot-clé absent d'ici s'écrit par son libellé, entre
## parenthèses — la forme des autres lignes portées.
const DESTINATAIRES := {
	ATTAQUE: "aux attaques",
	SORT: "aux sorts",
}


static func destinataire(id: String) -> String:
	if DESTINATAIRES.has(id):
		return Textes.t(DESTINATAIRES[id])
	return "(%s)" % libelle(id)


static func existe(id: String) -> bool:
	return LIBELLES.has(id)


## Le libellé dans la langue du joueur. La table garde ses valeurs françaises :
## ce sont elles, les clés de traduction.
static func libelle(id: String) -> String:
	return Textes.t(LIBELLES.get(id, id))
