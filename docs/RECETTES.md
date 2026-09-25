# Recettes

Les gestes qu'on refait tous les trois jalons, avec **les fichiers dans
l'ordre** et **le test qui refusera l'oubli**. Les invariants qu'elles
respectent sont dans [ARCHITECTURE.md](ARCHITECTURE.md).

Après chacune : `tests/run.sh`. Après celles qui touchent un `.tres` de contenu :
`tools/catalog.sh`, qui régénère [CATALOGUE.md](CATALOGUE.md).

> Dans un `.tres`, Godot **n'écrit que ce qui diffère du défaut du script**.
> `broadsword.tres` ne contient ni `kind` ni `family` : les deux valent déjà
> `"sword"` et `"weapon"`. Ne pas s'étonner de ne pas les y trouver.

---

## Ajouter une base d'objet

1. **`resources/items/<id>.tres`** — copier le voisin de sa lignée, c'est plus
   sûr que de partir de rien.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les sauvegardes (invariant 1) |
   | `display_name` | Ce que le joueur lit ; se change librement |
   | `kind` | Le dessin de repli **et l'arme en main**, au sens de `SpriteForge` — voir l'étape 3 |
   | `icon` | Son image, ou vide pour le dessin de la forge — voir l'étape 4 |
   | `family` | L'emplacement qui l'accepte, ou vide s'il ne s'équipe pas |
   | `tags` | **La famille en fait partie**, plus ce qui décrit l'objet (`melee`, `heavy`, `caster`…). Sur une arme, `caster` décide ce qu'elle laisse lancer : les sorts avec, les attaques sans |
   | `lineage` / `tier` | La suite à laquelle il appartient, et son rang |
   | `required_level` | La zone à partir de laquelle il tombe |
   | `grid_size` | Son encombrement en cases |
   | `implicit_*` | Le bonus que porte toute la base, **tiré entre `implicit_value` (le bas) et `implicit_roll_max`** ; `implicit_roll_max` à zéro le fige. Une lignée monte sa plage avec son palier. Pour des dégâts ajoutés, jamais tirés : `implicit_stat = damage_<nature>`, les deux bornes dans `implicit_value` et `implicit_value_max`, et la famille visée dans `implicit_scope` (`attack` ou `spell`). **Casque, gants, bottes, torse : `armor` ou `evasion`, plat** — c'est la défense de base de la pièce, que ses affixes montent sur place ; `test_armour_pieces_roll_only_their_own_defense` le vérifie |
   | `crit_chance` | **Arme seulement** : la chance critique de base de tout ce qu'elle lance, 0,10 à l'attaque, 0,05 à l'incantation. Zéro ailleurs ; `test_each_weapon_has_its_crit_and_its_kind` le vérifie. Un implicite de chance critique hors arme est **en pourcentage** |

2. **`core/item_catalog.gd`** — ajouter le `preload` dans `ALL`, **dans le bloc
   de sa lignée et par palier croissant**. C'est le seul endroit où les bases
   sont listées ; l'ordre est celui des planches de la forge.

3. **`art/sprite_forge.gd`**, seulement si le `kind` est nouveau :
   - une arme → un cas dans `_weapon()` ;
   - autre chose → un cas dans `_gear()` **et** l'ajouter à la liste `GEAR`,
     qui sert d'aiguillage entre les deux.

   À faire **même quand la base aura son image** : le `kind` est aussi l'arme
   posée dans la main du personnage, et `test_each_base_has_a_non_empty_icon`
   vérifie les deux séparément.

4. **Son image**, facultative — sans elle la base est jouable, dessinée par la
   forge. Une ligne dans `tools/item_icons.json` (le sujet du prompt, la graine
   retenue), puis `tools/item_icons.py gen --only <id>`, on choisit sur la
   planche, et `apply` copie le PNG et branche le champ. La recette complète et
   ses pièges : [`resources/icons/LISEZMOI.md`](../resources/icons/LISEZMOI.md).

5. Vérifier la **fenêtre de chute** dans `docs/CATALOGUE.md` après régénération.
   Elle n'est écrite nulle part : elle naît de la rencontre entre `required_level`
   et le palier suivant de la lignée. Insérer un palier au milieu **raccourcit
   celui d'avant**.

**Ce qui refusera un oubli** — `tests/unit/test_catalog.gd` :
`test_each_base_has_an_id`, `test_ids_are_unique`,
`test_each_base_has_a_non_empty_icon`,
`test_each_base_carries_its_family_as_a_tag`,
`test_implicits_target_real_stats`,
`test_each_lineage_is_monotonic` (un palier supérieur doit demander un niveau
supérieur **et** donner un implicite supérieur), `test_no_base_has_an_empty_window`,
`test_each_slot_has_a_base_at_every_level`.

**Et son nom anglais** : une entrée dans `i18n/en.po`, dont le `msgid` est le
`display_name` français. Voir « Ajouter un texte affiché ».

---

## Ajouter un affixe d'objet

1. **`resources/item_affixes/<id>.tres`** — copier un affixe qui vise la même
   sorte de statistique, pour hériter d'une échelle plausible.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les sauvegardes |
   | `suffix` | Le nom que l'objet prend — « Épée **de l'Agilité** » —, préposition et article compris : le genre du mot ne se devine pas. Unique dans la réserve, et à traduire dans `i18n/en.po` |
   | `stat` | Sans portée : un champ **réel** de `CharacterStats`, présent dans `StatMod.LABELS`. Avec : un nombre de `SkillStats.LABELS` — `skill_levels` compris, à plat —, des dégâts ajoutés `damage_<id>` sur `DamageType.IDS`, ou des dégâts contre un état `damage_vs_<id>` sur `StatusEffects.IDS`, en pourcentage — ceux-là n'existent **qu'avec une portée** |
   | `scope` | Vide pour la fiche du personnage ; sinon **un mot-clé de `Keywords`**, et l'affixe n'agit que sur les compétences qui le portent |
   | `percent` | Pourcentage plutôt que valeur absolue |
   | `tags` | Les étiquettes visées ; **vide = partout** |
   | `excludes` | Ce qui refuse, et **qui l'emporte** sur `tags` |
   | `rounded` | Le pas de la valeur tirée : `1` pour un entier, `0.01` pour une fraction |
   | `weight` | Son poids dans la réserve |
   | `tiers` | L'échelle, **du meilleur au pire**. Pour des dégâts ajoutés, deux plages par palier : `min_value`/`max_value` pour la borne basse, `min_top`/`max_top` pour la borne haute |

2. **L'échelle** est la seule partie délicate :
   - le **premier** de la liste est le T1, le meilleur ;
   - le **dernier** doit exiger `required_level = 1`, sinon l'affixe n'existe pas
     dans les premières zones et sa première sortie ressemble à un ajout de
     contenu plutôt qu'à une progression ;
   - la monotonie est obligatoire : niveau requis et valeurs croissent ensemble
     du bas vers le haut ;
   - une fourchette l'est **sur ses deux bornes**, et sa plage basse ne dépasse
     jamais sa plage haute : un objet ne doit pas pouvoir tirer « ajoute 9 à 7 ».

3. **`core/item_affix_pool.gd`** — ajouter le `preload` dans `ALL`.

4. **La forge de réglage pagine sa liste par 24** (`ForgeGallery.LIST_ROWS`) ;
   les bijoux en sont à 30. Seul le tableau des paliers peut encore déborder
   (`test_the_item_sheet_fits_its_height`).

5. **Une chance critique** : plate, l'affixe ne va **que sur les armes**, où elle monte
   la base (locale) ; partout ailleurs, `percent = true`.
   `test_no_flat_crit_outside_a_weapon` refuse le reste.
   **Une armure ou une esquive** est locale sur une pièce d'armure et n'y va que si
   c'est sa défense : `ItemAffix.fits()` le fait seul, rien à étiqueter.

6. **Préférer une exclusion à une liste d'autorisations** quand la règle est
   « partout sauf ». Une base ajoutée plus tard hérite du refus sans qu'on y
   pense, là où une liste d'autorisations l'aurait oubliée en silence.

**Ce qui refusera un oubli** — `tests/unit/test_affixes.gd` :
`test_each_affix_targets_a_real_named_field`,
`test_everything_modifiable_reads_on_the_sheet` (voir la recette suivante),
`test_each_scale_is_monotonic`, `test_each_affix_exists_from_level_1`,
`test_tier_1_is_the_best`, `test_rounding_is_the_same_at_every_tier`,
`test_no_affix_tag_targets_nothing` (une étiquette qui ne
correspond à aucune base est une faute de frappe qui ne se verrait jamais),
`test_the_pool_does_not_contain_the_same_line_twice`,
`test_each_affix_has_its_own_suffix`,
`test_each_scoped_affix_targets_a_keyword_and_a_cast_number`,
`test_each_range_is_monotonic_and_the_right_way_round`,
`test_a_rolled_range_stays_in_both_its_spans` ; et
`tests/integration/test_workbench.gd : test_each_accepted_affix_has_its_line`, qui
refuse une base dont la liste déborde du bas de l'établi.

---

## Ajouter une action rebindable

1. **`project.godot`** — l'action et sa touche par défaut. **Ne pas taper le blob
   sérialisé à la main** : le faire écrire par le moteur, sur une copie temporaire,
   puis rapatrier le fichier.

   ```gdscript
   var ev := InputEventKey.new()
   ev.keycode = KEY_J            # ou ev.physical_keycode, pour lier une position
   ProjectSettings.set_setting("input/mon_action", {"deadzone": 0.2, "events": [ev]})
   ProjectSettings.save()
   ```

   `keycode` lie **la lettre** que le joueur voit, `physical_keycode` **la position**
   sur le clavier. Les déplacements sont des positions, pour que ZQSD tombe où tombe
   WASD ; tout le reste est une lettre.

2. **`core/keybinds.gd`** — l'entrée dans `ACTIONS`, identifiant **définitif**
   (invariant 1, il part dans `settings.json`) et libellé français.

3. **`i18n/en.po`** — l'anglais du libellé.

4. **Celui qui écoute** : `event.is_action_pressed("mon_action")` dans un
   `_unhandled_input`, ou `Input.is_action_pressed()` pour une touche maintenue. Un
   `KEY_*` écrit dans un `if` ne se rebinde pas — c'est tout l'objet de la recette.

L'onglet des touches se remplit seul : il lit `ACTIONS`. Au-delà de seize actions,
vérifier qu'il tient dans les 360 px (deux colonnes aujourd'hui).

**Ce qui refusera un oubli** — `tests/unit/test_keybinds.gd` :
`test_each_action_exists_and_is_named` (l'action ajoutée d'un seul côté),
`test_no_two_default_keys_collide` (deux actions sur la même touche), et
`tests/unit/test_translations.gd` pour le libellé sans anglais.

Les touches de **réglage** — F2 à F6, G, K, PAGE, H, B — ne sont pas des actions :
elles ouvrent des outils et non le jeu, et `zone.gd` les lit par leur code.

---

## Ajouter une statistique

Deux tests forment une **bijection** qu'il faut satisfaire des deux côtés :

- `test_everything_modifiable_reads_on_the_sheet` — tout affixe doit viser une
  statistique affichée ;
- `test_each_sheet_stat_is_reachable_by_an_affix` — toute
  statistique affichée doit être atteignable par un affixe.

Autrement dit : **on n'ajoute pas une statistique seule.** Elle arrive avec au
moins un affixe, ou elle n'arrive pas.

Les lignes « attaque » et « trait » du groupe OFFENSE ne sont pas des
statistiques : ce sont les deux compétences de départ, résolues par le chemin du
lancer. Leur explication est dans `StatHelp.SKILLS`, et elles comptent comme
atteintes dès qu'un affixe de dégâts ajoutés vise l'un de leurs mots-clés.

1. **`core/character_stats.gd`** — le champ `@export`, dans son groupe.
2. **`core/stat_mod.gd`** — son entrée dans `LABELS` **et dans `AGREEMENT`** (le genre
   et le nombre du libellé, pour « accrue » ou « accrus » —
   `test_each_label_has_its_agreement`) ; l'unité fait partie du nom
   quand elle n'est pas évidente : « PV/s » et non « régénération »). Puis, si
   elle se lit en pourcentage :
   - rangée en fraction ou en multiplicateur (0.05 → « 5 % ») → `SCALED` ;
   - déjà comptée en points de pourcentage (75 → « 75 % ») → `PERCENT_POINTS`,
     **déduit** de `DamageType.RESIST_FIELDS`, plus les chances d'état nommées à la
     main (jalon 20) : une statistique qui compte en points sans être une résistance
     s'ajoute à cette courte liste, à côté du filtre.

   Confondre les deux donne « 7500 % de résistance au feu ».
3. **`ui/stat_help.gd`** — son entrée dans `TEXTS` : ce qu'elle fait, en une
   phrase. Ajouter un cas dans `_now()` seulement si le nombre affiché ne parle
   pas de lui-même — une notation d'armure, oui ; « 90 de vitesse », non.
4. **`ui/stats_panel.gd`** — sa place dans `GROUPS`, qui est l'ordre de lecture.
5. **Un affixe qui la vise**, voir la recette précédente — **seulement si elle
   s'affiche sur la fiche** : les trois chances d'état n'y sont pas, et c'est une
   compétence qui les donne.
6. Si elle doit croître avec le niveau de zone : `CharacterStats.scale_to_level`.

**Une chance de poser un état** en plus : sa case dans `StatusEffects.CHANCE_STATS`,
à la place de sa sorte. C'est le seul endroit qui lie les deux — sans elle, le champ
existe et ne sert à rien.

**Ce qui refusera un oubli** : les deux tests ci-dessus, plus
`test_each_sheet_stat_has_its_explanation`,
`test_no_explanation_targets_an_unknown_field`, et surtout
`test_the_sheet_fits_its_height` — la fiche doit tenir **entière** dans les
360 pixels du cadrage, et c'est le groupe des attributs, ajouté après coup, qui
avait fait déborder la dernière ligne sur l'aide du bas.

**Et son anglais** : deux entrées dans `i18n/en.po`, son nom de `LABELS` et son
explication de `StatHelp`. La fiche doit ensuite tenir dans **les deux langues** —
`tests/integration/test_widths.gd`.

---

## Ajouter une nature de dégâts

C'est la recette qui montre pourquoi `DamageType` est une feuille sans
dépendance : des tables alignées sur un seul enum.

1. **`core/damage_type.gd`** — la valeur dans `Kind`, **à la fin** (l'enum est
   indexé par des tableaux), puis son entrée dans les cinq tables : `NAMES`,
   `IDS` (**définitif** : il forme le nom `damage_<id>` que les sauvegardes
   écrivent), `DAMAGE_LABELS`, `COLORS`, `RESIST_FIELDS`.
2. **`core/character_stats.gd`** — le champ `res_<name>`, du même nom que dans
   `RESIST_FIELDS`.
3. **`core/stat_mod.gd`** — `LABELS` et `AGREEMENT`. Rien à ajouter à
   `PERCENT_POINTS`, qui se déduit de `RESIST_FIELDS`.
4. **`ui/stats_panel.gd`** — dans le groupe `RÉSISTANCES`.
5. **Un affixe** qui la donne, avec `excludes = ["weapon"]` comme ses sœurs.
6. **Deux affixes de dégâts ajoutés**, `<id>_to_attacks` et `<id>_to_spells` :
   copier ceux d'une nature voisine, échelle comprise. Hors de l'étiquette d'archétype
   (`melee` / `caster`), les deux vont sur les mêmes bases —
   `test_added_damage_fits_the_same_bases_for_attacks_and_spells`. Une nature est une nature
   comme les autres, même si aucune compétence n'en est encore.
7. **Son état**, voir « Ajouter un état » : une nature en pose exactement un.

`StatHelp` n'a **rien** à changer : sa ligne « plafonnée à 75 % » est écrite pour
tout ce qui est dans `RESIST_FIELDS`, donc la nouvelle nature en hérite. La fiche
du manuel non plus : elle écrit une ligne par nature ajoutée, dans sa couleur.

Une nature **ne donne pas de mot-clé d'elle-même** : il faut l'entrée dans
`Skill.KEYWORD_OF_NATURE` et un affixe qui la vise — voir « Ajouter un
mot-clé ». Sans eux, une compétence de feu n'affiche simplement pas « Feu ».

**Ce qui refusera un oubli** — `tests/unit/test_damage_type.gd` :
`test_tables_cover_every_nature`,
`test_only_physical_has_no_field`,
`test_no_color_is_mistaken_for_gold` (l'or est réservé aux critiques et
aux élites), `test_colors_are_distinct_from_each_other` ;
`tests/unit/test_affixes.gd : test_each_nature_adds_to_attacks_and_spells` ; et
`tests/unit/test_status_effects.gd : test_each_nature_applies_one_state_only`.

**Et son anglais** : deux entrées dans `i18n/en.po`, son nom (`NAMES`) et ses
dégâts (`DAMAGE_LABELS`) — « froid » et « dégâts de froid » se traduisent
séparément, parce que l'anglais colle le nom au mot « damage ».

---

## Ajouter un état

Un état est ce qu'un coup laisse sur ce qu'il touche — embrasé, transi, saignant.
Deux sortes : ceux qu'un coup **tire** par sa nature — **une nature en pose exactement
un**, le physique compris, et ils sont dans `ROLLED` —, et ceux qu'un **lancer pose**
(`Skill.inflicted_state`, la décomposition de la Peste) ou qu'une malédiction pose.

1. **`core/status_effects.gd`** — la valeur dans `Kind`, **à la fin** (les tables sont
   indexées par l'enum), puis son entrée dans `NATURES` (sa couleur et la part qu'il
   brûle), `IDS` (**définitif**, un affixe `damage_vs_<id>` le nomme), `NAMES`,
   `AGAINST`, `DURATIONS` et `CHANCE_STATS`. Tiré par une nature : dans `ROLLED`. S'il
   brûle par à-coups qui pourrissent : dans `TICKING`.
2. **Ce qu'il fait** :
   - s'il brûle → son taux dans `_burn_per_second()`. `advance()` le compte
     déjà, et le plus fort l'emporte sans rien écrire de plus ;
   - s'il change une grandeur → un facteur dans `StatusEffects`, **lu là où vit déjà la
     règle qu'il modifie** : la mitigation dans `Hurtbox`, la marche dans
     `Enemy.movement_speed()`, la cadence dans `Enemy._cool_down()` et
     `Player._physics_process()`. Jamais une seconde copie de la règle. Sa force est
     **une constante** (`CURSE`, `CHILL`…) : une réapplication ne fait que rafraîchir.
     Le jour où elle se renforce (passif, talent), la porter sur `State` et la comparer
     dans `put()` comme `per_second` — la plus forte l'emporte, la plus faible ne
     rafraîchit rien.
3. **Son icône** : un masque 7×7 dans `StatusIcon.MASKS`, à la même place que
   dans `Kind`. Le reste — la couleur de l'icône, la teinte et l'annonce — lit
   `StatusEffects.color()`, la couleur de sa nature, sauf quand elle ne se lit pas sur un
   corps, comme le blanc du physique, ou qu'elle se confondrait avec un autre état de
   la même nature : voir `StatusEffects.OWN_COLORS`.

**Ce qui refusera un oubli** — `tests/unit/test_status_effects.gd :
test_chaque_nature_pose_un_etat_et_un_seul` (les tables alignées, chaque nature posée
une fois), `test_each_state_has_its_color`, `test_each_state_has_its_icon` ; `tests/unit/test_translations.gd`, qui relève
`StatusEffects.NAMES` et `AGAINST` ; `test_each_state_has_its_id_and_its_line`.

**Et son nom anglais** dans `i18n/en.po`, section « États ».

---

## Ajouter un archétype d'ennemi

C'est la recette la moins bien gardée par la campagne : **relire cette liste**
plutôt que compter sur les tests.

1. **`resources/<name>_stats.tres`** — sa fiche `CharacterStats`.
2. **`actors/enemies/<name>.gd`** — `extends Enemy`, et une seule méthode à
   écrire : `tick(delta)`. Sa forme est imposée :

   ```gdscript
   func tick(delta: float) -> void:
       if not _should_act():      # en tête, toujours
           return
       # … décider et se déplacer …
       _cool_down(delta)          # une fois par tick, hors du test de portée
       if <à portée> and _attack_cd <= 0.0:
           _strike(direction)     # recharge et anime le coup
           # … frapper …
       else:
           _animate()             # anime depuis la vitesse réelle
   ```

   **Pas de `_physics_process`.** C'est l'`EnemyManager` qui tick — invariant 5.
   `_cool_down` est appelé **hors** du test de portée : glissé dedans,
   l'évaluation paresseuse figerait l'attente d'un ennemi hors de portée.

3. **`actors/enemies/<name>.tscn`** — copier `grunt.tscn`. Les enfants attendus
   par `Enemy` sont `Sprite` (un `ActorSprite`), `Hurtbox`, `HealthBar`,
   `AffixTag`. **Le `ShaderMaterial` du sprite doit être
   `resource_local_to_scene`**, sinon tous les ennemis de l'écran flashent
   ensemble.
4. **`art/sprite_forge.gd`** — le nom dans `ARCHETYPES`, et un cas dans
   `config()` : cinq couleurs, une dizaine de mesures, trois options. La
   silhouette doit se lire **avant** la couleur, dans une mêlée de soixante-dix.

   Puis **son dessin**, par l'un des deux chemins, jamais les deux :

   - **des grilles dessinées à la main** dans `ART` — un corps et trois paires de
     jambes par direction, écrits caractère par caractère avec la légende `INK`,
     plus le poignet d'où part l'arme. C'est le chemin des acteurs du jeu : chaque
     pixel est posé, la palette reste paramétrable et l'animation vient du
     décalage des grilles. Dessiner hors de Godot puis recopier — `Image.save_png`
     tourne en `--headless`, la forge se rend donc sans écran ;
   - **l'assemblage de capsules** de `_draw_front` / `_draw_side`, qui déduit ses
     tons d'un éclairage. Il reste pour ce qui n'est pas un personnage (le
     mannequin) et pour un essai rapide : un archétype absent d'`ART` y tombe
     tout seul.
5. **Le faire naître** : `world/enemy_spawner.gd` pour le peuplement d'une zone,
   ou une touche de `world/test_arena.gd` pour l'essayer seul.
6. **Le juger dans la forge** (`F4`) : quatre variantes côte à côte, les défauts
   de proportion sautent aux yeux.

---

## Ajouter un emplacement d'équipement

1. **`core/equipment_slots.gd`** — l'entrée dans `SLOTS` : `family` et `label`.
   La clé est **définitive** (invariant 1). L'ordre d'insertion est celui dans
   lequel le panneau les montre.
2. **`ui/inventory_panel.gd`** — l'entrée dans `DOLL`, un `Rect2i` en cases : le
   rectangle qu'un objet de cette famille occuperait dans le sac. Ajuster
   `DOLL_COLS` / `DOLL_ROWS` si la grille s'élargit.
3. **Au moins une base** de cette famille, à tous les niveaux de zone.

**Ce qui refusera un oubli** : `test_the_table_is_complete`,
`test_former_slots_keep_their_name`,
`test_each_slot_has_at_least_one_base`,
`test_each_slot_has_a_base_at_every_level`,
`test_the_click_finds_the_drawn_slot` (l'endroit dessiné et l'endroit
cliquable ne peuvent pas diverger), `test_the_panel_stays_in_frame`.

**Et son nom anglais** : une entrée dans `i18n/en.po` pour son `label`.

---

## Ajouter une compétence

1. **`resources/skills/<id>.tres`** — copier une voisine du même manuel.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les barres sauvegardées (invariant 1) |
   | `name` | Ce que le joueur lit ; se change librement |
   | `description` | Ce qu'elle **fait**, en une phrase, pour la fiche de survol : le geste, jamais ses nombres. **Deux lignes au plus** — environ soixante-cinq signes —, sinon la fiche déborde du cadrage |
   | `nature` | Un `DamageType.Kind` : la résistance qui s'y oppose et la couleur du disque de la barre |
   | `cadence` / `cast_time` | Le **temps du geste**. `WEAPON` le lit sur l'arme (`attack_time` / `attack_speed`) et ignore `cast_time` ; `CAST` prend `cast_time` divisé par `cast_speed`. Un sort sans `cast_time` **ni** `cooldown` repartirait à chaque image, et `test_each_skill_declares_the_pace_its_cadence_reads` le refuse |
   | `cooldown` | **La recharge, et rien d'autre** : un délai propre à la compétence que **ni la vitesse d'attaque ni celle d'incantation ne touchent** — seule `CharacterStats.cooldown_recovery` la raccourcit. Zéro pour la plupart des sorts ; non nulle pour ce qu'on ne doit pas enchaîner (une ruée, un vortex) et pour l'anti-rebond d'un geste entretenu. La case attend **le plus long des deux** |
   | `mana_cost` | 0 pour un geste gratuit |
   | `damage_per_point` | Un nombre **par point placé**, dans la nature de la compétence : sa longueur est le maximum de la case. Les objets ajoutent leurs fourchettes par-dessus. **Vide pour ce qui ne frappe pas** — un buff, un déplacement —, et la fiche n'annonce alors ni dégâts, ni forme, ni moyenne |
   | `declared_points_max` | Le nombre de points d'une compétence **sans table de dégâts**, comme un passif. Zéro partout ailleurs |
   | `buffs` | Ce que le lancer pose **sur son lanceur** : un `SkillBuff` par buff — un identifiant, un nom, et des `TalentLine` par point placé, aux règles d'un passif (voir « Ajouter un passif », §2). La fiche ouvre **un bloc par buff, sous son nom** |
   | `health_scaling` | La part des PV max du lanceur ajoutée aux dégâts propres, **par coup**. Zéro pour ce qui ne s'adosse pas à la vie |
   | `shape` | Ce que le lancer pose dans le monde, **et son dessin** : `ARC`, `BOLT`, `STRIKE`, `BALL`, `CHAIN`, `CLOUD`, `AURA`, `SNAKE`, `CROSS`, `ORBIT`, `DASH`, `BUFF`, `WAVE`, `CYCLONE`, `SPIKES`, `NOVA`, `VORTEX`, `BEAM`, `PILLAR`, `PULSE`, `SUMMON`, `GATE`, `CURSE`. `BOLT` et `BALL` donnent `projectile` |
   | `declared_keywords` | **Seulement ce que rien d'autre ne dit** — aujourd'hui rien. Jamais la nature, la cadence ni la forme, qui donnent déjà `lightning`, `spell`, `attack` ou `projectile` |
   | `projectiles` / `spread_in_degrees` | 1 et 0 pour un trait ; 8 et 360 pour une nova |
   | `projectile_speed` | En pixels par seconde ; **obligatoire** dès qu'elle porte `projectile`. La scène du tir n'en déclare plus |
   | `targets` | Une chaîne : combien d'ennemis, le premier compris |
   | `duration` / `period` | Un nuage, un serpent, une orbite : ce qu'ils vivent, et l'écart entre deux frappes — ou entre deux touches d'une même cible. Une aura a une période et pas de durée ; une ruée a une durée, celle de ce qu'elle laisse |
   | `radius` | Une boule (son explosion), un nuage, une aura, un pilier, une pulsation ; et **la longueur** d'un faisceau, dont la largeur est celle de son dessin |
   | `simultaneous` | Une orbite : combien à la fois. Zéro, sans limite |
   | `self_burn` | Une aura, un buff : la part des PV max qu'il brûle au lanceur par seconde. **Mortelle** |
   | `mana_per_second` | Un buff, un cyclone : le mana drainé par seconde, **à plat**. La réserve vide **l'éteint** |
   | `self_heal` | Ce qu'un geste entretenu **rend** par seconde, en part des PV max. Le pendant de `self_burn`, et sans mitigation : un soin ne se résiste pas |
   | `self_wither` | Un buff : la part des PV **actuels** qu'il ronge par seconde. Jamais mortelle |
   | `inflicted_state` / `inflict_chance` | L'état qu'elle **pose** à ce qu'elle touche (`StatusEffects.Kind`, hors de `ROLLED`) et sa chance ; −1 pour rien. Ce qu'il brûle part du coup, donc du niveau du sort. Une malédiction n'a que ça |
   | `status_chance_increase` | Ce que ce lancer **accroît** à la chance de poser son état, en points de pourcentage — +50 sur la Nova de glace, qui fait passer 20 % à 30 %. Il s'additionne aux accrus du porteur. **Hors de portée des nœuds** : c'est ce qui distingue une compétence de sa voisine. La fiche le montre **avec ce qu'il donne**, et seulement si la sorte a sa statistique dans `StatusEffects.CHANCE_STATS` |
   | `binds_caster` | Ce geste enferme-t-il son lanceur : rien d'autre ne part, on ne bouge plus, et seule son extinction reste permise |
   | `required_manual_level` | À partir de quand la case accepte son premier point |

2. **`core/skill_catalog.gd`** — le `preload` dans `ALL`. C'est le seul
   endroit qui les liste, et c'est là que les sauvegardes retrouvent un
   identifiant.

3. **Le manuel qui l'enseigne** — une `ManualCell` de plus dans son `.tres`,
   avec sa **position sur la page**. Deux cases à la même position se
   recouvriraient sans que rien ne le dise. La grille fait **quatre colonnes sur
   deux rangées** : au-delà, la case sort de la fenêtre.

4. **Son arbre**, s'il y en a un : voir « Ajouter un nœud de talent ». Une
   compétence sans nœud reste jouable — sa case ouvre alors une vue qui ne montre
   que sa racine.

Deux compétences d'un même manuel doivent **se distinguer par ce qu'elles
font** — une chaîne, un nuage, une aura — et pas seulement par leurs nombres :
sinon c'est une seule compétence à plusieurs réglages, et l'arbre de la première
dit déjà mieux la même chose. C'est la leçon du jalon 11, qui a retiré deux sorts
de foudre qui n'étaient qu'un éclair vif à d'autres réglages.

**Une ruée** (`DASH`) porte le lanceur au curseur, à `PLACEMENT_RANGE` au plus, **murs
et ennemis traversés** — seule l'arrivée doit être libre. Elle veut une `duration`,
celle de ce qu'elle laisse, et **l'un ou l'autre** : un `radius` et une `period` pour
une trace qui frappe, ou des `buffs` pour ce qu'elle pose sur le lanceur. Une
`period` **égale à sa `duration`** donne une trace qui ne frappe qu'une fois tout le
couloir : c'est la Ruée tranchante, un coup d'épée sur toute la traversée. **Un buff**
(`BUFF`) veut un drain — PV ou mana — et au moins un `SkillBuff` : il n'a pas de dégâts,
donc ni arbre de talents utile, ni « moyenne par lancer ». Les buffs d'un lancer
s'allument et s'éteignent **ensemble**, sous l'identifiant de la compétence.

**Un faisceau** (`BEAM`) part du lanceur dans sa visée, frappe **une fois tout ce qui
est sur sa ligne** — `Targets.in_capsule()`, qui ne s'arrête pas au premier corps — et
s'efface. Il veut un `radius`, qui est sa longueur. **Un pilier** (`PILLAR`) tombe au
curseur et **une pulsation** (`PULSE`) est portée par le lanceur : tous deux veulent
une `duration`, une `period` et un `radius`, et frappent leur cercle à chaque
impulsion. Une pulsation **finit seule** — elle ne se paie pas à la seconde, donc elle
n'est pas un geste entretenu et ne s'éteint pas à la touche.

**Une invocation** (`SUMMON`) relève des `Minion` jusqu'à `simultaneous`, qui gardent
le `radius` autour du joueur et frappent à la `period` — au nom du joueur. **Un portail**
(`GATE`) tombe au curseur, vit `duration` et crache une créature par `period`, qui
explose au `radius`. **Une malédiction** (`CURSE`) n'a ni dégâts ni buff : un `radius`
et un `inflicted_state`, posé d'un coup sur son cercle, avec `declared_points_max`.

**Un geste entretenu** est `AURA`, `BUFF` ou `CYCLONE` : `Player._is_sustained()` en
décide, la case s'allume et s'éteint sur la même touche, et `SkillStats.sustained`
retire la « moyenne par lancer ». Les trois veulent un prix par seconde.

**Une forme neuve** est un geste à part : une valeur de plus **à la fin** de
`Skill.Shape` (les `.tres` écrivent l'entier), son cas dans
`Player.cast_slot()`, son nœud dans `actors/skills/` — qui passe par
`Targets` pour trouver ses cibles et par `Hurtbox.take_damage()` pour frapper —, et
son test dans `tests/integration/test_shapes.gd`.

**Son dessin** suit le skill `/dessiner-un-effet` — planche choisie par
l'utilisateur, puis captures réelles — et se fait dans son `_draw()`, avec le module de sa matière quand elle
en a une — `fx/lightning.gd` (tracée), `fx/fire.gd`, `fx/frost.gd`, `fx/holy.gd`,
`fx/slash.gd` et `fx/necrotic.gd`, qui posent les planches de `EffectForge` (dessinées) —, parce que quatre façons de dessiner un
éclair, une flamme ou un cristal ne se liraient pas comme la même chose. Une matière
**tracée** prend `material = ArtPalette.ADDITIVE` au `_ready()` et les textures de
`fx/glow.gd` plutôt que des primitives : un cœur
(`Glow.draw_blob`), un bord de zone (`Glow.draw_ring`, dont la crête tombe pile sur le
rayon qui mord), une comète (`Glow.draw_streak`, tête sur `from` — elle repose la
transformation à l'identité, donc un appelant qui en avait posé une la repose). Un
`draw_arc` d'un pixel se lit comme un affichage de portée, et surtout **rien ne brille
en dessous de 0,9 de luminance** : un effet a besoin d'un cœur presque blanc, pas d'un
aplat à alpha 0,25. Une matière **dessinée**, elle, ne prend **pas** l'additif — son
contour sombre n'y ajoute rien —, se cale sur `EffectForge.snap()`, et ne s'éteint
pas en pâlissant : une planche à demi-transparente sur un sol sombre sort grise. Elle
se coupe, redescend sous terre ou se vide de ses pièces. Si elle a un nombre neuf : le
champ dans `SkillStats` et son `LABELS`, sa copie dans
`Skill.resolve()`, sa ligne dans la fiche du manuel, et sa condition dans
`test_each_shape_has_the_numbers_it_needs`.

**Ce qui refusera un oubli** — `tests/unit/test_skills.gd` :
`test_each_skill_has_an_id`, `test_ids_are_unique`,
`test_chaque_competence_vise_des_champs_reels`,
`test_each_skill_has_what_it_takes_to_deal_damage`,
`test_each_declared_keyword_belongs_to_the_list`,
`test_do_not_declare_what_nature_or_cadence_already_say`,
`test_each_skill_casting_projectiles_has_a_speed`,
`test_each_shape_has_the_numbers_it_needs`,
`test_a_skill_without_a_damage_table_declares_its_points_and_its_lines`,
`test_without_modifier_resolution_returns_the_sheet` ; et
`tests/integration/test_manual_panel.gd :
test_les_cases_tiennent_dans_le_panneau`, qui refuse une case posée hors de la
page, et `test_the_sheet_stays_in_frame`, qui refuse une case dont la fiche
au survol sortirait de l'écran.

**Et son nom anglais** : deux entrées dans `i18n/en.po` pour son `name` et sa
`description`, une de plus par buff qu'elle pose. Il s'écrit
en entier dans le menu de la barre et en tête de sa fiche, tous deux étroits —
`tests/integration/test_widths.gd` refuse un nom qui déborde.

---

## Ajouter un mot-clé

Un mot-clé est une **prise** : il n'existe que parce qu'un modificateur mord
dessus, et le joueur le lit sur la page du manuel comme une promesse. D'où la
règle qui ressemble à celle des statistiques : **on n'ajoute pas un mot-clé
seul.** Il arrive avec au moins un affixe qui le vise, ou il n'arrive pas.

1. **`core/keywords.gd`** — la constante, puis son entrée dans `LABELS`, **à
   sa place dans l'ordre de lecture** : ce que la compétence fait, sa nature, sa
   famille. L'identifiant est **définitif** (invariant 1) ; le libellé se change
   librement. Puis **ses deux phrases** : `QUALIFIERS` (« de feu »), qui qualifie les
   dégâts et les niveaux dans la phrase, et `RECIPIENTS` (« aux compétences de feu »),
   qui dit à qui s'adresse tout le reste. Si le mot-clé fait **avec les dégâts un seul
   nom** qu'une langue ne coupe pas — « damage over time » —, il va dans `DAMAGE_NOUNS`
   à la place de `QUALIFIERS`. Sans elles, la ligne finit entre parenthèses
   et `test_no_content_line_ends_in_parentheses` la refuse.
2. **D'où il vient** :
   - de la nature → une entrée dans `Skill.KEYWORD_OF_NATURE` ;
   - de la cadence → une entrée dans `Skill.KEYWORD_OF_CADENCE` ;
   - de rien d'autre → `declared_keywords` dans les `.tres` qui le portent.
3. **Un affixe qui le vise** — `scope` dans son `.tres`, voir « Ajouter un
   affixe d'objet ».
4. Si ce qu'il doit modifier n'est pas encore un nombre de lancer : le champ dans
   `SkillStats`, son entrée dans `LABELS`, et sa copie dans
   `Skill.resolve()`. Puis le lire là où le lancer le consomme.

**Ce qui refusera un oubli** : `test_each_keyword_has_a_label_and_each_deduction_targets_the_list`,
`test_each_declared_keyword_belongs_to_the_list`, et surtout
`tests/unit/test_affixes.gd : test_each_keyword_is_targeted_by_something` —
le mot-clé décoratif, affiché sans que rien ne le vise.

**Et son anglais** : son libellé dans `i18n/en.po`, son qualificatif (« de feu » →
« fire », que le gabarit remet avant le nom) et son destinataire (« aux sorts » →
« to spells »).

---

## Ajouter un passif

Un passif est une case de manuel qu'on ne lance pas : ses points agissent tant
que le livre est au râtelier. Ses lignes sont **celles d'un affixe** — même
forme, même application, même façon de s'écrire à l'écran.

1. **Dans le `.tres` du manuel** — une `ManualCell` de plus, avec `passive`
   au lieu de `skill`, et sa position sur la grille. Une case porte l'un ou
   l'autre, **jamais les deux** : les deux donneraient deux compteurs de points
   pour un seul identifiant.

   | Champ du `Passive` | À remplir |
   |---|---|
   | `id` | Unique dans le livre, **définitif** — il part dans les sauvegardes, dans le même dictionnaire que les cases et les nœuds (invariant 1) |
   | `name` | Ce que le joueur lit |
   | `required_manual_level` | À partir de quel niveau du livre la case s'ouvre |
   | `points_max` | Combien de points elle accepte. Un champ, contrairement à une compétence qui le déduit de sa table de dégâts |
   | `lines` | Un `TalentLine` par effet : `stat`, `percentage`, `value_per_point`, et `value_max_per_point` pour une fourchette. `more` fait d'un pourcentage un « plus », qui multiplie après la somme des accrus : **réservé aux lignes `damage` des nœuds et aux clés de voûte de l'arbre de passifs**, les passifs de manuel restent accrus (jalon 14) |

2. **Ce qu'une ligne peut viser** — c'est la règle des affixes, à la lettre :
   - `scope` **vide** → un champ réel de `CharacterStats`, présent dans
     `StatMod.LABELS` ; il agit sur la fiche du personnage ;
   - `scope` **remplie** → un mot-clé de `Keywords`, et un nombre de
     `SkillStats` (ou des dégâts ajoutés `damage_<nature>`) ; il agit sur
     **toutes** les compétences qui portent ce mot-clé, même celles d'un autre
     livre du râtelier.

3. **Rien à écrire ailleurs.** `Player.recompute_stats()` verse déjà les passifs
   du râtelier dans la même liste que les objets portés, et le tri qui suit
   décide de ce qui va à la fiche et de ce qui va aux compétences.

**Ce qui refusera un oubli** — `tests/unit/test_talents.gd` :
`test_each_slot_holds_one_thing_only`,
`test_a_book_ids_are_unique`,
`test_each_passive_line_targets_the_sheet_or_a_keyword` (la faute de frappe qui
ne casse rien : le point placé ne fait simplement rien),
`test_no_manual_fills_up_entirely` ; et
`tests/integration/test_player.gd : test_a_rack_passive_enters_the_sheet`
et `test_a_passive_leaves_with_its_book`.

**Et son nom anglais** dans `i18n/en.po`, plus la tenue de sa fiche dans les deux
langues — `tests/integration/test_widths.gd`.

---

## Ajouter un nœud à l'arbre de passifs

L'arbre est **un seul fichier**, `resources/passive_tree.tres` : un `PassiveTree` et ses
`PassiveNode` en sous-ressources. 496 nœuds liés se relisent mal dans
l'inspecteur ; retoucher le texte du `.tres` est le geste attendu.

**D'abord, chemin ou cluster ?**

- **Un nœud de chemin** — un axe ou un anneau — ne porte **que** des attributs : +10
  sur un axe, +5/+5 sur un anneau (celui de l'axe le plus proche en premier, pour
  l'icône). Jamais un pourcentage : traverser l'arbre rend des attributs, pas des
  dégâts. Le troisième anneau (`far_*`) est à 35 cases du départ, au-delà des clés de
  voûte ; ses clusters pendent dehors, entre 39 et 49 cases.
- **Un nœud de cluster** va dans un cul-de-sac branché sur **une seule** jonction du
  squelette. Un cluster relié à deux jonctions devient un raccourci qu'on prend en
  passant ; ne le faire qu'en le voulant.
- **La place manque** depuis le jalon 26 : la couronne des clusters est pleine sur tout
  le haut, et l'arbre ne peut plus grandir en hauteur sans sortir du zoom large (−49 à
  +46 remplissent déjà le cadre). Chercher un tracé **par le calcul** — distances et
  croisements contre tous les nœuds — avant de l'écrire ; en largeur, il reste de la
  marge.
- **Un notable** dit le thème de son cluster plus fort, avec une seconde ligne. **Pas
  de clé de voûte de plus** : trois « plus » suffisent (jalon 17, §8).

**Ensuite, ce que le nœud vaut.** Un petit nœud qui accroît des dégâts prend la valeur
de sa **portée**, et rien d'autre : plus elle est étroite, moins il sert souvent, plus
il donne (jalon 23).

| Palier | Ce que la ligne exige | Valeur |
|---|---|---|
| large | `attack` ou `spell` | **8 %** |
| étroit | une nature ou une forme : `fire`, `cold`, `lightning`, `melee`, `projectile`, `area` | **10 %** |
| conditionnel | `damage_vs_<état>`, quelle que soit la portée | **12 %** |

`test_each_small_damage_line_sits_on_the_specificity_scale` refuse tout le reste ; une
valeur hors de la table est une régression, pas un réglage. Le **notable** en est
libre : il vaut à peu près deux petits et demi, répartis comme son thème le demande —
la table ne le juge pas. Les lignes qui ne sont pas des dégâts (résistances, vitesses,
chances d'état) n'ont pas de palier : c'est l'affixe de la même statistique qui les
calibre.

1. **Une sous-ressource `PassiveNode`**, et sa référence dans le tableau `nodes` du
   `[resource]`.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans la liste des nœuds pris d'une sauvegarde (invariant 1) |
   | `name` | Vide pour un petit nœud ; **obligatoire** pour un notable ou une clé de voûte, et traduit |
   | `kind` | `1` petit (le défaut, qui ne s'écrit pas), `2` notable, `3` clé de voûte. `0` est le départ, **unique** |
   | `position` | En cases de la grille (`PassiveTreePanel.UNIT` pixels chacune), le départ en `0, 0` ; l'intelligence vers le haut, la force en bas à gauche, la dextérité en bas à droite. Deux nœuds n'ont jamais la même case |
   | `links` | Les identifiants voisins, **d'un seul côté** : `PassiveTree` rend le graphe symétrique |
   | `lines` | Des `TalentLine`, pris une fois — `value_per_point` est la valeur du nœud. Les règles d'une ligne de passif de manuel (voir « Ajouter un passif »), plus `more` pour une clé de voûte. Pas de `damage` sans portée : la fiche n'a pas de champ de dégâts |

2. **Le relier** : un nœud sans chemin vers le départ ne se prendra jamais.

   **Son lien ne doit croiser aucun autre** (`test_no_two_links_cross`) : un
   carrefour qui n'existe pas fait suivre la mauvaise branche à l'œil. Et le garder à
   **une case au moins** d'un lien voisin — en dessous, les deux traits se confondent
   à l'écran ; c'est l'écart le plus serré de l'arbre actuel.

   **Deux cases au moins entre deux nœuds**, y compris ceux d'un autre cluster
   (`test_two_nodes_never_crowd_each_other`) : les pastilles font 6 px de rayon pour
   une case de 10, donc à une case elles se touchent. C'est le plancher de l'arbre,
   mesuré : aucune paire n'est en dessous.

   **Son icône** se lit sur sa **première ligne** (`PassiveIcon.look_of()`) : une
   statistique ou un mot-clé que `PassiveIcon.SHEET` et `SCOPED` ne connaissent pas
   encore y demande une entrée — un masque de `MASKS` et une couleur.

3. **Retirer ou renommer un nœud** efface ce nœud **et ceux qu'il reliait** chez tout
   personnage qui l'avait pris (`PassiveTree.legal()`) : ne le faire qu'en le sachant.

4. **Le banc** : un nœud qui change un chemin de `BenchProfiles.builds()` se vérifie
   par `test_each_path_is_taken_in_full`, puis `tools/balance.sh calculation`.

**Ce qui refusera un oubli** — `tests/unit/test_passive_tree.gd` :
`test_the_content_ids_are_unique_and_one_start`, `test_each_link_targets_an_existing_node`,
`test_each_node_is_reachable_from_the_start`, `test_two_nodes_never_crowd_each_other`,
`test_each_line_targets_the_sheet_or_a_cast_number`, `test_each_notable_and_keystone_is_named`,
`test_each_small_damage_line_sits_on_the_specificity_scale`,
`test_each_node_has_its_icon`, `test_the_tree_offers_more_nodes_than_points` ;
`tests/unit/test_translations.gd` pour le nom.

**Et son nom anglais** dans `i18n/en.po`, section « Arbre de passifs ». Puis
`tools/catalog.sh`, qui liste l'arbre dans [CATALOGUE.md](CATALOGUE.md).

---

## Ajouter un nœud de talent

Un nœud change **la façon dont une compétence se joue**. Il vit sur la case du
manuel et non sur la compétence : deux manuels qui enseigneraient le même sort
l'orienteraient chacun à leur façon.

1. **Dans le `.tres` du manuel**, dans le tableau `talents` de la case.

   | Champ | À remplir |
   |---|---|
   | `id` | **Définitif**, et unique dans le livre. La forme `<compétence>_<nœud>` le tient hors de portée d'un homonyme |
   | `name` | Ce que le joueur lit |
   | `position` | Sur la petite grille de l'arbre : **trois colonnes sur deux rangées**, à droite de la racine |
   | `parent` | L'identifiant du nœud dont il dépend, ou vide : il part alors de la compétence |
   | `required_points` | Combien de points dans **la compétence** l'ouvrent. Jamais zéro, jamais plus que ce que la case accepte |
   | `points_max` | Combien de points il accepte |
   | `lines` | Comme celles d'un passif, mais **sans portée** : un nœud ne vise que sa compétence, et ne peut donc viser qu'un nombre de `SkillStats` — dont `use_time` et `recharge` depuis le jalon 23. **`interval` ne se vise pas**, il se déduit des deux |
   | `converts_to` / `converted_part_per_point` | La nature d'arrivée et la part déplacée. **C'est la part qui dit s'il y a conversion** : l'enum commence au physique |
   | `added_keywords` | Ce que le nœud donne à sa compétence — **seulement un mot-clé de nature**. `projectile`, `attack` et `spell` décident du chemin du lancer |

2. **Un échange se dit dans les deux sens** : « +2 projectiles » et
   « −25 % dégâts » sur le même nœud. C'est le seul endroit du jeu où un point
   placé peut faire baisser un nombre, et c'est ce qui rend un arbre intéressant
   plutôt qu'additionnel.

   **Effacer un nombre se dit par −100 %** : c'est ainsi que « Sans répit » retire
   sa recharge à la Ruée d'orage. Un plat négatif la ferait passer sous zéro sur une
   autre compétence ; l'accru, lui, l'annule quelle qu'elle soit. Retirer la recharge
   coupe la case de `cooldown_recovery` et la remet à la cadence du lanceur : c'est un
   échange, pas un cadeau, et le nœud le paie en allongeant `use_time`.

3. **Rien à écrire ailleurs** : `Manual.can_invest()` porte déjà les
   conditions, `Player.talents_of()` les rassemble, et `Skill.resolve()`
   les applique — donc la page du manuel les annonce sans qu'on la touche.

**Ce qui refusera un oubli** — `tests/unit/test_talents.gd` :
`test_each_parent_exists_in_the_same_tree`,
`test_each_tree_has_a_root_and_stays_reachable` (un nœud qui demande plus
de points que la case n'en accepte ne s'ouvrirait jamais),
`test_each_node_line_targets_a_cast_number`,
`test_a_node_gives_only_one_nature_keyword`,
`test_each_conversion_targets_another_nature` ; et
`tests/integration/test_manual_panel.gd : test_slots_and_nodes_fit_in_the_panel`,
qui refuse un nœud posé hors de la fenêtre.

**Et son nom anglais** dans `i18n/en.po`.

---

## Ajouter un manuel

Un manuel est **une base d'objet** de plus, plus un archétype.

1. **`resources/manuals/<id>.tres`** — l'archétype : son nom, et une
   `ManualCell` par compétence **ou par passif**, chacune à sa position. Un
   manuel sans passif est permis ; un manuel sans compétence, non — c'est un
   objet de quatre cases de sac qui n'apprend rien à lancer.
2. **`resources/items/manuel_<id>.tres`** — la base : `family = "manual"`,
   `tags = ["manual"]`, sa propre `lineage` d'un seul palier, et le champ `manual`
   qui pointe sur l'archétype. Son `tier` dit sa **rareté**, pas son rang de
   relève.
3. **Son propre `kind`**, et un cas dans `SpriteForge._gear()` plus son entrée
   dans `GEAR` : tous les manuels ont le même palier, donc les mêmes couleurs, et
   c'est la **silhouette** qui doit les séparer dans un sac. Cinq livres au même
   dessin sont cinq objets qu'on ne distingue qu'en les survolant. Les six
   d'aujourd'hui : une pile couchée, un livre ouvert en V, un rouleau, un livre debout,
   un livre couché dans son halo, un livre couché sous un crâne — les deux derniers
   débordent du livre lui-même, une orientation de plus se serait confondue avec les
   quatre autres.
4. **`core/item_catalog.gd`** — le `preload` dans le bloc des manuels.
5. **Vérifier le budget** : `docs/CATALOGUE.md` donne, pour chaque manuel, le
   nombre de destinations de points contre les vingt qu'un livre gagne. En
   dessous de vingt, le manuel se remplit entièrement et cesse d'être un choix.

**Ce qui refusera un oubli** — `tests/unit/test_manuals.gd` :
`test_an_archetype_goes_with_the_manual_family` (une base porte un archétype
**si et seulement si** elle est de la famille des manuels),
`test_chaque_case_porte_une_competence`, `test_a_manual_receives_no_affix`.

**Et ses deux noms anglais** dans `i18n/en.po` : celui de l'archétype, qui coiffe
la page, et celui de la base, que le sac affiche. Ce sont deux textes différents
— « Maître de la foudre » et « Manuel de la foudre ».

Un manuel échappe aux règles écrites pour l'équipement — affixes, lignée à
paliers, implicite croissant — et la question se pose à un seul endroit :
`EquipmentSlots.equippable_family()`.

---

## Ajouter une classe jouable

Le dessin d'abord, par `tools/character_forge.py` — la recette complète, pièges
compris, est [tools/characters/LISEZMOI.md](../tools/characters/LISEZMOI.md). Puis :

1. **`core/character.gd`** — une entrée dans `CLASSES` : l'archétype de la forge
   (le nom de `art/characters/<id>.png`) et le nom affiché.
2. **`art/sprite_forge.gd`** — l'archétype dans `ARCHETYPES`. Rien d'autre : palette
   et arme par défaut sont lues dans la planche.
3. **`core/save_store.gd`** — `create()` si la classe part avec un autre
   équipement.
4. **`ui/character_select.gd`** — ses vignettes dans `LOOKS`.
5. **`i18n/en.po`** — son nom ; `test_no_orphan_translation` relit `CLASSES`.

`test_a_sheet_plays_its_generated_cycles` refuse une planche sans marche, coup
d'épée ou lancer générés, ou dont une image n'a pas sa main armée — l'ajouter à sa
liste de corps ;
`test_every_animation_of_a_sheet_moves`, une animation dont deux images sont
identiques.

---

## Faire évoluer le format de sauvegarde

La recette la plus dangereuse du dépôt : elle se rate en silence et ne se voit
qu'au **premier lancement après la mise à jour**, sur les fichiers des joueurs.

1. **`core/character.gd`** — le champ dans `to_dict()` **et** dans
   `from_dict()`, avec une valeur par défaut quand il est absent. Un champ
   isolé qui manque ne doit jamais faire échouer le personnage entier.
2. **Monter `VERSION`.**
3. **Ajouter l'ancien numéro à `READABLE_VERSIONS`**, et décider ce que devient un
   fichier de l'ancien format. Ne jamais deviner : les objets d'une v1 prennent
   le niveau 1 parce qu'on ne sait pas dans quelle zone ils sont tombés.
4. **`tests/fixtures/character_v<N>.json`** — écrire à la main un fichier de
   référence du nouveau format, et **garder les anciens**.
5. **Si une statistique disparaît**, les lignes d'objet qui la visent sont dans
   les fichiers des joueurs : les convertir dans `Character._current_line()`
   par une **équivalence exacte** avec le jeu d'avant, ou les retirer avec un
   `push_warning`. Voir `test_attack_damage_becomes_physical_to_attacks`
   et `test_a_damage_percentage_is_removed`.

Les fichiers de référence attrapent exactement ce que l'aller-retour en mémoire
ne peut pas voir : le jour où `unspent_points` devient `points`, l'aller-retour
passe toujours (les deux côtés ont changé ensemble) et le fichier de référence,
lui, ne se relit plus. Voir [tests/fixtures/LISEZMOI.md](../tests/fixtures/LISEZMOI.md).

**Ne jamais régénérer un fichier de référence pour faire passer un test.**

---

## Ajouter un réglage joueur

1. **`core/settings.gd`** — la propriété avec son `set`, qui sort sans rien faire
   sur une valeur inchangée puis appelle `_announce()` : ceux qui lisent le réglage,
   puis le disque. Puis son entrée dans `to_dict()` et `from_dict()`.
2. **`ui/pause_menu.tscn` et `.gd`** — la case ou le bouton dans le `VBox`
   `Options`. **Poser la valeur avant de connecter le signal** : dans l'autre
   sens, l'initialisation émet un `toggled` et réécrit le réglage avec lui-même.

Un réglage qui ne survit pas à la fermeture n'est pas un réglage.
`tests/integration/test_settings_disk.gd` couvre l'aller-retour, le fichier
abîmé et l'absence de fichier.

---

## Ajouter un terme au glossaire

Un mot que le joueur doit pouvoir comprendre sans quitter l'écran : en gras là où il
apparaît, et son encadré à côté.

1. **`core/glossary.gd`** — son entrée dans `TERMS` (identifiant **définitif**, il
   voyage dans la marque ; ses quatre formes `ms`, `fs`, `mp`, `fp` ; son encadré), et
   l'encadré dans `ENTRIES` s'il est nouveau (titre et définition, en français).
2. **Là où le mot s'écrit** — `Glossary.term(id, accord)` dans une place `{terme}`
   du gabarit. Jamais le mot en clair : sans marque, il n'est ni gras ni expliqué.
3. **Là où le texte se dessine** — `RichText` pour la ligne, et
   `GlossaryBoxes.draw()` en dernier, avec le rectangle qui montre le texte.
4. **`i18n/en.po`** — chaque forme, le titre et la définition. `test_translations`
   les relève dans `Glossary`.

**Ce qui refusera un oubli** — `tests/unit/test_glossary.gd` : quatre formes et un
encadré par terme, un titre et une définition par encadré, aucune marque dans
`en.po` ; `test_translations.gd` pour l'anglais.

---

## Ajouter un texte affiché

**Le texte français est la clé.** Le code l'écrit en clair, `i18n/en.po` en donne
l'anglais, et il n'existe pas de fichier français. Le prix de ce choix : retoucher
un texte change sa clé, et sa traduction tombe sans un mot — l'anglais réaffiche
alors le français.

1. **Dans le code** — l'envelopper dans `Texts.t("…")` **là où il est lu**, et
   jamais là où il est dessiné : une table de libellés se traduit dans sa
   fonction de lecture (`StatMod.name()`, `Keywords.label_of()`,
   `EquipmentSlots.label()`), un contenu par son accesseur
   (`Item.display_name()`, `Skill.displayed_name()`). Un texte posé dans une
   scène — `Label`, `Button`, texte fantôme d'un champ — n'a **rien** à faire :
   Godot le traduit seul.
2. **`i18n/en.po`** — `msgid` le français, `msgstr` l'anglais, dans la section
   qui va bien.
3. **Une phrase se traduit entière.** Dès qu'elle porte deux valeurs ou plus,
   elles sont **nommées** : `Texts.t("ajoute {bas} à {haut} {degats}")`. Collée
   à partir de morceaux, elle sortirait en anglais dans l'ordre du français.
4. **Un pluriel** passe par `Texts.tn(singular, plural, n)` : le français met
   le singulier à zéro, l'anglais le pluriel, et c'est `en.po` qui porte la règle
   de chaque langue.
5. **Deux sens pour un même mot** demandent un contexte :
   `Texts.t("vitesse", "fiche de compétence")`, et un `msgctxt` dans le `.po`.
6. **Un pourcentage** s'écrit par `StatMod.percentage()` — l'espace devant le
   signe est une règle française, et le gabarit est lui-même traduit.
   **Un terme du glossaire** (accru, amplifié…) par `Glossary.term()`, jamais écrit
   dans la clé : le gabarit lui réserve une place `{terme}`, et ce qui le dessine
   passe par `RichText`.
7. **Ce qui est dessiné à la main doit redessiner** quand la langue change :
   `_notification(NOTIFICATION_TRANSLATION_CHANGED)`. Elle arrive **aussi à
   l'entrée dans l'arbre**, donc la garder derrière `is_node_ready()` dès qu'on y
   touche un `@onready`. Ce qui **mesure** un texte une fois — `AffixTag` — doit
   le re-mesurer.

**Ce qui refusera un oubli** — `tests/unit/test_translations.gd` :
`test_each_displayed_text_has_its_english` (les tables, le contenu, les scènes, et
chaque littéral confié à `Texts`), `test_no_orphan_translation` (une entrée
d'`en.po` que plus rien n'affiche est un texte français qui a changé),
`test_templates_keep_their_values` ; et `tests/integration/test_widths.gd`,
qui refuse un texte débordant **dans l'une des deux langues**.

Ce qui **ne se traduit pas** : les outils de réglage (forge `F4`, arène `F2`,
établi `B`, bandeau `H`), `CATALOGUE.md`, la console (`push_warning`), et les
identifiants.

---

## Refaire les tuiles de décor

```bash
tools/tiles.py gen            # trois graines par sujet, ~10 s l'une
tools/tiles.py make           # écrit art/tiles/atlas.png depuis les graines retenues
```

ComfyUI doit tourner ; depuis WSL il répond sur l'IP de l'hôte, pas sur
`127.0.0.1` (variable `COMFY`). Le sujet et la graine retenue sont **la même
ligne** de `tools/tiles.json` : refaire une tuile, c'est changer l'un des deux.

Trois réglages, et ce sont les seuls qui comptent :

| Constante | Ce qu'elle décide |
|---|---|
| `CROP` | **L'échelle de la pierre**, en part du rendu de 1024 px. À 10 %, un pavé fait six pixels dans la tuile ; à 30 %, il en fait un et il ne reste qu'un grain gris |
| `FLOOR_LUM` / `WALL_LUM` | La luminance visée. **Plus basse que celle de la couleur de base** : à moyenne égale, une pierre appareillée se lit plus claire qu'un aplat, et les ennemis s'y noient |
| `FLOOR_SPREAD` | Le contraste interne. C'est lui qui fait la différence entre « de la pierre » et « un damier qui crie » |
| `FLOOR_PATCHES` | **Combien d'amas de pierre par variante, la première étant nue.** Une texture qui couvre son cadre d'un bord à l'autre est une paroi, quelle que soit sa couleur : un sol, c'est de la terre et quelques pierres. Et quatre tuiles toutes marquées se répètent visiblement dès qu'on en voit trente |

Le négatif refuse explicitement la maçonnerie (`brick`, `masonry`, `mortar
lines`, `running bond`, `wall`) : sans ça, « dungeon stone floor » sort un mur de
briques à tous les coups, et le sol finit par être le mur repeint d'une autre
couleur.

Le modèle donne la **matière** — le grain, les fissures, la distribution des
valeurs. Il ne décide ni la valeur du sol, ni quelle tuile de mur porte son
dessus éclairé : ça, c'est `tools/tiles.py` et `TilesetBuilder`, et ça ne se
délègue pas, sous peine de perdre l'écart mesuré entre le décor et les acteurs.

**Ce qui refusera un oubli** : rien. Aucune assertion ne voit une tuile — juger
sur une capture réelle en fenêtré, avec des ennemis dessus, jamais sur l'atlas
seul.

---

## Régénérer la documentation

```bash
tools/catalog.sh          # docs/CATALOGUE.md, depuis les .tres
tools/balance.sh calculation # docs/EQUILIBRAGE.md, la grille seule
tools/balance.sh        # et la simulation, bien plus lente
```

Après un réglage d'équilibrage — une échelle d'affixe, la courbe des ennemis, une table
de dégâts —, relancer le calcul puis `tests/run.sh balance`. Un profil nouveau ou
un build de plus s'ajoute dans `tools/balance/profiles.gd` ; son test d'étape 1,
`tests/unit/test_bench_profiles.gd`, refuse un profil aux points mal placés.

Les autres documents (`ARCHITECTURE.md`, `RECETTES.md`, `README.md`) sont
écrits à la main : ils décrivent des décisions, et aucune décision ne se génère.
