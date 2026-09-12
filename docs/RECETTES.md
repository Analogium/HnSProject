# Recettes

Les gestes qu'on refait tous les trois jalons, avec **les fichiers dans
l'ordre** et **le test qui refusera l'oubli**. Les invariants qu'elles
respectent sont dans [ARCHITECTURE.md](ARCHITECTURE.md).

Après chacune : `tests/run.sh`. Après celles qui touchent un `.tres` de contenu :
`tools/catalogue.sh`, qui régénère [CATALOGUE.md](CATALOGUE.md).

> Dans un `.tres`, Godot **n'écrit que ce qui diffère du défaut du script**.
> `epee_large.tres` ne contient ni `kind` ni `family` : les deux valent déjà
> `"sword"` et `"weapon"`. Ne pas s'étonner de ne pas les y trouver.

---

## Ajouter une base d'objet

1. **`resources/items/<id>.tres`** — copier le voisin de sa lignée, c'est plus
   sûr que de partir de rien.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les sauvegardes (invariant 1) |
   | `display_name` | Ce que le joueur lit ; se change librement |
   | `kind` | Le dessin, au sens de `SpriteForge` — voir l'étape 3 |
   | `family` | L'emplacement qui l'accepte, ou vide s'il ne s'équipe pas |
   | `tags` | **La famille en fait partie**, plus ce qui décrit l'objet (`melee`, `heavy`, `caster`…) |
   | `lignee` / `palier` | La suite à laquelle il appartient, et son rang |
   | `niveau_requis` | La zone à partir de laquelle il tombe |
   | `grid_size` | Son encombrement en cases |
   | `implicit_*` | Le bonus que porte toute la base, sans tirage. Pour des dégâts ajoutés : `implicit_stat = degats_<nature>`, les deux bornes dans `implicit_value` et `implicit_value_max`, et la famille visée dans `implicit_portee` (`attaque` ou `sort`) |

2. **`core/item_catalog.gd`** — ajouter le `preload` dans `ALL`, **dans le bloc
   de sa lignée et par palier croissant**. C'est le seul endroit où les bases
   sont listées ; l'ordre est celui des planches de la forge.

3. **`art/sprite_forge.gd`**, seulement si le `kind` est nouveau :
   - une arme → un cas dans `_weapon()` ;
   - autre chose → un cas dans `_gear()` **et** l'ajouter à la liste `GEAR`,
     qui sert d'aiguillage entre les deux.

   Sans ça l'icône sort vide, et personne ne le voit avant de l'avoir ramassé.

4. Vérifier la **fenêtre de chute** dans `docs/CATALOGUE.md` après régénération.
   Elle n'est écrite nulle part : elle naît de la rencontre entre `niveau_requis`
   et le palier suivant de la lignée. Insérer un palier au milieu **raccourcit
   celui d'avant**.

**Ce qui refusera un oubli** — `tests/unit/test_catalogue.gd` :
`test_chaque_base_a_un_identifiant`, `test_les_identifiants_sont_uniques`,
`test_chaque_base_a_une_icone_non_vide`,
`test_chaque_base_porte_sa_famille_en_etiquette`,
`test_les_implicites_visent_des_statistiques_reelles`,
`test_chaque_lignee_est_monotone` (un palier supérieur doit demander un niveau
supérieur **et** donner un implicite supérieur), `test_aucune_base_n_a_une_fenetre_vide`,
`test_chaque_emplacement_a_une_base_a_tous_les_niveaux`.

**Et son nom anglais** : une entrée dans `i18n/en.po`, dont le `msgid` est le
`display_name` français. Voir « Ajouter un texte affiché ».

---

## Ajouter un affixe d'objet

1. **`resources/item_affixes/<id>.tres`** — copier un affixe qui vise la même
   sorte de statistique, pour hériter d'une échelle plausible.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les sauvegardes |
   | `stat` | Sans portée : un champ **réel** de `CharacterStats`, présent dans `StatMod.LABELS`. Avec : un nombre de `StatsDeCompetence.LABELS`, ou des dégâts ajoutés `degats_<id>` sur `DamageType.IDS` — ceux-là n'existent **qu'avec une portée** |
   | `portee` | Vide pour la fiche du personnage ; sinon **un mot-clé de `MotsCles`**, et l'affixe n'agit que sur les compétences qui le portent |
   | `percent` | Pourcentage plutôt que valeur absolue |
   | `tags` | Les étiquettes visées ; **vide = partout** |
   | `exclut` | Ce qui refuse, et **qui l'emporte** sur `tags` |
   | `arrondi` | Le pas de la valeur tirée : `1` pour un entier, `0.01` pour une fraction |
   | `weight` | Son poids dans la réserve |
   | `tiers` | L'échelle, **du meilleur au pire**. Pour des dégâts ajoutés, deux plages par palier : `min_value`/`max_value` pour la borne basse, `min_haut`/`max_haut` pour la borne haute |

2. **L'échelle** est la seule partie délicate :
   - le **premier** de la liste est le T1, le meilleur ;
   - le **dernier** doit exiger `niveau_requis = 1`, sinon l'affixe n'existe pas
     dans les premières zones et sa première sortie ressemble à un ajout de
     contenu plutôt qu'à une progression ;
   - la monotonie est obligatoire : niveau requis et valeurs croissent ensemble
     du bas vers le haut ;
   - une fourchette l'est **sur ses deux bornes**, et sa plage basse ne dépasse
     jamais sa plage haute : un objet ne doit pas pouvoir tirer « ajoute 9 à 7 ».

3. **`core/item_affix_pool.gd`** — ajouter le `preload` dans `ALL`.

4. **Préférer une exclusion à une liste d'autorisations** quand la règle est
   « partout sauf ». Une base ajoutée plus tard hérite du refus sans qu'on y
   pense, là où une liste d'autorisations l'aurait oubliée en silence.

**Ce qui refusera un oubli** — `tests/unit/test_affixes.gd` :
`test_chaque_affixe_vise_un_champ_reel_et_nomme`,
`test_tout_ce_qui_se_modifie_se_lit_sur_la_fiche` (voir la recette suivante),
`test_chaque_echelle_est_monotone`, `test_chaque_affixe_existe_des_le_niveau_1`,
`test_le_tier_1_est_le_meilleur`, `test_l_arrondi_est_le_meme_a_tous_les_paliers`,
`test_aucune_etiquette_d_affixe_ne_vise_le_vide` (une étiquette qui ne
correspond à aucune base est une faute de frappe qui ne se verrait jamais),
`test_la_reserve_ne_contient_pas_deux_fois_la_meme_ligne`,
`test_chaque_affixe_porte_vise_un_mot_cle_et_un_nombre_de_lancer`,
`test_chaque_fourchette_est_monotone_et_a_l_endroit`,
`test_une_fourchette_tiree_reste_dans_ses_deux_plages` ; et
`tests/integration/test_atelier.gd : test_chaque_affixe_accepte_a_sa_ligne`, qui
refuse une base dont la liste déborde du bas de l'établi.

---

## Ajouter une statistique

Deux tests forment une **bijection** qu'il faut satisfaire des deux côtés :

- `test_tout_ce_qui_se_modifie_se_lit_sur_la_fiche` — tout affixe doit viser une
  statistique affichée ;
- `test_chaque_statistique_de_la_fiche_est_atteignable_par_un_affixe` — toute
  statistique affichée doit être atteignable par un affixe.

Autrement dit : **on n'ajoute pas une statistique seule.** Elle arrive avec au
moins un affixe, ou elle n'arrive pas.

Les lignes « attaque » et « trait » du groupe OFFENSE ne sont pas des
statistiques : ce sont les deux compétences de départ, résolues par le chemin du
lancer. Leur explication est dans `StatHelp.COMPETENCES`, et elles comptent comme
atteintes dès qu'un affixe de dégâts ajoutés vise l'un de leurs mots-clés.

1. **`core/character_stats.gd`** — le champ `@export`, dans son groupe.
2. **`core/stat_mod.gd`** — son entrée dans `LABELS` (l'unité fait partie du nom
   quand elle n'est pas évidente : « PV/s » et non « régénération »). Puis, si
   elle se lit en pourcentage :
   - rangée en fraction ou en multiplicateur (0.05 → « 5 % ») → `SCALED` ;
   - déjà comptée en points de pourcentage (75 → « 75 % ») → `PERCENT_POINTS`.

   Confondre les deux donne « 7500 % de résistance au feu ».
3. **`ui/stat_help.gd`** — son entrée dans `TEXTS` : ce qu'elle fait, en une
   phrase. Ajouter un cas dans `_now()` seulement si le nombre affiché ne parle
   pas de lui-même — une notation d'armure, oui ; « 90 de vitesse », non.
4. **`ui/stats_panel.gd`** — sa place dans `GROUPS`, qui est l'ordre de lecture.
5. **Un affixe qui la vise**, voir la recette précédente.
6. Si elle doit croître avec le niveau de zone : `CharacterStats.mettre_a_l_echelle`.

**Ce qui refusera un oubli** : les deux tests ci-dessus, plus
`test_chaque_statistique_de_la_fiche_a_son_explication`,
`test_aucune_explication_ne_vise_un_champ_inconnu`, et surtout
`test_la_fiche_tient_dans_sa_hauteur` — la fiche doit tenir **entière** dans les
360 pixels du cadrage, et c'est le groupe des attributs, ajouté après coup, qui
avait fait déborder la dernière ligne sur l'aide du bas.

**Et son anglais** : deux entrées dans `i18n/en.po`, son nom de `LABELS` et son
explication de `StatHelp`. La fiche doit ensuite tenir dans **les deux langues** —
`tests/integration/test_largeurs.gd`.

---

## Ajouter une nature de dégâts

C'est la recette qui montre pourquoi `DamageType` est une feuille sans
dépendance : des tables alignées sur un seul enum.

1. **`core/damage_type.gd`** — la valeur dans `Kind`, **à la fin** (l'enum est
   indexé par des tableaux), puis son entrée dans les cinq tables : `NAMES`,
   `IDS` (**définitif** : il forme le nom `degats_<id>` que les sauvegardes
   écrivent), `LIBELLES_DE_DEGATS`, `COLORS`, `RESIST_FIELDS`.
2. **`core/character_stats.gd`** — le champ `res_<nom>`, du même nom que dans
   `RESIST_FIELDS`.
3. **`core/stat_mod.gd`** — `LABELS` et `PERCENT_POINTS`.
4. **`ui/stats_panel.gd`** — dans le groupe `RÉSISTANCES`.
5. **Un affixe** qui la donne, avec `exclut = ["weapon"]` comme ses sœurs.
6. **Deux affixes de dégâts ajoutés**, `<id>_aux_attaques` et `<id>_aux_sorts` :
   copier ceux d'une nature voisine, échelle comprise. Une nature est une nature
   comme les autres, même si aucune compétence n'en est encore.

`StatHelp` n'a **rien** à changer : sa ligne « plafonnée à 75 % » est écrite pour
tout ce qui est dans `RESIST_FIELDS`, donc la nouvelle nature en hérite. La fiche
du manuel non plus : elle écrit une ligne par nature ajoutée, dans sa couleur.

Une nature **ne donne pas de mot-clé d'elle-même** : il faut l'entrée dans
`Competence.MOT_CLE_DE_NATURE` et un affixe qui la vise — voir « Ajouter un
mot-clé ». Sans eux, une compétence de feu n'affiche simplement pas « Feu ».

**Ce qui refusera un oubli** — `tests/unit/test_damage_type.gd` :
`test_les_tables_couvrent_toutes_les_natures`,
`test_seul_le_physique_n_a_pas_de_champ`,
`test_aucune_couleur_ne_confond_avec_l_or` (l'or est réservé aux critiques et
aux élites), `test_les_couleurs_sont_distinctes_entre_elles` ; et
`tests/unit/test_affixes.gd : test_chaque_nature_s_ajoute_aux_attaques_et_aux_sorts`.

**Et son anglais** : deux entrées dans `i18n/en.po`, son nom (`NAMES`) et ses
dégâts (`LIBELLES_DE_DEGATS`) — « froid » et « dégâts de froid » se traduisent
séparément, parce que l'anglais colle le nom au mot « damage ».

---

## Ajouter un archétype d'ennemi

C'est la recette la moins bien gardée par la campagne : **relire cette liste**
plutôt que compter sur les tests.

1. **`resources/<nom>_stats.tres`** — sa fiche `CharacterStats`.
2. **`actors/enemies/<nom>.gd`** — `extends Enemy`, et une seule méthode à
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

3. **`actors/enemies/<nom>.tscn`** — copier `grunt.tscn`. Les enfants attendus
   par `Enemy` sont `Sprite` (un `ActorSprite`), `Hurtbox`, `HealthBar`,
   `AffixTag`. **Le `ShaderMaterial` du sprite doit être
   `resource_local_to_scene`**, sinon tous les ennemis de l'écran flashent
   ensemble.
4. **`art/sprite_forge.gd`** — le nom dans `ARCHETYPES`, et un cas dans
   `config()` : cinq couleurs, une dizaine de mesures, trois options. La
   silhouette doit se lire **avant** la couleur, dans une mêlée de soixante-dix.
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

**Ce qui refusera un oubli** : `test_la_table_est_complete`,
`test_les_emplacements_d_avant_gardent_leur_nom`,
`test_chaque_emplacement_a_au_moins_une_base`,
`test_chaque_emplacement_a_une_base_a_tous_les_niveaux`,
`test_le_clic_retrouve_l_emplacement_dessine` (l'endroit dessiné et l'endroit
cliquable ne peuvent pas diverger), `test_le_panneau_tient_dans_le_cadrage`.

**Et son nom anglais** : une entrée dans `i18n/en.po` pour son `label`.

---

## Ajouter une compétence

1. **`resources/competences/<id>.tres`** — copier une voisine du même manuel.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les barres sauvegardées (invariant 1) |
   | `nom` | Ce que le joueur lit ; se change librement |
   | `nature` | Un `DamageType.Kind` : la résistance qui s'y oppose et la couleur du disque de la barre |
   | `cadence` / `recharge` | `ARME` suit la fiche (`attack_cooldown`) ; `INCANTATION` suit `recharge` divisée par `cast_speed` |
   | `cout_en_mana` | 0 pour un geste gratuit |
   | `degats_par_point` | Un nombre **par point placé**, dans la nature de la compétence : sa longueur est le maximum de la case. Les objets ajoutent leurs fourchettes par-dessus |
   | `attribut` / `pourcentage_par_attribut` | Vide pour ce qui ne monte avec rien |
   | `mots_cles_declares` | **Seulement ce que rien d'autre ne dit** — aujourd'hui `projectile`. Jamais la nature ni la cadence, qui donnent déjà `foudre`, `sort` ou `attaque` |
   | `projectiles` / `dispersion_en_degres` | 1 et 0 pour un trait ; 3 et 24 pour une salve ; 8 et 360 pour une nova |
   | `vitesse_de_projectile` | En pixels par seconde ; **obligatoire** dès qu'elle porte `projectile`. La scène du tir n'en déclare plus |
   | `niveau_de_manuel_requis` | À partir de quand la case accepte son premier point |

2. **`core/competence_catalog.gd`** — le `preload` dans `ALL`. C'est le seul
   endroit qui les liste, et c'est là que les sauvegardes retrouvent un
   identifiant.

3. **Le manuel qui l'enseigne** — une `CaseDeManuel` de plus dans son `.tres`,
   avec sa **position sur la page**. Deux cases à la même position se
   recouvriraient sans que rien ne le dise. La grille fait **quatre colonnes sur
   deux rangées** : au-delà, la case sort de la fenêtre.

4. **Son arbre**, s'il y en a un : voir « Ajouter un nœud de talent ». Une
   compétence sans nœud reste jouable — sa case ouvre alors une vue qui ne montre
   que sa racine.

Deux compétences d'un même manuel doivent **se distinguer par ce qu'elles
font** — un trait, un cône, un coup lourd — et pas seulement par leurs nombres :
sinon c'est une seule compétence à plusieurs réglages, et l'arbre de la première
dit déjà mieux la même chose.

**Ce qui refusera un oubli** — `tests/unit/test_competences.gd` :
`test_chaque_competence_a_un_identifiant`, `test_les_identifiants_sont_uniques`,
`test_chaque_competence_vise_des_champs_reels`,
`test_chaque_competence_a_de_quoi_faire_des_degats`,
`test_chaque_mot_cle_declare_appartient_a_la_liste`,
`test_on_ne_declare_pas_ce_que_la_nature_ou_la_cadence_disent_deja`,
`test_chaque_competence_qui_lance_des_projectiles_a_une_vitesse`,
`test_sans_modificateur_la_resolution_rend_la_fiche` ; et
`tests/integration/test_panneau_manuels.gd :
test_les_cases_tiennent_dans_le_panneau`, qui refuse une case posée hors de la
page, et `test_la_fiche_reste_dans_le_cadrage`, qui refuse une case dont la fiche
au survol sortirait de l'écran.

**Et son nom anglais** : une entrée dans `i18n/en.po` pour son `nom`. Il s'écrit
en entier dans le menu de la barre et en tête de sa fiche, tous deux étroits —
`tests/integration/test_largeurs.gd` refuse un nom qui déborde.

---

## Ajouter un mot-clé

Un mot-clé est une **prise** : il n'existe que parce qu'un modificateur mord
dessus, et le joueur le lit sur la page du manuel comme une promesse. D'où la
règle qui ressemble à celle des statistiques : **on n'ajoute pas un mot-clé
seul.** Il arrive avec au moins un affixe qui le vise, ou il n'arrive pas.

1. **`core/mots_cles.gd`** — la constante, puis son entrée dans `LIBELLES`, **à
   sa place dans l'ordre de lecture** : ce que la compétence fait, sa nature, sa
   famille. L'identifiant est **définitif** (invariant 1) ; le libellé se change
   librement.
2. **D'où il vient** :
   - de la nature → une entrée dans `Competence.MOT_CLE_DE_NATURE` ;
   - de la cadence → une entrée dans `Competence.MOT_CLE_DE_CADENCE` ;
   - de rien d'autre → `mots_cles_declares` dans les `.tres` qui le portent.
3. **Un affixe qui le vise** — `portee` dans son `.tres`, voir « Ajouter un
   affixe d'objet ».
4. Si ce qu'il doit modifier n'est pas encore un nombre de lancer : le champ dans
   `StatsDeCompetence`, son entrée dans `LABELS`, et sa copie dans
   `Competence.resoudre()`. Puis le lire là où le lancer le consomme.

**Ce qui refusera un oubli** : `test_chaque_mot_cle_a_un_libelle_et_chaque_deduction_vise_la_liste`,
`test_chaque_mot_cle_declare_appartient_a_la_liste`, et surtout
`tests/unit/test_affixes.gd : test_chaque_mot_cle_est_vise_par_quelque_chose` —
le mot-clé décoratif, affiché sans que rien ne le vise.

**Et son anglais** : son libellé dans `i18n/en.po`, plus son destinataire s'il
en a un (« aux sorts » → « to spells »), qui est le morceau de phrase que porte
une ligne de dégâts ajoutés.

---

## Ajouter un passif

Un passif est une case de manuel qu'on ne lance pas : ses points agissent tant
que le livre est au râtelier. Ses lignes sont **celles d'un affixe** — même
forme, même application, même façon de s'écrire à l'écran.

1. **Dans le `.tres` du manuel** — une `CaseDeManuel` de plus, avec `passif`
   au lieu de `competence`, et sa position sur la grille. Une case porte l'un ou
   l'autre, **jamais les deux** : les deux donneraient deux compteurs de points
   pour un seul identifiant.

   | Champ du `Passif` | À remplir |
   |---|---|
   | `id` | Unique dans le livre, **définitif** — il part dans les sauvegardes, dans le même dictionnaire que les cases et les nœuds (invariant 1) |
   | `nom` | Ce que le joueur lit |
   | `niveau_de_manuel_requis` | À partir de quel niveau du livre la case s'ouvre |
   | `points_max` | Combien de points elle accepte. Un champ, contrairement à une compétence qui le déduit de sa table de dégâts |
   | `lignes` | Un `LigneDeTalent` par effet : `stat`, `pourcentage`, `valeur_par_point`, et `valeur_max_par_point` pour une fourchette |

2. **Ce qu'une ligne peut viser** — c'est la règle des affixes, à la lettre :
   - `portee` **vide** → un champ réel de `CharacterStats`, présent dans
     `StatMod.LABELS` ; il agit sur la fiche du personnage ;
   - `portee` **remplie** → un mot-clé de `MotsCles`, et un nombre de
     `StatsDeCompetence` (ou des dégâts ajoutés `degats_<nature>`) ; il agit sur
     **toutes** les compétences qui portent ce mot-clé, même celles d'un autre
     livre du râtelier.

3. **Rien à écrire ailleurs.** `Player.recompute_stats()` verse déjà les passifs
   du râtelier dans la même liste que les objets portés, et le tri qui suit
   décide de ce qui va à la fiche et de ce qui va aux compétences.

**Ce qui refusera un oubli** — `tests/unit/test_talents.gd` :
`test_chaque_case_porte_une_chose_et_une_seule`,
`test_les_identifiants_d_un_livre_sont_uniques`,
`test_chaque_ligne_de_passif_vise_la_fiche_ou_un_mot_cle` (la faute de frappe qui
ne casse rien : le point placé ne fait simplement rien),
`test_aucun_manuel_ne_se_remplit_entierement` ; et
`tests/integration/test_player.gd : test_un_passif_du_ratelier_entre_dans_la_fiche`
et `test_un_passif_s_en_va_avec_son_livre`.

**Et son nom anglais** dans `i18n/en.po`, plus la tenue de sa fiche dans les deux
langues — `tests/integration/test_largeurs.gd`.

---

## Ajouter un nœud de talent

Un nœud change **la façon dont une compétence se joue**. Il vit sur la case du
manuel et non sur la compétence : deux manuels qui enseigneraient le même sort
l'orienteraient chacun à leur façon.

1. **Dans le `.tres` du manuel**, dans le tableau `talents` de la case.

   | Champ | À remplir |
   |---|---|
   | `id` | **Définitif**, et unique dans le livre. La forme `<compétence>_<nœud>` le tient hors de portée d'un homonyme |
   | `nom` | Ce que le joueur lit |
   | `position` | Sur la petite grille de l'arbre : **trois colonnes sur deux rangées**, à droite de la racine |
   | `parent` | L'identifiant du nœud dont il dépend, ou vide : il part alors de la compétence |
   | `points_requis` | Combien de points dans **la compétence** l'ouvrent. Jamais zéro, jamais plus que ce que la case accepte |
   | `points_max` | Combien de points il accepte |
   | `lignes` | Comme celles d'un passif, mais **sans portée** : un nœud ne vise que sa compétence, et ne peut donc viser qu'un nombre de `StatsDeCompetence` |
   | `convertit_vers` / `part_convertie_par_point` | La nature d'arrivée et la part déplacée. **C'est la part qui dit s'il y a conversion** : l'enum commence au physique |
   | `mots_cles_ajoutes` | Ce que le nœud donne à sa compétence — **seulement un mot-clé de nature**. `projectile`, `attaque` et `sort` décident du chemin du lancer |

2. **Un échange se dit dans les deux sens** : « +2 projectiles » et
   « −25 % dégâts » sur le même nœud. C'est le seul endroit du jeu où un point
   placé peut faire baisser un nombre, et c'est ce qui rend un arbre intéressant
   plutôt qu'additionnel.

3. **Rien à écrire ailleurs** : `Manuel.peut_investir()` porte déjà les
   conditions, `Player.talents_de()` les rassemble, et `Competence.resoudre()`
   les applique — donc la page du manuel les annonce sans qu'on la touche.

**Ce qui refusera un oubli** — `tests/unit/test_talents.gd` :
`test_chaque_parent_existe_dans_le_meme_arbre`,
`test_chaque_arbre_a_une_racine_et_reste_atteignable` (un nœud qui demande plus
de points que la case n'en accepte ne s'ouvrirait jamais),
`test_chaque_ligne_de_noeud_vise_un_nombre_de_lancer`,
`test_un_noeud_ne_donne_qu_un_mot_cle_de_nature`,
`test_chaque_conversion_vise_une_autre_nature` ; et
`tests/integration/test_panneau_manuels.gd : test_les_cases_et_les_noeuds_tiennent_dans_le_panneau`,
qui refuse un nœud posé hors de la fenêtre.

**Et son nom anglais** dans `i18n/en.po`.

---

## Ajouter un manuel

Un manuel est **une base d'objet** de plus, plus un archétype.

1. **`resources/manuels/<id>.tres`** — l'archétype : son nom, et une
   `CaseDeManuel` par compétence **ou par passif**, chacune à sa position. Un
   manuel sans passif est permis ; un manuel sans compétence, non — c'est un
   objet de quatre cases de sac qui n'apprend rien à lancer.
2. **`resources/items/manuel_<id>.tres`** — la base : `family = "manual"`,
   `tags = ["manual"]`, sa propre `lignee` d'un seul palier, et le champ `manuel`
   qui pointe sur l'archétype. Son `palier` dit sa **rareté**, pas son rang de
   relève.
3. **Son propre `kind`**, et un cas dans `SpriteForge._gear()` plus son entrée
   dans `GEAR` : tous les manuels ont le même palier, donc les mêmes couleurs, et
   c'est la **silhouette** qui doit les séparer dans un sac. Trois livres au même
   dessin sont trois objets qu'on ne distingue qu'en les survolant.
4. **`core/item_catalog.gd`** — le `preload` dans le bloc des manuels.
5. **Vérifier le budget** : `docs/CATALOGUE.md` donne, pour chaque manuel, le
   nombre de destinations de points contre les vingt qu'un livre gagne. En
   dessous de vingt, le manuel se remplit entièrement et cesse d'être un choix.

**Ce qui refusera un oubli** — `tests/unit/test_manuels.gd` :
`test_un_archetype_va_avec_la_famille_du_manuel` (une base porte un archétype
**si et seulement si** elle est de la famille des manuels),
`test_chaque_case_porte_une_competence`, `test_un_manuel_ne_recoit_aucun_affixe`.

**Et ses deux noms anglais** dans `i18n/en.po` : celui de l'archétype, qui coiffe
la page, et celui de la base, que le sac affiche. Ce sont deux textes différents
— « Maître de la foudre » et « Manuel de la foudre ».

Un manuel échappe aux règles écrites pour l'équipement — affixes, lignée à
paliers, implicite croissant — et la question se pose à un seul endroit :
`EquipmentSlots.famille_equipable()`.

---

## Faire évoluer le format de sauvegarde

La recette la plus dangereuse du dépôt : elle se rate en silence et ne se voit
qu'au **premier lancement après la mise à jour**, sur les fichiers des joueurs.

1. **`core/personnage.gd`** — le champ dans `vers_dict()` **et** dans
   `depuis_dict()`, avec une valeur par défaut quand il est absent. Un champ
   isolé qui manque ne doit jamais faire échouer le personnage entier.
2. **Monter `VERSION`.**
3. **Ajouter l'ancien numéro à `VERSIONS_LUES`**, et décider ce que devient un
   fichier de l'ancien format. Ne jamais deviner : les objets d'une v1 prennent
   le niveau 1 parce qu'on ne sait pas dans quelle zone ils sont tombés.
4. **`tests/fixtures/personnage_v<N>.json`** — écrire à la main un fichier de
   référence du nouveau format, et **garder les anciens**.
5. **Si une statistique disparaît**, les lignes d'objet qui la visent sont dans
   les fichiers des joueurs : les convertir dans `Personnage._ligne_actuelle()`
   par une **équivalence exacte** avec le jeu d'avant, ou les retirer avec un
   `push_warning`. Voir `test_des_degats_d_attaque_deviennent_du_physique_aux_attaques`
   et `test_un_pourcentage_de_degats_est_retire`.

Les fichiers de référence attrapent exactement ce que l'aller-retour en mémoire
ne peut pas voir : le jour où `points_a_placer` devient `points`, l'aller-retour
passe toujours (les deux côtés ont changé ensemble) et le fichier de référence,
lui, ne se relit plus. Voir [tests/fixtures/LISEZMOI.md](../tests/fixtures/LISEZMOI.md).

**Ne jamais régénérer un fichier de référence pour faire passer un test.**

---

## Ajouter un réglage joueur

1. **`core/settings.gd`** — la propriété avec son `set`, qui appelle `_ecrire()`
   et, si des nœuds doivent réagir, `changed.emit()`. Puis son entrée dans
   `vers_dict()` et `depuis_dict()`.
2. **`ui/pause_menu.tscn` et `.gd`** — la case ou le bouton dans le `VBox`
   `Options`. **Poser la valeur avant de connecter le signal** : dans l'autre
   sens, l'initialisation émet un `toggled` et réécrit le réglage avec lui-même.

Un réglage qui ne survit pas à la fermeture n'est pas un réglage.
`tests/integration/test_reglages_disque.gd` couvre l'aller-retour, le fichier
abîmé et l'absence de fichier.

---

## Ajouter un texte affiché

**Le texte français est la clé.** Le code l'écrit en clair, `i18n/en.po` en donne
l'anglais, et il n'existe pas de fichier français. Le prix de ce choix : retoucher
un texte change sa clé, et sa traduction tombe sans un mot — l'anglais réaffiche
alors le français.

1. **Dans le code** — l'envelopper dans `Textes.t("…")` **là où il est lu**, et
   jamais là où il est dessiné : une table de libellés se traduit dans sa
   fonction de lecture (`StatMod.nom()`, `MotsCles.libelle()`,
   `EquipmentSlots.label()`), un contenu par son accesseur
   (`Item.display_name()`, `Competence.nom_affiche()`). Un texte posé dans une
   scène — `Label`, `Button`, texte fantôme d'un champ — n'a **rien** à faire :
   Godot le traduit seul.
2. **`i18n/en.po`** — `msgid` le français, `msgstr` l'anglais, dans la section
   qui va bien.
3. **Une phrase se traduit entière.** Dès qu'elle porte deux valeurs ou plus,
   elles sont **nommées** : `Textes.t("ajoute {bas} à {haut} {degats}")`. Collée
   à partir de morceaux, elle sortirait en anglais dans l'ordre du français.
4. **Un pluriel** passe par `Textes.tn(singulier, pluriel, n)` : le français met
   le singulier à zéro, l'anglais le pluriel, et c'est `en.po` qui porte la règle
   de chaque langue.
5. **Deux sens pour un même mot** demandent un contexte :
   `Textes.t("vitesse", "fiche de compétence")`, et un `msgctxt` dans le `.po`.
6. **Un pourcentage** s'écrit par `StatMod.pourcentage()` — l'espace devant le
   signe est une règle française, et le gabarit est lui-même traduit.
7. **Ce qui est dessiné à la main doit redessiner** quand la langue change :
   `_notification(NOTIFICATION_TRANSLATION_CHANGED)`. Elle arrive **aussi à
   l'entrée dans l'arbre**, donc la garder derrière `is_node_ready()` dès qu'on y
   touche un `@onready`. Ce qui **mesure** un texte une fois — `AffixTag` — doit
   le re-mesurer.

**Ce qui refusera un oubli** — `tests/unit/test_traductions.gd` :
`test_chaque_texte_affiche_a_son_anglais` (les tables, le contenu, les scènes, et
chaque littéral confié à `Textes`), `test_aucune_traduction_orpheline` (une entrée
d'`en.po` que plus rien n'affiche est un texte français qui a changé),
`test_les_gabarits_gardent_leurs_valeurs` ; et `tests/integration/test_largeurs.gd`,
qui refuse un texte débordant **dans l'une des deux langues**.

Ce qui **ne se traduit pas** : les outils de réglage (forge `F4`, arène `F2`,
établi `B`, bandeau `H`), `CATALOGUE.md`, la console (`push_warning`), et les
identifiants.

---

## Régénérer la documentation

```bash
tools/catalogue.sh          # docs/CATALOGUE.md, depuis les .tres
```

Les trois autres documents (`ARCHITECTURE.md`, `RECETTES.md`, `README.md`) sont
écrits à la main : ils décrivent des décisions, et aucune décision ne se génère.
