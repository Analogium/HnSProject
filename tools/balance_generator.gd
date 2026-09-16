extends Node

## Écrit `docs/EQUILIBRAGE.md` : le calcul sur toute la grille, puis la simulation sur
## une sélection de cases. Lancé par `tools/balance.sh` ; l'argument `calculation` saute
## la simulation. Une scène et non un `--script`, qui n'enregistrerait pas les autoloads.

const OUTPUT := "user://EQUILIBRAGE.md"
const PLAYER := preload("res://actors/player/player.tscn")

## La simulation joue chaque profil dans cette zone, et l'Équipé à ± l'écart.
const SIMULATED_ZONE := 40
const SIMULATED_SPREAD := 20


func _ready() -> void:
	var l := PackedStringArray()
	_header(l)
	_levels(l)

	var start := Time.get_ticks_msec()
	var player: Player = PLAYER.instantiate()
	add_child(player)
	var calculation := BenchCalculation.new(player)
	for build in BenchProfiles.builds():
		_grid(l, calculation, build)
	calculation = null
	player.free()
	print("calcul : %d ms" % (Time.get_ticks_msec() - start))

	if "calculation" in OS.get_cmdline_user_args():
		l.append("## Simulation")
		l.append("")
		l.append("Non relancée : `tools/balance.sh calculation`.")
	else:
		await _simulation(l)

	var f := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if f == null:
		push_error("Écriture impossible : %s" % OUTPUT)
		get_tree().quit(1)
		return
	f.store_string("\n".join(l) + "\n")
	f.close()
	get_tree().quit()


func _header(l: PackedStringArray) -> void:
	l.append("# Banc d'équilibrage")
	l.append("")
	l.append("<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->")
	l.append("")
	l.append("Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits")
	l.append("par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par")
	l.append("les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages")
	l.append("restent une décision — voir `hack-n-slash-jalon-13.md`.")
	l.append("")
	l.append("| verdict | coups pour tuer un grunt | survie au contact |")
	l.append("|---|---|---|")
	l.append("| %s trivial | moins de %s | plus de %s s |" % [
		BenchCalculation.PIPS[0], _n(BenchCalculation.HITS_TRIVIAL), _n(BenchCalculation.SURVIVAL_COMFORTABLE)
	])
	l.append("| %s confortable | %s à %s | plus de %s s |" % [
		BenchCalculation.PIPS[1], _n(BenchCalculation.HITS_TRIVIAL), _n(BenchCalculation.HITS_COMFORTABLE),
		_n(BenchCalculation.SURVIVAL_COMFORTABLE)
	])
	l.append("| %s tendu | %s à %s | %s à %s s |" % [
		BenchCalculation.PIPS[2], _n(BenchCalculation.HITS_COMFORTABLE), _n(BenchCalculation.HITS_TIGHT),
		_n(BenchCalculation.SURVIVAL_TIGHT), _n(BenchCalculation.SURVIVAL_COMFORTABLE)
	])
	l.append("| %s mur | plus de %s | moins de %s s |" % [
		BenchCalculation.PIPS[3], _n(BenchCalculation.HITS_TIGHT), _n(BenchCalculation.SURVIVAL_TIGHT)
	])
	l.append("")
	l.append("Le verdict est le pire des deux axes. Pour lire les nombres :")
	l.append("")
	l.append("- **coups** : avec la compétence de la barre qui en demande le moins, critique en")
	l.append("  moyenne, après les défenses de l'ennemi ;")
	l.append("- **secondes** : par `average_per_second()`, *si tout touche* — les traits d'une")
	l.append("  nova comptent tous sur la même cible — et sans compter la réserve de mana ;")
	l.append("- **survie** : au contact de %d grunts et %d caster sans affixe, après armure," % [
		BenchCalculation.GRUNTS_IN_CONTACT, BenchCalculation.CASTERS_IN_CONTACT
	])
	l.append("  résistances et esquive, régénération déduite. ∞ : la régénération suffit.")
	l.append("")


## La colonne vertébrale de la grille : un profil « de la zone Z » a ce niveau.
func _levels(l: PackedStringArray) -> void:
	l.append("## Niveau attendu")
	l.append("")
	l.append("Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population")
	l.append("moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.")
	l.append("")
	var header := "| zone |"
	var line := "| niveau |"
	for zone in BenchProfiles.ZONES:
		header += " %d |" % zone
		line += " %d |" % BenchProfiles.expected_level(zone).x
	l.append(header)
	l.append("|---|" + "---|".repeat(BenchProfiles.ZONES.size()))
	l.append(line)
	l.append("")


func _grid(l: PackedStringArray, calculation: BenchCalculation, build: BenchProfiles.Build) -> void:
	var book := ItemCatalog.by_id(build.manual)
	l.append("## %s — %s, %s" % [build.name, book.display_name, _keystone_of(build)])
	l.append("")
	var header := "| profil |"
	for zone in BenchProfiles.ZONES:
		header += " zone %d |" % zone
	l.append(header)
	l.append("|---|" + "---|".repeat(BenchProfiles.ZONES.size()))

	var detail := PackedStringArray()
	for profile in BenchProfiles.Profile.values():
		var line := "| %s |" % BenchProfiles.PROFILE_NAMES[profile]
		for zone in BenchProfiles.ZONES:
			var m := calculation.measure(BenchProfiles.character(build, profile, zone), zone)
			line += " %s |" % _cell(m)
			detail.append(_detail(BenchProfiles.PROFILE_NAMES[profile], m))
		l.append(line)
	l.append("")
	l.append("Case : verdict, coups pour tuer un grunt, secondes de survie.")
	l.append("")
	l.append("<details><summary>Détail</summary>")
	l.append("")
	l.append("| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |")
	l.append("|---|---|---|---|---|---|---|---|---|---|")
	l.append_array(detail)
	l.append("")
	l.append("</details>")
	l.append("")


## La clé de voûte où mène le chemin du build.
func _keystone_of(build: BenchProfiles.Build) -> String:
	var tree := PassiveTree.shared()
	for id in build.path:
		if tree.node(id).kind == PassiveNode.Kind.KEYSTONE:
			return tree.node(id).name
	return ""


func _cell(m: BenchCalculation.Measurement) -> String:
	return "%s %s · %s s" % [BenchCalculation.PIPS[m.verdict], _n(m.grunt_hits), _n(m.survival)]


func _detail(name: String, m: BenchCalculation.Measurement) -> String:
	return "| %s | %d | %d | %s | %s | %s | %s | %s | %s | %s |" % [
		name, m.zone, m.level, m.skill if not m.skill.is_empty() else "—",
		_n(m.grunt_hits), _n(m.caster_hits), _n(m.colossus_hits),
		_n(m.grunt_seconds), _n(m.colossus_seconds), _n(m.survival),
	]


## Chaque profil dans la zone simulée, l'Équipé de cette zone joué à ± l'écart.
func _simulation(l: PackedStringArray) -> void:
	l.append("## Simulation")
	l.append("")
	l.append("Un robot dans `world/zone.tscn`, graine %d, plafond de %d s de jeu : il marche vers" % [
		BenchSimulation.SEED, roundi(BenchSimulation.CAP)
	])
	l.append("l'ennemi le plus proche et lance toute sa barre dès que la recharge le permet. Un joueur")
	l.append("médiocre, et c'est voulu : un plancher. Une mort recharge la zone.")
	l.append("")
	l.append("| build | profil | construit pour | zone jouée | niveau | tués/min | morts | sous 30 % | vidée en |")
	l.append("|---|---|---|---|---|---|---|---|---|")
	for build in BenchProfiles.builds():
		var cells := []
		for profile in BenchProfiles.Profile.values():
			var zone := 1 if profile == BenchProfiles.Profile.BEGINNER else SIMULATED_ZONE
			cells.append([profile, zone, zone])
		for spread in [-SIMULATED_SPREAD, SIMULATED_SPREAD]:
			cells.append([BenchProfiles.Profile.EQUIPPED, SIMULATED_ZONE, SIMULATED_ZONE + spread])
		for c in cells:
			var start := Time.get_ticks_msec()
			var r: BenchSimulation.Result = await BenchSimulation.new().play(
				self, BenchProfiles.character(build, c[0], c[1]), c[2]
			)
			print("simulation %s %s %d→%d : %d ms" % [
				build.id, BenchProfiles.PROFILE_NAMES[c[0]], c[1], c[2], Time.get_ticks_msec() - start
			])
			l.append("| %s | %s | %d | %d | %d | %s | %d | %s s | %s |" % [
				build.name, BenchProfiles.PROFILE_NAMES[c[0]], c[1], c[2], r.level,
				_n(r.kills_per_minute()), r.deaths, _n(r.under_low_health),
				"%s s" % _n(r.time_value) if r.emptied else "—",
			])
	l.append("")


## Deux décimales sous 10, une sous 100, aucune au-delà ; virgule décimale.
static func _n(x: float) -> String:
	if is_inf(x):
		return "∞"
	var text_value := "%d" % roundi(x)
	if absf(x) < 10.0:
		text_value = "%.2f" % x
	elif absf(x) < 100.0:
		text_value = "%.1f" % x
	return text_value.replace(".", ",")
