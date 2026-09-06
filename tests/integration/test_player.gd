extends GutTest

## Le joueur monté dans l'arbre : réserve de mana, régénérations, équipement et
## recalcul de la fiche. Rien de tout ça n'existe hors scène.

var _p: Player


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	# Un parent dédié pour les tirs : sans lui ils naissent sous le script de
	# test et y restent après coup, ce que GUT signale en enfants non libérés.
	var tirs := Node2D.new()
	add_child_autofree(tirs)
	_p.projectile_parent = tirs
	await wait_physics_frames(1)


func test_reserve_pleine_a_la_naissance() -> void:
	assert_eq(_p.mana, 50.0)
	assert_eq(_p.stats.max_mana, 50.0)
	assert_eq(_p.health, _p.stats.max_health)


func test_le_tir_coute_du_mana() -> void:
	_p._shoot()
	assert_eq(_p.mana, 44.0, "6 par tir")


func test_reserve_insuffisante_refuse_le_tir() -> void:
	_p._set_mana(2.0)
	_p._shoot()
	assert_eq(_p.mana, 2.0, "ni tir, ni prélèvement partiel")


func test_regenerations() -> void:
	_p._set_mana(10.0)
	_p._regen(1.0)
	assert_eq(_p.mana, 14.0, "4 de mana par seconde")
	_p._set_health(50.0)
	_p._regen(1.0)
	assert_eq(_p.health, 51.0, "1 PV par seconde")


func test_la_regeneration_ne_depasse_pas_le_plafond() -> void:
	_p._regen(10.0)
	assert_eq(_p.health, _p.stats.max_health)
	assert_eq(_p.mana, _p.stats.max_mana)


## La hurtbox reçoit la fiche courante, pas une copie périmée : recompute_stats
## en fabrique une neuve à chaque équipement.
func test_la_hurtbox_suit_la_fiche() -> void:
	assert_eq(_p.hurtbox.stats, _p.stats, "à la naissance")
	_p.equip(Item.new(load("res://resources/items/plastron.tres")))
	assert_eq(_p.hurtbox.stats, _p.stats, "après un équipement")
	_p.unequip("chest")
	assert_eq(_p.hurtbox.stats, _p.stats, "après un retrait")


func test_la_baguette_accelere_l_incantation_pas_la_lame() -> void:
	var recharge := _p.stats.attack_cooldown
	_p.equip(Item.new(load("res://resources/items/baguette.tres")))
	assert_almost_eq(_p.stats.cast_speed, 1.15, 0.001, "+15 % d'incantation")
	assert_eq(_p.stats.attack_cooldown, recharge, "le corps à corps est intact")


## Le cœur du système d'équipement : un objet retiré ne laisse rien derrière lui,
## parce que recompute_stats repart toujours de la ressource du disque.
func test_un_objet_retire_ne_laisse_rien() -> void:
	var mod := StatMod.new("armor", StatMod.Mode.FLAT, 40.0)
	_p.equip(Item.new(load("res://resources/items/plastron.tres"), [mod]))
	assert_eq(_p.stats.armor, 40.0)
	_p.unequip("chest")
	assert_eq(_p.stats.armor, 0.0)
	assert_eq(_p.stats.max_health, 100.0, "l'implicite est parti aussi")


## Retirer un plastron baisse le plafond : la vie courante doit le suivre, sinon
## la barre déborde et le joueur garde des PV qu'il n'a plus.
func test_les_pv_repassent_sous_le_nouveau_plafond() -> void:
	_p.equip(Item.new(load("res://resources/items/plastron.tres")))
	_p._set_health(120.0)
	_p.unequip("chest")
	assert_eq(_p.health, 100.0)


## La ressource du disque n'est jamais écrite : aucun .tres du projet n'est
## resource_local_to_scene, l'y toucher contaminerait toutes les parties.
func test_la_fiche_du_disque_reste_intacte() -> void:
	_p.equip(Item.new(
		load("res://resources/items/plastron.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 50.0)]
	))
	var disque: CharacterStats = load("res://resources/stats/player_stats.tres")
	assert_eq(disque.max_health, 100.0, "le fichier n'a pas bougé")
	assert_ne(_p.stats, disque, "la copie de travail est distincte")


func test_le_sac_plein_laisse_l_objet_au_sol() -> void:
	var plastron: ItemBase = load("res://resources/items/plastron.tres")
	while _p.inventory.add(Item.new(plastron)):
		pass
	assert_false(_p.pick_up(Item.new(plastron)), "refusé, donc il reste au sol")
