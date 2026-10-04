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
	if "trees" in OS.get_cmdline_user_args():
		await _trees()
		return
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
	l.append("<!-- Fichier généré par tools/balance.sh — ne pas éditer à la main. -->")
	l.append("")
	l.append("Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits")
	l.append("par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par")
	l.append("les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages")
	l.append("restent une décision — voir `JALONS/hack-n-slash-jalon-13.md`.")
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
	l.append("Un profil équipé est tiré %d fois : coups et survie sont les médianes, chacune" % BenchCalculation.ITEM_DRAWS)
	l.append("sur son axe ; le détail est celui du tirage médian en coups.")
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
			var m := calculation.measure_profile(build, profile, zone, zone)
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


## Le banc des arbres (jalon 37) : `tools/balance.sh trees`, qui écrit `docs/ARBRES.md`.
## `only=<compétence>,<compétence>` n'en mesure que celles-là et recopie les autres du rapport
## précédent ; `probe` s'arrête aux compétences nues.
const TREE_PARTS := "user://arbres"
const TREE_MANUALS := [
	"manual_fire", "manual_lightning", "manual_cold", "manual_necrotic", "manual_weapons",
	"manual_holy",
]


func _trees() -> void:
	var args := OS.get_cmdline_user_args()
	var only := ""
	for a in args:
		if a.begins_with("only="):
			only = a.trim_prefix("only=")
	# Sans gel : il ralentit le temps de jeu, et le banc compte en secondes de jeu.
	Game.hit_stop_duration = 0.0
	var bench := BenchTrees.new(self)
	print("arbres réserve : %.0f mana, %.1f/s" % [bench.mana_pool, bench.mana_regen])
	# `measure=<manuel>:<compétence>:<nœud>,<nœud>…` : un build, scène par scène et
	# distance par distance, pour regarder de près ce que le rapport résume.
	for a in args:
		if a.begins_with("measure="):
			var parts := a.trim_prefix("measure=").split(":")
			var nodes := Array(parts[2].split(",", false)) if parts.size() > 2 else []
			for scene in [BenchTrees.Scene.PACK, BenchTrees.Scene.DUEL]:
				for distance in [BenchTrees.NEAR, BenchTrees.FAR]:
					var m: BenchTrees.Measure = await bench._run(parts[0], parts[1], nodes, scene, distance)
					print("arbres mesure %s %d px : %.1f/s, %d morts" % [
						BenchTrees.SCENE_NAMES[scene], distance, m.per_second, m.kills
					])
			get_tree().quit()
			return
	# `part=<i>/<n>` : ce processus ne prend qu'une compétence sur n, la i-ème en
	# alternance — le Serpent ne tombe pas avec ses voisines. Chaque section va dans
	# son propre fichier, que `tools/balance.sh` rassemble dans l'ordre.
	var part := Vector2i(0, 1)
	for a in args:
		if a.begins_with("part="):
			var split := a.trim_prefix("part=").split("/")
			part = Vector2i(int(split[0]), int(split[1]))
	DirAccess.make_dir_recursive_absolute(TREE_PARTS)
	if part.x == 0:
		var head := PackedStringArray()
		_trees_header(head, bench)
		_write(TREE_PARTS.path_join("00.md"), head)
	var previous := _previous_sections() if not only.is_empty() else {}
	var index := 0
	for manual_id: String in TREE_MANUALS:
		var book := ItemCatalog.by_id(manual_id)
		var first_of_manual := true
		for cell in book.manual.cells:
			if cell.skill == null or cell.talents.is_empty() or not cell.skill.strikes():
				continue
			index += 1
			var mine := (index - 1) % part.y == part.x
			var l := PackedStringArray()
			if first_of_manual:
				l.append("## %s" % book.display_name)
				l.append("")
				first_of_manual = false
			if not mine:
				continue
			# Hors de `only=`, la section du rapport précédent, à sa place : `balance.sh` réécrit
			# tout le fichier, et il n'en restait que les compétences mesurées.
			if not only.is_empty() and not cell.skill.id in only.split(","):
				if not previous.has(cell.skill.name):
					print("arbres %s : absent du rapport précédent, relancer sans only=" % cell.skill.id)
				l.append_array(previous.get(cell.skill.name, PackedStringArray()))
				_write(TREE_PARTS.path_join("%02d.md" % index), l)
				continue
			var start := Time.get_ticks_msec()
			var runs := bench.runs
			await _tree(l, bench, manual_id, cell, "probe" in args)
			_write(TREE_PARTS.path_join("%02d.md" % index), l)
			print("arbres %s : %d ms, %d simulations" % [cell.skill.id, Time.get_ticks_msec() - start, bench.runs - runs])
	get_tree().quit()


## Les sections de `docs/ARBRES.md` (la copie du banc), par titre de compétence, sans le
## titre de manuel, que la boucle réécrit. Normalisées à une ligne vide finale, comme
## celles que `_tree()` écrit.
func _previous_sections() -> Dictionary:
	var out := {}
	var f := FileAccess.open("res://docs/ARBRES.md", FileAccess.READ)
	if f == null:
		return out
	var current := ""
	for line in f.get_as_text().split("\n"):
		if line.begins_with("## "):
			current = ""
		elif line.begins_with("### "):
			current = line.trim_prefix("### ")
			out[current] = []
		if not current.is_empty():
			(out[current] as Array).append(line)
	for title: String in out:
		var lines: Array = out[title]
		while not lines.is_empty() and (lines[-1] as String).is_empty():
			lines.pop_back()
		lines.append("")
		out[title] = PackedStringArray(lines)
	return out


func _write(path: String, l: PackedStringArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(l) + "\n")
	f.close()


func _trees_header(l: PackedStringArray, bench: BenchTrees) -> void:
	l.append("# Banc des arbres")
	l.append("")
	l.append("<!-- Fichier généré par tools/balance.sh trees — ne pas éditer à la main. -->")
	l.append("")
	l.append("Chaque compétence de dégâts des manuels repris, lancée sans relâche sur des cibles")
	l.append("immobiles par les vraies fonctions du jeu (`BenchTrees`) : **paquet**, %d grunts de" % (BenchTrees.PACK_RING + 1))
	l.append("zone %d qui renaissent à leur mort ; **duel**, une cible qui ne meurt pas. Au contact" % BenchTrees.ZONE)
	l.append("(%d px) ou au point visé (%d px), la meilleure des deux. Dégâts par seconde après" % [BenchTrees.NEAR, BenchTrees.FAR])
	l.append("défenses, brûlures comprises, sur %d s après %d s de chauffe, avec la réserve du Sort" % [BenchTrees.SECONDS, BenchTrees.WARM_UP])
	l.append("« Équipé » de zone %d : %d mana et %s/s. Compétence à 5 points, arbre à %d." % [
		BenchTrees.MANA_ZONE, roundi(bench.mana_pool), _n(bench.mana_regen), Manual.MAX_LEVEL
	])
	l.append("")
	l.append("Les builds sont **cherchés** et non écrits : à chaque pas, le nœud — avec le chemin le")
	l.append("moins cher qui l'ouvre — qui rend le plus par point dans la scène visée. Une")
	l.append("transformation ou une conversion est prise d'abord, puis la recherche reprend. ×N :")
	l.append("le rapport à la compétence sans arbre, dans la même scène. Ce qui ne frappe pas —")
	l.append("les buffs, la Malédiction putride — n'est pas mesuré : ce qu'ils valent se lit sur une")
	l.append("autre compétence. Ce que le banc ne voit pas — ralentir, tirer, esquiver,")
	l.append("survivre — ne rend rien ici.")
	l.append("")


func _tree(l: PackedStringArray, bench: BenchTrees, manual_id: String, cell: ManualCell, probe: bool) -> void:
	l.append("### %s" % cell.skill.name)
	l.append("")
	l.append("| build | points | paquet | duel |")
	l.append("|---|---|---|---|")
	var bare := BenchTrees.Build.new()
	await bench.complete(manual_id, cell, bare)
	l.append("| sans arbre | — | %s | %s |" % [_dps(bare.pack, null), _dps(bare.duel, null)])
	if probe:
		l.append("")
		return
	var chosen: Array[BenchTrees.Build] = []
	for scene in [BenchTrees.Scene.PACK, BenchTrees.Scene.DUEL]:
		var b: BenchTrees.Build = await bench.best_build(manual_id, cell, scene)
		await bench.complete(manual_id, cell, b)
		chosen.append(b)
		l.append("| meilleur au %s | %s | %s | %s |" % [
			BenchTrees.SCENE_NAMES[scene], b.label(cell), _dps(b.pack, bare.pack), _dps(b.duel, bare.duel)
		])
	for node in cell.talents:
		if not (node.transforms or node.converts or node.frees):
			continue
		var forced := bench.opening(cell, node)
		for scene in [BenchTrees.Scene.PACK, BenchTrees.Scene.DUEL]:
			var b: BenchTrees.Build = await bench.best_build(manual_id, cell, scene, forced)
			await bench.complete(manual_id, cell, b)
			chosen.append(b)
			l.append("| %s au %s (%s) | %s | %s | %s |" % [
				node.name, BenchTrees.SCENE_NAMES[scene],
				"transformation" if node.transforms else "conversion", b.label(cell),
				_dps(b.pack, bare.pack), _dps(b.duel, bare.duel)
			])
	var never := PackedStringArray()
	for node in cell.talents:
		if chosen.all(func(b: BenchTrees.Build) -> bool: return b.count(node.id) == 0):
			never.append(node.name)
	l.append("")
	l.append("Jamais pris : %s." % (", ".join(never) if not never.is_empty() else "aucun"))
	l.append("")


func _dps(m: BenchTrees.Measure, bare: BenchTrees.Measure) -> String:
	var text_value := "%s/s" % _n(m.per_second)
	if bare != null and bare.per_second > 0.0:
		text_value += " ×%s" % _n(m.per_second / bare.per_second)
	return text_value


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
