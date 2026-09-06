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
multijoueur, optimisation. Ils sont au jalon 3 ou plus loin — la sauvegarde y est
allée, voir `hack-n-slash-jalon-3.md`.

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

Deux classes, pas une — c'est le point d'architecture de la partie objets.

`ItemBase` (`.tres`, sur le disque) est le **type** : ce qui est vrai de toutes
les épées. Nom, dessin, emplacement, encombrement, et un **implicite** — le bonus
que porte la famille entière, sans tirage. Elle est partagée par tous les
exemplaires et n'est jamais écrite, comme `base_stats` chez le joueur.

`Item` (en mémoire) est l'**exemplaire** ramassé : une base, plus les affixes
tirés à sa création. Avant lui, le butin rendait directement la ressource du
disque : toutes les épées du jeu étaient le même objet, et y écrire un affixe
l'aurait écrit dans `epee.tres`.

```gdscript
class_name Item
var base: ItemBase
var explicits: Array[StatMod]    # 0 à 6, tirés à la création
```

`StatMod` — un champ de `CharacterStats`, à plat ou en pourcentage — décrit
aussi bien l'implicite d'une base qu'un affixe tiré : tout ce qui les lit n'a
qu'une forme à connaître. Les plats s'appliquent **avant** les pourcentages,
sinon deux objets identiques ne donnent pas le même résultat selon l'ordre
d'équipement.

**Chaque affixe déclare les emplacements où il peut sortir.** Une épée ne donne
pas de PV, une armure pas d'allonge : sans ce filtre, tous les objets se valent
et le type de base ne veut plus rien dire. Six affixes d'arme, quatre d'armure —
c'est la réserve de la base qui plafonne le tirage, pas la table des poids, donc
un plastron s'arrête à quatre lignes là où une épée peut en porter six.

**La rareté se déduit** du nombre d'affixes (0 commun, 1-2 magique, 3+ rare)
plutôt que d'être tirée à part : deux sources pour la même information finissent
par se contredire, et un objet doré sans affixe est un mensonge.

Mesuré sur 5000 objets réellement tombés : 47 % communs, 37 % magiques, 16 %
rares, 1,08 affixe par objet. Et sur 40 000 tirages, aucun affixe n'est jamais
sorti sur un emplacement qui ne l'admet pas.

### 5.3 Le butin

À la mort, une table tire une base au hasard puis ses affixes. Chute à 20 %,
multipliée par la quantité de butin de l'ennemi (+10 % par affixe porté).

**Abandonné :** la table devait *lire ce que l'ennemi portait* — un Colossal
lâchant plus volontiers de la robustesse, un Véloce de la vitesse. Décision du
4 septembre 2026 : le tirage reste uniforme. Lier le type de butin aux affixes
de la cible ajoute une règle à apprendre avant même qu'il y ait assez de types
d'objets pour qu'elle se remarque.

Au sol : une `Area2D` avec l'icône, et un halo à la couleur de rareté — de loin,
avant même de distinguer la forme, on sait si ça vaut le détour. Ramassage au
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

### 5.5 L'inventaire et l'équipement

Une grille de 10 × 5 sur le joueur, un panneau à la touche **I**, et deux
emplacements portés au-dessus : arme et torse. Un dictionnaire indexé par nom
d'emplacement, pas un champ par emplacement — ajouter les bottes ou l'anneau
n'est qu'une entrée de plus dans `Player.SLOTS`.

Clic droit pour porter, clic droit sur l'emplacement pour retirer : un seul
geste dans les deux sens, et il évite d'avoir à viser un emplacement avec un
objet en main. L'objet est **sorti du sac avant** d'être porté, ce qui garantit
que celui qu'il remplace trouve une place ; ce qui déborde vraiment tombe au
sol, plutôt que d'annuler l'échange qu'on vient de demander.

`recompute_stats()` repart toujours de la ressource du disque : un objet retiré
ne peut pas laisser son bonus derrière lui. Les PV courants sont ramenés sous le
nouveau plafond au passage — sinon retirer un plastron laisse une barre qui
déborde.

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
- [x] **4b. Équipement.** Deux emplacements — arme et torse — au-dessus du sac.
      Clic droit pour porter, clic droit sur l'emplacement pour retirer.
      `recompute_stats()` repart de la ressource du disque et applique implicites
      et affixes, les valeurs plates avant les pourcentages. L'arme portée se
      voit sur le personnage : la forge redessine ses planches avec elle.
- [x] **5. La fiche de personnage.** Décidée le 6 septembre 2026, après le
      jalon : la réserve d'affixes ne pouvait pas s'étoffer tant que le jeu
      n'avait que huit statistiques. Voir la section 9.

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
- **Une statistique sans source est une statistique morte.** Vraie deux fois :
  le mana sans rien à dépenser, et une résistance qu'aucun ennemi n'éprouve.
  C'est ce qui a décidé du coût en mana du tir et de l'élément du caster
  (section 9), plutôt que de poser cinq champs que personne n'exerce.


---

## 9. La fiche de personnage

Ajoutée le 6 septembre 2026, entre le jalon 2 et le jalon 3. La raison est
mécanique : la réserve d'affixes ne pouvait pas s'étoffer tant que le jeu n'avait
que huit statistiques à viser. Une épée à six affixes portait forcément les six
mêmes lignes — c'est la réserve qu'il fallait élargir, et pour ça il fallait
d'abord des statistiques à modifier.

Le jeu de statistiques est le classique du genre : vie, mana, armure, esquive,
cinq résistances, régénération de vie et de mana, vitesse d'attaque,
d'incantation et de déplacement.

### 9.1 Armure et esquive sont des notations, pas des points

L'armure retranchait des points fixes. Elle est devenue une **notation** :

```
réduction = armure / (armure + 5 × dégâts du coup)      plafond 90 %
```

Elle se lit par rapport à la taille du coup encaissé — beaucoup contre le
harcèlement, peu contre un gros coup. Des points plats ne s'échelonnent pas : à
bas niveau ils sont négligeables, à haut niveau ils rendent invulnérable, et il
n'y a pas de zone entre les deux. L'esquive suit la même famille de courbe
(`esquive / (esquive + 60)`, plafond 75 %) mais reste **binaire** : le coup est
évité ou il ne l'est pas. C'est cette irrégularité qui la distingue de l'armure ;
sans elle, les deux défenses seraient deux noms pour la même chose.

Les deux formules vivent dans `CharacterStats` et non dans la `Hurtbox` qui les
applique, parce que la fiche doit pouvoir annoncer « 42 d'armure, soit 46 %
contre un coup de 10 » sans réécrire la règle de son côté.

**Un coup passe toujours** : le plancher à 1 dégât reste, et les deux plafonds
existent pour la même raison — l'invulnérabilité est une impasse, pas une
difficulté.

### 9.2 Les natures de dégâts sont vivantes, pas décoratives

`DamageType` porte les six natures, leurs noms, leurs couleurs et le champ de
résistance de chacune. Une classe à part et non un enum posé dans `DamageInfo` :
`CharacterStats` doit nommer ses résistances par nature et `DamageInfo` nomme
déjà `CharacterStats`, donc les deux se référenceraient en rond.

**La couleur d'un dégât gagne sur toutes les autres**, y compris sur l'or du
critique : savoir par quoi on est touché est la seule information qu'on ne peut
pas déduire d'ailleurs, alors qu'un critique se reconnaît déjà à sa taille.
Elle est définie **une seule fois**, dans `DamageType.COLORS` — le nombre qui
s'envole, la gerbe d'éclats et la ligne de la fiche la partagent.

Décision du 6 septembre : les résistances devaient être **exercées tout de
suite**, pas attendre une future passe de contenu. Le tir du caster est donc du froid
et celui du joueur de la foudre, et les deux billes ont été repeintes dans leur
teinte. Conséquence voulue : **l'armure n'arrête pas les éléments**, donc le tir
est le recours contre un ennemi Blindé — un choix tactique là où il n'y en avait
aucun.

### 9.3 Le mana est une contrainte, pas une jauge

Le tir secondaire est devenu un sort : il coûte 6 de mana sur une réserve de 50
qui remonte de 4 par seconde, et sa cadence suit `cast_speed` là où l'épée suit
`attack_speed`. Huit tirs d'affilée, puis il faut alterner. Une réserve que rien
ne dépense n'aurait été qu'une barre décorative de plus.

`attack_cooldown` reste le rythme de base de l'arme ou de l'archétype ;
`attack_speed` et `cast_speed` sont les multiplicateurs portés par le
personnage. Les affixes visent les seconds : « +8 % de vitesse d'attaque » se
lit, « -7 % de temps de recharge » demande une conversion mentale à chaque fois.
L'affixe *Vif* et l'implicite de la baguette ont migré en conséquence — le jeu
n'a plus deux façons d'exprimer la même chose.

### 9.4 Ce qui n'a pas été fait

- **Aucun affixe nouveau.** Décision explicite : la réserve s'étoffera plus
  tard, maintenant qu'elle a de quoi viser. Le jalon 3 s'est finalement porté sur
  la persistance du personnage, donc l'élargissement de la réserve attend encore. *Cuirassé* vise la nouvelle notation
  d'armure et *Vif* la cadence, mais rien n'a été ajouté.
- **L'esquive n'a donc aucune source.** Elle est mesurée et jouable, mais aucun
  objet n'en donne encore. C'est le prix de la décision précédente, assumé.
- **Les ennemis ne régénèrent pas et n'ont pas de mana.** Les champs valent zéro
  par défaut : leur en donner serait une décision de design, pas un état par
  défaut.

---

## 10. Les attributs

Ajoutés le 6 septembre 2026, juste avant d'attaquer le jalon 3. Les trois
classiques du genre : **force, dextérité, intelligence**.

### 10.1 Ce ne sont pas des statistiques, ce sont des entrées

Un attribut ne fait rien par lui-même. Il est là pour qu'on en **dérive** des
statistiques réelles, et chacun en gouverne **deux** — une réserve et une
cadence. Un attribut qui n'en gouvernerait qu'une serait un alias pour la
statistique qu'il pilote, et autant modifier celle-ci directement.

| Attribut | Par point | Par point |
|---|---|---|
| Force | +2 PV max | +0,2 dégât d'attaque |
| Dextérité | +1,5 d'esquive | +0,4 point de % de vitesse d'attaque |
| Intelligence | +1,5 de mana max | +0,4 point de % de vitesse d'incantation |

Première calibration, à ajuster en jouant. À dix dans chaque — le départ — cela
vaut +20 PV, +2 dégâts, 15 d'esquive, +15 de mana et +4 % sur les deux cadences.

**La dextérité donne enfin une source à l'esquive**, qui n'en avait aucune depuis
sa création : elle était mesurée, testée, et strictement inatteignable en jouant.

Zéro par défaut sur `CharacterStats`, comme le mana : un grunt n'a pas
d'attributs, et lui en donner dix silencieusement lui offrirait vingt points de
vie que personne n'aurait décidés.

### 10.2 L'ordre du recalcul, en trois temps

C'est le seul point délicat, et il tombe faux dans les deux sens si on l'ignore :

1. **les modificateurs qui visent les attributs** — un objet « +20 force » doit
   être compté avant qu'on en dérive quoi que ce soit, sinon il ne rapporte pas
   les quarante points de vie qui vont avec ;
2. **la dérivation** ;
3. **tout le reste**, plats puis pourcentages — pour qu'un « +10 % PV »
   multiplie aussi ce que la force a donné.

`recompute_stats()` partitionne donc les modificateurs selon
`CharacterStats.ATTRIBUTES`. Deux tests gardent chacune des deux moitiés de la
règle, parce qu'inverser deux lignes suffirait à la casser sans que rien ne
plante.

### 10.3 Trois points par niveau, placés à la main

Les gains bruts de l'ancienne progression — `LEVEL_HEALTH` (+8 PV) et
`LEVEL_DAMAGE` (+1 dégât) par niveau — **ont disparu**. Ce sont les points qui
les remplacent : la progression passe désormais par une grandeur que le joueur
choisit, et garder deux sources automatiques en plus aurait demandé de
rééquilibrer les trois ensemble.

À assumer : la survie brute progresse moins vite qu'avant. Au niveau 10, les 27
points valent +54 PV s'ils vont tous dans la force, contre +72 automatiques
auparavant. `POINTS_PER_LEVEL` est le bouton.

**Pas de retour en arrière.** Une répartition qu'on peut défaire n'est plus un
choix, c'est un réglage, et il n'y aurait aucune raison de ne pas tout remettre
dans le même attribut avant chaque combat.

### 10.4 La fiche prend la souris, mais seulement quand il le faut

Un `[+]` apparaît au bout de chaque ligne d'attribut **tant qu'il reste des
points**. Le joueur lisant ses attaques par sondage, un clic sur un bouton
déclencherait aussi un coup d'épée : la fiche réclame donc la souris — mais
uniquement quand il y a quelque chose à cliquer. Le reste du temps elle reste
l'affichage passif qu'on peut laisser ouvert en se battant.

Le drapeau `Game.ui_grabs_input` est devenu un **ensemble** de demandeurs. En
simple booléen, refermer le sac alors que la fiche tient encore la souris le
remettait à faux, et le joueur se remettait à frapper en cliquant dans un
panneau.
