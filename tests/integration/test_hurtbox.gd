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


# --------------------------------------------------------------------------
# Le coup en plusieurs natures (jalon 8, étape 1)
# --------------------------------------------------------------------------

func _parts(physique := 0.0, froid := 0.0, foudre := 0.0) -> Array[float]:
	var p := DamageType.parts_vides()
	p[DamageType.Kind.PHYSICAL] = physique
	p[DamageType.Kind.COLD] = froid
	p[DamageType.Kind.LIGHTNING] = foudre
	return p


## Le coup, tel qu'il ressort de la zone après mitigation.
func _encaisser(st: CharacterStats, parts: Array[float]) -> DamageInfo:
	var hb := Hurtbox.new()
	hb.stats = st
	add_child_autofree(hb)
	var info := DamageInfo.en_parts(parts, Vector2.ZERO)
	hb.take_damage(info)
	return info


## **Tout le jalon tient ici** : un sort de foudre qui porte du froid perd sa
## foudre contre un ennemi qui y résiste, et garde son froid.
func test_chaque_part_est_reduite_par_sa_resistance() -> void:
	var st := CharacterStats.new()
	st.res_lightning = 75.0
	var info := _encaisser(st, _parts(0.0, 10.0, 40.0))
	assert_almost_eq(info.parts[DamageType.Kind.LIGHTNING], 10.0, 0.001, "la foudre perd les trois quarts")
	assert_almost_eq(info.parts[DamageType.Kind.COLD], 10.0, 0.001, "le froid passe entier")
	assert_almost_eq(info.amount, 20.0, 0.001, "et la vie perd la somme")


## L'armure protège plus des petits coups : calculée sur le total, elle traiterait
## les douze points physiques d'un sort à soixante-deux comme un gros coup.
func test_l_armure_ne_voit_que_la_part_physique() -> void:
	var st := CharacterStats.new()
	st.armor = 60.0
	var info := _encaisser(st, _parts(12.0, 0.0, 50.0))
	assert_almost_eq(
		info.parts[DamageType.Kind.PHYSICAL], 12.0 * (1.0 - st.armor_reduction(12.0)), 0.001,
		"réduite comme un coup de douze"
	)
	assert_almost_eq(info.parts[DamageType.Kind.LIGHTNING], 50.0, 0.001, "et la foudre ne la voit pas")


## Un plancher par part ferait d'un coup en trois natures un coup à trois points.
func test_le_plancher_porte_sur_le_total() -> void:
	var st := CharacterStats.new()
	st.armor = 1000000.0
	st.res_cold = 75.0
	st.res_lightning = 75.0
	var info := _encaisser(st, _parts(2.0, 0.4, 0.4))
	assert_almost_eq(info.amount, Hurtbox.MIN_DAMAGE, 0.001)


## La nature d'un coup est celle de sa plus grosse part : c'est elle qui teint la
## gerbe d'éclats et dit contre quoi on frappe, et le nombre en montre le total.
func test_la_nature_d_un_coup_est_celle_de_sa_plus_grosse_part() -> void:
	var info := DamageInfo.en_parts(_parts(0.0, 30.0, 10.0), Vector2.ZERO)
	assert_eq(info.type, DamageType.Kind.COLD)
	assert_eq(info.amount, 40.0)
	assert_eq(DamageInfo.new(0.0, Vector2.ZERO).type, DamageType.Kind.PHYSICAL, "un coup nul reste physique")


## Les parts sont recopiées : la mitigation d'un ennemi ne doit pas revenir dans
## le sort qui l'a frappé, et frapper le suivant avec des dégâts déjà réduits.
func test_un_coup_ne_partage_pas_ses_parts_avec_son_lanceur() -> void:
	var lancees := _parts(0.0, 0.0, 40.0)
	var st := CharacterStats.new()
	st.res_lightning = 75.0
	_encaisser(st, lancees)
	assert_eq(lancees[DamageType.Kind.LIGHTNING], 40.0)


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
