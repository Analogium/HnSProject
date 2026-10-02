# Hack'n'slash top-down — jalon 36

Suite des jalons 1 à 35. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 2 octobre 2026.** Les arbres du **Maître du froid**.

---

## 1. Ce que l'utilisateur a demandé

Dans la continuité des jalons 34 et 35 : le manuel suivant, la glace. Le système (pool
par compétence, réseau sans paliers, transformations, description obligatoire) ne bouge
pas ; on remplit quatre arbres.

## 2. L'état de départ

Deux nœuds chiffrés sur trois des compétences, convertis tels quels au jalon 34 :
Éclats et Poussée (Pics de glace), Souffle et Morsure (Nova de glace), Blizzard et Œil
du cyclone (Désastre hivernal). **Le Tombeau de glace n'a pas d'arbre.** Aucun nœud ne
change la façon dont le sort se joue.

**L'identité du froid**, celle que les arbres doivent creuser : la **zone** (tout le
manuel frappe des cercles, rien ne vole), le **transi** (−25 % de vitesse d'action) et
la **tenue** : se poser, encaisser, laisser grandir. Pas de critique ni de saut : c'est
la foudre.

## 3. Ce qui se réutilise tel quel

| nombre | sur | pourquoi ça marche déjà |
|---|---|---|
| `kill_burst` | tous | `Player._on_slew()` ; le froid tire le transi (`rolled_by()`) : « un transi tué éclate » |
| chance d'état, temps du geste, rayon, durée, `period` | tous | lignes ordinaires |
| `damage_vs_chill` | tous | `SkillStats.against()` : une ligne de compétence peut déjà le viser |
| `mana_per_second` | Tombeau | rendu modifiable au jalon 35 (Sobriété) |
| lignes de buff | Tombeau | `Skill.is_buff_line()` : une ligne qui ne vise pas un nombre du lancer va au buff |
| le sol gelé | Pics, Nova | `DashTrail.patch()` dessine déjà le givre pour le froid (jalon 34, sol converti) |

## 4. Ce qui est neuf

**a. La force du transi.** Aujourd'hui `StatusEffects.CHILL` est une constante, et une
réapplication ne fait que rafraîchir la durée. Un nombre de lancer, **`chill_effect`**
(« effet du transi », en points de pourcentage), le rend plus fort ; la force est portée
par l'état et **comparée dans `put()`** comme le `per_second` des brûlures : un transi
plus faible n'écrase ni ne rafraîchit un plus fort. C'est la règle notée en mémoire le
25 septembre, et elle servira aux autres états.

**b. Des nombres de `SkillStats`** :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `chill_effect` | le transi posé ralentit davantage | `StatusEffects` (§4a) |
| `pull` | chaque impulsion tire les ennemis touchés vers le cœur | `IceVortex`, par le recul déjà porté par `DamageInfo.knockback`, inversé |
| `self_heal` | le soin du Tombeau devient un nombre que les nœuds visent | `Buff`, sur le lancer résolu comme le drain |

**c. Des nombres déjà connus, lus par plus de formes** :

- `ground_duration` : les **Pics** et la **Nova** laissent un sol gelé (la nova passe par
  `Fireball.burst()`, l'éclatement qui pose déjà explosion puis sol) ;
- `splits` : les **Pics**, en retombant, projettent leurs éclats en étoile
  (`Projectile.split()`, comme le Météore) — des javelots de glace ;
- `end_burst` : le **Désastre** éclate en finissant ; le **Tombeau** éclate quand on en
  sort (avec des dégâts de froid ajoutés par le même nœud, comme le Coup de tonnerre de
  la Ruée d'orage).

**d. Trois transformations**, et un affranchissement :

- **Sillon de glace** (Pics → `FISSURE`) : les pics percent en ligne, de vous jusqu'au
  point visé, un cercle après l'autre. Même dessin que les pics.
- **Onde de givre** (Nova → `RING`) : un anneau qui s'élargit jusqu'à trois fois le
  rayon et frappe une fois chaque ennemi au passage. **Le seul visuel neuf** — par
  `/dessiner-un-effet`.
- **Implosion** (Désastre → `IMPLOSION`) : le vortex part à pleine taille, se resserre
  jusqu'au cœur et y éclate de tout son rayon. Même dessin, croissance inversée.
- **Armure de givre** (Tombeau) : il ne vous enferme plus. Le Tombeau est un buff, que
  `Skill.TRANSFORMABLE` refuse ; c'est donc un nœud qui éteint `binds_caster` sur le
  lancer, et le dessin retombe sur celui d'un buff de froid (les flocons qui montent).

`IGNORED_BY_SHAPE` : `ground_duration` sous Onde (un sol de trois rayons) ; `end_burst`
sous Implosion (elle éclate déjà).

## 5. Les arbres — validés le 2 octobre

Mêmes conventions qu'aux jalons 34 et 35 : chiffres de **premier réglage**,
l'équilibrage en dernier ; « relié à (n) » = points demandés dans le parent, un seul lien
payé suffit ; ⇄ marque un échange. Environ 25 points pour 20 dans chaque arbre.

Trois nœuds reviennent dans chaque arbre, comme Étincelles et Surtension à la foudre :
**Engelure** (chance d'état), **Froid mordant** (effet du transi) et **Bris** (un transi
tué éclate).

### Pics de glace — le piège posé

| nœud | pts | effet | relié à |
|---|---|---|---|
| Tranchant | 4 | +8 % dégâts plus | — |
| Poussée *(gardé)* | 2 | +10 % rayon | — |
| Réflexe | 3 | −8 % temps du geste | — |
| Engelure | 3 | +15 % chance d'état | Tranchant (1) ou Réflexe (1) |
| **Éclats** *(gardé, devient vrai)* | 2 | en retombant, 2 éclats par point, à 40 % | Tranchant (2) |
| Givre persistant | 2 | laisse un sol gelé, 1 s par point | Poussée (1) |
| Froid mordant | 3 | +10 % effet du transi | Engelure (1) |
| Morsure du froid | 3 | +12 % dégâts accrus contre les transis | Froid mordant (1) |
| Bris | 1 | un transi tué éclate (50 %) | Engelure (3) |
| **Sillon de glace** | 1 | **les pics percent en ligne jusqu'au point visé** ⇄ −30 % rayon | Poussée (2) ou Éclats (1) |

Éclats garde son identifiant mais devient ce que son nom dit ; le +8 % passe à Tranchant.

### Nova de glace — le cercle qui transit

| nœud | pts | effet | relié à |
|---|---|---|---|
| Morsure *(gardé, réglé)* | 4 | +8 % dégâts plus | — |
| Souffle *(gardé)* | 3 | +10 % rayon | — |
| Réflexe | 2 | −10 % temps du geste | — |
| Engelure | 3 | +15 % chance d'état | Morsure (1) |
| Froid mordant | 3 | +10 % effet du transi | Souffle (1) ou Engelure (1) |
| Givre persistant | 2 | laisse un sol gelé, 1 s par point | Souffle (2) |
| Morsure du froid | 3 | +12 % dégâts accrus contre les transis | Froid mordant (1) |
| Bris | 1 | un transi tué éclate (50 %) | Engelure (3) |
| **Onde de givre** | 1 | **un anneau qui s'élargit jusqu'à 3× le rayon** ⇄ −20 % dégâts | Souffle (2) ou Réflexe (2) |

### Tombeau de glace — l'abri qui mord en sortant

Le buff « Carapace de givre » garde sa ligne ; les nœuds de buff s'y ajoutent tant
qu'il tient.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Glace épaisse | 4 | −3 % dégâts subis (buff) | — |
| Dégel | 3 | +20 % soin | — |
| Longue nuit | 3 | +20 % durée | — |
| Isolant | 3 | +8 % rés. froid (buff) | Glace épaisse (1) |
| Sobriété | 2 | −25 % mana drainé | Longue nuit (1) |
| **Éclatement** | 3 | en sortant, le tombeau éclate : ajoute 8 à 16 froid, rayon 12 par point | Glace épaisse (2) ou Longue nuit (2) |
| Engelure | 3 | +15 % chance d'état | Éclatement (1) |
| Froid mordant | 2 | +10 % effet du transi | Éclatement (1) |
| Bris | 1 | un transi tué éclate (50 %) | Engelure (3) |
| **Armure de givre** | 1 | **le tombeau ne vous enferme plus** ⇄ −50 % durée | Dégel (2) ou Sobriété (1) |

### Désastre hivernal — grandir, aspirer, imploser

| nœud | pts | effet | relié à |
|---|---|---|---|
| Œil du cyclone *(gardé, réglé)* | 4 | +8 % dégâts plus | — |
| Blizzard *(gardé)* | 2 | +20 % durée | — |
| Bourrasque | 3 | +10 % rayon | — |
| Rafales | 2 | −15 % intervalle des frappes ⇄ −10 % durée | Œil du cyclone (1) |
| Engelure | 3 | +15 % chance d'état | Œil du cyclone (1) ou Bourrasque (1) |
| **Aspiration** | 3 | chaque impulsion tire les ennemis vers le cœur | Bourrasque (1) |
| Froid mordant | 3 | +10 % effet du transi | Engelure (1) |
| Avalanche | 3 | éclate en finissant, rayon 15 par point | Blizzard (1) |
| Bris | 1 | un transi tué éclate (50 %) | Engelure (3) |
| **Implosion** | 1 | **part à pleine taille, se resserre et éclate au cœur** ⇄ −30 % durée | Aspiration (2) ou Avalanche (1) |

## 5 bis. Ce que la livraison a changé à la proposition

Validé par l'utilisateur tel quel (« ça me convient »). Ce qui a bougé en chemin :

- **Morsure du froid devient Acharnement** : dans l'arbre de la Nova, elle voisinait avec
  Morsure, et deux noms aussi proches se confondaient. La ligne (+12 % contre les
  transis) tient dans la fiche de survol (`test_largeurs` passe).
- **Le libellé du sol** disait « secondes de sol brûlant » : faux pour un sol gelé.
  Il dit « secondes de sol laissé », quelle que soit la nature.
- **Demandé par l'utilisateur après la livraison** (3 octobre) :
  - **chaque cercle du Sillon projette ses éclats**, et non le dernier seul ;
  - **le sol gelé de la nova a sa taille** et suit son rayon, au lieu des 14 px d'un
    sol d'impact (`SkillStats.ground()` prend un rayon). La trame d'un rayon neuf se
    cuit une fois : **1,9 ms à 46, 4,1 ms à 69**. Remplir l'image d'un tableau d'octets
    plutôt que par `set_pixel()` n'a rien gagné — le coût est le calcul par pixel — et
    a été retiré ;
  - **l'Armure de givre fixe la recharge du Tombeau à 5 s** (`FREED_RECHARGE`), après
    tous les modificateurs et sans récupération : un second prix, avec la durée
    réduite de moitié.
- **L'Éclatement du Tombeau vit dans `Player.extinguish()`**, le seul chemin de
  l'extinction : par sa fin, sa touche ou une réserve vide. Il ne vaut que pour un buff
  **lancé** (forme `BUFF`) — le buff d'une Ruée d'orage qui finit n'éclate pas une
  seconde fois — et jamais sur un mort.
- **`Targets.strike_circle()` prend un recul**, négatif pour l'Aspiration : l'impulsion
  passe par `DamageInfo.knockback`, que l'ennemi amortit déjà dans sa marche.
- **Le guide** : l'article du transi dit que des nœuds du Maître du froid le renforcent.
  La phrase sur la réapplication (« un plus faible ne change rien ») est devenue vraie
  pour lui aussi.

**L'Onde de givre, choisie sur planche** (`Bureau\hns-captures-onde-de-givre\`, deux
images : six partis pris à deux temps — l'anneau qui part et celui qui s'épuise) :
éclats couchés (le provisoire), couronne de pics, javelots projetés, anneau de glace
plein, éclats en désordre, pics et givre au sol. **« Javelots projetés »** : ceux du
Trait de glace (`Frost.javelin()`, déjà cuits au cap), pointe dehors, un tous les seize
pixels de cercle, à l'angle d'or pour qu'un javelot de plus ne déplace pas les autres ;
au bout, l'anneau se vide au lieu de pâlir. Refaites avant de montrer la planche : le
givre au sol en taches (variantes 3 et 6) se lisait comme des pièces bleues — la 3 est
devenue les javelots, la 6 une bande tramée.

**Vu à la capture** (`Bureau\hns-captures-froid-jalon36\`) : l'Onde se lit, de la
couronne serrée à l'étoile qui s'ouvre ; le Sillon perce en ligne vers le point visé ;
l'Implosion se resserre et éclate en couronne de pics sur un groupe que l'Aspiration a
ramassé (images 11 à 13 ; la première frise tombait avant l'éclatement). **L'Armure de
givre se voit à peine** : quelques flocons de buff autour du personnage, la retombée
annoncée au §4d — un dessin à elle passerait par une planche.

**Le banc de combat** (300 ennemis tenus, la case lancée sans relâche, 240 images de
chauffe puis 1 440, cinq passes alternées) : Nova nue **5,48 ms** de physique contre
Onde de givre (avec Souffle, Morsure, Engelure, Froid mordant) **4,27 ms** — elle tue
plus loin, 221 ennemis simulés en fin de mesure contre 245 ; Désastre nu **5,66 ms**
contre Implosion et Aspiration 3 **6,05 ms**, dans le bruit (écart type 0,7 à 0,8).
**165 img/s partout, 0 % du temps figé.**

**Relevé d'équilibrage** : `tests/run.sh balance` sur HEAD (worktree) puis ici,
**les mêmes échecs, messages identiques à la ligne** — aucun profil du banc ne prend un
nœud de glace.

## 6. Le déroulé

**Fait** : 1 à 5. **Reste** : l'équilibrage, en dernier.


1. **Ce document**, et la validation du §5 par l'utilisateur.
2. **Le moteur** : la force du transi (§4a), les trois nombres (§4b), les lectures du
   §4c, les trois formes et l'affranchissement — chacun avec son test de forme.
3. **Les arbres** dans `cold.tres`, descriptions comprises (relues contre le code).
4. **L'Onde de givre** sur planche (`/dessiner-un-effet`) ; capture fenêtrée du Sillon,
   de l'Implosion, de l'Armure de givre et de l'Aspiration.
5. **`/valider`** : la campagne ; le banc de combat — éclats, sols et explosions en
   chaîne multiplient les coups ; `tools/catalog.sh` ; `tests/run.sh balance` relevé
   avant → après, sans correction. ARCHITECTURE et RECETTES dans le même geste.
