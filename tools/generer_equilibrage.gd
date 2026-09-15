extends Node

## Écrit `docs/EQUILIBRAGE.md` : le calcul sur toute la grille, puis la simulation sur
## une sélection de cases. Lancé par `tools/equilibrage.sh` ; l'argument `calcul` saute
## la simulation. Une scène et non un `--script`, qui n'enregistrerait pas les autoloads.

const SORTIE := "user://EQUILIBRAGE.md"
const JOUEUR := preload("res://actors/player/player.tscn")

## La simulation joue chaque profil dans cette zone, et l'Équipé à ± l'écart.
const ZONE_SIMULEE := 40
const ECART_SIMULE := 20


func _ready() -> void:
	var l := PackedStringArray()
	_entete(l)
	_niveaux(l)

	var debut := Time.get_ticks_msec()
	var joueur: Player = JOUEUR.instantiate()
	add_child(joueur)
	var calcul := CalculDuBanc.new(joueur)
	for build in ProfilsDuBanc.builds():
		_grille(l, calcul, build)
	calcul = null
	joueur.free()
	print("calcul : %d ms" % (Time.get_ticks_msec() - debut))

	if "calcul" in OS.get_cmdline_user_args():
		l.append("## Simulation")
		l.append("")
		l.append("Non relancée : `tools/equilibrage.sh calcul`.")
	else:
		await _simulation(l)

	var f := FileAccess.open(SORTIE, FileAccess.WRITE)
	if f == null:
		push_error("Écriture impossible : %s" % SORTIE)
		get_tree().quit(1)
		return
	f.store_string("\n".join(l) + "\n")
	f.close()
	get_tree().quit()


func _entete(l: PackedStringArray) -> void:
	l.append("# Banc d'équilibrage")
	l.append("")
	l.append("<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->")
	l.append("")
	l.append("Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits")
	l.append("par les règles du jeu à chaque lancement (`ProfilsDuBanc`), et le calcul passe par")
	l.append("les vraies fonctions (`CalculDuBanc`). Le banc montre les écarts ; les réglages")
	l.append("restent une décision — voir `hack-n-slash-jalon-13.md`.")
	l.append("")
	l.append("| verdict | coups pour tuer un grunt | survie au contact |")
	l.append("|---|---|---|")
	l.append("| %s trivial | moins de %s | plus de %s s |" % [
		CalculDuBanc.PASTILLES[0], _n(CalculDuBanc.COUPS_TRIVIAL), _n(CalculDuBanc.SURVIE_CONFORTABLE)
	])
	l.append("| %s confortable | %s à %s | plus de %s s |" % [
		CalculDuBanc.PASTILLES[1], _n(CalculDuBanc.COUPS_TRIVIAL), _n(CalculDuBanc.COUPS_CONFORTABLE),
		_n(CalculDuBanc.SURVIE_CONFORTABLE)
	])
	l.append("| %s tendu | %s à %s | %s à %s s |" % [
		CalculDuBanc.PASTILLES[2], _n(CalculDuBanc.COUPS_CONFORTABLE), _n(CalculDuBanc.COUPS_TENDU),
		_n(CalculDuBanc.SURVIE_TENDUE), _n(CalculDuBanc.SURVIE_CONFORTABLE)
	])
	l.append("| %s mur | plus de %s | moins de %s s |" % [
		CalculDuBanc.PASTILLES[3], _n(CalculDuBanc.COUPS_TENDU), _n(CalculDuBanc.SURVIE_TENDUE)
	])
	l.append("")
	l.append("Le verdict est le pire des deux axes. Pour lire les nombres :")
	l.append("")
	l.append("- **coups** : avec la compétence de la barre qui en demande le moins, critique en")
	l.append("  moyenne, après les défenses de l'ennemi ;")
	l.append("- **secondes** : par `moyenne_par_seconde()`, *si tout touche* — les traits d'une")
	l.append("  nova comptent tous sur la même cible — et sans compter la réserve de mana ;")
	l.append("- **survie** : au contact de %d grunts et %d caster sans affixe, après armure," % [
		CalculDuBanc.GRUNTS_AU_CONTACT, CalculDuBanc.CASTERS_AU_CONTACT
	])
	l.append("  résistances et esquive, régénération déduite. ∞ : la régénération suffit.")
	l.append("")


## La colonne vertébrale de la grille : un profil « de la zone Z » a ce niveau.
func _niveaux(l: PackedStringArray) -> void:
	l.append("## Niveau attendu")
	l.append("")
	l.append("Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population")
	l.append("moyenne de l'`EnemySpawner` et le retard de `Enemy.facteur_d_experience()`.")
	l.append("")
	var entete := "| zone |"
	var ligne := "| niveau |"
	for zone in ProfilsDuBanc.ZONES:
		entete += " %d |" % zone
		ligne += " %d |" % ProfilsDuBanc.niveau_attendu(zone).x
	l.append(entete)
	l.append("|---|" + "---|".repeat(ProfilsDuBanc.ZONES.size()))
	l.append(ligne)
	l.append("")


func _grille(l: PackedStringArray, calcul: CalculDuBanc, build: ProfilsDuBanc.Build) -> void:
	var livre := ItemCatalog.by_id(build.manuel)
	l.append("## %s — %s, %s" % [build.nom, livre.display_name, StatMod.LABELS[build.attribut]])
	l.append("")
	var entete := "| profil |"
	for zone in ProfilsDuBanc.ZONES:
		entete += " zone %d |" % zone
	l.append(entete)
	l.append("|---|" + "---|".repeat(ProfilsDuBanc.ZONES.size()))

	var detail := PackedStringArray()
	for profil in ProfilsDuBanc.Profil.values():
		var ligne := "| %s |" % ProfilsDuBanc.NOMS_DE_PROFIL[profil]
		for zone in ProfilsDuBanc.ZONES:
			var m := calcul.mesurer(ProfilsDuBanc.personnage(build, profil, zone), zone)
			ligne += " %s |" % _case(m)
			detail.append(_detail(ProfilsDuBanc.NOMS_DE_PROFIL[profil], m))
		l.append(ligne)
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


func _case(m: CalculDuBanc.Mesure) -> String:
	return "%s %s · %s s" % [CalculDuBanc.PASTILLES[m.verdict], _n(m.coups_grunt), _n(m.survie)]


func _detail(nom: String, m: CalculDuBanc.Mesure) -> String:
	return "| %s | %d | %d | %s | %s | %s | %s | %s | %s | %s |" % [
		nom, m.zone, m.niveau, m.competence if not m.competence.is_empty() else "—",
		_n(m.coups_grunt), _n(m.coups_caster), _n(m.coups_colosse),
		_n(m.secondes_grunt), _n(m.secondes_colosse), _n(m.survie),
	]


## Chaque profil dans la zone simulée, l'Équipé de cette zone joué à ± l'écart.
func _simulation(l: PackedStringArray) -> void:
	l.append("## Simulation")
	l.append("")
	l.append("Un robot dans `world/zone.tscn`, graine %d, plafond de %d s de jeu : il marche vers" % [
		SimulationDuBanc.GRAINE, roundi(SimulationDuBanc.PLAFOND)
	])
	l.append("l'ennemi le plus proche et lance toute sa barre dès que la recharge le permet. Un joueur")
	l.append("médiocre, et c'est voulu : un plancher. Une mort recharge la zone.")
	l.append("")
	l.append("| build | profil | construit pour | zone jouée | niveau | tués/min | morts | sous 30 % | vidée en |")
	l.append("|---|---|---|---|---|---|---|---|---|")
	for build in ProfilsDuBanc.builds():
		var cases := []
		for profil in ProfilsDuBanc.Profil.values():
			var zone := 1 if profil == ProfilsDuBanc.Profil.DEBUTANT else ZONE_SIMULEE
			cases.append([profil, zone, zone])
		for ecart in [-ECART_SIMULE, ECART_SIMULE]:
			cases.append([ProfilsDuBanc.Profil.EQUIPE, ZONE_SIMULEE, ZONE_SIMULEE + ecart])
		for c in cases:
			var debut := Time.get_ticks_msec()
			var r: SimulationDuBanc.Resultat = await SimulationDuBanc.new().jouer(
				self, ProfilsDuBanc.personnage(build, c[0], c[1]), c[2]
			)
			print("simulation %s %s %d→%d : %d ms" % [
				build.id, ProfilsDuBanc.NOMS_DE_PROFIL[c[0]], c[1], c[2], Time.get_ticks_msec() - debut
			])
			l.append("| %s | %s | %d | %d | %d | %s | %d | %s s | %s |" % [
				build.nom, ProfilsDuBanc.NOMS_DE_PROFIL[c[0]], c[1], c[2], r.niveau,
				_n(r.tues_par_minute()), r.morts, _n(r.sous_la_vie_basse),
				"%s s" % _n(r.temps) if r.videe else "—",
			])
	l.append("")


## Deux décimales sous 10, une sous 100, aucune au-delà ; virgule décimale.
static func _n(x: float) -> String:
	if is_inf(x):
		return "∞"
	var texte := "%d" % roundi(x)
	if absf(x) < 10.0:
		texte = "%.2f" % x
	elif absf(x) < 100.0:
		texte = "%.1f" % x
	return texte.replace(".", ",")
