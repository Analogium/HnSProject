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
   | `implicit_*` | Le bonus que porte toute la base, sans tirage |

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

---

## Ajouter un affixe d'objet

1. **`resources/item_affixes/<id>.tres`** — copier un affixe qui vise la même
   sorte de statistique, pour hériter d'une échelle plausible.

   | Champ | À remplir |
   |---|---|
   | `id` | Unique, **définitif** — il part dans les sauvegardes |
   | `stat` | Un champ **réel** de `CharacterStats`, présent dans `StatMod.LABELS` |
   | `percent` | Pourcentage plutôt que valeur absolue |
   | `tags` | Les étiquettes visées ; **vide = partout** |
   | `exclut` | Ce qui refuse, et **qui l'emporte** sur `tags` |
   | `arrondi` | Le pas de la valeur tirée : `1` pour un entier, `0.01` pour une fraction |
   | `weight` | Son poids dans la réserve |
   | `tiers` | L'échelle, **du meilleur au pire** |

2. **L'échelle** est la seule partie délicate :
   - le **premier** de la liste est le T1, le meilleur ;
   - le **dernier** doit exiger `niveau_requis = 1`, sinon l'affixe n'existe pas
     dans les premières zones et sa première sortie ressemble à un ajout de
     contenu plutôt qu'à une progression ;
   - la monotonie est obligatoire : niveau requis et valeurs croissent ensemble
     du bas vers le haut.

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
`test_la_reserve_ne_contient_pas_deux_fois_la_meme_ligne`.

---

## Ajouter une statistique

Deux tests forment une **bijection** qu'il faut satisfaire des deux côtés :

- `test_tout_ce_qui_se_modifie_se_lit_sur_la_fiche` — tout affixe doit viser une
  statistique affichée ;
- `test_chaque_statistique_de_la_fiche_est_atteignable_par_un_affixe` — toute
  statistique affichée doit être atteignable par un affixe.

Autrement dit : **on n'ajoute pas une statistique seule.** Elle arrive avec au
moins un affixe, ou elle n'arrive pas.

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

---

## Ajouter une nature de dégâts

C'est la recette qui montre pourquoi `DamageType` est une feuille sans
dépendance : quatre tables alignées sur un seul enum.

1. **`core/damage_type.gd`** — la valeur dans `Kind`, **à la fin** (l'enum est
   indexé par des tableaux), puis son entrée dans les trois tables : `NAMES`,
   `COLORS`, `RESIST_FIELDS`.
2. **`core/character_stats.gd`** — le champ `res_<nom>`, du même nom que dans
   `RESIST_FIELDS`.
3. **`core/stat_mod.gd`** — `LABELS` et `PERCENT_POINTS`.
4. **`ui/stats_panel.gd`** — dans le groupe `RÉSISTANCES`.
5. **Un affixe** qui la donne, avec `exclut = ["weapon"]` comme ses sœurs.

`StatHelp` n'a **rien** à changer : sa ligne « plafonnée à 75 % » est écrite pour
tout ce qui est dans `RESIST_FIELDS`, donc la nouvelle nature en hérite.

**Ce qui refusera un oubli** — `tests/unit/test_damage_type.gd` :
`test_les_tables_couvrent_toutes_les_natures`,
`test_seul_le_physique_n_a_pas_de_champ`,
`test_aucune_couleur_ne_confond_avec_l_or` (l'or est réservé aux critiques et
aux élites), `test_les_couleurs_sont_distinctes_entre_elles`.

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
   | `degats_par_point` | Un nombre **par point placé** : sa longueur est le maximum de la case |
   | `stat_de_base` | `attack_damage` ou `spell_damage` — le terme qui garde les affixes vivants |
   | `attribut` / `pourcentage_par_attribut` | Vide pour ce qui ne monte avec rien |
   | `projectiles` / `dispersion_en_degres` | 1 et 0 pour un trait ; 3 et 24 pour une salve ; 8 et 360 pour une nova |
   | `niveau_de_manuel_requis` | À partir de quand la case accepte son premier point |

2. **`core/competence_catalog.gd`** — le `preload` dans `ALL`. C'est le seul
   endroit qui les liste, et c'est là que les sauvegardes retrouvent un
   identifiant.

3. **Le manuel qui l'enseigne** — une `CaseDeManuel` de plus dans son `.tres`,
   avec sa **position sur la page**. Deux cases à la même position se
   recouvriraient sans que rien ne le dise.

**Ce qui refusera un oubli** — `tests/unit/test_competences.gd` :
`test_chaque_competence_a_un_identifiant`, `test_les_identifiants_sont_uniques`,
`test_chaque_competence_vise_des_champs_reels`,
`test_chaque_competence_a_de_quoi_faire_des_degats` ; et
`tests/integration/test_panneau_manuels.gd :
test_les_cases_tiennent_dans_le_panneau`, qui refuse une case posée hors de la
page.

---

## Ajouter un manuel

Un manuel est **une base d'objet** de plus, plus un archétype.

1. **`resources/manuels/<id>.tres`** — l'archétype : son nom, et une
   `CaseDeManuel` par compétence, chacune à sa position.
2. **`resources/items/manuel_<id>.tres`** — la base : `family = "manual"`,
   `tags = ["manual"]`, `kind = "manuel"`, et le champ `manuel` qui pointe sur
   l'archétype. Son `palier` dit sa **rareté**, pas son rang de relève.
3. **`core/item_catalog.gd`** — le `preload` dans le bloc des manuels.

**Ce qui refusera un oubli** — `tests/unit/test_manuels.gd` :
`test_un_archetype_va_avec_la_famille_du_manuel` (une base porte un archétype
**si et seulement si** elle est de la famille des manuels),
`test_chaque_case_porte_une_competence`, `test_un_manuel_ne_recoit_aucun_affixe`.

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

## Régénérer la documentation

```bash
tools/catalogue.sh          # docs/CATALOGUE.md, depuis les .tres
```

Les trois autres documents (`ARCHITECTURE.md`, `RECETTES.md`, `README.md`) sont
écrits à la main : ils décrivent des décisions, et aucune décision ne se génère.
