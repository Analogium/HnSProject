extends GutTest

## Le point de passage unique de tous les coups du jeu. Intégration et non
## unitaire : une Area2D hors de l'arbre n'a pas de global_position, et le
## retour visuel passe par un nœud.

var _recu := -1.0


func _frapper(st: CharacterStats, montant: float, nature: DamageType.Kind) -> float:
	var hb := Hurtbox.new()
	hb.stats = st
	add_child_autofree(hb)
	_recu = -1.0
	hb.damaged.connect(func(info: DamageInfo) -> void: _recu = info.amount)
	hb.take_damage(DamageInfo.new(montant, Vector2.ZERO, 0.0, false, nature))
	return _recu


func test_l_armure_coupe_le_physique() -> void:
	var st := CharacterStats.new()
	st.armor = 60.0
	assert_almost_eq(_frapper(st, 12.0, DamageType.Kind.PHYSICAL), 6.0, 0.001)


func test_la_resistance_coupe_son_element() -> void:
	var st := CharacterStats.new()
	st.res_fire = 50.0
	assert_almost_eq(_frapper(st, 20.0, DamageType.Kind.FIRE), 10.0, 0.001)
	assert_almost_eq(
		_frapper(st, 20.0, DamageType.Kind.COLD), 20.0, 0.001,
		"une résistance ne couvre pas les autres natures"
	)


## Conséquence voulue de la refonte : le tir élémentaire est le recours contre
## un ennemi blindé.
func test_l_armure_n_arrete_pas_les_elements() -> void:
	var st := CharacterStats.new()
	st.armor = 1000.0
	assert_almost_eq(_frapper(st, 20.0, DamageType.Kind.LIGHTNING), 20.0, 0.001)


func test_un_coup_passe_toujours() -> void:
	var st := CharacterStats.new()
	st.armor = 1000000.0
	assert_eq(_frapper(st, 2.0, DamageType.Kind.PHYSICAL), Hurtbox.MIN_DAMAGE)


## Le mannequin de mesure : sans fiche, on lit les dégâts bruts.
func test_sans_fiche_aucune_mitigation() -> void:
	var hb := Hurtbox.new()
	add_child_autofree(hb)
	_recu = -1.0
	hb.damaged.connect(func(info: DamageInfo) -> void: _recu = info.amount)
	hb.take_damage(DamageInfo.new(37.0, Vector2.ZERO))
	assert_eq(_recu, 37.0)


func test_invulnerable_n_emet_rien() -> void:
	var hb := Hurtbox.new()
	hb.invulnerable = true
	add_child_autofree(hb)
	_recu = -1.0
	hb.damaged.connect(func(info: DamageInfo) -> void: _recu = info.amount)
	hb.take_damage(DamageInfo.new(10.0, Vector2.ZERO))
	assert_eq(_recu, -1.0, "aucun signal")


## Sans ce garde-fou, chaque coup du jeu consommerait un tirage de Game.rng —
## et comme les graines de zone en sortent, se battre décalerait toutes les
## zones tirées ensuite.
func test_esquive_nulle_ne_consomme_pas_le_hasard() -> void:
	Game.rng.seed = 1234
	var avant := Game.rng.state
	_frapper(CharacterStats.new(), 10.0, DamageType.Kind.PHYSICAL)
	assert_eq(Game.rng.state, avant, "Game.rng intact")


func test_esquive_evite_environ_la_moitie_des_coups() -> void:
	var st := CharacterStats.new()
	st.evasion = 60.0   # 50 % attendu
	Game.rng.seed = 99
	var touches := 0
	for i in 2000:
		if _frapper(st, 10.0, DamageType.Kind.PHYSICAL) > 0.0:
			touches += 1
	# Fenêtre large : on vérifie la mécanique, pas la qualité du générateur.
	assert_between(touches, 880, 1120, "environ un coup sur deux passe")


## Un coup esquivé n'est pas un coup à zéro : il n'a pas eu lieu, donc pas de
## signal, donc ni recul, ni flash, ni vol de vie pour l'attaquant.
func test_un_coup_esquive_n_emet_pas_de_signal() -> void:
	var st := CharacterStats.new()
	st.evasion = 1000000.0   # plafond : 75 % d'esquive
	Game.rng.seed = 5
	var esquives := 0
	for i in 200:
		if _frapper(st, 10.0, DamageType.Kind.PHYSICAL) < 0.0:
			esquives += 1
	assert_gt(esquives, 0, "au moins un coup esquivé sans signal")
