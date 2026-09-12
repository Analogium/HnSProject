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
	_manuels(l)
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
	l.append("%d bases d'objets, %d compétences, %d affixes d'objets, %d affixes d'ennemis." % [
		ItemCatalog.ALL.size(), CompetenceCatalog.ALL.size(),
		ItemAffixPool.ALL.size(), AffixPool.ALL.size()
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


## Ce que chaque manuel enseigne : ses cases, et l'arbre de chacune de ses
## compétences.
##
## C'est la partie du contenu qu'on ne peut pas regarder autrement qu'en ouvrant
## un `.tres` — vingt-sept nœuds répartis dans trois fichiers — et c'est celle
## qu'on veut sous les yeux pour équilibrer un arbre contre un autre.
func _manuels(l: PackedStringArray) -> void:
	l.append("## Manuels")
	l.append("")
	l.append("Un manuel gagne **un point par niveau**, %d au plafond" % Manuel.NIVEAU_MAX)
	l.append("(`Manuel.NIVEAU_MAX`), et ses cases, ses passifs et ses nœuds se servent")
	l.append("dans le même sac : la colonne « points » dit ce que chacun accepte, et leur")
	l.append("somme dépasse volontairement ce qu'un livre peut gagner.")
	l.append("")
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		if base.manuel == null:
			continue
		_un_manuel(l, base)


func _un_manuel(l: PackedStringArray, base: ItemBase) -> void:
	var arch := base.manuel
	var budget := 0
	l.append("### %s — `%s`" % [arch.nom, base.id])
	l.append("")
	l.append("| case | sorte | ouvre à | points | coût | recharge | traits | par point |")
	l.append("|---|---|---|---|---|---|---|---|")
	for case: CaseDeManuel in arch.cases:
		budget += case.points_max()
		if case.passif != null:
			l.append("| %s | passif | niveau %d | %d | — | — | — | %s |" % [
				case.passif.nom, case.passif.niveau_de_manuel_requis, case.passif.points_max,
				_par_point(case.passif.lignes)
			])
			continue
		var c := case.competence
		var table := PackedStringArray()
		for d in c.degats_par_point:
			table.append("%d" % roundi(d))
		l.append("| %s | %s %s | niveau %d | %d | %d mana | %s | %d | %s |" % [
			c.nom,
			"attaque" if c.cadence == Competence.Cadence.ARME else "sort",
			DamageType.NAMES[c.nature],
			c.niveau_de_manuel_requis,
			c.points_max(),
			roundi(c.cout_en_mana),
			"arme" if c.cadence == Competence.Cadence.ARME else "%.2f s" % c.recharge,
			c.projectiles,
			" · ".join(table),
		])
	l.append("")

	var noeuds := 0
	var lignes := PackedStringArray()
	for case: CaseDeManuel in arch.cases:
		for n: NoeudDeTalent in case.talents:
			noeuds += 1
			budget += n.points_max
			lignes.append("| %s | %s | %s | %s | %d | %s |" % [
				n.nom,
				case.competence.nom,
				"—" if n.parent.is_empty() else case.noeud_de(n.parent).nom,
				Textes.tn(
					"%d point de compétence", "%d points de compétence", n.points_requis
				) % n.points_requis,
				n.points_max,
				_effet_du_noeud(n),
			])
	if noeuds > 0:
		l.append("| nœud | compétence | parent | demande | points | par point |")
		l.append("|---|---|---|---|---|---|")
		l.append_array(lignes)
		l.append("")
	l.append("%d destinations de points pour %d gagnés." % [budget, Manuel.NIVEAU_MAX])
	l.append("")


## Les lignes d'un passif ou d'un nœud, telles qu'un objet les écrirait : c'est la
## même fonction qui les affiche en jeu, donc la référence ne peut pas annoncer
## autre chose que la page du manuel.
func _par_point(lignes: Array[LigneDeTalent]) -> String:
	var out := PackedStringArray()
	for ligne in lignes:
		out.append(ligne.modificateur(1).label())
	return " · ".join(out) if out.size() > 0 else "—"


func _effet_du_noeud(n: NoeudDeTalent) -> String:
	var out := PackedStringArray()
	if n.lignes.size() > 0:
		out.append(_par_point(n.lignes))
	if n.convertit():
		out.append("convertit %d %% en %s" % [
			roundi(n.part_convertie_par_point * 100.0), DamageType.NAMES[n.convertit_vers]
		])
	for id in n.mots_cles_ajoutes:
		out.append("donne le mot-clé %s" % MotsCles.LIBELLES.get(id, id))
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
				i + 1, t.niveau_requis, a.plage(i), t.poids,
			])
		l.append("")


func _tries() -> Array:
	var out := ItemAffixPool.ALL.duplicate()
	out.sort_custom(func(a: ItemAffix, b: ItemAffix) -> bool: return a.id < b.id)
	return out
