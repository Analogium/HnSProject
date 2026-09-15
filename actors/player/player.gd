class_name Player
extends CharacterBody2D

signal died
## Pour le HUD, par signal : vie et mana ne bougent qu'aux coups et à la régénération.
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal leveled_up(level: int)
## Les points d'attribut non dépensés ont changé — gagnés ou placés.
signal points_changed(restants: int)
signal equipment_changed

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas

## La ressource du disque, **jamais modifiée** (invariant 2).
@export var base_stats: CharacterStats

## Le personnage persiste : ni la mort ni le changement de zone ne remettent la
## progression à zéro.
const XP_BASE := 40.0
const XP_POWER := 1.5
## Points d'attribut par niveau, et **rien d'autre** : la progression passe par une
## grandeur que le joueur choisit.
const POINTS_PER_LEVEL := 3
## Soin partiel à la montée : complet, on chercherait à monter au milieu d'un paquet.
const LEVEL_HEAL := 0.30

## Les attaques de départ ne s'apprennent pas : leur table n'a qu'une entrée.
const POINTS_DES_ATTAQUES_DE_BASE := 1

## Jusqu'où un nuage ou un serpent se posent du personnage. Au-delà du curseur, on
## poserait hors de l'écran à la manette ; en deçà, on se jetterait dans le paquet.
const PORTEE_DE_POSE := 140.0
## Ce qui distingue une frappe lourde d'un coup d'épée au toucher, en plus du dessin.
const SECOUSSE_DE_FRAPPE := 2.0

## Durée pendant laquelle la hitbox est active. Réglable à chaud depuis l'arène.
@export var swing_duration: float = 0.12

@export_group("Tir")
## Moins de dégâts que le corps à corps, sans obliger à entrer dans la mêlée.
@export var bolt_scene: PackedScene
## Le tir de Boule de feu, qui explose à l'impact.
@export var boule_scene: PackedScene
## Secousse de caméra à l'impact. 0 pour la couper.
@export var shake_amount: float = 2.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var attack_pivot: Node2D = $AttackPivot
@onready var hitbox: Area2D = $AttackPivot/Hitbox
@onready var swing_arc: SwingArc = $AttackPivot/SwingArc
@onready var camera: Camera2D = $Camera2D

## Où atterrissent les tirs du joueur. Posé par la scène (zone ou arène) ;
## à défaut, ils naissent à côté du joueur.
var projectile_parent: Node2D

## La fiche de travail — disque, attributs, équipement —, **recalculée d'un bloc** et
## jamais retouchée : sinon les bonus s'accumulent.
var stats: CharacterStats

var level := 1
var xp := 0
var xp_to_next := 40

## Tenu ici : `stats` est reconstruite à chaque recalcul.
var allocated := CharacterStats.empty_attributes()
var unspent_points := 0

## Le sac porte son propre signal `changed`.
var inventory := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)

## Ce qui est porté, par emplacement. Un Item par entrée, ou rien.
var equipment := {}

## L'interface s'y branche, elle ne les possède pas.
var ratelier := Ratelier.new()
var barre := BarreDeCompetences.par_defaut()

## Le manuel de départ a-t-il déjà été donné à ce personnage.
var manuel_offert := false

## Ce que l'équipement donne aux compétences d'un mot-clé, reconstruit par
## `recompute_stats()` et lu à chaque lancer.
var mods_de_competence: Array[StatMod] = []

var health: float
var mana: float
var is_dead := false
## Ses états, comme ceux d'un ennemi.
var etats := Etats.new()
var facing := Vector2.RIGHT
## Une recharge par case : deux compétences voisines s'enchaînent.
var _recharges := PackedFloat32Array()
## Les cases tenues depuis un appui **né en jeu** : sinon le clic qui choisit une
## compétence dans le menu de la barre la lancerait aussitôt.
var _maintenues: Array[bool] = []
## Les parts du coup en cours, **tirées une fois au départ du geste** : tout l'arc
## reçoit la même valeur.
var _parts_du_coup: Array[float] = []
var _secousse_du_coup := 0.0
var _is_swinging := false
## L'aura allumée, ou null. Une seule : Immolation est la seule compétence entretenue.
var _aura: Immolation
var _couronne: CouronneDeLames
## Ce que la brûlure d'Immolation a pris depuis le dernier chiffre affiché.
var _brulure_a_montrer := Etats.Paquet.new()
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	_recharges.resize(BarreDeCompetences.EMPLACEMENTS)
	_maintenues.resize(BarreDeCompetences.EMPLACEMENTS)
	recompute_stats()
	xp_to_next = _needed_for(level)
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)
	hurtbox.etats = etats
	etats.change.connect(_montrer_les_etats)
	etats.atteint.connect(_annoncer_l_etat)
	etats.soin.connect(_soigner)


## La souris sert-elle à viser ? Pas déduit de sa position, qui bouge avec la caméra.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true
	elif event is InputEventJoypadButton:
		_aim_with_mouse = false
	elif event is InputEventJoypadMotion:
		# Seuil large : sinon la dérive du stick au repos rebascule la visée.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_aim_with_mouse = false


func _physics_process(delta: float) -> void:
	# Le gel ralentit la recharge des cinq cases ici, la marche plus bas.
	var cadence := etats.facteur_de_vitesse
	for i in _recharges.size():
		_recharges[i] = maxf(_recharges[i] - delta * cadence, 0.0)

	_regen(delta)
	_subir_les_etats(delta)
	if is_dead:
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	# Le sprite suit la visée, pas le déplacement : on recule face à l'ennemi.
	sprite.set_state(input != Vector2.ZERO, facing)

	var speed := stats.move_speed * cadence * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	# Sondage des cinq cases, sauf quand un panneau tient la souris. Tenue, la touche
	# relance à chaque fin de recharge : la cadence est celle de `lancer()`.
	for i in BarreDeCompetences.EMPLACEMENTS:
		var action := "competence_%d" % (i + 1)
		if Game.ui_grabs_input or not Input.is_action_pressed(action):
			_maintenues[i] = false
			continue
		if Input.is_action_just_pressed(action):
			_maintenues[i] = true
		if _maintenues[i]:
			lancer(i)


## Lance la compétence de cette case. **Le seul chemin** — touches, barre, tests — et
## il porte les cinq refus : case vide, non apprise, réserve, recharge, orbite pleine.
func lancer(index: int) -> bool:
	if is_dead or _recharges.size() <= index or _recharges[index] > 0.0:
		return false
	var competence := barre.competence_de(index)
	if competence == null:
		return false
	var points := points_de_competence(competence.id)
	if points <= 0:
		return false
	var geste := resoudre(competence, points)

	if competence.forme == Competence.Forme.AURA:
		# Tenir la touche n'alterne pas : une aura qui clignote serait inutilisable.
		_maintenues[index] = false
		if aura_allumee():
			# Éteindre n'est pas lancer : ni coût, la recharge seulement contre le rebond.
			_aura.eteindre()
			_aura = null
			_recharges[index] = geste.intervalle
			return true
	if mana < geste.cout_en_mana:
		return false
	# Refusée plutôt que de remplacer la plus ancienne : la touche tenue paierait pour
	# rien.
	if competence.forme == Competence.Forme.ORBITE and _couronne_de_lames().pleine(geste.maximum_simultane()):
		return false

	_set_mana(mana - geste.cout_en_mana)
	_recharges[index] = geste.intervalle
	# La forme de la compétence et non celle du geste : aucun nœud ne la change.
	match competence.forme:
		Competence.Forme.TRAIT:
			_tirer(geste, bolt_scene)
		Competence.Forme.BOULE:
			_tirer(geste, boule_scene)
		Competence.Forme.CHAINE:
			if ChaineDEclairs.decharger(_parent_des_effets(), self, geste, facing) > 0:
				Game.hit_stop()
				Game.shake_camera(camera, shake_amount)
		Competence.Forme.NUAGE:
			NuageDOrage.poser(_parent_des_effets(), _point_vise(), geste, etats)
		Competence.Forme.SERPENT:
			SerpentInfernal.lacher(_parent_des_effets(), _point_vise(), geste, facing, etats)
		Competence.Forme.AURA:
			_aura = Immolation.allumer(self, competence)
		Competence.Forme.ORBITE:
			_couronne_de_lames().ajouter(geste)
		Competence.Forme.FRAPPE:
			_swing(geste, SwingArc.Style.FRAPPE)
		Competence.Forme.CROIX:
			_swing(geste, SwingArc.Style.CROIX)
		_:
			_swing(geste)
	return true


func aura_allumee() -> bool:
	return is_instance_valid(_aura) and _aura.allumee()


## Combien d'épées tournent autour du personnage.
func epees_en_orbite() -> int:
	return _couronne.nombre() if _couronne != null else 0


## Ce qu'une aura coûte à son porteur cette image-ci, réparti entre les natures comme
## ses dégâts, chaque part par `CharacterStats.attenuer()`, engourdissement compris.
## **Pas un coup** : ni esquive ni plancher. L'armure se compte sur la perte **par
## seconde**, pas sur la tranche d'une image. Mortelle.
func bruler(part_par_seconde: float, repartition: Array[float], delta: float) -> void:
	if is_dead or part_par_seconde <= 0.0:
		return
	var par_seconde := stats.max_health * part_par_seconde
	var subie := 0.0
	for kind in repartition.size():
		subie += stats.attenuer(kind, par_seconde * repartition[kind])
	var perte := subie * etats.facteur_de_degats_subis * delta
	_set_health(health - perte)
	var chiffre := _brulure_a_montrer.ajouter(perte, delta)
	if chiffre > 0.0 and HitFeedback.current != null:
		HitFeedback.current.degats_sans_coup(hurtbox.global_position, chiffre, true)
	if health <= 0.0:
		_die()


## Ce que les états brûlent, ôté par le seul chemin de la vie.
func _subir_les_etats(delta: float) -> void:
	var perte := etats.avancer(delta)
	if perte <= 0.0:
		return
	_set_health(health - perte)
	var chiffre := etats.chiffre()
	if chiffre > 0.0 and HitFeedback.current != null:
		HitFeedback.current.degats_sans_coup(hurtbox.global_position, chiffre, true)
	if health <= 0.0:
		_die()


## Ce que sa pourriture lui rend.
func _soigner(montant: float) -> void:
	if not is_dead:
		_set_health(health + montant)


## Un état neuf s'annonce : la pastille seule ne dirait pas pourquoi on ralentit.
func _annoncer_l_etat(sorte: int) -> void:
	if HitFeedback.current != null:
		HitFeedback.current.etat(hurtbox.global_position, sorte)


func _montrer_les_etats() -> void:
	sprite.montrer_les_etats(etats)
	health_bar.montrer_les_etats(etats)


## Au curseur, à `PORTEE_DE_POSE` au plus ; à la manette, à cette distance devant.
func _point_vise() -> Vector2:
	var vers := facing * PORTEE_DE_POSE
	if _aim_with_mouse:
		vers = (get_global_mouse_position() - global_position).limit_length(PORTEE_DE_POSE)
	return global_position + vers


## Où naissent tirs, nuages et serpents ; à défaut d'un conteneur, à côté du joueur.
func _parent_des_effets() -> Node:
	return projectile_parent if projectile_parent != null else get_parent()


func _couronne_de_lames() -> CouronneDeLames:
	if _couronne == null:
		_couronne = CouronneDeLames.new()
		_couronne.auteur = etats
		add_child(_couronne)
	return _couronne


## **Le chemin du lancer et de la page du manuel** : fiche et modificateurs de mot-clé.
func resoudre(competence: Competence, points: int) -> StatsDeCompetence:
	return competence.resoudre(points, stats, mods_de_competence, talents_de(competence.id))


## Publique pour le voile de la barre.
func recharge_restante(index: int) -> float:
	return _recharges[index] if index >= 0 and index < _recharges.size() else 0.0


## Les points du manuel qui l'enseigne, ou l'unique point d'une attaque de départ ;
## zéro si son livre a quitté le râtelier.
func points_de_competence(id_competence: String) -> int:
	var livre := livre_de(id_competence)
	if livre != null:
		return livre.manuel.points_de(id_competence)
	if CompetenceCatalog.est_de_depart(id_competence):
		return POINTS_DES_ATTAQUES_DE_BASE
	return 0


## **Le seul endroit qui le cherche** : points et nœuds viennent du même livre.
func livre_de(id_competence: String) -> Item:
	for livre in ratelier.equipes():
		if livre.enseigne(id_competence):
			return livre
	return null


## Vides pour une attaque de départ, qui n'a pas de case.
func talents_de(id_competence: String) -> Array[TalentInvesti]:
	var livre := livre_de(id_competence)
	return livre.talents_investis(id_competence) if livre != null else [] as Array[TalentInvesti]


## **Le seul chemin** : un passif change la fiche, le recalcul ne s'oublie pas.
func investir(emplacement: int, identifiant: String) -> bool:
	var livre := ratelier.a(emplacement)
	if livre == null or livre.base.manuel == null:
		return false
	if not livre.manuel.investir(livre.base.manuel, identifiant):
		return false
	_after_equipment_change()
	return true


## Reprend un point d'une case, d'un passif ou d'un nœud — `Manuel` dit quand.
## Une compétence retombée à zéro sort de la barre, comme quand son livre part.
func reprendre(emplacement: int, identifiant: String) -> bool:
	var livre := ratelier.a(emplacement)
	if livre == null or livre.base.manuel == null:
		return false
	if not livre.manuel.reprendre(livre.base.manuel, identifiant):
		return false
	_vider_la_barre_de(livre.base.manuel.competences())
	_after_equipment_change()
	return true


## Ce qu'on peut poser dans une case de barre : les deux attaques de départ, et
## toute case des manuels à l'étude où l'on a mis au moins un point.
func competences_disponibles() -> Array[Competence]:
	var out: Array[Competence] = []
	for id: String in CompetenceCatalog.DE_DEPART:
		out.append(CompetenceCatalog.by_id(id))
	for livre in ratelier.equipes():
		for competence in livre.base.manuel.competences():
			if livre.manuel.points_de(competence.id) > 0:
				out.append(competence)
	return out


## Un coup par coup du geste — deux pour une croix —, chacun tiré, avec sa hitbox.
func _swing(geste: StatsDeCompetence, style := SwingArc.Style.ARC) -> void:
	_is_swinging = true
	_secousse_du_coup = shake_amount * (SECOUSSE_DE_FRAPPE if style == SwingArc.Style.FRAPPE else 1.0)
	swing_arc.play(swing_duration * float(geste.coups), style)
	sprite.attack()

	for coup in geste.coups:
		if coup > 0:
			# Un ennemi déjà dedans n'y *entre* pas deux fois : la hitbox doit être fermée une
			# image de physique avant de se rouvrir.
			await get_tree().physics_frame
		_parts_du_coup = geste.tirer(Game.rng)
		_already_hit.clear()
		# set_deferred : on est peut-être dans un rappel de physique.
		hitbox.set_deferred("monitoring", true)
		# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
		await get_tree().create_timer(swing_duration, true, false, true).timeout
		hitbox.set_deferred("monitoring", false)
	_is_swinging = false


## Les traits répartis sur l'écart du geste résolu : tout vient de
## `StatsDeCompetence`, rien n'est relu sur la compétence.
func _tirer(geste: StatsDeCompetence, scene: PackedScene) -> void:
	if scene == null:
		return
	var parent := _parent_des_effets()
	var nombre := geste.nombre_de_projectiles()

	# Un seul trait part droit devant, quelle que soit la dispersion.
	var ecart := deg_to_rad(geste.dispersion_en_degres)
	# Un cercle complet divise l'écart par le nombre de traits et non par les intervalles
	# — sinon le dernier retombe sur le premier —, décalé d'un demi-pas.
	var referme := is_equal_approx(ecart, TAU)
	var pas := 0.0
	var depart := 0.0
	if nombre > 1:
		pas = ecart / float(nombre if referme else nombre - 1)
		depart = -ecart * 0.5 + (pas * 0.5 if referme else 0.0)

	# Une fois pour la salve : la nature que le tir montre ne dépend pas du trait.
	var nature := geste.nature_dominante()
	for i in nombre:
		var direction := facing.rotated(depart + pas * float(i))
		# Un tirage par trait : trois traits identiques se liraient comme un seul coup.
		var tir := Projectile.spawn(
			parent, scene, global_position, direction, geste.tirer(Game.rng), self,
			geste.vitesse_de_projectile, nature
		)
		if tir is BouleDeFeu:
			(tir as BouleDeFeu).rayon_d_explosion = geste.rayon


## Testé avant d'écrire : une barre pleine n'émet rien.
func _regen(delta: float) -> void:
	if stats.health_regen > 0.0 and health < stats.max_health:
		_set_health(health + stats.health_regen * delta)
	if stats.mana_regen > 0.0 and mana < stats.max_mana:
		_set_mana(mana + stats.mana_regen * delta)


## Reconstruit la fiche **de zéro** : additionner compterait les bonus à chaque appel.
func recompute_stats() -> void:
	stats = base_stats.duplicate()
	for champ in CharacterStats.ATTRIBUTES:
		stats.set(champ, float(stats.get(champ)) + float(allocated[champ]))

	# Tous les objets d'un coup : les plats avant les pourcentages, quel que soit
	# l'ordre d'équipement.
	var mods: Array[StatMod] = []
	for slot in EquipmentSlots.ids():
		var item: Item = equipment.get(slot)
		if item != null:
			mods.append_array(item.mods())

	# Les passifs du râtelier, dans la même liste et le même tri que les objets.
	for livre in ratelier.equipes():
		mods.append_array(livre.mods_de_passifs())

	# En trois temps — attributs, dérivation, reste — pour que « +20 force » rapporte ses
	# PV et que « +10 % PV » les multiplie. Ce qui vise un mot-clé part à part, pour le
	# lancer.
	var sur_attributs: Array[StatMod] = []
	var sur_le_reste: Array[StatMod] = []
	var sur_les_competences: Array[StatMod] = []
	for m in mods:
		if not m.portee.is_empty():
			sur_les_competences.append(m)
		elif m.stat in CharacterStats.ATTRIBUTES:
			sur_attributs.append(m)
		else:
			sur_le_reste.append(m)
	StatMod.apply_all(stats, sur_attributs)
	stats.apply_attributes()
	StatMod.apply_all(stats, sur_le_reste)

	# La force ajoute ses dégâts aux attaques, lue sur la fiche **finale**.
	sur_les_competences.append(StatMod.fourchette(
		StatsDeCompetence.stat_ajoutee(DamageType.Kind.PHYSICAL),
		stats.degats_de_force(), stats.degats_de_force(), MotsCles.ATTAQUE
	))
	mods_de_competence = sur_les_competences

	# Une chance critique au-dessus de 1 ne veut rien dire, et le multiplicateur
	# sous 1 transformerait un critique en coup amorti.
	stats.crit_chance = clampf(stats.crit_chance, 0.0, 1.0)
	stats.crit_multiplier = maxf(stats.crit_multiplier, 1.0)

	# Réassignée : la hurtbox défendrait sinon avec l'ancienne fiche.
	hurtbox.stats = stats


## Fait entrer un personnage sauvegardé dans ce corps, après son _ready. **Recopie** et
## non adoption : sac, râtelier et barre restent ceux que l'interface a liés.
func charger(personnage: Personnage) -> void:
	if personnage == null:
		return

	level = maxi(personnage.niveau, 1)
	xp = personnage.experience
	xp_to_next = _needed_for(level)
	unspent_points = personnage.points_a_placer
	for champ in CharacterStats.ATTRIBUTES:
		allocated[champ] = int(personnage.attributs.get(champ, 0))

	inventory.clear()
	for pose in personnage.sac.placed:
		# Sa place d'abord : un sac rechargé se retrouve tel qu'on l'a laissé.
		if not inventory.place(pose.data, pose.cell):
			inventory.add(pose.data)

	equipment.clear()
	for emplacement in personnage.equipement:
		# Un emplacement inconnu est écarté : il fausserait la fiche sans s'afficher.
		if EquipmentSlots.exists(emplacement):
			equipment[emplacement] = personnage.equipement[emplacement]

	# Recopiés comme le sac, pour la même raison.
	for i in Ratelier.EMPLACEMENTS:
		ratelier.retirer(i)
		ratelier.poser(i, personnage.ratelier.a(i))
	for i in BarreDeCompetences.EMPLACEMENTS:
		barre.poser(i, personnage.barre.id_de(i))
	manuel_offert = personnage.manuel_offert

	sprite.set_variant(personnage.silhouette)
	# Recalcul, plafonds et arme visible : trois choses qu'on oublierait à la main.
	_after_equipment_change()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)

	# Sans ces signaux, HUD et fiche attendraient le premier ennemi tué.
	xp_changed.emit(xp, xp_to_next, level)
	points_changed.emit(unspent_points)


## L'inverse, avant l'écriture : rien de calculé.
func remplir(personnage: Personnage) -> void:
	if personnage == null:
		return
	personnage.niveau = level
	personnage.experience = xp
	personnage.points_a_placer = unspent_points
	for champ in CharacterStats.ATTRIBUTES:
		personnage.attributs[champ] = int(allocated[champ])
	personnage.silhouette = sprite.current_variant()

	personnage.sac = Inventory.new(inventory.cols, inventory.rows)
	for pose in inventory.placed:
		personnage.sac.place(pose.data, pose.cell)
	personnage.equipement = equipment.duplicate()

	personnage.ratelier = Ratelier.new()
	for i in Ratelier.EMPLACEMENTS:
		personnage.ratelier.poser(i, ratelier.a(i))
	personnage.barre = BarreDeCompetences.new()
	for i in BarreDeCompetences.EMPLACEMENTS:
		personnage.barre.poser(i, barre.id_de(i))
	personnage.manuel_offert = manuel_offert


## Porte un objet et rend celui qu'il remplace. `emplacement` vide : le premier libre
## (le ramassage) ; le panneau impose le sien. Rend l'objet lui-même s'il est refusé.
func equip(item: Item, emplacement := "") -> Item:
	if item == null:
		return null
	var cible := emplacement if not emplacement.is_empty() else EquipmentSlots.free_for(item, equipment)
	if cible.is_empty() or not EquipmentSlots.accepts(cible, item):
		return item
	var ancien: Item = equipment.get(cible)
	equipment[cible] = item
	_after_equipment_change()
	return ancien


## Le pendant d'`equip()` pour ce qui se lit : l'objet refusé est rendu. `index` à -1 :
## le premier emplacement libre, à défaut le premier.
func etudier(item: Item, index := -1) -> Item:
	if not Ratelier.accepte(item):
		return item
	var cible := index
	if cible < 0:
		cible = 0
		for i in Ratelier.EMPLACEMENTS:
			if ratelier.a(i) == null:
				cible = i
				break
	var ancien := ratelier.poser(cible, item)
	# Un manuel porte des passifs : le poser change la fiche.
	_after_equipment_change()
	return ancien


## Retire un manuel et **vide les cases de barre de ses compétences** : une case grisée
## se découvre au pire moment. Le seul chemin (page, rechargement).
func cesser_d_etudier(index: int) -> Item:
	var parti := ratelier.retirer(index)
	if parti == null or parti.base.manuel == null:
		return parti

	_vider_la_barre_de(parti.base.manuel.competences())
	# Et ses passifs s'en vont avec lui.
	_after_equipment_change()
	return parti


## « La sait-on encore », pas « d'où venait-elle » : un autre livre peut l'enseigner.
func _vider_la_barre_de(competences: Array[Competence]) -> void:
	for competence in competences:
		if points_de_competence(competence.id) > 0:
			continue
		for i in BarreDeCompetences.EMPLACEMENTS:
			if barre.id_de(i) == competence.id:
				barre.vider(i)


func unequip(slot: String) -> Item:
	var item: Item = equipment.get(slot)
	if item == null:
		return null
	equipment.erase(slot)
	_after_equipment_change()
	return item


func equipped(slot: String) -> Item:
	return equipment.get(slot)


## Place un point d'attribut, sans retour en arrière : une répartition défaisable serait
## un réglage, pas un choix.
func spend_point(attribut: String) -> bool:
	if unspent_points <= 0 or not allocated.has(attribut):
		return false
	allocated[attribut] += 1
	unspent_points -= 1
	recompute_stats()
	# Les plafonds ont bougé : force et intelligence montent PV et réserve.
	_set_health(health)
	_set_mana(mana)
	points_changed.emit(unspent_points)
	return true


## La fiche change, donc les plafonds : la vie courante redescend sous le nouveau. Un
## manuel passe par ici aussi, ses passifs étant une pièce d'armure.
func _after_equipment_change() -> void:
	recompute_stats()
	_set_health(health)
	_set_mana(mana)
	sprite.set_weapon(weapon_kind())
	equipment_changed.emit()


## L'arme visible, vide pour celle de la fiche. Publique : la fenêtre de personnage
## dessine la même silhouette.
func weapon_kind() -> String:
	var arme: Item = equipment.get("weapon")
	return "" if arme == null else arme.base.kind


## **Le seul chemin pour changer la vie** : la barre suit, le plafond s'applique.
func _set_health(value: float) -> void:
	health = clampf(value, 0.0, stats.max_health)
	health_bar.set_health(health, stats.max_health)
	health_changed.emit(health, stats.max_health)


## Le pendant du précédent pour la réserve, plafond compris.
func _set_mana(value: float) -> void:
	mana = clampf(value, 0.0, stats.max_mana)
	mana_changed.emit(mana, stats.max_mana)


func _needed_for(lvl: int) -> int:
	return Progression.cout_du_niveau(lvl, XP_BASE, XP_POWER)


## Appelée par l'EnemyManager quand un ennemi meurt d'un vrai coup.
func gain_xp(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	xp += amount
	# Une boucle et non un test : un ennemi qui vaut beaucoup peut faire monter
	# de deux niveaux d'un coup.
	while xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()
	xp_changed.emit(xp, xp_to_next, level)


func _level_up() -> void:
	level += 1
	xp_to_next = _needed_for(level)
	unspent_points += POINTS_PER_LEVEL
	points_changed.emit(unspent_points)
	recompute_stats()
	_set_health(health + stats.max_health * LEVEL_HEAL)
	_set_mana(mana + stats.max_mana * LEVEL_HEAL)
	leveled_up.emit(level)


## **Le seul chemin** d'une récompense, mort ou boule d'expérience : le retard sur la
## zone, puis le joueur et les manuels du râtelier, **du même montant**. Rien ne la
## borne vers le haut : descendre plus bas rapporte mieux.
func recompenser(brut: float, niveau_zone: int, ou: Vector2) -> int:
	var gain := maxi(roundi(brut * Enemy.facteur_d_experience(niveau_zone, level)), 1)
	gain_xp(gain)
	for livre in ratelier.equipes():
		livre.manuel.gagner_experience(gain)
	if HitFeedback.current != null:
		HitFeedback.current.xp_gain(ou, gain)
	return gain


## Faux quand le sac est plein : l'objet reste au sol.
func pick_up(item: Item) -> bool:
	if item == null:
		return false
	var pris := inventory.add(item)
	# Le livre de départ est « donné » quand il est **pris**, pas quand il tombe ; un
	# joueur qui le jette n'en reçoit pas un second.
	if pris and item.manuel != null:
		manuel_offert = true
	if HitFeedback.current != null:
		HitFeedback.current.loot_gain(
			global_position, item.display_name() if pris else Textes.t("sac plein")
		)
	return pris


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(stats, global_position, _parts_du_coup)
	info.auteur = etats
	(area as Hurtbox).take_damage(info)

	# **Au premier touché seulement** : un balayage est un geste, pas cinq.
	if _already_hit.size() == 1:
		Game.hit_stop()
		Game.shake_camera(camera, _secousse_du_coup)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	_set_health(health - info.amount)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		_die()


## Le drapeau évite plusieurs `died` : plusieurs grunts frappent dans la même image.
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	# Ce qui frappait pour lui s'éteint avec lui.
	if aura_allumee():
		_aura.eteindre()
	_aura = null
	if _couronne != null:
		_couronne.vider()
	# Un corps relevé ne se relève pas en flammes.
	etats.vider()
	died.emit()   # l'écran de fin de run se branchera ici


func revive() -> void:
	is_dead = false
	# Un corps tombé encaisse toujours : ses tirages ont pu reposer des états.
	etats.vider()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	velocity = Vector2.ZERO
	set_physics_process(true)
