extends GutTest

## Le pont entre le personnage sauvegardé et le corps qui le joue : `charger`
## et `remplir`. Il a besoin de l'arbre — le sprite, la hurtbox et les barres
## n'existent qu'une fois le joueur dans une scène.

var _p: Player
var _crees: PackedStringArray


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_crees = PackedStringArray()
	await wait_physics_frames(1)


func after_each() -> void:
	for id in _crees:
		Sauvegarde.supprimer(id)
	Game.personnage = null


func _personnage_joue() -> Personnage:
	var p := Personnage.nouveau("Revenante", 2)
	p.niveau = 5
	p.experience = 33
	p.points_a_placer = 4
	p.attributs["strength"] = 7
	p.sac.place(Item.new(ItemCatalog.by_id("epee"), [
		StatMod.new("attack_damage", StatMod.Mode.FLAT, 5.0),
	] as Array[StatMod]), Vector2i(4, 1))
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"))
	return p


func test_charger_pose_la_progression() -> void:
	_p.charger(_personnage_joue())
	assert_eq(_p.level, 5)
	assert_eq(_p.xp, 33)
	assert_eq(_p.unspent_points, 4)
	assert_eq(_p.allocated["strength"], 7)
	assert_eq(_p.xp_to_next, _p._needed_for(5), "le palier suit le niveau chargé")


## La force chargée doit être **dans la fiche**, pas seulement dans le compteur
## de points : c'est recompute_stats qui en dérive les PV, et l'oublier donnerait
## un personnage de niveau 5 avec les points de vie d'un débutant.
func test_charger_recalcule_la_fiche() -> void:
	var nu := _p.stats.max_health
	_p.charger(_personnage_joue())
	# La fiche porte le **total** : la force de la fiche de départ plus les points
	# placés. C'est la répartition seule qui est sauvegardée, pas ce total.
	assert_eq(
		_p.stats.strength, _p.base_stats.strength + 7.0,
		"la force de départ plus les sept points placés"
	)
	# 7 points de force et un plastron : les deux doivent se voir.
	assert_gt(_p.stats.max_health, nu, "les PV ont suivi")
	assert_eq(_p.health, _p.stats.max_health, "et on reprend en pleine santé")


func test_charger_remplit_le_sac_a_la_bonne_place() -> void:
	_p.charger(_personnage_joue())
	assert_eq(_p.inventory.placed.size(), 1)
	assert_ne(_p.inventory.index_at(Vector2i(4, 1)), Inventory.EMPTY, "à sa case")
	assert_eq(_p.inventory.placed[0].data.explicits.size(), 1, "avec son affixe")


## Le panneau d'inventaire garde une référence sur l'objet Inventory depuis son
## bind. Le remplacer au chargement lui laisserait un sac fantôme.
func test_charger_ne_remplace_pas_l_objet_sac() -> void:
	var avant := _p.inventory
	_p.charger(_personnage_joue())
	assert_eq(_p.inventory, avant, "le même sac, rempli autrement")


func test_charger_equipe_et_change_la_silhouette() -> void:
	_p.charger(_personnage_joue())
	assert_eq(_p.equipped("chest").base.id, "plastron")
	assert_eq(_p.sprite.current_variant(), 2, "la silhouette choisie à la création")


## Un emplacement que le joueur ne sait pas porter est écarté au lieu d'entrer
## dans l'équipement, où il fausserait le calcul sans jamais s'afficher.
func test_un_emplacement_inconnu_n_est_pas_porte() -> void:
	var p := _personnage_joue()
	p.equipement["cape"] = Item.new(ItemCatalog.by_id("epee"))
	_p.charger(p)
	assert_false(_p.equipment.has("cape"))
	assert_eq(_p.equipment.size(), 1, "le plastron seul")


func test_remplir_rend_ce_que_le_joueur_est_devenu() -> void:
	var p := _personnage_joue()
	_p.charger(p)
	_p.gain_xp(2000)
	_p.spend_point("dexterity")
	_p.pick_up(Item.new(ItemCatalog.by_id("baguette")))

	var apres := Personnage.nouveau("vide", 0)
	_p.remplir(apres)
	assert_eq(apres.niveau, _p.level, "le niveau gagné")
	assert_eq(apres.experience, _p.xp)
	assert_eq(apres.points_a_placer, _p.unspent_points)
	assert_eq(apres.attributs["dexterity"], 1, "le point placé")
	assert_eq(apres.attributs["strength"], 7, "et ceux d'avant")
	assert_eq(apres.sac.placed.size(), 2, "l'épée chargée plus la baguette ramassée")
	assert_eq(apres.silhouette, 2)


## Rien de calculé ne doit repartir sur le disque : les statistiques se
## reconstruisent, et les écrire créerait une seconde vérité.
func test_remplir_n_ecrit_aucune_statistique() -> void:
	var p := _personnage_joue()
	_p.charger(p)
	_p.remplir(p)
	var dict := p.vers_dict()
	assert_false(dict.has("stats"))
	assert_false(dict.has("max_health"))
	assert_eq(dict.size(), 12, "douze champs, ni plus ni moins")


## Le tour complet, sans passer par le disque : jouer, remplir, sérialiser,
## relire, recharger dans un corps neuf.
func test_le_tour_complet_conserve_le_personnage() -> void:
	var p := _personnage_joue()
	_p.charger(p)
	_p.gain_xp(500)
	_p.remplir(p)

	var relu := Personnage.depuis_dict(JSON.parse_string(JSON.stringify(p.vers_dict())))
	var corps: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(corps)
	await wait_physics_frames(1)
	corps.charger(relu)

	assert_eq(corps.level, _p.level)
	assert_eq(corps.xp, _p.xp)
	assert_eq(corps.stats.max_health, _p.stats.max_health, "la même fiche recalculée")
	assert_eq(corps.inventory.placed.size(), _p.inventory.placed.size())
	assert_eq(corps.equipped("chest").base.id, "plastron")
