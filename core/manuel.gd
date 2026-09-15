class_name Manuel
extends RefCounted

## Ce qu'un exemplaire de manuel a appris : son expérience et ses points placés. Son
## niveau se déduit, jamais retenu. RefCounted comme `Item` ; il ne connaît pas son
## archétype, que les règles reçoivent en argument.

## La courbe du manuel. Premier réglage : un livre neuf monte d'un niveau en une
## poignée d'ennemis, de trois en une zone.
const XP_BASE := 90.0
const XP_PUISSANCE := 1.25

## Vingt niveaux, vingt points, pour bien plus de destinations : le plafond fait du
## livre un choix plutôt qu'une collection.
const NIVEAU_MAX := 20

## L'expérience **totale** : c'est elle qu'on écrit.
var experience := 0

## Points placés par identifiant : cases, passifs et nœuds partagent ce dictionnaire
## et ne doivent jamais se confondre (invariant 1). On y entre par `investir()` et
## `reprendre()`, qui portent les conditions.
var points := {}


## Déduit à chaque appel, jamais retenu.
func niveau() -> int:
	return Progression.niveau_atteint(experience, XP_BASE, XP_PUISSANCE, NIVEAU_MAX)


## Ce qu'il reste avant le niveau suivant, et le coût de ce niveau.
func avancement() -> Vector2i:
	return Progression.avancement(experience, XP_BASE, XP_PUISSANCE, NIVEAU_MAX)


## Un point par niveau, le premier compris : un livre neuf ouvre une case.
func points_gagnes() -> int:
	return niveau()


func points_restants() -> int:
	return points_gagnes() - points_places()


## Le seul chemin : les manuels du râtelier, à chaque récompense.
func gagner_experience(montant: int) -> void:
	if montant > 0:
		experience += montant


func points_de(identifiant: String) -> int:
	return int(points.get(identifiant, 0))


## Tous points confondus.
func points_places() -> int:
	var total := 0
	for id in points:
		total += int(points[id])
	return total


## **Toutes les conditions sont ici**, pour les trois sortes de destination :
## l'interface n'en vérifie aucune.
func peut_investir(archetype: ManuelArchetype, identifiant: String) -> bool:
	return (
		points_restants() > 0
		and est_ouvert(archetype, identifiant)
		and points_de(identifiant) < _maximum(archetype, identifiant)
	)


## Les conditions **structurelles** seules : la page distingue « verrouillé » de
## « plus de point à placer ».
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


## Sur les points de sa compétence, et son parent doit en porter un.
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


## Zéro pour ce que le livre ne connaît pas.
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


## Un point se reprend partout (décidé le 14 septembre 2026), sauf un nœud dont un
## enfant porte des points, et une compétence qui passerait sous les points qu'un de
## ses nœuds investis demande.
func peut_reprendre(archetype: ManuelArchetype, identifiant: String) -> bool:
	if archetype == null or points_de(identifiant) <= 0:
		return false
	if archetype.passif_de(identifiant) != null:
		return true
	var case := archetype.case_de(identifiant)
	if case != null:
		for noeud in case.talents:
			if points_de(noeud.id) > 0 and points_de(identifiant) - 1 < noeud.points_requis:
				return false
		return true
	if archetype.noeud_de(identifiant) == null:
		return false
	var case_du_noeud := archetype.case_du_noeud(identifiant)
	if case_du_noeud == null:
		return false
	for enfant in case_du_noeud.enfants_de(identifiant):
		if points_de(enfant.id) > 0:
			return false
	return true


## Rend le point **au livre** ; l'entrée est effacée à zéro, comme l'écrit la
## sauvegarde.
func reprendre(archetype: ManuelArchetype, identifiant: String) -> bool:
	if not peut_reprendre(archetype, identifiant):
		return false
	var restant := points_de(identifiant) - 1
	if restant <= 0:
		points.erase(identifiant)
	else:
		points[identifiant] = restant
	return true


## Les nœuds investis de cette compétence, avec leurs points.
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


## Dans la forme d'un objet porté : le même tri les range ensuite.
func mods_de_passifs(archetype: ManuelArchetype) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if archetype == null:
		return out
	for passif in archetype.passifs():
		out.append_array(passif.mods(points_de(passif.id)))
	return out
