# Hack'n'slash top-down — jalon 2

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions. Ce document ne redit pas ce qui y est déjà écrit.

**Direction arrêtée le 3 septembre 2026 :** un ARPG à **personnage persistant**
(pas un roguelite à runs qui s'effacent), dans lequel la génération procédurale
des visuels n'est pas un pipeline d'assets mais **une règle de jeu** — un ennemi
porte sur lui ce qu'il est.

---

## 1. Périmètre du jalon 2

**Dedans :**

- Affixes sur les ennemis, avec teinte appliquée au sprite
- Expérience et niveaux du joueur
- Objets, butin au sol, et un inventaire
- Menu Échap avec des options, et barres de vie affichables

**Explicitement dehors :** enchaînement des zones, sauvegarde, classes, audio,
multijoueur, optimisation. Ils sont au jalon 3 ou plus loin.

**Critère de réussite :** repérer un ennemi bleu dans un paquet, savoir avant de
l'engager qu'il sera rapide, le tuer pour son butin, équiper ce butin, et sentir
la différence au coup suivant.

---

## 2. Le principe structurant du jalon

Un seul, et il conditionne tout le reste :

> **La forge dit l'identité. Le shader dit l'état.**

L'archétype d'un ennemi — sa silhouette, ses proportions, ses couleurs de base —
est calculé par `SpriteForge` et mis en cache pour la session. Son état du moment
— il flashe, il est affixé, il est gelé — est un uniforme de shader.

Se tromper de côté coûte cher. Générer une variante de sprite par combinaison
d'affixes ferait exploser le cache : cinq affixes donnent trente et une
combinaisons, multipliées par quatre archétypes et quatre variantes, soit près de
cinq cents jeux de vingt-quatre images. Une teinte de shader coûte un `vec3` et
ne dépend pas du nombre de combinaisons.

---

## 3. Affixes

### 3.1 Le modèle

`core/affix.gd` — une `Resource`, comme `CharacterStats`, pour la même raison :
un `.tres` par affixe, éditable dans l'inspecteur, sans toucher au code.

```gdscript
class_name Affix
extends Resource

@export var id: StringName
@export var display_name: String
## Teinte appliquée au sprite. C'est le seul canal par lequel le joueur
## apprend l'affixe : elle doit être franche et unique.
@export var tint: Color

@export_group("Multiplicateurs")
@export var health_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var cooldown_mult: float = 1.0
@export var xp_mult: float = 1.5
```

### 3.2 Le jeu d'affixes de départ

Cinq. Quatre sont de purs multiplicateurs — donc du contenu, pas du code — et un
seul demande un comportement. C'est délibéré : le système doit faire ses preuves
avant que les branches de comportement se multiplient.

| Affixe | Effet | Couleur du liseré |
|---|---|---|
| **Colossal** | +100 % PV, −20 % vitesse | terre brûlée `#944F1C` |
| **Véloce** | +45 % vitesse, −25 % PV | cyan `#54D8E0` |
| **Brutal** | +60 % dégâts, +20 % temps de recharge | rouge `#D8433A` |
| **Blindé** | dégâts reçus réduits d'un montant fixe | acier `#8C93A6` |
| **Vorace** | se soigne de 25 % des dégâts infligés | pourpre `#B0348C` |

Chaque effet tire dans une direction différente et **chaque affixe a une
contrepartie**. Un affixe sans contrepartie n'est pas un affixe, c'est une barre
de vie plus longue.

### 3.3 La règle de couleur

**Un liseré autour de la silhouette, pas une teinte du corps.** Repeindre le
sprite fait perdre la couleur de l'archétype : un grunt cyan ne se lit plus comme
un grunt, et on troque une information contre une autre au lieu d'en ajouter une.
Le liseré se pose à l'extérieur du contour noir que le rastériseur dessine déjà,
donc la couleur est séparée du corps par ce noir et les deux se lisent.

- **aucun affixe** → aucun liseré. Le mob ordinaire reste exactement tel que la
  forge l'a dessiné, sinon la couleur cesse de vouloir dire quelque chose ;
- **un affixe** → sa couleur, sur un pixel ;
- **deux affixes** → doré `#FACC4D`, la couleur réservée à l'élite, **sur deux
  pixels**. L'épaisseur se lit à une distance où la couleur ne se distingue plus.
  On perd l'information « lesquels » sur le corps, on la retrouve dans les noms
  empilés au-dessus de la tête.

Les noms d'affixes s'affichent en texte au-dessus de la barre de vie, chacun dans
la couleur de son affixe — c'est ce qui apprend au joueur à lire le liseré seul.
Leur **valeur** est relevée à 0,80 minimum : la couleur d'un liseré peut être
volontairement sombre, un texte sombre sur sol sombre ne se lit pas.

Tirage : 18 % d'un affixe, 4 % de deux. Deux affixes ne se cumulent jamais s'ils
sont opposés (Colossal et Véloce s'annuleraient).

### 3.4 Le shader

`core/flash.gdshader` gagne le liseré : un pixel vide au contact de la silhouette
prend la couleur. L'ordre compte — **le liseré d'abord, le flash par-dessus** :
un ennemi qui encaisse doit devenir blanc, quel que soit son affixe.

```glsl
uniform vec3 rim_color = vec3(1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.0;
uniform float rim_width : hint_range(1.0, 3.0) = 1.0;

// Un pixel vide au contact de la silhouette prend la couleur de l'affixe.
if (rim_amount > 0.0 && solid < 0.5) {
	vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
	float near = /* les quatre voisins, testés à step(0.5, alpha) */;
	if (near > 0.0) {
		c = rim_color;
		// max : là où le liseré recouvre l'ombre au sol, il ne doit pas la
		// rendre plus transparente qu'elle ne l'est.
		a = max(a, rim_amount);
	}
}
```

`tint_amount` autour de **0.35**, pas 1.0 : un aplat de couleur détruit le
modelé que le rastériseur a mis 0,265 ms par image à produire. On veut un mob
teinté, pas une silhouette peinte.

### 3.5 Deux règles non négociables

**Dupliquer les stats.** Aucun des `.tres` n'est `resource_local_to_scene` : tous
les grunts pointent sur le même objet. Un affixe appliqué en place multiplierait
les PV de *tous* les grunts de la session, et l'éditeur peut graver le résultat
dans le fichier.

```gdscript
if not affixes.is_empty():
	stats = stats.duplicate()   # avant toute multiplication, sans exception
```

**Tirer sur la zone, pas sur `Game.rng`.** Les affixes se déduisent de la case
d'apparition, comme la silhouette (`ActorSprite._pick()`) et le sens de rotation
du caster. Une même graine doit redonner exactement les mêmes ennemis affixés,
sinon la zone cesse d'être reproductible.

---

## 4. Expérience et niveaux

`Enemy` porte une valeur d'expérience dérivée de ses PV et de ses affixes — pas
une constante posée à la main, qui divergerait du jour où les stats bougent.

```gdscript
func xp_value() -> int:
	var v := stats.max_health * 0.35
	for a in affixes:
		v *= a.xp_mult
	return maxi(roundi(v), 1)
```

L'attribution passe par l'`EnemyManager`, qui connaît déjà la cible. `die()`
prend un paramètre :

```gdscript
func die(award := true) -> void:
```

`kill_all()` passe `false`. Sans ça, la touche K de débogage et la scène de
stress feraient monter le joueur de dix niveaux par erreur.

Courbe : `xp_pour_niveau_suivant = 40 * level^1.5`, arrondi. À la montée de
niveau, +8 PV max, +1 dégât, et **soin partiel** — pas complet, sinon monter de
niveau devient une potion gratuite au milieu d'un paquet.

Affichage : une barre fine en bas de l'écran et le numéro de niveau. C'est tout ;
un tableau de caractéristiques attendra qu'il y ait des caractéristiques à
regarder.

---

## 5. Objets et inventaire

### 5.1 L'icône est générée, comme le reste

Dans `SpriteForge` et non dans un fichier à part, contrairement à ce qui était
prévu : l'icône d'une arme est un appel à `_weapon()`, la fonction qui la pose
déjà dans la main d'un personnage. Une épée d'objet et l'épée que tient le joueur
sortent du même code — elles ne peuvent pas diverger. Le dessin est recadré sur
ce qu'il a réellement peint (donc centré par construction, sur son halo au sol
comme dans sa case), puis agrandi d'un facteur **entier** pour remplir son
emplacement.

### 5.2 Le modèle

```gdscript
class_name ItemData
extends Resource

@export var display_name: String
@export var rarity: int          # 0 commun, 1 magique, 2 rare
@export var slot: StringName     # &"weapon", ou &"" pour un consommable
@export var kind: StringName     # &"sword", &"cleaver", ... pour l'icône
@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
```

### 5.3 Le butin

À la mort, une table pondérée tire un objet — **et elle lit ce que l'ennemi
portait**. Un Colossal lâche plus volontiers de la robustesse, un Véloce de la
vitesse, un élite lâche mieux. C'est ce qui donne une raison de choisir sa cible
dans un paquet plutôt que de frapper le plus proche.

Au sol : une `Area2D` avec l'icône et un faisceau coloré par rareté. Ramassage au
contact, comme un ARPG classique.

### 5.4 Les stats du joueur deviennent calculées

C'est le point d'architecture du jalon, et il répare un défaut existant : l'arène
de réglage écrit aujourd'hui directement dans `player.stats.knockback_force`,
c'est-à-dire dans la ressource partagée `player_stats.tres`.

```gdscript
## La ressource du disque, jamais modifiée.
@export var base_stats: CharacterStats
## La copie de travail : base + niveaux + objets équipés. Recalculée à chaque
## changement, jamais modifiée pièce par pièce — sinon les bonus s'accumulent
## silencieusement à chaque rééquipement.
var stats: CharacterStats
```

### 5.5 L'inventaire

Une grille de 10 × 5 sur le joueur, un panneau à la touche **I**, un seul
emplacement d'équipement pour commencer : l'arme. Ramasser range dans
l'inventaire ; équiper depuis l'inventaire remplace, et l'ancien objet retourne
dans la grille.

**Chaque objet occupe un rectangle de cases**, comme dans Path of Exile et Hero
Siege : une épée une colonne sur trois lignes, une baguette une sur deux, un
plastron deux sur trois. Ce n'est donc pas le nombre d'objets qui limite mais la
place qu'ils prennent, et ranger devient une décision plutôt qu'une formalité.

Le modèle vit dans `core/inventory.gd` — sans nœud ni dessin, donc testable seul.
Il tient une grille d'occupation en plus de la liste des objets : c'est elle qui
rend « est-ce que ça tient ici ? » immédiat pour chaque case survolée. Le panneau
ne détient rien, il lit le sac du joueur et le manipule.

À la souris : clic pour prendre, clic pour reposer, clic droit pour jeter au sol.
Un objet suivi par le curseur plutôt qu'un glisser maintenu — on tient parfois
une pièce plusieurs secondes, le temps de faire de la place. La case visée est
teintée en vert ou en rouge selon que l'objet y tient.

Deux règles pour qu'un objet ne disparaisse jamais : sac plein, il **reste au
sol** au lieu d'être avalé ; sac refermé la main pleine, l'objet revient à sa
place, ou à la première libre, ou par terre.

---

## 6. Menu Échap, options, barres de vie

### 6.1 Le menu

`ui/pause_menu.tscn`, un `CanvasLayer` en `PROCESS_MODE_WHEN_PAUSED` — sans ça
le menu se fige avec le jeu qu'il est censé mettre en pause. Ouverture sur
Échap : Reprendre / Options / Quitter.

Échap sert déjà de « retour » dans la forge, la carte de réglage et la scène de
stress. Pas de conflit : ce sont des aperçus de débogage, le menu n'existe que
dans la zone.

### 6.2 Les options

Un autoload `Settings`, distinct de `Game` qui est déjà l'état de la partie. Une
seule case à cocher pour l'instant :

```gdscript
signal changed
var show_health_bars := true
```

Le signal évite de faire interroger le réglage par trois cents barres à chaque
image.

### 6.3 Les barres

`ui/health_bar.gd`, un `Node2D` enfant de l'acteur, dessiné en `_draw()`.

Trois règles, dictées par le nombre d'ennemis à l'écran :

- **cachée à pleine vie** — sinon trois cents barres pleines encombrent l'écran
  sans rien dire ;
- **redessinée au changement de vie**, jamais à chaque image ;
- **coupée à la racine quand l'option est décochée** : `visible = false` et
  aucun `_process`, pas une barre transparente qui continue de coûter.

---

## 7. Ordre de construction

Chaque étape doit être jouable et testée avant la suivante.

- [x] **1. Menu Échap, autoload `Settings`, barres de vie.** Aucune dépendance,
      et ça pose la coquille d'interface où tout le reste viendra se brancher.
      Les barres rendent aussi les affixes lisibles à l'étape 3 — sans elles, on
      ne *voit* pas qu'un Colossal a le double de PV.
- [x] **2. Expérience et niveaux.** Le signal `died` existe déjà. Première boucle
      de progression, sans machinerie nouvelle.
- [x] **3. Affixes.** Demande la duplication des stats. C'est ici que le pari du
      jalon se joue : à valider sur une capture, au milieu d'un paquet, pas seul
      sur fond uni.
- [x] **4a. Objets, butin, inventaire.** Trois objets nus — une épée, une
      baguette, un plastron — dont l'icône est dessinée par la forge, pour les
      armes par la fonction même qui les pose dans la main d'un personnage.
      Chute à 20 %, multipliée par la quantité de butin de l'ennemi (+10 % par
      affixe). Ramassage au contact, sac de 10 × 5 à la touche **I**, où chaque
      objet occupe son rectangle de cases et se range à la souris.
- [ ] **4b. Équipement.** Un emplacement, l'arme. Ramasser équipe, l'ancien
      objet retourne dans le sac, et `recompute_stats()` reprend les bonus. Rien
      n'est encore fait : les deux objets n'ont volontairement aucun effet.

---

## 8. Ce qui peut mal tourner

- **Deux couleurs voisines ne se distinguent pas en 32 px.** Constaté : Colossal
  en ambre et l'élite en doré se confondaient. C'est la **valeur** qui sépare de
  façon fiable, pas la teinte — Colossal est passé en terre brûlée sombre.
- **Trop d'affixes visibles à la fois.** Deux au maximum, et le second passe par
  le doré. Un troisième marqueur en 32 px ne se lit pas.
- **Les ressources partagées.** Stats d'ennemis à l'affixage, stats du joueur à
  l'équipement. Le même piège, deux fois, dans le même jalon.
- **Le coût des barres de vie.** Trois cents `_draw()` par image ne sont pas
  gratuits. Relancer la scène de stress après l'étape 1, avant d'aller plus loin.
