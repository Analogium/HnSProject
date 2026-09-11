extends Node

## Écrit `docs/CATALOGUE.md` à partir du catalogue et de la réserve d'affixes.
##
## Une référence **générée** et non tenue à la main : elle décrit soixante-six
## `.tres`, et une table recopiée à la main serait fausse à la première retouche
## d'équilibrage sans que rien ne le signale. Lancer `tools/catalogue.sh` après
## avoir touché un `.tres`.
##
## Une scène et non un `--script` : `--script` n'enregistre pas les autoloads, et
## la fenêtre de chute se lit contre `Game.NIVEAU_MAX`.
##
## Écrit dans `user://` : en jeu exporté `res://` n'est pas inscriptible, et
## c'est le lanceur qui rapatrie le fichier dans le dépôt.

const SORTIE := "user://CATALOGUE.md"


func _ready() -> void:
	var l := PackedStringArray()
	_entete(l)
	_bases(l)
	_affixes(l)
	_echelles(l)

	var f := FileAccess.open(SORTIE, FileAccess.WRITE)
	if f == null:
		push_error("Écriture impossible : %s" % SORTIE)
		get_tree().quit(1)
		return
	f.store_string("\n".join(l) + "\n")
	f.close()
	print("CATALOGUE écrit : ", ProjectSettings.globalize_path(SORTIE))
	get_tree().quit()


func _entete(l: PackedStringArray) -> void:
	l.append("# Référence des données")
	l.append("")
	l.append("<!-- Fichier généré par tools/catalogue.sh — ne pas éditer à la main. -->")
	l.append("")
	l.append("%d bases d'objets, %d affixes d'objets, %d affixes d'ennemis." % [
		ItemCatalog.ALL.size(), ItemAffixPool.ALL.size(), AffixPool.ALL.size()
	])
	l.append("")
	l.append("Deux règles ne se lisent dans aucun `.tres`, et il faut les avoir en tête")
	l.append("pour lire les tables :")
	l.append("")
	l.append("- **la colonne « tombe en zones » est calculée.** Une base tombe de son")
	l.append("  `niveau_requis` jusqu'à **%d niveaux** après l'ouverture du palier suivant" % ItemCatalog.MARGE_DE_RELEVE)
	l.append("  de sa lignée (`ItemCatalog.MARGE_DE_RELEVE`). Insérer un palier au milieu")
	l.append("  d'une lignée raccourcit donc celui d'avant ;")
	l.append("- **tous les paliers d'un affixe ne sortent jamais ensemble.** Un objet n'en a")
	l.append("  que **%d** d'ouverts à la fois — le meilleur qu'il atteint et les %d du" % [ItemAffix.PALIERS_OUVERTS, ItemAffix.PALIERS_OUVERTS - 1])
	l.append("  dessous (`ItemAffix.PALIERS_OUVERTS`). La colonne « ouvre à » des échelles")
	l.append("  donne le plancher, pas la garantie.")
	l.append("")
	l.append("Niveaux de zone : %d à %d." % [Game.NIVEAU_MIN, Game.NIVEAU_MAX])
	l.append("")


## Les bases, dans l'ordre du catalogue — par lignée, puis par palier — pour que
## les trois âges d'un même objet restent voisins.
func _bases(l: PackedStringArray) -> void:
	l.append("## Bases d'objets")
	l.append("")
	l.append("| id | nom | lignée | palier | famille | étiquettes | implicite | cases | tombe en zones |")
	l.append("|---|---|---|---|---|---|---|---|---|")
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		var imp := base.implicit()
		var f := ItemCatalog.fenetre_de_chute(base)
		var fenetre := "%d et au-delà" % f.x if f.y <= 0 else "%d à %d" % [f.x, f.y]
		l.append("| `%s` | %s | %s | %d | %s | %s | %s | %d × %d | %s |" % [
			base.id,
			base.display_name,
			base.lignee,
			base.palier,
			base.family if not base.family.is_empty() else "—",
			", ".join(base.tags),
			"—" if imp == null else imp.label(),
			base.grid_size.x, base.grid_size.y,
			fenetre,
		])
	l.append("")


## Les affixes d'objets, triés par identifiant : on vient en chercher un qu'on a
## en tête, et l'ordre de la réserve — thématique — ne se devine pas.
func _affixes(l: PackedStringArray) -> void:
	l.append("## Affixes d'objets")
	l.append("")
	l.append("`vise` vide veut dire « partout », sous réserve d'`interdit`, qui l'emporte.")
	l.append("")
	l.append("| id | statistique | vise | interdit | poids | paliers | bases éligibles |")
	l.append("|---|---|---|---|---|---|---|")
	for brut in _tries():
		var a: ItemAffix = brut
		# Par `compatibles()` et non par `fits()` : le filtre par étiquettes n'est
		# qu'une partie de la règle, et une base qui ne se porte nulle part
		# n'accepte aucun affixe, pas même universel. Interrogé sur `fits()` seul,
		# ce document annonçait qu'un manuel pouvait recevoir de la dextérité —
		# une référence qui décrit autre chose que le tirage est pire qu'aucune
		# référence.
		var eligibles := 0
		for autre in ItemCatalog.ALL:
			if ItemAffixPool.compatibles(autre).has(a):
				eligibles += 1
		l.append("| `%s` | %s%s | %s | %s | %d | %d | %d / %d |" % [
			a.id,
			StatMod.nom(a.stat, a.portee),
			" (%)" if a.percent else "",
			", ".join(a.tags) if a.tags.size() > 0 else "*partout*",
			", ".join(a.exclut) if a.exclut.size() > 0 else "—",
			a.weight,
			a.tiers.size(),
			eligibles, ItemCatalog.ALL.size(),
		])
	l.append("")

	l.append("### Affixes d'ennemis")
	l.append("")
	l.append("| id | nom | PV | vitesse | dégâts | recharge | armure | vol de vie | exp |")
	l.append("|---|---|---|---|---|---|---|---|---|")
	for brut in AffixPool.ALL:
		var a: Affix = brut
		l.append("| `%s` | %s | ×%.2f | ×%.2f | ×%.2f | ×%.2f | +%.0f | %.0f %% | ×%.2f |" % [
			a.id, a.display_name, a.health_mult, a.speed_mult, a.damage_mult,
			a.cooldown_mult, a.armor, a.lifesteal * 100.0, a.xp_mult,
		])
	l.append("")
	l.append("Un affixe apparaît sur %.0f %% des ennemis, deux sur %.0f %%." % [
		AffixPool.CHANCE_ONE * 100.0, AffixPool.CHANCE_TWO * 100.0
	])
	l.append("")


## Le détail palier par palier. C'est la seule chose qu'on ne peut pas voir sans
## ouvrir un `.tres` — et celle qu'on veut sous les yeux pour équilibrer.
func _echelles(l: PackedStringArray) -> void:
	l.append("## Échelles de paliers")
	l.append("")
	l.append("T1 est le meilleur. « ouvre à » est le niveau d'objet minimum du palier.")
	l.append("")
	for brut in _tries():
		var a: ItemAffix = brut
		var mode := StatMod.Mode.PERCENT if a.percent else StatMod.Mode.FLAT
		l.append("**`%s`** — %s, arrondi %s" % [
			a.id, StatMod.nom(a.stat, a.portee),
			("%.2f" % a.arrondi).trim_suffix("0").trim_suffix("0").trim_suffix("."),
		])
		l.append("")
		l.append("| palier | ouvre à | plage | poids |")
		l.append("|---|---|---|---|")
		for i in a.tiers.size():
			var t: ItemAffixTier = a.tiers[i]
			l.append("| T%d | %d | %s | %d |" % [
				i + 1, t.niveau_requis,
				StatMod.range_label(a.stat, mode, t.min_value, t.max_value),
				t.poids,
			])
		l.append("")


func _tries() -> Array:
	var out := ItemAffixPool.ALL.duplicate()
	out.sort_custom(func(a: ItemAffix, b: ItemAffix) -> bool: return a.id < b.id)
	return out
