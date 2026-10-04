# Hack'n'slash top-down — jalon 39

Suite des jalons 1 à 38. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 3 octobre 2026.** Les arbres du **Maître chevalier**.

---

## 1. Ce que l'utilisateur a demandé

« Comme pour le précédent jalon » : le manuel suivant, le chevalier (`manual_weapons`),
repris comme la nécromancie au jalon 38 — **pas de nœud qui revienne d'un arbre à
l'autre**, avec les mêmes trois exceptions (un nœud de dégâts, de rayon et de durée par
arbre au plus ; un échange ⇄ et le prix d'un nœud qui change le jeu n'en comptent pas).

## 2. L'état de départ

Deux ou trois nœuds chiffrés par compétence, convertis tels quels au jalon 34. Deux
conversions (Lame ardente, Lame sainte), une bascule (Enchaînement) ; **rien ne change
la façon dont un geste se joue**. Garde de fer est un passif : pas d'arbre, comme Cœur
de braise.

| compétence | forme | ce qu'elle fait | nœuds actuels |
|---|---|---|---|
| Frappe lourde | `STRIKE` | un coup d'arme, secousse forte | Élan, Lame ardente (→ feu), Saignée (+3 à 8 phys.) |
| Coup en croix | `CROSS` | deux coups d'arme | Taille, Estoc (+2 à 6 phys.), Lame sainte (→ sacré) |
| Épée spirale | `ORBIT` | 3 épées au plus tournent autour de soi, 5 s | Ronde, Tranchant, Endurance |
| Vague tranchante | `WAVE` | l'arc du coup part droit devant, mord une fois par corps | Fil de l'arc, Course |
| Cyclone | `CYCLONE` | entretenu, frappe son cercle toutes les 0,35 s, draine 10 mana/s | Fauchage, Envergure |
| Ruée tranchante | `DASH` | se rue au curseur, un couloir tranchant derrière | Fil tranchant, Andain, Enchaînement |

**L'identité du chevalier** : ce qui **pèse** (l'impact, le recul), ce qui **ouvre**
(le saignement, l'état que tire le physique), ce qui **garde** (les lames autour de soi,
la vie reprise au coup) et ce qui **porte** (la vague, la charge). Pas de froid ni de
contrôle durable, pas d'invocation.

`Saignée` et `Estoc` portent la même ligne (`damage_physical`) dans deux arbres : la
règle en retire une. Saignée part — son nom promettait un saignement qu'elle ne posait
pas, et le saignement va au Coup en croix.

## 3. Ce qui se réutilise tel quel

| nombre / forme | sur | pourquoi ça marche déjà |
|---|---|---|
| `kill_burst` | Coup en croix | `Player._on_slew()` : le physique tire le saignement (`rolled_by()`) |
| `status_chance_increase` | Coup en croix | le saignement est l'état tiré du physique (`ROLLED`) |
| `damage_vs_bleed` | Coup en croix | « contre les saignants » existe (`StatusEffects.AGAINST`) |
| `crit_chance` | Frappe lourde | la ligne d'Ardeur (feu) |
| `end_burst` | Ruée tranchante | `Player._dash()` le lit déjà à l'arrivée |
| `LEAP` | Ruée tranchante | le Bond de la Ruée ardente : la transformation et son dessin existent |
| `mana_per_second`, `period`, `recharge`, `use_time` | Cyclone, Ruée, Vague | lignes déjà visables (Sobriété, Pouls lent, Élan, Enchaînement) |
| `pull` | Cyclone | lu par `IceVortex` ; il suffit que `Cyclone._strike()` le lise |
| `ground_duration` | Vague | la Ruée tranchante a déjà un couloir physique (`DashTrail`) |

## 4. Ce qui est neuf

**a. La force du saignement** — `bleed_effect`, le mécanisme `State.strength` du jalon
38 étendu à un quatrième état : le saignement **saigne plus vite** (`per_second`), comme
la décomposition. Par `SkillStats.strength_of()`, donc lu sur la fiche (« saignant ·
×1.30 ») et dans la fenêtre Alt.

**b. Des nombres de `SkillStats`** :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `knockback` | recul ajouté au coup | `Player._on_hitbox_area_entered()`, en plus de `stats.knockback_force` ; le Brise-sol |
| `life_on_hit` | PV rendus par ennemi touché | le coup d'arme, par `Player` |
| `blade_ward` | dégâts subis retirés par épée en orbite | `Player.recompute_stats()`, relancé quand la couronne gagne ou perd une épée (comme `bone_wall`) |
| `radius` sur l'orbite | `BladeCrown.RADIUS` devient le rayon du lancer | `BladeCrown` ; `spiral_sword.tres` porte 26 |
| `sword_volley` | à la fin de leur durée, les épées partent chacune vers l'ennemi le plus proche et traversent | `BladeCrown` ; dessin : l'épée tournée existe (`Slash.sword()`) |
| `waves` | vagues en plus, en éventail | `Player` au lancer de `WAVE` — pas `projectiles`, la vague n'est pas un tir (`test_projectile_numbers_only_on_a_projectile`) |
| `mana_on_hit` | mana rendu par ennemi touché | `Cyclone._strike()`, par `Player.gain_mana()` |

**c. Deux formes neuves** :

- **Brise-sol** (Frappe lourde → `SLAM`) : la lame s'abat sur le sol devant soi et
  frappe **tout le cercle** autour du point d'impact, une fois, gel et secousse d'une
  frappe. **Dessin neuf** (planche).
- **Ressac** (Vague → `BOOMERANG`) : arrivée au bout de sa course, la vague revient vers
  le lanceur et mord **une seconde fois** au retour. Même dessin, le croissant retourné.

Plus le **Saut de guerre** (Ruée → `LEAP`, existant) et deux nœuds qui changent le jeu
sans être des formes (l'orbite et le cyclone tiennent un état chez le lanceur) : la
**Volée d'épées** et la **Fauche vorace**.

`IGNORED_BY_SHAPE` : `LEAP` ignore déjà durée et rayon (Andain, Lame traînante) ;
`BOOMERANG` ignore `ground_duration` s'il ne peut pas poser son sillon deux fois — à
trancher au moteur.

## 5. Les arbres — validés le 3 octobre, tels que livrés

Mêmes conventions qu'aux jalons 34 à 38 : chiffres de **premier réglage** ; « relié à
(n) » = points demandés dans le parent, un seul lien payé suffit ; ⇄ marque un échange.
**21 ou 22 points pour un pool de 20** dans chaque arbre.

### Frappe lourde — le fracas

| nœud | pts | effet | relié à |
|---|---|---|---|
| Élan *(gardé)* | 5 | +12 % dégâts plus | — |
| Pesée | 3 | +25 % chance critique de base accrue | — |
| Coup de bélier | 4 | repousse l'ennemi touché | — |
| Hargne | 4 | chaque ennemi touché rend 2 PV par point | Élan (1) |
| Lame ardente *(gardé)* | 1 | devient feu | Élan (1) |
| **Brise-sol** | 1 | **frappe le sol : tout le cercle de 28 px autour de l'impact** ⇄ −15 % dégâts plus | Élan (2) ou Coup de bélier (2) |
| Cratère | 3 | +20 % rayon (Brise-sol) | Brise-sol (1) |

### Coup en croix — la plaie

| nœud | pts | effet | relié à |
|---|---|---|---|
| Taille *(gardé)* | 5 | +12 % dégâts plus | — |
| Entaille | 3 | +15 % chance d'état (le saignement) | — |
| Estoc *(gardé)* | 3 | ajoute 2 à 6 dégâts physiques | Taille (1) |
| Plaie ouverte | 3 | +20 % dégâts accrus contre les saignants | Taille (1) |
| Hémorragie | 4 | +15 % effet du saignement | Entaille (1) |
| **Gerbe de sang** | 3 | **un saignant tué éclate, rayon 15 par point** | Hémorragie (2) |
| Lame sainte *(gardé)* | 1 | devient sacré — et ne fait plus saigner | Taille (2) |

Lame sainte reste ici malgré le reste de l'arbre : la prendre, c'est renoncer à la
plaie pour la bénédiction. Un vrai choix.

### Épée spirale — la garde

| nœud | pts | effet | relié à |
|---|---|---|---|
| Tranchant *(gardé)* | 5 | +12 % dégâts plus | — |
| Ronde *(gardé)* | 3 | +1 épée simultanée | — |
| Endurance *(gardé)* | 4 | +20 % durée | — |
| Bouclier de lames | 5 | −2 % dégâts subis par épée en orbite | Ronde (1) |
| Orbite large | 3 | +20 % rayon de l'orbite | Tranchant (1) |
| **Volée d'épées** | 1 | **à la fin de leur durée, les épées partent vers l'ennemi le plus proche et traversent** ⇄ −30 % durée | Tranchant (2) ou Bouclier de lames (2) |

### Vague tranchante — la portée

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fil de l'arc *(gardé)* | 5 | +12 % dégâts plus | — |
| Course *(gardé)* | 4 | +20 % durée (la portée) | — |
| Grand arc | 4 | +15 % rayon | — |
| Vagues jumelles | 3 | +1 vague par point, en éventail | Fil de l'arc (2) |
| Sillon d'acier | 4 | laisse un couloir tranchant derrière elle, 1 s par point | Course (1) |
| **Ressac** | 1 | **au bout de sa course, la vague revient et mord une seconde fois** ⇄ −20 % dégâts | Course (2) ou Vagues jumelles (1) |

### Cyclone — le tourbillon

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fauchage *(gardé)* | 5 | +10 % dégâts plus | — |
| Envergure *(gardé)* | 3 | +15 % rayon | — |
| Souffle long | 4 | −15 % mana drainé | — |
| Moulinet | 3 | −10 % intervalle des frappes | Fauchage (1) |
| Tourbillon | 3 | chaque frappe attire les ennemis vers vous | Envergure (1) |
| **Fauche vorace** | 3 | **chaque ennemi touché rend 0,4 mana par point** — un paquet entretient le tour | Souffle long (2) ou Moulinet (1) |

### Ruée tranchante — la charge

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fil tranchant *(gardé)* | 5 | +12 % dégâts plus | — |
| Andain *(gardé)* | 3 | +15 % rayon | — |
| Charge | 4 | −8 % recharge | Fil tranchant (1) |
| Lame traînante | 3 | +100 % durée du couloir : une frappe de plus par point | Andain (1) |
| Choc d'arrivée | 4 | à l'arrivée, frappe le cercle de 12 px par point | Andain (1) |
| Enchaînement *(gardé)* | 1 | −100 % recharge ⇄ +500 % temps du geste | Charge (2) |
| **Saut de guerre** | 1 | **un bond qui ne frappe qu'à l'arrivée, rayon 32** ⇄ +40 % temps du geste | Fil tranchant (2) ou Choc d'arrivée (1) |

## 5 bis. Ce que la livraison a changé à la proposition

Validée par l'utilisateur telle quelle (« oui, ça me va »), le chevalier dans
`UNIQUE_TREES` et retiré de `SHALLOW_TREES`. Ce qui a bougé en chemin :

- **Le temps du geste n'est qu'à la Ruée** : la règle refuse une même ligne dans deux
  arbres, et `use_time` servait au Brise-sol, à Revers et à Enchaînement. Le Brise-sol
  paie en **−15 % de dégâts plus** ; **Revers est retiré** (la vague n'a pas d'autre
  ligne de cadence possible — sa vitesse est une vitesse de projectile, refusée sur ce
  qui n'en est pas un) et ses trois points vont à Course (4) et Grand arc (4), Sillon
  d'acier passant à 4 points.
- **Lame traînante** : « +0,25 s » s'affichait « +0.3 durée ». Elle donne **+100 % de
  durée** par point — exactement une frappe de couloir de plus, le couloir de 0,25 s
  frappant une fois par 0,25 s.
- **Le rayon de l'orbite** sort de `BladeCrown.RADIUS` pour `spiral_sword.tres`
  (26) : chaque épée tourne au rayon de son lancer.
- **Un état, un nombre de force** : `SkillStats.EFFECT_OF`, une table, remplace le
  `match` de `strength_of()` ; `suffer()` reçoit le lancer au lieu de la seule force du
  transi.
- **Un bogue que le test a pris** : à l'expiration d'une épée, la fiche se refaisait
  avant que l'épée quitte la liste — le Bouclier de lames restait.

## 5 ter. Le dessin, les captures, les bancs

**Le Brise-sol, choisi sur planche** (`Bureau\hns-captures-brise-sol\`, six partis pris
en quatre temps) : « fissures » — cinq failles sombres et fourchues depuis un éclair au
cœur, qui se dissolvent —, contre un bourrelet de cailloux, une onde de choc en anneau,
une lame plantée sous des étincelles, des bouffées de poussière, et des fêlures sous un
anneau fin. Refaites avant de montrer la planche : les fissures sortaient en **araignée**
(sept pattes coudées, une lèvre claire doublant chaque trait) et les dalles soulevées en
**parapluie** posé au sol. `Slash.fissures()`, fabriquées au rayon : **0,47 ms** à 28 px,
0,65 à 45 (Cratère 3), 0,98 à 56 ; relues, 4 µs.

**Vu à la capture** (`Bureau\hns-captures-chevalier-jalon39\`, treize images, en ville) :
le sol se fend devant le joueur, dans la visée ; les Vagues jumelles partent en éventail ;
le Ressac part, puis revient retourné vers le joueur (11 à 13) ; la Volée d'épées, le Saut
de guerre (son arc et son explosion) et le Tourbillon tiennent. **La capture a montré que
le Ressac ne revenait pas** : le nœud n'avait pas sa forme dans le `.tres` — le test de
forme passe par un nœud d'essai. `test_the_knight_transformations_carry_their_shapes`
tient désormais les trois formes sur les vrais nœuds.

**Le banc des arbres** (`docs/ARBRES.md`, le chevalier mesuré pour la première fois).
Hors des critères du jalon 37 :

| | paquet | duel | |
|---|---|---|---|
| Brise-sol | ×1,89 | ×0,73 | trop fort au paquet : il frappe tout un cercle, la Frappe lourde un arc |
| Ressac | ×1,37 | ×1,33 | la seconde morsure vaut plus que les 20 % qu'elle coûte |
| Saut de guerre | ×0,52 | ×0,24 | le bond perd le couloir, que Lame traînante fait frapper quatre fois |
| Lame ardente (conversion) | ×1,32 | ×1,26 | l'embrasement brûle plus que le saignement |

Lame sainte reste neutre (×0,89 · ×0,96). Jamais pris, faute d'être vus par le banc :
Coup de bélier et Hargne (recul, survie), Endurance, Bouclier de lames et Orbite large
(l'orbite ne mord que ce qui passe), Souffle long et Fauche vorace (la réserve du banc
suffit au cyclone), Enchaînement.

**Le banc de combat** (300 ennemis, la case lancée sans relâche, 240 images de chauffe
puis 1 440, cinq passes alternées) : Coup en croix nu 6,07 ms contre 4,71 avec Taille,
Entaille, Hémorragie et Gerbe de sang ; Vague nue 6,07 contre 5,76 avec Vagues jumelles 3,
Course et Ressac ; Épée spirale nue 6,15 contre 5,40 avec Volée et Ronde 3 — les nœuds
tuent plus vite, il reste moins à simuler. **165 img/s partout, au plus 7,5 % du temps
figé** (le Coup en croix nu ; 0 à 1 % sous la Vague et l'épée, qui ne gèlent pas).

**Relevé d'équilibrage** (`tests/run.sh balance`) : 4 couloirs sur 5 en échec **avant
comme après**, mêmes verdicts. Le profil « Mêlée » du jalon 13 prend Élan jusqu'au bout,
qui passe de 3 × 14 % à 5 × 12 % : il tue en 12 % de coups de moins en profondeur (Nu, zone
120 : 79,4 → 68,2), un peu moins vite au premier niveau du livre (un point de 12 %).

## 5 quater. Après la livraison — demandé par l'utilisateur le 3 octobre

- **Arsenal** (Épée spirale, 3 points, relié à Ronde (1)) : chaque lancer fait naître une
  épée de plus par point, d'un coup — `extra_swords`, dans la limite de la ronde
  (`max_simultaneous`), sans quoi Ronde ne servirait plus. L'arbre passe à 24 points. Au
  banc, Arsenal entre dans le meilleur build au duel : ×4,55 → **×5,28**.
- **Le Ressac pose son sillon au retour aussi** : chaque passage de la vague en est un,
  avec son Sillon d'acier. Les deux sillons d'une même vague ne cumulent pas sur une
  cible (jalon 37) : le retour ne frappe en plus que là où il passe ailleurs que l'aller.
- **Un lien se prend dans les deux sens** : le Ressac, ouvert par la Course, n'ouvrait pas
  les Vagues jumelles auxquelles il est relié — il fallait « faire le tour » par Fil de
  l'arc. La règle change pour **tous les manuels** : un nœud s'ouvre par un parent à ses
  points, ou par un enfant à un point. Les nœuds tenus se comptent depuis la compétence,
  de proche en proche, pour que deux nœuds ne se tiennent pas l'un l'autre
  (`test_a_link_is_taken_both_ways_without_holding_itself`). La fiche d'un nœud fermé
  propose aussi ses enfants sous « ou » ; un lien s'allume dès que ses deux bouts portent
  un point.

## 6. Le déroulé

**Fait** : 1 à 5. **Reste** : le réglage des quatre hors critères (§5 ter) au banc des
arbres, quand l'utilisateur le demandera, comme au jalon 38.

1. **Ce document**, et la validation du §5 par l'utilisateur.
2. **Le moteur** : la force du saignement (§4a), les nombres (§4b), `SLAM` et
   `BOOMERANG` — chacun avec son test de forme ; le chevalier dans `UNIQUE_TREES`.
3. **Les arbres** dans `weapons.tres`, descriptions comprises (relues contre le code).
4. **Le Brise-sol** sur planche (`/dessiner-un-effet`) ; capture fenêtrée du Ressac, de
   la Volée d'épées, du Saut de guerre et du Tourbillon.
5. **`/valider`** : la campagne ; le banc de combat (Gerbe de sang, Vagues jumelles et
   Volée multiplient les coups) ; `tools/catalog.sh` ; `tools/balance.sh trees` avec le
   chevalier dans `TREE_MANUALS` ; `tests/run.sh balance` relevé, sans correction.
   ARCHITECTURE et RECETTES dans le même geste.
