# Hack'n'slash top-down — jalon 54

Suite des jalons 1 à 53. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 17 octobre 2026**, sur la branche `3d`, dans un worktree à part :
`../HnSProject-3d`, `config/name="HnSProject 3D"` (jamais le `user://` du jeu, donc
jamais ses personnages). La version 2D continue sur `master`, dans `HnSProject/`.
**À la fusion, `config/name` reste celui de `master`.**

---

## 1. Ce que l'utilisateur a demandé

- Changer le style visuel : « un style 3D comme Torchlight Infinite, le tout dans un
  style se rapprochant de Torchlight Infinite ».
- Le faire dans un dossier à part, « si ça ne plaît pas, j'aurai toujours la version
  actuelle ».
- « Quelque chose de fonctionnel qui pourra évoluer, pas de bric-à-brac juste pour que
  ça ressemble à quelque chose. »

## 2. La décision : tout en 3D, le jeu sur un plan

Les entités deviennent des `Node3D` — `CharacterBody3D`, `Area3D` — **à hauteur
verrouillée à 0**. Le gameplay ne change pas : Torchlight Infinite se joue à plat, la
3D est la façon de le montrer.

**Écarté : une simulation 2D recopiée par une vue 3D.** Moins chère au départ, elle
coupe chaque entité en deux moitiés, deux arbres et deux repères, pour toujours ; et
tout ce que la vue doit apprendre à la simulation (l'os de la main pour une traînée,
une ligne de vue contre un mur 3D, du relief) devient un aller-retour. Écartée aussi,
l'astuce d'une `Camera2D` écrasée sous une caméra orthographique : elle laissait
effets et sol en 2D couchés au sol, tout à jeter.

Ce que la 3D simplifie : plus de `z_index` ni de tri en Y — le tampon de profondeur
les remplace ; le visuel d'une compétence est un nœud enfant de sa compétence.

**Unité : 1 m = 16 px** de l'ancien repère (un personnage de ~27 px fait ~1,7 m).
Toutes les distances des `.tres` (portées, rayons, vitesses) sont en pixels : on les
convertit **en un seul endroit** à la lecture, ou on les réécrit en mètres. Mesuré à
l'ouverture de l'étape 1 : les pixels ne sont pas que dans les `.tres` (~70 champs), mais
aussi dans ~220 constantes du code et ~1 000 vecteurs des tests — une conversion « à la
lecture » en aurait demandé plus de 250. **Tranché le 17 octobre : pour l'étape 1, le monde
3D se mesure en pixels, 1 unité = 1 px.** Aucun chiffre du gameplay ne bouge, et la
campagne portée garde ses valeurs. Seul le visuel connaît les mètres, en un endroit : le
modèle posé ×16, caméra et lumière en pixels. **Le but final reste les mètres partout** :
un geste à part et mécanique — toutes les distances ÷ 16, la campagne pour filet —, une
fois le gameplay prouvé intact en 3D.

## 3. Ce qui ne bouge pas

`core/` (53 `Vector2`, presque tous dans `Hurtbox`), l'interface (`ui/`, des
`Control`), les `.tres`, l'équilibrage, la génération de la carte (une grille), les
icônes, la ville dans sa logique.

## 4. Le coût, mesuré

| | à porter |
|---|---|
| `Vector2` dans le code de jeu | ~1 100 (`actors/` 504, `ui/` 294 dont une part reste 2D, `art/` 224, `fx/` 169, `world/` 106) |
| `Vector2` dans les tests | ~900, sur 25 800 lignes |
| formes de collision | 80 `CircleShape2D`, 5 capsules, 2 rectangles |
| requêtes physiques | 4 `direct_space_state` |
| dessins de compétences | 44 `Node2D` de `actors/skills/` portent leur `_draw` |
| visée à la souris | 4 appels de monde à `get_global_mouse_position()` → une seule fonction, rayon contre le plan du sol |

## 5. Les étapes

Chaque étape livre du code définitif ; aucune ne pose d'échafaudage à démonter.

0. **Export `.glb` et premier regard.** `tools/blender_sheet.py <id> --glb` écrit
   `art/models/<id>.glb` : le corps gréé, `rest`, `walk` et les gestes de
   `gestes.json` cuits en actions par `pose_anim.py`, l'image d'impact en
   métadonnée ; les armes de `weapons.py` à part, accrochées à l'os de la main en jeu.
   Le **Vive lame** (le seul gréé par Mixamo) posé dans une scène à caméra et lumière
   façon Torchlight Infinite, capture sur le Bureau. **C'est le risque n°1** — les
   modèles Stable Fast 3D tiennent-ils une caméra proche et un éclairage dynamique ? —
   et on le lève avant de porter quoi que ce soit. L'outil et la lumière restent.
1. **La simulation en 3D, des capsules pour corps.** Zone, joueur, ennemis,
   projectiles, objets au sol, `Hurtbox`, `EnemyManager`, flow field (il reste une
   grille, lue en XZ). Les compétences gardent leur logique ; leur dessin s'éteint.
   **La campagne portée doit redonner les mêmes chiffres** : on change le type des
   vecteurs, jamais une valeur attendue. C'est la preuve que le gameplay n'a pas bougé.
2. **`ActorModel`**, le pendant 3D d'`ActorSprite`, **même interface** : `set_state`,
   `attack`, `impact_of`, `flash`, `set_rim`, `show_states`, `set_archetype`,
   `set_variant`, `current_variant`, `set_weapon` — les acteurs n'en appellent pas
   d'autre. La direction devient une rotation ; flash, liseré et teinte d'état, les
   uniformes d'un matériau en `next_pass`. Tous les acteurs de `tools/characters/`.
3. **Le monde** : sol, murs et décor bâtis depuis la grille de `MapGenerator`.
4. **Les effets**, compétence par compétence. **Une compétence sans dessin 3D montre
   le visuel générique de son élément** — le même principe que l'icône absente
   (« le champ vide reste un état normal »). `/dessiner-un-effet` est à réécrire
   pour la 3D avant la première.
5. **Lumière et post-traitement** pensés pour la 3D : le seuil de lueur de 0,9 et le
   plafond de 0,88 (`ArtPalette`, `blender_sheet.LIGHT_MAX`) tombent.

`docs/ARCHITECTURE.md` est réécrit au fil des étapes : ses invariants 2D (la lueur,
le tri en Y, `Hurtbox` en `Area2D`) mentiraient dès l'étape 1.

## 6. À trancher sur capture

- ~~Caméra perspective à focale étroite ou orthographique~~ — **tranché le 17 octobre :
  la façon Torchlight**, `proche-perspective` de `tools/look_3d.gd` : perspective, champ
  vertical de 30°, 20 m, inclinée de 45°. Elle montre moins de sol que l'écran 2D.
  **Recadrée le 17 octobre** sur une capture de Torchlight Infinite fournie par
  l'utilisateur : champ de 40°, inclinée de 55°, et le recul qui montre au plan du joueur
  le monde de la caméra 2D (360 px au zoom de 85 %, soit 582 unités) — les sprites
  gardent leur taille d'avant, les portées leur place à l'écran.
- L'interface, pensée à 640 × 360 en pixel art, à côté d'un monde net : à juger une
  fois le monde fait.
- La performance : remesurer `world/stress_test.tscn` après l'étape 2 (meshes
  skinnés). La zone jouée compte 69 ennemis ; les 935 du banc demanderont sans doute
  un `MultiMesh` ou des animations cuites dans les sommets.

## 7. Étape 0, faite le 17 octobre 2026

**L'outil.** `tools/blender_sheet.py <id> --glb` → `tools/blender/export_glb.py`, 4 s par
personnage. `rest` et `walk` y sont les boucles entières (la planche n'en gardait qu'une
image), chaque geste écrit dure **une seconde** : l'impact se lit en secondes, le jeu
règlera la vitesse. Deux choses ont dû bouger pour que le geste soit fait **d'os seuls** :

- `pose_anim.play()` porte maintenant le corps par les **hanches**, plus par l'objet
  armature — planche du balayage recomparée : identique au pixel, repères compris ;
- la main **tourne avec la lame** (`grip()`) : la cinématique inverse ne pliait que le
  bras, et l'arme suivait la cible, pas l'os.

**Écart avec §5 : les armes sont dans le `.glb` du personnage**, un nœud `weapon_<type>`
sous l'os de la main, pas un fichier par arme. La prise (où la main tient la poignée) et
la taille dépendent du corps ; posées dans Blender, elles arrivent justes à l'import, sans
réglage par personnage côté jeu. `set_weapon` n'aura qu'à en montrer une.

**Le regard** (`world/lighting.tscn`, `tools/look_3d.gd`, captures dans
`Bureau\hns-captures-modele-3d\`) : soleil chaud en haut à gauche côté caméra, ambiance
froide, ACES, SSAO, MSAA 4× posé par le scénario seul. Le Vive lame **et la sorcière**,
parce que le Vive lame est un modèle TRELLIS : le risque n°1 portait sur Stable Fast 3D.

- **Le Vive lame (TRELLIS) tient le gros plan** : visage, écharpe, gants lisibles.
- **La sorcière ne le tient pas** : le chapeau est un barbouillage de taches sarcelle,
  rouges et blanches, que la réduction à 38 px cachait. **Ce n'est pas Stable Fast 3D** :
  son modèle brut (`model_sf3d.glb`), posé à côté sous la même caméra, est propre. Les
  taches viennent de `blender/project.py`, qui repeint face et dos d'après deux images
  et donne au reste (le dessus du bord du chapeau, que la caméra à 45° voit en plein) la
  couleur la plus proche. Le dos deviné par Stable Fast 3D reste faux (la cape rose pâle).
- Les armes, des volumes pensés pour 36 px, font plastique sous une vraie lumière.
- Le sol est la texture 2D posée telle quelle : sa refonte est l'étape 3.

## 8. Après l'étape 0

- ~~Réparer `project.py`~~ — fait : il ne repeint que ce qui fait face à une image, le
  reste garde la texture de Stable Fast 3D ramenée au ton de la face. La sorcière est à
  refaire de toute façon (proportions).
- **Les proportions chibi n'ont plus de sens** dans un jeu façon Torchlight Infinite
  (remarque de l'utilisateur, 17 octobre). **Tranché sur planche le même jour** : la
  direction « Torchlight » — semi-réaliste, visage un peu anime, proportions adultes
  élancées —, parmi quatre (héroïque trapu, sombre réaliste, anime). Tirée par Qwen-Image,
  LoRA pixel art éteint. Tous les personnages sont à refaire depuis l'image source, le
  Vive lame d'abord : son image source (Qwen-Image sur fond vert, `model_3d.py image`) et
  son modèle Stable Fast 3D, face repeinte, et son gréage **local** sont faits : les
  articulations se lisent sur la silhouette en pose A (`model_3d.joints`), plus besoin de
  Mixamo. Captures dans `Bureau\hns-captures-vive-lame-adulte\`. En `.glb`, les armes
  gardent leur échelle (le ×1,4 n'était que pour 36 px).
  - **Les gestes sont à reprendre** : `gestes.json` a été écrit pour des bras chibi ; la
    garde tend le bras armé loin du corps, et les autres gestes sont à juger sur capture.
  - Les autres personnages suivent le même chemin : concept, `model_3d.py image`, `mesh
    --sf3d`, `rig`, `blender_sheet.py --glb`.

## 9. Étape 1 — le plan, écrit avant de porter (17 octobre)

Mesuré : ~23 000 lignes de jeu (`Vector2` : 634 `global_position`, 76 `from_angle`, 32
`angle()`, 32 `rotated`, 21 `orthogonal`), ~25 000 de tests (815 `Vector2` dans
l'intégration). Le jeu ne se lance pas tant que l'étape n'est pas finie.

**Conventions.**

- **1 unité = 1 px** (§2). Le plan de jeu est XZ : le `(x, y)` 2D devient `(x, 0, y)`. La
  caméra regarde depuis +Y et +Z : le bas de l'écran est +Z, comme le +y d'avant, et un
  angle 2D garde son sens — `Flat.from_angle(a)` vaut `(cos a, 0, sin a)`.
- **`Flat`** (`core/flat.gd`) est le seul utilitaire de plan : `from_angle`, `angle`,
  `rotated`, `orthogonal`, ce que `Vector3` n'a pas. Partout ailleurs, les méthodes de
  `Vector3` (`distance_to`, `normalized`, `lerp`…) servent telles quelles.
- **Hauteur verrouillée à 0** : `CharacterBody3D` (`axis_lock_linear_y`), `Area3D` et
  `Node3D` posés à y = 0.
- **Formes** : un cercle de rayon r devient une sphère de rayon r — les centres étant tous
  à y = 0, la collision est la même ; une capsule 2D, une `CapsuleShape3D` couchée dans le
  plan ; un rectangle, une boîte.
- **Murs** : des `StaticBody3D` bâtis depuis la grille de `MapGenerator`, épais de part et
  d'autre de y = 0 pour qu'un rayon à hauteur 0 les traverse.
- **Requêtes physiques** (4) : `PhysicsDirectSpaceState3D`, mêmes formes.
- **Visée** : une seule fonction, le rayon de la caméra par la souris contre le plan y = 0.
- **Caméra** : `Camera3D` sur le joueur, la façon Torchlight (§6) en pixels — champ de 40°,
  inclinée de 55°, le recul déduit du cadre 2D. La secousse passe par `h_offset` / `v_offset`.
- **Lumière** : `world/lighting.tscn`, ses distances passées en pixels.

**Ce qui s'affiche à la fin de l'étape.**

- **Écart avec §5 : pas de capsules.** `ActorSprite` passe en `AnimatedSprite3D`, en
  billboard, un pixel pour une unité : les acteurs montrent leurs planches debout dans le
  monde 3D. Il garde son interface **et ses données** — l'image d'impact des gestes, que la
  campagne vérifie ; une capsule les aurait laissées sans propriétaire. L'étape 2 le
  remplace par `ActorModel`, même interface. Flash, liseré et teinte passent en shader
  `spatial`.
- **L'affichage tête haute en espace écran** : barres de vie, nombres de dégâts, noms au
  sol, noms des objets de la ville sur un `CanvasLayer`, chacun posé par la projection de
  la caméra (`unproject_position`) ; survol et clic se testent à l'écran.
- **Les compétences et `fx/` gardent leur logique, leur dessin s'éteint** : `_draw` et
  `queue_redraw` retirés (l'étape 4 les redessine ; les anciens sont dans `master`). Les
  télégraphes ennemis aussi : le jeu se joue, moins lisible, jusqu'à l'étape 4.
- **Le sol** : un plan à la texture du biome ; décor et vrai sol, à l'étape 3.
- **Tri en Y et `z_index`** : supprimés, le tampon de profondeur les remplace.

**L'ordre**, du bas vers le haut, l'analyse statique (`--check-only`) à chaque palier :

1. `core/` : `Flat`, `Hurtbox` en `Area3D`, `DamageInfo.source_position`, `DeferredTree`,
   la secousse de `Game`.
2. `actors/skills/targets.gd` (les requêtes), projectiles, objets au sol, ennemis et
   `EnemyManager`, joueur.
3. Les 48 compétences.
4. `fx/`, `art/` (`ActorSprite`, `HealthBar`), `world/` (zone, murs, champ de chemin,
   peuplement, banc, arène), ce que `ui/` lit du monde.
5. Les tests : les positions du monde en `Vector3(x, 0, y)`, **aucune valeur attendue
   changée**. Un test qui casse est une régression du portage.
6. La campagne entière, puis le banc de performance remesuré (§6).

## 10. Étape 1, faite le 17 octobre 2026

Le jeu tourne en 3D sur un plan, mesuré en pixels (§2, §9). Ce qui a bougé en route :

- **`Flat`** porte aussi `cross`, `angle_to`, `xz`, `PX_PER_M`, et l'inverse de la visée,
  `on_screen()` : sans caméra, il rend le plan à plat — c'est ce qui laisse les tests des
  étiquettes, des nombres et des barres sur leurs chiffres.
- **`Hurtbox.overhead()` reste un point du plan au nord du corps**, comme en 2D : la marque
  du Paratonnerre s'y pose et cherche son héritier de là.
- **Les murs ont une demi-case de haut** : à une case, la caméra à 45° perdait le joueur
  derrière le moindre mur (capture). Leur forme est l'étape 3.
- **Les pieds sur l'origine**, donc sur le sol : calé comme en 2D, le centre du corps sur
  l'origine, le sprite descendait de 11 px sous le plan et le sol le coupait à la taille.
  Barres, étiquettes d'affixes et nombres montent d'autant
  (`SpriteForge.CENTER_ABOVE_FEET`) ; sans caméra (les tests), ils restent à plat.
- **La croix attend deux images de physique** entre ses coups : Jolt voyait la fermeture et
  la réouverture de la hitbox avant le même pas, et le second coup ne touchait plus.
- **`ActorSprite` en billboard** plutôt que des capsules (§9) ; flash, liseré et teinte d'état
  éteints jusqu'à `ActorModel`. **Un bug d'avant, sur `master` aussi** : la teinte d'état n'a
  jamais paru — `ActorSprite` posait `tint_color`, le shader attendait `teinte_couleur`.
- Les bibliothèques de dessin (`fx/`, `EffectForge`) restent : la forge (F4) les montre, et
  l'étape 4 pourra reprendre leurs pièces.

**La campagne garde ses valeurs.** Ce qui a changé dans les tests : les positions du monde en
`Vector3(x, 0, y)`, les points d'écran par `Flat.on_screen()`, la secousse par `h_offset` et
`v_offset`, et ces tests du **dessin 2D**, retirés ou réduits à leur part de jeu
(`test_shapes.gd` sauf mention) :

- le tour de peinture des serpents (`HellSnake.on_turn`), les maillons des Chaînes du
  jugement (`pieces`), le lit de flammes du sillon, le lit de taches d'un sol converti, le
  halo cuit d'une explosion : retirés ;
- le Trait de glace, l'orbe statique en meute, la traînée sous les corps, la Gestation :
  sans leurs assertions de rotation, de matériau, d'arcs dessinés, de `z_index` et de
  taille dessinée ;
- la Triade sous l'Incarnation et le nœud de conversion (`test_player.gd`) : la nature du
  coup au lieu de la teinte dessinée ;
- `test_status_effects_in_game.gd` : sans la teinte du sprite ;
- la Bifurcation : la cible écartée passe de 60 à 62 px — à 60, deux cibles étaient à
  égale distance, et leur ordre est celui du moteur physique.

**Le banc** (`world/stress_test.tscn`, graine 4242, fenêtré, 240 images de chauffe puis
1 440 mesurées), contre la référence 2D de `CLAUDE.md` :

| ennemis simulés | 2D : img/s, physique | 3D : img/s, physique |
|---|---|---|
| ~140 | 165, 4,54 ms | 164, 2,25 ms |
| ~282 | 165, 4,41 ms | 162, 4,46 ms |
| ~552 | 165, 6,77 ms | 148, 8,48 ms (160 et 6,66 ms à un autre passage) |
| 935 / 834 | 165, 8,62 ms | **10**, 18,91 ms |
| combat, 300 | 165, 11 ms, 6 % figé | 165, 7,58 ms, 5,7 % figé |

L'ombre des sprites d'acteur est éteinte : une carte debout n'en a pas de sensée, et elle
faisait tomber 600 ennemis à 107 img/s. **Au-delà de ~550 simulés, la physique de Jolt coûte
deux fois celle de la 2D**, et à 1 000 elle ne suit plus le pas. La zone jouée en compte 69 :
environ 8× de marge, contre 25× avant.

## 11. Reste à faire

- La physique au-delà de 550 ennemis : à creuser avant que l'étape 2 ajoute ses meshes
  skinnés (§6).
- Étape 2 : `ActorModel` — avec lui reviennent flash, liseré et teinte (la vraie, cette fois).
- `Game.WORLD_ZOOM` grossit encore le texte posé « dans le monde », devenu écran : 18 % trop
  grand. À trancher avec l'interface (§6).
- Les télégraphes ennemis n'ont plus de dessin : le jeu se joue sans voir venir l'obus du
  mortier, jusqu'à l'étape 4.
