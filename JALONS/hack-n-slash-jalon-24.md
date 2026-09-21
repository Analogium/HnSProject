# Hack'n'slash top-down — jalon 24

Suite des jalons 1 à 23. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 19 septembre 2026** (les quatre lots ; §9 dit ce que les
captures ont contredit). Le jeu a seize compétences, une
forge de sprites et quarante-quatre icônes, et il ne ressemble toujours pas à ce qu'il
veut être. La référence demandée est **Hero Siege** : du pixel art saturé, des sorts qui
*émettent* de la lumière, des silhouettes caricaturales qui se lisent dans une mêlée.

Ce jalon soutient que l'écart **n'est pas un écart de dessin**. Il est, dans l'ordre,
un écart de **rendu**, de **palette**, de **matière de VFX**, et seulement en dernier de
**silhouette**. D'où quatre lots qu'on peut arrêter après n'importe lequel.

---

## 1. L'état des lieux

| Ce qui se voit | Où ça vit | Sous quelle forme |
|---|---|---|
| Acteurs — joueur, grunt, caster, dummy | `art/sprite_forge.gd` sur `art/pixel_canvas.gd` | procédural, `FRAME = 32`, 4 variantes × 3 directions × (idle 2, walk 4, attack 2) = **24 images par variante** |
| Couleurs | `art/art_palette.gd` | rampes de 5 teintes, ombre vers un violet froid, lumière vers un blanc chaud |
| VFX de compétences | les 16 scripts de `actors/skills/` | **66 appels de dessin** vectoriel (`draw_circle`, `draw_line`, `draw_arc`…) en blend additif partagé (`ArtPalette.ADDITIVE`) |
| Projectiles, arc de coup, orbes, éclats de dégâts | `actors/projectiles/`, `actors/player/swing_arc.gd`, `actors/items/`, `fx/hit_feedback.gd` | même technique |
| Icônes de compétences et d'objets | `resources/icons/` | PNG hors du jeu (SDXL + `pixel-art-xl`) |
| Tuiles | `world/tileset_builder.gd` | procédural |
| **Rendu, post-process** | **nulle part** | pas de `WorldEnvironment`, `rendering/viewport/hdr_2d` absent de `project.godot` : **aucun glow, aucun bloom** |

---

## 2. Le défaut : cinq écarts, du plus payant au moins payant

**1. Rien n'émet.** Un sort de Hero Siege est une source de lumière ; ici
`holy_pulse.gd` dessine un `draw_arc` d'un pixel à alpha 0,25 sur un sol sombre. Le
blend additif est déjà là, mais sans buffer flottant il **sature à blanc et s'arrête
là** : deux couches additives empilées donnent 1,0, jamais 1,8, donc il n'y a rien
au-dessus du blanc que le rendu pourrait faire déborder. C'est l'écart le plus visible
et le moins cher à combler — il ne touche aucun script de compétence.

**2. Les VFX sont de la géométrie, pas de la matière.** Un cercle net de rayon exact se
lit comme un affichage de portée ; Hero Siege empile des blobs mous, des streaks et des
étincelles qui n'ont pas de bord. Les 66 appels de dessin sont au bon endroit et au bon
moment — c'est leur **primitive** qui est fausse, pas leur logique.

**3. La palette est celle d'un jeu sombre, pas d'un jeu saturé.** `BASE_STOP = 0.6`
place la couleur de base au-dessus du milieu de la rampe pour laisser « plus de place
aux ombres qu'aux lumières » : un sprite est majoritairement dans son ombre. C'est un
choix cohérent, et c'est l'inverse du modèle visé.

**4. Les silhouettes sont anatomiquement justes.** `config()` donne `head_r = 3.8` pour
un corps de 27 px : des proportions réalistes. Hero Siege caricature — tête grosse,
arme surdimensionnée, coiffe qui identifie la classe à dix mètres. En 32 px, il n'y a
pas la place de caricaturer *et* de garder le modelé.

**5. Le joueur a la même facture que ses ennemis.** C'est le seul sprite qu'on regarde
pendant des heures, et il est dessiné par la même fonction que le grunt.

---

## 3. La règle : la lumière est une couche, pas un dessin

Un seul principe porte les deux premiers lots, et c'est lui qui rend le jalon petit.

**Ce qui brille ne se dessine pas plus clair, il se dessine au-dessus d'un seuil.** Le
glow du `WorldEnvironment` ne fait déborder que ce qui dépasse `glow_hdr_threshold`, et
c'est la **valeur** qui trie, pas la couche : le glow s'applique au viewport entier, on
ne peut pas en exclure l'interface.

> Ce paragraphe disait d'abord *au-dessus du blanc*, avec `hdr_2d` pour rendre le
> buffer flottant et laisser l'additif empiler au-delà de 1,0. Mesuré, `hdr_2d`
> linéarise le canevas sans le réencoder : le sol passe de 71 à 14 (§9). Le jeu reste
> donc en LDR, seuil à **0,9**, et deux des trois conséquences ci-dessous ont changé.

- **les sprites ne brillent pas, l'interface si.** Le plus clair pixel d'un sprite est
  à 0,88 — le cristal du caster, 0,02 sous le seuil —, donc le pixel art reste net — c'est l'essentiel. Mais le texte blanc
  du HUD est à 1,0 : il déborde, et rien en LDR ne peut l'en empêcher. Un halo sur les
  nombres de dégâts, on s'en accommode ; l'isoler demanderait un viewport séparé ;
- **l'ombre au sol des sprites ne brille pas.** Un noir à 30 % ne dépasse aucun seuil.
  Le piège du jalon des assets — `core/flash.gdshader` blanchissait l'ombre, mesuré à
  (52,48,45) au repos contre (128,124,121) pendant le flash — **ne se repose pas ici** :
  il vient d'un shader qui repeignait le sprite, pas du post-process ;
- **un impact déborde déjà.** `flash.gdshader` mélange vers `vec3(1.0)` : au-dessus de
  0,9, donc un ennemi qui encaisse brille, sans qu'on ait touché le shader. C'est le
  « pop » du modèle, obtenu gratuitement par le choix du seuil.

Le corollaire, et la découverte du jalon : **le lot A seul ne paie pas**. Les effets
existants dessinaient des aplats à alpha 0,07 à 0,45 sur un sol à 0,26 — ils ne
passaient aucun seuil praticable, et la couche de lumière n'avait rien à faire briller.
Il leur manquait un **cœur**, pas un post-process. Le lot C n'est donc pas la suite
facultative du lot A : c'est ce qui le rend visible.

---

## 4. Les lots, dans l'ordre

Chacun se juge sur une capture avant/après et s'annule d'un `git checkout`. L'ordre
n'est pas négociable : le lot A change l'aspect de tout ce que les suivants dessinent,
donc le juger après eux, c'est le juger deux fois.

### Lot A — la couche de lumière

`rendering/viewport/hdr_2d = true` dans `project.godot`, un `WorldEnvironment` dans la
scène de zone et dans l'arène, `Environment` en `background_mode = Canvas`, glow activé,
seuil à régler à la capture (autour de 1,0, là où l'additif commence à déborder).

Trois réglages et rien d'autre. **Aucun script ne change.** Le glow est un
post-process plein écran : c'est le seul lot du jalon qui se paie en images par seconde,
donc le seul qui **oblige** à relancer le banc (§7).

### Lot B — la palette

`SHADOW_TINT`, `LIGHT_TINT`, `BASE_STOP`, `SHADOW_STRENGTH`, `LIGHT_STRENGTH` : cinq
constantes d'`art_palette.gd`, dont le fichier dit déjà qu'elles « retendent l'ambiance
du jeu entier d'un coup ». Un essai, une capture, on garde ou on jette. Le risque n'est
pas technique, il est de goût : remonter `BASE_STOP` sature les acteurs **et** les
tuiles, et un sol saturé mange les silhouettes qu'il porte. Si les deux ne peuvent pas
vivre avec la même rampe, c'est que la rampe du sol doit s'en séparer — et ça, ce n'est
plus un réglage, c'est une règle en plus. À trancher sur l'image, pas ici.

### Lot C — la matière des VFX

Quatre textures additives produites par `PixelCanvas` (une passe de gradient, pas de
nouvelle couche), mises en cache statique comme les planches de sprites, et utilisées
par `draw_texture_rect` / `draw_set_transform` à la place des primitives. On convertit
**dans l'ordre du gain visible** :

1. `explosion.gd`, `fireball.gd`, `hit_feedback.gd` — ce qu'on voit à chaque coup ;
2. les auras et zones (`immolation`, `holy_pulse`, `sacred_pillar`, `ice_vortex`,
   `storm_cloud`) — les grands aplats, là où un bord net se remarque le plus ;
3. les traits (`chain_lightning`, `holy_beam`, `static_charge`, `dash_trail`) ;
4. le reste, s'il en reste envie.

`hit_feedback.gd` tient la règle à ne pas casser : **un seul nœud dessine tout, sans
allocation par coup**. Une texture ne change rien à ça ; un nœud de particules par
impact, si — d'où l'absence de `GPUParticles2D` dans ce jalon (§5).

### Lot D — la caricature

`config()` uniquement : `head_r`, `sh_w`, `torso_r`, l'échelle de l'arme dans
`_weapon()`. Puis, si 32 px plafonne, `FRAME = 48` — avec `CX = 23.5`, car c'est l'axe
à la demie qui rend la silhouette symétrique au `flip_h`, et `FEET` à revoir dans le
même geste. Le rastériseur ne bouge pas.

Coût : une image de 32×32 coûte **0,265 ms** mesurés, soit 56 ms au premier chargement
d'une zone puis 0 par le cache statique. En 48×48 il y a 2,25 fois plus de pixels ; ce
que ça donne **n'est pas encore mesuré** et se relèvera avant d'écrire un chiffre ici.

### Lot E — le joueur à la main (facultatif, probablement pas dans ce jalon)

La porte de sortie est à moitié ouverte : `[S]` dans la galerie (F4) exporte les
planches dans `art/generated/` — les 16 planches y sont déjà — mais **rien ne les relit**.
`ActorSprite._rebuild()` appelle toujours `SpriteForge.frames()`.

Il manque un override : si `res://art/sheets/<archetype>_v<n>.png` existe, construire les
`SpriteFrames` depuis la planche, sinon forger. Une quinzaine de lignes, et la
cohabitation devient possible — joueur retouché, soixante-neuf ennemis procéduraux. Le
champ vide reste un état normal, comme pour `Skill.icon` et `ItemBase.icon`.

Ce lot est écrit ici pour être **refusé en connaissance de cause** : 24 images par
variante, 4 variantes, 4 archétypes, et il faut que les quatre directions et les deux
temps d'attaque restent cohérents entre eux. `docs/ARCHITECTURE.md` tranche déjà :
« une image immobile se juge une fois ; un sprite qui s'anime dans quatre directions et
cinq variantes, non ».

---

## 5. Arbitrages

**Pourquoi pas tout redessiner à la main.** 4 archétypes × 4 variantes × 24 images =
**384 images**, chacune à garder cohérente avec ses voisines en silhouette, en palette
et en timing. Ce n'est pas un jalon, c'est un métier. Et la forge n'est pas une
commodité qu'on remplacerait : la silhouette d'un ennemi se **déduit de sa case
d'apparition**, c'est ce qui fait qu'une graine de zone redonne le même combat. Des
planches figées gardent cette propriété, un dossier d'images tirées au hasard la perd.

**Pourquoi ComfyUI ne sert pas ici.** Le tuyau existe et il est bon pour ce qu'il fait —
des icônes, qui sont des images immobiles jugées une fois. Il est mauvais pour les deux
besoins de ce jalon :

- **les textures de VFX** : SDXL sort un *objet* dès qu'on lui demande un *phénomène*.
  « a vertical beam of light descending » donne un chandelier, « a godray onto the
  ground » une torche — constaté en ajoutant le manuel sacré. Un blob radial mou, c'est
  un gradient : dix lignes dans `PixelCanvas`, exact, gratuit, en cache ;
- **les planches d'acteurs** : le modèle n'a aucune notion de cohérence entre deux
  images d'une même animation. Chaque frame dériverait. Pour le lot E, l'outil est un
  éditeur de pixels sur les planches exportées, pas un modèle de diffusion.

Donc : **rien dans ce jalon n'a besoin de ComfyUI.** Le serveur ne sera rallumé que si
une nouvelle icône apparaît, ce que ce jalon ne prévoit pas.

**Pourquoi pas de particules GPU.** Un `GPUParticles2D` par impact, c'est un nœud par
impact, et le combat dense en produit des dizaines par seconde — exactement ce que
`HitFeedback` a été écrit pour éviter. Le jour où un effet le demandera vraiment, il se
posera **en un nœud permanent** qu'on émet, pas en un nœud par coup. Hors jalon.

**Pourquoi le glow avant la palette.** Les deux se jugent à l'œil et le premier change
la valeur apparente de toutes les couleurs. Régler la palette d'abord, c'est la régler
contre un rendu qu'on va remplacer.

**Ce qui n'est pas mesuré et qui s'écrira après l'avoir été** : le coût du glow en
images par seconde, le coût d'une image de 48×48, le seuil de glow retenu.

---

## 6. Ce qui refusera un oubli

Le dessin n'a pas d'assertion — « aucune assertion ne voit un panneau qui passe sous un
autre ». Mais trois propriétés de ce jalon sont vérifiables, et deux le sont déjà :

- `test_the_four_player_silhouettes_are_distinguishable` et
  `test_a_silhouette_always_gives_the_same_drawing` (`tests/unit/test_forge.gd`)
  gardent le lot D : une caricature qui écrase les différences entre variantes, ou qui
  réintroduit un tirage, échoue là ;
- `test_outfits_cover_the_variants` garde les quatre tenues si le lot B touche
  `PLAYER_CLOTHS` ;
- **manque, à écrire avec le lot D** : une assertion que le sprite **porte toujours son
  ombre au sol dans son alpha**. C'est l'hypothèse sur laquelle reposent le seuil
  `step(0.5, tex.a)` de `flash.gdshader` et les trois effets qui en dépendent ; un
  changement de `FRAME` ou de `FEET` peut la casser sans qu'aucun test bronche
  aujourd'hui. Forme visée : sur une image de repos, il existe des pixels d'alpha
  strictement entre 0 et 0,5 sous la ligne des pieds ;
- **manque, avec le lot E s'il est fait** : l'override de planche doit se replier sur la
  forge quand le PNG n'existe pas, et donner les mêmes noms d'animations. Un test qui
  charge un archétype sans planche et compte ses animations suffit.

Rien de tout ça ne remplace la capture. **Le lot A et le lot B ne se jugent qu'à
l'image**, en fenêtré : en `--headless`, le pilote de rendu est un bouchon et les
captures sortent vides — et un post-process ne s'y exécute même pas.

---

## 7. Ordre de travail, et ce qui se juge comment

| Lot | Ce qui bouge | Comment on juge |
|---|---|---|
| A | `project.godot`, 2 scènes | capture fenêtrée, zone + arène, un sort de chaque nature ; **banc relancé** |
| B | 5 constantes | capture fenêtrée, mêlée dense sur sol clair **et** sol sombre |
| C | 16 scripts, 1 fonction de `PixelCanvas` | capture par famille d'effet ; `tests/run.sh` (la logique de frappe est couverte, elle ne doit pas broncher) |
| D | `config()`, éventuellement `FRAME` | `tests/run.sh unit` + galerie F4, les quatre variantes des quatre archétypes ; **mesure du coût de forge** |
| E | `sprite_forge.gd`, `actor_sprite.gd` | `tests/run.sh` + galerie |

Le banc à relancer pour le lot A est `world/stress_test.tscn`, graine 4242, en fenêtré,
**après ~240 images de chauffe** — le premier bloc mesure le démarrage (27 img/s contre
165 en régime établi). Référence à battre, ou à ne pas perdre de plus de quelques
pour cent : 165 img/s à 142, 284, 562 et 935 ennemis simulés, et 165 img/s pour
11 ms de physique à 300 ennemis en attaque tenue (`[5]`), 6 % du temps figé.

Un post-process plein écran coûte **par pixel d'écran, pas par ennemi** : si le lot A
se paie, il se paiera pareil à 69 ennemis et à 935, et c'est la ligne à basse charge
qui le dira.

**Doc à mettre à jour dans le même geste**, si les lots passent : le paragraphe de
`docs/ARCHITECTURE.md` sur le rendu procédural (il ne mentionne aucune couche de
rendu), la table « où vit une règle » pour le seuil de glow, et `docs/RECETTES.md` pour
la recette « ajouter un effet visuel » si le lot C crée une primitive de texture.

---

## 8. Hors jalon

- **Les tuiles.** `world/tileset_builder.gd` n'est pas touché. Le sol de Hero Siege est
  plus détaillé et plus contrasté que le nôtre, mais il se juge après les acteurs : un
  sol qu'on regarde est un sol qui a gagné contre ce qui se bat dessus.
- **Une lumière 2D par sort** (`PointLight2D`). Vrai éclairage dynamique, vrai coût, et
  il faudrait un `CanvasModulate` et des normal maps sur les sprites pour que ça donne
  autre chose qu'un rond pâle. Le glow donne 80 % de l'effet pour 0 % de ça.
- **Le shake d'écran et le screen-space distortion d'impact.** Du même registre que le
  glow, moins universels, et le gel d'impact occupe déjà cette place.
- **Les animations en plus** (mort, dégât reçu, sort). Le jeu s'en passe ; ajouter des
  temps d'animation change le ressenti du combat, ce qui est un jalon de jeu, pas de
  visuel.

---

## 9. Livré le 19 septembre 2026

Les quatre lots, dans l'ordre annoncé, chacun jugé sur une capture réelle en fenêtré à
1 280 × 720 — banc `world/stress_test.tscn`, graine 4242, 70 ennemis, aura + nuage
d'orage + pulsation allumés.

### Ce que les captures ont contredit

- **`hdr_2d` est inutilisable.** Il linéarise le canevas et ne le réencode pas : le sol
  tombe de **(71, 66, 61) à (14, 12, 10)**, soit très exactement 0,278^2,2. Tout le jeu
  devient noir. Le réglage reste dans `project.godot` à `false`, écrit plutôt
  qu'absent, pour que personne ne le réessaie sans lire cette ligne ;
- **`glow_bloom` lave l'écran.** À 0,15, il fait entrer le sol lui-même dans le glow
  (71 → 87) : tout se lève, donc le contraste baisse, exactement l'inverse du modèle.
  Laissé à 0 ;
- **le lot B ne parlait pas de saturation mais de valeur.** Mesuré avant : 95 % des
  pixels d'un acteur sont à 0,316 et le sol à 0,29 — **la même valeur**, donc aucune
  séparation figure/fond. Le sol est descendu à 0,21 et les murs l'ont suivi ; c'est ce
  chiffre-là, pas la saturation de la rampe, qui fait ressortir les silhouettes ;
- **un maximum en pointe n'atteint jamais 1,0.** Le premier anneau plafonnait à
  **0,87** — sous le seuil de glow — parce qu'aucun pixel ne tombe pile sur sa crête.
  Les trois dégradés de `fx/glow.gd` ont donc un **plateau** au sommet. Sans le test,
  ça passait pour un choix artistique ;
- **un anneau mou déborde du rayon qu'il annonce.** La première version retombait
  symétriquement de part et d'autre de sa crête, donc son halo allait jusqu'à **1,28
  fois** le rayon où le coup mord — exactement ce que la pulsation sacrée refuse depuis
  son écriture. La retombée est devenue asymétrique : longue à l'intérieur, éteinte un
  pixel avant le bord de l'image. Trouvé à la relecture du diff contre la doc qui
  venait d'être écrite, pas à la capture ;
- **deux pixels par œil donnent un air renfrogné.** Essayé sur la tête grossie du lot D,
  rejeté sur planche : un bandeau sombre, pas un regard. Un œil d'un pixel tient, même
  sur une tête de 9 px.

### Ce qui a été fait

| Lot | Ce qui a bougé |
|---|---|
| A | `fx/bloom.tres` (additif, seuil 0,9, intensité 1,3, niveaux 1-4), un `WorldEnvironment` dans `world/zone.tscn` et `world/test_arena.tscn`, `viewport/hdr_2d=false` écrit explicitement |
| B | `TilesetBuilder.FLOOR_BASE` 0,29 → **0,21**, `WALL_BASE` et `WALL_TOP` d'autant ; `ArtPalette.BASE_STOP` 0,6 → **0,55** et `LIGHT_STRENGTH` 0,42 → **0,52**, plafonnés par le seuil de glow |
| C | `fx/glow.gd` (cœur, anneau, comète) et **17 conversions** dans 14 effets : explosion, immolation, pulsation sacrée, nuage d'orage, boule de feu, vortex, pilier, faisceau, chaîne, charge statique, traînée de ruée, buff, cyclone, pieux, serpent, et l'impact du geste de mêlée |
| D | `SpriteForge.config()` : tête de 3,8 à **4,6** (grunt 5,0, caster 4,0), épaules et buste d'autant, hanches descendues — jambes plus courtes |

**`fx/glow.gd` et non `PixelCanvas`**, contrairement à ce qu'annonçait le §4 : le
rastériseur travaille en (rampe, niveau d'éclairage) pour des silhouettes de sprite, et
un dégradé alpha ne partage rien avec ce modèle. Les textures vivent donc dans `fx/`,
avec le reste des effets.

**`fx/hit_feedback.gd` n'a pas été touché.** Ses éclats sont des carrés d'un pixel posés
sur des coordonnées entières, et son en-tête dit pourquoi : une particule à cheval sur
deux pixels trahit le rendu pixel art. Les adoucir aurait défait un arbitrage mesuré
pour appliquer une recette.

### Ce que ça coûte

**0,05 ms de GPU par image** à 1 280 × 720, glow allumé contre éteint : 0,127 ms contre
0,075, mesuré trois fois en alternance, à ±0,007. Sur les 6 ms d'un budget à 165 img/s,
c'est 0,8 %.

**Piège de mesure, à ne pas réapprendre** : les images par seconde de cette machine ne
mesurent rien — 24, 60, 70, 204, 215, 429 img/s sur la *même* configuration, selon la
place de la fenêtre et l'éditeur ouvert à côté. Seul
`RenderingServer.viewport_get_measured_render_time_gpu()` isole un post-process. Et la
fenêtre de mesure se compte en **pas de physique**, pas en images : à vsync coupée, la
configuration lente joue deux fois plus longtemps que la rapide et ne voit pas la même
scène.

### Ce qui refuse un oubli, maintenant

- `tests/unit/test_glow.gd` (neuf, 4 tests) : le cœur de chaque texture passe 0,95 —
  donc le seuil de glow —, la crête de l'anneau tombe là où `draw_ring` place la
  morsure, la tête de la comète est sur `from`, et une texture n'est construite qu'une
  fois ;
- `test_a_sprite_carries_its_ground_shadow_in_its_alpha` (neuf) : l'ombre au sol est
  toujours dans le canal alpha, ce dont dépend le `step(0.5, tex.a)` de
  `flash.gdshader`. Seize pixels sur une image de repos — les 428 du jalon des assets se
  comptaient sur la planche entière ;
- les trois tests de `test_forge.gd` ont tenu le lot D sans modification.

**829 tests, 829 passent** (824 avant, plus les cinq neufs).

### Ce qui reste

- **`FRAME` est resté à 32.** Le faire passer à 48 ne donne pas « plus de résolution » :
  les coordonnées du squelette sont en pixels de monde, donc un cadre plus grand
  agrandit le personnage **dans la zone**, face à des tuiles de 32. C'est un changement
  de jeu, pas de dessin ;
- **les armes n'ont pas grossi.** La caricature est passée par la tête seule, qui coûte
  huit nombres ; les sept armes de `_weapon()` sont sept séries de longueurs, et l'épée
  de 11 px tient déjà sa place dans la silhouette ;
- **les tuiles n'ont reçu que leur valeur.** Le sol reste un grain uniforme : c'est le
  poste suivant, et le §8 dit pourquoi il vient après les acteurs ;
- **le halo sur le texte du HUD** est le prix du seuil en LDR. Un viewport séparé pour
  l'interface l'enlèverait ; personne ne l'a encore trouvé gênant.

---

## 10. Le vrai défaut, et la deuxième livraison du 19 septembre 2026

Les quatre lots livrés, l'utilisateur a tranché : *« ça ne change pas ce que je veux, ce
que je désire c'est un style pixel art propre tel que Hero Siege »*. Il a raison, et le
§2 de ce document s'était trompé d'ordre : il rangeait la silhouette en quatrième
position derrière le rendu, la palette et la matière des effets. C'était le **premier**
poste, et aucun des trois autres ne pouvait le remplacer.

### Le diagnostic, compté sur une planche

Une image de repos du joueur, agrandie ×10 : **330 pixels opaques, 25 couleurs** —
exactement les 5 rampes × 5 niveaux. Le défaut n'était donc pas le nombre de tons.

Il était dans **qui les place** : un corps assemblé en capsules, dont chaque ton est
déduit d'une formule d'éclairage, change de valeur par pixels isolés et épars. Du
bruit, là où le pixel art propre pose des **bandes franches choisies**. Et rien de ce
qu'une formule ne sait pas déduire n'existait : pas de ceinture, pas de col, pas de
ligne de botte, pas de liseré d'armure, un visage à deux points.

Le plafond de la forge, c'était « des volumes ronds lisibles ». On y était.

### Ce qui a changé

**Les pixels sont écrits à la main, dans le code.** `PixelCanvas.stamp()` pose une
grille — une ligne par rangée, un caractère par pixel — traduite en (rampe, niveau) par
la légende `INK`. Les capsules déduisent leurs tons, une grille les **choisit** ; un
archétype passe par l'un ou l'autre, jamais les deux.

| Archétype | Ce qui est dessiné |
|---|---|
| joueur | 3 corps (face, profil, dos), 3 paires de jambes de face, 3 de profil |
| grunt | 3 corps, 6 paires de jambes — trapu, épaules larges, yeux d'ambre, mâchoire à crocs |
| caster | 3 corps, 3 ourlets de robe — capuche pointue, **aucun visage** : un creux noir et deux braises |
| mannequin | inchangé, il reste un poteau assemblé en capsules |

Trois choses ont été gardées du chemin procédural, et c'est ce qui rend la bascule
petite : le **contour** (posé après coup par `to_image()` sur la silhouette entière,
donc jamais un contour par pièce), l'**ombre au sol** dans le canal alpha, et surtout
l'**arme**, qui reste tracée par `_weapon()` — elle suit l'équipement, elle ne peut pas
être dans une grille. Chaque direction déclare donc le **poignet armé** d'où elle part.

L'animation vient du décalage des grilles : les jambes sont une grille à part posée à
`LEGS_TOP`, le buste respire d'un pixel au-dessus sans emmener les pieds, et sa première
rangée de tunique bouche le trou. `WALK_LEGS` dit quelle paire pour chaque temps de
`WALK_SWING`.

### Ce que les planches ont appris

- **la symétrie n'est pas négociable de face.** Un premier jet avait les cheveux plus
  lourds à gauche « pour la lumière » : ça se lit comme une erreur, pas comme un
  éclairage. La lumière se porte par les **tons** seuls, la silhouette reste symétrique
  — c'est aussi ce qu'impose le `flip_h` du profil ;
- **un trou noir entre deux jambes se lit comme un défaut.** L'entrejambe du grunt était
  en cuir niveau 0 : sur un sol sombre, deux pixels noirs font un accroc. Passé en ombre
  d'étoffe ;
- **une épée tenue à hauteur de ceinture traverse le visage, de profil.** Le poignet du
  profil est donc plus bas et plus en avant que celui de face — un nombre par direction,
  pas une règle générale ;
- **un couperet est plus large qu'une épée** : le grunt de profil a fallu descendre son
  poignet jusqu'à la hanche pour que la lame cesse de recouvrir sa tête ;
- **dessiner dans Godot est trop lent pour dessiner.** Les rampes d'`ArtPalette` ont été
  reproduites en Python, avec la même passe de contour : la boucle passe d'une minute à
  une seconde, et les grilles finales sont recopiées telles quelles. C'est l'atelier qui
  a permis les quinze essais, pas le talent.

### Ce que ça coûte, et ce que ça retire

**829 tests, 829 passent**, sans un test modifié : les trois tests de `test_forge.gd`
tenaient déjà la bonne promesse, et celui de l'ombre au sol écrit au §9 a validé la
bascule sans qu'on y touche.

**Les quatre variantes d'un ennemi ne diffèrent plus que par la teinte.** Le commentaire
de `VARIANTS` promet qu'un paquet de sept grunts ne ressemble pas à sept copies du même
pochoir ; avec une grille par archétype, c'est **exactement** ce que ça devient, à la
nuance de peau près. Trois marques dessinées par variante — cornes, bandeau, balafre —
le rendraient, à raison d'une petite grille posée par-dessus le corps. Laissé à
l'arbitrage : c'est une promesse affaiblie sciemment, pas un oubli.

---

## 11. Les tuiles, par ComfyUI — troisième livraison du 19 septembre 2026

Les acteurs propres, le sol devenait le poste faible. La question posée était : peut-on
**partir d'un pixel art généré** ? La réponse mesurée est oui, mais pas pour tout — et
le décor est justement l'endroit où ça marche, parce qu'il est **statique** : aucune
cohérence d'animation à tenir, aucune symétrie de `flip_h`, et une tolérance au bruit
qu'un visage de 9 px n'a pas.

`tools/tiles.py` (`gen` / `make`) reprend le moteur de `tools/item_icons.py` — SDXL +
`pixel-art-xl`, mêmes réglages qu'au jalon 11 — avec deux différences qui comptent.

**Le négatif est devenu un paramètre.** Celui des objets refuse « tiled pattern » et
« grid » : posé sur une tuile, il combat exactement ce qu'on demande.
`item_icons.workflow()` et `render()` prennent donc un `neg` optionnel, par défaut
l'ancien. *(Au passage : `skill_icons.py` déclare son propre `NEG` mais appelle le
`render` des objets — son négatif n'a jamais servi. Non corrigé, ce n'est pas ce jalon.)*

**Le modèle donne la matière, le code garde la règle.** La génération décide du grain,
des fissures, de la distribution des valeurs. Elle ne décide ni la valeur du sol, ni
quelle tuile de mur porte son dessus éclairé — ça reste peint par sept rangées de code,
comme avant, parce que c'est cette bande-là qui fait lire une masse de murs comme des
blocs et non comme un empilement de briques.

### Les deux chiffres qui ont tout décidé

- **l'échelle de la découpe.** SDXL rend un pavage de briques de ~25 px sur 1024 : réduit
  à 32, chaque pierre pèse **un pixel** et il ne reste qu'un grain gris. Six découpes
  comparées sur planche : à **10 %** du rendu, une pierre fait six pixels et le sol se
  lit. Au-delà de 24 %, c'est du bruit. Ce seul nombre sépare « une texture » de « du
  pixel art » ;
- **à moyenne égale, une texture se lit plus claire qu'un aplat.** Première intégration :
  le sol généré recentré sur la luminance exacte de `FLOOR_BASE` (0,196), c'est-à-dire
  *la même valeur moyenne* que le sol procédural. À la capture, les ennemis s'y
  noyaient : ce sont les joints clairs qui accrochent l'œil, pas la moyenne. Descendu à
  **0,150**, l'écart avec les acteurs redevient celui du §9.

Mesuré sur les trois états, sur la même bande d'image :

| | sol | acteurs (p95) | écart |
|---|---|---|---|
| avant le jalon 24 | 0,262 | 0,316 | **0,053** |
| sprites dessinés, sol procédural | 0,188 | 0,476 | **0,289** |
| sprites dessinés, sol généré | 0,146 | 0,405 | **0,259** |

Le sol généré coûte 0,03 d'écart au sol procédural, et en rend cinq fois plus que l'état
de départ. C'est le prix d'une pierre appareillée, et il est payé sciemment.

### Ce qui a aussi été appris

- **une couture ne se ferme pas par un fondu.** Deux méthodes essayées avant la bonne.
  Fondre au centre après un demi-décalage raccorde la tuile **avec elle-même**, pas avec
  sa voisine : la ligne sombre revenait tous les 32 px. Fondre la dernière bande dans la
  première ferme bien la couture, mais **bave sur cinq pixels de chaque bord**, et cette
  bavure redessine la grille de tuiles à l'écran — pire que le défaut qu'elle corrige.
  La bonne méthode ne touche aucun pixel : on **cherche** parmi quelques centaines de
  découpes celles dont le bord gauche ressemble déjà au bord droit (`best_offsets`,
  erreur de raccord 0,046 sur le sol retenu) ;
- **les quatre variantes doivent partager leur normalisation.** Étirée chacune sur ses
  propres extrêmes, une découpe sombre et une claire ressortent à la même moyenne, et le
  sol devient un patchwork dès qu'elles se touchent. La fenêtre se mesure une fois sur
  le rendu entier ;
- **faire varier la position des découpes, pas leur taille.** Quatre tailles voisines
  donnent quatre échelles de pierre, ce qui se voit immédiatement quand elles se
  touchent.

### Le défaut que l'utilisateur a vu, et la règle qui le corrige

Première intégration livrée, son verdict : *« on dirait que le sol est un mur mais peint
d'une autre couleur »*. Exact, et deux fautes se cumulaient.

La première est un prompt. « dungeon stone floor » sort **un mur de briques** à tous les
coups — le modèle n'a pas de notion de point de vue, il a une notion de maçonnerie. Il
faut la lui interdire explicitement : `brick, brickwork, masonry, mortar lines, regular
rows, running bond, wall, vertical surface` dans le négatif. Les rendus deviennent alors
de vrais sols : dalles irrégulières, pavés ronds, terre battue.

La seconde est plus intéressante, parce qu'elle ne se voit sur **aucun rendu isolé** :

> **Une texture qui couvre son cadre d'un bord à l'autre est une paroi, quelle que soit
> sa couleur.** Un mur est couvert de pierre ; un sol, c'est de la terre avec quelques
> pierres dessus.

Baisser l'amplitude ne suffit pas — ça garde le contour de chaque caillou, donc le
quadrillage. Il faut une rareté **spatiale** : on étiquette les amas de la texture
(`ndimage.label`) et on n'en garde que quelques-uns par tuile, le reste retombant à
16 % de son relief. Et **la tuile qui domine la carte est nue** : `FLOOR_PATCHES =
(0, 3, 4, 5)`. Cette dernière règle était déjà écrite dans le dessin procédural — « tuile
neutre, celle qui domine » —, elle avait juste été perdue en chemin.

Mesuré sur la même bande d'image : l'écart-type du sol passe de **0,034** (pierre
partout) à **0,024** (terre et amas). Il est devenu calme, pas seulement plus sombre.

`TilesetBuilder` charge `art/tiles/atlas.png` s'il existe et retombe sinon sur sa
peinture procédurale — le même partage que `SpriteForge.ART` et les capsules : **une
image qu'on peut juger une fois est un fichier, ce qui s'anime reste du code.**

**829 tests, 829 passent**, aucun modifié : aucune assertion ne voit une tuile, et c'est
écrit dans la recette.

---

## 12. L'arène — quatrième livraison du 19 septembre 2026

Le décor propre, la demande suivante portait sur la **forme** des zones et non plus sur
leur dessin : *« d'assez grands endroits libres de bouger et quelques obstacles ici et
là »*. C'est la définition d'une arène de Hero Siege, et l'inverse d'une caverne.

**L'algorithme n'a pas changé d'une ligne.** L'automate cellulaire de `MapGenerator`
sait déjà faire les deux : tout tient dans `fill_chance`, et il était réglé sur la
caverne. Quinze combinaisons mesurées — part de sol, nombre d'obstacles distincts qui ne
touchent pas l'enceinte, taille médiane, et **distance médiane d'une case de sol au
premier mur**, qui est la seule qui dise « place pour bouger ».

| | sol | obstacles | taille médiane | dist. médiane | **sol à ≥ 4 tuiles d'un mur** | fragments perdus |
|---|---|---|---|---|---|---|
| 0,45 / 5 (caverne) | 58,8 % | 31 | 14 | 2 | **12,7 %** | 283 |
| **0,37 / 6 (arène)** | **83,1 %** | **17** | **20** | **4** | **61,9 %** | **0** |

Le chiffre qui compte est le dernier de la ligne visible : **on passe de 13 % à 62 % du
sol où l'on peut tourner autour d'un ennemi**. Le reste en découle.

Deux réglages plutôt qu'un : à `fill` égal, **cinq passes de lissage donnent 29 cailloux
là où six en donnent 17, plus gros**. Un obstacle de 20 cases fait quatre tuiles sur
cinq — un éperon rocheux ; un de 7 cases est un caillou qu'on ne voit pas. Retenu 0,37 /
6, ce qui donne environ **1,7 obstacle par écran**.

Trois choses vérifiées avant de changer le chiffre, parce qu'elles auraient pu l'interdire :

- **le peuplement ne s'exprime pas en densité** mais en **14 paquets** de 3 à 7
  (`EnemySpawner.pack_count`). Ouvrir la carte ne change donc pas le nombre d'ennemis —
  68 à la graine 4242 contre 69 avant, l'écart d'un seul venant d'un paquet qui place un
  corps de moins. En revanche **ils s'étalent sur 41 % de sol en plus** : à paquets
  constants, on croise donc moins de monde par écran. C'est une décision de jeu, laissée
  à l'arbitrage — `pack_count` à 20 rendrait la densité d'avant ;
- **plus aucun fragment n'est perdu.** `_keep_largest_region()` bouchait 283 cases de
  poches isolées à 0,45 ; à 0,37 il n'en bouche **aucune**. La carte est d'un seul tenant
  par construction, ce qui n'était pas garanti ;
- **la valeur n'était écrite qu'à moitié au bon endroit.** `map_debug.gd` recopiait
  `0.45` et `5` pour son écran de réglage : deux valeurs qui auraient fini par mentir sur
  ce qu'on règle. Elles sont devenues `MapGenerator.DEFAULT_FILL` et
  `DEFAULT_ITERATIONS`, que l'écran lit.

**829 tests, 829 passent.** Un a dû changer : `EXPECTED_ENEMIES` passe de 69 à 68 dans
`tests/e2e/test_zone.gd`. Ce n'est pas un chiffre ajusté pour faire passer un test —
c'est une référence **attachée à un réglage de génération**, et son commentaire dit
désormais lequel, pour que la prochaine session sache à quoi elle est accrochée.

---

## 13. La foudre — cinquième livraison du 19 septembre 2026

Demandé : de **vrais** visuels pour les gestes du manuel de la foudre. Ils étaient au
jalon 11 ce que le §2 reprochait à tout le reste : de la géométrie correcte. Un trait
brisé de trois pixels, un filament d'un pixel, un disque à chaque nœud.

**Un seul endroit, `fx/lightning.gd`**, pour les cinq gestes électriques du jeu : la
chaîne, les éclairs du nuage, les bras de la charge statique, la traînée de la Ruée
d'orage et le projectile de nature foudre. `ChainLightning.broken()` y a déménagé et
disparu : un nuage qui appelait une fonction d'une *compétence* pour dessiner son éclair
disait déjà que la règle manquait d'un toit.

Ce qui fait un éclair plutôt qu'un fil électrique, et qui n'y était pas :

- **des fourches.** Deux branches mortes qui repartent de biais, parfois vers l'arrière,
  sur 16 à 34 % de la portée. Une seule chose sépare une décharge d'un câble, c'est
  qu'elle rate ;
- **trois passes au lieu de deux** : un halo large à 0,10, un corps à 0,28, un filament
  à 1. Le halo porte **la couleur**, le filament porte **la lumière** ;
- **un battement, pas un fondu.** La forme tient 1/18ᵉ de seconde (`Lightning.hold`,
  combiné à la graine du nœud pour que deux éclairs voisins ne battent pas à l'unisson)
  et l'opacité de la chaîne descend par quatre paliers. À une forme par image, l'œil ne
  voit plus un éclair mais du bruit ;
- **un éclat à l'impact**, teinté large et blanc minuscule.

### Trois chiffres, et deux d'entre eux ont demandé une capture

- **Le violet de la foudre plafonne à 0,63 de luminance** (`DamageType.COLORS[3]`), et le
  seuil de glow est à 0,9. Un éclair entièrement teinté **ne peut pas briller**, quelle
  que soit son opacité — le cœur d'avant, à 0,55 vers le blanc, arrivait à 0,79 et
  restait sous le seuil. À 0,92 vers le blanc, il passe. C'est le seul pixel de l'éclair
  qui a le droit d'être presque blanc ;
- **les passes teintées ont une largeur plancher** (4 et 2,2 px). Sans elle, un
  projectile dessiné à 0,55 d'échelle donnait un halo d'1,65 px : invisible derrière le
  filament, donc un éclair **blanc**, qui se lit comme un éclat physique. Constaté à la
  capture, pas au calcul ;
- **l'éclat d'impact est passé de 6 à 4 de rayon, et son blanc à un tiers.** Un disque
  blanchi de rayon 6 fait **26 pixels à l'écran** — le facteur 2 du cadrage se paie ici
  —, et les deux ennemis frappés disparaissaient dessous. Première capture de la chaîne :
  une tache blanche à la place du combat.

Le projectile est le seul écart par nature du jeu : `Projectile._draw()` branche sur
`nature()` et dessine un éclair couché sur sa trajectoire au lieu de la bille à
auréoles. C'est assumé, et écrit dans le code : la foudre est la seule matière qui ait
une **forme** propre, les autres sont des boules qui brillent.

**829 tests, 829 passent**, aucun modifié.

### Un piège d'atelier, pas de jeu

Trois exemplaires du même manuel dans trois cases du râtelier donnent **zéro point** :
le râtelier ne cumule pas deux copies d'un même livre. Et `Player.study()` vide la barre
de toutes les compétences du manuel qu'on pose, donc poser la case juste après chaque
étude la fait effacer par la suivante. Les deux ont coûté deux captures vides avant
qu'un `print` des points ne le dise. Pour piloter plusieurs gestes d'un même manuel :
**un seul livre, tous les `invest`, puis les cases de barre**.

## 14. Le feu — sixième livraison du 19 septembre 2026

Demandé : la même chose que pour la foudre, mais pour le manuel de feu. Le défaut de
départ était plus net encore que celui de la foudre, parce qu'il était **écrit quatre
fois** : quatre triangles de flamme — Immolation, la Ruée ardente, la Boule de feu, et
rien pour le Serpent — et quatre blancs chauds voisins dans quatre fichiers, tous
différents d'un centième.

**Un seul endroit, `fx/fire.gd`**, pour les cinq gestes ardents : les langues
d'Immolation et de la Ruée ardente, les braises d'Ignition, la traînée de la Boule de
feu, son explosion, et le dos du Serpent infernal, qui ne brûlait pas du tout.

Ce qui fait le feu, et qui n'y était pas :

- **un profil qui se renfle.** Une langue s'élargit jusqu'à 30 % de sa hauteur avant de
  se fermer. Un profil qui décroît de bout en bout est un triangle, quelle que soit la
  façon dont on l'anime — c'est ce qu'étaient les quatre d'avant ;
- **trois couches emboîtées**, c'est-à-dire **un dégradé de température** : halo teinté
  à 0,28, corps tiède à 0,34, cœur presque blanc à 0,85. Une langue d'une seule couleur
  reste un triangle orange ;
- **une pointe qui lèche**, déplacée par le carré de la hauteur : le pied ne bouge pas,
  sinon la flamme penche d'un bloc ;
- **une respiration commune** (`Fire.breath`), deux sinus de périodes incommensurables :
  un seul donne un battement régulier, qui se lit comme une boucle d'animation.

### Les chiffres, et ce que seule la capture a dit

- **L'orange du feu plafonne à 0,57 de luminance** et le seuil de glow est à 0,9. Les
  quatre blancs chauds remplacés donnaient des cœurs à 0,75 (l'explosion), 0,79 (le
  serpent), 0,836 (la boule) et 0,899 (le brasier) : **aucun ne débordait**, et deux
  d'entre eux l'affirmaient en commentaire. `Fire.heart()` monte à 0,92 ;
- **en additif, c'est le bleu qui blanchit.** Le blanc chaud en porte 0,78. Trois
  couches franches s'ajoutent par-dessus le sol et saturent les trois canaux avant
  d'avoir l'air chaudes : le premier brasier capturé était une **couronne de dents
  blanches**. Le cœur est donc une mèche — 0,22 de la largeur — et non une flamme
  réduite, et le cœur d'explosion suit la règle de l'éclat de la foudre : teinté large,
  blanc minuscule ;
- **un orange peu opaque sur un sol sombre sort brun.** Le piège était déjà écrit dans
  `Explosion`, il s'est reposé deux fois : le disque d'Immolation à 0,08 faisait une
  flaque à bord net (remplacé par un cœur de lumière, qui s'éteint vers le bord), et le
  ruban de la Ruée ardente à 0,10 se voyait avant ses flammes ;
- **les opacités sont réglées pour l'additif**, celui de quatre appelants sur cinq. Le
  Serpent se dessine en mélange normal, où rien ne s'additionne : ses premières langues,
  à la taille de celles du brasier, étaient invisibles à la capture. Elles sont une fois
  et demie plus grandes, et c'est écrit dans `fx/fire.gd`.

### Un piège de Godot, qui se reposera

**Un sommet en double fait échouer la triangulation** d'un polygone : Godot ne dessine
rien et crie à chaque image. La pointe d'une langue est un point de largeur nulle, donc
les deux côtés s'y rejoignaient sur le même sommet — et seules les plus fines, celles de
la queue du serpent, le montraient. Même chose sous l'aire du pixel : `MIN_HEIGHT` et
`MIN_WIDTH` refusent les langues qu'on ne verrait pas. `test_a_tongue_has_no_duplicated_vertex`
refuse l'oubli.

**833 tests, 833 passent**, aucun modifié.

### Ce que le banc de capture a demandé

Le scénario de capture est celui de la foudre, à trois choses près, toutes trouvées à
leurs dépens : **les sorts veulent une baguette** (l'épée de départ les refuse tous, et
`cast_slot` répond `false` sans rien dire de plus) ; **l'explosion d'un tir part où le
tir touche**, c'est-à-dire souvent hors cadre, donc elle est posée à la main à 64 px du
joueur, même nœud et même geste résolu ; et une capture jugée **au triple zoom**, parce
qu'à l'échelle de l'écran une langue de huit pixels ne se juge pas.

## 15. La glace — septième livraison du 19 septembre 2026

Demandé : la même chose pour le manuel du froid. Ses quatre cases n'avaient pas le
défaut des deux autres manuels — rien n'était écrit quatre fois —, elles avaient
l'inverse : **un trait d'un pixel pour tout relief**. Un triangle plat avec une arête
claire pour les pics, une polyligne d'un pixel pour les bras du vortex, un hexagone
cerclé pour le tombeau, des carrés de deux pixels pour les éclats.

**Un seul endroit, `fx/frost.gd`**, pour les quatre gestes froids, plus les esquilles
de la Nova de glace, qui passe par `Explosion`.

### Le chiffre qui retourne la règle des deux autres matières

**Le cyan du froid porte 0,81 de luminance** — contre 0,57 pour le feu et 0,63 pour la
foudre. C'est la matière la plus claire du jeu, et à pleine opacité sur le sol elle
monte à **0,933** : elle dépasse le seuil de glow *sans qu'on y ajoute quoi que ce
soit*. Tout ce que le feu et la foudre ont appris s'inverse donc :

- là où une flamme a besoin d'un cœur presque blanc pour déborder, **la glace n'a besoin
  de rien**. L'éclaircir ne fait que lui retirer sa teinte : la pointe des pics d'avant,
  à 0,55 vers le blanc, avait 0,775 de rouge — du verre, pas de la glace ;
- ce qui lui manquait n'était pas de la lumière mais de **l'ombre**. Et en mélange
  additif on n'assombrit rien : ombrer veut dire **retirer de l'alpha**, pas de la
  couleur.

D'où la forme : un cristal est **deux flancs et une arête**. La même teinte à 0,34 et à
0,62, l'arête de givre à 0,95 entre les deux. Les deux flancs diffèrent — symétriques,
ils donnent un sapin, et sept sapins en cercle une couronne de l'avent.

### Ce que les captures ont corrigé

- **Les pics étaient des esquilles.** À 1,4 de demi-largeur pour 18 de haut, sept
  cristaux en rond se lisaient comme un éclat de verre brisé. À 2,4 + 1,6 ils percent le
  sol ;
- **une spirale lisse est un coup de pinceau.** Les bras du vortex passent de neuf
  segments à cinq : c'est la brisure qui dit la glace. Ils ont gagné une passe large
  teintée sous leur pixel de givre, et **une lame au bout**, couchée sur la spirale —
  sans elle, rien ne dit dans quel sens le vortex tourne ;
- **le disque de fond du vortex faisait une flaque à bord net**, le même piège que le
  brasier d'Immolation trois heures plus tôt, corrigé de la même façon : un cœur de
  lumière à la place du disque plein.

La Nova de glace a servi à ranger `Explosion` : la matière du souffle — langues pour le
feu, esquilles pour le froid — vit maintenant dans `_matter()`, et le blanc du cœur dans
`_core()`, **par nature**. Une nova nécrotique qui jetterait des flammes mentirait sur ce
qu'elle fait ; elle n'a que l'onde, et c'est écrit.

**837 tests, 837 passent**, aucun modifié. Le Tombeau de glace a coûté une capture vide :
il est refusé pour réserve insuffisante, et `cast_slot()` répond `false` sans dire
laquelle de ses six raisons — c'est le troisième piège d'atelier du même genre.

## 16. Le vrai défaut des effets, et un essai — 20 septembre 2026

L'utilisateur, devant les trois matières livrées : « c'est trop moche ». Il avait
raison, et le diagnostic des §13 à §15 était **à côté**. J'ai passé trois livraisons à
régler la lumière, les opacités et les formes d'effets qui sont tracés en polygones,
alors que le défaut est que ce ne sont **pas des pixels**.

### La mesure qui tranche

Deux carrés de 55×60 pixels dans la même capture, un ennemi et une langue de flamme :

| | couleurs | voisins identiques | pixels de contour |
|---|---|---|---|
| ennemi (sprite de la forge) | **29** | 77,5 % | **12,5 %** |
| langue de flamme (polygones) | **423** | 58,3 % | **0 %** |

Le jeu tourne en 640×360 étiré au double : un pixel d'art fait deux pixels d'écran. Un
polygone tracé en flottants tombe **entre** deux pixels du jeu et sort anti-aliasé à la
résolution de l'écran. Ajoutons qu'aucun effet n'a de contour, là où tout le décor en a.
Les effets sont peints dans une autre langue que le jeu, et à une autre résolution. Rien
ne rattrape ça au réglage — c'est le même défaut qu'au §10, où c'était *qui place les
pixels* qui manquait, et je l'ai refait sur les effets.

### ComfyUI n'y peut rien

Question posée, réponse mesurée : non, et il n'y a rien à installer.

1. Le défaut n'est pas le dessin mais la grille. Une image générée sort lisse et doit
   être ramenée au pixel du jeu par le traitement des tuiles (§11) ;
2. SDXL n'a **aucune cohérence d'une image à l'autre** : six images d'explosion générées
   ne sont pas la même explosion. Il faudrait AnimateDiff ou ControlNet, non installés,
   qui se battent de toute façon avec la grille ;
3. tout ce qu'il faut est déjà là : `PixelCanvas`, `ArtPalette.ramp()`, la passe de
   contour, les grilles dessinées à la main du §10.

### L'essai : le brasier d'Immolation

Un seul geste converti, pour juger avant d'engager le reste. `art/effect_forge.gd` :

- **quatre temps d'une langue, dessinés à la main**, neuf pixels sur treize, montés par
  `PixelCanvas` avec deux rampes — celle de la teinte et celle du cœur — et le contour
  posé par la forge autour de la silhouette ;
- **un halo de sol tramé** (Bayer 4×4, trois paliers) à la place du dégradé radial : un
  dégradé lisse était la dernière chose de l'aura qui trahissait le vecteur ;
- les planches se posent sur une **coordonnée entière** : posée entre deux pixels du
  jeu, une planche se rééchantillonne et ses blocs de deux pixels se brisent ;
- elles se dessinent dans un nœud **en mélange normal**, pas dans l'additif de l'aura :
  un contour sombre n'ajoute rien en additif, il disparaît, et avec lui ce qui rattache
  l'effet au décor.

Dans le même carré de 18×26 : **82 couleurs et aucun contour** avant, **40 et 4,3 %**
après. Capture à trois volets dans `21-preuve-pixels.png` — un ennemi, la langue
d'avant, la langue forgée.

**841 tests, 841 passent.** Le reste des effets est inchangé, et se voit sur la même
capture : c'est la comparaison.

### Le serpent, deuxième essai — 20 septembre 2026

« C'est vrai que c'est un peu mieux » : le brasier passe, le doute reste. Deuxième
geste converti, et le plus dur des deux, parce que **sa forme change à chaque image**.
Une planche ne peut donc pas être gardée : il faut la refaire.

Deux tentatives, la première jetée :

1. **Une file de perles** — un disque forgé par anneau, posé sur la grille, avec un
   contour en passe séparée pour que l'union soit cernée une fois. Résultat à la
   capture : un dos **moiré et bosselé**. Seize dégradés côte à côte font du bruit, et
   le contour d'une grosse perle ressort entre deux petites ;
2. **le corps rastérisé en entier**, une capsule d'un anneau au suivant dans un seul
   `PixelCanvas`, contour posé autour de l'union — exactement ce que la forge fait pour
   un personnage. Un seul volume éclairé, une seule silhouette.

**Mesuré au banc** (`capture/bench_snake.gd`, seize anneaux dans 96×96) : **0,64 ms par
image**, dont 0,47 pour `to_image` seul et 0,17 pour la mise en capsules — **0,61 ms**
une fois la tête, la crête et les yeux ajoutés. Refait **30
fois par seconde** et non 60 — le serpent avance d'un pixel par image, sa forme n'en
change pas —, ce qui ramène la dépense à **0,32 ms par serpent**. La texture est mise à
jour et non recréée, donc le cadre est fixe (96×96) et `to_image` ne balaie de toute
façon que ce qui est peint.

Trois réglages trouvés à la capture, et un seul compte vraiment :

- **une braise n'a pas d'ombre violette.** Les creux du corps tiraient au brun-violet et
  la bête ressortait en **tronc d'arbre** : c'est `ArtPalette.SHADOW_TINT`, qui accorde
  tous les sprites du jeu entre eux, mais qui suppose une lumière extérieure. Ce qui est
  sa propre source prend une ombre rouge sombre — `ramp()` accepte désormais la sienne ;
- **cinq tons le long du corps et non trois** : à trois, les changements se lisaient
  comme deux coutures en travers du dos ;
- **une tête d'un pixel plus large** que le premier anneau, sinon la bête est un tuyau
  qui s'amincit et on ne sait pas par quel bout elle avance.

Le corps est aussi passé de 3,8 à 5 de rayon : une silhouette cernée perd un pixel de
matière au contour, et à trois le serpent sortait ver de terre. `CONTACT` n'a pas bougé
— la morsure est la même.

**841 tests, 841 passent.** Captures `23-serpent-forge.png` et `24-serpent-de-pres.png`.

### Le serpent, troisième essai : ce qu'un volume éclairé n'invente pas

« Le serpent ne me convainc pas assez. » Regardé à nouveau, et cette fois sur une image
où il est **droit** : ce n'est pas un serpent, c'est un tuyau. Un volume éclairé donne le
galbe, jamais l'identité — c'est le §10 pour les personnages, reposé pour les bêtes.

Plutôt que de deviner ce qui manquait, **une planche de sept corps sur la même échine**,
rendue hors du jeu (`capture/snakes.gd`, pur calcul, donc headless) : l'actuel, une tête
sculptée, des écailles franches, un corps de charbon fendu de lave, une crête dorsale,
et deux cumuls. Choix de l'utilisateur : **tête + crête + queue**.

Les trois choses qui manquaient, et qui ne se calculent pas :

- **une tête**, faite d'un crâne et d'un museau — deux capsules, donc elle tourne avec le
  corps sans demander une planche par direction. Plus deux yeux de **deux** pixels : à un
  seul, l'œil disparaît sur une tête de dix pixels ;
- **une crête dorsale**, un pixel clair le long de l'échine. Vue de dessus, une bête n'a
  pas de dos sans elle. Elle **meurt avant la queue** et s'éteint en chemin : menée
  jusqu'au bout à pleine clarté, elle se lisait comme un ruban peint sur la bête ;
- **une queue en pointe** — 0,8 de rayon au lieu de 2. Arrêtée net, elle donnait un tuyau
  coupé.

Le tout coûte **0,61 ms par image** au même banc, toujours refait à 30 Hz.

**841 tests, 841 passent.** Planche de choix `25-serpents-a-choisir.png`, résultat en jeu
`26-serpent-final.png` (droit et lové, les deux cas).

### Le cran au-dessus : une planche d'animation — 20 septembre 2026

Demandé : voir ce que donne une vraie planche dessinée **image par image**, comme un
sprite de personnage, et non une forme qu'on anime en la déplaçant. Fait sur la **boule
de feu** : six temps de treize pixels de côté, plus trois bouffées de traînée.

Le choix du geste n'est pas libre, et c'est la découverte de ce lot : **une planche ne
supporte ni la rotation ni le redimensionnement.** Pivotée, elle se rééchantillonne et
ses blocs de deux pixels d'écran se brisent ; agrandie d'un facteur qui n'est pas entier,
ses pixels deviennent inégaux. Donc :

- **la boule de feu** y a droit : sa taille est une constante, et une boule n'a pas
  d'orientation — il a suffi de lui retirer la rotation que `Projectile` pose sur tous
  les tirs, et de placer sa traînée à la main derrière elle ;
- **l'explosion n'y a pas droit** : son rayon est une statistique, qui va de 20 pour la
  Boule de feu à 46 pour la Nova de glace, et qu'un nœud agrandit encore. Elle restera
  faite de dessins **replacés** — des langues sur un cercle — ou d'un tracé.

C'est la règle qui manquait, et elle range les trois chemins du dessin d'effet : planche
d'animation pour ce qui est de taille fixe, planches replacées pour ce qui se répète,
rastérisation par image pour ce qui change de forme.

Deux détails que la planche a redemandés, et qui sont les mêmes que pour le brasier :
**pas de mélange additif** — un contour sombre n'y ajoute rien et disparaît —, et un
**calage sur le pixel du jeu** à chaque image.

Quatorze images par seconde pour la boule : plus lent, elle clignote ; plus vite, le
dessin se perd et il ne reste qu'un scintillement. Deux tests refusent l'oubli : les
grilles rectangulaires, et **six temps réellement distincts** — une animation dont deux
images sont identiques est une image fixe payée deux fois, et rien ne le dirait.

**843 tests, 843 passent.** Planche `27-planche-boule-de-feu.png`, en jeu
`28-boule-en-vol.png`.

### Le brasier et le serpent, choisis sur planche — 20 septembre 2026

La méthode promise au tour précédent, appliquée pour de bon : **deux planches avant
d'écrire une ligne**. Six langues de brasier (`29-langues-a-choisir.png`, chacune seule
puis posée en couronne à l'échelle du jeu) et six serpents, flammes comprises
(`30-serpents-a-choisir.png`). Rendues en `--headless`, pur calcul.

Retenu : **la langue au pied sombre**, et un serpent **plus fin, plus long, à écailles
franches**.

- **Le pied sombre pose la flamme.** Un dégradé vertical franc — presque noir au pied,
  blanc à la pointe — au lieu d'une langue claire de bout en bout, qui flottait au-dessus
  du sol. C'est la variante que la couronne à l'échelle du jeu a départagée : les autres
  s'y lisaient comme des bougies ;
- **la finesse fait le serpent.** Vingt anneaux de 2,85 et quatre de rayon, au lieu de
  seize de 3,6 et cinq : le même corps cesse d'être un tuyau qui ondule. L'écart est
  choisi pour que **la longueur totale ne bouge pas** — 54 pixels —, sinon la morsure
  s'allongerait avec le dessin, et un changement de dessin n'a pas à toucher
  l'équilibrage ;
- **une bande sur deux de deux crans plus sombre** : le seul motif qui survive à la
  taille où la bête est vue.

Le corps s'étant allongé de quatre anneaux, les langues du dos sont passées d'un anneau
sur trois à un sur quatre — à trois, le peigne que le premier réglage avait retiré
revenait. Le corps plus fin coûte moins cher : **0,58 ms par image** au banc, contre
0,61.

Les langues du dos du serpent **gardent leur pied clair** : posées sur la bête et non au
sol, un pied sombre y ferait un trou.

**843 tests, 843 passent.**

### Un trou dans la campagne, trouvé par accident

En remplaçant les grilles de la langue, j'ai supprimé `EffectForge.FLAME_HZ` sans le
voir. **`tests/run.sh unit` est passé au vert** : les tests unitaires ne chargent pas les
nœuds de compétence, donc rien n'a vu que `Immolation` et `HellSnake` ne compilaient
plus. C'est la capture en jeu qui l'a dit, par un `SCRIPT ERROR` dans sa sortie.

La leçon vaut au-delà : **une suite unitaire verte ne dit pas que le jeu compile.** Le
garde-fou existant de `run.sh` ne voit que les scripts *de test* qui ne compilent pas.
Lancer la suite complète, ou une capture, reste le seul moyen de le savoir.

### L'explosion et la Ruée ardente — 20 septembre 2026

Deux planches encore (`33-explosions-a-choisir.png`, `34-ruees-a-choisir.png`), cinq
souffles et quatre traînées. Retenu : **l'explosion en langues seules**, et la
**traînée en sillon continu**.

**L'explosion sans anneau.** Le choix retenu est celui que je ne recommandais pas — et
il est le bon pour une raison que la planche ne montrait pas : c'est le seul qui ne
mette **qu'une matière** à l'écran. Un anneau tracé à côté de langues dessinées, ce sont
deux façons de peindre le feu dans la même image. Onze langues au lieu de cinq, parce
que dessinées elles doivent se toucher pour faire une onde, et un **éclat en étoile** au
centre, en trois temps : un disque blanc est un trou dans l'image, une étoile est un
coup. Rien ne dépasse le rayon qui mord : les langues **sont** l'onde.

**Le sillon.** Une file de brûlures qui se recouvrent tous les quatre pixels, et des
langues plantées dessus. C'est ce qui remplace le ruban brun que le §14 avait déjà dû
affaiblir : on voit enfin qu'on est passé par là.

Deux corrections prises à la capture :

- **une cendre grise est invisible.** Le sol du jeu est déjà à 0,21 de luminance ; la
  brûlure ne peut pas se faire voir en étant plus sombre. Elle est donc **brune** — la
  braise qui couve dans la terre — avec une ombre chaude, comme le serpent. Un test
  vérifie qu'elle reste malgré tout sous le sol ;
- **une langue tous les treize pixels faisait une palissade.** Les langues dessinées
  font neuf pixels de large, contre trois pour les tracées d'avant : l'écart passe à
  vingt-deux, ce qui redonne la densité de la planche.

Les deux nœuds perdent leur mélange additif **quand leur nature est le feu**, et le
gardent sinon : une planche cernée n'ajoute pas de lumière, elle en cache.

**845 tests, 845 passent.**

### Deux réglages demandés, et ce qu'ils ont appris

« Plus instantanée et court » pour l'explosion, « plus de flammes sur le chemin » pour
la Ruée.

**Le souffle peint dure moitié moins que le tracé** : 0,16 s contre 0,30. Ce n'est pas
un caprice de durée, c'est une conséquence du médium — un effet tracé s'éteint par un
dégradé, un effet dessiné n'a que des images. Tenue trois dixièmes de seconde, la
couronne de langues se mettait à ressembler à un feu de camp posé là. Trois valeurs le
font :

- l'onde atteint son **plein rayon en trois centièmes de seconde** (un cinquième de sa
  vie) au lieu des deux tiers : c'est ce qui la rend instantanée plutôt que soufflée ;
- la couronne reste à **pleine opacité jusqu'aux deux tiers**, puis s'éteint d'un coup.
  Un fondu progressif se lit comme un feu qui meurt, une coupure comme un souffle — la
  même raison qui donne son battement à la foudre ;
- l'éclat en étoile brûle ses trois images en **un huitième de seconde** : il doit avoir
  disparu avant que l'œil ne le détaille.

**Ce qui faisait la palissade du sillon n'était pas le nombre de langues mais leur
régularité.** Je l'avais corrigé en les espaçant — 13 px puis 22 —, ce qui vidait le
couloir. La vraie correction est l'alternance : une grande langue, une petite, la petite
écartée de l'axe à tour de rôle. À 11 px d'écart, le chemin est deux fois plus fourni
qu'avant et ne s'aligne plus.

**845 tests, 845 passent.**

## Le manuel de glace, dessiné

Le feu était entier ; restait l'autre matière qui a une forme propre. Quatre gestes :
**Pics de glace**, **Nova de glace**, **Tombeau de glace**, **Désastre hivernal**.

### La planche d'abord

Six silhouettes de cristal, chacune montrée seule **et** en couronne de sept — c'est
le geste qu'on juge, pas le dessin isolé. Deux variantes se sont éliminées toutes
seules : le **prisme à étages** sortait en sapin (le piège que `fx/frost.gd` annonçait
déjà : deux flancs identiques font un conifère), et l'**aiguille** en pilier.

Choisie : la **lame facettée**, deux flancs francs et l'arête de givre entre les deux.
Et deux tailles alternées plutôt qu'une, pour la raison apprise sur la Ruée — ce qui
fait une palissade, c'est la régularité, pas le nombre.

La demande qui a tout orienté ensuite : **le Désastre hivernal doit être un
tourbillon**, pas un cercle de pics.

### Ce qui se dessine, et comment

| geste | ce qui le dessine |
|---|---|
| Pics de glace | sept cristaux alternés grand/petit, sur un givre de sol tramé |
| Nova de glace | un anneau d'éclats qui file, puis onze cristaux debout derrière lui |
| Tombeau de glace | un bloc de 21×29, posé à 0,8 d'alpha : le seul dessin qu'on regarde **à travers** |
| Désastre hivernal | douze bras d'éclats couchés sur leur cap, et des flocons aspirés |

Le tourbillon a demandé une chose que le feu n'avait jamais demandée : **une planche
ne tourne pas**. Un éclat orienté sur sa tangente ne peut donc pas être pivoté — il
faut le dessiner dans chaque sens. Deux grilles (droite, diagonale) et trois quarts de
tour chacune donnent les **huit orientations**, le quart de tour étant la seule
rotation qu'un dessin en pixels supporte sans se rééchantillonner. La lumière tourne
avec, ce qui serait faux sur un sprite posé, mais un éclat emporté culbute.

Même piège, autre bout : le cristal qui **sort de terre**. Une planche étirée se
rééchantillonne, donc la sortie n'est pas un redimensionnement mais un **découpage** au
ras du sol (`draw_texture_rect_region`) — le pied reste au sol et la pointe monte.

### Les deux erreurs que seules les captures ont dites

**Un cristal qui s'estompe sort gris.** C'est le retour, pour la troisième fois du
jalon, du « orange peu opaque qui sort brun » : posée à demi-transparente sur un sol à
0,21, une planche claire se mélange au sol et perd sa teinte. La campagne ne voit rien,
la capture le crie. Un dessin ne s'éteint donc pas en pâlissant :

- les pics et la couronne de la nova **redescendent sous terre** — le même découpage,
  à l'envers ;
- le tourbillon **se vide** : à mesure qu'il meurt, ses éclats disparaissent un à un
  selon une trame stable. Un éclat en moins se lit comme un éclat en moins ; un éclat à
  demi transparent se lit comme de la boue ;
- ce qui s'efface encore sont le givre au sol et les flocons, qui sont faits pour ça.

**Un flanc sombre vu à travers n'est pas de l'ombre, c'est de la crasse.** Le tombeau,
dessiné sur toute la rampe comme un sprite ordinaire, sortait en caillou gris une fois
posé sur son porteur. Sa rampe ne descend plus sous le troisième palier : la glace
s'ombre d'un cran, pas de quatre.

Dernier réglage de composition : les bras du tourbillon s'égrenaient en collier à leur
extrémité, parce qu'un pas constant en paramètre parcourt deux fois plus de chemin au
bord qu'au centre. Les rangs sont donc étirés vers le bord (`pow(t, 0.6)`).

### Ce que la livraison a rendu mort

Le manuel de feu et celui de glace étant tous deux dessinés, **plus personne ne trace
de flamme ni de cristal** :

- `Fire.tongue`, `draw_tongue`, `breath` et le profil des langues — supprimés, avec
  leurs trois tests de forme ; `fx/fire.gd` ne garde que sa couleur et la braise
  d'Ignition, seul geste du feu encore tracé ;
- `Frost.shard`, `draw_shard`, `tip`, `draw_flake` et les opacités de facette —
  supprimés ; `fx/frost.gd` devient le fichier qui **pose** les planches ;
- `Explosion._matter()`, qui ne servait plus que ces deux natures, et les branches par
  nature de son cœur et de son éclat ;
- le calage sur le pixel du jeu, écrit **sept fois** depuis le début du jalon, tient
  maintenant dans `EffectForge.snap()`.

**845 tests, 845 passent.**

### Douze bras plutôt que quatre

Demandé après coup : « beaucoup plus de branches ». Planche de quatre densités — 4,
6, 8, 12 — au rayon plein, et c'est **12** qui a été retenu.

Ce que le nombre change n'est pas la quantité mais la **forme** : à quatre, on voit
quatre traits qui tournent ; à douze, les bras se touchent au cœur et font une roue
pleine, ce qui donne enfin un œil au tourbillon. Et le geste raconte alors ses deux
temps — une roue serrée sur le lanceur au début, puis, à mesure qu'il grandit et se
vide, une **tempête de neige** d'éclats épars qui découvre le porteur. C'est le nom
de son premier nœud, Blizzard.

Rien d'autre n'a bougé : l'espacement reste celui du dessin, donc un bras de douze
coûte ce que coûtait un bras de quatre.

**845 tests, 845 passent.**

## Le manuel sacré, dessiné

Quatre gestes : **Frappe sacrée**, **Pulsation sacrée**, **Pilier sacré**,
**Lumière sacrée**. Et un problème que ni le feu ni la glace n'avaient posé.

### Le trait part dans n'importe quelle direction

Une planche ne pivote pas. Pour le tourbillon, la réponse avait été de dessiner
l'éclat dans ses huit sens ; un trait de quatre-vingts pixels ne peut pas se
contenter de huit caps — à 11° près, sa pointe tomberait à huit pixels de ce
qu'il mord.

Planche de cinq traits. Deux chemins s'y opposaient :

- le **chapelet de marques** — losanges, croix — qui part dans n'importe quelle
  direction sans rien calculer, mais dont les planches se recouvrent : chacune
  porte son propre contour, et le trait sort effrangé. C'est le « tas de
  saucisses cernées » que `PixelCanvas` évite en ne cernant que la silhouette
  **finale** ;
- le **trait rastérisé d'un coup**, qui n'a qu'une silhouette donc un seul
  contour, au prix d'une rastérisation par lancer.

Retenu : le trait plein, avec son éclat de départ (choix de l'utilisateur), et
les ondes de la Pulsation en **étincelles**.

### Ce que la rastérisation coûtait, et ce qu'elle coûte

1,78 ms pour une diagonale — trop cher pour un sort qu'on relance deux fois par
seconde, quand une image de jeu en vaut six.

Le coupable n'était pas le dessin mais le **balayage** : `to_image()` parcourait
le rectangle englobant, et un trait en biais n'occupe que 14 % du sien.
`PixelCanvas` borne maintenant son balayage **par rangée** et non par rectangle,
ce qui descend le trait à **1,16 ms** et profite à tout ce que la forge dessine.
Les bornes se tiennent en variables locales dans la boucle de capsule et ne
s'écrivent qu'une fois par rangée : deux accès indexés par pixel auraient coûté
plus que le balayage épargné.

### Une lumière n'a pas de dessous

Le trait, éclairé comme un objet — d'en haut à gauche, comme tout le reste du
jeu —, sortait avec un flanc mauve sombre et se lisait comme un **os**. Poussé
tout en haut de sa rampe, il s'aplatit et perd son rose. À 0,35 il garde un peu
de volume sans avoir d'ombre : c'est la seule matière du jeu qui ait sa propre
règle d'éclairage, parce que c'est la seule qui *soit* la lumière.

Le blanc du sacré, lui, vivait dans trois fichiers à trois valeurs — 0,55, 0,60
et 0,80 vers le blanc —, exactement le désordre des quatre blancs chauds du feu.
Il n'y en a plus qu'un, et il est mesuré : **0,70, soit 0,91 de luminance**, juste
au-dessus du seuil de glow.

### Le reste du manuel

- la **Pulsation** envoie seize grains qui s'écartent les uns des autres à mesure
  que l'onde s'ouvre. Leur nombre ne change pas : c'est leur écartement qui dit
  que l'onde grandit, et ils n'ont donc jamais besoin de pâlir ;
- le **Pilier** est une tranche de colonne **carrelée**, dont la grille est pleine
  bord à bord : `PixelCanvas` ne lui pose alors aucun contour, et deux tranches
  posées l'une sur l'autre ne montrent pas de barre sombre entre elles. Le bord
  de la colonne est dessiné *dans* la tranche. Elle défile d'un nombre entier de
  pixels par image — c'est ce qui fait **couler** la lumière — et se coiffe d'une
  pointe qui reprend exactement le profil de la tranche. Elle tombe du ciel, puis
  se retire par le haut ;
- la **Lumière sacrée** monte six grains autour du porteur, à pleine opacité :
  trois pixels qui s'effacent s'éteignent en gris bien avant d'avoir disparu.

Les grains dessinés de tous les manuels suivent maintenant cette règle. Seules
les braises d'Ignition gardent leur fondu — elles sont tracées, c'est le dernier
geste du feu en polygones.

**846 tests, 846 passent.**

## Le manuel du maître d'armes, dessiné

Cinq gestes — **Frappe lourde**, **Coup en croix**, **Vague tranchante**, **Épée
spirale**, **Cyclone** — et l'**Attaque** de base, qui partage leur croissant. Le
problème qu'ils posent ensemble est celui qu'aucun autre manuel n'avait posé à
cette échelle : **tout y pivote**. Les arcs suivent la visée, la vague sa course,
les lames du cyclone et l'épée leur cercle. Et une planche tournée se
rééchantillonne.

### Fabriquer au cap

Le trait sacré se rastérisait une fois, à sa naissance. Un coup d'arme ne peut pas
se le permettre : il s'anime, et il part dix fois par seconde. La réponse est un
**cache par cap** — trente-deux, un tous les 11,25° —, rempli au premier passage :

- ce qui est **géométrique** — croissant, entaille — se rastérise directement au cap ;
- ce qui est **dessiné à la main** — l'épée — se dessine une fois, pointe à droite,
  et se **tourne** au cap par un échantillonnage à vote : neuf points par pixel, on
  garde l'encre la plus fréquente. Comparé sur planche au plus proche voisin, c'est
  le vote qui garde une lame d'un pixel d'un seul tenant. Le contour se pose
  *après* la rotation : tourner un contour le rendrait épais d'un côté.

Le temps d'un coup est arrondi à l'un de ses **huit temps** : sans cela, chaque
image fabriquerait une forme que le cache ne retrouverait jamais.

Mesuré au premier passage par un cap : croissant de frappe 0,9 ms, lame du cyclone
0,6, entaille 0,3, épée 0,8 — 1,6 avant que la rotation ne saute les pixels loin de
la lame et ne soit gardée pour les silhouettes rémanentes (0,2 ms de plus
chacune). Les passages suivants ne coûtent rien.

### Ce qu'un test a trouvé

Un quart de tour de l'épée perdait **cinq pixels sur trente-neuf**. Le cadre tourné
n'avait pas la parité de la grille, si bien que chaque centre de pixel d'arrivée
tombait **pile sur une frontière** de la grille de départ, et le vote tranchait au
hasard. Le cadre prend maintenant la parité de la grille ; le test qui exige un
quart de tour sans perte reste.

### Le croissant

Choisi sur planche : la **lame pleine** — fil blanc, corps teinté, **lourd en tête et
effilé en queue**. Épais au milieu, comme le tracé d'avant, il se lisait comme une
feuille ; c'est l'épaisseur en tête qui dit dans quel sens la lame passe.

Et il ne se trame pas en finissant : sa traîne **se résorbe dans la tête**, et le coup
s'achève sur sa pointe. Tramée, la fin du coup ressemblait à la variante en damier
écartée sur la même planche. Ce qui se dissout, ce sont les entailles, l'impact de
la frappe, la vague en fin de course et l'épée qui disparaît — et la dissolution se
fait **après** le contour (`EffectForge.dissolve()`) : avant, chaque pixel restant
serait cerné pour lui-même et le dessin tournerait en poussière noire.

Les images rémanentes de l'épée sont sa silhouette, **tramée** plutôt que
transparente — une ombre à 30 % d'opacité sur un sol sombre sort grise.

**865 tests, 865 passent.**

### Une compétence de plus : la Ruée tranchante

Demandée en même temps : « un dash qui effectue un coup d'épée sur toute la
traversée ». Elle prend la case libre (2, 1) du manuel, au niveau 5 comme les
autres ruées, avec deux nœuds — **Fil tranchant** (+12 % de dégâts amplifiés par
point) et **Andain** (+15 % de rayon accru, donc un couloir plus large).

**Pas de forme neuve.** C'est une `DASH` dont la trace a une période **égale à sa
durée** : `strikes_over_duration()` rend alors un seul coup, donné à tout le
couloir — une cible sous deux sondes n'est frappée qu'une fois, la trace le
garantissait déjà. Cadence de l'arme, donc un coup d'arme pour les affixes, et une
recharge de 3 s pour qu'on ne la prenne pas pour un moyen de transport.

Son dessin est la seule forme du manuel qu'on **ne peut pas** arrondir au cap le
plus proche : la coupe court sur toute la traversée, et à 140 px, 5° d'erreur la
feraient finir à douze pixels du joueur. Elle est donc fabriquée **à l'angle
exact**, une fois par ruée, et jamais gardée (`Slash.cleave()`) — chaque ruée a la
sienne, la garder ne ferait que remplir la mémoire. Mesuré : **1 ms** par ruée,
une fois, bornée par rangée comme le trait sacré. Des étincelles s'en arrachent
de part et d'autre ; la coupe, elle, ne pâlit pas.

Les nombres (16 à 40 par point, 10 mana) sont pris aux voisines et **non
équilibrés** : l'équilibrage se fait en dernier (jalon 13, §7). `EQUILIBRAGE.md`
sort identique après régénération — les couloirs qui échouent échouaient déjà.
Elle n'a **pas encore d'icône** : la case retombe sur le disque de sa couleur.

**866 tests, 866 passent.**

#### Son icône, et un nœud de cadence

**L'icône** sort du tuyau des compétences (`tools/skill_icons.py`), sur deux
planches de quatre sujets. Le premier tour est retombé dans le piège déjà noté :
demander un **trait** — « a long diagonal sword slash streak » — rend une épée
**verticale**, et la graine 777 raye. C'est le personnage saisi en pleine ruée qui
dit le mouvement ; retenu sur la seconde planche : « a swordsman dashing
horizontally at great speed, sword held forward, white speed lines streaking
behind him », graine 1337, sur l'ardoise du chevalier. Refait par le tuyau, le
tirage est identique à l'octet près à celui de la planche.

`apply` a gagné un `--only` : son cache vit dans un dossier temporaire, et sans
lui il exigeait les tirages de toutes les compétences, vidés depuis.

**Le nœud « Enchaînement »** est le pendant d'arme de « Sans répit » (Ruée d'orage) :
−100 % de recharge, +500 % de temps du geste. La recharge effacée, c'est le geste
qui borne la case — et le geste d'une compétence d'arme se lit **sur l'arme**, donc
c'est la **vitesse d'attaque** qui décide, là où « Sans répit » rend la main à la
vitesse d'incantation. +500 % et non +400 : à 0,45 s par coup, la ruée repart
toutes les 2,7 s, un peu mieux que ses 3 s de recharge — le nœud doit valoir un
point. Même place dans l'arbre, (0, 1), deux points dans la compétence, un seul
dans le nœud.

Le test qui l'accompagne vérifie les deux côtés de la promesse : la vitesse
d'attaque doublée coupe l'attente en deux, celle d'incantation ne touche rien.

**867 tests, 867 passent.**
