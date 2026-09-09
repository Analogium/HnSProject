class_name Manuel
extends RefCounted

## Ce qu'un exemplaire de manuel a appris : son expérience, et les points placés
## dans ses cases. **Un par manuel ramassé.**
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
## `Competence.degats()` reçoit la fiche. Une référence en retour serait un
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

## Vingt niveaux, donc vingt points : de quoi remplir les quatre cases d'un
## archétype à cinq points chacune, et pas une de plus. Un manuel qu'on finit est
## un manuel qu'on remplace ; c'est ce plafond qui rend le suivant intéressant.
const NIVEAU_MAX := 20

## L'expérience **totale** accumulée par ce livre. Totale et non « depuis le
## dernier niveau » : c'est elle qu'on écrit, et le niveau s'en déduit.
var experience := 0

## Points placés, par identifiant de compétence. Les identifiants partent sur le
## disque : ils ne se renomment jamais (invariant 1).
##
## En lecture seule de fait : on y entre par `investir()`, qui porte les quatre
## conditions. Y écrire à la main donnerait un manuel qui doit des points à
## personne.
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


func points_de(id_competence: String) -> int:
	return int(points.get(id_competence, 0))


## Le total placé, tous points confondus. Utile à la page et au test qui vérifie
## qu'un manuel n'a pas dépensé plus qu'il n'a gagné.
func points_places() -> int:
	var total := 0
	for id in points:
		total += int(points[id])
	return total


## Peut-on placer un point de plus dans cette case ? Quatre conditions, et
## l'appelant n'a aucune à vérifier de son côté : une interface qui refait le
## test finit par en oublier un, et c'est le clic qui donne le point de trop.
##
## L'archétype est passé en argument plutôt que retenu : un manuel est l'état
## d'un exemplaire, il ne connaît pas le livre dont il vient — c'est l'objet qui
## porte les deux.
func peut_investir(archetype: ManuelArchetype, id_competence: String) -> bool:
	if archetype == null:
		return false
	var case := archetype.case_de(id_competence)
	if case == null or case.competence == null:
		return false
	if niveau() < case.competence.niveau_de_manuel_requis:
		return false
	if points_de(id_competence) >= case.competence.points_max():
		return false
	return points_restants() > 0


## Place un point et dit si c'est fait. **Sans retour en arrière**, comme les
## points d'attribut du jalon 3 et pour la même raison : une répartition qu'on
## peut défaire n'est plus un choix, c'est un réglage, et rien n'empêcherait de
## refaire son manuel avant chaque paquet d'ennemis.
func investir(archetype: ManuelArchetype, id_competence: String) -> bool:
	if not peut_investir(archetype, id_competence):
		return false
	points[id_competence] = points_de(id_competence) + 1
	return true
