extends GutTest

## L'unité d'affichage d'une statistique et l'ordre d'application des
## modificateurs. Les deux se voient immédiatement à l'écran quand ils sont
## faux, mais seulement si on regarde le bon objet au bon moment.


func test_display_units() -> void:
	assert_eq(StatMod.format("crit_chance", 0.05), "5 %", "fraction lue en %")
	assert_eq(StatMod.format("attack_speed", 1.1), "110 %", "multiplicateur lu en %")
	assert_eq(StatMod.format("crit_multiplier", 2.0), "200 %")
	assert_eq(StatMod.format("res_fire", 40.0), "40 %", "déjà en points de %")
	assert_eq(StatMod.format("max_health", 120.0), "120", "sans unité")
	assert_eq(StatMod.format("attack_damage", 6.5, true), "+6.5", "signe et décimale")
	assert_eq(StatMod.format("attack_damage", 6.0, true), "+6", "pas de décimale inutile")


## Confondre les deux familles donnerait « 7500 % de résistance au feu ».
func test_the_two_unit_families_do_not_mix() -> void:
	for s in StatMod.SCALED:
		assert_false(s in StatMod.PERCENT_POINTS, "%s n'est que dans une famille" % s)


func test_labels() -> void:
	assert_eq(StatMod.new("armor", StatMod.Mode.FLAT, 25.0).label(), "+25 armure")
	assert_eq(
		Glossary.plain(StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0).label()),
		"+8 % de vitesse d'attaque accrue"
	)
	assert_eq(StatMod.new("res_fire", StatMod.Mode.FLAT, 20.0).label(), "+20 % rés. feu")


## Jalon 18 : un plat monte la base, un accru l'accroît — dans les deux langues.
func test_crit_lines_name_the_base() -> void:
	var flat := StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.04)
	var increased := StatMod.new("crit_chance", StatMod.Mode.PERCENT, 20.0)
	assert_eq(flat.label(), "+4 % de chance critique de base")
	assert_eq(Glossary.plain(increased.label()), "+20 % de chance critique de base accrue")
	Settings.from_dict({"language": Settings.ENGLISH})
	var flat_text := flat.label()
	var increased_text := Glossary.plain(increased.label())
	Settings.from_dict({"language": Settings.FRENCH})
	assert_eq(flat_text, "+4% to base crit chance")
	assert_eq(increased_text, "+20% increased base crit chance")


## Jalon 15 : le terme dit le calcul et le sens, s'accorde avec la statistique, et
## « de » s'élide devant une voyelle.
func test_a_percentage_names_its_term() -> void:
	var plain := func(stat: String, mode: StatMod.Mode, v: float) -> String:
		return Glossary.plain(StatMod.new(stat, mode, v).label())
	assert_eq(plain.call("max_health", StatMod.Mode.MORE, 20.0), "+20 % de PV amplifiés")
	assert_eq(plain.call("armor", StatMod.Mode.MORE, 20.0), "+20 % d'armure amplifiée")
	assert_eq(plain.call("armor", StatMod.Mode.PERCENT, 10.0), "+10 % d'armure accrue")
	assert_eq(plain.call("attack_speed", StatMod.Mode.PERCENT, -15.0), "-15 % de vitesse d'attaque réduite")
	assert_eq(plain.call("max_health", StatMod.Mode.MORE, -20.0), "-20 % de PV atténués")


func test_a_percentage_reads_in_english() -> void:
	Settings.from_dict({"language": Settings.ENGLISH})
	var increased := StatMod.new("damage", StatMod.Mode.PERCENT, 20.0, Keywords.LIGHTNING)
	var less := StatMod.new("max_health", StatMod.Mode.MORE, -20.0)
	var increased_text := Glossary.plain(increased.label())
	var less_text := Glossary.plain(less.label())
	Settings.from_dict({"language": Settings.FRENCH})
	assert_eq(increased_text, "+20% increased damage (Lightning)")
	assert_eq(less_text, "-20% less HP")


## Le terme porte sa marque : c'est elle qui ouvre l'encadré.
func test_a_percentage_calls_its_glossary_entry() -> void:
	assert_eq(
		Glossary.terms(StatMod.new("armor", StatMod.Mode.PERCENT, 10.0).label()),
		PackedStringArray(["additive"])
	)
	assert_eq(
		Glossary.terms(StatMod.new("armor", StatMod.Mode.MORE, -10.0).readable_value()),
		PackedStringArray(["multiplicative"])
	)
	assert_eq(Glossary.terms(StatMod.new("armor", StatMod.Mode.FLAT, 10.0).label()), PackedStringArray())


## Un libellé sans accord prendrait le masculin singulier en silence.
func test_each_label_has_its_agreement() -> void:
	for field in StatMod.LABELS:
		assert_true(Glossary.AGREEMENTS.has(StatMod.AGREEMENT.get(field, "")), "« %s »" % field)
	for field in SkillStats.LABELS:
		assert_true(Glossary.AGREEMENTS.has(SkillStats.AGREEMENT.get(field, "")), "« %s »" % field)


## Une ligne portée dit ce qu'elle vise, avec **le libellé de la page du manuel** :
## « +20 % dégâts » tout court se lirait comme la ligne de fiche du même nom.
func test_a_scoped_modifier_says_what_it_targets() -> void:
	assert_eq(
		StatMod.new("projectiles", StatMod.Mode.FLAT, 1.0, Keywords.PROJECTILE).label(),
		"+1 nombre de projectiles (Projectile)"
	)
	assert_eq(
		Glossary.plain(StatMod.new("damage", StatMod.Mode.PERCENT, 20.0, Keywords.LIGHTNING).label()),
		"+20 % de dégâts accrus (Foudre)"
	)


## Des dégâts ajoutés se lisent comme la phrase du genre, destinataire compris.
## Des bornes égales s'écrivent comme un nombre : « ajoute 6 à 6 » se lit comme
## une faute.
func test_a_range_reads_in_full_words() -> void:
	var cold := StatMod.ranged("damage_cold", 3.0, 7.0, Keywords.SPELL)
	assert_eq(cold.label(), "ajoute 3 à 7 dégâts de froid aux sorts")
	assert_eq(cold.readable_value(), "3–7")
	var force := StatMod.ranged("damage_physical", 6.0, 6.0, Keywords.ATTACK)
	assert_eq(force.label(), "ajoute 6 dégâts physiques aux attaques")
	assert_eq(force.readable_value(), "6")


## Chaque nature a son identifiant et son nom de dégâts : une table plus courte
## que l'enum ferait planter la première ligne d'objet de la nature oubliée.
func test_each_nature_has_its_id_and_damage_name() -> void:
	assert_eq(DamageType.IDS.size(), DamageType.Kind.size())
	assert_eq(DamageType.DAMAGE_LABELS.size(), DamageType.Kind.size())
	for nature in DamageType.Kind.values():
		assert_eq(
			SkillStats.added_nature(SkillStats.added_stat(nature)), nature,
			"« %s » se relit" % DamageType.IDS[nature]
		)


## Le cœur de l'affaire : deux objets identiques doivent donner le même
## personnage quel que soit l'ordre où on les équipe.
func test_flats_before_percentages() -> void:
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


## Jalon 14 : les accrus d'un champ s'additionnent, chaque « plus » multiplie ensuite,
## quel que soit l'ordre de la liste.
func test_increased_add_up_and_more_multiplies() -> void:
	var mods: Array[StatMod] = [
		StatMod.new("max_health", StatMod.Mode.MORE, 10.0),
		StatMod.new("max_health", StatMod.Mode.PERCENT, 10.0),
		StatMod.new("max_health", StatMod.Mode.MORE, 10.0),
		StatMod.new("max_health", StatMod.Mode.PERCENT, 10.0),
		StatMod.new("max_health", StatMod.Mode.FLAT, 100.0),
	]
	var a := CharacterStats.new()
	a.max_health = 100.0
	StatMod.apply_all(a, mods)
	assert_almost_eq(a.max_health, 200.0 * 1.2 * 1.21, 1e-3, "(100 + 100) × 1,20 × 1,1 × 1,1")

	mods.reverse()
	var b := CharacterStats.new()
	b.max_health = 100.0
	StatMod.apply_all(b, mods)
	assert_almost_eq(b.max_health, a.max_health, 1e-3, "l'ordre ne change rien")


## **La confusion des deux familles.** Un modificateur qui vise un mot-clé ne
## touche pas la fiche, même quand son champ y porte un nom : sinon « +20 % de
## dégâts de foudre » deviendrait « +20 % de dégâts » pour toutes les compétences,
## foudre comprise, qui le recevrait alors deux fois.
func test_a_scoped_modifier_writes_nothing_on_the_sheet() -> void:
	var sheet := CharacterStats.new()
	var before := sheet.attack_damage
	StatMod.apply_all(sheet, [
		StatMod.new("attack_damage", StatMod.Mode.FLAT, 50.0, Keywords.LIGHTNING),
	])
	assert_eq(sheet.attack_damage, before)


# --------------------------------------------------------------------------
# L'affichage d'une jauge
# --------------------------------------------------------------------------

## Le défaut trouvé en jouant : 216 / 215. Les PV étaient pleins — 215,4 sur
## 215,4 — mais la valeur courante était arrondie vers le haut et le maximum au
## plus proche, chacun de son côté.
func test_a_full_gauge_never_shows_more_than_its_maximum() -> void:
	assert_eq(StatMod.gauge(215.4, 215.4), "215 / 215", "pleine, et fractionnaire")
	assert_eq(StatMod.gauge(215.6, 215.6), "216 / 216")
	assert_eq(StatMod.gauge(100.0, 100.0), "100 / 100", "le cas entier ne bouge pas")


## L'autre bout de la barre, et la raison pour laquelle l'arrondi se fait vers
## le haut : à 0,4 PV on est vivant.
func test_leftover_health_is_not_displayed_as_zero() -> void:
	assert_eq(StatMod.gauge(0.4, 100.0), "1 / 100")
	assert_eq(StatMod.gauge(0.01, 100.0), "1 / 100")


func test_zero_stays_zero() -> void:
	assert_eq(StatMod.gauge(0.0, 100.0), "0 / 100", "mort, et ça doit se voir")


## Un personnage sans mana : la fiche l'annonce, elle ne divise pas par zéro.
func test_a_missing_pool() -> void:
	assert_eq(StatMod.gauge(0.0, 0.0), "0 / 0")


# --------------------------------------------------------------------------
# Les plages de paliers (jalon 5, étape 7)
# --------------------------------------------------------------------------

## Une plage annonce ce qu\'un affixe **peut** donner : pas de signe, et l\'unité
## une seule fois. « +8 %–+11 % » se lit comme deux valeurs, pas comme un
## intervalle.
func test_a_span_is_written_without_sign_and_with_a_single_unit() -> void:
	assert_eq(StatMod.range_label("max_health", StatMod.Mode.FLAT, 45.0, 58.0), "45–58")
	assert_eq(StatMod.range_label("max_health", StatMod.Mode.PERCENT, 8.0, 11.0), "8–11 %")
	# Une statistique rangée en fraction se lit en pourcentage, une seule fois.
	assert_eq(StatMod.range_label("crit_chance", StatMod.Mode.FLAT, 0.05, 0.07), "5–7 %")
	# Et une déjà comptée en points de pourcentage n\'est pas multipliée.
	assert_eq(StatMod.range_label("res_fire", StatMod.Mode.FLAT, 16.0, 21.0), "16–21 %")


## Le libellé d\'un modificateur est sa valeur plus le nom de la statistique :
## les deux fonctions ne doivent pas diverger d\'un arrondi, d\'où le partage.
func test_the_bare_value_is_the_label_one() -> void:
	var m := StatMod.new("attack_speed", StatMod.Mode.PERCENT, 9.0)
	assert_eq(Glossary.plain(m.label()), "+9 % de vitesse d\'attaque accrue")
	assert_eq(StatMod.value_label(m.stat, m.mode, m.value), "+9 %")
	var flat := StatMod.new("max_health", StatMod.Mode.FLAT, 63.0)
	assert_eq(flat.label(), "+63 PV")
	assert_eq(StatMod.value_label(flat.stat, flat.mode, flat.value), "+63")
