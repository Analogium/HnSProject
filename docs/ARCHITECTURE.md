# Architecture

Ce document dit **où vit chaque règle** et **ce qu'on ne peut pas casser**. Les
`JALONS/hack-n-slash-jalon-*.md` disent ce qu'il fallait construire et pourquoi,
dans l'ordre où ça a été décidé ; celui-ci décrit l'état actuel, sans
chronologie.

## Le postulat

**Tout ce qui bouge est calculé par du code.** Les sprites d'acteurs et le
TileSet n'existent pas sur le disque : ils sont peints au premier appel, puis
gardés en cache pour la session. Une graine dérivée du nom et du numéro de
variante fait que le même personnage ressort identique à chaque lancement.

Ça a deux conséquences que rien d'autre dans le projet ne rappelle :

- **ajouter un acteur ou une tuile, c'est écrire une fonction**, pas importer un
  fichier — voir [RECETTES.md](RECETTES.md) ;
- **la génération procédurale est une règle de jeu**, pas une commodité. La
  silhouette d'un ennemi se déduit de sa case d'apparition, pas d'un tirage :
  c'est ce qui fait qu'une graine de zone redonne exactement le même combat.

La porte de sortie existe : `[S]` dans la forge (F4) exporte toutes les planches
en PNG, retouchables dans un éditeur d'image.

**Ce qui ne bouge pas fait exception** : les icônes de compétences et celles des
objets sont des PNG de `resources/icons/`, branchés sur un champ du `.tres`
(`Skill.icon`, `ItemBase.icon`) et produits hors du jeu — voir
[le LISEZMOI du dossier](../resources/icons/LISEZMOI.md). Une image immobile se
juge une fois ; un sprite qui s'anime dans quatre directions et cinq variantes,
non. **Le champ vide reste un état normal dans les deux cas** : sans image, la
forge dessine l'objet et la barre dessine un disque, donc rien ne casse en
attendant l'image.

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
| `tools/` | Les outils hors jeu : génération de la documentation, banc d'équilibrage. | tout |
| `resources/` | Les `.tres` : bases d'objets, affixes, fiches d'archétypes, **manuels, compétences, passifs et arbres de talents**, l'arbre de passifs (`passive_tree.tres`). | — |

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
| `WeightedRoll` | `ItemAffixPool` précharge les `.tres` d'`ItemAffix` ; un `ItemAffix` qui appellerait la réserve refermerait la boucle. |
| `Keys` | Sept scènes lisent le clavier, aucune n'a à connaître les six autres. |
| `ArtPalette`, `UiPalette` | Les couleurs sont lues par tout le monde et ne lisent personne. |
| `Texts` | La traduction est demandée par les tables de libellés, par le contenu et par les panneaux : elle ne peut nommer aucun des trois. |
| `Keywords`, `SkillStats` | `StatMod` y lit le nom de ce qu'une ligne portée vise, et `Skill` applique des `StatMod` : qu'elles nomment l'une ou l'autre, et la boucle se referme. |
| `LegacyFrench` | `Character`, `SaveStore` et `Settings` la lisent pour relire le disque d'avant ; une table figée n'a rien à nommer. |
| `StatusEffects` | `DamageInfo` le nomme pour dire qui frappe, et `Hurtbox` pour ce que porte la victime : il reçoit des parts et un auteur, jamais un coup. |
| `SpawnSeed` | La graine d'un point d'apparition est lue par l'ennemi, le caster et le sprite : elle ne peut connaître aucun des trois. |

## Où vit chaque règle

| La question | La réponse |
|---|---|
| Combien un coup fait-il vraiment ? | `CharacterStats` (armure, esquive, résistances ; la défense d'une part, `mitigate()`), appliqué **part par part** par `Hurtbox` : l'armure sur la part physique, sa résistance à chaque autre nature, le plancher sur le total |
| Quels objets tombent dans une zone ? | `ItemCatalog.available()` |
| Comment un ennemi monte-t-il avec la zone ? | `CharacterStats.scale_to_level()` : la vie **composée** de `HEALTH_PER_LEVEL` par niveau ; les dégâts, l'armure et les cinq résistances linéaires ; l'esquive jamais. `Enemy.sheet_of()` y ajoute les affixes, sur une copie. L'expérience suit la vie (`Enemy.xp_from_health()`) |
| Jusqu'à quand une base tombe-t-elle ? | `ItemCatalog.drop_window()` |
| Quels affixes une base peut-elle porter ? | `ItemAffix.fits()` via `ItemAffixPool.compatibles()` |
| Quels paliers un objet atteint-il ? | `ItemAffix.unlocked_tiers()` |
| Combien d'affixes sur un objet neuf ? | `ItemAffixPool.COUNT_WEIGHTS` |
| Quelle rareté ? | `Item.rarity()`, **déduite** du nombre d'affixes |
| Où va un objet équipé ? | `EquipmentSlots.free_for()` |
| Ce qui tient dans le sac ? | `Inventory.fits()` |
| À quoi ressemble un objet ? | `SpriteForge.inventory_icon(base, place)` dans le sac, `ground_icon(base)` au sol : l'image de `ItemBase.icon` si la base en a une, sinon le dessin de la forge d'après son `kind` et son palier. `ghost_icon(kind, place)` est le troisième chemin, celui d'un **emplacement vide** — il n'y a pas d'objet, donc pas d'image. Les trois passent par `_fit()`, qui agrandit d'un facteur **entier** |
| Où l'arme d'un personnage est-elle dessinée ? | `SpriteForge._weapon()`, d'après `ItemBase.kind` — **le même champ** que le dessin de repli de l'icône. Une image d'objet ne le remplace pas : `test_each_base_has_a_non_empty_icon` vérifie les deux |
| Comment s'écrit une valeur à l'écran ? | `StatMod.format()` / `gauge()` / `range_label()` ; des dégâts résolus, `SkillStats.readable_range()` ; un pourcentage, `StatMod.percentage()`, dont la typographie suit la langue |
| En quelle langue s'écrit un texte ? | `Texts.t()`, dans la fonction qui **lit** le libellé — jamais chez celui qui le dessine. Le texte français est la clé ; l'anglais vit dans `i18n/en.po`, et `Settings.language` choisit |
| Jusqu'où descend une fenêtre flottante ? | `Hud.gauges_top()` : les jauges sont dessinées après les panneaux, et passeraient par-dessus. **« Niv. » et l'indicateur de points d'arbre compris** |
| Ce que rapporte un ennemi ? | `Enemy.experience_of()`, dérivé de ses PV donc du niveau de sa zone — **sans borne haute** |
| Quel niveau a un personnage qui arrive dans une zone ? | `BenchProfiles.expected_level()` : chaque zone d'avant vidée une fois, avec la population moyenne de l'`EnemySpawner`, borné par `Player.MAX_LEVEL`. Une mesure du banc, pas une règle du jeu ; une case équipée y lit la médiane de `BenchCalculation.ITEM_DRAWS` tirages (`measure_profile()`) |
| À quel point un personnage type s'en sort-il ? | `BenchCalculation.measure()`, sur un vrai `Player` : `Player.resolve()` pour ce qui part, `Hurtbox.mitigate_part()` pour ce qui arrive. Les couloirs sont ses constantes, gardés par `tests/run.sh balance` ; le rapport, `tools/balance.sh` → [EQUILIBRAGE.md](EQUILIBRAGE.md) |
| Quand l'expérience fond-elle ? | `Enemy.experience_factor()` : sur une zone laissée **derrière** soi, jamais sur une zone trop haute |
| Par où passe un ennemi ? | `FlowField`, à défaut la ligne droite |
| Ce qui survit à la fermeture ? | `Character.to_dict()` et `Settings.to_dict()` |
| Comment une sauvegarde aux noms français se relit-elle ? | `LegacyFrench` : clés et identifiants des versions 1 à 5, ancien dossier, anciens réglages |
| Ce qu'un lancer fait vraiment ? | `Skill.resolve()`, par `Player.resolve()` — **appelée par le lancement, la page du manuel et la fiche de personnage** : dégâts par nature en fourchette et leur décomposition, projectiles, dispersion, vitesse, coût, intervalle |
| Quelle chance critique a un coup ? | `Skill.resolve()` : **la fiche** (`CharacterStats.crit_chance`), qui ne porte que **la base de l'arme** — `Item.crit_chance()` : `ItemBase.crit_chance` (10 % à l'attaque, 5 % à l'incantation) plus ses plats locaux, fois ses accrus locaux —, fois les accrus du reste — sans portée ou portés. **Hors d'une arme, une chance critique n'est jamais plate** (`test_no_flat_crit_outside_a_weapon`) : implicites d'anneaux, `keen`, nœuds de l'arbre ; une ligne plate relue sur autre chose qu'une arme est retirée par `Character._current_line()`. Les accrus sans portée ne touchent jamais la fiche : `Player.recompute_stats()` les envoie au lancer. Le multiplicateur reste celui de la fiche. Tiré à chaque coup par `DamageInfo.roll()` — coup d'arc, tir, `Targets.strike()` ; un coup sans lancer ne critique pas. La page du manuel lit la chance et le multiplicateur sur ce même lancer |
| Combien une compétence inflige-t-elle en moyenne ? | `SkillStats.average_per_cast()` et `average_per_second()` : si tout touche, avant défenses, sans critique |
| Combien fait un coup parti ? | `SkillStats.roll()` : une fois par projectile, une fois par coup d'épée pour tout son arc, une fois pour une chaîne entière, une fois par impulsion d'un nuage ou d'une aura, une fois par contact d'un serpent ou d'une épée — avec `Game.rng` et **un tirage par fourchette ouverte** |
| Quels mots-clés porte une compétence ? | `Skill.keywords()` : les déclarés, plus ceux que donnent la nature, la cadence et **la forme** — `KEYWORD_OF_SHAPE` : tir et boule sont `projectile`, frappe, croix et orbite `melee`, nuage, aura et serpent `area`. `ARC` étant la forme par défaut, le coup d'arme déclare `melee` lui-même. Sur la liste fermée de `Keywords`, et **un mot-clé affiché doit être visé par un affixe** (`test_each_keyword_is_targeted_by_something`). Ceux d'un **lancer** sont dans `SkillStats.keywords`, nœuds d'arbre compris |
| Dans quel ordre se lisent-ils ? | `Keywords.sort_in_order()`, et nulle part ailleurs : ils arrivent de trois sources et deux compétences voisines doivent se lire colonne contre colonne |
| Une ligne d'affixe vise-t-elle la fiche ou un mot-clé ? | `StatMod.scope` — vide pour la fiche. `StatMod.apply_all()` écarte le reste, `Player.recompute_stats()` le range dans `skill_mods`, avec la force changée en dégâts physiques aux attaques |
| Comment des pourcentages se combinent-ils ? | `StatMod.apply()` pour la fiche et les nombres d'un lancer, `Skill.resolve()` pour ses dégâts : plats, puis **la somme des accrus** (`Mode.PERCENT`) d'un champ, puis **chaque « plus »** (`Mode.MORE`) à la suite. Les affixes et les passifs de manuel donnent de l'accru ; le « plus » vient d'une `TalentLine.more` : les lignes `damage` des nœuds de talent et les clés de voûte de l'arbre de passifs. `SkillStats.increased` et `more` gardent les deux facteurs pour la page du manuel |
| Comment s'écrit un pourcentage ? | `StatMod.label()` : « +10 % d'armure **accrue** » — valeur, nom, **terme**, complément (« contre les embrasés », « (Sort) »). Le terme dit le calcul et le sens (`StatMod.term_of()` : accru, réduit, amplifié, atténué) et s'accorde par `StatMod.AGREEMENT` / `SkillStats.AGREEMENT`. Une ligne de fiche nommée par son terme : `StatMod.term_label()` |
| Comment un terme du glossaire s'écrit-il ? | `Glossary.term()` **seulement** : le mot accordé et traduit, entouré d'une marque invisible (`Glossary.START`…`END`). Aucune clé de `en.po` n'en contient. `Glossary.plain()` la retire pour ce qui ne se dessine pas en jeu (catalogue, forge, messages de test) |
| Qui dessine une ligne qui peut porter un terme ? | `RichText` — `draw()`, `draw_right()`, `width()`, `fold()` : le terme en gras (la police épaissie), la marque sans largeur. **Toute mesure d'une telle ligne passe par lui**, `test_widths` compris |
| Quand un encadré du glossaire apparaît-il ? | `GlossaryBoxes.draw()`, appelé en dernier par ce qui montre le texte — l'infobulle du sac, la fiche du manuel, l'aide de la fiche — **dès que le texte est affiché**, un encadré par sens. `layout()` cherche à droite, à gauche, dessous puis dessus une place qui ne couvre pas le panneau, dans le cadrage et au-dessus des jauges. L'établi met le terme en gras sans encadré : c'est un outil |
| À quelle cadence se lance-t-elle ? | `Skill.interval()` : la fiche pour l'arme, la recharge du sort pour l'incantation |
| Que pose un lancer dans le monde ? | `Skill.shape`, lue par `Player.cast_slot()` **sur la compétence** : aucun nœud ne la change. Elle porte le comportement et le dessin ensemble, et `projectile` s'en déduit |
| Combien de coups porte un lancer, si tout touche ? | `SkillStats.average_per_cast()` : projectiles × cibles × coups de la forme × `strikes_over_duration()` — **la fonction même qui compte les impulsions du nuage**. Une aura n'a que `average_per_second()` |
| Quels chiffres de dégâts s'affichent ? | `Settings.shows_damage()`, lue par `HitFeedback` pour le coup, l'esquive et la brûlure : une case pour ce que subit le joueur, une pour ce que subissent les ennemis. Le chiffre seulement — la gerbe d'éclats reste |
| Qui se dessine par-dessus qui ? | L'ordre des enfants de `UI` dans `world/zone.tscn`, et rien d'autre. L'arbre de passifs est **le premier** : il peint un fond plein sur tout l'écran, et le sac, la fiche, les manuels et l'établi doivent se lire par-dessus (`test_zone_ui.gd`). Le bandeau reste dernier |
| Que ferme Échap ? | `Zone.close_interfaces()`, dans `_input` : ce qui est **visible** — sac, fiche, manuels, arbre de passifs, établi, menu de la barre —, et le menu de pause seulement quand rien ne l'était. Par la visibilité et non par `Game.ui_grabs_input`, que la fiche ne prend jamais |
| Qu'est-ce qu'on peut lancer ? | `Player.cast_slot()`, qui porte les six refus — case vide, non apprise, mauvaise arme, réserve, recharge, orbite pleine. Une aura allumée s'y **éteint** sans coût, et la touche tenue ne la rallume pas |
| Quelle arme une compétence veut-elle ? | (jalon 18) `Skill.usable_with()` : le mot-clé de sa cadence contre `ItemBase.allowed_keyword()` — les sorts pour une arme `caster`, les attaques pour les autres, rien sans arme. La main gauche ne compte pas. L'arme de départ est posée par `SaveStore.create()` (épée en main, baguette au sac), et par la zone sans personnage |
| Une ligne d'objet est-elle locale ? | `ItemBase.is_local()` : aujourd'hui la chance critique d'une arme, plate (`cruel`, « +4 % de chance critique de base ») ou accrue (`precise`). `Item.mods()` ne les verse pas à la fiche ; elles font `Item.crit_chance()`, que `mods()` verse en une seule ligne plate. L'infobulle l'écrit « (local) » par `Item.explicit_line()`, et la base sous l'implicite par `Item.crit_line()` |
| Qui atteint un coup qui ne naît pas d'une collision ? | `Targets.in_circle()`, sur le calque des hurtbox ennemies : la chaîne, le nuage, l'aura, le serpent, l'épée, l'explosion. **Jamais depuis un rappel de collision** — l'espace y est verrouillé |
| Qu'est-ce qui fige le jeu parmi les compétences ? | Ce qui frappe d'un geste : coups d'arc, tirs, chaîne. **Ce qui dure ne fige jamais** — un nuage gèlerait l'image à chaque impulsion |
| Ce que coûte l'Immolation ? | `Player.burn()` : répartie entre les natures comme les dégâts de l'aura (`SkillStats.distribution()`), chaque part atténuée par `CharacterStats.mitigate()` — **la règle d'un coup reçu**, donc objets et passifs compris, et l'engourdissement. Pas un coup pour le reste : ni esquive, ni plancher d'un point. **Mortelle** |
| Quand le jeu se fige-t-il ? | `Game.hit_stop()` : **un gel par geste et non par cible**, et `hit_stop_period` entre deux. Sans elle, une compétence tenue sur une nuée figeait le jeu 12 % du temps sans qu'aucune image ne se perde |
| Qui secoue la caméra ? | `Game.shake_camera()`, **une seule secousse à la fois** : relancée, elle reprend la plus forte des deux amplitudes au lieu d'en empiler une seconde |
| Quand une touche de compétence part-elle ? | Le sondage de `Player._physics_process()` : **tenue, elle relance à chaque fin de recharge**, et ne s'arme qu'au passage à l'état enfoncé — un bouton encore baissé quand un panneau rend la souris ne lance rien |
| Combien de points dans une compétence ? | `Player.skill_points()` : le manuel du râtelier qui l'enseigne, ou un seul pour ce que liste `SkillCatalog.STARTING`. **Les niveaux en bonus** (`SkillStats.LEVELS`, toujours portés par un mot-clé) s'y ajoutent dans `Skill.resolve()` seulement, et seulement si un point est placé : `Manual` ne les voit jamais, ils n'ouvrent aucun nœud. Au-delà de la table, `Skill.damage()` la prolonge par `GROWTH_PER_EXTRA_LEVEL`, composé |
| Une ligne se donne-t-elle en fourchette ? | `StatMod.ranged_stat()` ; la ligne qu'un affixe ou un implicite donne, `StatMod.from_definition()` |
| Quel niveau a un manuel ? | `Manual.level()`, **déduit** de son expérience par `Progression` |
| Peut-on y placer un point ? | `Manual.can_invest()` — les quatre conditions, jamais dans l'interface |
| Où un manuel apprend-il ? | Au râtelier seulement, par `Player.reward()` — le chemin d'une mort **et** d'une boule d'expérience de l'établi, avec le retard sur la zone |
| Que porte une case de manuel ? | `ManualCell` : une compétence **ou** un passif — jamais les deux —, sa position, et l'arbre de talents de la première |
| D'où viennent les talents d'un lancer ? | `Player.talents_of()`, qui passe par le livre du râtelier qui enseigne la compétence. Ils entrent dans `Skill.resolve()` **sans être filtrés** : un nœud ne vise que sa propre compétence, et c'est tout ce qui le distingue d'un modificateur d'objet |
| D'où viennent les attributs placés ? | De l'**arbre de passifs** seulement, avec les objets et les passifs de manuel : plus aucun point d'attribut. `PassiveTree.mods()` des nœuds pris (`Player.passives`), versé par `Player.recompute_stats()` dans **la même liste** que les objets — attributs avant la dérivation, mots-clés dans `skill_mods` |
| Combien de points d'arbre ? | `PassiveTree.points_gained()` : niveau − 1, **déduit**, jamais retenu ; les restants, `remaining_points()`. Le bandeau les annonce au-dessus du niveau tant qu'il en reste (`Hud._refresh_points()`, sur `passives_changed` et `xp_changed`) |
| Quel niveau maximal pour un personnage ? | `Player.MAX_LEVEL` (100) : au plafond, `xp_to_next` vaut zéro et l'expérience ne s'accumule plus. Les zones, elles, montent jusqu'à `Game.MAX_LEVEL` (120) |
| Peut-on prendre un nœud de l'arbre, le reprendre ? | `PassiveTree.can_take()` — un point restant, voisin d'un nœud pris ou du départ — et `can_release()` — **tous les autres nœuds pris restent reliés au départ** sans lui, par `connected()`. Gratuit. Le panneau (P) n'en vérifie aucune ; `Player.take_passive()` / `release_passive()` sont les seuls chemins |
| Quelle forme a l'arbre de passifs ? | `resources/passive_tree.tres`, 418 nœuds (jalon 19). Un **squelette** : trois axes depuis le départ — intelligence en haut, dextérité en bas à droite, force en bas à gauche —, une clé de voûte au bout de chacun, et trois anneaux qui les croisent (`inner_*`, `outer_*`, `far_*`). Un nœud de squelette ne porte **que** des attributs : +10 sur un axe, +5/+5 sur un anneau. Le troisième anneau passe **au-delà** des clés de voûte, qui ne sont donc jamais un passage : on l'atteint par les trois ponts `*_bridge`, qui contournent la clé de voûte depuis le dernier nœud d'axe. Les **clusters** sont des culs-de-sac branchés sur une seule jonction, faits de petits nœuds et de leurs notables. Une **forme** du graphe, jamais un champ de `PassiveNode` |
| Le zoom du panneau de l'arbre ? | `PassiveTreePanel.ZOOMS` (0,35, 1 et 1,5), trois crans à la molette, qui multiplient `UNIT` dans `screen_position()` et les rayons dans `_radius()` — donc la tolérance de `node_at()`. `zoom_by()` garde le centre du cadre. Pas d'icône au cran large ; retour au cran normal à l'ouverture |
| Ce qu'une sauvegarde peut porter dans l'arbre ? | `PassiveTree.legal()`, à la relecture : les identifiants inconnus et les nœuds coupés du départ sont retirés, et pas plus de nœuds que de points |
| Ce qu'un passif de manuel change, et quand ? | `Manual.passive_mods()`, versé par `Player.recompute_stats()` dans **la même liste** que les objets portés — donc trié par la même règle entre la fiche et les mots-clés. Seulement au râtelier : un livre du sac ne donne rien |
| Peut-on placer un point ? | `Manual.can_invest()`, pour les trois sortes de destination. `is_open()` porte les conditions **structurelles** seules, pour que la page distingue « verrouillé » de « plus de point à placer » |
| Peut-on le reprendre ? | `Manual.can_refund()`, pour les trois sortes : pas un nœud sous un enfant qui porte des points, pas une compétence sous les points qu'un de ses nœuds investis demande. `Player.refund()` vide la barre d'une compétence retombée à zéro |
| Où convertit-on des dégâts ? | `SkillStats.apply_conversion()`, appelée par `resolve()` **après les fourchettes ajoutées**, sur **toutes les natures** du coup : entière, il n'en reste qu'une, donc qu'un état possible. `conversions` en garde la part pour la fiche |
| Dans quelle nature un tir se dessine-t-il ? | `SkillStats.dominant_nature()` : celle de la compétence, ou celle où une conversion a emmené le plus gros de ses dégâts **propres** — ce qu'un objet ajoute ne change pas la couleur |
| Un coup pose-t-il un état ? | `StatusEffects.suffer()`, appelée par `Hurtbox.take_damage()` **après** l'esquive, la mitigation et le signal : 20 % pour un coup entièrement d'une nature, partagés selon ses parts, **plus la part des PV max de la cible que la nature retire** (`StatusEffects.chance()`), **un tirage par nature présente**, physique compris. Chance, durées et forces sont les constantes de `StatusEffects` |
| Qui a porté un coup ? | `DamageInfo.author` — les états de l'attaquant, jamais son nœud —, posé par ce qui fabrique le coup ; un tir le lit sur son lanceur par `StatusEffects.of()`. `DamageInfo.cast`, le lancer du joueur, voyage à côté : `Targets.strike()` et `Explosion.put()` l'exigent, `Projectile.spawn()` et le coup d'arc le posent |
| Quand un bonus contre un état s'applique-t-il ? | Résolu par `Skill.resolve()` dans `SkillStats.against_increased` / `against_more` (statistiques `damage_vs_<id>` sur `StatusEffects.IDS`), appliqué par `Hurtbox.take_damage()` **avec la bénédiction, avant l'esquive et l'armure**, par `SkillStats.against_factor()` sur les états **déjà présents**. L'accru s'ajoute aux accrus du lancer, le « plus » multiplie. La page du manuel le montre à part du total « par coup » ; le banc ne le compte pas |
| Ce qu'un état change, et où ? | Les facteurs de `StatusEffects`, lus **là où vit déjà la règle** : la bénédiction de l'auteur avant la mitigation, l'engourdissement après ; le gel dans `Enemy.movement_speed()`, `Enemy._cool_down()` et la cadence de `Player._physics_process()`. Ce qui brûle sort d'`StatusEffects.advance()` et s'ôte par `_set_health()`, chez l'ennemi depuis l'`EnemyManager`, avec la régénération |
| Comment un état se voit-il ? | Dans la couleur de sa nature, sauf le saignement (`StatusEffects.BLOOD`), sur le signal `StatusEffects.change` : `HealthBar.show_states()`, qui dessine l'icône de chacun (`StatusIcon`, un masque 7×7 par état), et `ActorSprite.show_states()`. Le nom au-dessus du **joueur seul**, par `HitFeedback.state()` ; ce qui brûle, par `HitFeedback.damage_without_hit()` — **statique**, elle porte le test de nullité que ses trois appelants écrivaient — et les paquets d'`StatusEffects.Pack` |

## Les invariants

Ce sont les huit choses qui cassent silencieusement. Aucune ne se voit à la
compilation, et la moitié ne se voit qu'au lancement suivant.

### 1. Les identifiants écrits sur le disque ne changent jamais

`ItemBase.id`, `ItemAffix.id`, les clés de `EquipmentSlots.SLOTS`, les
identifiants de `Keywords` — la portée d'un affixe en nomme un —, ceux de
`DamageType.IDS` — ils forment le nom des dégâts ajoutés, `damage_cold` —, ceux de
`StatusEffects.IDS` — le nom des dégâts contre un état, `damage_vs_ignite` —, ceux
de `Skill`, `Passive` et `TalentNode` — les trois partagent le
dictionnaire de points d'un manuel, et **deux identiques dans un même livre
partageraient un compteur** —, ceux de `PassiveNode` — la liste des nœuds pris
d'un personnage —, l'entier de `StatMod.Mode` — une valeur ne s'ajoute
qu'à la fin — et les noms de champs de `Character.to_dict()`
sont **dans les sauvegardes des joueurs**.
Renommer `chest` en `torso` fait disparaître le plastron de tout le monde — au
prochain chargement seulement, sans erreur.

Ils ont changé **une fois**, quand le code est passé en anglais : les noms français
d'avant sont figés dans `LegacyFrench`, qui les traduit à la lecture des versions 1 à 5.
Un renommage futur fait pareil — une version de plus et sa table — ou ne se fait pas.

Le nom lisible est à côté (`display_name`, `label`) et se change librement.
`test_milestone_4_ids_survive` et
`test_former_slots_keep_their_name` gardent la porte.

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
| La silhouette, les affixes, le sens de rotation d'un ennemi | `SpawnSeed.at()`, le `hash()` du point d'apparition — **les trois passent par elle**, un arrondi qui divergerait casserait la reproductibilité sans rien dire |
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

- `GroundItem.spawn()`, `ExperienceOrb.put()` et `Explosion.put()` passent
  par `DeferredTree.add_deferred()` : ajout puis position, dans cet ordre, une
  position globale ne voulant rien dire hors de l'arbre. **Un parent libéré avant
  l'appel différé libère le nœud** — sinon il fuit hors de l'arbre avec ce qu'il
  porte, comme le manuel de départ d'une zone fermée dans la même image ;
- `Player._swing()` passe par `set_deferred("monitoring", …)`, et **attend une
  image de physique** avant de rouvrir la hitbox pour le second coup d'une croix :
  fermée puis rouverte dans la même image, elle ne coupe rien, et un ennemi déjà
  dedans n'y *entre* pas une seconde fois ;
- `Explosion.put()` naît en différé et ne frappe qu'à sa première image de
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
| La pose d'un état | `Hurtbox.take_damage()`, par `StatusEffects.suffer()` |
| La naissance d'un ennemi | `EnemyManager.spawn()` |
| La naissance d'un tir | `Projectile.spawn()` |
| La recherche des cibles d'un coup sans collision | `Targets.in_circle()` |
| La résolution d'un lancer | `Player.resolve()` — le lancer et la fiche du manuel |
| Le placement d'un point de manuel | `Player.invest()` / `refund()` : un passif change la fiche, et la page ne peut pas oublier le recalcul |
| La prise d'un nœud de l'arbre de passifs | `Player.take_passive()` / `release_passive()`, pour la même raison |
| La pose d'un objet au sol | `GroundItem.spawn()` |
| Le retour visuel d'un coup | `HitFeedback.current` |
| Le tirage pondéré | `WeightedRoll.weighted()` |

Écrire `health = …` à la main plutôt que `_set_health()` ne casse rien de
visible : la barre ment, c'est tout.

### 6. Le viewport logique fait 640 × 360

`stretch/mode` vaut `canvas_items` : le 2D est rendu à la résolution de la
fenêtre — d'où du texte net — mais **le viewport logique reste 640 × 360**. Les
mises en page calculées à la main (panneaux, infobulles, HUD) comptent dessus.

Deux tests gardent l'invariant, parce qu'aucune assertion n'attrape un panneau
qui passe sous un autre : `test_the_sheet_fits_its_height` et
`test_the_item_sheet_fits_its_height`. Ils comparent la hauteur du
contenu à celle du cadrage en passant par la **même** fonction que le dessin
(`StatsPanel.content_height()`, `ForgeGallery.sheet_height()`) — sinon ils
valideraient leur propre copie du calcul.

`stretch/scale_mode` reste **fractionnaire** : le jeu remplit exactement la
fenêtre, bandes noires exclues, au prix d'une ligne de pixels doublée aux
facteurs non entiers. Arbitré en essayant les deux ; ne pas remettre `integer`
sans redemander.

### 7. Le format de sauvegarde se lit en arrière

`Character.VERSION` est le numéro **écrit** ; `READABLE_VERSIONS` est la liste de
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
| `ui/character_select.tscn` | L'accueil : choisir, créer, supprimer un personnage | — |
| `world/zone.tscn` | La partie | — |
| `world/test_arena.tscn` | Régler le game feel à chaud | `F2` |
| `world/map_debug.tscn` | Régler la génération de carte et le niveau de zone | `F3` |
| `art/forge_gallery.tscn` | Juger les sprites, et la fiche d'une base d'objet | `F4` |
| `world/stress_test.tscn` | Banc de mesure | `F6` |

Dans la zone : `I` sac, `C` fiche, `M` manuels, `P` arbre de passifs, `TAB` carte, `H` bandeau,
`F5` nouvelle zone, `G` paquet, `K` tout tuer, `Page haut/bas` niveau de la
prochaine zone, `Échap` ferme ce qui est ouvert, puis ouvre le menu et la
sauvegarde. Les cinq cases de la barre se lancent par `skill_1` à `skill_5` — clic gauche, clic droit, `A`, `R`,
`F` — et **la barre lit ses libellés dans la carte d'entrées**, jamais dans une
liste réécrite à côté. Chaque aperçu se referme par la touche qui l'a
ouvert, et par `Échap`.

## Sauvegarde

Un fichier JSON par personnage dans `user://characters/`, plus
`user://settings.json` pour les réglages de la machine.

Rien de **calculé** n'est écrit : ni PV, ni statistiques, ni états. Elles se reconstruisent
à partir de la fiche de base, des nœuds pris de l'arbre et de l'équipement. Les
écrire créerait une seconde vérité qui figerait l'équilibrage du jour de la
sauvegarde, et un rééquilibrage n'atteindrait jamais les personnages existants.

L'arbre de passifs s'écrit en **liste d'identifiants** (`passives`, version 7), jamais
en points : les restants se déduisent du niveau. Les attributs placés des versions 1
à 6 sont **abandonnés** à la relecture, sans conversion — trois points libres n'ont
pas d'équivalent juste en nœuds — et le joueur retrouve ses niveau − 1 points.

Les points d'un passif et d'un nœud de talent voyagent dans le **même**
dictionnaire que ceux des cases (`manual.points`) : le jalon 10 n'a donc ajouté
aucun champ, et aucun numéro de version. En revanche, la relecture demande à
l'archétype s'il **connaît** l'identifiant (`ManualArchetype.knows`) et non
s'il l'enseigne : la question d'avant aurait jeté tous les arbres au premier
rechargement, sur des fichiers intacts.

Les versions 1 à 5 et les réglages d'avant parlent français — `nom`, `epee`,
`degats_feu`, `user://personnages`, `user://reglages.json`. `LegacyFrench` traduit
le fichier avant `Character.from_dict()`, renomme l'ancien dossier au premier accès,
et l'écriture suivante part en version 6. Les fichiers de référence v1 à v5 gardent
leurs noms français exprès : voir `tests/fixtures/LISEZMOI.md`.

Une ligne d'objet qui vise une statistique **disparue** est convertie à la
lecture, dans `Character._current_line()`, et seulement par une équivalence
exacte avec le jeu d'avant : les dégâts plats des versions 1 à 4 deviennent des
dégâts ajoutés aux attaques ou aux sorts. Ce qui n'a pas d'équivalent est retiré
**avec un avertissement**, jamais deviné.

L'écriture passe par un `.tmp` renommé : une coupure laisse un fichier inutile
plutôt qu'un personnage tronqué. Trois déclencheurs — la croix de la fenêtre, le
retour au menu, la montée de niveau — plus un filet toutes les deux minutes.
