class_name Manuel
extends RefCounted

## Ce qu'un exemplaire de manuel a appris : son expérience, et les points placés
## dans ses cases, ses passifs et les nœuds de ses arbres. **Un par manuel
## ramassé.**
##
## Son **niveau n'est pas ici** : `niveau()` le déduit de l'expérience à chaque
## appel. Le retenir créerait la deuxième vérité que la sauvegarde refuse partout
## ailleurs — elle n'écrit ni PV, ni statistiques, ni total d'attributs.
##
## RefCounted et non Resource, pour la raison qui a fait ce choix sur `Item` et
## `Personnage` : ceci n'est pas un fichier du projet mais l'état d'un objet de
## la partie, et une Resource sauvegardée porte des chemins de scripts qu'elle
## exécute au chargement.
##
## Il ne connaît pas son archétype. C'est l'objet qui porte les deux — sa base
## sait quel livre c'est, son manuel sait ce qu'il en a tiré — et les règles qui
## ont besoin des deux reçoivent l'archétype en argument, comme
## `Competence.resoudre()` reçoit la fiche. Une référence en retour serait un
## deuxième chemin vers la même information.

## La courbe du manuel : sa propre base et sa propre puissance, sur la forme
## partagée avec le personnage. Réglées sur ce que rapporte une zone — un grunt
## de niveau 1 vaut onze points — pour qu'un livre neuf monte d'un niveau en une
## poignée d'ennemis et de trois en une zone, puis ralentisse franchement.
##
## **Premier réglage, à sentir en jouant** : l'équilibrage fin est hors jalon, et
## ces deux nombres sont le premier endroit où revenir quand la progression
## paraîtra molle ou galopante.
const XP_BASE := 90.0
const XP_PUISSANCE := 1.25

## Vingt niveaux, donc vingt points — et **un manuel ne se remplit plus** depuis
## le jalon 10 : ses cases, son passif et les nœuds de ses arbres se servent dans
## le même sac, et le manuel de la foudre offre soixante-quatre destinations pour
## ces vingt points.
##
## C'est le plafond qui fait du livre un choix plutôt qu'une collection à
## compléter, et c'est ce qui distingue deux exemplaires du même manuel.
const NIVEAU_MAX := 20

## L'expérience **totale** accumulée par ce livre. Totale et non « depuis le
## dernier niveau » : c'est elle qu'on écrit, et le niveau s'en déduit.
var experience := 0

## Points placés, par identifiant : les cases, les passifs et les nœuds d'arbre
## s'y mélangent, parce que ce sont les mêmes points. Les identifiants partent sur
## le disque : ils ne se renomment jamais, et deux d'entre eux ne peuvent pas se
## confondre dans un même livre (invariant 1).
##
## En lecture seule de fait : on y entre par `investir()` et par `reprendre()`,
## qui portent toutes les conditions. Y écrire à la main donnerait un manuel qui
## doit des points à personne.
var points := {}


## Le niveau atteint, **déduit** de l'expérience à chaque appel. Jamais retenu :
## deux vérités sur le même nombre, et c'est le rechargement qui choisit.
func niveau() -> int:
	return Progression.niveau_atteint(experience, XP_BASE, XP_PUISSANCE, NIVEAU_MAX)


## Ce qu'il reste à gagner avant le niveau suivant, et le coût de ce niveau —
## de quoi dessiner la barre du haut de la page sans la recalculer à l'écran.
func avancement() -> Vector2i:
	return Progression.avancement(experience, XP_BASE, XP_PUISSANCE, NIVEAU_MAX)


## **Un point par niveau, le premier compris.** Un livre tout juste ramassé a donc
## de quoi ouvrir une case : sans ça, sa page ne ferait rien du tout à la première
## ouverture, ce qui se lit comme une panne plutôt que comme une attente.
func points_gagnes() -> int:
	return niveau()


func points_restants() -> int:
	return points_gagnes() - points_places()


## Le seul chemin par lequel un manuel apprend. Appelé pour chaque manuel du
## râtelier à la mort d'un ennemi — jamais pour celui qui dort dans le sac.
func gagner_experience(montant: int) -> void:
	if montant > 0:
		experience += montant


func points_de(identifiant: String) -> int:
	return int(points.get(identifiant, 0))


## Le total placé, tous points confondus. Utile à la page et au test qui vérifie
## qu'un manuel n'a pas dépensé plus qu'il n'a gagné.
func points_places() -> int:
	var total := 0
	for id in points:
		total += int(points[id])
	return total


## Peut-on placer un point de plus là ? **Toutes les conditions sont ici**, pour
## les trois sortes de destination — une case, un passif, un nœud d'arbre — et
## l'appelant n'en vérifie aucune de son côté : une interface qui refait le test
## finit par en oublier un, et c'est le clic qui donne le point de trop.
##
## L'archétype est passé en argument plutôt que retenu : un manuel est l'état
## d'un exemplaire, il ne connaît pas le livre dont il vient — c'est l'objet qui
## porte les deux.
func peut_investir(archetype: ManuelArchetype, identifiant: String) -> bool:
	return (
		points_restants() > 0
		and est_ouvert(archetype, identifiant)
		and points_de(identifiant) < _maximum(archetype, identifiant)
	)


## Les conditions **structurelles** : le niveau du livre pour une case ou un
## passif, les points de la compétence et l'état du parent pour un nœud. Ni le
## maximum, ni les points qui restent.
##
## Séparée de `peut_investir()` pour la page, qui doit distinguer « verrouillé »
## de « ouvert, mais tu n'as plus de point à placer » — deux états qu'un joueur
## ne lit pas de la même façon. Le distinguer dans le dessin aurait recopié la
## règle là où elle finit par diverger.
func est_ouvert(archetype: ManuelArchetype, identifiant: String) -> bool:
	if archetype == null:
		return false
	var case := archetype.case_de(identifiant)
	if case != null:
		return niveau() >= case.niveau_requis()
	var passif := archetype.passif_de(identifiant)
	if passif != null:
		return niveau() >= passif.niveau_de_manuel_requis
	return _noeud_ouvert(archetype, identifiant)


## Un nœud s'ouvre sur les points de **sa compétence**, pas sur le niveau du
## livre : un arbre s'achète après le sort, jamais à sa place. Et son parent doit
## porter au moins un point — un nœud accroché à un nœud éteint s'ouvrirait sans
## que le lien dessiné veuille dire quoi que ce soit.
func _noeud_ouvert(archetype: ManuelArchetype, id_noeud: String) -> bool:
	var noeud := archetype.noeud_de(id_noeud)
	if noeud == null:
		return false
	var case := archetype.case_du_noeud(id_noeud)
	if case == null or case.competence == null:
		return false
	if points_de(case.competence.id) < noeud.points_requis:
		return false
	return noeud.parent.is_empty() or points_de(noeud.parent) > 0


## Combien de points cet identifiant accepte, quelle que soit sa sorte. Zéro pour
## ce que le livre ne connaît pas, ce qui suffit à tout refuser.
func _maximum(archetype: ManuelArchetype, identifiant: String) -> int:
	var case := archetype.case_de(identifiant)
	if case != null:
		return case.points_max()
	var passif := archetype.passif_de(identifiant)
	if passif != null:
		return passif.points_max
	var noeud := archetype.noeud_de(identifiant)
	return noeud.points_max if noeud != null else 0


## Place un point et dit si c'est fait.
func investir(archetype: ManuelArchetype, identifiant: String) -> bool:
	if not peut_investir(archetype, identifiant):
		return false
	points[identifiant] = points_de(identifiant) + 1
	return true


## Peut-on reprendre un point ? **Seulement dans un nœud d'arbre.**
##
## Une case et un passif décident de ce qu'un personnage *sait* : les défaire,
## c'est la répartition qu'on refait avant chaque paquet d'ennemis, refusée au
## jalon 3 pour les attributs. Un arbre décide de ce qu'une compétence *fait* —
## essayer une conversion et revenir est la façon dont on la comprend, et un
## joueur qui ne peut pas revenir ne l'essaie pas.
##
## Le seul refus : un nœud dont un enfant porte encore des points, qui laisserait
## la branche accrochée à un nœud vide.
func peut_reprendre(archetype: ManuelArchetype, identifiant: String) -> bool:
	if archetype == null or points_de(identifiant) <= 0:
		return false
	if archetype.noeud_de(identifiant) == null:
		return false
	var case := archetype.case_du_noeud(identifiant)
	if case == null:
		return false
	for enfant in case.enfants_de(identifiant):
		if points_de(enfant.id) > 0:
			return false
	return true


## Rend le point **au livre**, jamais au personnage : il se replace ailleurs dans
## le même manuel, et pas dans un autre.
##
## L'entrée est effacée à zéro plutôt que laissée à zéro : c'est ce que la
## sauvegarde écrit, et un fichier qui liste des nœuds vides se lit mal.
func reprendre(archetype: ManuelArchetype, identifiant: String) -> bool:
	if not peut_reprendre(archetype, identifiant):
		return false
	var restant := points_de(identifiant) - 1
	if restant <= 0:
		points.erase(identifiant)
	else:
		points[identifiant] = restant
	return true


## Les nœuds de cette compétence où l'on a placé au moins un point, avec leurs
## points. C'est ce que la résolution d'un lancer consomme, et elle n'a pas à
## savoir qu'un nœud vide existe.
func talents_investis(archetype: ManuelArchetype, id_competence: String) -> Array[TalentInvesti]:
	var out: Array[TalentInvesti] = []
	if archetype == null:
		return out
	var case := archetype.case_de(id_competence)
	if case == null:
		return out
	for noeud in case.talents:
		var places := points_de(noeud.id)
		if places > 0:
			out.append(TalentInvesti.new(noeud, places))
	return out


## Ce que les passifs de ce livre donnent, dans la forme qu'un objet porté donne
## déjà : c'est le même tri qui les range ensuite entre la fiche et les
## compétences, et donc la même règle qui les empêche de compter deux fois.
func mods_de_passifs(archetype: ManuelArchetype) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if archetype == null:
		return out
	for passif in archetype.passifs():
		out.append_array(passif.mods(points_de(passif.id)))
	return out
