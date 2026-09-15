# Architecture

Ce document dit **où vit chaque règle** et **ce qu'on ne peut pas casser**. Les
`hack-n-slash-jalon-*.md` disent ce qu'il fallait construire et pourquoi,
dans l'ordre où ça a été décidé ; celui-ci décrit l'état actuel, sans
chronologie.

## Le postulat

**Aucun asset n'existe sur le disque.** Pas une image, pas une planche de tuiles.
Les sprites, les icônes d'objets et le TileSet sont calculés par du code au
premier appel, puis gardés en cache pour la session. Une graine dérivée du nom et
du numéro de variante fait que le même personnage ressort identique à chaque
lancement.

Ça a deux conséquences que rien d'autre dans le projet ne rappelle :

- **ajouter du contenu visuel, c'est écrire une fonction**, pas importer un
  fichier — voir [RECETTES.md](RECETTES.md) ;
- **la génération procédurale est une règle de jeu**, pas une commodité. La
  silhouette d'un ennemi se déduit de sa case d'apparition, pas d'un tirage :
  c'est ce qui fait qu'une graine de zone redonne exactement le même combat.

La porte de sortie existe : `[S]` dans la forge (F4) exporte toutes les planches
en PNG, retouchables dans un éditeur d'image.

## La carte

| Dossier | Ce qu'on y met | Connaît |
|---|---|---|
| `core/` | Les règles et les données du jeu. Aucun dessin, presque aucun nœud. | rien du reste |
| `art/` | Le rendu procédural : rastériseur, forge de sprites, galerie de réglage. | `core/` |
| `world/` | La carte, le champ de chemin, le peuplement, la scène de zone. | `core/`, `art/`, `actors/` |
| `actors/` | Ce qui bouge : joueur, ennemis, projectiles, objets au sol. | `core/`, `art/` |
| `ui/` | Les panneaux et l'affichage tête haute. | `core/`, `art/` |
| `fx/` | Le retour visuel des coups. | `core/` |
| `tests/` | La campagne GUT — voir [tests/README.md](../tests/README.md). | tout |
| `tools/` | Les outils hors jeu (génération de cette documentation). | tout |
| `resources/` | Les `.tres` : bases d'objets, affixes, fiches d'archétypes, **manuels, compétences, passifs et arbres de talents**. | — |

**Le sens de circulation ne s'inverse jamais.** `core/` ne remonte pas vers une
scène, un nœud ou un panneau. C'est ce qui permet à la moitié de la campagne de
tourner sans arbre de scène, et c'est le premier symptôme à surveiller : un
`preload` d'une `.tscn` dans `core/` est une régression d'architecture.

**Deux exceptions assumées**, et elles sont dans `core/` parce que c'est là que
vit la règle qu'elles appliquent :

- `core/hurtbox.gd` est une `Area2D`. Elle est le **point de passage unique de
  tous les coups du jeu**, et la mitigation qu'elle applique est écrite dans
  `CharacterStats`, à côté.
- `core/settings.gd` est un autoload `Node`. Il porte les réglages du joueur, pas
  l'état de la partie — ce dernier est dans `Game`.

Les déplacer réécrirait des chemins `res://` dans quatre `.tscn` et dans les
autoloads pour zéro gain de comportement. Décidé : on ne les déplace pas.

## Les feuilles

Ces classes ne dépendent de rien. C'est volontaire : GDScript refuse les cycles
de dépendances, et chacune est née d'un cycle qu'il fallait casser.

| Classe | Pourquoi elle est seule |
|---|---|
| `DamageType` | `CharacterStats` nomme ses résistances par nature, et `DamageInfo` nomme déjà `CharacterStats`. |
| `Tirage` | `ItemAffixPool` précharge les `.tres` d'`ItemAffix` ; un `ItemAffix` qui appellerait la réserve refermerait la boucle. |
| `Touches` | Sept scènes lisent le clavier, aucune n'a à connaître les six autres. |
| `ArtPalette`, `UiPalette` | Les couleurs sont lues par tout le monde et ne lisent personne. |
| `Textes` | La traduction est demandée par les tables de libellés, par le contenu et par les panneaux : elle ne peut nommer aucun des trois. |
| `MotsCles`, `StatsDeCompetence` | `StatMod` y lit le nom de ce qu'une ligne portée vise, et `Competence` applique des `StatMod` : qu'elles nomment l'une ou l'autre, et la boucle se referme. |
| `Etats` | `DamageInfo` le nomme pour dire qui frappe, et `Hurtbox` pour ce que porte la victime : il reçoit des parts et un auteur, jamais un coup. |

## Où vit chaque règle

| La question | La réponse |
|---|---|
| Combien un coup fait-il vraiment ? | `CharacterStats` (armure, esquive, résistances ; la défense d'une part, `attenuer()`), appliqué **part par part** par `Hurtbox` : l'armure sur la part physique, sa résistance à chaque autre nature, le plancher sur le total |
| Quels objets tombent dans une zone ? | `ItemCatalog.disponibles()` |
| Jusqu'à quand une base tombe-t-elle ? | `ItemCatalog.fenetre_de_chute()` |
| Quels affixes une base peut-elle porter ? | `ItemAffix.fits()` via `ItemAffixPool.compatibles()` |
| Quels paliers un objet atteint-il ? | `ItemAffix.ouverts()` |
| Combien d'affixes sur un objet neuf ? | `ItemAffixPool.COUNT_WEIGHTS` |
| Quelle rareté ? | `Item.rarity()`, **déduite** du nombre d'affixes |
| Où va un objet équipé ? | `EquipmentSlots.free_for()` |
| Ce qui tient dans le sac ? | `Inventory.fits()` |
| Comment s'écrit une valeur à l'écran ? | `StatMod.format()` / `gauge()` / `range_label()` ; des dégâts résolus, `StatsDeCompetence.fourchette_lisible()` ; un pourcentage, `StatMod.pourcentage()`, dont la typographie suit la langue |
| En quelle langue s'écrit un texte ? | `Textes.t()`, dans la fonction qui **lit** le libellé — jamais chez celui qui le dessine. Le texte français est la clé ; l'anglais vit dans `i18n/en.po`, et `Settings.langue` choisit |
| Jusqu'où descend une fenêtre flottante ? | `Hud.haut_des_jauges()` : les jauges sont dessinées après les panneaux, et passeraient par-dessus |
| Ce que rapporte un ennemi ? | `Enemy.xp_value()`, dérivé de ses PV donc du niveau de sa zone — **sans borne haute** |
| Quand l'expérience fond-elle ? | `Enemy.facteur_d_experience()` : sur une zone laissée **derrière** soi, jamais sur une zone trop haute |
| Par où passe un ennemi ? | `FlowField`, à défaut la ligne droite |
| Ce qui survit à la fermeture ? | `Personnage.vers_dict()` et `Settings.vers_dict()` |
| Ce qu'un lancer fait vraiment ? | `Competence.resoudre()`, par `Player.resoudre()` — **appelée par le lancement, la page du manuel et la fiche de personnage** : dégâts par nature en fourchette et leur décomposition, projectiles, dispersion, vitesse, coût, intervalle |
| Combien une compétence inflige-t-elle en moyenne ? | `StatsDeCompetence.moyenne_par_lancer()` et `moyenne_par_seconde()` : si tout touche, avant défenses, sans critique |
| Combien fait un coup parti ? | `StatsDeCompetence.tirer()` : une fois par projectile, une fois par coup d'épée pour tout son arc, une fois pour une chaîne entière, une fois par impulsion d'un nuage ou d'une aura, une fois par contact d'un serpent ou d'une épée — avec `Game.rng` et **un tirage par fourchette ouverte** |
| Quels mots-clés porte une compétence ? | `Competence.mots_cles()` : les déclarés, plus ceux que donnent la nature et la cadence, sur la liste fermée de `MotsCles`. Ceux d'un **lancer** sont dans `StatsDeCompetence.mots_cles`, nœuds d'arbre compris |
| Dans quel ordre se lisent-ils ? | `MotsCles.ordonner()`, et nulle part ailleurs : ils arrivent de trois sources et deux compétences voisines doivent se lire colonne contre colonne |
| Une ligne d'affixe vise-t-elle la fiche ou un mot-clé ? | `StatMod.portee` — vide pour la fiche. `StatMod.apply_all()` écarte le reste, `Player.recompute_stats()` le range dans `mods_de_competence`, avec la force changée en dégâts physiques aux attaques |
| À quelle cadence se lance-t-elle ? | `Competence.intervalle()` : la fiche pour l'arme, la recharge du sort pour l'incantation |
| Que pose un lancer dans le monde ? | `Competence.forme`, lue par `Player.lancer()` **sur la compétence** : aucun nœud ne la change. Elle porte le comportement et le dessin ensemble, et `projectile` s'en déduit |
| Combien de coups porte un lancer, si tout touche ? | `StatsDeCompetence.moyenne_par_lancer()` : projectiles × cibles × coups de la forme × `frappes_dans_la_duree()` — **la fonction même qui compte les impulsions du nuage**. Une aura n'a que `moyenne_par_seconde()` |
| Quels chiffres de dégâts s'affichent ? | `Settings.montre_les_degats()`, lue par `HitFeedback` pour le coup, l'esquive et la brûlure : une case pour ce que subit le joueur, une pour ce que subissent les ennemis. Le chiffre seulement — la gerbe d'éclats reste |
| Que ferme Échap ? | `Zone.fermer_les_interfaces()`, dans `_input` : ce qui est **visible** — sac, fiche, manuels, établi, menu de la barre —, et le menu de pause seulement quand rien ne l'était. Par la visibilité et non par `Game.ui_grabs_input`, que la fiche ne prend qu'avec des points à placer |
| Qu'est-ce qu'on peut lancer ? | `Player.lancer()`, qui porte les cinq refus — case vide, non apprise, réserve, recharge, orbite pleine. Une aura allumée s'y **éteint** sans coût, et la touche tenue ne la rallume pas |
| Qui atteint un coup qui ne naît pas d'une collision ? | `Cibles.dans_le_cercle()`, sur le calque des hurtbox ennemies : la chaîne, le nuage, l'aura, le serpent, l'épée, l'explosion. **Jamais depuis un rappel de collision** — l'espace y est verrouillé |
| Qu'est-ce qui fige le jeu parmi les compétences ? | Ce qui frappe d'un geste : coups d'arc, tirs, chaîne. **Ce qui dure ne fige jamais** — un nuage gèlerait l'image à chaque impulsion |
| Ce que coûte l'Immolation ? | `Player.bruler()` : répartie entre les natures comme les dégâts de l'aura (`StatsDeCompetence.repartition()`), chaque part atténuée par `CharacterStats.attenuer()` — **la règle d'un coup reçu**, donc objets et passifs compris, et l'engourdissement. Pas un coup pour le reste : ni esquive, ni plancher d'un point. **Mortelle** |
| Quand le jeu se fige-t-il ? | `Game.hit_stop()` : **un gel par geste et non par cible**, et `hit_stop_periode` entre deux. Sans elle, une compétence tenue sur une nuée figeait le jeu 12 % du temps sans qu'aucune image ne se perde |
| Qui secoue la caméra ? | `Game.shake_camera()`, **une seule secousse à la fois** : relancée, elle reprend la plus forte des deux amplitudes au lieu d'en empiler une seconde |
| Quand une touche de compétence part-elle ? | Le sondage de `Player._physics_process()` : **tenue, elle relance à chaque fin de recharge**, et ne s'arme qu'au passage à l'état enfoncé — un bouton encore baissé quand un panneau rend la souris ne lance rien |
| Combien de points dans une compétence ? | `Player.points_de_competence()` : le manuel du râtelier qui l'enseigne, ou un seul pour ce que liste `CompetenceCatalog.DE_DEPART` |
| Une ligne se donne-t-elle en fourchette ? | `StatMod.stat_en_fourchette()` ; la ligne qu'un affixe ou un implicite donne, `StatMod.depuis_definition()` |
| Quel niveau a un manuel ? | `Manuel.niveau()`, **déduit** de son expérience par `Progression` |
| Peut-on y placer un point ? | `Manuel.peut_investir()` — les quatre conditions, jamais dans l'interface |
| Où un manuel apprend-il ? | Au râtelier seulement, par `Player.recompenser()` — le chemin d'une mort **et** d'une boule d'expérience de l'établi, avec le retard sur la zone |
| Que porte une case de manuel ? | `CaseDeManuel` : une compétence **ou** un passif — jamais les deux —, sa position, et l'arbre de talents de la première |
| D'où viennent les talents d'un lancer ? | `Player.talents_de()`, qui passe par le livre du râtelier qui enseigne la compétence. Ils entrent dans `Competence.resoudre()` **sans être filtrés** : un nœud ne vise que sa propre compétence, et c'est tout ce qui le distingue d'un modificateur d'objet |
| Ce qu'un passif change, et quand ? | `Manuel.mods_de_passifs()`, versé par `Player.recompute_stats()` dans **la même liste** que les objets portés — donc trié par la même règle entre la fiche et les mots-clés. Seulement au râtelier : un livre du sac ne donne rien |
| Peut-on placer un point ? | `Manuel.peut_investir()`, pour les trois sortes de destination. `est_ouvert()` porte les conditions **structurelles** seules, pour que la page distingue « verrouillé » de « plus de point à placer » |
| Peut-on le reprendre ? | `Manuel.peut_reprendre()`, pour les trois sortes : pas un nœud sous un enfant qui porte des points, pas une compétence sous les points qu'un de ses nœuds investis demande. `Player.reprendre()` vide la barre d'une compétence retombée à zéro |
| Où convertit-on des dégâts ? | `StatsDeCompetence.convertir()`, appelée par `resoudre()` **après les fourchettes ajoutées**, sur **toutes les natures** du coup : entière, il n'en reste qu'une, donc qu'un état possible. `convertis` en garde la part pour la fiche |
| Dans quelle nature un tir se dessine-t-il ? | `StatsDeCompetence.nature_dominante()` : celle de la compétence, ou celle où une conversion a emmené le plus gros de ses dégâts **propres** — ce qu'un objet ajoute ne change pas la couleur |
| Un coup pose-t-il un état ? | `Etats.subir()`, appelée par `Hurtbox.take_damage()` **après** l'esquive, la mitigation et le signal : 20 % pour un coup entièrement d'une nature, partagés selon ses parts, **un tirage par nature présente**, physique compris. Chance, durées et forces sont les constantes de `Etats` |
| Qui a porté un coup ? | `DamageInfo.auteur` — les états de l'attaquant, jamais son nœud —, posé par ce qui fabrique le coup ; un tir le lit sur son lanceur par `Etats.de()` |
| Ce qu'un état change, et où ? | Les facteurs de `Etats`, lus **là où vit déjà la règle** : la bénédiction de l'auteur avant la mitigation, l'engourdissement après ; le gel dans `Enemy.vitesse_de_deplacement()`, `Enemy._cool_down()` et la cadence de `Player._physics_process()`. Ce qui brûle sort d'`Etats.avancer()` et s'ôte par `_set_health()`, chez l'ennemi depuis l'`EnemyManager`, avec la régénération |
| Comment un état se voit-il ? | Dans la couleur de sa nature, sauf le saignement (`Etats.SANG`), sur le signal `Etats.change` : `HealthBar.montrer_les_etats()`, qui dessine l'icône de chacun (`IconeDEtat`, un masque 7×7 par état), et `ActorSprite.montrer_les_etats()`. Le nom au-dessus du **joueur seul**, par `HitFeedback.etat()` ; ce qui brûle, par `HitFeedback.degats_sans_coup()` et les paquets d'`Etats.Paquet` |

## Les invariants

Ce sont les huit choses qui cassent silencieusement. Aucune ne se voit à la
compilation, et la moitié ne se voit qu'au lancement suivant.

### 1. Les identifiants écrits sur le disque ne changent jamais

`ItemBase.id`, `ItemAffix.id`, les clés de `EquipmentSlots.SLOTS`, les
identifiants de `MotsCles` — la portée d'un affixe en nomme un —, ceux de
`DamageType.IDS` — ils forment le nom des dégâts ajoutés, `degats_froid` —, ceux
de `Competence`, `Passif` et `NoeudDeTalent` — les trois partagent le
dictionnaire de points d'un manuel, et **deux identiques dans un même livre
partageraient un compteur** — et les noms de champs de `Personnage.vers_dict()`
sont **dans les sauvegardes des joueurs**.
Renommer `chest` en `torse` fait disparaître le plastron de tout le monde — au
prochain chargement seulement, sans erreur.

Le nom lisible est à côté (`display_name`, `label`) et se change librement.
`test_les_identifiants_du_jalon_4_survivent` et
`test_les_emplacements_d_avant_gardent_leur_nom` gardent la porte.

### 2. Un `.tres` du disque ne s'écrit jamais

Aucune ressource du projet n'est `resource_local_to_scene`. Écrire dans
`base_stats`, dans un `ItemBase` ou dans une fiche d'archétype touche **le
fichier**, donc toutes les parties suivantes de la session — et l'éditeur peut
graver le résultat.

`duplicate()` avant toute écriture. C'est la séparation `ItemBase` / `Item`,
`base_stats` / `stats`, et c'est pourquoi `Enemy._ready` ne copie sa fiche que
si quelqu'un va réellement y écrire.

### 3. Le hasard du monde passe par le tirage de la zone

Une même graine doit redonner exactement la même zone : mêmes murs, mêmes tuiles,
mêmes ennemis, mêmes silhouettes, mêmes affixes. `Game.rng` est le fil des
tirages de la partie — son état dépend de tout ce qui a été tiré avant, donc il
ne peut rien reproduire.

| Ce qu'on tire | Avec quoi |
|---|---|
| La carte, les paquets d'ennemis | le RNG de zone, réamorcé sur la graine |
| La silhouette, les affixes, le sens de rotation d'un ennemi | `hash()` de la case d'apparition |
| **Le butin** | `Game.rng`, **et c'est voulu** |
| Qu'un coup pose un état | `Game.rng` : un tirage par nature présente dans le coup, physique compris |
| La gerbe d'éclats, la secousse de caméra | leur tirage à eux — `HitFeedback._rng`, `Game._rng_camera` |

Le butin est l'exception : il récompense une action, pas un lieu. Adossé à la
case, tuer le même ennemi dans une zone qu'on revisite redonnerait toujours le
même objet, et recharger suffirait à garantir une chute.

Corollaire moins évident : **une fonction doit consommer le même nombre de
tirages quel que soit son résultat.** C'est pourquoi `Hurtbox` teste
`evade > 0.0` avant d'appeler `randf()` — sans ça, chaque coup du jeu décalerait
les graines de zone tirées ensuite.

### 4. Rien ne naît depuis un rappel de collision

Godot refuse qu'on ajoute une `Area2D` à l'arbre pendant qu'il résout les
collisions : *« Can't change this state while flushing queries »*. Or un ennemi
meurt presque toujours depuis un `area_entered`.

- `GroundItem.spawn()` fait `add_child.call_deferred()` puis
  `set_deferred("global_position", …)` — dans cet ordre, une position globale ne
  voulant rien dire hors de l'arbre ;
- `Player._swing()` passe par `set_deferred("monitoring", …)`, et **attend une
  image de physique** avant de rouvrir la hitbox pour le second coup d'une croix :
  fermée puis rouverte dans la même image, elle ne coupe rien, et un ennemi déjà
  dedans n'y *entre* pas une seconde fois ;
- `Explosion.poser()` naît en différé et ne frappe qu'à sa première image de
  physique : la boule qui l'appelle est dans son rappel de collision, où l'espace
  refuse les requêtes ;
- la mort du joueur et la montée de niveau repassent par `call_deferred`, sinon
  la liste de l'`EnemyManager` rétrécit sous ses propres pieds.

Et : **`is_instance_valid()` avant tout `as`** sur une référence conservée.
Convertir un objet déjà libéré est en soi une erreur, qui interrompt la fonction
avant son `queue_free()` — c'est ce qui faisait traverser le joueur par le tir
d'un caster abattu à distance, en le blessant à chaque image.

### 5. Un seul pilote, un seul point de passage

| Ce qui est unique | Où |
|---|---|
| Le tick des ennemis | `EnemyManager._physics_process` — aucun ennemi n'a de `_physics_process` |
| L'écriture de la vie | `_set_health()` chez le joueur comme chez l'ennemi : la barre y est mise à jour |
| Tous les coups reçus | `Hurtbox.take_damage()` |
| La pose d'un état | `Hurtbox.take_damage()`, par `Etats.subir()` |
| La naissance d'un ennemi | `EnemyManager.spawn()` |
| La naissance d'un tir | `Projectile.spawn()` |
| La recherche des cibles d'un coup sans collision | `Cibles.dans_le_cercle()` |
| La résolution d'un lancer | `Player.resoudre()` — le lancer et la fiche du manuel |
| Le placement d'un point de manuel | `Player.investir()` / `reprendre()` : un passif change la fiche, et la page ne peut pas oublier le recalcul |
| La pose d'un objet au sol | `GroundItem.spawn()` |
| Le retour visuel d'un coup | `HitFeedback.current` |
| Le tirage pondéré | `Tirage.pondere()` |

Écrire `health = …` à la main plutôt que `_set_health()` ne casse rien de
visible : la barre ment, c'est tout.

### 6. Le viewport logique fait 640 × 360

`stretch/mode` vaut `canvas_items` : le 2D est rendu à la résolution de la
fenêtre — d'où du texte net — mais **le viewport logique reste 640 × 360**. Les
mises en page calculées à la main (panneaux, infobulles, HUD) comptent dessus.

Deux tests gardent l'invariant, parce qu'aucune assertion n'attrape un panneau
qui passe sous un autre : `test_la_fiche_tient_dans_sa_hauteur` et
`test_la_fiche_d_objet_tient_dans_sa_hauteur`. Ils comparent la hauteur du
contenu à celle du cadrage en passant par la **même** fonction que le dessin
(`StatsPanel.content_height()`, `ForgeGallery.hauteur_de_fiche()`) — sinon ils
valideraient leur propre copie du calcul.

`stretch/scale_mode` reste **fractionnaire** : le jeu remplit exactement la
fenêtre, bandes noires exclues, au prix d'une ligne de pixels doublée aux
facteurs non entiers. Arbitré en essayant les deux ; ne pas remettre `integer`
sans redemander.

### 7. Le format de sauvegarde se lit en arrière

`Personnage.VERSION` est le numéro **écrit** ; `VERSIONS_LUES` est la liste de
ce qu'on sait **lire**. Monter le premier sans ajouter l'ancien à la seconde fait
passer tous les personnages existants en « illisible » d'un coup, alors que leurs
fichiers sont intacts — et ça ne se voit qu'au premier lancement après la mise à
jour.

Un champ absent reprend sa valeur par défaut ; un numéro **inconnu** est refusé.
Jamais deviner.

### 8. Les nombres mesurés sont des points de comparaison

Les chiffres de performance dans les commentaires (`PixelCanvas.to_image` à
0,265 ms/image, `FlowField` à 1,67 ms, la génération de carte à 78,8 ms) ont été
mesurés, pas estimés. Ils justifient les seuls endroits du projet où l'on écrit
des tableaux packés plutôt que des structures lisibles. **Remesurer avant de
toucher à ces boucles**, et remesurer après.

Les tableaux packés autorisés : `FlowField` (`_walkable`, `_dx`, `_dy`),
`HitFeedback._p` (les particules), `PixelCanvas` (`_ramp`, `_level`). Partout
ailleurs, une petite classe nommée.

## Les scènes et leurs touches

| Scène | Rôle | Depuis la zone |
|---|---|---|
| `ui/selection_personnage.tscn` | L'accueil : choisir, créer, supprimer un personnage | — |
| `world/zone.tscn` | La partie | — |
| `world/test_arena.tscn` | Régler le game feel à chaud | `F2` |
| `world/map_debug.tscn` | Régler la génération de carte et le niveau de zone | `F3` |
| `art/forge_gallery.tscn` | Juger les sprites, et la fiche d'une base d'objet | `F4` |
| `world/stress_test.tscn` | Banc de mesure | `F6` |

Dans la zone : `I` sac, `C` fiche, `M` manuels, `TAB` carte, `H` bandeau,
`F5` nouvelle zone, `G` paquet, `K` tout tuer, `Page haut/bas` niveau de la
prochaine zone, `Échap` ferme ce qui est ouvert, puis ouvre le menu et la
sauvegarde. Les cinq cases de la barre se lancent par `competence_1` à `competence_5` — clic gauche, clic droit, `A`, `R`,
`F` — et **la barre lit ses libellés dans la carte d'entrées**, jamais dans une
liste réécrite à côté. Chaque aperçu se referme par la touche qui l'a
ouvert, et par `Échap`.

## Sauvegarde

Un fichier JSON par personnage dans `user://personnages/`, plus
`user://reglages.json` pour les réglages de la machine.

Rien de **calculé** n'est écrit : ni PV, ni statistiques, ni états. Elles se reconstruisent
à partir de la fiche de base, des attributs placés et de l'équipement. Les
écrire créerait une seconde vérité qui figerait l'équilibrage du jour de la
sauvegarde, et un rééquilibrage n'atteindrait jamais les personnages existants.

Les points d'un passif et d'un nœud d'arbre voyagent dans le **même**
dictionnaire que ceux des cases (`manuel.points`) : le jalon 10 n'a donc ajouté
aucun champ, et aucun numéro de version. En revanche, la relecture demande à
l'archétype s'il **connaît** l'identifiant (`ManuelArchetype.connait`) et non
s'il l'enseigne : la question d'avant aurait jeté tous les arbres au premier
rechargement, sur des fichiers intacts.

Une ligne d'objet qui vise une statistique **disparue** est convertie à la
lecture, dans `Personnage._ligne_actuelle()`, et seulement par une équivalence
exacte avec le jeu d'avant : les dégâts plats des versions 1 à 4 deviennent des
dégâts ajoutés aux attaques ou aux sorts. Ce qui n'a pas d'équivalent est retiré
**avec un avertissement**, jamais deviné.

L'écriture passe par un `.tmp` renommé : une coupure laisse un fichier inutile
plutôt qu'un personnage tronqué. Trois déclencheurs — la croix de la fenêtre, le
retour au menu, la montée de niveau — plus un filet toutes les deux minutes.
