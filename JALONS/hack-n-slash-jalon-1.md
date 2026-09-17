# Hack'n'slash top-down — Postulat et jalon 1

Document de cadrage et de démarrage. Godot 4, GDScript, pixel art top-down.

---

## 1. Postulat de base

### Le pitch

Un hack'n'slash top-down en pixel art, dans la lignée de Hero Siege : on incarne une
classe, on traverse des zones générées procéduralement, on nettoie des hordes
d'ennemis, on ramasse du loot, on monte en puissance.

### La boucle de jeu

```
Entrer dans une zone générée
    → nettoyer les paquets d'ennemis
        → ramasser le loot
            → s'équiper / monter de niveau
                → zone suivante, plus difficile
```

Tout le reste (arbre de talents, actes, boss, saisons) est une extension de cette
boucle. Si elle n'est pas satisfaisante à sec — juste courir, frapper, tuer — aucune
couche de contenu ne la sauvera.

### La sensation cible

Le cœur du genre, ce n'est ni la difficulté ni la profondeur du build. C'est le
**retour tactile du coup qui touche**. Trois choses le produisent, dans cet ordre
d'importance :

1. **Hit-stop** — le jeu se fige 40 à 80 ms au moment de l'impact
2. **Knockback** — l'ennemi est repoussé, il ne reste pas planté
3. **Feedback visuel** — flash blanc sur le sprite touché, particules, nombre de dégâts

Ces trois éléments sont dans le jalon 1. Ce ne sont pas de la finition tardive,
c'est le socle sur lequel tu jugeras tout le reste.

### Contraintes visuelles


| Paramètre           | Valeur                                                      |
| ------------------- | ----------------------------------------------------------- |
| Perspective         | Vue de dessus 3/4, tuiles carrées                           |
| Résolution de rendu | 640 × 360                                                   |
| Taille des tuiles   | 32 × 32                                                     |
| Hauteur des persos  | ~32 px                                                      |
| Palette             | Décor sombre et désaturé / effets et loot très saturés      |
| Contour             | Noir ou sombre sur toutes les entités (lisibilité en horde) |




### Périmètre du jalon 1

**Dedans :**

- Personnage jouable avec stats en `Resource`
- Déplacement 8 directions avec accélération
- Attaque de corps à corps avec hitbox, hit-stop, knockback
- Deux archétypes d'ennemis au comportement réellement différent
- Génération procédurale d'une zone au lancement
- Placement des ennemis par paquets sur la zone

**Explicitement dehors :**

- Loot, inventaire, progression, XP
- Menus, sauvegarde, audio
- Animations élaborées (un sprite statique suffit pour valider le game feel)
- Multijoueur
- Optimisation. Le code ci-dessous est conçu pour *pouvoir* être optimisé, pas
pour l'être déjà.

**Critère de réussite :** tu lances le jeu, une zone différente apparaît à chaque
run, tu traverses, tu frappes des ennemis, et taper est agréable.

---



## 2. Architecture



### Arborescence

```
res://
├── core/
│   ├── character_stats.gd      # Resource de stats
│   ├── damage_info.gd          # Paquet de dégâts
│   ├── hurtbox.gd              # Zone qui reçoit
│   └── game.gd                 # Autoload (hit-stop, RNG global)
├── actors/
│   ├── player/
│   │   ├── player.gd
│   │   └── player.tscn
│   └── enemies/
│       ├── enemy.gd            # Base commune
│       ├── grunt.gd            # Mêlée fonceur
│       ├── caster.gd           # Distance kiteur
│       ├── enemy_manager.gd    # Pilote tous les ennemis
│       └── *.tscn
├── world/
│   ├── map_generator.gd        # Automate cellulaire
│   ├── enemy_spawner.gd        # Placement par paquets
│   └── zone.tscn               # Scène principale
└── resources/
    └── stats/                  # .tres : player, grunt, caster
```



### Le principe structurant

**Aucun ennemi n'a de** `_physics_process`**.** Leur logique vit dans une méthode
`tick(delta)` appelée par un `EnemyManager` unique.

Ça ne coûte rien à écrire aujourd'hui, et ça te donne gratuitement, plus tard :

- le culling par distance (ne ticker que ce qui est proche de la caméra)
- le passage aux tableaux packés le jour où le profileur le demande
- le ralenti / pause / debug step sur les ennemis seuls

Si tu ne fais qu'une chose de ce document, fais celle-là.

### Réglages projet

```
Display > Window > Viewport Width           640
Display > Window > Viewport Height          360
Display > Window > Stretch > Mode           viewport
Display > Window > Stretch > Aspect         keep
Rendering > Textures > Default Texture Filter   Nearest
Rendering > 2D > Snap 2D Transforms to Pixel    on
Rendering > 2D > Snap 2D Vertices to Pixel      on
```



### Layers de collision


| Layer | Usage           |
| ----- | --------------- |
| 1     | Décor (murs)    |
| 2     | Joueur (corps)  |
| 3     | Ennemis (corps) |
| 4     | Hurtbox joueur  |
| 5     | Hurtbox ennemis |
| 6     | Hitbox joueur   |
| 7     | Hitbox ennemis  |




### Input map

```
move_left    A, flèche gauche, joy axis 0-
move_right   D, flèche droite, joy axis 0+
move_up      W, flèche haut,   joy axis 1-
move_down    S, flèche bas,    joy axis 1+
attack       clic gauche, espace, joy bouton 2
```

---



## 3. Le socle : stats et dégâts



### `core/character_stats.gd`

Les stats sont une `Resource` et pas des variables exportées sur le personnage.
Trois raisons : tu les édites dans l'inspecteur sans toucher au code, tu crées un
`.tres` par type d'ennemi, et le jour où tu ajoutes des objets, les modificateurs se
composent sur la ressource sans rien casser.

```gdscript
class_name CharacterStats
extends Resource

@export var max_health: float = 100.0
@export var move_speed: float = 90.0

@export_group("Combat")
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.45
@export var attack_range: float = 28.0
@export var knockback_force: float = 180.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
```



### `core/damage_info.gd`

Le coup ne transporte pas qu'un nombre. Il transporte d'où il vient — sinon tu ne
peux pas calculer la direction du knockback.

```gdscript
class_name DamageInfo
extends RefCounted

var amount: float
var source_position: Vector2
var knockback: float
var is_crit: bool

func _init(
    p_amount: float,
    p_source: Vector2,
    p_knockback: float = 0.0,
    p_crit: bool = false
) -> void:
    amount = p_amount
    source_position = p_source
    knockback = p_knockback
    is_crit = p_crit


static func roll(stats: CharacterStats, source: Vector2) -> DamageInfo:
    var crit := randf() < stats.crit_chance
    var dmg := stats.attack_damage * (stats.crit_multiplier if crit else 1.0)
    return DamageInfo.new(dmg, source, stats.knockback_force, crit)
```



### `core/hurtbox.gd`

Une `Area2D` qui ne fait rien d'autre que relayer un signal. La logique de dégâts
appartient à l'acteur, pas à la zone.

```gdscript
class_name Hurtbox
extends Area2D

signal damaged(info: DamageInfo)

@export var invulnerable: bool = false

func take_damage(info: DamageInfo) -> void:
    if invulnerable:
        return
    damaged.emit(info)
```



### `core/game.gd` (autoload)

```gdscript
extends Node

var rng := RandomNumberGenerator.new()
var _hit_stop_active := false

func _ready() -> void:
    rng.randomize()


## Fige le jeu très brièvement à l'impact. C'est LE réglage du game feel :
## teste entre 0.03 et 0.10, tu sentiras la différence immédiatement.
func hit_stop(duration: float = 0.05) -> void:
    if _hit_stop_active:
        return
    _hit_stop_active = true
    Engine.time_scale = 0.02
    # 4e paramètre = ignore_time_scale, sinon le timer est figé lui aussi
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
    _hit_stop_active = false


func shake_camera(camera: Camera2D, amount: float = 3.0, duration: float = 0.15) -> void:
    var elapsed := 0.0
    while elapsed < duration:
        var falloff := 1.0 - (elapsed / duration)
        camera.offset = Vector2(
            rng.randf_range(-amount, amount),
            rng.randf_range(-amount, amount)
        ) * falloff
        await get_tree().process_frame
        elapsed += get_process_delta_time()
    camera.offset = Vector2.ZERO
```

---



## 4. Le joueur



### Scène `player.tscn`

```
Player (CharacterBody2D)          layer 2, mask 1|3
├── Sprite2D
├── CollisionShape2D              CircleShape2D, rayon ~7
├── Hurtbox (Hurtbox)             layer 4, mask 7
│   └── CollisionShape2D
└── AttackPivot (Node2D)          tourne vers la direction visée
    └── Hitbox (Area2D)           layer 6, mask 5, monitoring off par défaut
        └── CollisionShape2D      CapsuleShape2D, décalée de ~20 px en x
```

Le `AttackPivot` est le point clé : c'est lui qui tourne, la hitbox reste fixe
dessus. Tu obtiens un arc de swing correct sans manipuler de transform à la main.

### `actors/player/player.gd`

```gdscript
class_name Player
extends CharacterBody2D

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas
const SWING_DURATION := 0.12

@export var stats: CharacterStats

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_pivot: Node2D = $AttackPivot
@onready var hitbox: Area2D = $AttackPivot/Hitbox

var health: float
var facing := Vector2.RIGHT
var _attack_cd := 0.0
var _is_swinging := false
var _already_hit: Array[Node] = []


func _ready() -> void:
    health = stats.max_health
    hitbox.monitoring = false
    hitbox.area_entered.connect(_on_hitbox_area_entered)
    hurtbox.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
    _attack_cd = maxf(_attack_cd - delta, 0.0)

    var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

    # La direction visée suit la souris si elle bouge, sinon l'input directionnel.
    var to_mouse := get_global_mouse_position() - global_position
    if to_mouse.length() > 4.0:
        facing = to_mouse.normalized()
    elif input != Vector2.ZERO:
        facing = input.normalized()

    attack_pivot.rotation = facing.angle()
    sprite.flip_h = facing.x < 0.0

    var speed := stats.move_speed * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
    if input != Vector2.ZERO:
        velocity = velocity.lerp(input.normalized() * speed, ACCEL)
    else:
        velocity = velocity.lerp(Vector2.ZERO, FRICTION)

    move_and_slide()

    if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
        _swing()


func _swing() -> void:
    _attack_cd = stats.attack_cooldown
    _is_swinging = true
    _already_hit.clear()

    # set_deferred : on est dans un callback physique, on ne peut pas
    # modifier l'état de monitoring en direct.
    hitbox.set_deferred("monitoring", true)

    await get_tree().create_timer(SWING_DURATION).timeout

    hitbox.set_deferred("monitoring", false)
    _is_swinging = false


func _on_hitbox_area_entered(area: Area2D) -> void:
    if not area is Hurtbox or area in _already_hit:
        return
    _already_hit.append(area)   # un swing ne touche une cible qu'une fois

    var info := DamageInfo.roll(stats, global_position)
    (area as Hurtbox).take_damage(info)
    Game.hit_stop(0.05)


func _on_damaged(info: DamageInfo) -> void:
    health -= info.amount
    velocity += (global_position - info.source_position).normalized() * info.knockback
    _flash()
    if health <= 0.0:
        _die()


func _flash() -> void:
    sprite.material.set_shader_parameter("flash_amount", 1.0)
    await get_tree().create_timer(0.08).timeout
    sprite.material.set_shader_parameter("flash_amount", 0.0)


func _die() -> void:
    set_physics_process(false)
    print("mort")   # à remplacer par l'écran de fin de run
```



### Shader de flash blanc

`ShaderMaterial` sur le `Sprite2D`, en `canvas_item` :

```glsl
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(mix(tex.rgb, vec3(1.0), flash_amount), tex.a);
}
```

C'est le retour visuel le plus rentable du jeu : quinze lignes, effet immédiat.
Mets le même matériau sur les ennemis.

---



## 5. Les ennemis



### `actors/enemies/enemy.gd` — la base

```gdscript
class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: CharacterStats

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox

var health: float
var target: Node2D
var is_dead := false


func _ready() -> void:
    health = stats.max_health
    hurtbox.damaged.connect(_on_damaged)
    # Volontairement désactivé : c'est l'EnemyManager qui pilote.
    set_physics_process(false)


func setup(p_target: Node2D) -> void:
    target = p_target


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
    pass


func _on_damaged(info: DamageInfo) -> void:
    if is_dead:
        return
    health -= info.amount
    velocity += (global_position - info.source_position).normalized() * info.knockback
    _flash()
    if health <= 0.0:
        die()


func die() -> void:
    if is_dead:
        return
    is_dead = true
    died.emit(self)
    queue_free()


func _flash() -> void:
    sprite.material.set_shader_parameter("flash_amount", 1.0)
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(self):
        sprite.material.set_shader_parameter("flash_amount", 0.0)
```



### Type 1 — `grunt.gd` : le fonceur

Il va droit sur toi et frappe au contact. C'est la masse. Individuellement inoffensif,
dangereux en nombre parce qu'il te bloque et t'encercle.

```gdscript
class_name Grunt
extends Enemy

const ACCEL := 0.08
const SEPARATION_RADIUS := 18.0
const SEPARATION_FORCE := 0.35

@export var contact_damage: float = 8.0

var _attack_cd := 0.0


func tick(delta: float) -> void:
    if target == null or is_dead:
        return

    var to_target := target.global_position - global_position
    var dist := to_target.length()
    var desired := to_target.normalized()

    # Séparation : sans ça les grunts se superposent en une bouillie illisible.
    desired += _separation() * SEPARATION_FORCE

    velocity = velocity.lerp(desired.normalized() * stats.move_speed, ACCEL)
    move_and_slide()

    _attack_cd = maxf(_attack_cd - delta, 0.0)
    if dist < stats.attack_range and _attack_cd <= 0.0:
        _attack_cd = stats.attack_cooldown
        var info := DamageInfo.new(contact_damage, global_position, 120.0)
        (target as Player).hurtbox.take_damage(info)


## Repousse les voisins proches. Approximation grossière mais suffisante :
## on interroge les corps déjà en contact plutôt que de faire une requête spatiale.
func _separation() -> Vector2:
    var push := Vector2.ZERO
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        var other := col.get_collider()
        if other is Enemy:
            var away: Vector2 = global_position - (other as Node2D).global_position
            if away.length() < SEPARATION_RADIUS:
                push += away.normalized()
    return push
```



### Type 2 — `caster.gd` : le kiteur à distance

Il maintient une distance, se décale latéralement, et tire. Il change complètement
ta façon de jouer : tu ne peux plus rester au milieu de la mêlée, il faut choisir des
cibles prioritaires.

**C'est ça, avoir deux types d'ennemis différents.** Deux mêlées avec des PV et des
dégâts différents, ce n'est qu'un seul type. La différence doit être comportementale,
et elle doit poser au joueur une question différente.

```gdscript
class_name Caster
extends Enemy

const ACCEL := 0.06

@export var projectile_scene: PackedScene
@export var preferred_distance: float = 150.0
@export var flee_distance: float = 95.0
@export var strafe_bias: float = 0.7

var _cast_cd := 0.0
var _strafe_dir := 1.0


func setup(p_target: Node2D) -> void:
    super(p_target)
    _strafe_dir = 1.0 if Game.rng.randf() < 0.5 else -1.0


func tick(delta: float) -> void:
    if target == null or is_dead:
        return

    var to_target := target.global_position - global_position
    var dist := to_target.length()
    var dir := to_target.normalized()

    var move := Vector2.ZERO
    if dist > preferred_distance:
        move = dir                                      # se rapproche
    elif dist < flee_distance:
        move = -dir                                     # recule
    else:
        move = dir.orthogonal() * _strafe_dir * strafe_bias   # tourne autour

    velocity = velocity.lerp(move * stats.move_speed, ACCEL)
    move_and_slide()

    _cast_cd = maxf(_cast_cd - delta, 0.0)
    if dist < preferred_distance * 1.4 and _cast_cd <= 0.0:
        _cast_cd = stats.attack_cooldown
        _fire(dir)


func _fire(dir: Vector2) -> void:
    var p := projectile_scene.instantiate()
    p.global_position = global_position + dir * 12.0
    p.setup(dir, stats.attack_damage, self)
    get_tree().current_scene.add_child(p)
```



### `actors/enemies/enemy_manager.gd`

```gdscript
class_name EnemyManager
extends Node2D

const CULL_DISTANCE := 700.0   # au-delà, on ne tick pas

var enemies: Array[Enemy] = []
var target: Node2D


func register(enemy: Enemy) -> void:
    enemy.setup(target)
    enemy.died.connect(_on_enemy_died)
    enemies.append(enemy)


func _physics_process(delta: float) -> void:
    if target == null:
        return

    var origin := target.global_position
    var cull_sq := CULL_DISTANCE * CULL_DISTANCE

    # Parcours à l'envers : on peut retirer des éléments sans casser l'index.
    for i in range(enemies.size() - 1, -1, -1):
        var e := enemies[i]
        if not is_instance_valid(e) or e.is_dead:
            enemies.remove_at(i)
            continue
        if origin.distance_squared_to(e.global_position) > cull_sq:
            continue
        e.tick(delta)


func _on_enemy_died(enemy: Enemy) -> void:
    enemies.erase(enemy)
```

> **La migration future.** Le jour où tu dépasses ~500 ennemis, tu ne réécris pas le
> jeu : tu remplaces le contenu de `_physics_process` par une boucle sur des
> `PackedVector2Array` et tu passes le rendu en `MultiMeshInstance2D`. Les appelants
> ne changent pas. C'est précisément pour ça que la logique est ici et pas dans
> chaque ennemi.

---



## 6. Génération procédurale de la zone



### Le choix de l'algorithme

Trois familles possibles :


| Algorithme              | Résultat                        | Verdict                                                                                  |
| ----------------------- | ------------------------------- | ---------------------------------------------------------------------------------------- |
| BSP (salles + couloirs) | Donjon rectiligne               | Bon pour des intérieurs, mauvais pour du combat de horde : les couloirs cassent la mêlée |
| Marche aléatoire        | Tunnels serpentants             | Trop étroit, même problème                                                               |
| **Automate cellulaire** | Cavernes ouvertes et organiques | **Retenu** — grandes poches ouvertes, obstacles naturels                                 |


L'automate cellulaire donne exactement ce dont un hack'n'slash a besoin : de larges
espaces où l'on peut tourner autour des ennemis, ponctués d'obstacles qui cassent les
lignes de vue et créent des goulots.

### `world/map_generator.gd`

```gdscript
class_name MapGenerator
extends RefCounted

const WALL := 1
const FLOOR := 0

var width: int
var height: int
var fill_chance: float
var iterations: int

var grid: Array = []          # grid[y][x]
var floor_cells: Array[Vector2i] = []


func _init(p_width := 96, p_height := 96, p_fill := 0.45, p_iter := 5) -> void:
    width = p_width
    height = p_height
    fill_chance = p_fill
    iterations = p_iter


func generate(rng_seed: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = rng_seed

    _noise_fill(rng)
    for i in iterations:
        _smooth()
    _keep_largest_region()
    _collect_floor_cells()


## Bruit initial. Les bords sont forcés en mur pour fermer la zone.
func _noise_fill(rng: RandomNumberGenerator) -> void:
    grid = []
    for y in height:
        var row := []
        for x in width:
            var is_border := x < 2 or y < 2 or x >= width - 2 or y >= height - 2
            row.append(WALL if is_border or rng.randf() < fill_chance else FLOOR)
        grid.append(row)


## Règle 4-5 : un mur reste mur s'il a ≥4 voisins murs,
## un sol devient mur s'il a ≥5 voisins murs.
func _smooth() -> void:
    var next := []
    for y in height:
        var row := []
        for x in width:
            var walls := _count_wall_neighbours(x, y)
            if grid[y][x] == WALL:
                row.append(WALL if walls >= 4 else FLOOR)
            else:
                row.append(WALL if walls >= 5 else FLOOR)
        next.append(row)
    grid = next


func _count_wall_neighbours(cx: int, cy: int) -> int:
    var count := 0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            var x := cx + dx
            var y := cy + dy
            # Hors grille = mur : ça referme naturellement les bords.
            if x < 0 or y < 0 or x >= width or y >= height or grid[y][x] == WALL:
                count += 1
    return count


## Étape indispensable : l'automate produit des poches isolées.
## On garde la plus grande et on bouche le reste.
func _keep_largest_region() -> void:
    var visited := {}
    var best: Array[Vector2i] = []

    for y in height:
        for x in width:
            var key := Vector2i(x, y)
            if grid[y][x] != FLOOR or visited.has(key):
                continue
            var region := _flood_fill(key, visited)
            if region.size() > best.size():
                best = region

    var keep := {}
    for c in best:
        keep[c] = true

    for y in height:
        for x in width:
            if grid[y][x] == FLOOR and not keep.has(Vector2i(x, y)):
                grid[y][x] = WALL


func _flood_fill(start: Vector2i, visited: Dictionary) -> Array[Vector2i]:
    var region: Array[Vector2i] = []
    var queue: Array[Vector2i] = [start]
    visited[start] = true

    const NEIGHBOURS := [
        Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
    ]

    while not queue.is_empty():
        var cell: Vector2i = queue.pop_back()
        region.append(cell)
        for offset in NEIGHBOURS:
            var n: Vector2i = cell + offset
            if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height:
                continue
            if visited.has(n) or grid[n.y][n.x] != FLOOR:
                continue
            visited[n] = true
            queue.append(n)

    return region


func _collect_floor_cells() -> void:
    floor_cells.clear()
    for y in height:
        for x in width:
            if grid[y][x] == FLOOR:
                floor_cells.append(Vector2i(x, y))


## Point d'apparition : la case de sol la plus proche du centre de la carte.
func get_spawn_cell() -> Vector2i:
    var center := Vector2i(width / 2, height / 2)
    var best := floor_cells[0]
    var best_dist := 1 << 30
    for c in floor_cells:
        var d: int = (c - center).length_squared()
        if d < best_dist:
            best_dist = d
            best = c
    return best


func is_walkable(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
        return false
    return grid[cell.y][cell.x] == FLOOR
```



### Peindre dans le TileMapLayer

Deux `TileMapLayer` : un pour le sol, un pour les murs. Le layer mur porte la
physique (Physics Layer 1 dans le TileSet), le layer sol non.

```gdscript
func paint(gen: MapGenerator, floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
    floor_layer.clear()
    wall_layer.clear()

    for y in gen.height:
        for x in gen.width:
            var cell := Vector2i(x, y)
            if gen.grid[y][x] == MapGenerator.FLOOR:
                floor_layer.set_cell(cell, 0, _random_floor_tile())
            else:
                wall_layer.set_cell(cell, 0, Vector2i(0, 0))


## Variation visuelle : 85 % de tuile neutre, 15 % de variantes (fissures, cailloux).
func _random_floor_tile() -> Vector2i:
    if Game.rng.randf() < 0.15:
        return Vector2i(Game.rng.randi_range(1, 3), 0)
    return Vector2i(0, 0)
```

**Paramètres à régler.** `fill_chance` autour de 0.45 donne un bon équilibre : en
dessous de 0.40 la carte est un champ vide, au-dessus de 0.50 elle s'étrangle en
tunnels. `iterations` à 5 ; moins, c'est bruité, plus, ça lisse tout jusqu'à
l'ennui. Fais-toi un bouton de régénération à chaud pour les tester rapidement.

---



## 7. Placement des ennemis

Le placement uniforme est le piège du débutant : il donne un bruit constant
d'ennemis, sans rythme. **Les ennemis se placent par paquets**, avec du vide entre
les paquets. C'est ce qui crée l'alternance tension / respiration qui fait tout
l'intérêt de la traversée.

Un paquet mixte (des grunts qui foncent + un caster derrière) est bien plus
intéressant qu'un paquet homogène : tu dois décider si tu perces jusqu'au caster ou
si tu nettoies d'abord.

### `world/enemy_spawner.gd`

```gdscript
class_name EnemySpawner
extends Node

const TILE_SIZE := 32

@export var pack_count: int = 14
@export var pack_size_min: int = 3
@export var pack_size_max: int = 7
@export var pack_radius_tiles: int = 3
@export var min_distance_from_spawn_tiles: int = 8
@export var min_distance_between_packs_tiles: int = 6

@export var grunt_scene: PackedScene
@export var caster_scene: PackedScene

## Poids relatifs. Un caster pour ~3 grunts.
var _spawn_table: Array[Dictionary] = []


func _ready() -> void:
    _spawn_table = [
        {"scene": grunt_scene,  "weight": 75},
        {"scene": caster_scene, "weight": 25},
    ]


func populate(gen: MapGenerator, manager: EnemyManager, spawn_cell: Vector2i) -> void:
    var anchors := _pick_pack_anchors(gen, spawn_cell)

    for anchor in anchors:
        var size := Game.rng.randi_range(pack_size_min, pack_size_max)
        _spawn_pack(gen, manager, anchor, size)


## Choisit des centres de paquet suffisamment éloignés du joueur et entre eux.
func _pick_pack_anchors(gen: MapGenerator, spawn_cell: Vector2i) -> Array[Vector2i]:
    var anchors: Array[Vector2i] = []
    var min_from_spawn_sq := min_distance_from_spawn_tiles ** 2
    var min_between_sq := min_distance_between_packs_tiles ** 2

    var attempts := 0
    var max_attempts := pack_count * 40

    while anchors.size() < pack_count and attempts < max_attempts:
        attempts += 1
        var cell: Vector2i = gen.floor_cells[Game.rng.randi() % gen.floor_cells.size()]

        if (cell - spawn_cell).length_squared() < min_from_spawn_sq:
            continue

        var too_close := false
        for a in anchors:
            if (cell - a).length_squared() < min_between_sq:
                too_close = true
                break
        if too_close:
            continue

        anchors.append(cell)

    return anchors


func _spawn_pack(
    gen: MapGenerator,
    manager: EnemyManager,
    anchor: Vector2i,
    size: int
) -> void:
    var placed := 0
    var attempts := 0

    while placed < size and attempts < size * 12:
        attempts += 1
        var offset := Vector2i(
            Game.rng.randi_range(-pack_radius_tiles, pack_radius_tiles),
            Game.rng.randi_range(-pack_radius_tiles, pack_radius_tiles)
        )
        var cell := anchor + offset

        if not gen.is_walkable(cell):
            continue

        var enemy: Enemy = _pick_scene().instantiate()
        # +0.5 tuile : on vise le centre de la case, pas son coin.
        enemy.global_position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE

        manager.add_child(enemy)
        manager.register(enemy)
        placed += 1


func _pick_scene() -> PackedScene:
    var total := 0
    for entry in _spawn_table:
        total += entry["weight"]

    var roll := Game.rng.randi() % total
    for entry in _spawn_table:
        roll -= entry["weight"]
        if roll < 0:
            return entry["scene"]

    return _spawn_table[0]["scene"]
```



### `world/zone.gd` — l'assemblage

```gdscript
extends Node2D

const TILE_SIZE := 32

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var player: Player = $Player
@onready var enemy_manager: EnemyManager = $EnemyManager
@onready var spawner: EnemySpawner = $EnemySpawner

var generator: MapGenerator


func _ready() -> void:
    generate_zone(Game.rng.randi())


func generate_zone(zone_seed: int) -> void:
    generator = MapGenerator.new()
    generator.generate(zone_seed)

    paint(generator, floor_layer, wall_layer)

    var spawn_cell := generator.get_spawn_cell()
    player.global_position = (Vector2(spawn_cell) + Vector2(0.5, 0.5)) * TILE_SIZE

    enemy_manager.target = player
    spawner.populate(generator, enemy_manager, spawn_cell)


## Utile pendant le réglage : régénère la zone sans relancer le jeu.
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
        for child in enemy_manager.get_children():
            child.queue_free()
        enemy_manager.enemies.clear()
        generate_zone(Game.rng.randi())
```

Le `WallLayer` et le conteneur d'entités doivent avoir **Y-sort activé**, sinon les
personnages passeront devant et derrière les murs de façon incohérente.

---



## 8. Ordre de construction

Chaque étape doit être jouable et testée avant de passer à la suivante.

- [ ] **1. Réglages projet + input map.** Cinq minutes, mais tout le rendu en dépend.
- [ ] **2.** `CharacterStats`**,** `DamageInfo`**,** `Hurtbox`**, autoload** `Game`**.** Aucun visuel, c'est le socle.
- [ ] **3. Joueur qui se déplace** dans une scène de test avec quelques murs posés à la main. Règle `ACCEL` et `FRICTION` jusqu'à ce que ça te plaise — n'avance pas tant que c'est mou.
- [ ] **4. Mannequin d'entraînement** : un `StaticBody2D` avec une Hurtbox et le shader de flash.
- [ ] **5. Attaque CaC.** Fais varier `SWING_DURATION`, la taille de la hitbox, et surtout la durée du hit-stop. **C'est l'étape la plus importante du jalon.** Passes-y du temps.
- [ ] **6.** `Enemy` **+** `EnemyManager` **+** `Grunt`**.** Spawn manuel de 5 grunts, valide la séparation et le knockback.
- [ ] **7. Projectile +** `Caster`**.** Vérifie que sa présence change vraiment ta façon de jouer.
- [ ] **8.** `MapGenerator` avec affichage debug (des `ColorRect` suffisent). Règle `fill_chance` et `iterations` avant de brancher le TileSet.
- [ ] **9. Peinture TileMapLayer + Y-sort + collisions.**
- [ ] **10.** `EnemySpawner`**.** Règle `pack_count` et les distances jusqu'à obtenir un rythme de traversée agréable.

---



## 9. Après le jalon 1

Dans l'ordre de priorité, une fois la boucle validée :

1. **Nombres de dégâts flottants et particules d'impact** — le feedback qui manque le plus après le hit-stop
2. **Un troisième archétype** : le tank lent qui bloque, ou l'invocateur qui produit des grunts
3. **Loot** : table pondérée, raretés, faisceau coloré au sol
4. **Sortie de zone** et enchaînement des zones avec montée de difficulté
5. **Progression** : XP, niveaux, une première compétence active

Et le réflexe à prendre tout de suite : **une scène de stress test** avec un spawner
qui balance N ennemis d'un coup et le moniteur de performance ouvert. Tu sauras où
est ton vrai plafond au lieu de le supposer.