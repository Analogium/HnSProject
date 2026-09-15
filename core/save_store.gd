class_name SaveStore

## Un fichier JSON par personnage dans `user://characters/` : supprimer est un
## `remove()`, une corruption ne coûte qu'un personnage.

const FOLDER := "user://characters"
const EXTENSION := ".json"
## Le suffixe d'écriture avant renommage ; un `.tmp` qui traîne n'est pas un
## personnage.
const TEMPORARY := ".tmp"


static func path(id: String) -> String:
	return "%s/%s%s" % [FOLDER, id, EXTENSION]


static func exists(id: String) -> bool:
	return FileAccess.file_exists(path(id))


## Temporaires ignorés ; dossier absent, liste vide (premier lancement).
static func ids() -> PackedStringArray:
	LegacyFrench.move_save_folder(FOLDER)
	var found := PackedStringArray()
	var folder := DirAccess.open(FOLDER)
	if folder == null:
		return found
	for file in folder.get_files():
		# Un `.json.tmp` ne finit pas par `.json` : le reste d'une écriture
		# coupée est écarté par ce seul test.
		if file.ends_with(EXTENSION):
			found.append(file.trim_suffix(EXTENSION))
	return found


## Le plus récemment joué en tête. Un fichier illisible **reste dans la liste**,
## marqué : son fichier est intact.
static func list_all() -> Array[Character]:
	var characters: Array[Character] = []
	for id in ids():
		var p := read(id)
		characters.append(p if p != null else Character.unreadable_with(id))
	characters.sort_custom(func(a: Character, b: Character) -> bool: return a.played_on > b.played_on)
	return characters


## Null pour un fichier absent, tronqué ou de version inconnue ; jamais d'exception.
static func read(id: String) -> Character:
	LegacyFrench.move_save_folder(FOLDER)
	var file := FileAccess.open(path(id), FileAccess.READ)
	if file == null:
		return null
	var text_value := file.get_as_text()
	file.close()

	# Une instance de JSON : la fonction statique journalise une erreur moteur sur un
	# fichier abîmé, cas attendu ici.
	var reader := JSON.new()
	if reader.parse(text_value) != OK:
		push_warning("Sauvegarde « %s » illisible : %s, ligne %d." % [
			id, reader.get_error_message(), reader.get_error_line()
		])
		return null
	if not reader.data is Dictionary:
		push_warning("Sauvegarde « %s » illisible : ce n'est pas un objet JSON." % id)
		return null
	return Character.from_dict(reader.data)


## Écrit et **date du jour** : sauvegarder, c'est avoir joué. En deux temps, un `.tmp`
## fermé puis renommé, pour qu'une coupure ne laisse jamais un fichier tronqué.
static func write(character: Character) -> bool:
	if character == null or character.id.is_empty() or character.unreadable:
		return false
	if DirAccess.make_dir_recursive_absolute(FOLDER) != OK:
		push_error("Impossible de créer %s" % FOLDER)
		return false

	character.played_on = Time.get_date_string_from_system()

	var temp_path := path(character.id) + TEMPORARY
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Écriture impossible : %s" % temp_path)
		return false
	# Indenté : se diagnostique à l'œil.
	file.store_string(JSON.stringify(character.to_dict(), "\t"))
	file.close()

	var folder := DirAccess.open(FOLDER)
	if folder == null:
		return false
	if folder.rename(temp_path.get_file(), path(character.id).get_file()) != OK:
		push_error("Renommage impossible : %s" % temp_path)
		folder.remove(temp_path.get_file())
		return false
	return true


## Identifiant retiré jusqu'à en trouver un libre : une collision écraserait un
## personnage.
static func create(name: String, silhouette: int) -> Character:
	var character := Character.create_new(name, silhouette)
	var attempts := 0
	while exists(character.id) and attempts < 100:
		character.id = Character.new_id()
		attempts += 1
	return character if write(character) else null


## Irréversible, et c'est voulu : c'est à l'interface de demander confirmation.
static func delete(id: String) -> bool:
	var folder := DirAccess.open(FOLDER)
	if folder == null:
		return false
	return folder.remove(id + EXTENSION) == OK
