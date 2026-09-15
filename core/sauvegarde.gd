class_name Sauvegarde

## Un fichier JSON par personnage dans `user://personnages/` : supprimer est un
## `remove()`, une corruption ne coûte qu'un personnage.

const DOSSIER := "user://personnages"
const EXTENSION := ".json"
## Le suffixe d'écriture avant renommage ; un `.tmp` qui traîne n'est pas un
## personnage.
const TEMPORAIRE := ".tmp"


static func chemin(id: String) -> String:
	return "%s/%s%s" % [DOSSIER, id, EXTENSION]


static func existe(id: String) -> bool:
	return FileAccess.file_exists(chemin(id))


## Temporaires ignorés ; dossier absent, liste vide (premier lancement).
static func ids() -> PackedStringArray:
	var trouves := PackedStringArray()
	var dossier := DirAccess.open(DOSSIER)
	if dossier == null:
		return trouves
	for fichier in dossier.get_files():
		# Un `.json.tmp` ne finit pas par `.json` : le reste d'une écriture
		# coupée est écarté par ce seul test.
		if fichier.ends_with(EXTENSION):
			trouves.append(fichier.trim_suffix(EXTENSION))
	return trouves


## Le plus récemment joué en tête. Un fichier illisible **reste dans la liste**,
## marqué : son fichier est intact.
static func lister() -> Array[Personnage]:
	var tous: Array[Personnage] = []
	for id in ids():
		var p := lire(id)
		tous.append(p if p != null else Personnage.illisible_avec(id))
	tous.sort_custom(func(a: Personnage, b: Personnage) -> bool: return a.joue_le > b.joue_le)
	return tous


## Null pour un fichier absent, tronqué ou de version inconnue ; jamais d'exception.
static func lire(id: String) -> Personnage:
	var fichier := FileAccess.open(chemin(id), FileAccess.READ)
	if fichier == null:
		return null
	var texte := fichier.get_as_text()
	fichier.close()

	# Une instance de JSON : la fonction statique journalise une erreur moteur sur un
	# fichier abîmé, cas attendu ici.
	var lecteur := JSON.new()
	if lecteur.parse(texte) != OK:
		push_warning("Sauvegarde « %s » illisible : %s, ligne %d." % [
			id, lecteur.get_error_message(), lecteur.get_error_line()
		])
		return null
	if not lecteur.data is Dictionary:
		push_warning("Sauvegarde « %s » illisible : ce n'est pas un objet JSON." % id)
		return null
	return Personnage.depuis_dict(lecteur.data)


## Écrit et **date du jour** : sauvegarder, c'est avoir joué. En deux temps, un `.tmp`
## fermé puis renommé, pour qu'une coupure ne laisse jamais un fichier tronqué.
static func ecrire(personnage: Personnage) -> bool:
	if personnage == null or personnage.id.is_empty() or personnage.illisible:
		return false
	if DirAccess.make_dir_recursive_absolute(DOSSIER) != OK:
		push_error("Impossible de créer %s" % DOSSIER)
		return false

	personnage.joue_le = Time.get_date_string_from_system()

	var provisoire := chemin(personnage.id) + TEMPORAIRE
	var fichier := FileAccess.open(provisoire, FileAccess.WRITE)
	if fichier == null:
		push_error("Écriture impossible : %s" % provisoire)
		return false
	# Indenté : se diagnostique à l'œil.
	fichier.store_string(JSON.stringify(personnage.vers_dict(), "\t"))
	fichier.close()

	var dossier := DirAccess.open(DOSSIER)
	if dossier == null:
		return false
	if dossier.rename(provisoire.get_file(), chemin(personnage.id).get_file()) != OK:
		push_error("Renommage impossible : %s" % provisoire)
		dossier.remove(provisoire.get_file())
		return false
	return true


## Identifiant retiré jusqu'à en trouver un libre : une collision écraserait un
## personnage.
static func creer(nom: String, silhouette: int) -> Personnage:
	var personnage := Personnage.nouveau(nom, silhouette)
	var essais := 0
	while existe(personnage.id) and essais < 100:
		personnage.id = Personnage.nouvel_id()
		essais += 1
	return personnage if ecrire(personnage) else null


## Irréversible, et c'est voulu : c'est à l'interface de demander confirmation.
static func supprimer(id: String) -> bool:
	var dossier := DirAccess.open(DOSSIER)
	if dossier == null:
		return false
	return dossier.remove(id + EXTENSION) == OK
