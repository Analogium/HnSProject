extends Node

## Écrit `docs/CATALOGUE.md` à partir du catalogue et de la réserve d'affixes.
##
## Une référence **générée** et non tenue à la main : elle décrit soixante-six
## `.tres`, et une table recopiée à la main serait fausse à la première retouche
## d'équilibrage sans que rien ne le signale. Lancer `tools/catalogue.sh` après
## avoir touché un `.tres`.
##
## Une scène et non un `--script` : `--script` n'enregistre pas les autoloads, et
## la fenêtre de chute se lit contre `Game.MAX_LEVEL`.
##
## Écrit dans `user://` : en jeu exporté `res://` n'est pas inscriptible, et
## c'est le lanceur qui rapatrie le fichier dans le dépôt.

const OUTPUT := "user://CATALOGUE.md"


func _ready() -> void:
	var l := PackedStringArray()
	_header(l)
	_bases(l)
	_manuals(l)
	_passive_tree(l)
	_affixes(l)
	_scales(l)

	var f := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if f == null:
		push_error("Écriture impossible : %s" % OUTPUT)
		get_tree().quit(1)
		return
	f.store_string("\n".join(l) + "\n")
	f.close()
	print("CATALOGUE écrit : ", ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit()


func _header(l: PackedStringArray) -> void:
	l.append("# Référence des données")
	l.append("")
	l.append("<!-- Fichier généré par tools/catalogue.sh — ne pas éditer à la main. -->")
	l.append("")
	l.append("%d bases d'objets, %d compétences, %d affixes d'objets, %d affixes d'ennemis." % [
		ItemCatalog.ALL.size(), SkillCatalog.ALL.size(),
		ItemAffixPool.ALL.size(), AffixPool.ALL.size()
	])
	l.append("")
	l.append("Deux règles ne se lisent dans aucun `.tres`, et il faut les avoir en tête")
	l.append("pour lire les tables :")
	l.append("")
	l.append("- **la colonne « tombe en zones » est calculée.** Une base tombe de son")
	l.append("  `required_level` jusqu'à **%d niveaux** après l'ouverture du palier suivant" % ItemCatalog.READING_MARGIN)
	l.append("  de sa lignée (`ItemCatalog.READING_MARGIN`). Insérer un palier au milieu")
	l.append("  d'une lignée raccourcit donc celui d'avant ;")
	l.append("- **tous les paliers d'un affixe ne sortent jamais ensemble.** Un objet n'en a")
	l.append("  que **%d** d'ouverts à la fois — le meilleur qu'il atteint et les %d du" % [ItemAffix.OPEN_TIERS, ItemAffix.OPEN_TIERS - 1])
	l.append("  dessous (`ItemAffix.OPEN_TIERS`). La colonne « ouvre à » des échelles")
	l.append("  donne le plancher, pas la garantie.")
	l.append("")
	l.append("Niveaux de zone : %d à %d." % [Game.MIN_LEVEL, Game.MAX_LEVEL])
	l.append("")


## Les bases, dans l'ordre du catalogue — par lignée, puis par palier — pour que
## les trois âges d'un même objet restent voisins.
func _bases(l: PackedStringArray) -> void:
	l.append("## Bases d'objets")
	l.append("")
	l.append("| id | nom | lignée | palier | famille | étiquettes | implicite | critique | cases | tombe en zones |")
	l.append("|---|---|---|---|---|---|---|---|---|---|")
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		var imp := base.implicit()
		var f := ItemCatalog.drop_window(base)
		var window := "%d et au-delà" % f.x if f.y <= 0 else "%d à %d" % [f.x, f.y]
		l.append("| `%s` | %s | %s | %d | %s | %s | %s | %s | %d × %d | %s |" % [
			base.id,
			base.display_name,
			base.lineage,
			base.tier,
			base.family if not base.family.is_empty() else "—",
			", ".join(base.tags),
			"—" if imp == null else Glossary.plain(imp.label()),
			"—" if base.family != ItemBase.WEAPON_FAMILY else StatMod.format(SkillStats.CRIT_CHANCE, base.crit_chance),
			base.grid_size.x, base.grid_size.y,
			window,
		])
	l.append("")


## Ce que chaque manuel enseigne : ses cases, et l'arbre de chacune de ses
## compétences.
##
## C'est la partie du contenu qu'on ne peut pas regarder autrement qu'en ouvrant
## un `.tres` — vingt-sept nœuds répartis dans trois fichiers — et c'est celle
## qu'on veut sous les yeux pour équilibrer un arbre contre un autre.
func _manuals(l: PackedStringArray) -> void:
	l.append("## Manuels")
	l.append("")
	l.append("Un manuel gagne **un point par niveau**, %d au plafond" % Manual.MAX_LEVEL)
	l.append("(`Manual.MAX_LEVEL`), et ses cases, ses passifs et ses nœuds se servent")
	l.append("dans le même sac : la colonne « points » dit ce que chacun accepte, et leur")
	l.append("somme dépasse volontairement ce qu'un livre peut gagner.")
	l.append("")
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		if base.manual == null:
			continue
		_a_manual(l, base)


func _a_manual(l: PackedStringArray, base: ItemBase) -> void:
	var arch := base.manual
	var budget := 0
	l.append("### %s — `%s`" % [arch.name, base.id])
	l.append("")
	l.append("| case | sorte | ouvre à | points | coût | cadence | forme | par point |")
	l.append("|---|---|---|---|---|---|---|---|")
	for cell: ManualCell in arch.cells:
		budget += cell.points_max()
		if cell.passive != null:
			l.append("| %s | passif | niveau %d | %d | — | — | — | %s |" % [
				cell.passive.name, cell.passive.required_manual_level, cell.passive.points_max,
				_per_point(cell.passive.lines)
			])
			continue
		var c := cell.skill
		# Sans table de dégâts, la colonne dit ce que le point donne — comme pour un
		# passif : une case qui n'annonce rien ne se relit pas.
		var table := PackedStringArray()
		for d in c.damage_per_point:
			table.append("%d" % roundi(d))
		if table.is_empty():
			for buff in c.buffs:
				table.append("%s : %s" % [buff.name, _per_point(buff.lines)])
		# Le mot-clé de la cadence par la table de `Skill`, jamais par un ternaire
		# recopié : la colonne annonçait « attack » à côté d'une nature française.
		var cadence := Keywords.label_of(Skill.KEYWORD_OF_CADENCE[c.cadence])
		l.append("| %s | %s %s | niveau %d | %d | %d mana | %s | %s | %s |" % [
			c.name,
			cadence.to_lower(),
			DamageType.NAMES[c.nature],
			c.required_manual_level,
			c.points_max(),
			roundi(c.mana_cost),
			_pace(c),
			_shape(c),
			" · ".join(table),
		])
	l.append("")

	var nodes := 0
	var lines := PackedStringArray()
	for cell: ManualCell in arch.cells:
		for n: TalentNode in cell.talents:
			nodes += 1
			budget += n.points_max
			lines.append("| %s | %s | %s | %s | %d | %s |" % [
				n.name,
				cell.skill.name,
				"—" if n.parent.is_empty() else cell.node_of(n.parent).name,
				Texts.tn(
					"%d point de compétence", "%d points de compétence", n.required_points
				) % n.required_points,
				n.points_max,
				_node_effect(n),
			])
	if nodes > 0:
		l.append("| nœud | compétence | parent | demande | points | par point |")
		l.append("|---|---|---|---|---|---|")
		l.append_array(lines)
		l.append("")
	l.append("%d destinations de points pour %d gagnés." % [budget, Manual.MAX_LEVEL])
	l.append("")


func _passive_tree(l: PackedStringArray) -> void:
	var tree := PassiveTree.shared()
	l.append("## Arbre de passifs")
	l.append("")
	l.append("Un point par niveau après le premier (`PassiveTree.points_gained()`), %d nœuds" % tree.nodes.size())
	l.append("hors du départ. Un nœud se prend voisin d'un nœud pris, se reprend tant qu'il ne")
	l.append("coupe rien. Les petits nœuds sont listés par région, dans l'ordre du fichier.")
	l.append("")
	l.append("| nœud | sorte | case | voisins | effet |")
	l.append("|---|---|---|---|---|")
	for n in tree.nodes:
		if n.kind == PassiveNode.Kind.START:
			continue
		l.append("| %s | %s | %d, %d | %s | %s |" % [
			n.id if n.name.is_empty() else "**%s** `%s`" % [n.name, n.id],
			String(PassiveNode.Kind.keys()[n.kind]).to_lower(),
			n.position.x, n.position.y,
			", ".join(tree.neighbors(n.id)),
			_per_point(n.lines),
		])
	l.append("")


## Les lignes d'un passif ou d'un nœud, telles qu'un objet les écrirait : c'est la
## même fonction qui les affiche en jeu, donc la référence ne peut pas annoncer
## autre chose que la page du manuel.
func _per_point(lines: Array[TalentLine]) -> String:
	var out := PackedStringArray()
	for line in lines:
		out.append(Glossary.plain(line.modifier(1).label()))
	return " · ".join(out) if out.size() > 0 else "—"


## Le temps du geste et la recharge : deux nombres que rien ne change ensemble.
func _pace(c: Skill) -> String:
	var out := PackedStringArray()
	if c.cadence == Skill.Cadence.WEAPON:
		out.append("cadence de l'arme")
	elif c.cast_time > 0.0:
		out.append("%.2f s" % c.cast_time)
	if c.cooldown > 0.0:
		out.append("recharge %.2f s" % c.cooldown)
	return " · ".join(out) if out.size() > 0 else "—"


## La forme et les nombres qui la décrivent : « trait ×8 sur 360° », « nuage 3 s,
## rayon 34 ». Ce qui vaut sa valeur par défaut ne s'écrit pas.
func _shape(c: Skill) -> String:
	var out := PackedStringArray([String(Skill.Shape.keys()[c.shape]).to_lower()])
	if c.projectiles > 1:
		out.append("×%d sur %d°" % [c.projectiles, roundi(c.spread_in_degrees)])
	if c.targets > 1:
		out.append("%d cibles" % c.targets)
	if c.duration > 0.0:
		out.append("%.1f s" % c.duration)
	if c.radius > 0.0:
		out.append("rayon %d" % roundi(c.radius))
	if c.period > 0.0:
		out.append("toutes les %.2f s" % c.period)
	if c.simultaneous > 0:
		out.append("%d au plus" % c.simultaneous)
	if c.self_burn > 0.0:
		out.append("brûle %d %% PV/s" % roundi(c.self_burn * 100.0))
	# Les deux autres prix d'un geste entretenu. Absents jusqu'au jalon 21, où le
	# cyclone se paie **entièrement** au drain : la table l'aurait donné gratuit.
	if c.mana_per_second > 0.0:
		out.append("draine %d mana/s" % roundi(c.mana_per_second))
	if c.self_heal > 0.0:
		out.append("rend %.1f %% PV/s" % (c.self_heal * 100.0))
	if c.status_chance_increase > 0.0:
		out.append("%+d %% de chance d'état" % roundi(c.status_chance_increase))
	if c.health_scaling > 0.0:
		out.append("adossé aux PV %.1f %%" % (c.health_scaling * 100.0))
	return " · ".join(out)


func _node_effect(n: TalentNode) -> String:
	var out := PackedStringArray()
	if n.lines.size() > 0:
		out.append(_per_point(n.lines))
	if n.converts():
		out.append("convertit %d %% en %s" % [
			roundi(n.converted_part_per_point * 100.0), DamageType.NAMES[n.converts_to]
		])
	for id in n.added_keywords:
		out.append("donne le mot-clé %s" % Keywords.LABELS.get(id, id))
	return " · ".join(out)


## Les affixes d'objets, triés par identifiant : on vient en chercher un qu'on a
## en tête, et l'ordre de la réserve — thématique — ne se devine pas.
func _affixes(l: PackedStringArray) -> void:
	l.append("## Affixes d'objets")
	l.append("")
	l.append("`vise` vide veut dire « partout », sous réserve d'`interdit`, qui l'emporte.")
	l.append("")
	l.append("| id | statistique | vise | interdit | poids | paliers | bases éligibles |")
	l.append("|---|---|---|---|---|---|---|")
	for raw in _sorted_affixes():
		var a: ItemAffix = raw
		# Par `compatibles()` et non par `fits()` : le filtre par étiquettes n'est
		# qu'une partie de la règle, et une base qui ne se porte nulle part
		# n'accepte aucun affixe, pas même universel. Interrogé sur `fits()` seul,
		# ce document annonçait qu'un manuel pouvait recevoir de la dextérité —
		# une référence qui décrit autre chose que le tirage est pire qu'aucune
		# référence.
		var eligible := 0
		for other in ItemCatalog.ALL:
			if ItemAffixPool.compatibles(other).has(a):
				eligible += 1
		l.append("| `%s` | %s%s | %s | %s | %d | %d | %d / %d |" % [
			a.id,
			StatMod.name(a.stat, a.scope),
			" (%)" if a.percent else "",
			", ".join(a.tags) if a.tags.size() > 0 else "*partout*",
			", ".join(a.excludes) if a.excludes.size() > 0 else "—",
			a.weight,
			a.tiers.size(),
			eligible, ItemCatalog.ALL.size(),
		])
	l.append("")

	l.append("### Affixes d'ennemis")
	l.append("")
	l.append("| id | nom | PV | vitesse | dégâts | temps d'attaque | armure | vol de vie | exp |")
	l.append("|---|---|---|---|---|---|---|---|---|")
	for raw in AffixPool.ALL:
		var a: Affix = raw
		l.append("| `%s` | %s | ×%.2f | ×%.2f | ×%.2f | ×%.2f | +%.0f | %.0f %% | ×%.2f |" % [
			a.id, a.display_name, a.health_mult, a.speed_mult, a.damage_mult,
			a.attack_time_mult, a.armor, a.lifesteal * 100.0, a.xp_mult,
		])
	l.append("")
	l.append("Un affixe apparaît sur %.0f %% des ennemis, deux sur %.0f %%." % [
		AffixPool.CHANCE_ONE * 100.0, AffixPool.CHANCE_TWO * 100.0
	])
	l.append("")


## Le détail palier par palier. C'est la seule chose qu'on ne peut pas voir sans
## ouvrir un `.tres` — et celle qu'on veut sous les yeux pour équilibrer.
func _scales(l: PackedStringArray) -> void:
	l.append("## Échelles de paliers")
	l.append("")
	l.append("T1 est le meilleur. « ouvre à » est le niveau d'objet minimum du palier.")
	l.append("")
	for raw in _sorted_affixes():
		var a: ItemAffix = raw
		l.append("**`%s`** — « %s », %s, arrondi %s" % [
			a.id, a.suffix, StatMod.name(a.stat, a.scope),
			("%.2f" % a.rounded).trim_suffix("0").trim_suffix("0").trim_suffix("."),
		])
		l.append("")
		l.append("| palier | ouvre à | plage | poids |")
		l.append("|---|---|---|---|")
		for i in a.tiers.size():
			var t: ItemAffixTier = a.tiers[i]
			l.append("| T%d | %d | %s | %d |" % [
				i + 1, t.required_level, a.span(i), t.weight,
			])
		l.append("")


func _sorted_affixes() -> Array:
	var out := ItemAffixPool.ALL.duplicate()
	out.sort_custom(func(a: ItemAffix, b: ItemAffix) -> bool: return a.id < b.id)
	return out
