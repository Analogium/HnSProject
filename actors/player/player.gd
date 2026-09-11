class_name Player
extends CharacterBody2D

signal died
## Vie et mana, pour l'affichage tête haute. Par signal et non lu à chaque image :
## les deux ne bougent qu'aux coups et à la régénération.
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

## La ressource du disque. **Jamais modifiée** : aucun `.tres` du projet n'est
## `resource_local_to_scene`, donc l'écrire toucherait le fichier lui-même et
## toutes les parties suivantes de la session.
@export var base_stats: CharacterStats

## Progression. Le personnage persiste : ni la mort ni le changement de zone ne
## les remettent à zéro.
const XP_BASE := 40.0
const XP_POWER := 1.5
## Points d'attribut gagnés par niveau. La montée ne donne **que** ça, pas de PV
## ni de dégâts bruts en plus : la progression passe par une grandeur que le
## joueur choisit, et trois sources demanderaient de les rééquilibrer ensemble.
const POINTS_PER_LEVEL := 3
## Soin partiel à la montée de niveau, jamais complet : à 100 % on chercherait à
## monter de niveau au milieu d'un paquet plutôt qu'à se battre.
const LEVEL_HEAL := 0.30

## Les deux attaques de départ ne s'apprennent pas : leur table de dégâts n'a
## qu'une entrée, et c'est celle-là qu'on demande. Écrit une fois pour qu'aucun
## appelant n'ait à deviner ce que « 1 » veut dire.
const POINTS_DES_ATTAQUES_DE_BASE := 1

## Durée pendant laquelle la hitbox est active. Réglable à chaud depuis l'arène.
@export var swing_duration: float = 0.12

@export_group("Tir")
## Attaque à distance. Moins de dégâts que le corps à corps, mais elle
## n'oblige pas à entrer dans la mêlée : c'est le compromis à régler.
@export var bolt_scene: PackedScene
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

## Copie de travail : la fiche du disque, plus les attributs placés, plus ce que
## l'équipement ajoute. Recalculée d'un bloc à chaque changement, jamais retouchée
## pièce par pièce — sinon les bonus s'accumuleraient à chaque recalcul.
var stats: CharacterStats

var level := 1
var xp := 0
var xp_to_next := 40

## Ce que le joueur a placé, par attribut. Tenu ici et non sur `stats`, qui est
## reconstruite de zéro à chaque recalcul et perdrait la répartition.
var allocated := CharacterStats.empty_attributes()
var unspent_points := 0

## Ce qu'on a ramassé, et où c'est rangé. Le sac porte son propre signal
## `changed`, auquel l'interface s'abonne directement.
var inventory := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)

## Ce qui est porté, par emplacement. Un Item par entrée, ou rien.
var equipment := {}

## Les manuels à l'étude, et les cinq cases à portée de doigt. Ils vivent sur le
## joueur comme le sac : l'interface s'y branche, elle ne les possède pas.
var ratelier := Ratelier.new()
var barre := BarreDeCompetences.par_defaut()

## Le manuel de départ a-t-il déjà été donné à ce personnage.
var manuel_offert := false

## Ce que l'équipement donne aux compétences qui portent un mot-clé : « +1
## projectile », « +20 % de dégâts de foudre ». Reconstruite d'un bloc par
## `recompute_stats()`, comme la fiche et pour la même raison, et lue à chaque
## lancer par `resoudre()`.
var mods_de_competence: Array[StatMod] = []

var health: float
var mana: float
var is_dead := false
var facing := Vector2.RIGHT
## Une recharge par case de la barre, et non une par sorte d'attaque : deux
## compétences posées côte à côte doivent pouvoir s'enchaîner, et la même
## compétence sur deux cases ne doit pas se recharger deux fois — ce que la
## barre interdit déjà en refusant les doublons.
var _recharges := PackedFloat32Array()
## Ce que le coup en cours inflige, **tiré une fois au départ du geste** : la
## hitbox s'ouvre une image plus tard, la case de barre aura pu changer
## entre-temps, et tous les ennemis de l'arc reçoivent la même valeur — un
## balayage qui fait 3 à l'un et 7 à l'autre dans la même image se lit comme un
## bug.
var _parts_du_coup: Array[float] = []
var _is_swinging := false
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


func _ready() -> void:
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	_recharges.resize(BarreDeCompetences.EMPLACEMENTS)
	recompute_stats()
	xp_to_next = _needed_for(level)
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)


## Quel périphérique sert à viser. À ne pas déduire de
## get_global_mouse_position(), qui bouge aussi quand la caméra suit le joueur —
## la souris paraîtrait constamment en mouvement.
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
	for i in _recharges.size():
		_recharges[i] = maxf(_recharges[i] - delta, 0.0)

	_regen(delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	# Le sprite suit la visée, pas le déplacement : dans un hack'n'slash on
	# recule en gardant l'ennemi en face, et voir le dos du joueur à ce
	# moment-là casse la lecture du combat.
	sprite.set_state(input != Vector2.ZERO, facing)

	var speed := stats.move_speed * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	# Les cinq cases sont lues par sondage, ce qui court-circuite le système
	# d'entrées de l'interface : sans ce test, chaque clic dans le sac lancerait
	# aussi la compétence de la première case.
	if not Game.ui_grabs_input:
		for i in BarreDeCompetences.EMPLACEMENTS:
			if Input.is_action_just_pressed("competence_%d" % (i + 1)):
				lancer(i)


## Lance la compétence de cette case, si elle en a une, qu'on l'a apprise, que la
## réserve suit et que la recharge est passée. **Le seul chemin** : les cinq
## touches, la barre à l'écran et les tests passent tous par ici, et aucun n'a à
## refaire une de ces quatre vérifications.
##
## Publique : c'est l'équivalent du `_swing()` d'avant pour les tests, et le
## point d'entrée d'une case cliquée le jour où la barre deviendra cliquable.
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
	if mana < geste.cout_en_mana:
		return false

	_set_mana(mana - geste.cout_en_mana)
	_recharges[index] = geste.intervalle
	# Le mot-clé et non la cadence : c'est lui qui dit ce que la compétence fait.
	# Un sort de zone sera une incantation sans être un tir.
	if competence.porte(MotsCles.PROJECTILE):
		_tirer(geste)
	else:
		_swing(geste)
	return true


## Ce que cette compétence fait lancée maintenant, avec ces points : la fiche du
## personnage et les modificateurs de mot-clé qu'il porte.
##
## **Le chemin du lancer et celui de la page du manuel.** Si chacun appelait
## `Competence.resoudre()` de son côté, l'un finirait par oublier la liste des
## modificateurs, et la page annoncerait un trait de moins que ce qui part.
func resoudre(competence: Competence, points: int) -> StatsDeCompetence:
	return competence.resoudre(points, stats, mods_de_competence)


## Ce qu'il reste à attendre sur cette case, en secondes, ou zéro. Publique parce
## que la barre dessine son voile dessus : elle lisait `_recharges` directement,
## et le jour où la recharge changera de forme elle se serait mise à mentir sans
## qu'aucun test ne le voie.
func recharge_restante(index: int) -> float:
	return _recharges[index] if index >= 0 and index < _recharges.size() else 0.0


## Combien de points ce personnage a dans cette compétence : ceux du manuel qui
## l'enseigne, ou l'unique point des deux attaques de départ, que personne
## n'apprend.
##
## Zéro pour une compétence dont le manuel a quitté le râtelier : elle ne fait
## alors plus rien du tout, ce qui est exactement ce qu'on veut — mais la barre
## vide sa case avant qu'on en arrive là.
func points_de_competence(id_competence: String) -> int:
	for livre in ratelier.equipes():
		if livre.enseigne(id_competence):
			return livre.manuel.points_de(id_competence)
	if CompetenceCatalog.est_de_depart(id_competence):
		return POINTS_DES_ATTAQUES_DE_BASE
	return 0


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


func _swing(geste: StatsDeCompetence) -> void:
	_parts_du_coup = geste.tirer(Game.rng)
	_is_swinging = true
	_already_hit.clear()
	swing_arc.play(swing_duration)
	sprite.attack()

	# set_deferred : on est dans un callback physique, on ne peut pas
	# modifier l'état de monitoring en direct.
	hitbox.set_deferred("monitoring", true)

	# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
	await get_tree().create_timer(swing_duration, true, false, true).timeout

	hitbox.set_deferred("monitoring", false)
	_is_swinging = false


## Un ou plusieurs projectiles, répartis sur l'écart que le geste résolu décrit.
## Nombre, écart, vitesse et dégâts viennent tous de `StatsDeCompetence` : le
## lanceur ne relit rien sur la compétence, sinon un modificateur de mot-clé
## changerait la fiche du manuel sans changer le tir.
func _tirer(geste: StatsDeCompetence) -> void:
	if bolt_scene == null:
		return
	var parent := projectile_parent if projectile_parent != null else get_parent()
	var nombre := geste.nombre_de_projectiles()

	# Un seul projectile part droit devant, quoi qu'annonce la dispersion : le
	# centrer sur un demi-écart le ferait tirer à côté de la visée. Pas et départ
	# restent donc nuls, et la rotation ne fait rien.
	var ecart := deg_to_rad(geste.dispersion_en_degres)
	# Le cercle complet se compte autrement que l'éventail : ses deux extrémités
	# se rejoignent, donc l'écart se divise par le nombre de traits et non par les
	# intervalles qui les séparent — sinon le dernier retomberait sur le premier.
	# Le demi-pas de décalage garde alors la couronne centrée sur la visée.
	var referme := is_equal_approx(ecart, TAU)
	var pas := 0.0
	var depart := 0.0
	if nombre > 1:
		pas = ecart / float(nombre if referme else nombre - 1)
		depart = -ecart * 0.5 + (pas * 0.5 if referme else 0.0)

	for i in nombre:
		var direction := facing.rotated(depart + pas * float(i))
		# Un tirage par trait : trois traits identiques au point près se liraient
		# comme un seul coup recopié.
		Projectile.spawn(
			parent, bolt_scene, global_position, direction, geste.tirer(Game.rng), self,
			geste.vitesse_de_projectile
		)


## Vie et mana remontent en continu. Testé avant d'écrire : une fois la barre
## pleine, écrire quand même émettrait un signal et redessinerait le HUD à chaque
## image.
func _regen(delta: float) -> void:
	if stats.health_regen > 0.0 and health < stats.max_health:
		_set_health(health + stats.health_regen * delta)
	if stats.mana_regen > 0.0 and mana < stats.max_mana:
		_set_mana(mana + stats.mana_regen * delta)


## Reconstruit les stats de zéro à partir de la ressource du disque. De zéro et
## non par incréments : additionner à la valeur courante compterait le bonus une
## fois de plus à chaque appel, et un objet retiré laisserait le sien derrière
## lui.
func recompute_stats() -> void:
	stats = base_stats.duplicate()
	for champ in CharacterStats.ATTRIBUTES:
		stats.set(champ, float(stats.get(champ)) + float(allocated[champ]))

	# Tous les objets d'un coup, et non emplacement par emplacement : c'est ce
	# qui permet d'appliquer les valeurs plates avant les pourcentages, donc
	# d'obtenir le même personnage quel que soit l'ordre d'équipement.
	var mods: Array[StatMod] = []
	for slot in EquipmentSlots.ids():
		var item: Item = equipment.get(slot)
		if item != null:
			mods.append_array(item.mods())

	# En trois temps, et l'ordre compte. Les attributs sont des **entrées** : ils
	# doivent être définitifs avant qu'on en dérive quoi que ce soit, sinon un
	# objet donnant « +20 force » ne rapporterait pas ses quarante points de vie.
	# Et la dérivation doit précéder le reste, pour qu'un « +10 % PV » multiplie
	# aussi ce que la force a donné.
	#
	# Ce qui vise un mot-clé part à part : il n'appartient pas à la fiche, et
	# `apply_all` l'écarterait de toute façon. Il est gardé pour le lancer.
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

	# La force ajoute ses dégâts physiques aux attaques, lue sur la fiche
	# **finale** : un anneau de force doit rapporter les siens.
	sur_les_competences.append(StatMod.fourchette(
		StatsDeCompetence.stat_ajoutee(DamageType.Kind.PHYSICAL),
		stats.degats_de_force(), stats.degats_de_force(), MotsCles.ATTAQUE
	))
	mods_de_competence = sur_les_competences

	# Une chance critique au-dessus de 1 ne veut rien dire, et le multiplicateur
	# sous 1 transformerait un critique en coup amorti.
	stats.crit_chance = clampf(stats.crit_chance, 0.0, 1.0)
	stats.crit_multiplier = maxf(stats.crit_multiplier, 1.0)

	# Réassignée à chaque recalcul, puisqu'on en fabrique une neuve : sans ça la
	# hurtbox continuerait de défendre avec l'ancienne fiche.
	hurtbox.stats = stats


## Fait entrer un personnage sauvegardé dans ce corps : progression, points
## placés, sac, équipement, silhouette.
##
## Recopie plutôt qu'adoption : le sac et l'équipement restent **ceux du joueur**,
## ceux que l'interface a liés à son ouverture. Leur substituer les objets venus de
## la sauvegarde laisserait le panneau afficher un sac qui n'est plus le bon.
##
## À appeler après le _ready du joueur.
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
		# Sa place d'abord : un sac rechargé doit se retrouver tel qu'on l'a
		# laissé, pas rangé automatiquement.
		if not inventory.place(pose.data, pose.cell):
			inventory.add(pose.data)

	equipment.clear()
	for emplacement in personnage.equipement:
		# Un emplacement inconnu est écarté et non porté : une sauvegarde peut
		# venir d'une version qui en avait un de plus, et il fausserait le calcul
		# des statistiques sans jamais s'afficher nulle part.
		if EquipmentSlots.exists(emplacement):
			equipment[emplacement] = personnage.equipement[emplacement]

	# Le râtelier et la barre se recopient comme le sac, et pour la même raison :
	# ce sont ceux du joueur que l'interface a liés à son ouverture, et leur
	# substituer les objets de la sauvegarde laisserait les panneaux branchés sur
	# des collections qui ne sont plus les bonnes.
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

	# L'interface s'accroche à ces signaux : sans eux le HUD garderait le niveau
	# 1 et la fiche annoncerait zéro point à placer jusqu'au premier ennemi tué.
	xp_changed.emit(xp, xp_to_next, level)
	points_changed.emit(unspent_points)


## L'inverse, juste avant d'écrire sur le disque. Rien de calculé n'y entre — ni
## PV, ni statistiques : elles se reconstruisent au chargement.
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


## Porte un objet et rend celui qu'il remplace, ou null. C'est l'interface qui
## décide du sort de l'ancien, pas le joueur.
##
## `emplacement` vide : le premier libre de la famille — le chemin du ramassage,
## où personne ne désigne de destination. Le panneau, lui, impose celui sur lequel
## l'objet a été lâché, sinon un anneau lâché sur la main droite irait à la gauche
## si elle est libre.
##
## Renvoie l'objet lui-même quand il ne peut pas être porté, pour que l'appelant
## ne le perde jamais.
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


## Met un manuel à l'étude et rend celui qu'il remplace, ou null. C'est le
## pendant d'`equip()` pour ce qui se lit au lieu de se porter, et il en garde la
## règle : **l'objet refusé est rendu tel quel**, jamais perdu.
##
## `index` à -1 : le premier emplacement libre, à défaut le premier — la règle
## des deux doigts du jalon 4, appliquée à trois livres.
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
	return ratelier.poser(cible, item)


## Retire un manuel du râtelier et le rend, **en vidant les cases de barre qui
## désignaient ses compétences**. Une case grisée qui annonce un sort inlançable
## se découvre au pire moment ; une case vide se voit tout de suite.
##
## Le seul chemin, donc le seul endroit où ce vidage est écrit : la page des
## manuels et le rechargement d'une sauvegarde passent tous deux par ici.
func cesser_d_etudier(index: int) -> Item:
	var parti := ratelier.retirer(index)
	if parti == null or parti.base.manuel == null:
		return parti

	for competence in parti.base.manuel.competences():
		# Un autre livre du râtelier peut enseigner la même chose : la question
		# est « la sait-on encore », pas « d'où venait-elle ». La réponse est lue
		# **après** le retrait, donc elle tient compte de ce qui reste.
		if points_de_competence(competence.id) > 0:
			continue
		for i in BarreDeCompetences.EMPLACEMENTS:
			if barre.id_de(i) == competence.id:
				barre.vider(i)
	return parti


func unequip(slot: String) -> Item:
	var item: Item = equipment.get(slot)
	if item == null:
		return null
	equipment.erase(slot)
	_after_equipment_change()
	return item


func equipped(slot: String) -> Item:
	return equipment.get(slot)


## Place un point dans un attribut. Renvoie faux si le nom est inconnu ou s'il ne
## reste rien à placer — l'interface n'a pas à vérifier d'avance.
##
## Sans retour en arrière : une répartition qu'on peut défaire n'est plus un choix,
## c'est un réglage, et rien n'empêcherait de tout mettre dans le même attribut
## avant chaque combat.
func spend_point(attribut: String) -> bool:
	if unspent_points <= 0 or not allocated.has(attribut):
		return false
	allocated[attribut] += 1
	unspent_points -= 1
	recompute_stats()
	# Les plafonds ont bougé : la force monte les PV maximum, l'intelligence la
	# réserve. Sans ce passage, la barre resterait sur l'ancien maximum.
	_set_health(health)
	_set_mana(mana)
	points_changed.emit(unspent_points)
	return true


## Les statistiques changent, donc les PV maximum aussi : retirer un plastron
## doit ramener la vie courante sous le nouveau plafond, sinon la barre déborde
## et le joueur garde des PV qu'il n'a plus.
func _after_equipment_change() -> void:
	recompute_stats()
	_set_health(health)
	_set_mana(mana)
	sprite.set_weapon(weapon_kind())
	equipment_changed.emit()


## L'arme visible. Vide quand rien n'est porté : le joueur reprend alors l'épée de
## sa fiche d'archétype plutôt que de se battre à mains nues.
##
## Publique : la fenêtre de personnage dessine la même silhouette que le monde,
## arme comprise, et ne doit pas la déduire une seconde fois.
func weapon_kind() -> String:
	var arme: Item = equipment.get("weapon")
	return "" if arme == null else arme.base.kind


## Le seul chemin pour changer la vie : la barre suit chaque écriture, et il
## suffirait d'en oublier une pour qu'elle mente. Le plafond est appliqué ici
## aussi — un soin ou un plastron retiré ne doivent jamais laisser plus de PV que
## le maximum.
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


## Appelée par l'objet au sol quand le joueur lui passe dessus. Renvoie faux quand
## il ne reste pas de rectangle libre à sa taille : l'objet reste au sol, il ne
## doit pas s'évaporer parce que le sac est plein.
func pick_up(item: Item) -> bool:
	if item == null:
		return false
	var pris := inventory.add(item)
	# Le livre de départ est « donné » quand il est réellement **pris**, jamais
	# quand il tombe : une zone regénérée entre les deux effacerait sinon le seul
	# manuel du personnage. Et ce n'est pas déduit du contenu du sac — celui qui
	# jette le sien n'en reçoit pas un second, le drapeau reste posé.
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
	(area as Hurtbox).take_damage(info)
	Game.hit_stop()
	if shake_amount > 0.0:
		Game.shake_camera(camera, shake_amount)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	_set_health(health - info.amount)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		_die()


## Le drapeau évite d'émettre died plusieurs fois : plusieurs grunts peuvent
## frapper dans la même image, et chaque coup relancerait un rechargement complet
## de la zone.
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	died.emit()   # l'écran de fin de run se branchera ici


func revive() -> void:
	is_dead = false
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	velocity = Vector2.ZERO
	set_physics_process(true)
