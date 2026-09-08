# Architecture

Ce document dit **où vit chaque règle** et **ce qu'on ne peut pas casser**. Les
cinq `hack-n-slash-jalon-*.md` disent ce qu'il fallait construire et pourquoi,
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
| `resources/` | Les `.tres` : bases d'objets, affixes, fiches d'archétypes. | — |

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

## Où vit chaque règle

| La question | La réponse |
|---|---|
| Combien un coup fait-il vraiment ? | `CharacterStats` (armure, esquive, résistances), appliqué par `Hurtbox` |
| Quels objets tombent dans une zone ? | `ItemCatalog.disponibles()` |
| Jusqu'à quand une base tombe-t-elle ? | `ItemCatalog.fenetre_de_chute()` |
| Quels affixes une base peut-elle porter ? | `ItemAffix.fits()` via `ItemAffixPool.compatibles()` |
| Quels paliers un objet atteint-il ? | `ItemAffix.ouverts()` |
| Combien d'affixes sur un objet neuf ? | `ItemAffixPool.COUNT_WEIGHTS` |
| Quelle rareté ? | `Item.rarity()`, **déduite** du nombre d'affixes |
| Où va un objet équipé ? | `EquipmentSlots.free_for()` |
| Ce qui tient dans le sac ? | `Inventory.fits()` |
| Comment s'écrit une valeur à l'écran ? | `StatMod.format()` / `gauge()` / `range_label()` |
| Ce que rapporte un ennemi ? | `Enemy.xp_value()` et `Enemy.facteur_d_experience()` |
| Par où passe un ennemi ? | `FlowField`, à défaut la ligne droite |
| Ce qui survit à la fermeture ? | `Personnage.vers_dict()` et `Settings.vers_dict()` |

## Les invariants

Ce sont les huit choses qui cassent silencieusement. Aucune ne se voit à la
compilation, et la moitié ne se voit qu'au lancement suivant.

### 1. Les identifiants écrits sur le disque ne changent jamais

`ItemBase.id`, `ItemAffix.id`, les clés de `EquipmentSlots.SLOTS`, et les noms de
champs de `Personnage.vers_dict()` sont **dans les sauvegardes des joueurs**.
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
- `Player._swing()` passe par `set_deferred("monitoring", …)` ;
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
| La naissance d'un ennemi | `EnemyManager.spawn()` |
| La naissance d'un tir | `Projectile.spawn()` |
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

Dans la zone : `I` sac, `C` fiche, `TAB` carte, `H` bandeau, `F5` nouvelle zone,
`G` paquet, `K` tout tuer, `Page haut/bas` niveau de la prochaine zone,
`Échap` menu et sauvegarde. Chaque aperçu se referme par la touche qui l'a
ouvert, et par `Échap`.

## Sauvegarde

Un fichier JSON par personnage dans `user://personnages/`, plus
`user://reglages.json` pour les réglages de la machine.

Rien de **calculé** n'est écrit : ni PV, ni statistiques. Elles se reconstruisent
à partir de la fiche de base, des attributs placés et de l'équipement. Les
écrire créerait une seconde vérité qui figerait l'équilibrage du jour de la
sauvegarde, et un rééquilibrage n'atteindrait jamais les personnages existants.

L'écriture passe par un `.tmp` renommé : une coupure laisse un fichier inutile
plutôt qu'un personnage tronqué. Trois déclencheurs — la croix de la fenêtre, le
retour au menu, la montée de niveau — plus un filet toutes les deux minutes.
