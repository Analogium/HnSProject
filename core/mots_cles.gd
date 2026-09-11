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


static func existe(id: String) -> bool:
	return LIBELLES.has(id)


static func libelle(id: String) -> String:
	return LIBELLES.get(id, id)
