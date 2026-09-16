extends GutTest

## Le pont entre le personnage sauvegardé et le corps qui le joue : `load_character`
## et `fill`. Il a besoin de l'arbre — le sprite, la hurtbox et les barres
## n'existent qu'une fois le joueur dans une scène.

var _p: Player
var _created: PackedStringArray


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_created = PackedStringArray()
	await wait_physics_frames(1)


func after_each() -> void:
	for id in _created:
		SaveStore.delete(id)
	Game.character = null


func _played_character() -> Character:
	var p := Character.create_new("Revenante", 2)
	p.level = 5
	p.experience = 33
	p.unspent_points = 4
	p.attributes["strength"] = 7
	p.bag.place(Item.new(ItemCatalog.by_id("sword"), [
		StatMod.ranged("damage_physical", 3.0, 7.0, Keywords.ATTACK),
	] as Array[StatMod]), Vector2i(4, 1))
	p.equipment["chest"] = Item.new(ItemCatalog.by_id("breastplate"))
	return p


## **Le test qui garantit que la version 5 ne fait perdre de force à personne** :
## un personnage relu d'une version 4 frappe, en moyenne, exactement comme avant
## la mise à jour.
##
## Les nombres ont été **mesurés** sur l'ancien calcul, le 11 septembre 2026,
## juste avant qu'il ne disparaisse : ce sont des points de comparaison, pas des
## réglages. On compare le milieu de chaque fourchette, parce que les implicites
## devenus fourchettes ont gardé leur moyenne et non leur valeur.
func test_a_character_reread_from_version_4_hits_as_before() -> void:
	var dict := Character.create_new("Ancienne", 0).to_dict()
	dict["version"] = 4
	dict["attributes"]["strength"] = 4
	dict["attributes"]["intelligence"] = 9
	dict["equipment"] = {
		"weapon": {"base": "sword", "level": 10, "affixes": [
			{"stat": "attack_damage", "mode": 0, "value": 6.0, "affix": "sharp", "tier": 7},
		]},
		"offhand": {"base": "grimoire", "level": 10, "affixes": [
			{"stat": "spell_damage", "mode": 0, "value": 5.0, "affix": "arcane", "tier": 6},
		]},
	}
	_p.load_character(Character.from_dict(JSON.parse_string(JSON.stringify(dict))))

	# Trois points dans chaque compétence, un dans l'Attaque et le Trait : leur table
	# n'en a qu'un. Au-delà, les niveaux en bonus la prolongent depuis le jalon 14,
	# alors que la mesure prenait sa dernière valeur.
	var measurements := {
		SkillCatalog.ID_ATTACK: 24.8,
		SkillCatalog.ID_BOLT: 17.0,
		"swift_bolt": 77.44,
		"lightning_nova": 65.12,
	}
	for id in measurements:
		var c := SkillCatalog.by_id(id)
		# Les sorts ont été mesurés avec 4 % par point d'intelligence de la fiche, retirés
		# le 15 septembre 2026 : ce retrait n'est pas la migration, qui se juge sans lui.
		var expected := float(measurements[id])
		if not SkillCatalog.is_starting(id):
			expected /= 1.0 + 0.04 * _p.stats.intelligence
		var cast := _p.resolve(c, mini(3, c.points_max()))
		assert_almost_eq(
			(cast.total_min() + cast.total_max()) * 0.5, expected, 0.001, "« %s »" % c.name
		)


func test_loading_sets_the_progression() -> void:
	_p.load_character(_played_character())
	assert_eq(_p.level, 5)
	assert_eq(_p.xp, 33)
	assert_eq(_p.unspent_points, 4)
	assert_eq(_p.allocated["strength"], 7)
	assert_eq(_p.xp_to_next, _p._needed_for(5), "le palier suit le niveau chargé")


## La force chargée doit être **dans la fiche**, pas seulement dans le compteur
## de points : c'est recompute_stats qui en dérive les PV, et l'oublier donnerait
## un personnage de niveau 5 avec les points de vie d'un débutant.
func test_loading_recomputes_the_sheet() -> void:
	var bare := _p.stats.max_health
	_p.load_character(_played_character())
	# La fiche porte le **total** : la force de la fiche de départ plus les points
	# placés. C'est la répartition seule qui est sauvegardée, pas ce total.
	assert_eq(
		_p.stats.strength, _p.base_stats.strength + 7.0,
		"la force de départ plus les sept points placés"
	)
	# 7 points de force et un plastron : les deux doivent se voir.
	assert_gt(_p.stats.max_health, bare, "les PV ont suivi")
	assert_eq(_p.health, _p.stats.max_health, "et on reprend en pleine santé")


func test_loading_fills_the_bag_in_the_right_place() -> void:
	_p.load_character(_played_character())
	assert_eq(_p.inventory.placed.size(), 1)
	assert_ne(_p.inventory.index_at(Vector2i(4, 1)), Inventory.EMPTY, "à sa case")
	assert_eq(_p.inventory.placed[0].data.explicits.size(), 1, "avec son affixe")


## Le panneau d'inventaire garde une référence sur l'objet Inventory depuis son
## bind. Le remplacer au chargement lui laisserait un sac fantôme.
func test_loading_does_not_replace_the_bag_object() -> void:
	var before := _p.inventory
	_p.load_character(_played_character())
	assert_eq(_p.inventory, before, "le même sac, rempli autrement")


func test_loading_equips_and_changes_the_silhouette() -> void:
	_p.load_character(_played_character())
	assert_eq(_p.equipped("chest").base.id, "breastplate")
	assert_eq(_p.sprite.current_variant(), 2, "la silhouette choisie à la création")


## Un emplacement que le joueur ne sait pas porter est écarté au lieu d'entrer
## dans l'équipement, où il fausserait le calcul sans jamais s'afficher.
func test_an_unknown_slot_is_not_worn() -> void:
	var p := _played_character()
	p.equipment["cape"] = Item.new(ItemCatalog.by_id("sword"))
	_p.load_character(p)
	assert_false(_p.equipment.has("cape"))
	assert_eq(_p.equipment.size(), 1, "le plastron seul")


func test_fill_returns_what_the_player_has_become() -> void:
	var p := _played_character()
	_p.load_character(p)
	_p.gain_xp(2000)
	_p.spend_point("dexterity")
	_p.pick_up(Item.new(ItemCatalog.by_id("wand")))

	var after := Character.create_new("empty", 0)
	_p.fill(after)
	assert_eq(after.level, _p.level, "le niveau gagné")
	assert_eq(after.experience, _p.xp)
	assert_eq(after.unspent_points, _p.unspent_points)
	assert_eq(after.attributes["dexterity"], 1, "le point placé")
	assert_eq(after.attributes["strength"], 7, "et ceux d'avant")
	assert_eq(after.bag.placed.size(), 2, "l'épée chargée plus la baguette ramassée")
	assert_eq(after.silhouette, 2)


## Rien de calculé ne doit repartir sur le disque : les statistiques se
## reconstruisent, et les écrire créerait une seconde vérité.
func test_fill_writes_no_stat() -> void:
	var p := _played_character()
	_p.load_character(p)
	_p.fill(p)
	var dict := p.to_dict()
	assert_false(dict.has("stats"))
	assert_false(dict.has("max_health"))

	# Les champs attendus, nommés plutôt que comptés : un total seul annonce
	# qu'il y en a un de trop sans dire lequel, et c'est le moment où on aimerait
	# le savoir. Ajouter une ligne ici doit rester un geste délibéré.
	var expected_all := [
		"version", "id", "name", "silhouette", "created_on", "played_on",
		"level", "experience", "attributes", "unspent_points",
		"bag", "equipment",
		# Jalon 6 : ce qu'on étudie, ce qu'on a sous les doigts, et si le livre de
		# départ a déjà été donné.
		"rack", "bar", "manual_given",
	]
	for key in expected_all:
		assert_true(dict.has(key), "le champ « %s » a disparu du fichier" % key)
	assert_eq(dict.size(), expected_all.size(), "et pas un champ de plus")


## Le tour complet, sans passer par le disque : jouer, remplir, sérialiser,
## relire, recharger dans un corps neuf.
func test_the_full_loop_keeps_the_character() -> void:
	var p := _played_character()
	_p.load_character(p)
	_p.gain_xp(500)
	_p.fill(p)

	var reread := Character.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	var body: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(body)
	await wait_physics_frames(1)
	body.load_character(reread)

	assert_eq(body.level, _p.level)
	assert_eq(body.xp, _p.xp)
	assert_eq(body.stats.max_health, _p.stats.max_health, "la même fiche recalculée")
	assert_eq(body.inventory.placed.size(), _p.inventory.placed.size())
	assert_eq(body.equipped("chest").base.id, "breastplate")
