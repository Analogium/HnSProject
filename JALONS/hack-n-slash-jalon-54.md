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
son disque se pose en différé lui aussi. Restent sans rien les créatures (rats, corbeau,
invocations), les buffs et auras portés par le joueur, et trois cas à part.

**Coût** (300 ennemis en combat, sans vsync, A sans étincelles contre B, six paires alternées) :
sous le bruit du jour — la même configuration allait de 3,2 à 9,5 ms l'image, et B − A valait
en moyenne −0,4 ms (de −0,95 à +0,36). La matière de particules est gardée par nature : fabriquée
à chaque tir, sa rampe partait au GPU à chaque fois. Les télégraphes, mesurés de même, ne se
distinguent pas non plus du bruit ; aux mesures calmes le banc retrouve les ~2,5 ms du §12.

## 14. Reste à faire

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
- **Le guide du jeu**, en fin de jalon : la molette, et les deux façons de jouer (ZQSD ou souris).
- `Game.WORLD_ZOOM` grossit encore le texte posé « dans le monde », devenu écran : 18 % trop
  grand. À trancher avec l'interface (§6).
