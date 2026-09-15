extends GutTest

## Les couloirs du jalon 13 (§4), sur la mesure du calcul. **Ils ne se corrigent pas en
## changeant leurs chiffres** : un couloir qui casse après un réglage est l'alerte que le
## banc existe pour donner. Hors de la suite par défaut : `tests/run.sh equilibrage`.

var _calcul: CalculDuBanc


func before_each() -> void:
	var joueur: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(joueur)
	_calcul = CalculDuBanc.new(joueur)


func after_each() -> void:
	_calcul = null


func _mesure(build: ProfilsDuBanc.Build, profil: int, construit_pour: int, jouee: int) -> CalculDuBanc.Mesure:
	return _calcul.mesurer(ProfilsDuBanc.personnage(build, profil, construit_pour), jouee)


func _lire(build: ProfilsDuBanc.Build, profil: int, m: CalculDuBanc.Mesure) -> String:
	return "%s %s en zone %d : %s (%.2f coups, survie %.1f s)" % [
		build.nom, ProfilsDuBanc.NOMS_DE_PROFIL[profil], m.zone,
		CalculDuBanc.NOMS_DE_VERDICT[m.verdict], m.coups_grunt, m.survie,
	]


func test_un_debutant_est_a_l_aise_en_zone_1() -> void:
	for build in ProfilsDuBanc.builds():
		var m := _mesure(build, ProfilsDuBanc.Profil.DEBUTANT, 1, 1)
		assert_eq(m.verdict, CalculDuBanc.Verdict.CONFORTABLE, _lire(build, ProfilsDuBanc.Profil.DEBUTANT, m))


func test_un_personnage_equipe_n_est_ni_trivial_ni_au_mur_dans_sa_zone() -> void:
	var profil := ProfilsDuBanc.Profil.EQUIPE
	for build in ProfilsDuBanc.builds():
		for zone in ProfilsDuBanc.ZONES:
			var m := _mesure(build, profil, zone, zone)
			assert_true(
				m.verdict in [CalculDuBanc.Verdict.CONFORTABLE, CalculDuBanc.Verdict.TENDU],
				_lire(build, profil, m)
			)


## Hors zone 1, où le Nu et le Débutant sont le même personnage.
func test_un_personnage_nu_est_tendu_dans_sa_zone() -> void:
	var profil := ProfilsDuBanc.Profil.NU
	for build in ProfilsDuBanc.builds():
		for zone in ProfilsDuBanc.ZONES.slice(1):
			var m := _mesure(build, profil, zone, zone)
			assert_eq(m.verdict, CalculDuBanc.Verdict.TENDU, _lire(build, profil, m))


func test_un_personnage_sur_equipe_ne_rencontre_pas_de_mur_dans_sa_zone() -> void:
	var profil := ProfilsDuBanc.Profil.SUR_EQUIPE
	for build in ProfilsDuBanc.builds():
		for zone in ProfilsDuBanc.ZONES:
			var m := _mesure(build, profil, zone, zone)
			assert_ne(m.verdict, CalculDuBanc.Verdict.MUR, _lire(build, profil, m))


func test_vingt_niveaux_plus_haut_rien_n_est_trivial() -> void:
	for build in ProfilsDuBanc.builds():
		for profil in ProfilsDuBanc.Profil.values():
			for zone in ProfilsDuBanc.ZONES:
				if zone + 20 > Game.NIVEAU_MAX:
					continue
				var m := _mesure(build, profil, zone, zone + 20)
				assert_ne(m.verdict, CalculDuBanc.Verdict.TRIVIAL, _lire(build, profil, m))
