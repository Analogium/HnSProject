class_name Sauvegarde

## Les personnages sur le disque : un fichier JSON par personnage, dans
## `user://personnages/`.
##
## Un fichier par personnage et non un fichier unique : supprimer devient un
## `remove()`, une sauvegarde corrompue ne coûte qu'un personnage, et deux
## écritures ne peuvent pas se marcher dessus.

const DOSSIER := "user://personnages"
const EXTENSION := ".json"
## L'écriture passe par ce suffixe avant d'être renommée. Il ne doit jamais
## apparaître dans une liste : un fichier temporaire qui traîne est le reste
## d'une coupure, pas un personnage.
const TEMPORAIRE := ".tmp"


static func chemin(id: String) -> String:
	return "%s/%s%s" % [DOSSIER, id, EXTENSION]


static func existe(id: String) -> bool:
	return FileAccess.file_exists(chemin(id))


## Les identifiants présents, dans l'ordre du système de fichiers. Les fichiers
## temporaires sont ignorés, et le dossier absent rend une liste vide plutôt
## qu'une erreur — c'est l'état normal au tout premier lancement.
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


## Tous les personnages, le plus récemment joué en tête — c'est celui qu'on
## vient reprendre neuf fois sur dix.
##
## Un fichier illisible **entre quand même dans la liste**, marqué comme tel. Le
## faire disparaître donnerait à croire que le personnage est perdu, alors que
## son fichier est toujours là et récupérable.
static func lister() -> Array[Personnage]:
	var tous: Array[Personnage] = []
	for id in ids():
		var p := lire(id)
		tous.append(p if p != null else Personnage.illisible_avec(id))
	tous.sort_custom(func(a: Personnage, b: Personnage) -> bool: return a.joue_le > b.joue_le)
	return tous


## Renvoie null pour un fichier absent, tronqué, ou d'une version qu'on ne sait
## pas lire. Jamais d'exception : l'écran de sélection doit survivre à n'importe
## quel contenu, y compris un fichier écrit à la main.
static func lire(id: String) -> Personnage:
	var fichier := FileAccess.open(chemin(id), FileAccess.READ)
	if fichier == null:
		return null
	var texte := fichier.get_as_text()
	fichier.close()

	# Une instance de JSON et non JSON.parse_string() : la fonction statique
	# journalise une erreur du **moteur** sur un fichier abîmé, alors que ce cas
	# est attendu ici. L'instance donne au passage la ligne fautive.
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


## Écrit le personnage, et **marque la date du jour** au passage : sauvegarder,
## c'est avoir joué. Ici et pas chez l'appelant, qui l'oublierait sur l'un des
## trois points de sauvegarde.
##
## Écriture en deux temps : un fichier temporaire, fermé, puis renommé sur le
## vrai. Une coupure laisse alors un `.tmp` inutile au lieu d'un personnage
## tronqué. Le renommage n'est pas atomique sous Windows, mais ce qu'on empêche
## c'est un fichier à moitié écrit portant le nom du personnage.
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
	# Indenté : une sauvegarde qu'on peut ouvrir dans un éditeur de texte se
	# diagnostique en dix secondes, et quelques kilo-octets ne coûtent rien.
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


## Crée un personnage et l'écrit tout de suite. L'identifiant est retiré jusqu'à
## en trouver un libre : une collision écraserait un personnage existant, et
## c'est la seule façon d'en perdre un sans l'avoir demandé.
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
