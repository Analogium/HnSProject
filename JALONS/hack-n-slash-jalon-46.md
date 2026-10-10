# Hack'n'slash top-down — jalon 46

Suite des jalons 1 à 45. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 10 octobre 2026.** Les arbres du **manuel du chevalier** repris comme ceux des
flammes (jalon 42), de la foudre (jalon 43), du froid (jalon 44) et de la nécromancie
(jalon 45).

---

## 1. Ce que l'utilisateur a demandé

« Comme pour les jalons précédents avec les manuels, j'aimerais attaquer maintenant le
manuel du chevalier. » Les demandes du jalon 42, §1, valent telles quelles : un peu plus de
nœuds, aucun nœud qui revient d'un arbre à l'autre, des nœuds originaux par compétence, des
**suites** derrière ce qui change le jeu, quelques interactions, quelques leviers simples —
et une vignette par nœud (jalon 42, §14), arbre par arbre.

## 2. La règle du jalon

Celle du jalon 42, §2, devenue celle de tous les arbres au jalon 44 : **aucun nom ni aucune
ligne** ne revient d'un arbre à l'autre, sauf un nœud de dégâts, de rayon et de durée par
arbre, et les échanges entiers. Une suite n'a qu'un parent, et ne lit que des nombres que ce
parent fait servir. Un nom ne double pas un autre manuel.

Le chevalier respecte la première moitié depuis le jalon 39. Ce qui lui manque : **six ou
sept nœuds par arbre, 21 ou 22 points**, une seule suite (le Cratère), et la moitié de ses
nœuds sont des leviers chiffrés.

**Cible** : celle du froid et de la nécrose — 13 à 21 nœuds par arbre, 30 à 40 points pour
un pool de 20, deux à quatre nœuds que seule la compétence a, une à deux suites par nœud qui
change le jeu. Six arbres : une interaction dans deux au plus, à l'intérieur du manuel.
**Garde de fer** reste un passif, sans arbre.

**L'identité**, celle du jalon 39, §2 : ce qui **pèse** (l'impact, le recul), ce qui
**ouvre** (le saignement), ce qui **garde** (les lames autour de soi, la vie reprise) et ce
qui **porte** (la vague, la charge). Pas de froid ni de contrôle durable, pas d'invocation.
Ce que la reprise ajoute : le **rythme** — le coup qui tombe à son temps, le tour qui
s'emballe, la ruée qui se relance.

Inspirations relevées : dans PoE, le *Ruthless* (un coup sur trois écrase), l'*Exsanguinate*
qui vide le saignement, le *Sunder* et ses ondes, l'*Earthquake*, le *Blade Vortex*, le
*Shield Charge* ; dans Diablo IV, les *Dust Devils* du tourbillon, le *Vulnerable*, le
*Death Blow* qui se relance sur un tué ; dans Last Epoch, le *Rive* en trois temps et la
*Ring of Shields* ; dans Diablo II, le *Leap Attack* qui assomme ; dans Hero Siege, la ruée
du samouraï qui se recharge sur un tué ; l'escrime pour les noms du Coup en croix.

## 3. Le manuel du chevalier — la proposition

### Noms pris ailleurs

| nom | pris par | devient |
|---|---|---|
| Élan | Ruée ardente (flammes, jalon 42) | **Fracas** |

L'identifiant reste (`heavy_strike_momentum`) : il est dans les sauvegardes (invariant 1).

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Frappe lourde — le fracas *(7 → 14 nœuds, 33 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Fracas** *(l'Élan)* | 5 | +12 % dégâts plus | — |
| Pesée *(gardé)* | 3 | +25 % chance critique accrue | — |
| Coup de bélier *(gardé)* | 4 | repousse l'ennemi touché | — |
| Hargne *(gardé)* | 4 | chaque ennemi touché rend 2 PV par point | Fracas (1) |
| Lame ardente *(gardé)* | 1 | devient feu | Fracas (1) |
| Brise-sol *(gardé)* | 1 | transformation : tout le cercle autour de l'impact ⇄ −15 % dégâts plus | Fracas (2) ou Coup de bélier (2) |
| ↳ Cratère *(gardé)* | 3 | +20 % rayon du Brise-sol | Brise-sol (1) |
| **Coup sûr** *(neuf)* | 1 | **une Frappe lourde sur trois est critique à coup sûr**, et son gel d'impact dure le double — le *Ruthless* | Pesée (2) |
| **Brèche** *(neuf)* | 3 | **l'armure cède** : un ennemi frappé subit 6 % par point de dégâts en plus de vos coups d'arme pendant 3 s — le *Vulnerable* | Fracas (2) |
| **Collision** *(neuf)* | 2 | **un repoussé qui heurte un autre ennemi** leur inflige à tous deux 25 % du coup par point | Coup de bélier (1) |
| ↳ **Coup de massue** *(neuf)* | 1 | le coup sûr frappe aussi tout le cercle de 30 px autour de sa cible, à 50 % | Coup sûr (1) |
| ↳ **Quilles** *(neuf)* | 1 | l'ennemi heurté par une Collision **est repoussé à son tour**, une fois | Collision (1) |
| ↳ **Tremblement** *(neuf)* | 2 | le Brise-sol frappe un second anneau, au double de son rayon, 0,3 s plus tard, à 25 % du coup par point — le *Sunder* | Brise-sol (1) |
| ↳ **Fer rouge** *(neuf)* | 2 | la Lame ardente sur un embrasé **prolonge son embrasement** de 1 s par point | Lame ardente (1) |

### Coup en croix — la plaie *(7 → 15 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Taille *(gardé)* | 5 | +12 % dégâts plus | — |
| Entaille *(gardé)* | 3 | +15 % chance de faire saigner | — |
| Estoc *(gardé)* | 3 | ajoute 2 à 6 dégâts physiques | Taille (1) |
| Plaie ouverte *(gardé)* | 3 | +20 % accrus contre les saignants | Taille (1) |
| Hémorragie *(gardé)* | 4 | +15 % effet du saignement | Entaille (1) |
| Gerbe de sang *(gardé)* | 3 | un saignant tué éclate | Hémorragie (2) |
| Lame sainte *(gardé)* | 1 | devient sacré — et ne fait plus saigner | Taille (2) |
| **Lacération** *(neuf)* | 2 | chaque croix sur un saignant **prolonge son saignement** de 1 s par point | Entaille (1) |
| **Riposte** *(neuf)* | 3 | **un coup reçu arme la riposte** : le Coup en croix suivant, dans les 2 s, frappe 20 % plus fort par point | Taille (1) |
| **Tierce** *(neuf)* | 1 | **la croix a un troisième temps** : un estoc droit devant, 0,12 s après le second coup, à 60 % — le *Rive* | Estoc (2) |
| **Saignée** *(neuf)* | 2 | **le second coup vide le saignement** : ce qui restait à saigner tombe d'un coup, 20 % plus fort par point — l'*Exsanguinate* | Hémorragie (1) |
| ↳ **Quarte** *(neuf)* | 1 | la Tierce **traverse** : l'estoc frappe tout ce qui est sur sa ligne, 60 px derrière la cible | Tierce (1) |
| ↳ **Transfusion** *(neuf)* | 2 | ce que vide la Saignée vous rend 5 % de ses dégâts en PV par point | Saignée (1) |
| ↳ **Éclaboussure** *(neuf)* | 1 | ce que touche la Gerbe de sang **saigne à coup sûr** | Gerbe de sang (1) |
| ↳ **Ordalie** *(neuf)* | 1 | sous la Lame sainte, le second coup **bénit à coup sûr** | Lame sainte (1) |

La Saignée n'est pas la Saignée du jalon 39, retirée : celle-ci tient la promesse du nom.
Sous la Lame sainte, la Lacération, la Saignée et ses suites ne servent plus
(`IGNORED_BY_MECHANIC`), comme l'Hémorragie aujourd'hui — et ne s'ouvrent pas par elle.

### Épée spirale — la garde *(7 → 14 nœuds, 38 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Tranchant *(gardé)* | 5 | +12 % dégâts plus | — |
| Ronde *(gardé)* | 3 | +1 épée simultanée | — |
| Endurance *(gardé)* | 4 | +20 % durée | — |
| Bouclier de lames *(gardé)* | 5 | −2 % dégâts subis par épée | Ronde (1) |
| Orbite large *(gardé)* | 3 | +20 % rayon de l'orbite | Tranchant (1) |
| Arsenal *(gardé)* | 3 | une épée de plus par lancer | Ronde (1) |
| Volée d'épées *(gardé)* | 1 | à la fin, les épées partent vers l'ennemi le plus proche ⇄ −30 % durée | Tranchant (2) ou Bouclier de lames (2) |
| **Valse** *(neuf)* | 3 | les épées tournent 15 % plus vite par point — elles croisent plus de monde | — |
| **Affûtage** *(neuf)* | 3 | chaque ennemi qu'une épée coupe **l'affûte** : +4 % de dégâts plus par point, 5 fois au plus, tant qu'elle vit | Tranchant (1) |
| **Parade** *(neuf)* | 2 | **une épée qui croise un projectile ennemi le brise**, une fois par épée et par 2 s, moins 0,5 s par point | Orbite large (1) |
| **Brise-lames** *(neuf)* | 1 | **un coup qui vous touche brise une épée à sa place** : il ne fait rien, une fois toutes les 3 s — la *Ring of Shields* | Bouclier de lames (2) |
| **Escorte** 🔗 *(neuf)* | 2 | **chaque Frappe lourde ou Coup en croix envoie une épée** de la ronde frapper sa cible et revenir, à 25 % du coup par point | Ronde (2) |
| ↳ **Grenaille** *(neuf)* | 2 | l'épée brisée par le Brise-lames **éclate** autour de vous, 40 % du coup par point | Brise-lames (1) |
| ↳ **Ralliement** *(neuf)* | 1 | les épées de la Volée **reviennent** une fois dans la ronde, pour 2 s | Volée d'épées (1) |

### Vague tranchante — la portée *(6 → 13 nœuds, 36 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fil de l'arc *(gardé)* | 5 | +12 % dégâts plus | — |
| Course *(gardé)* | 4 | +20 % durée (la portée) | — |
| Grand arc *(gardé)* | 4 | +15 % rayon | — |
| Vagues jumelles *(gardé)* | 3 | +1 vague par point, en éventail | Fil de l'arc (2) |
| Sillon d'acier *(gardé)* | 4 | laisse un couloir tranchant derrière elle | Course (1) |
| Ressac *(gardé)* | 1 | transformation : la vague revient et mord une seconde fois ⇄ −20 % dégâts | Course (2) ou Vagues jumelles (1) |
| **Retenue** *(neuf)* | 3 | −10 % coût en mana par point | — |
| **Houle** *(neuf)* | 3 | **la vague grossit en volant** : jusqu'à 25 % de rayon et de dégâts en plus par point au bout de sa course | Grand arc (1) |
| **Proue** *(neuf)* | 3 | le premier ennemi mordu prend 20 % de plus par point | Fil de l'arc (1) |
| **Lame de fond** *(neuf)* | 1 | **la vague emporte ce qu'elle mord** : les ennemis sont traînés avec elle jusqu'au bout de sa course | Course (2) ou Houle (1) |
| ↳ **Brisants** *(neuf)* | 2 | au bout de sa course, la Lame de fond **jette ce qu'elle porte** : chacun prend 30 % du coup par point | Lame de fond (1) |
| ↳ **Va-et-vient** *(neuf)* | 1 | le Ressac **repart une troisième fois** vers la visée, à 50 % | Ressac (1) |
| ↳ **Herse** *(neuf)* | 2 | ce qui se tient dans le Sillon d'acier **saigne** : 15 % de chance par point à chaque frappe du sillon | Sillon d'acier (1) |

La Lame de fond et le Ressac s'excluent : une vague qui rapporte ce qu'elle emporte rendrait
les ennemis au joueur. Pas de chemin de l'un à l'autre ; `IGNORED_BY_SHAPE`.

### Cyclone — le tourbillon *(6 → 14 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fauchage *(gardé)* | 5 | +10 % dégâts plus | — |
| Envergure *(gardé)* | 3 | +15 % rayon | — |
| Souffle long *(gardé)* | 4 | −15 % mana drainé | — |
| Moulinet *(gardé)* | 3 | −10 % intervalle des frappes | Fauchage (1) |
| Tourbillon *(gardé)* | 3 | chaque frappe attire les ennemis | Envergure (1) |
| Fauche vorace *(gardé)* | 3 | chaque ennemi touché rend du mana | Souffle long (2) ou Moulinet (1) |
| **Pied ferme** *(neuf)* | 3 | −5 % dégâts subis par point en tournant ⇄ −10 % vitesse de déplacement par point | Souffle long (1) |
| **Vertige** *(neuf)* | 3 | **le tour s'emballe** : chaque seconde tournée raccourcit l'intervalle de 4 % par point, 3 s au plus | Moulinet (1) |
| **Derviches** *(neuf)* | 1 | **le tour lâche des tourbillons** : toutes les 1,5 s, un petit derviche part droit devant vous et fauche ce qu'il croise, à 40 % — les *Dust Devils* | Envergure (2) ou Fauchage (2) |
| **Dénouement** *(neuf)* | 1 | **l'arrêt frappe** : relâcher le tour lâche une dernière frappe, 20 % plus forte par seconde tournée, 5 s au plus | Fauchage (2) |
| **Ronde folle** 🔗 *(neuf)* | 2 | tant que le Cyclone tourne, **les épées de l'Épée spirale tournent deux fois plus vite** et frappent 15 % plus fort par point | Moulinet (2) |
| ↳ **Sirocco** *(neuf)* | 2 | un derviche de plus par point, en éventail | Derviches (1) |
| ↳ **Trombe** *(neuf)* | 1 | les derviches **cherchent** l'ennemi le plus proche | Derviches (1) |
| ↳ **Coup de vent** *(neuf)* | 1 | le Dénouement **repousse** loin tout ce qu'il touche | Dénouement (1) |

### Ruée tranchante — la charge *(7 → 14 nœuds, 32 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fil tranchant *(gardé)* | 5 | +12 % dégâts plus | — |
| Andain *(gardé)* | 3 | +15 % rayon | — |
| Charge *(gardé)* | 4 | −8 % recharge | Fil tranchant (1) |
| Lame traînante *(gardé)* | 3 | +100 % durée du couloir | Andain (1) |
| Choc d'arrivée *(gardé)* | 4 | à l'arrivée, frappe le cercle autour de vous | Andain (1) |
| Enchaînement *(gardé)* | 1 | −100 % recharge ⇄ +500 % temps du geste | Charge (2) |
| Saut de guerre *(gardé)* | 1 | transformation : un bond qui ne frappe qu'à l'arrivée ⇄ +40 % temps du geste | Fil tranchant (2) ou Choc d'arrivée (1) |
| **Voltige** *(neuf)* | 1 | pendant la ruée, **aucun coup ne vous touche** | — |
| **Coupe-jarret** *(neuf)* | 2 | le couloir fait saigner : 20 % de chance par point | Fil tranchant (1) |
| **Relance** *(neuf)* | 1 | **un ennemi tué par la ruée la recharge sur-le-champ** — le *Death Blow* | Charge (1) |
| ↳ **Hallali** *(neuf)* | 2 | chaque Relance fait frapper la ruée suivante 15 % plus fort par point, 3 fois au plus | Relance (1) |
| ↳ **Trouée** *(neuf)* | 2 | chaque ennemi traversé ajoute 10 % par point au Choc d'arrivée | Choc d'arrivée (1) |
| ↳ **Retombée** *(neuf)* | 1 | la réception du Saut de guerre **assomme** : les ennemis touchés ne frappent plus pendant 0,8 s — le *Leap Attack* | Saut de guerre (1) |
| ↳ **Pas chassé** *(neuf)* | 2 | sous l'Enchaînement, une ruée qui en suit une autre de moins d'1 s frappe 10 % plus fort par point, 3 fois au plus | Enchaînement (1) |

La Relance n'a pas de sens sous l'Enchaînement, qui n'a plus de recharge : pas de chemin de
l'un à l'autre, `IGNORED_BY_MECHANIC`. Le Coupe-jarret est sans effet avec le Saut de guerre,
qui n'a pas de couloir (`IGNORED_BY_SHAPE`).

### Récapitulatif

- **40 → 84 nœuds**, dont **21 suites** (le Cratère compris) ; une quarantaine de nombres neufs dans `SkillStats`.
  Deux arbres sur six ont une interaction, toutes deux **à l'intérieur du manuel** et toutes
  deux vers l'Épée spirale : l'Escorte (depuis les coups d'arme) et la Ronde folle (depuis
  le Cyclone). La garde devient ce qui relie le chevalier.
- **Chaque arbre a son rôle** : la Frappe lourde le coup qui tombe à son temps, le Coup en
  croix la plaie qu'on ouvre puis qu'on vide, l'Épée spirale ce qui garde, la Vague ce qui
  emporte, le Cyclone le tour qui s'emballe, la Ruée la charge qui se relance.
- **Ce qui se réutilise** : le compteur de lancers du Plein régime (Coup sûr) ;
  `Game.hit_stop()` (Coup sûr) ; `Explosion.put()` (Coup de massue, Grenaille, Dénouement) ;
  `StatusEffects.extend()` (Fer rouge, Lacération) ; `SURE_STATE` (Éclaboussure, Ordalie) ;
  `seek` (Trombe) ; le recul du Coup de bélier (Collision, Quilles, Coup de vent) ; le signal
  `slew` (Relance) ; le buff à charges de la Soif de sang (Riposte, Hallali, Pas chassé) ;
  `BladeCrown` (Valse, Affûtage, Parade, Brise-lames, Escorte, Ronde folle, Ralliement).
- **Le neuf qui touche aux ennemis** : la **Brèche** (une marque que porte l'ennemi, à lire
  sur lui), la **Collision** (un repoussé qui en heurte un autre), la **Lame de fond** (des
  ennemis traînés), la **Retombée** (un ennemi assommé), la **Parade** (des projectiles
  ennemis brisés).
- **Dessin** (`/dessiner-un-effet`) : le derviche, l'estoc de la Tierce, l'éclat de la
  Grenaille, l'assommé de la Retombée, la marque de la Brèche. Les vignettes des 84 nœuds
  passent par `tools/node_icons.py` (jalon 42, §14) — la palette du chevalier est à créer.
- **Ce qui se multiplie** : les Derviches et le Sirocco, la Tierce, l'Escorte, les Quilles
  (bornées : une fois), le Va-et-vient. À remesurer sur `world/stress_test.tscn`.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes : Frappe lourde,
  Coup en croix, Épée spirale, Vague, Cyclone, Ruée. `docs/ARBRES.md` se régénère ; les
  couloirs d'équilibrage se relèvent avant → après, sans les corriger (jalon 13, §7).

### Les questions

1. **Assommer** (la Retombée) est un contrôle neuf : aucun ennemi ne s'arrête aujourd'hui,
   hormis le chargeur qui s'étourdit lui-même. Proposé : **0,8 s, les élites à moitié, les
   boss jamais** — ou pas d'assommé du tout, et la Retombée devient un second choc.
2. **La Brèche** : un état neuf, qui se lit sur l'ennemi et dans la fenêtre Alt comme les
   autres (« fêlé »), ou une marque silencieuse ? Proposé : **un état**, `Kind.BREACH` — ce
   qu'un nœud change doit se lire.
3. **Le renommage** — Élan → Fracas : d'accord ?
4. **La Parade** ne brise que les traits du lanceur (`enemy_bolt`) ; les obus du mortier
   tombent du ciel et passent au-dessus des lames. D'accord ?

## 4. Les réponses

L'utilisateur, sur la proposition : « ok va pour ça, j'accepte, j'accepte, d'accord ».

- **la Retombée assomme** : 0,8 s, la moitié sur une élite, jamais sur un boss ;
- **la Brèche est un état**, « fêlé », qui se lit sur l'ennemi et dans la fenêtre Alt ;
- **le renommage** : Élan → Fracas. L'identifiant reste (`heavy_strike_momentum`) ;
- **la Parade** ne brise que les traits du lanceur, pas les obus du mortier.

Livraison arbre par arbre, en commençant par la Frappe lourde.

## 5. La Frappe lourde — livrée

Les quatorze nœuds du §3, sept neufs. L'Élan devient **Fracas** ; les identifiants gardés ne
changent pas.

### Ce qui est neuf au moteur

- **L'état fêlé** (`StatusEffects.Kind.BREACH`, physique, 3 s), posé sans tirage par la
  Brèche, comme la Surchauffe, à `strength_of()` : 1 + la Brèche. Sa force **multiplie tout
  coup qui porte le mot-clé attaque** (`SkillStats.against_factor()`), d'où qu'il vienne : la
  Brèche de la Frappe lourde sert au Coup en croix, à la Vague, au Cyclone. Lu dans la fenêtre
  Alt (« fêlé · 100 % », « force du fêlé ×1,18 ») et au guide. Son icône, un écu fendu, est
  **provisoire** jusqu'à sa planche.
- **La Collision** passe par l'`EnemyManager`, le seul pilote des ennemis : le coup arme le
  repoussé (`Enemy.shove()`, `COLLISION_WINDOW`), et après son tick, `Enemy.collide()` lit ce
  que `move_and_slide()` vient de heurter. Seul compte un voisin **devant lui dans le sens du
  recul** : dans un paquet, chacun touche déjà ses voisins. Les deux prennent le même tirage
  (`SkillStats.collided()`). Sous les Quilles, le heurté part avec le recul du coup et peut en
  heurter un troisième, sans le pousser.
- **Le Coup sûr** compte ses lancers comme le Glacier (`Player._sure`) ; le lancer qui tombe
  juste porte `is_sure`, que lisent le gel (`_stop_of()`, `SURE_STOP`) et le Coup de massue.
- **Le Tremblement** frappe l'anneau entre le rayon du Brise-sol et son double,
  `TREMOR_GAP` après, avec les fissures du Brise-sol à sa taille.
- **Le Fer rouge** rend du temps à l'embrasement **avant** que le coup ne tire le sien
  (`Hurtbox`) : un embrasement neuf n'est pas allongé.

### Les écarts avec la proposition

- **Le Fer rouge** rend du temps jusqu'à la pleine durée de l'embrasement, et pas au-delà —
  la règle de `StatusEffects.extend()`, celle de la Morsure nécrosante.
- **Le Coup de massue** est sans effet avec le Brise-sol, qui frappe déjà tout le cercle
  (`IGNORED_BY_SHAPE`) ; il ne s'ouvre que par le Coup sûr.

### Les tests

Six tests, « Frappe lourde (jalon 46) » dans `test_shapes.gd` : le Coup sûr au troisième et
au sixième lancer, le Coup de massue hors de portée de l'arme, la Brèche à sa force — un autre
coup d'arme y gagne, un sort non —, le Fer rouge, l'anneau du Tremblement, et la Collision
avec les Quilles sur **trois vrais grunts menés par leur `EnemyManager`** (frappé puis heurtant,
heurté puis heurtant, heurté). La campagne : **1 393 tests, tous verts**, les fuites de fin
de campagne celles du jalon 45 (15 `CanvasItem`, 30 instances).

### Le banc

Relevé sans correction (jalon 13, §7), `tools/balance.sh trees only=heavy_strike`.

| | avant | après |
|---|---|---|
| paquet | ×4,77 (Brise-sol, Cratère, Pesée) | **×9,96** (Brise-sol, Tremblement, Lame ardente, Fer rouge, Coup sûr, Brèche) |
| duel | ×1,89 (Élan seul) | **×3,87** (Pesée, Coup sûr, Brèche, Lame ardente, Fer rouge) |

La Brèche paie à la Frappe elle-même : le fêlé prend tout coup d'arme, le sien compris. Le
Tremblement remplace le Cratère dans le meilleur Brise-sol. À reprendre à l'équilibrage. Jamais
pris — le banc ne voit ni le recul ni les heurts, et ses cibles sont seules : Coup de bélier,
Hargne, Cratère, Coup de massue, Collision, Quilles.

### La performance

L'`EnemyManager` demande à chaque ennemi s'il est repoussé (`Enemy.shoved()`). Banc
`world/stress_test.tscn`, 300 ennemis, combat tenu, 240 images de chauffe puis 1 440, six
paires **dans un ordre alterné** : **5,45 contre 5,58 ms** de physique en moyenne, pour un
écart de 0,6 ms d'un tir à l'autre — dans le bruit ; 165 img/s des deux côtés. Une première
série sans alterner l'ordre donnait l'« après » plus haut à chaque paire (5,14 contre 5,90) :
c'était la place dans la série, pas le code.


## 6. Les cinq autres arbres — livrés

« Fais tous les arbres » : Coup en croix, Épée spirale, Vague tranchante, Cyclone et Ruée
tranchante d'un tenant, les nœuds du §3. Le manuel compte **84 nœuds**.

### Ce qui est neuf au moteur

- **Coup en croix.** La **Tierce** est un estoc à part (`Player._thrust()`), `TIERCE_GAP` après
  la croix : une capsule devant soi (`Targets.in_capsule()`), le plus proche, ou toute la ligne
  sous la **Quarte** ; dessinée par la trace de la frappe vive (`LungeTrail`), en attendant sa
  planche. La **Saignée** lit le second coup (`_hit_index`) : `StatusEffects.drain()` ôte le
  saignement et rend ce qu'il restait à brûler, qui frappe d'un coup, sans critique
  (`SkillStats.bled()`) ; la **Transfusion** en rend une part. La **Riposte** s'arme dans
  `Player._on_damaged()`. L'**Ordalie** passe `SURE_STATE` au second coup. L'**Éclaboussure**
  est la Poudrière des flammes (`powder_keg`) : le même nombre, dans un autre manuel.
- **Épée spirale.** La couronne lit tout : la **Valse** (la plus rapide mène la ronde),
  l'**Affûtage** (`Blade.honed`), la **Parade** (`Targets.bolts_in_circle()`, le calque des
  traits ennemis), le **Brise-lames** (`take_blow()`, en tête de `Player._on_damaged()` : le
  coup ne fait rien) et la **Grenaille**, l'**Escorte** (une `FlyingSword` sur la cible, depuis
  le premier coup d'une Frappe lourde ou d'un Coup en croix), le **Ralliement**
  (`FlyingSword.home`). La **Ronde folle** vient du Cyclone (`Player.spin_madness()`).
- **Vague.** La **Houle** (`_grown()`, que lisent la frappe et le dessin, par pas de deux
  pixels pour que chaque taille ne se fabrique qu'une fois), la **Proue**, la **Lame de fond**
  (les mordus avancent par `move_and_collide()`, murs compris) et les **Brisants**, le
  **Va-et-vient** (un troisième passage), la **Herse** (le sol du sillon prend son accru).
- **Cyclone.** Le **Vertige**, les **Derviches** (une classe neuve, `Dervish` : le dessin du
  cyclone en petit, provisoire), le **Sirocco**, la **Trombe**, le **Dénouement** et le **Coup de
  vent** (`Cyclone.extinguish()`), la **Ronde folle**.
- **Ruée.** La **Voltige** partage l'invulnérabilité de la Cage de Faraday
  (`Player._untouchable()`, qui ne se pose jamais par-dessus une autre), le **Coupe-jarret**,
  la **Relance** et l'**Hallali** (`_on_slew()` → `_relaunch()`), la **Trouée** (le trajet compté
  avant le choc), la **Retombée** (`Enemy.stun()` : `hold()`, comme l'Étau ; la moitié sur une
  élite — le jeu n'a pas de boss), le **Pas chassé**.

### Les écarts avec la proposition

- **Le Pied ferme** est fait de deux **lignes de buff** (dégâts subis, vitesse) : un geste
  entretenu allumé verse les lignes de ses nœuds comme un buff (`Player.buff_mods()`).
  `test_each_node_line_targets_a_cast_number` l'admet désormais pour les formes de
  `Skill.SUSTAINED_SHAPES`.
- **La Voltige** : la ruée est instantanée, il n'y a pas de « pendant ». Elle protège
  **à l'arrivée**, `VAULT_TIME`.
- **La Herse et le Coupe-jarret** accroissent la chance de faire saigner (+50 % par point)
  plutôt qu'une chance fixe : c'est la règle de toutes les chances d'état (`factor_of()`).
- **La Parade** attend `PARRY_WAIT` divisé par ses points, plutôt que 2 s moins 0,5 par point.
- **L'Escorte** envoie le double d'une épée sur la cible ; l'épée continue de tourner.
- **Libellés raccourcis** : trois débordaient de la fiche du nœud
  (`test_passive_and_node_sheets_fit_in_both_languages`).

### Les tests

Vingt-six tests de plus, par arbre (« Coup en croix (jalon 46) » et suivants,
`test_shapes.gd`). Deux pièges vus en route : la Vague lance aussi un coup d'arme, dont la
hitbox frappait la première cible des tests ; et **`test_an_icebreaker_burst_pays_for_the_time_left`
(jalon 44) était instable** — il mettait la chance critique de la fiche à zéro, mais allumer le
Tombeau refait la fiche : un critique à 5 % doublait le coup, sur HEAD comme ici. Le test
ramène désormais un critique à sa base ; la valeur attendue ne change pas.

La campagne : **1 419 tests, tous verts**. Captures des six arbres en jeu : `Bureau\hns-captures-arbres-chevalier\`.

### Le banc

Relevé sans correction (jalon 13, §7), `tools/balance.sh trees only=…` arbre par arbre. La
Frappe lourde, au §5.

| arbre | | avant | après |
|---|---|---|---|
| Coup en croix | paquet | ×8,16 | **×12,8** (Lame sainte, Ordalie, Tierce, Quarte) |
| | duel | ×5,56 | ×7,38 (Lame sainte, Tierce, Ordalie, Saignée) |
| Épée spirale | paquet | ×4,98 | **×12,7** (Affûtage, Valse) |
| | duel | ×5,28 | ×8,25 |
| Vague | paquet | ×11,0 (Ressac) | **×21,8** (Ressac, Va-et-vient, Houle) |
| | duel | ×6,37 | **×11,8** (Proue, Va-et-vient, Houle) |
| Cyclone | paquet | ×3,10 | ×5,97 (Derviches, Trombe, Sirocco, Vertige) |
| | duel | ×2,69 | ×3,94 (Vertige, Derviches) |
| Ruée | paquet | ×7,47 | **×58,1** (Relance, Hallali, Trouée, Enchaînement, Pas chassé) |
| | duel | ×13,4 | ×14,2 (Trouée) |

**La Ruée au paquet est hors d'échelle** : le banc la relance sans relâche sur neuf grunts qui
renaissent, et la Relance la rend à chaque tué — sous l'Enchaînement, le geste seul la borne.
En jeu, il faut traverser le paquet pour tuer. La Vague double par son troisième passage. À
reprendre à l'équilibrage, en premier ces deux-là. Jamais pris — le banc ne voit ni les coups
reçus, ni les traits ennemis, ni le recul, ni le saignement qu'on accroît : Riposte,
Transfusion, Éclaboussure ; Bouclier de lames, Parade, Brise-lames, Grenaille, Escorte,
Ralliement ; Sillon d'acier, Retenue, Lame de fond, Brisants, Herse ; Souffle long,
Tourbillon, Fauche vorace, Pied ferme, Dénouement, Coup de vent, Ronde folle ; Voltige,
Coupe-jarret, Retombée.

### La performance

Banc `world/stress_test.tscn`, 300 ennemis, combat tenu, 240 images de chauffe puis 1 440,
quatorze paires dans un ordre alterné : **5,10 contre 5,31 ms** de physique en moyenne (une
première série de six donnait 4,72 contre 5,44, la seconde de huit 5,38 contre 5,22 : l'écart
change de sens, il est dans le bruit) ; 165 img/s des deux côtés. Ce qui se multiplie —
Derviches et Sirocco, Escorte, Tierce, Quilles, Va-et-vient — n'a pas été mesuré à part.

### Ce qui reste au jalon

- ~~**les planches**~~ — faites, §7 ;
- **les vignettes** des 84 nœuds et des six icônes de compétence (jalon 42, §14), arbre par
  arbre ;
- **l'équilibrage**, en dernier.

## 7. Les planches — le fêlé, le derviche, l'estoc, l'assommé

Par `/dessiner-un-effet`. Planches et captures sur le Bureau, `hns-captures-planches-chevalier\`
(captures brutes dans `brut\`). Six partis pris par planche, montrés dans leur geste.

- **Le fêlé** (`1-planche-fele.png`, posé sur la barre de vie d'un grunt à côté de la goutte du
  saignement) : écu fendu, écu en deux, plastron fendu, heaume, anneau de mailles rompu, écu
  ébréché. **Choisi : l'écu fendu**, le provisoire — il reste tel quel. Refait avant de montrer :
  trois éclats d'armure sortaient en croix, celle du béni ; le heaume rond, en boule.
- **Le derviche** (`2-planche-derviche.png`, six temps qui avancent) : deux croissants (le
  provisoire), entonnoir de vent, poussière et lame, trois croissants, spirale d'acier, lame qui
  tournoie. **Choisi : la spirale d'acier**, `Slash.spiral()`. Refaits avant de montrer :
  l'entonnoir sortait en ruche rayée (des anneaux pleins, désormais interrompus), la poussière en
  cailloux sombres (le bas de la rampe ; poussée vers le haut).
- **L'estoc** (`3-planche-estoc.png`, quatre temps jusqu'à un grunt) : le fil de la frappe vive,
  une lance, l'épée portée en avant, un fuseau et son étoile, des traits de vitesse, un chevron.
  **Choisi : le fuseau et son étoile**, `ThrustTrail`. Sans la Quarte, l'étoile éclate sur celui
  que l'estoc frappe.
- **L'assommé** (`4-planche-assomme.png`, six temps au-dessus d'un grunt) : trois étoiles en
  orbite, une spirale, un anneau de points, des oiseaux, une étoile qui palpite, deux étincelles.
  **Choisi : les étoiles en orbite**, `StunMark`, au haut de la tête (`SpriteForge.top()`, rendue
  publique) ; un seul par ennemi.

**Mesuré** (banc headless) : 0,24 ms le premier cap de la spirale, 0,17 les suivants, 2 µs relue ;
le fuseau de 36 à 96 px, dissolution comprise, de 0,17 à 0,42 ms à chaque estoc ; les étoiles,
0,15 ms une fois.

**En jeu** (`5-estoc-en-jeu.png`, `6-derviches-en-jeu.png`, `7-assomme-en-jeu.png`) : le fuseau
part en biais jusqu'au grunt et l'étoile éclate à sa pointe ; les deux derviches du Sirocco
partent en éventail et frappent ; les étoiles tournent sur la tête des deux assommés. Vu à la
capture, corrigé dans le scénario et non dans le jeu : en ville, un objet au sol et son étiquette
passaient sur le geste, et le bond atterrissait sur les grunts — posés de part et d'autre.

Deux tests de plus (`test_effect_forge.gd` : les étoiles carrées, la spirale gardée et symétrique
d'un demi-tour), deux assertions dans `test_shapes.gd` (la trace de l'estoc, les étoiles qui
partent avec l'assommé). La campagne : **1 421 tests, tous verts**.

## 8. Les retours après les planches

1. **« Il faudrait que les coups de mêlée touchent d'un tout petit peu plus loin. »** En cherchant
   où vit l'allonge, un bogue : la fiche affichait une allonge de 28 px (`attack_range`), mais la
   hitbox de l'épée était une capsule **fixe dans la scène** — l'affixe « far_reaching » et les
   quatre nœuds d'allonge de l'arbre de passifs ne changeaient rien. `Player._reach_out()` pose
   désormais le bout de la capsule à l'allonge de la fiche, à chaque `recompute_stats()` ; le
   Brise-sol et l'impact de la Frappe lourde tombent en son milieu (`strike_reach()`, qui remplace
   `SLAM_REACH`). L'allonge du joueur passe de **28 à 32 px** (`player_stats.tres`). L'estoc de la
   Tierce porte `TIERCE_BEYOND` (12 px) au-delà de l'allonge plutôt qu'à 36 px fixes.
2. **« Le Coupe-jarret dit +X % de chance de faire saigner, mais la fenêtre Alt ne change pas. »**
   Il s'appliquait à une copie du lancer, au moment de la ruée : il est maintenant dans le lancer
   résolu (`SkillStats.finalize()`), que la fenêtre lit — et vaut aussi pour le Choc d'arrivée, ce
   que dit sa description. Même défaut, mêmes soins pour deux autres : la **Herse** passe dans
   `SkillStats.ground()` et a sa ligne dans la fenêtre (la chance du sillon), l'**Ordalie** aussi
   (« second coup qui bénit à coup sûr »).
3. **Un test instable de la nécrose** (`test_suction_drinks_from_the_wilting`, jalon 45), vu en
   relançant la campagne, échouait aussi sur HEAD une fois sur trois : l'explosion de la Succion
   regardait l'état **après** son coup, qui flétrit parfois sa cible — elle buvait alors deux fois.
   `Explosion` lit l'état avant de frapper.

Deux tests de plus : l'allonge de la fiche qui pousse la lame, le Coupe-jarret dans le lancer résolu.
