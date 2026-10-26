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
   pour la 3D avant la première — fait le 19 octobre, voir §13.
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
  gardent leur taille d'avant, les portées leur place à l'écran. **Le 18, la molette** la
  rapproche jusqu'au quart de ce recul, comme dans Path of Exile, pour voir les modèles de
  près ; jamais plus loin que le cadre par défaut.
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
L'arme se range pendant la marche et le lancer des Lames de jet, demande de l'utilisateur
(`ActorModel.SHEATHED`) : l'export, qui lit cette liste, n'y tourne pas la main (`wield`).

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
1 440 mesurées), contre la référence 2D de `CLAUDE.md`. Remesuré le 18 octobre, caméra
recadrée (§6) :

| ennemis simulés (2D / 3D) | 2D : img/s, physique | 3D : img/s, physique |
|---|---|---|
| 142 / 131 | 165, 4,54 ms | 165, 1,39 ms |
| 284 / 265 | 165, 4,41 ms | 165, 2,41 ms |
| 562 / 520 | 165, 6,77 ms | 165, 5,30 ms |
| — / 777 | — | 165, 8,51 ms |
| 935 / 918 | 165, 8,62 ms | 158, 9,40 ms |
| — / 1 114 | — | 65, 13,59 ms |
| combat, 300 | 165, 11 ms, 6 % figé | 165, 5,03 ms, 5,2 % figé |

L'ombre des sprites d'acteur est éteinte : une carte debout n'en a pas de sensée, et elle
faisait tomber 600 ennemis à 107 img/s. **La 3D tient la 2D jusqu'à ~920 simulés** et décroche
vers 1 100. Un premier relevé, le 17, donnait 10 img/s à 834 : il ne se reproduit pas, ni
avec la caméra d'alors (840 à 165 img/s). À 920, par pas de physique : 7,3 ms dans la boucle
de l'`EnemyManager`, dont 4 ms de `move_and_slide()` — le script et le glissement, pas le
pas de Jolt.

## 11. Étape 2, en cours (18 octobre)

**Tranché avec l'utilisateur : un personnage sans modèle garde sa planche** — le jeu reste
jouable pendant que les onze autres passent en 3D, chacun dès que son `.glb` existe.

- **`ActorModel`** (`art/actor_model.gd`) est le nœud `Model` de chaque acteur, `sprite`
  devenu `model` chez eux. Il pose `art/models/<archétype>.glb` s'il existe, son
  `ActorSprite` sinon (`ActorModel.sprite`) ; changer d'archétype en jeu change de genre de
  corps. La silhouette tirée du lieu d'apparition vit chez lui.
- **Le modèle** : ×`Flat.PX_PER_M`, tourné vers sa direction (sans les trois vues d'une
  planche), `rest` et `walk` en boucle, un geste relancé depuis zéro. L'export écrit
  désormais l'arme par défaut (`weapon`) à côté des images d'impact.
- **Flash, liseré et teinte reviennent** : `art/actor_overlay.gdshader` en
  `material_overlay`, par uniformes d'instance — un matériau pour tous les corps. Une planche
  n'en a pas : `ActorSprite` a perdu les siens, qui ne s'allumaient plus depuis l'étape 1.
- Les tests qui lisent l'intérieur d'une planche y passent par `model.sprite` ; celui de la
  touche tenue compte aussi `rest` et `walk` pour du repos. Aucune valeur attendue changée.
- Le Vive lame est le seul modèle : vu en jeu (`Bureau\hns-captures-modele-en-jeu\`),
  ombre, coup, flash et transi.

**Le 18 octobre, les détails du Vive lame** (retours de l'utilisateur, au zoom) :

- **Bras droit trop tendu, épée trop grande** : une seule cause, le haut du crâne du
  gréage local, resté chibi (voir `tools/characters/LISEZMOI.md`, pièges). Recalé.
- **L'épée flottait à côté du poing**, **le bras gauche** gardait la pose d'un autre
  squelette : os de prise au creux du poing, main gauche posée au repos et en marche.
- **La garde C** (« garde prête »), choisie sur planche parmi quatre.
- **Les doigts** restent des moignons repliés : la limite de Stable Fast 3D.

**Le générateur 3D.** L'utilisateur veut un rendu poli, sans payer. Stable Fast 3D donne une
figurine molle. Comparés sur la même image : **Hunyuan3D 2 / 2.1, TripoSG et Step1X-3D sont
exclus** — la licence de Hunyuan3D ne s'applique pas dans l'UE, ses sorties comprises, et les
deux autres en reprennent du code (HunyuanDiT, FlashVDM, décodeur Hunyuan 3D), sous des
licences qui excluent aussi l'UE. Hunyuan avait été lancé avant de lire sa licence : poids et
sorties retirés. **TRELLIS.2** (MIT, aucun code Tencent ; nvdiffrast tourne chez Hugging Face)
sort une forme nette — doigts, plis, visage — et sa propre texture, tout autour du corps : le
seul candidat propre, au prix du quota ZeroGPU (environ un modèle par jour). **Retenu** : le
Vive lame est refait par lui, réduit à 40 000 faces, regréé (poings repliés autour de la
ligne des jointures — les doigts étaient de vrais doigts, l'ancien repli les déchirait), en
garde C, vu en jeu au zoom ; le flash moucheté venait de faces retournées par la réduction.

**Le 18 octobre, le déplacement** (demande de l'utilisateur) : **le corps regarde où il va**,
plus la souris ; elle ne le tourne que pour frapper (`model.set_state(false, facing)` avant
le geste, comme les ennemis). La visée, elle, suit toujours le curseur. Et **le clic gauche
au sol fait marcher**, comme dans PoE et Torchlight (`Player._walk_click()`) : maintenu, le
point suit le curseur. **Le même jour, deux façons de jouer, pas les deux à la fois**
(retour de l'utilisateur) : `Settings.control_mode`, choisi par deux onglets de la page des
touches, ZQSD et Souris, chacun avec ses touches gardées. À la souris, plus de
déplacements au clavier ; « Déplacement » est sur le clic gauche, montré et jamais changé ;
les cases au clic droit, A, Z, E, R. Au clavier, rien ne change : le clic gauche est la
première case. Un coup interrompt la marche vers un point, mais pas bouton tenu : on
continue d'avancer après. La mort et un changement de zone oublient le point
(`Player.halt()`). **Le geste arrête le corps** (retour de l'utilisateur, le 19) : on
s'arrête pour frapper ou lancer, et la marche tenue, touches ou clic, reprend après, comme
dans PoE. Revient sur le jalon 47, §4, qui ralentissait à 0,4 sans figer (`ATTACK_MOVE_MULT`,
retiré). Sans recherche de chemin : un mur arrête la marche, il ne la contourne
pas. **Les jambes de la course** étaient trop écartées : cuisses resserrées de 12°
(`walk_leg_space`, choisi sur planche parmi 0, 6 et 12°).

**Le 18 octobre, la sorcière** passe au même chemin que le Vive lame. Son prompt reprend la
direction « Torchlight » en proportions adultes, et sa cape devient une pèlerine courte :
l'ancienne collait les bras au buste, Mixamo ne pouvait pas la gréer. Qwen-Image, graine 1337
(la 4242 avait quatre bras, la 777 une cape longue) ; il peint la peau bleue de lui-même, la
règle qui la repeignait pour SDXL (`model_recolor`) est retirée. TRELLIS.2 au quota du jour,
gréée par Mixamo, six animations armées dont une course posée — le sprint du Vive lame levait
les avant-bras. La baguette suit le bras (`wield`) ; sur planche, gestes lisibles. Ses jambes
étaient aussi trop écartées dans la course : −12°, comme lui.

**Le 18 octobre, les vues de face.** Le modèle brut de TRELLIS.2 (200 000 faces) est net là où
le corps de jeu, réduit, se fend ; l'utilisateur le veut « quand on voit le personnage de
face », pas sur l'acteur. L'export écrit `art/models/<id>_portrait.glb` : le brut, calé sur le
corps gréé par Mixamo, ses poids recopiés (transfert au plus proche), le repos seul — sans
repasser par Mixamo. `ActorPortrait` le rend dans un monde à part, sous la lumière du jeu et un
appoint rasant (de face, le chapeau mangeait le visage), cadré sur la hauteur que l'export
écrit (`extras.height`) : la boîte englobante d'un maillage gréé ne suit pas le squelette.
**Sélection de personnage** : le personnage choisi en grand à droite de la liste, la classe
choisie à droite de la création ; la liste se décale, les deux centrés ensemble. **Inventaire** :
la poupée devient le portrait, tournable au glissé. Une classe sans modèle garde sa planche.

**Le 19 octobre, le joueur de flûte** suit la sorcière : prompt « Torchlight » adulte, le
long manteau devenu un pourpoint mi-moutarde mi-cramoisi arrêté aux hanches (un pan long se
grée mal sur les jambes), graine 1337 sur trois, TRELLIS.2, Mixamo, six animations. Mixamo
n'a ni danse ni flûte : la Morsure et la Danse jouent le coup, ses airs le lancer (le
geste `bite` ira au Roi des Rats). **Ses bras rentraient dans le buste** pendant la course,
comme ceux du Vive lame : 40° d'écart (`arm_space`), choisi sur planche parmi 0, 20, 30 et
40°, rendue en orthographique et sans arme — en perspective, chaque colonne était vue d'un
autre angle, et l'épée, rangée en jeu, brouillait la lecture. **Sa main armée était
« cassée », posée de travers sur le bras** : pour que la lame prolonge le levier, `wield`
tournait le poignet jusqu'à 145° de la main de Mixamo (115° chez le Vive lame, 130° chez la
sorcière, et 60 à 75° au repos). Borné à 40° (`WRIST`, choisi sur planche parmi sans borne,
60, 40 et 25°), pour les trois : la lame suit encore le balayage et la frappe haute, et se
redresse à l'estoc. **Il sortait en habits noirs** : TRELLIS.2 lui avait posé
du métal partout (0,88 en moyenne), que la cuisson de couleur de Blender rend noir.
`bake_color.py` éteint désormais le métal de la source. La sorcière (0,73) et le Vive lame
(0,51), cuits avant, étaient plus sombres que leur modèle brut : recuits sur leur propre
dépliage, que Mixamo rend à l'identique, sans regréer — l'export prend la couleur du
`model.glb` recuit au lieu de la copie de Mixamo. Couleur moyenne de la texture : sorcière
18-40-44 → 37-56-63, Vive lame 57-43-39 → 75-58-52.

**Le Roi des Rats** (19 octobre, deuxième passage TRELLIS.2 du jour, le quota le permettait) :
même prompt « Torchlight », la queue enroulée à la taille pour ne pas se gréer sur les jambes
(TRELLIS.2 en a quand même fait une longue, qui pend derrière et suit sans se tordre), graine 777
— la seule aux bras nettement détachés du buste. Mixamo l'a gréé **sans os de doigts** : l'export
cherchait une prise d'arme sur le majeur ; sans arme, il n'en pose plus, ni ne tourne la main.
Ni morsure ni danse : le coup. Bras écartés de 40° comme les classes. **Le Roi grandi** de la
Légende (`rat_king_49` à `_58`, une planche par case) n'a pas de modèle à son nom : c'est celui du
Roi, agrandi au rapport de sa case sur la sienne (46, écrite par l'export dans `extras.size`).

## 12. Étape 3, le monde (18-19 octobre)

Tranché avec l'utilisateur : **des falaises qui montent**, comme Torchlight Infinite, et des
matières de Poly Haven (CC0, licence lue : sans territoire).

- **Le relief** (`Terrain`) : un maillage par zone, un sommet tous les 8 px, la hauteur tirée
  de la distance au praticable — plat sur le sol, falaise de 2,5 m dès la première case de
  mur, bosses sur le dessus. Le pied recule d'au plus 6 px dans le mur, jamais sur le sol.
  Les collisions restent les boîtes d'avant : **le gameplay ne bouge pas**, la campagne passe
  sans une valeur changée. Construit en 494 ms au premier jet, **97 ms** une fois la distance
  calculée par case (le sol utile est toujours dans les huit cases voisines : moins d'une
  case de montée).
- **L'estompage** : ce qui dépasse du sol, est plus près de la caméra que le joueur et tombe
  près de lui à l'écran passe en pointillé. Il règle aussi l'arbre qui masquait le joueur au
  zoom.
- **Les matières** : peintes d'abord par Qwen-Image (`tools/terrain_textures.py` l'a fait),
  jugées par l'utilisateur « pas mal, mais trop dessiné / cartoon » ; **des scans PBR** de
  Poly Haven retenus sur planche A/B (`Bureau\hns-captures-monde\planche-A-B.png`). Leur
  couleur recalée sur la palette en entier faisait un aplat orange : à mi-chemin, les nuances
  restent. Relief et rugosité dans une image par matière (`_nr`) : cinq matières à trois
  textures dépassaient les unités d'un shader.
- **Le décor** : neuf scans de Poly Haven réduits (rochers, gros bloc, bois mort couché,
  buisson teint de sec), grandis au-delà du réel comme les armes ; **les arbres morts debout
  sont générés** (`blender/dead_tree.py`) — le seul de Poly Haven faisait un poteau pâle.
  Un `MultiMesh` par modèle. Les sprites 2D du décor, l'atlas, les textures 2D du sol et
  `tools/tiles.py` sont partis.

**Coût, mesuré** (banc, 300 ennemis en combat, 1280 × 720, sans vsync, 1 440 images après
240 de chauffe, paires alternées) :

| | img/s | image | physique |
|---|---|---|---|
| avant l'étape 3 | 760 à 816 | 1,27 ms | 7,3 à 11,9 ms |
| relief et décor, couches toutes lues | 299 à 302 | 3,33 ms | 3,8 à 4,5 ms |
| **une couche à poids nul sautée** | **398** | **2,51 ms** | 3,1 à 3,5 ms |

Le rendu coûte 1,2 ms de plus par image : on reste à ~400 img/s, loin au-dessus des 165 de
l'écran. La physique n'en dépend pas (son écart vient du semis : 291 ennemis vivants contre
298). La première zone d'une partie coûte 1,7 s de plus, le chargement des modèles du décor.

## 13. Étape 4, les effets (19 octobre)

**Les télégraphes ennemis d'abord**, le seul manque qui changeait la façon de jouer. Cinq
dessins sur planche, en zone, à 30 et 80 % du plein (`Bureau\hns-captures-telegraphes\`) :
le pixel tramé de la 2D porté tel quel, un voile lisse, l'anneau qui se remplit, le sol qui
rougeoie, des hachures. **Retenu : l'anneau qui se remplit** — contour net, plein léger qui
monte, plus dense vers son front ; il laisse voir le sol. Premier essai de planche : les
disques tombaient dans la falaise (le joueur naît au bord de la carte) et le rouge clair se
fondait dans l'ocre ; recentrées et assombries, les cinq variantes se lisaient.

`DangerZone` devient la géométrie elle-même (`MeshInstance3D`) : un plan à la taille de sa
forme, tourné vers son cap — le couloir de la charge aurait couvert un carré de 340 px,
presque tout jeté. La distance au bord se calcule par forme (`measure()`), ce qui donne un
contour d'épaisseur égale. **L'opacité du menu** : `transparency` ne fait rien sur un
shader qui écrit `ALPHA` (mesuré sur capture : même intensité à 40 %). `Settings.veil()`
pose donc un paramètre d'instance `opacity`, que chaque shader 3D d'effet déclare.
Vérifié en zone (`Bureau\hns-captures-telegraphes-jeu\`) : à 40 %, 1 106 pixels rouge vif
au lieu de 7 187.

**Le visuel générique par élément.** Une cinquantaine de formes de compétence, presque toutes
invisibles depuis l'étape 1. Planche en zone : trois familles (projectile, éclatement, arc de
coup) en feu, froid et foudre, quatre façons (`Bureau\hns-captures-elements\`). **Retenu : les
particules.** Deux erreurs vues à la planche : au-dessus de 1, le tonemapping blanchissait
toutes les natures en un même blanc, et un bruit d'« énergie » trop fin sortait en rond blanc
déchiqueté (remplacé par un mélange lumière-particules). `ElementFx` : traînée des projectiles
(ceux des ennemis compris), gerbe des explosions, balayage des coups. Vu en combat
(`Bureau\hns-captures-etincelles\`) : à 4 px les étincelles ne se voyaient pas, passées à 7 ;
nées à 30 images par seconde (le défaut), les tirs rapides laissaient des perles. Pièges : posée
parmi les projectiles, la traînée cassait treize tests qui en comptent les enfants — elle vit à
la racine du viewport ; `finished` ne vient jamais sans rendu, la gerbe se libère sur minuterie.
**Deux familles de plus**, même langage : le disque d'une zone qui dure (`ElementFx.area`, des
étincelles qui montent d'un anneau au rayon de la zone) et le semis d'un trait (`line`, une
boîte le long du segment). Branchées en une ligne à la naissance de trente nœuds ; vues en
combat (`Bureau\hns-captures-fx-lightning\`, `-cold\`) : la chaîne saute d'ennemi en ennemi,
le nuage crache, l'orbe gelé file. Le sol qui brûle naît en différé, sa position après lui :
son disque se pose en différé lui aussi. **Les auras** ensuite : leur rayon change en route
(l'immolation monte, un nœud pris en cours), d'où `ElementFx.keep()`, qui reprend le disque
avec une autre matière — changer le nombre d'étincelles relancerait l'émetteur ; l'impulsion
sacrée jette une gerbe par onde, un buff un halo. Vues en combat (`Bureau\hns-captures-aura-*\`).
Restent sans rien les créatures (rats, corbeau, invocations), qui passeront par les modèles.

**`/dessiner-un-effet` réécrit pour la 3D**, avant le premier dessin propre : la planche se
rend dans le vrai jeu, en fenêtré (`tools/capture.sh`, un scénario qui pose ses variantes
autour du joueur) ; les règles de la grille 2D (pas d'additif, calé sur le pixel, rien ne
pâlit) cèdent la place à celles payées ici — couleur sous 1, opacité par paramètre
d'instance, géométrie à la taille de sa forme, particules sans `fixed_fps`, matières gardées.
Le parti pris choisi en 2D reste la référence ; ce qui a un corps passe par un modèle.

**Le manuel des flammes, la boule de feu d'abord** (l'utilisateur veut avancer manuel par
manuel). Première planche, cinq façons — flammes en particules, plasma, la couronne de la 2D
portée, aplats toon, noyau de lave (`Bureau\hns-captures-boule-de-feu\`) : « pas assez
parlantes ». L'utilisateur a montré la boule de feu de Path of Exile : un cœur brûlant dans un
halo, une longue traînée de flammes vives qui s'effilochent, la lumière portée au sol.
Deuxième planche, quatre déclinaisons (`Bureau\hns-captures-boule-de-feu-poe\`) : **retenue,
« en lumière »** — des flammèches qui s'additionnent. `FlameFx` (`fx/flame_fx.gd`, hérite
d'`ElementFx` pour suivre sa boule et lui survivre) : cœur marbré poussé à 1,4, lumière
portée sans ombre, traînée additive ; à l'explosion, flammes, fumée mêlée dessinée dessous,
brûlure au sol, éclair de lumière, à l'échelle du rayon. Le froid de la boule de Givre a sa
rampe. Ce que les planches et les captures ont corrigé :

- **La teinte mêlée vers le blanc sortait beige sur l'ocre** : une rampe saturée par
  élément (cœur, milieu, profond, bord), et la règle « sous 1 » réduite à ce qui se mêle.
  **Une flamme mêlée sortait peinte** — opaque, terne sous le soleil du sol — : en lumière,
  la somme monte au jaune où les flammèches s'empilent, saturée, la lueur garde la teinte.
- **Un bruit trop fin** mouchetait les bords au lieu de faire des langues ; trop de blanc au
  cœur des flammèches pâlissait toute la traînée.
- **Des perles dans la traînée**, deux causes, aucune dans l'effet : la compilation d'une
  matière neuve (la planche fait désormais un passage à blanc), et **chaque capture qui fige
  le jeu ~110 ms** — le gabarit `tools/capture_scenario.gd` garde maintenant ses images en
  mémoire jusqu'à `quit`, et sait entrer en zone (`["area"]`).
- **La première apparition de chaque matière gèle le jeu** : 89 ms pour les étincelles (déjà
  là depuis l'étape 4), 105 pour la boule, ~130 pour son explosion, mesurés image par image.
  `ElementFx.warm()`, appelé par la zone, fait paraître chaque famille une fois, invisible :
  plus aucune image lente ensuite ; le chargement passe de 140 à 147 ms.
- Le bruit se calcule dans les shaders (`fx/flame_common.gdshaderinc`) : une
  `NoiseTexture2D` se génère en différé.
- Captures en jeu, feu et Givre, de près et au zoom du jeu (`Bureau\hns-captures-boule-de-feu-jeu\`).

**Coût** (300 ennemis en combat, la boule de feu tenue en case 0 des deux côtés, sans vsync,
A avec les étincelles génériques contre B avec `FlameFx`, six paires alternées) : sous le
bruit — B − A vaut −0,28 ms en moyenne (de −1,96 à +1,46) ; les quatre dernières paires,
calmes, donnent ~3,3 ms l'image des deux côtés.

**Le Serpent infernal.** Première planche dans la langue de la boule (traînée, ruban de feu,
anneaux de braise, lave, ruban et flammes ; `Bureau\hns-captures-serpent\`) : « un peu trop
moche, on ne dirait pas un serpent ». Un serpent se lit à sa silhouette — tête en losange plus
large que le cou, corps qui s'effile — : deuxième planche, un vrai corps construit le long des
anneaux, en quatre matières (`Bureau\hns-captures-serpent-corps\`), **retenue : « braise »**.
Vu en jeu : « pas assez de volume, un dessin plat », puis, relief et reflets ajoutés, « toujours
un dessin sur le sol ». La cause était ailleurs : **les faces du tube étaient tournées à
l'envers**, la caméra voyait le dedans du fond du corps, et aucune lumière ne pouvait lui donner
de volume. Retournées, troisième planche de posture (`Bureau\hns-captures-serpent-volume\`) :
**retenu, l'avant dressé en cobra, un tiers plus épais**, écailles bombées, reflets, liseré chaud,
la lueur posée devant la tête — au-dessus, elle l'écrasait d'un rouge uniforme. `SerpentBody`
est une grille fixe que le shader courbe le long des anneaux : refaite en GDScript à chaque image
(la planche), elle aurait coûté des milliers de sommets par serpent et par image. Le Venin a sa
rampe nécrotique. Captures en jeu (`Bureau\hns-captures-serpent-jeu\`). **Coût** (même banc, le
serpent en case 0, trois en vie, machine calme) : 1,86 ms l'image des deux côtés, B − A = 0,00 ms
en moyenne (de −0,07 à +0,07).

**Retour sur la boule de feu** (20 octobre). « Le nœud Fragmentation ne marche pas » : il
marchait — compté image par image, la boule lâche ses trois éclats à l'impact et en bout de
course —, mais chaque éclat portait la traînée et la lumière d'une boule entière, et partait du
cœur de l'éclair de l'explosion : on ne le voyait pas naître. Un éclat a désormais son allure
(`FlameFx.as_shard()`) : cœur et flammèches à 0,55, traînée brève, sans lumière ; et l'éclair
d'une explosion suit son rayon. **Le Météore** n'avait que les étincelles génériques : planche
de quatre chutes (boule géante ou rocher en fusion, ombre qui grandit ou cercle qui se remplit ;
`Bureau\hns-captures-meteore\`), **retenue : la boule et l'ombre**. Il tombe en biais —
vue d'en haut, une chute droite ne se lit pas — avec une traînée dense, et éclate en flammes.
Vu en jeu, sa traînée sortait en perles : la boule bougeait au pas de physique, plus lent que
l'image ; elle bouge à l'image. Captures : `Bureau\hns-captures-fragmentation\`,
`-meteore-jeu\`.

**L'Immolation.** Première planche dans la langue de la boule (couronne de flammes, brasier
plein, porteur en feu, couronne et onde ; `Bureau\hns-captures-immolation\`), après deux
erreurs vues sur planche : les flammèches rondes de la boule, vues d'en haut, ne montaient pas —
des bulles ; d'où des **langues debout**, tournées vers la caméra autour de la verticale ; puis,
poussées vers le blanc, elles sortaient crème — le cœur reste dans la rampe. Verdict : « quelque
chose d'un peu plus sobre ». Deuxième planche, plus tenue (`-immolation-sobre\`) : **retenu, le
liseré de feu au rayon et quatorze flammèches**. `FireRing` suit le rayon (Feu de camp, Brasier)
et la nature (Flamme noire) à chaque impulsion. Vu en jeu (`-immolation-jeu\`) ; contre une
falaise, le liseré passe sous elle, comme le sol.

**La Ruée ardente** (20 octobre). Première planche toute en shader, dans la langue de la boule
(cœur et franges, braises, sol en flammes, rideau, lave ; `Bureau\hns-captures-ruee\`) : sur
l'ocre, les langues additionnées sortaient crème tant qu'un **lit calciné** sombre ne passait
pas dessous. Verdict : « assez cheap », faute de matière. Sans référence à montrer,
l'utilisateur voulait des textures peintes. Deuxième planche (`-ruee-matiere\`) : un scan de
terre craquelée de Poly Haven (CC0), noirci, dont les fissures rougeoient, et des flammes
photographiées par Qwen-Image sur fond noir, additionnées. Debout, ces flammes sortaient
tassées sous la caméra plongeante : tournées vers elle en entier, elles ont gardé leur
hauteur. Le sol « vu de dessus » de Qwen sortait en étoile de lave, pas en texture qui se
répète. **Retenu : les fissures seules**, sans flammes. `BurntPath` remplace, pour toute
trace de feu, le semis d'étincelles qui jurait par-dessus en jeu. Le Brasero y gagne le trait
de sa Triangulation. Captures en jeu : `-ruee-jeu\`. **Coût** (340 ennemis increvables, la
ruée en case 0, sans vsync, six paires alternées) : +0,035 ms l'image en moyenne (de −0,07
à +0,16), 1,49 contre 1,53 ms ; la physique, dans le bruit (+0,11, de −0,58 à +1,39).

**Le Serpent infernal, en textures vraies** (20 octobre, « le même procédé » à la demande de
l'utilisateur). Planche de sept peaux sur le corps de `SerpentBody` (`Bureau\hns-captures-
serpent-matiere\`, l'actuelle en 0) : deux peaux de serpent et deux d'écailles calcinées à
braises tirées par Qwen-Image, trois scans de Poly Haven (roche veinée, pierre de lave, terre
craquelée). Les scans sortaient bruns et sans écailles. Première passe : la peau, répétée sept
fois, se perdait (une écaille par pixel) et sortait argentée sous le soleil ; répétée trois
fois de long et une fois du tour (un nombre entier, sinon la couture du tour se voit), assombrie
et chauffée, elle se lit. **Retenu : « écailles B »**, une peau noire aux écailles fines dont les
joints rougeoient. Le tirage ne se raccorde pas : `tools/fx_textures.py` le recouvre de sa moitié
décalée, fondue vers les bords (la couture s'y devine), et tire relief et joints de sa clarté.
L'outil prend aussi les fissures de la Ruée, qui vivaient un temps dans `terrain_textures.py`.
Captures en jeu : `-serpent-peau-jeu\`. Coût non remesuré : deux lectures de texture prennent
la place du bruit et du hachage des écailles dessinées.

**La méthode retenue pour toutes les compétences** (20 octobre) : « on va garder cette méthode
pour les skills (et leurs variantes depuis leurs arbres bien sûr) », dit l'utilisateur après la
Ruée et le Serpent — des textures vraies, et la boule de feu et le Météore refaits ainsi.
Planche (`Bureau\hns-captures-boule-matiere\`) : la boule photographiée en vol avec trois
traînées (volutes photo, langues photo, volutes et braises) ; le Météore en boule géante ou en
rocher de croûte de lave dans une couronne de feu ; une même explosion pour tous (photo
d'explosion, volutes, fumée photo, la brûlure craquelée de la Ruée). Qwen tire des boules de feu
en spirale, belles mais dessinées, et des explosions en champignon : seul le nuage se garde, la
colonne ne se lit pas d'en haut ; découpé, il donne aussi les volutes. **Retenus : « photo » et
« boule géante »**. Erreurs vues sur planche puis en jeu : l'explosion montait au blanc (sept
photos et 220 volutes au Météore : deux photos, 120 volutes au plus, plus faibles) ; un grand
quad d'explosion enfoncé dans le sol y était coupé net (levé de 0,7 de sa taille) ; poussées par
la rampe du Givre, les photos sortaient en perles — la rampe s'éteint déjà vers le noir, et la
clarté la multipliait une seconde fois. Le feu garde les couleurs de la photo, une autre nature
y lit sa rampe. Les flammèches en bruit de shader (`flame_wisp`, `flame_smoke`, `flame_core`)
sont supprimées. Captures en jeu : `-boule-photo-boule\`, `-meteore\`, `-givre\`. Coût non
remesuré.

**Le Brasero** (20 octobre), dernier du manuel des flammes. Un objet qui a un corps : Poly Haven n'a
pas de trépied (un foyer de pierre, des pots de laiton, un poêle-baril). Planche de cinq façons en feu
et sous la Lanterne d'orage (`Bureau\hns-captures-brasero-matiere\`) : le trépied du jalon 42 en fer
rouillé scanné, avec une colonne de flammes photographiées, des braises seules, ou le cœur de la boule
dans la coupe ; une corbeille de barreaux en fer noirci ; le foyer de pierre scanné. **Retenu : le
trépied et ses flammes.** `BrazierFx` le bâtit de primitives fondues en un maillage, plaqué en
triplanaire — la coupe et les pieds n'ont pas d'UV qui se suivent. Vu sur planche : la foudre sortait
blanche, sans rampe à elle dans `FlameFx.RAMPS` (elle en a une) ; les fissures de la Ruée, répétées à
72 px, ne faisaient dans la coupe qu'une craquelure, une assiette brune — à 8 px, des braises. Le
`MOUTH` du Brasero, (0, 0, −9), était la hauteur de la coupe en 2D portée telle quelle : ses boules
partaient 9 px au nord, au sol ; elles partent du centre, et le visuel de la boule les lève au-dessus
du rebord. La grille 2D d'`EffectForge.brazier()`, morte depuis l'étape 1, est partie. Captures en
jeu, feu et foudre, au zoom du jeu et de près : `Bureau\hns-captures-brasero-jeu\`. **Vu par l'utilisateur** : sous
la Lanterne d'orage, le Foyer du mage tirait la Boule de feu en feu — résolue à part, avec son arbre,
elle ignorait la conversion du brasero. Un brasero converti lui impose sa nature, par le paramètre de
l'Incarnation (`Player.resolve(…, element)`) ; mots-clés et affixes suivent. Vue en jeu, la boule de
foudre sortait presque blanche, sa traînée surtout : la rampe de la foudre, foncée, la garde violette
(`Bureau\hns-captures-brasero-foyer\`). Coût non mesuré
(deux braseros à la fois de base : 36 particules et une lumière chacun).

**Le manuel de la foudre, l'Éclair vif d'abord** (21 octobre). Son trait est le projectile commun
du joueur : le Trait et la Peste le prennent aussi, et il change de nature dans l'arbre — froid du
Trait de glace, feu quand le Familier le rejoue. Première planche, en foudre, cinq façons en photos
d'arcs électriques de Qwen-Image (dard d'arc, plasma, comète, fil, éclair long ;
`Bureau\hns-captures-eclair-vif\`) : additionnés sur l'ocre, leurs cœurs blancs blanchissaient tout —
passés par la rampe de la foudre, violets mais sans cœur, ils sortaient en plumes ou en fumée.
Verdict : « ça ne ressemble pas vraiment à un éclair ». Un éclair se lit à son **zigzag** et à son
**cœur blanc fin** ; Qwen, même prié d'angles vifs, sort des arcs plumeux au tronc presque droit.
Deuxième planche (`-eclair-zigzag\`) : un ruban que le shader casse en coudes, retirés à chaque
battement, qui porte le tronc de la photo, et une rampe qui garde le blanc en haut. Premier rendu en
tube de néon, trop épais et trop doux : la bande de photo élargie (le tronc blanc reste fin dans le
ruban) et des crans fins entre les coudes. **Retenu d'abord : le zigzag** (contre fourches, crépitant, long,
photo nette), livré et capturé en jeu. Puis l'utilisateur a montré **Kinetic Bolt** de Path of Exile,
« auquel on ajoute un visuel électrique » : une trajectoire qui zigzague, une longue traînée qui en
garde la forme, un orbe d'énergie en tête. Troisième planche (`-eclair-kinetic\`) : équerre, dents de
scie, droit avec des arcs qui jaillissent de la traînée, équerre à gros orbe, équerre en bleu.
**Retenu : les dents de scie, en violet** — la couleur de la foudre partout ailleurs dans le jeu. Le
zigzag est un dessin seul : l'orbe s'écarte de 10 px au plus de la trajectoire, qui reste droite et
seule à toucher. `BoltFx` refait : l'orbe et ses trois arcs, la traînée (`BoltFx.Trail`, un ruban
refait à chaque image sur les positions passées de l'orbe, qui survit au tir) ; l'éclat de fin de
course naît en différé, la fin venant d'un rappel de collision. Captures en jeu : `-eclair-jeu\`. **« Ça lag un peu
quand je fais plusieurs éclairs »** (Paratonnerre pris aussi) : mesuré en zone, sans vsync, Surcharge
et Fourche sur deux meutes increvables, ce n'est pas le temps d'image — 3,7 à 6,6 ms avec ou sans
Paratonnerre, traînée ou lumières (les écarts entre phases identiques sont du bruit), aucune image au-delà
de 11 ms aux premiers tirs, aucun nœud qui s'accumule. C'est le pas : le tir avance au pas de
physique (60 Hz), de 3,83 px une image sur deux ou trois à 165 Hz, immobile entre deux ; les
étincelles le cachaient, un orbe net non. `BoltFx` se pose désormais à l'image entre les deux derniers
pas (1,39 px à chaque image, mesuré). Les gels d'impact figent 6 à 8 % du temps en tir continu,
sous les 10 % où le jeu se met à ressembler à du lag ; ils ne sont pas touchés. Coût non mesuré. Le premier tirage des textures par
l'outil est revenu vide : même prompt et même graine que la planche, ComfyUI servait le graphe de son
cache, sans image ; `character_forge.run()` donne un nom neuf au nœud d'enregistrement. 
**Le Trait de glace** (23 octobre), l'Éclair vif passé au froid. Planche en photos de Qwen-Image
(`Bureau\hns-captures-trait-de-glace\`) : un javelot de cristal en volume — le parti pris de la 2D,
une bipyramide éclairée qui tourne —, la photo d'un éclat couchée sur le cap, le geste de la foudre
en glace, un orbe dans la brume, une salve de trois cristaux. Deux sujets ont été retirés avant la
planche : l'éclatement sortait en glaçon cubique qui casse, la traînée portait une fougère de flocon.
Premier rendu tout blanc : **additionné à l'ocre, le cyan monte au blanc** — c'est la règle du froid,
qui s'ombre ; les photos passent par la rampe du froid et se **mêlent** au sol (alpha tiré de la
clarté), sous 0,85 de la rampe pour que son haut blanc ne vienne pas. **Retenu : le Kinetic de
glace** — le même geste que la foudre, ce qui dit « c'est le même sort ». `BoltFx` le prend pour le
froid **du joueur** : un orbe de glace hérissé sans arcs, une traînée de givre, un éclatement d'éclats ;
le tir de glace des casters garde ses étincelles. Le javelot 2D (`Frost.javelin`) est retiré. Captures
en jeu : `-trait-de-glace-jeu\`. Les éclats de l'Orbe gelée, des tirs de froid du joueur, le prennent
aussi en attendant le manuel de glace. Coût non mesuré (moins que la foudre : un quad, pas d'arcs).

**La fin de l'Éclair vif** (23 octobre) : quatre planches montrées d'un coup, à la demande de
l'utilisateur, avec cinq photos neuves de Qwen-Image (traînée de feu, javelot de flammes, braise,
globe de plasma, boule d'orage ; `Temp\hns-planche-eclair2\`), les autres reprises de `fx/`.
- **Le trait en feu** (`Bureau\hns-captures-eclair-feu\`) : Kinetic de feu, javelot ardent (la
  2D), comète, braise filante. Premier rendu blanc : la boule et les flammes additionnées à
  l'ocre montent au blanc ; passées par la rampe du feu, au cœur jaune, et à demi-force (0,55),
  elles restent orange. **Retenu : le Kinetic de feu** — le même geste dans les trois natures.
- **Les Esquilles** (`-esquilles\`) : mini Kinetic, étincelles, arcs, filaments. La traînée d'un
  éclat, courte, ne prenait qu'un bout de la photo du tronc et sortait en rectangles avant de la
  répéter plus serrée. **Retenu : le mini Kinetic** (le trait à 0,55, traînée comprise).
- **L'Orbe statique** (`-eclair-orbe\`) : boule de plasma (la 2D), globe à vrilles, boule d'orage
  (additionnée, son nuage gris sortait en coton ; mêlée, il reste sombre), cœur au cercle de
  portée. **Retenu : la boule de plasma** — les décharges en arcs, `Lightning.ARCS_MOST` au plus
  par frappe (un arc par cible coûtait 467 ms par seconde au jalon 43).
- **Le Satellite** (`-eclair-satellite\`) : orbe seul, sillage, anneau d'orbite, lien au joueur.
  **Retenu : le sillage.**
Tout passe par `BoltFx` (une fiche par allure, `BoltFx.Look`). Captures en jeu :
`-eclair-feu-jeu\` (le trait en feu tiré à la main, le Familier ne se pilote pas d'un scénario),
`-eclair-esquilles-jeu\`, `-eclair-orbe-jeu\`, `-eclair-satellite-jeu\`. Le dessin 2D du trait
et de l'orbe (`Lightning.dart`, `Lightning.orb`) est retiré. Les tirs de feu du joueur hors de la
Boule de feu (la comète d'un Chaudron converti) prennent aussi le Kinetic de feu. Coût non
mesuré. **L'Éclair vif est fini.**

**Le Satellite fait un tour entier** (23 octobre). « Au maximum les orbes n'entourent pas
complètement le joueur » ; l'utilisateur proposait de doubler la limite. Mesuré en tir continu :
6 orbes au plus, sous la limite de 12 — elle n'y était pour rien. Un orbe vivait 2,5 s, un tour
à 60 px et 92 px/s en prend 4,1 : un quart du cercle restait vide. **Retenu : un tour entier au
moins** (`SkillStats.finalize()`, une durée plus longue reste), contre des orbes plus gros ou une
orbite plus courte : 10 orbes, le cercle fermé (`Bureau\hns-captures-satellite-cercle\` ; la
première capture, au pied d'une falaise, en cachait la moitié dans la roche). Environ 64 % de
dégâts en plus en tir continu, à relever avec les couloirs. Puis l'utilisateur a montré le vrai
cas : « quand on cast un peu plus vite et/ou avec plusieurs projectiles » — trois paquets d'orbes
superposés en taches blanches. Chaque lancer posait ses orbes aux mêmes angles (devant le
lanceur, puis tous les 120°), la limite de 12 atteinte n'en gardait que quatre par paquet.
**Retenu : combler les vides** (contre doubler la limite, qui allongeait les paquets sans les
desserrer) — sur une orbite peuplée, chaque orbe naît au milieu du plus grand vide
(`StaticOrb._widest_gap()`) ; une orbite vide part toujours vers la visée. Trois orbes par lancer
avec la Fourche : 12 orbes régulièrement répartis (`Bureau\hns-captures-satellite-cercle-fourche\`).

**La Chaîne d'éclairs** (23 octobre). Le tronc de l'Éclair vif, mince et presque sans branches,
manquait de ramure sur un saut de 90 à 150 px qui ne dure que 0,22 s : deux sujets tirés par
Qwen-Image (graines 11, 22, 33, `Bureau\hns-chaine-eclairs-textures\` ; la sous-commande, morte avec le choix, est partie),
un saut ramifié — bons tous les trois — et un impact, où un éclair tombait du ciel dans chaque
tirage : l'étincelle de la foudre reste. Un faisceau de filaments, demandé deux fois, sortait noué
autour d'un objet. Planche en zone, cinq couloirs d'une source à trois grunts figés
(`Bureau\hns-captures-chaine-planche\`) : la photo ramifiée couchée de cible en cible, le ruban de
l'Orbe seul, le ruban sur sa ramure, **la tresse** (trois rubans fins aux coudes différents, façon
Arc de Path of Exile), et un arc qui court de saut en saut. Au premier rendu, les photos couchées
montraient leur voile violet en rectangles (seuil de clarté relevé à 0,4, bords adoucis) et la
tresse, à 1,4 largeur d'écart, ne se distinguait pas d'un ruban (2,5). **Retenue : la tresse.**
`BoltFx.braid()` en pose une par saut, le shader du ruban gagne `tail` (plein dès la source) ;
`ChainLightning.trace()` prend une nature au lieu d'une teinte, et l'Arc ardent (allumé et
engourdi) passe en feu. Vue en jeu sur une meute (`Bureau\hns-captures-chaine-jeu\`). Coût non
mesuré : trois maillages et une lumière par saut au lieu d'un semis de particules.

**Le Nuage d'orage** (23 octobre). Il n'avait que le disque d'étincelles générique, et ses frappes
ne se voyaient pas. Première planche, cinq nuages sur des grunts figés, frappant à la période de la
compétence (`Bureau\hns-captures-nuage-orage\`, refaite depuis) : un cumulonimbus photographié par
Qwen-Image, des volutes, une spirale d'orage couchée à plat, une ombre seule au sol avec un éclair
photographié qui tombe du ciel, un nuage embrasé de violet. Erreurs vues sur planche : posés à 46 px,
les nuages cachaient leurs cibles (montés à 80, aplatis) ; leur lueur additive montait au cœur blanc
de la rampe. Verdict : « beaucoup trop moche ». **La cause : une photo de nuage plaquée en `unshaded`
n'a pas de volume** — un autocollant flou, dont le gris-bleu mêlé à l'ocre virait à l'olive. Un nuage
n'est pas de la lumière : il doit prendre celle du jeu. Deuxième planche (même dossier) : des bosses
de cumulus tirées sur fond noir, leur **relief** tiré de leur clarté (un dôme flou plus le détail),
éclairées par le soleil, une lumière dedans qui flashe à chaque frappe ; une grappe de boules
bosselées, des volutes, des volutes sous la pluie, un nuage d'encre, une enclume basse. Premier rendu
blanc-lavande (albédo trop clair, flash trop fort) ; l'enclume basse cachait ses cibles, remplacée par
un nuage haut et translucide. **Retenues : les volutes**, sans pluie. Planche de la Grêle sur ce nuage
(`Bureau\hns-captures-grele\`) : grêlons sur cible, averse continue, colonne de grêle photographiée,
nuage de glace ; les grêlons en billboards ne se voyaient pas, des billes éclairées si ; la colonne
sortait violette (la rampe de la foudre par défaut), puis en rayon bleu. **Retenus : les grêlons sur
cible.** `StormCloudFx` (ARCHITECTURE, « Que montre une compétence en 3D ? ») : quinze bosses, ventre
plus sombre, à l'échelle du rayon (l'Orage portatif rapetisse, la hauteur reste) ; la lueur du dedans
monte avec l'Accumulation ; chaque frappe, Foudre jumelle comprise, tombe sur trois cibles au plus, le
paratonnerre de la Cible de l'orage et l'ennemi du Débordement ; à vide, sur un point du cercle. Le
dessin vit à la racine du viewport et se dissipe après son nuage. Captures en jeu, au cadre et de
près : `-nuage-foudre-jeu\`, `-nuage-grele-jeu\`. Coût non mesuré : seize billboards éclairés par
nuage, trois nuages au plus par lanceur.

**La Ruée d'orage** (24 octobre). Elle ne montrait rien : une téléportation nue (jalon 20), le halo
d'étincelles de son buff, la gerbe générique à l'explosion d'arrivée, et ses charges statiques n'avaient
aucun dessin. Deux planches en zone, photos de Qwen-Image (figures de Lichtenberg, onde de choc,
traînée de plasma) tirées lentement — Torchlight Infinite ouvert prenait 3 Go de VRAM, ComfyUI en
débordait de 6 en mémoire partagée, cinq minutes par image au lieu de quinze secondes ; une graine par
sujet. La ruée et son buff (`Bureau\hns-captures-ruee-orage\`) : éclair bref, traînée de plasma, brûlures
au départ et à l'arrivée, semis actuel. L'arrivée et les charges (`-ruee-orage-arrivee\`) : couronne
d'arcs (la 2D), onde de choc, brûlure de Lichtenberg, les deux ; mini-orbe, étincelle, étoile d'arcs (la
2D). Au premier rendu, la traînée de plasma sortait en trait laser (la photo lue sur toute sa hauteur,
pas sa bande), les brûlures en disques pleins, les arcs aux pieds trop petits pour se voir. **Retenus :
l'éclair bref, les arcs aux pieds, la couronne d'arcs, l'étincelle** (ARCHITECTURE, « Que montre une
compétence en 3D ? »). La couronne vaut pour toute explosion de foudre du jeu, la charge pour celles
qu'un engourdi laisse. Le ruban de la tresse devient `_ribbon_mesh`, partagé avec la ruée. Les dessins
2D de l'anneau et de la charge (`Lightning.ring`, `Lightning.charge`) partent avec leurs tests ; le reste
de `fx/lightning.gd` attend la fin du manuel. Captures en jeu, Coup de tonnerre et Sillage statique pris :
`-ruee-orage-jeu\`. Coût non mesuré.

**L'Électricité statique** (24 octobre), dernière du manuel. Ses charges ont l'étincelle de la Ruée
d'orage. Restaient le buff, qui brûle tout le combat (sobre), l'Ionisation et la Cage de Faraday ; le
Choc en retour a déjà la tresse, la Décharge totale la couronne. Deux planches, photos déjà dans `fx/`
(`Bureau\hns-captures-electricite-statique\`, `-ionisation\`) : halo, arcs sur le corps, grésillement
au sol, étincelles volantes, orbe à l'épaule ; dôme d'arcs, barreaux, bulle de plasma ; anneau qui
s'ouvre, arcs vers les engourdis, rien de plus. Les arcs vers les engourdis ne se voyaient pas à la
première capture : prise trop tard (0,3 s après l'impulsion pour « 0,1 s », l'anneau le montrait déjà
ouvert), les arcs de 0,16 s étaient éteints. L'utilisateur a pris le champ pour les charges, déjà faites :
la question était ce que montre le porteur. **Retenus : rien sur le porteur, le dôme d'arcs, l'anneau
qui s'ouvre.** L'impulsion est la couronne en plus discret : `BoltFx._ring()` sert aux deux. Captures en
jeu, un Choc en retour provoqué : `-electricite-statique-jeu\`. Coût non mesuré. Les cinq compétences du
manuel de la foudre sont en 3D ; la marque du Paratonnerre suit, plus bas.

**La marque du Paratonnerre** (24 octobre), le reste du manuel. Elle n'avait que les étincelles
génériques et se calait encore sur `Hurtbox.overhead()`, décalée vers le nord comme en 2D : en 3D, au sol
à côté de sa cible. Planche de cinq marques sur des grunts figés, dessins déjà choisis repris
(`Bureau\hns-captures-paratonnerre\`) : la foudre appelée (la 2D, l'éclair du nuage), une couronne d'arcs
sur la tête, l'étincelle des charges, une cible au sol, le halo. **Retenue : la foudre appelée.** La tête
est la hauteur du modèle (`ActorModel.height()`) ; l'éclair qui tombe devient `StormCloudFx.drop()`,
partagé avec le nuage. Captures en jeu, une meute increvable — le premier tir tuait sa cible et la marque
partait avec elle (`-paratonnerre-jeu\`). **`fx/lightning.gd` part**, avec ses tests et le grain de foudre
d'`EffectForge` : plus rien de la foudre 2D ne tournait ; `ARCS_MOST` passe dans `BoltFx`. **Le manuel de
la foudre est fini en 3D.** Coût non mesuré.

**Coût du manuel de la foudre** (24 octobre), au banc A/B : `world/stress_test.tscn` sur une copie,
300 grunts increvables collés au joueur (`SPAWN_RADIUS_TILES` 4, vie 1e9), sans vsync, 240 images de
chauffe puis 1 440 mesurées, l'ordre alterné dans chaque paire. A coupe sur la même copie le seul dessin
du scénario (`-- cut=…`, posé dans chaque dessin par le patch du banc), B est l'arbre. B − A, en moyenne
± l'erreur type :

| scénario | paires | image A → B (ms) | B − A image | B − A physique |
|---|---|---|---|---|
| Éclair vif (trait, traînée) | 5 | 10,41 → 10,59 | +0,19 ± 0,39 | +0,56 ± 0,33 |
| Chaîne d'éclairs (tresse) | 5 | 11,17 → 11,45 | +0,27 ± 0,54 | +0,16 ± 0,50 |
| Nuage d'orage (volutes, éclairs) | 10 | 12,33 → 12,27 | −0,06 ± 0,31 | −0,18 ± 0,25 |
| Ruée d'orage (éclair bref, arcs aux pieds, couronne, étincelles) | 10 | 10,92 → 10,99 | +0,07 ± 0,48 | +0,45 ± 0,29 |
| Électricité statique (Ionisation, étincelles) | 10 | 16,05 → 15,04 | −1,01 ± 0,74 | −2,39 ± 1,25 |
| Paratonnerre (foudre appelée) | 5 | 10,89 → 10,95 | +0,05 ± 0,69 | +0,03 ± 0,67 |

**Rien ne sort du bruit** : d'une paire à l'autre l'écart va de −2 à +2,7 ms, et aucune moyenne ne
dépasse deux erreurs types. La physique de l'Éclair vif et de la Ruée (+0,5) frôle 1,6 erreur type ;
les dessins tournent dans `_process`, pas dans la physique. Ce banc, ennemis collés et increvables, est
plus lourd que celui du §12 (10 à 12 ms l'image contre 2,5). **À part, un coût de jeu et non de dessin** :
sous le champ statique avec l'Ionisation, la physique monte à 16-19 ms, contre 7-8 avec le trait seul —
trois cents engourdis, des charges qui mordent ; à examiner. Le premier essai du scénario était faux :
la case 0 relancée à chaque pas refusait le lancer du champ, jamais allumé ; il est relancé à sa place
tant qu'il est éteint. Sur ce banc, `ElementFx.warm()` échoue (la zone entre dans l'arbre pendant le
`_ready()` de la scène, la racine refuse alors les enfants) : des deux côtés, sans fausser la comparaison.

La lumière portée ne suit pas le voile des sorts (`Settings.veil` n'atteint que la
géométrie). Les grilles 2D de la boule dans `EffectForge` restent : mortes depuis l'étape 1,
mêlées à celles de l'éclat, du météore et des bouffées des rats, elles partiront avec le
reste du manuel.

**Coût** (300 ennemis en combat, sans vsync, A sans étincelles contre B, six paires alternées) :
sous le bruit du jour — la même configuration allait de 3,2 à 9,5 ms l'image, et B − A valait
en moyenne −0,4 ms (de −0,95 à +0,36). La matière de particules est gardée par nature : fabriquée
à chaque tir, sa rampe partait au GPU à chaque fois. Les télégraphes, mesurés de même, ne se
distinguent pas non plus du bruit ; aux mesures calmes le banc retrouve les ~2,5 ms du §12.

**Le manuel du froid, les Pics de glace d'abord** (25 octobre). Ils n'avaient que la gerbe
générique. Poly Haven n'a pas de glace (de la neige seulement) : trois sujets tirés par Qwen-Image,
deux graines chacun — un bouquet de pics sur fond noir, une glace veinée raccordable, du givre au sol.
Lents : ~5 min le tirage, ComfyUI débordait de 3,2 Go en mémoire partagée (iCUE en tenait 4,2).
Première planche, cinq façons sur des grunts figés (`Bureau\hns-captures-pics-de-glace\`) : la 2D
portée (deux flancs et une arête, sans lumière), des cristaux éclairés plaqués de la glace veinée,
le bouquet photographié debout, un pic-roi et sa couronne, la glace éclairée avec du givre au sol.
Erreurs vues sur planche : des pics de 12 à 26 px ne se voyaient pas au cadre du jeu (24 à 40) ; les
cristaux éclairés sortaient en silhouettes blanches — **enroulés à l'inverse de ce que Godot tient
pour l'avant** (l'ordre horaire), la caméra voyait le dedans du fond et le reflet de bord, au
maximum, blanchissait tout ; le givre restait invisible, sa fondue partagée laissée à 0 par le cycle
d'avant. Verdict : « trop moche, ça fait trop pauvre », sans gâcher le gameplay — on les voit tout
le temps. Deuxième planche, le geste **habillé** (`-pics-de-glace-2\`) : un éclair de lumière froide,
le sol fendu de givre (les fissures de la Ruée), de la brume (la fumée de la boule de feu), et des
pics qui se brisent en éclats au lieu de rentrer sous terre ; en glace réfractante, en glace pleine
lumineuse, en cascade (petits au centre, couronne haute au bord), et **sobre** — la réfractante sans
brume, douze pics. Erreurs vues : des éclats qui volaient à 60 px hors du cercle (ils parlaient d'une
zone qui n'avait pas frappé), une brume qui cachait le grunt, un voile du bleu profond qui virait au
mauve sur l'ocre. **Retenu : sobre.** `IceSpikesFx` (ARCHITECTURE, « Que montre une compétence en
3D ? ») ; le dessin naît quand le cercle frappe, ce qui échelonne aussi le Sillon. En jeu, deux
pièges que la planche cachait : elle **étirait après avoir penché** (`Basis.scaled`, en repère
global), ce qui redressait les grands pics — refait dans l'autre ordre, ils sortaient en lames
couchées qui débordaient du cercle ; et les éclats, des pics entiers réduits, retombaient en galets
dressés — une esquille fine cuite couchée, qui tourne autour de la verticale, les remplace. La traînée
blanche vue à la première capture en jeu était le tir de glace d'un caster. Le cristal 2D
(`EffectForge.spike`, `Frost.raise_spike`) part avec ses tests. Captures en jeu, une meute de grunts
figés et le Sillon : `Bureau\hns-captures-pics-de-glace-jeu\`, `-sillon\`. **Coût** (le banc de la
foudre refait : 300 grunts increvables collés au joueur, les Pics en case 0, sans vsync, 240 images
de chauffe puis 1 440, A coupe le dessin sur la même copie, six paires alternées, ~48 lancers par
mesure ; ComfyUI arrêté) : 16,83 → 16,92 ms l'image, **B − A = +0,09 ± 0,37 ms**, physique
+0,17 ± 0,31, pire image +1,2 ± 3,1 — dans le bruit. Mesuré avant une correction qui ne fait
qu'alléger B : une seconde salve d'éclats repartait en fin de vie, `emitting` retombant à la fin de
la salve.
**Les Éclats de part et d'autre** (25 octobre, demande de l'utilisateur) : ils partaient en étoile
autour d'un axe fixe, la droite du monde — deux éclats allaient toujours à gauche et à droite de
l'écran. Ils partent maintenant de part et d'autre du lancer, en éventail par flanc
(`IceSpikes.flanks()`) : visés vers le haut, à gauche et à droite ; visés à droite, en haut et en bas.
Chaque cercle garde la direction de son lancer, Bosquet, Sillon, Crevasse et Réplique compris ; l'étoile
reste à l'Orbe gelée et au Météore. Vu en jeu, quatre éclats lancés vers le haut :
`Bureau\hns-captures-pics-de-glace-eclats\`.
**Le visuel des Éclats** (25 octobre) : ils portaient l'orbe du Trait de glace en petit, sans rien des
pics d'où ils sortent. Planche de cinq façons, quatre éclats lancés de part et d'autre d'une zone qui se
brise (`Bureau\hns-captures-eclats-de-glace\`) : l'actuel, une esquille de la glace des pics avec la
traînée du Trait, une esquille qui tournoie dans une poudre de givre, un javelot deux fois plus long, une
grappe de trois. La poudre sortait d'abord en coton blanc (les étincelles génériques, 7 px, presque
blanches), puis en pointillé de craie : dispersée et teintée du cyan moyen de la rampe, elle se tient.
**Retenu : l'esquille.** `IceShardFx` ; l'éclat de fin du Trait, à la taille d'un éclat, devient
`BoltFx.flare_at`, partagé. Captures en jeu, un grunt de chaque côté :
`Bureau\hns-captures-eclats-de-glace-jeu\`. Coût non mesuré : un cristal et une traînée par éclat, à la
place d'un orbe, de sa lumière et de sa traînée.
**La Nova de glace** (25 octobre), le second sort du manuel du froid. Elle n'avait que la gerbe
générique (`Explosion`). Planche de cinq façons, posées à des instants exacts plutôt qu'à l'horloge
(une capture gèle le jeu ~110 ms), au cadre du jeu puis de près sur le joueur
(`Bureau\hns-captures-nova-de-glace\`) : la couronne de la 2D portée (un anneau d'esquilles qui file,
puis onze cristaux des Pics debout sur le bord), le sol qui gèle seul derrière un front de glace
veinée, un souffle d'esquilles sur l'éclatement photographié du Trait couché au sol, un anneau de
brume (la fumée de la boule de feu, passée au froid), un dôme de glace qui éclate. Toutes avec
l'éclair et le sol fendu des Pics. Erreurs vues sur planche, avant de la montrer : **tout sortait
blanc** — le front du sol gelé monté au givre, la photo montée au cœur de la rampe, la brume en
coton (le reproche fait aux Éclats) ; redescendus du bleu profond au cyan, ils se tiennent. Le dôme
sortait laiteux et cachait le grunt : à moitié opaque. **Retenu : le souffle d'esquilles.**
`IceNovaFx` (ARCHITECTURE, « Que montre une compétence en 3D ? ») : les quarante esquilles dans un
seul `MultiMeshInstance3D` ; `Explosion` le pose pour **toute explosion de froid**, comme la
couronne pour la foudre. Le moteur sans rendu ne relit pas les transformations d'un `MultiMesh` :
les tests passent par `sliver(i)`. En jeu (`Bureau\hns-captures-nova-de-glace-jeu\`), un piège
de capture : lancée contre la falaise où naît le joueur, la Nova sortait **coupée en carré** — le
plateau, plus haut que le plan, la masque case par case ; capturée en terrain dégagé, elle rend comme
la planche. **Coût** (le banc des Pics : 300 grunts increvables collés au joueur, la Nova en case 0,
~16 lancers par mesure, sans vsync, 240 images de chauffe puis 1 440, A coupe le dessin sur la même
copie, paires alternées) : un premier banc de six paires donnait +0,61 ± 0,58 ms l'image et une pire
image à +5,0 ± 3,3 ms ; un second, plus bruité, qui coupait aussi les seules esquilles, −0,12 ± 0,80
et +0,35 ± 8,9. Sur les douze paires, **B − A = +0,24 ± 0,77 ms l'image** (erreur type 0,22),
physique +0,26 ± 0,67, pire image +2,7 ± 6,9 — dans le bruit ; les esquilles coupées ne se
distinguent ni de l'un ni de l'autre.
**L'Onde de givre et le sol gelé** (25 octobre), le reste de l'arbre de la Nova : la transformation
n'avait que la gerbe générique, le Givre persistant qu'un disque d'étincelles. Le Bris passe déjà par
`IceNovaFx` (une explosion de froid), le Souffle n'en change que le rayon. Une planche pour les deux
(`Bureau\hns-captures-onde-de-givre\`) : l'Onde en javelots (la 2D portée), en mur de pics qui court,
en front de glace veinée, en brume basse, à l'aller et au Reflux ; le sol en fissures tenues, en plaque
de glace, en givre poudreux, en fissures semées de cristaux. Erreurs vues sur planche : le sol fendu des
Pics étiré sur les 138 px de l'Onde devenait une grande plaque blanche qui écrasait tout — retiré de
l'Onde ; le givre poudreux sortait en disque de neige opaque, puis, éclairci, en voile gris-mauve (le
cyan pâle posé sur l'ocre) — en grains nets, il se tient. **Retenus : les javelots, « mais il faut bien
inverser le sens des cristaux lors du retour »**, et **les fissures**. `FrostRingFx` (un
`MultiMeshInstance3D` sur l'anneau ; le rayon lu à l'image par `FrostRing.reach_at()`, la formule
restant dans `FrostRing`) ; le sol gelé dans `DashTrail` pour toute nature froide (Pics et Désastre
compris), ravivé avec son sol. Captures en jeu : `Bureau\hns-captures-onde-de-givre-jeu\` (pointes
dehors à l'aller, vers le centre au Reflux) et `-sol-gele-jeu\` — le joueur, tué par la meute à la
première prise, renaissait contre la falaise : increvable, il reste en terrain dégagé. **Coût non
mesuré** : un `MultiMesh` d'une cinquantaine de cristaux par Onde, un plan par sol gelé.
**La Nova à la barre de Last Epoch** (25-26 octobre). L'utilisateur : « je veux un jeu beau, un peu
comme Last Epoch au niveau de la qualité visuelle des skills ». Sa liste des techniques (bruit qui
défile, dissolve à liseré, gradient mapping, mesh VFX, trails, flipbooks, additif et bloom, fresnel,
distorsion, décals) recoupée avec le projet : les rampes, les rubans, les traînées, l'additif et le
fresnel y étaient ; manquaient le dissolve, les flipbooks, la distorsion et les décals. La Nova, en
vitrine. **Les textures** : six tirages de Qwen-Image (ComfyUI relancé, débordant de 3,2 Go en mémoire
partagée — 4 à 7 min le tirage) ; le « givre au sol » sortait en feuilles de fougère, deux fois ;
une glace craquelée vue de dessus, en étoile, et une bande de vent de givre ont tenu
(`tools/fx_textures.py nova`). **Le flipbook** : une bouffée de fumée Mantaflow rendue dans Blender
(`tools/blender/mist_flipbook.py`) — les normales d'un tore soufflaient dans tous les sens et
s'annulaient (un champ de force pousse), à 60 la fumée quittait le domaine en trois images, contre
les parois elle s'écrasait en carré. Planche (`Bureau\hns-captures-nova-vitrine\`) : l'actuelle,
la pile avec brume sur deux glaces, la pile sans brume. Erreurs vues sur planche : **le décal sortait
en disque blanc** — éclairé par le soleil du jeu, son albédo presque blanc —, ramené au cyan ; et il
**bleuissait les grunts**, sa boîte de 40 px de haut les prenant : 8 px. **Retenu : la vitrine sans
brume**, la glace « A ». `IceNovaFx` refait (ARCHITECTURE, « Que montre une compétence en 3D ? ») :
onde de choc rongée, distorsion, esquilles qui se rongent (`dissolve`, ajouté au cristal des Pics, à 0
pour les autres), décal, scintillements par `INSTANCE_CUSTOM` ; la photo couchée et le sol fendu de
la Nova partent. Le voile du menu atteint un `Decal` (`Settings._fade`), et `ElementFx.warm()` l'éteint.
Vue en jeu : `Bureau\hns-captures-nova-vitrine-jeu\`. **Coût** (le banc de la Nova, huit paires
alternées) : un premier passage tournait à 49 ms l'image **des deux côtés** — ComfyUI gardait
Qwen-Image chargé, 19,3 Go de mémoire graphique, que `POST /free` ne rendait pas ; ComfyUI arrêté, le
banc retrouve ses 11 ms : **B − A = −0,20 ± 0,48 ms l'image** (erreur type 0,17), physique −0,15 ±
0,43, pire image −1,2 ± 1,9 — dans le bruit. Arrêter ComfyUI avant tout banc.
**L'arbre de la Nova à la même barre** (26 octobre) : l'Onde de givre et le sol gelé prennent les
couches de la Nova. Planche (`Bureau\hns-captures-nova-arbre\`) : l'Onde actuelle, la pile (onde de
choc sous les javelots, distorsion, scintillements, javelots qui se rongent) avec la glace de la Nova
laissée au sol, la pile sans glace, la pile dont les javelots partent un à un ; le sol actuel, la glace
« A », la glace « B », la glace « A » sous un liseré de givre qui frémit. Erreurs vues sur planche : la
glace étirée sur les 138 px de l'Onde devenait **une étoile géante blanche** qui écrasait tout — à 45 %
encore trop ; l'onde de choc, à 26 px, sortait en trait lisse sous les javelots — 40 px, son bord 14 px
devant eux ; le liseré sortait en anneau épais. **Retenus : la pile sans glace, et la glace « A ».**
`FrostRingFx` reçoit l'onde de choc, la distorsion et les scintillements, ses javelots se rongent au
lieu de partir un à un ; le sol gelé devient `FrostGroundFx`, que `DashTrail` fait vivre. Les couches
partagées sortent d'`IceNovaFx` en fonctions (`lay_ice`, `scatter_glints`, `multimesh`, `flat`,
`material`). Captures en jeu : `Bureau\hns-captures-onde-vitrine-jeu\`, `-sol-gele-vitrine-jeu\`.
**Coût de l'Onde** (l'Onde et son Reflux en case 0, ~25 Ondes par mesure, huit paires alternées,
ComfyUI arrêté) : **B − A = +0,71 ± 1,57 ms l'image** (erreur type 0,56), physique +0,51 ± 1,66, pire
image +1,2 ± 6,0 — dans le bruit, mais un bruit fort : la même configuration allait de 9,4 à 13,2 ms,
une partie des grunts mourant avant d'être rendus increvables (264 à 284 survivants). Le sol gelé, un
décal et dix scintillements, n'est pas mesuré.
**Le reste du manuel du froid à la même barre** (26 octobre). L'utilisateur : « refait donc les pics,
ainsi que tout le reste du manuel, et montre moi quand tout est finis ». Les planches ont donc été
**tranchées par moi**, sur pièce, et sont laissées sur le Bureau pour qu'il les conteste. Restaient les
Pics (« sobre »), le Tombeau de glace (le halo d'étincelles des buffs), le Désastre hivernal et son
Implosion (le disque d'étincelles), l'Orbe gelée (la traînée d'étincelles). **Les textures** : trois
tirages de Qwen-Image (4 à 6 min chacun) — un blizzard en spirale vu de dessus, une spirale de lames
de glace, une orbe hérissée dans sa brume ; ComfyUI arrêté ensuite, avant le banc. Planches :
`Bureau\hns-captures-pics-tombeau\`, `-orbe-gelee\`, `-desastre\`.
- **Les Pics** : l'actuel, la pile (cristaux qui se rongent, esquilles balistiques, glace de la Nova en
  décal, distorsion, scintillements), la pile sous une onde de choc au pied — un anneau blanc épais —,
  la pile sans esquilles. **Retenu : la pile.** Erreur vue sur planche : à demi rongé, un grand pic
  sortait en **papier déchiré blanc** ; rongé en 0,1 s, on ne le voit qu'en passant. Les esquilles
  quittent les particules pour un `MultiMesh` balistique (`IceSpikesFx.Flight`), qui se pose à un
  instant — sur planche comme en test. Le sol fendu (`fx/frost_cracks.gdshader`) part.
- **Le Tombeau** : le halo, une gangue de neuf cristaux penchés vers le joueur, un bloc taillé, la
  gangue sur un anneau de vent. Le bloc **cachait le joueur** (on ne le voyait plus au travers), l'anneau
  sortait en beignet blanc. **Retenu : la gangue** (`FrostTombFx`), qui se brise en esquilles au buff
  éteint.
- **Le Désastre** : le disque, le blizzard A, les lames B, le vent de la Nova enroulé en spirale (la
  texture recyclée, dite), le blizzard sous une distorsion qui tourne — trop brouillée. Le blizzard
  couvrait le cercle d'un **disque presque blanc** ; les lames laissent voir le sol entre leurs bras.
  **Retenu : les lames** (`IceVortexFx`), descendues à 0,75 d'opacité après la capture en jeu.
- **L'Orbe gelée** : un oursin de huit cristaux, l'orbe du Trait de glace en grand — une boule bleue qui
  luit —, un cœur dans la brume, une sphère hérissée, l'oursin dans une brume légère, la photo seule.
  **Retenu : l'oursin dans sa brume** (`FrozenOrbFx`). Erreur vue : la brume, triée avec les cristaux,
  passait devant et les grisait — `sorting_offset`. La couronne d'éclats posée sur planche à la fin
  faisait double emploi avec les vrais éclats de l'orbe : un éclat du Trait en grand suffit.

Captures en jeu : `Bureau\hns-captures-manuel-froid-jeu\` (les quatre), `-arbre-froid-jeu\` (le
Sillon, ses éclats, l'Implosion qui se resserre — son éclatement, celui de la Nova, tombe après la
dernière prise : le Blizzard allonge la durée). **Le code 2D de la glace part** avec le manuel fini,
comme `fx/lightning.gd` : `fx/frost.gd` (son givre, `RIME`, passe à `IceSpikesFx`), les éclats, le flocon
et le bloc du Tombeau d'`EffectForge`. Un piège de test : `wait_frames` compte des images de physique,
entre lesquelles le `_process` d'un dessin peut ne pas avoir tourné — les tests l'appellent eux-mêmes.
**Coût** (le banc des Pics, la compétence en case 0, huit paires alternées par sort, A coupe le dessin,
ComfyUI arrêté — mais **Torchlight Infinite ouvert** sur la machine, 2,2 Go : la même configuration
allait de 18 à 42 ms l'image, contre 16,8 ms stables le 25) : Pics **B − A = +2,5 ± 6,4 ms l'image**
(erreur type 2,3), physique +0,1 ± 1,0 ; Désastre +3,0 ± 6,4 (2,3), physique +0,5 ± 1,0 ; Orbe gelée
−0,9 ± 7,6 (2,7), physique −0,1 ± 1,3. Tout est dans le bruit, mais un bruit de 2 à 3 ms d'erreur type :
ce banc exclut un surcoût de l'ordre de 5 ms, pas d'un millième. **À remesurer machine calme.** Le
Tombeau, qui enferme trois secondes, ne se lance pas en boucle : non mesuré.
**La glace au sol retirée** (26 octobre, au retour de l'utilisateur) : « enlève le visuel du sol gelé sous
les skills qui n'en utilisent pas (encore) (genre désastre etc) ». La glace craquelée en décal se lit
« sol gelé » ; elle ne reste qu'au vrai sol gelé (`FrostGroundFx`, qui garde sa texture et sa pose) et
part du Désastre, des Pics, du Tombeau **et de la Nova** — qui ne gèle pas le sol sans Givre persistant,
la même règle, bien qu'elle ait été choisie dans la vitrine. Signalé aussi : « une petite frame où quelque
chose apparaît puis disparaît » au lancer du Désastre. Pas reproduit : filmé image par image en mode
film de Godot (`--write-movie`, à 60 puis à 165 images par seconde, l'écran de l'utilisateur), le
tourbillon naît net ; le seul éclat bref vu est le blanc d'un ennemi touché et ses pixels de mort. Le
décal, seul suspect restant (un atlas de décals refait à la première texture), part avec la glace.
**Les éclats de l'Orbe gelée** : « les zig zag sont inutiles ». Ils gardaient le Trait de glace, l'orbe
qui zigzague ; ils prennent l'esquille des Pics (`IceShardFx`, déjà choisie sur planche), crachés comme
à l'éclatement, et la Fracture brise une esquille en deux esquilles (`Projectile.fork(…, sliver)`).
**Les deux nœuds qui agissaient sans se montrer**, et les variantes jamais capturées. Planche
(`Bureau\hns-captures-halo-aspiration-planche\`) : le Halo de givre en rien, onde qui s'ouvre, liseré
tenu, souffle d'esquilles ; l'Aspiration en rien, esquilles aspirées (un mouvement, invisible sur image
fixe), anneau qui se resserre, distorsion qui aspire, esquilles et anneau. **Retenus par l'utilisateur :
l'onde qui s'ouvre, et la distorsion** — celle de la Nova à l'envers. Captures en jeu :
`Bureau\hns-captures-halo-aspiration-jeu\`. Les variantes (`-variantes-froid-jeu\`,
`-variantes-froid-coulee-jeu\`), prises par un scénario qui déclenche ses prises à la naissance d'une
explosion de froid : la Crevasse, l'Éclatement du Tombeau, l'Implosion sous la Singularité, la Coulée et
son Ornière. Erreur vue : à 104 px, l'onde de choc de la Nova, large d'une part de son rayon, devenait **un
beignet blanc** ; plafonnée à sa largeur en pixels à 46 px, la Nova ne change pas.

**Le manuel des flammes à la barre de Last Epoch** (26 octobre). L'utilisateur, après le froid : « refait
donc le visuel des skills du manuel de feu avec cette nouvelle méthode, si j'aime bien on adoptera cette
méthode définitivement ». Comme pour le froid, **les planches sont tranchées par moi** et restent sur le
Bureau (`hns-captures-feu-planche-boule\`, `-feu-planche-sol\`) ; l'état d'avant est dans
`-feu-avant\`. Manquaient au feu, parmi les techniques de la Nova : le dissolve à liseré, la distorsion,
des éclats balistiques posables ; et une couche promettait une mécanique absente — **la brûlure craquelée
sous chaque explosion disait un sol qui brûle** (la règle du sol gelé, 26 octobre) : elle part.
**La texture** : une bande de flammes de Qwen-Image pour l'onde de feu, deux graines (7 et 21, la même
flamme en biais), 20 s le pas — **la 7** (`fx/fire_wind.png`, `tools/fx_textures.py fire_wind`).
**Trois couches neuves**, partagées : la chaleur qui tremble (`fx/heat_haze.gdshader`, l'écran décalé par
un bruit qui monte, **dessinée avant le feu** : l'écran qu'elle relit n'a pas les effets, posée après elle
aurait effacé les flammes derrière elle), l'onde de feu (`fx/fire_shock.gdshader`, l'onde de choc de la
Nova en lumière) et les braises (`FireEmbers`, un `MultiMesh` balistique posé par `ember(i)`, **semé au
temps** : semé par image, le compte suivait l'écran à 165 Hz).
- **La boule** : l'actuelle, la pile (braises, chaleur), la pile rouge (la même, ses volutes à 55 %), et
  un ruban de flammes sous la boule — une bande plate aux bouts carrés, écarté. **Retenue : la pile rouge.**
- **L'explosion** (et le Météore, au même code) : l'actuelle, la pile, la pile rouge (photos et volutes
  baissées), la pile sans photos d'explosion. **Erreurs vues** : l'onde aux couleurs de sa photo sortait
  **blanc crème** sur l'ocre — passée à la rampe du feu ; large d'une part de son rayon, elle couvrait **un
  disque plein**, au Météore surtout — plafonnée en pixels à 20 px de rayon ; la somme des photos montait
  au blanc. **Retenue : la pile rouge** (`FireBlastFx`).
- **L'Immolation** : l'actuelle, son liseré en onde de feu sous la chaleur, la même plus une onde à chaque
  impulsion, l'actuelle sous la chaleur. **Retenu : le liseré de flammes** — une onde toutes les demi-secondes
  charge une aura qu'on garde tout le combat.
- **La Ruée** : l'actuelle, la pile aux langues de feu le long du couloir — **des dents orange** —, la pile
  sans elles : chaleur, et **fin rongée au liseré brûlant** au lieu du fondu. **Retenue : la fin rongée.**
- **Le Brasero** : l'actuel (il disparaissait d'un coup), la pile (chaleur, feu qui tombe, fer rongé au
  liseré), la même aux langues de feu dans la coupe, qu'on ne voit pas d'en haut. **Retenue : la pile** ;
  le fer passe en shader (`fx/brazier_iron.gdshader`) et `BrazierFx` à la racine du viewport, qui survit
  `OUT` s à son brasero.
- **Le Serpent** : l'actuel (fin en pointillé), la pile (braises qui montent du corps, fin rongée au liseré,
  la queue d'abord). **Retenue : la pile.**

**Une erreur de planche** à retenir : mon horloge avançait d'un soixantième par image, et l'écran en tourne
165 — les fins à « 2,95 s » tombaient à 1,1 s, jamais atteintes. Les liserés brûlants sortaient tous blancs
(le cœur de la rampe × 3 à 4) : la teinte du milieu, × 1,3 à 1,6. Captures en jeu :
`Bureau\hns-captures-manuel-feu-jeu\`, `-manuel-feu-fins-jeu\` (la Ruée, le Brasero et le Serpent qui finissent) ; la chaleur de
l'explosion marbrait trop le sol, à 0,03 : 0,02. `ElementFx.warm()` éteint désormais tout ce que sa chauffe
fait naître à la racine du viewport, plutôt que de le nommer un par un.
**Coût** (la boule de feu en case 0 contre 300 grunts increvables, sans vsync, huit paires alternées, A
coupe les couches neuves — onde, chaleur, braises —, ComfyUI arrêté, machine calme : 9,6 à 11,2 ms
l'image) : **B − A = +0,65 ± 0,42 ms l'image** (erreur type 0,15 ; sept paires sur huit positives),
physique +0,30 ± 0,54 (0,19), pire image −0,4 ± 2,7. **Hors du bruit, cette fois** : environ 6 % de l'image
quand on ne fait que lancer des boules dans une meute de 300. Les braises se posent en GDScript à chaque
image (35 par boule) : la première chose à couper si le combat dense le demande.

## 14. Reste à faire

- **Où en est l'étape 4** (20 octobre au soir) : le manuel des flammes est refait en textures
  vraies (§13), Brasero compris. **La foudre** commence : l'Éclair vif en foudre est fait (§13) ; fini le 23, Trait de glace, trait en feu, Esquilles, Orbe statique et Satellite compris ; l'interpolation de physique faite le 23 (plus bas) ; la Chaîne d'éclairs faite le 23 (§13, la tresse) ; le Nuage d'orage le 23 (§13, les volutes, la Grêle en grêlons) ; la Ruée d'orage, l'Électricité statique et la marque du Paratonnerre le 24 (§13) : **le manuel de la foudre est fini**, `fx/lightning.gd` retiré. **Le manuel du froid commence** le 25 : les Pics de glace, « sobre », puis la Nova de glace, « souffle d'esquilles », son Onde de givre en javelots et le sol gelé en fissures ; **la Nova refaite à la barre de Last Epoch**, gabarit des manuels à venir (§13) ; le 26, son arbre, puis les Pics, le Tombeau, le Désastre et l'Orbe gelée à la même barre : **le manuel du froid est fini**, `fx/frost.gd` retiré (§13). **Le manuel des flammes refait à la même barre** le 26 (§13) : la méthode adoptée pour de bon si l'utilisateur l'aime. Puis les autres manuels, chacun en textures vraies, variantes
  d'arbre comprises. **Coût à remesurer** au banc A/B (§13, Ruée) : la peau du Serpent, la boule
  de feu en photos, le Brasero ; le manuel de la foudre est mesuré (§13, dans le bruit). **Les couloirs d'équilibrage** à relever
  avant/après la règle « un corps ne bouge pas pendant son geste » (le grunt s'esquive à
  l'élan, le colosse reste planté plus longtemps) — en dernier, jalon 13, §7. Le grunt est
  fait. **Le caster** a son modèle TRELLIS.2 (20 octobre, graine 4242 : les bras les plus détachés,
  doigts ouverts pour Mixamo, robe ouverte sur les jambes ; tour dans `Bureau\hns-caster-modele-3d\`),
  dans `tools/characters/caster/3d/` — **les yeux cyan se perdent au fond du capuchon**, déjà sur le
  modèle brut : un point lumineux en jeu ou une retouche de texture, à trancher. Gréé par Mixamo
  le 20 (repos « Idle », marche « Walk With Briefcase », sort « Standing 1H Magic Attack 01 »),
  `arm_space` à 40° d'office comme le grunt et le Vive lame ; vu sous la lumière du jeu à côté du
  grunt (`Bureau\hns-captures-caster-3d\`, GIF) et en zone, qui tire (`-caster-jeu\`). « Quand il se déplace et
  qu'il attaque, il se place un peu à l'écart, comme s'il se téléportait » : sa marche, « Walk With
  Briefcase », n'était pas *In Place* — les hanches avançaient de 1,52 m sur le cycle (mesuré dans
  le `.glb`), et le corps revenait d'un coup à sa place au sort ou à la boucle. L'export ôte la
  dérive horizontale des hanches (`export_glb.in_place`) : 0,03 m. Les autres marches et tous les
  gestes Mixamo du projet, mesurés, revenaient déjà à leur point de départ. **Le chevalier** (`charger`) est prêt pour TRELLIS.2 : son prompt
  « Torchlight » adulte écrit, image source tirée le 20 (graine 777, la seule sans cape — celle de la
  sorcière collait ses bras au buste ; `Bureau\hns-charger-modele.png`), détourage rangé dans
  `charger/3d/model_front.png`. TRELLIS a refusé ce soir-là, quota du jour épuisé après le caster ;
  passé le 21 (tour dans `Bureau\hns-charger-modele-3d\` : cornes, plates et tabard tenus, dos plus
  sombre). Gréé par Mixamo le 21 (repos « Idle », course « Running »). Les bras rentraient dans
  l'armure à 40° : comparés sur capture à 55 et 70° (`Bureau\hns-captures-charger-bras-*\`),
  **70° et `elbows` à 0,5** — l'écart seul laissait les poings croiser devant le tabard, la course
  de Mixamo étant un sprint. Vu en zone, qui charge (`-charger-jeu\`). Sa charge **appelle**
  `attack()` (`Enemy._strike()` à la fin de l'élan) : son ancien geste écrit retiré, `ActorModel.attack()`
  plantait faute d'animation ; un corps sans geste d'attaque garde maintenant celui qu'il joue, et
  la charge part en courant. Une animation de charge Mixamo (épaule en avant) irait mieux. **Le mortier** : prompt « Torchlight » adulte (le gobelin cuivré
  du jalon 27), graine 4242 le 21 (`Bureau\hns-mortar-modele.png` : bras détachés, et la seule à
  porter des tubes de cuivre sur les épaules, comme des fûts — ils se lisent en plongée), passé par
  TRELLIS.2 le même jour après le chevalier (tour dans `Bureau\hns-mortar-modele-3d\`). Gréé par
  Mixamo le 21 (« Idle », « Running », « Throw » pour son obus en cloche) ; bras comparés sur
  capture (`-mortar-bras-40\`, `-60\`) : à 40°, les poings croisaient devant le ventre à la course et
  en fin de lancer — **60° et `elbows` à 0,5**. Vu en zone, qui tire (`-mortar-jeu\`). **Le gonflé et le colosse** :
  prompts « Torchlight » adultes, graines 777 le 22 (`Bureau\hns-bloater-modele.png`,
  `hns-brute-modele.png` ; bras détachés — la 4242 du gonflé portait des volutes de spores le long
  des bras), passés par TRELLIS.2 le même jour (tours `-bloater-modele-3d\`, `-brute-modele-3d\`) ;
  les volutes sont restées en petites fumées sombres le long des bras du gonflé. **Le quota est de
  deux modèles par jour**, et se recharge 24 h après le premier de la veille (16 h 49), pas à
  minuit — « 174s left » ne suffit pas avant. Le marchand (graine 777, la lanterne pend à la hotte)
  et l'entraîneur (4242, manteau long ouvert, bras dégagés) ont leur image source
  (`Bureau\hns-merchant-modele.png`, `hns-trainer-modele.png`). Le marchand est passé par TRELLIS.2
  le 23 à 19 h 35 (tour dans `Bureau\hns-merchant-modele-3d\`), gréé par Mixamo le 24 : un repos
  seul (« Idle »), il ne marche jamais ; `arm_space` à 40° d'office. Vu sous la lumière du jeu
  (`Bureau\hns-captures-merchant-3d\`, GIF). L'entraîneur est le dernier corps sans modèle : le test
  du repli sur planche le prend ; son modèle venu, ce repli n'aura plus de sujet. L'entraîneur a été refusé juste
  après (« 120s requested vs. 171s left », réessayer 24 h plus tard) : ce jour-là, il ne restait
  qu'un passage. Son tirage, perdu avec le `/tmp` de WSL, a été retiré le 23 à la même graine,
  et son détourage est rangé. Passé par TRELLIS.2 le 24 à 19 h 35, 31 s après le retour du quota
  (tour dans `Bureau\hns-trainer-modele-3d\` : plates, tunique, manteau tenus ; le dos plus sombre). Gréés par Mixamo le 22 : le gonflé
  (« Idle », « Fast Run » ; il enfle sur place, sans geste), le colosse (« Idle », « Orc Walk »).
  **Le coup au sol du colosse, Mixamo ne l'a pas** : écrit à la main, `smash` dans
  `tools/blender/gestes.json` — les deux poings au-dessus du heaume en se cambrant, puis abattus
  ensemble au sol devant lui, buste plongé et un pied en avant, impact à 0,55. Un geste écrit
  l'est pour ce corps : `export_glb` ne lui applique plus `arm_space` ni `elbows`, qui
  corrigent l'acteur de Mixamo et défaisaient les poings joints. 60° et `elbows` 0,5 d'office,
  comme le mortier. Vus en zone (`Bureau\hns-captures-lourds-jeu\`) : le gonflé enfle et
  éclate, le colosse montre son cône et frappe. L'entraîneur gréé par Mixamo le 24 (« Idle » seul, l'épée en main, `arm_space` 40) : **tous les personnages ont leur modèle**. Le repli sur planche (`ActorSprite`) reste : le mannequin d'entraînement, les morts-vivants invoqués et le corps par défaut du joueur sont encore des grilles 2D — retiré un moment sur la foi des seules planches de `art/characters/`, il a cassé 510 tests et a été rendu. Le test du repli porte sur le mannequin. Avant lui : Mixamo à la main
  (l'utilisateur dépose les `.fbx` dans `<id>/mixamo/`), `blender_sheet.py <id> --glb`.
- **Le Vive lame gréé par Mixamo** (18 octobre) : sa garde écrite à la main n'avait « rien de
  naturel », le bras gauche rentré dans les côtes. Copier les animations d'autres jeux est
  exclu (leur travail) ; Mixamo donne de la vraie capture, gratuite et libre dans un jeu.
  L'utilisateur a choisi neuf animations (repos, course, balayage, frappe de haut, estoc,
  rafale, coup 360°, lancer, sort) ; l'export les joue telles quelles, l'épée sur un os de
  prise posé d'après les doigts, l'impact pris à la plus grande vitesse de la main. Ses
  attaques sont à mains nues : l'épée suivait un poing vide (vers le dos, le sol, à rebours
  du coup). L'export oriente la main image par image (`export_glb.wield`) : la lame prolonge
  le levier épaule → main, penchée de 0,7 vers l'avant et 0,3 vers le haut du buste, son
  plat repris de l'image d'avant. Vérifié sur planche, sept attaques × huit images, poignets
  compris (`Bureau\hns-captures-epee\`). Des animations Mixamo d'épée resteraient mieux.
  **La Rafale jouait le « Combo Ver. 3 »**, des coups de poing : le jeu porte trois estocs
  à 0,25 du geste l'un de l'autre (`FLURRY_GAP`). L'export la tire de l'estoc (`repeat`) :
  préparation, extension, puis deux fois retrait à rebours et extension à sa vitesse
  d'origine, calés sur la cadence lue dans `skill_stats.gd` ; impacts à 0,11, 0,36, 0,61.
  **L'impact de l'estoc tombait sur le retrait** (0,47) : aussi vif que le coup. `impact`
  écarte les images où le bras perd plus de 2 % d'allonge ; l'estoc frappe à 0,17, les
  autres gestes n'ont pas bougé.
- **La réduction des modèles TRELLIS.2 fend les visages** au zoom (sorcière nettement, Vive
  lame moins) : voir `tools/characters/LISEZMOI.md`, pièges. Tranché : le corps réduit reste
  en zone, où on le voit de loin ; les vues de face prennent le modèle brut (ci-dessus).
- **La poupée de l'inventaire est petite** (3 × 3 cases) pour un portrait 3D : à agrandir si
  l'utilisateur le demande.
- **Cheveux et peau claire de la sorcière « brûlent »** : ils passent le seuil de lueur de la
  2D, que l'étape 5 revoit.
- Étape 2 : les onze autres personnages en proportions adultes, un par un. **TRELLIS.2 pour
  ceux qu'on voit de près** (les trois classes, le Roi des Rats, marchand, entraîneur), au
  quota gratuit du jour ; les ennemis, TRELLIS.2 ou Stable Fast 3D, à trancher sur les
  premiers vus en jeu. SPAR3D essayé à la demande de l'utilisateur : pas mieux que SF3D.
  **Le grunt d'abord**, au même prompt « Torchlight » adulte : image source tirée le
  19 octobre (graine 4242, les bras les plus détachés du buste), TRELLIS.2 refusé faute de
  quota ce jour-là, passé le 20 (un orque massif, texture tenue de dos ; tour dans
  `Bureau\hns-grunt-modele-3d\`). Le tirage source, dans un temporaire, avait disparu :
  `mesh` reprend le détourage rangé à côté du modèle. Gréé par Mixamo le 20 (repos « Breathing
  Idle », course « Unarmed Run Forward », attaque « Standing Melee Attack Downward ») : Mixamo
  n'a trouvé que l'index, et l'export, qui posait la prise d'après les doigts, s'arrêtait ;
  elle se pose maintenant d'après l'os de la main. Vu sous la lumière du jeu
  (`Bureau\hns-captures-grunt-3d\`, GIF) et en zone (`-grunt-jeu\`). La course est un sprint,
  le couperet levé devant le visage : `blender.elbows` si l'utilisateur le trouve gênant. Vu
  par l'utilisateur : « ses bras rentrent dans son corps à lui aussi » — `blender.arm_space` à
  40°, comme le Vive lame (`Bureau\hns-captures-grunt-bras\`). Et « il continue d'avancer
  pendant son attaque » : **un corps ne bouge pas pendant son geste**, joueur comme ennemi, pour
  que la vitesse d'attaque fasse enchaîner ; le coup part à l'impact (`Enemy._strike`, voir
  ARCHITECTURE, « Quand le personnage joue-t-il son attaque ? »). Tranché avec lui : un tireur
  ne se plante que le temps de son tir (`Caster.SHOT`), pas toute sa cadence de 1,5 à 3,2 s.
- **L'interpolation de physique de Godot, pour tout le jeu — faite le 23 octobre** (décision de
  l'utilisateur le 21). À 60 pas sur un écran à 165 Hz, tout ce qui bougeait au pas avançait par
  à-coups (le tir : 3,83 px une image sur deux ou trois, §13) ; `BoltFx` se lissait à la main, ce
  qui ne passait pas à l'échelle. Activée au projet (`physics_jitter_fix` à 0, comme le veut
  Godot avec elle) ; ARCHITECTURE, « Le mouvement entre deux pas », en tient les trois règles.
  **Vérifié sur un projet d'essai** (Godot 4.7.2) avant d'écrire : un nœud posé dans l'image de
  son `add_child` n'a rien à déclarer ; un saut sans `reset` glisse sur un pas (190 → 400 → 695 →
  991 au lieu de 1 000) ; un nœud interpolé qu'on bouge à l'image traîne et tremble (27,0, 27,6,
  28,9, 30,0 pour 28 à 31) ; un enfant hors interpolation suit son parent interpolé. D'où
  `Player.warp()` (zone, waypoint, portail, ruées, Bond, danse) et des `reset` (portail, rappel
  d'un serviteur, marque qui change de cible, mannequin) ; hors interpolation la caméra, les
  émetteurs d'`ElementFx`, l'écart du zigzag de `BoltFx`, la chute du Météore ; caméra, barres de
  vie, affixes, émetteurs et traînée lisent `get_global_transform_interpolated()`. **Le Serpent
  infernal**, fait d'uniformes que le moteur n'interpole pas, s'interpole à la main
  (`SerpentBody._process()`). Le lissage de `BoltFx` est retiré. **Coût** (300 ennemis en combat,
  sans vsync, A coupée contre B active par `get_tree().physics_interpolation`, sur le même arbre,
  quatre paires alternées — deux premières écartées, ComfyUI tournait sur la carte) : 7,86 contre
  8,18 ms l'image, **+0,31 ms**, de même signe dans les quatre paires ; physique 4,61 contre 4,73,
  dans le bruit. Pas encore jugé en jouant. Au passage, sur le banc seul :
  `ElementFx.warm()`, appelé du `_ready()` de la zone pendant celui du banc, ne peut rien ajouter
  au viewport (trois erreurs `create_timer`, A comme B) — sans effet sur la mesure.
- **Le guide du jeu**, en fin de jalon : la molette, et les deux façons de jouer (ZQSD ou souris).
- `Game.WORLD_ZOOM` grossit encore le texte posé « dans le monde », devenu écran : 18 % trop
  grand. À trancher avec l'interface (§6).
