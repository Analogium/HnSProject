extends GutTest

## L'unité d'affichage d'une statistique et l'ordre d'application des
## modificateurs. Les deux se voient immédiatement à l'écran quand ils sont
## faux, mais seulement si on regarde le bon objet au bon moment.


func test_unites_d_affichage() -> void:
	assert_eq(StatMod.format("crit_chance", 0.05), "5 %", "fraction lue en %")
	assert_eq(StatMod.format("attack_speed", 1.1), "110 %", "multiplicateur lu en %")
	assert_eq(StatMod.format("crit_multiplier", 2.0), "200 %")
	assert_eq(StatMod.format("res_fire", 40.0), "40 %", "déjà en points de %")
	assert_eq(StatMod.format("max_health", 120.0), "120", "sans unité")
	assert_eq(StatMod.format("attack_damage", 6.5, true), "+6.5", "signe et décimale")
	assert_eq(StatMod.format("attack_damage", 6.0, true), "+6", "pas de décimale inutile")


## Confondre les deux familles donnerait « 7500 % de résistance au feu ».
func test_les_deux_familles_d_unites_ne_se_melangent_pas() -> void:
	for s in StatMod.SCALED:
		assert_false(s in StatMod.PERCENT_POINTS, "%s n'est que dans une famille" % s)


func test_libelles() -> void:
	assert_eq(StatMod.new("armor", StatMod.Mode.FLAT, 25.0).label(), "+25 armure")
	assert_eq(
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0).label(),
		"+8 % vitesse d'attaque"
	)
	assert_eq(StatMod.new("res_fire", StatMod.Mode.FLAT, 20.0).label(), "+20 % rés. feu")


## Le cœur de l'affaire : deux objets identiques doivent donner le même
## personnage quel que soit l'ordre où on les équipe.
func test_les_plats_avant_les_pourcentages() -> void:
	var mods: Array[StatMod] = [
		StatMod.new("max_health", StatMod.Mode.PERCENT, 50.0),
		StatMod.new("max_health", StatMod.Mode.FLAT, 100.0),
	]
	var a := CharacterStats.new()
	a.max_health = 100.0
	StatMod.apply_all(a, mods)

	var inverse: Array[StatMod] = [mods[1], mods[0]]
	var b := CharacterStats.new()
	b.max_health = 100.0
	StatMod.apply_all(b, inverse)

	assert_eq(a.max_health, 300.0, "(100 + 100) x 1,5")
	assert_eq(b.max_health, a.max_health, "l'ordre d'équipement ne change rien")


# --------------------------------------------------------------------------
# L'affichage d'une jauge
# --------------------------------------------------------------------------

## Le défaut trouvé en jouant : 216 / 215. Les PV étaient pleins — 215,4 sur
## 215,4 — mais la valeur courante était arrondie vers le haut et le maximum au
## plus proche, chacun de son côté.
func test_une_jauge_pleine_n_affiche_jamais_plus_que_son_maximum() -> void:
	assert_eq(StatMod.gauge(215.4, 215.4), "215 / 215", "pleine, et fractionnaire")
	assert_eq(StatMod.gauge(215.6, 215.6), "216 / 216")
	assert_eq(StatMod.gauge(100.0, 100.0), "100 / 100", "le cas entier ne bouge pas")


## L'autre bout de la barre, et la raison pour laquelle l'arrondi se fait vers
## le haut : à 0,4 PV on est vivant.
func test_un_reste_de_vie_ne_s_affiche_pas_a_zero() -> void:
	assert_eq(StatMod.gauge(0.4, 100.0), "1 / 100")
	assert_eq(StatMod.gauge(0.01, 100.0), "1 / 100")


func test_zero_reste_zero() -> void:
	assert_eq(StatMod.gauge(0.0, 100.0), "0 / 100", "mort, et ça doit se voir")


## Un personnage sans mana : la fiche l'annonce, elle ne divise pas par zéro.
func test_une_reserve_absente() -> void:
	assert_eq(StatMod.gauge(0.0, 0.0), "0 / 0")


# --------------------------------------------------------------------------
# Les plages de paliers (jalon 5, étape 7)
# --------------------------------------------------------------------------

## Une plage annonce ce qu\'un affixe **peut** donner : pas de signe, et l\'unité
## une seule fois. « +8 %–+11 % » se lit comme deux valeurs, pas comme un
## intervalle.
func test_une_plage_s_ecrit_sans_signe_et_avec_une_seule_unite() -> void:
	assert_eq(StatMod.range_label("max_health", StatMod.Mode.FLAT, 45.0, 58.0), "45–58")
	assert_eq(StatMod.range_label("max_health", StatMod.Mode.PERCENT, 8.0, 11.0), "8–11 %")
	# Une statistique rangée en fraction se lit en pourcentage, une seule fois.
	assert_eq(StatMod.range_label("crit_chance", StatMod.Mode.FLAT, 0.05, 0.07), "5–7 %")
	# Et une déjà comptée en points de pourcentage n\'est pas multipliée.
	assert_eq(StatMod.range_label("res_fire", StatMod.Mode.FLAT, 16.0, 21.0), "16–21 %")


## Le libellé d\'un modificateur est sa valeur plus le nom de la statistique :
## les deux fonctions ne doivent pas diverger d\'un arrondi, d\'où le partage.
func test_la_valeur_seule_est_celle_du_libelle() -> void:
	var m := StatMod.new("attack_speed", StatMod.Mode.PERCENT, 9.0)
	assert_eq(m.label(), "+9 % vitesse d\'attaque")
	assert_eq(StatMod.value_label(m.stat, m.mode, m.value), "+9 %")
	var plat := StatMod.new("max_health", StatMod.Mode.FLAT, 63.0)
	assert_eq(plat.label(), "+63 PV")
	assert_eq(StatMod.value_label(plat.stat, plat.mode, plat.value), "+63")
