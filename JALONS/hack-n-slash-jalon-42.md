# Hack'n'slash top-down — jalon 42

Suite des jalons 1 à 41. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 5 octobre 2026.** Les arbres des **manuels non uniques** — flammes, foudre,
froid — repris un manuel à la fois, en commençant par les flammes.

---

## 1. Ce que l'utilisateur a demandé

« Développer encore plus le nombre de nœuds des manuels, dans un nouveau jalon qui doit
couvrir tous les manuels non uniques, manuel par manuel, en commençant par celui des
flammes. » À retenir pour chacun :

- **un peu plus de nœuds** par compétence ;
- des nœuds **reviennent d'une compétence à l'autre** : en changer, sinon l'originalité
  d'une compétence ne se voit pas ;
- **chaque compétence a ses nœuds originaux**, comme dans Last Epoch — mécanique neuve,
  transformation, effet neuf ;
- quelques nœuds d'**interaction avec une autre compétence** (rarement d'un autre
  manuel) — sans que ça devienne une habitude : le mot d'ordre est l'originalité ;
- quelques nœuds **simples et génériques** restent normaux.

Sur la première proposition : « c'est pas mal mais j'aimerais un peu plus » — des
**nœuds-suites**, reliés au nœud qu'ils prolongent et à lui seul. « Un nœud après Météore
qui ferait lâcher des mini-météorites : il n'a de sens et d'effet que si l'on prend
Météore. » Un autre chemin n'est admis que si la suite a aussi du sens par lui. Pour les
idées : Last Epoch, mais aussi PoE, Hero Siege, Torchlight Infinite, Reddit.

## 2. La règle du jalon

Les trois manuels entrent dans `UNIQUE_TREES` au fur et à mesure : **aucun nom ni aucune
ligne ne revient d'un arbre à l'autre** d'un même manuel, sauf un nœud de dégâts, de
rayon et de durée par arbre (jalons 38 à 41). Une fois le froid fini, tous les manuels y
sont et la constante disparaît : la règle devient celle de tous les arbres.

**Un échange n'est pas un second levier.** Le test ne l'exempte aujourd'hui que ligne par
ligne : Pouls lent (−50 % de cadence ⇄ +60 % plus) compterait comme un second nœud de
dégâts. Il exemptera le nœud entier dès qu'une de ses lignes est une perte
(`StatMod.is_loss()`), ce que dit déjà son commentaire.

**Les suites (↳).** Une suite n'a qu'un parent : le nœud qui change le jeu et qu'elle
prolonge. Le moteur le permet déjà (`TalentNode.parents`, un seul suffit). Un test
vérifiera qu'une suite ne lit que des nombres que la forme ou la mécanique de son parent
lit — une suite de Météore sans Météore ne ferait rien, et c'est précisément pourquoi elle
ne doit être accessible que par lui.

**Cible** : 13 à 21 nœuds par compétence (9 à 12 aujourd'hui), 30 à 43 points offerts pour
un pool de 20. Dans chaque arbre : quelques leviers simples, les mécaniques gardées, **deux
à quatre nœuds que seule cette compétence a**, et **une à deux suites** derrière chaque
nœud qui change le jeu. Une interaction entre compétences dans **deux arbres sur cinq** au
plus par manuel.

Inspirations relevées : dans Last Epoch, le *Concentrated* qui troque la zone contre la
touche directe, le *Flamethrower* qui change le geste, les nœuds de Flame Rush qui lancent
une autre compétence à l'arrivée (*Magma Starter*) ou se combinent avec un sort d'une
autre école (*Gas Powered*, avec Frost Wall) ; dans Hero Siege, *IGNITE THE FLAMES!*, des
charges d'ignition qui éclatent en pulsation au maximum ; dans PoE, l'Incinerate qui monte
tant qu'on le tient.

## 3. Le manuel des flammes — la proposition

### Ce qui se répète aujourd'hui

| ligne | arbres qui la portent | où elle reste |
|---|---|---|
| Étincelles (chance d'état) | Boule de feu, Immolation, Ruée ardente | **Boule de feu** — la Réaction en chaîne en a besoin |
| sol brûlant | Boule de feu, Serpent, Immolation | **Serpent** — la Queue de flammes est son sillage |
| explosion des tués | Boule de feu, Immolation | **Boule de feu** |
| explosion finale | Serpent, Ruée ardente | **Ruée ardente** — l'Atterrissage |
| brûlure subie | Immolation, Ignition | **Immolation** — se brûler pour brûler, c'est elle |
| +1 projectile ⇄ / +1 serpent ⇄ | Boule de feu, Serpent | les deux : deux statistiques distinctes (`projectiles`, `brood`) |

Conventions des jalons précédents : chiffres de **premier réglage**, « relié à (n) » =
points demandés dans le parent, ⇄ marque un échange. **Neuf** = un nombre de `SkillStats`
à écrire ; 🔗 = interaction avec une autre compétence ; **↳** = suite, accessible par son
seul parent.

### Boule de feu — l'artillerie *(12 → 21 nœuds, 43 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Attisement *(gardé)* | 4 | +8 % dégâts plus | — |
| Souffle ardent *(gardé)* | 3 | +15 % rayon de l'explosion | — |
| Vélocité *(gardé)* | 2 | +20 % vitesse de projectile | — |
| Ardeur *(gardé)* | 2 | +25 % chance critique | Attisement (2) |
| Étincelles *(gardé)* | 3 | +15 % chance d'état | Souffle ardent (1) ou Ardeur (1) |
| Double langue *(gardé)* | 2 | +1 boule en éventail ⇄ −10 % plus | Vélocité (2) |
| Perforation *(gardé)* | 2 | traverse un ennemi de plus | Vélocité (1) |
| Fragmentation *(gardé)* | 3 | éclate en petites boules | Perforation (1) ou Double langue (1) |
| Réaction en chaîne *(gardé)* | 1 | un embrasé tué explose, en chaîne | Étincelles (3) |
| Givre *(gardé)* | 1 | conversion au froid | Ardeur (1) |
| Météore *(gardé)* | 1 | transformation : tombe du ciel | Attisement (3) ou Double langue (1) |
| **Noyau dense** | 1 | **la boule n'explose presque plus** : −75 % rayon ⇄ +50 % dégâts plus — la touche directe contre la zone | Attisement (2) |
| **Prise d'air** *(neuf)* | 3 | **la boule enfle en volant** : son explosion gagne 10 % de rayon et de dégâts par point, par 100 px parcourus — tirer de loin | Vélocité (1) |
| **Surchauffe** *(neuf)* | 3 | **une explosion surchauffe ce qu'elle touche pendant 3 s** : la boule suivante l'y frappe 8 % plus fort par point, jusqu'à trois fois — marteler une cible | Noyau dense (1) ou Ardeur (1) |
| **Feu nourri** 🔗 *(neuf)* | 2 | **une boule lancée pendant que votre Immolation brûle sort attisée du brasier** : +15 % dégâts plus et +15 % rayon par point | Souffle ardent (2) |
| ↳ **Pluie de météorites** *(neuf)* | 3 | **après l'impact, une mini-météorite par point retombe autour du point visé**, 0,3 s plus tard, à 30 % des dégâts et un tiers du rayon | Météore (1) |
| ↳ **Chute libre** | 1 | le météore tombe aussitôt : **le geste n'est plus allongé** | Météore (1) |
| ↳ **Givre profond** | 3 | la boule de glace transit plus fort : +15 % effet du transi par point (`chill_effect`) | Givre (1) |
| ↳ **Éclats en cascade** *(neuf)* | 1 | **les éclats éclatent à leur tour**, une fois, à moitié de leur force | Fragmentation (2) |
| ↳ **Poudrière** *(neuf)* | 1 | **l'explosion d'un tué pose à coup sûr l'état de la boule** sur ce qu'elle touche — la chaîne ne s'arrête plus faute d'embrasés | Réaction en chaîne (1) |
| ↳ **Convergence** *(neuf)* | 1 | **les boules ne partent plus en éventail : elles se rejoignent au point visé**, où une même cible les prend toutes | Double langue (1) |

*Retiré* : Braises dispersées (le sol va au Serpent).

### Serpent infernal — le chasseur *(10 → 20 nœuds, 38 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Mue *(gardé)* | 4 | +8 % dégâts plus | — |
| Longue vie *(gardé)* | 3 | +20 % durée | — |
| Crocs *(gardé)* | 2 | ajoute 4 à 9 dégâts de feu | — |
| Sifflement | 3 | −8 % temps du geste | — |
| Vif *(gardé)* | 2 | rampe plus vite ⇄ vit moins | Longue vie (1) ou Mue (1) |
| Queue de flammes *(gardé)* | 3 | sillon de sol brûlant — **le seul sol du manuel** | Longue vie (1) ou Chasseur (1) |
| Chasseur *(gardé)* | 1 | suit l'ennemi le plus proche | Crocs (1) |
| Couvée *(gardé)* | 2 | +1 serpent ⇄ −15 % plus (la limite de trois tient) | Mue (2) |
| Hydre *(gardé)* | 1 | des petits à sa mort | Couvée (2) ou Gloutonnerie (2) |
| Venin *(gardé)* | 1 | conversion au nécrotique | Crocs (2) |
| **Gloutonnerie** *(neuf)* | 3 | **chaque ennemi que le serpent tue le fait grossir** : +5 % dégâts plus par point et +0,5 s de vie par proie, cinq proies au plus — il grandit à l'écran (`HellSnake._size`, jalon 41) | Mue (1) |
| **Constriction** *(neuf)* | 1 | **le serpent s'enroule autour du premier ennemi qu'il mord** et ne le lâche plus : il cesse de ramper et mord deux fois plus vite jusqu'à sa mort, puis repart | Chasseur (1) |
| **Ouroboros** *(neuf)* | 1 | **le serpent se mord la queue** : il tourne en rond autour du point où il tombe, sans chasser ; avec la Queue de flammes, il trace un anneau de feu ⇄ le Chasseur ne sert plus | Queue de flammes (2) |
| **Crachat** *(neuf)* | 2 | **toutes les 1,5 s, le serpent crache une petite boule de feu** vers l'ennemi le plus proche à 100 px : 30 % d'une morsure par point | Vif (1) ou Sifflement (1) |
| ↳ **Spirale** *(neuf)* | 1 | **l'anneau se resserre en tournant** : de son rayon à son centre sur la vie du serpent, en rabattant les ennemis vers le milieu | Ouroboros (1) |
| ↳ **Étau** *(neuf)* | 1 | **l'ennemi enlacé ne bouge plus** et n'attaque plus tant que le serpent le tient | Constriction (1) |
| ↳ **Mue de croissance** *(neuf)* | 1 | **à la cinquième proie, le serpent mue** : il éclate en une gerbe de feu autour de lui, reprend sa taille et sa vie entière, et recommence à grossir | Gloutonnerie (3) |
| ↳ **Gerbe** *(neuf)* | 2 | le crachat part en éventail : **+1 boule par point** | Crachat (1) |
| ↳ **Venin d'hydre** | 2 | les petits de l'Hydre vivent 0,5 s de plus et mordent 15 % plus fort, par point | Hydre (1) |
| ↳ **Morsure nécrosante** *(neuf)* | 2 | chaque morsure sur un pourrissant **prolonge sa pourriture** de 0,5 s par point | Venin (1) |

*Retiré* : Mue explosive (l'explosion finale va à la Ruée).

### Immolation — le bûcher *(9 → 17 nœuds, 43 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fournaise *(gardé)* | 5 | +8 % dégâts plus | — |
| Brasier *(gardé)* | 4 | +15 % rayon | — |
| Cœur tiède *(gardé)* | 3 | −20 % brûlure subie | — |
| Pouls lent *(gardé)* | 2 | frappe moins souvent, bien plus fort | Fournaise (2) |
| Phénix *(gardé)* | 1 | brûle deux fois plus ⇄ +40 % plus | Cœur tiède (2) |
| Flamme noire *(gardé)* | 1 | conversion au nécrotique | Pouls lent (1) |
| **Brûlure profonde** *(neuf)* | 4 | **force de l'embrasement** posé par le brasier : +15 % par point — le dernier état sans force | Fournaise (1) |
| **Tirage** | 3 | **le brasier aspire l'air** : chaque impulsion attire les ennemis vers vous (`pull`, déjà lu par `Targets.strike_circle`) | Brasier (1) |
| **Feu de camp** *(neuf)* | 3 | **immobile, le brasier monte** : +6 % de dégâts plus et +5 % de rayon par point et par seconde sans bouger, trois secondes au plus ; il retombe dès que vous marchez | Brasier (2) ou Pouls lent (1) |
| **Escarbilles** *(neuf)* | 3 | **à chaque impulsion, une escarbille par point jaillit vers un ennemi hors du cercle**, jusqu'à deux fois le rayon : 40 % d'une impulsion — les braises que l'aura dessine déjà | Brasier (1) ou Tirage (1) |
| **Offrandes** *(neuf)* | 3 | chaque ennemi tué par le brasier rend 1 mana par point | Cœur tiède (1) |
| ↳ **Fonte** *(neuf)* | 3 | **l'embrasement du brasier fait fondre les défenses** : l'embrasé perd 5 résistance au feu par point, comme le maudit perd du nécrotique (`resistance_lost()`) | Brûlure profonde (2) |
| ↳ **Renaissance** *(neuf)* | 1 | **une fois par minute, un coup fatal vous laisse à 1 PV** et le brasier explose de toute sa force, deux fois son rayon | Phénix (1) |
| ↳↳ **Cendres du phénix** *(neuf)* | 1 | après une renaissance, **4 s sans brûlure subie et +50 % dégâts plus** | Renaissance (1) |
| ↳ **Veillée** *(neuf)* | 2 | **à pleine montée du feu de camp**, vous regagnez 1 % de vos PV par seconde et par point | Feu de camp (3) |
| ↳ **Œil du brasier** *(neuf)* | 2 | les ennemis **dans le tiers central** du cercle prennent 12 % de dégâts plus par point — là où le Tirage les amène | Tirage (2) |
| ↳ **Âmes consumées** *(neuf)* | 2 | le brasier nécrotique **soigne** : chaque ennemi qu'il tue rend 1 % de vos PV max par point | Flamme noire (1) |

*Retirés* : Étincelles (Boule de feu), Cendres vivantes (le sol va au Serpent),
Contagion ardente (l'explosion des tués va à la Boule de feu).

### Ruée ardente — la traînée *(10 → 17 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Bûcher *(gardé)* | 4 | +8 % dégâts plus | — |
| Sillage *(gardé)* | 3 | +25 % durée de la traînée | — |
| Élan *(gardé)* | 2 | −10 % recharge | — |
| Braises *(gardé)* | 3 | +20 % rayon de la traînée | Sillage (1) |
| Brûle-pavé *(gardé)* | 2 | la traînée dure bien plus ⇄ brûle moins fort | Sillage (1) ou Bûcher (1) |
| Tison *(gardé)* | 2 | +12 % dégâts contre les embrasés | Bûcher (2) |
| Atterrissage *(gardé)* | 3 | explosion à l'arrivée — **la seule explosion finale du manuel** | Élan (1) |
| Onde de choc *(gardé)* | 2 | l'explosion d'arrivée s'élargit | Atterrissage (2) |
| Bond *(gardé)* | 1 | transformation : un saut | Atterrissage (1) ou Élan (2) |
| **Départ en trombe** *(neuf)* | 2 | **l'explosion d'arrivée éclate aussi là d'où vous partez**, à 35 % de sa force par point | Atterrissage (1) |
| **Mèche** *(neuf)* | 3 | **quand la traînée s'éteint, elle s'embrase d'un bout à l'autre** : une flamme court de votre départ à votre arrivée et chaque plaque explose à son passage, 50 % d'une impulsion par point | Brûle-pavé (1) ou Tison (1) |
| **Seconde foulée** *(neuf)* | 1 | **dans la seconde et demie qui suit une ruée, la relancer est gratuit** et ne relance pas la recharge — une fois | Élan (2) |
| **Charmeur** 🔗 *(neuf)* | 1 | **à l'arrivée, un Serpent infernal surgit des flammes**, si vous savez le lancer : avec vos points et votre arbre du serpent, sans coût, compté dans la limite de trois | Atterrissage (2) |
| ↳ **Onde brûlante** *(neuf)* | 2 | **l'atterrissage du bond projette un anneau de flammes** qui s'étend jusqu'à deux fois son rayon, 40 % des dégâts par point (l'anneau de `FrostRing`) | Bond (1) |
| ↳ **Mèche courte** | 1 | la mèche s'allume **dès votre arrivée** au lieu d'attendre l'extinction ⇄ la traînée disparaît avec elle | Mèche (1) |
| ↳ **Danse du charmeur** *(neuf)* | 1 | à l'arrivée, **vos serpents déjà en jeu se ruent vers vous** et chassent autour de votre point d'arrivée | Charmeur (1) |
| ↳ **Foulée de feu** | 2 | la seconde ruée, celle qui est gratuite, laisse une traînée 20 % plus forte par point | Seconde foulée (1) |

*Retiré* : Étincelles (Boule de feu).

### Ignition — la combustion *(9 → 15 nœuds, 33 points)*

La Combustion garde ses lignes ; les nœuds de buff s'y ajoutent tant qu'elle brûle. Elle
perd la brûlure subie, qui va à l'Immolation : son prix se gère autrement.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Braise vive *(gardé)* | 4 | +6 % dégâts de feu accrus (buff) | — |
| Allure *(gardé)* | 3 | +4 % vitesse de déplacement (buff) | — |
| **Combustible** *(neuf)* | 3 | **la combustion brûle votre mana avant votre vie** : 20 % par point de sa brûlure payée en mana tant qu'il en reste | — |
| Brasier intérieur *(gardé)* | 3 | +8 chance d'embraser (buff) | Braise vive (2) |
| Peau de braise *(gardé)* | 2 | +8 résistance au feu (buff) | Combustible (1) ou Braise vive (1) |
| Emballement *(gardé)* | 2 | +4 % vitesse d'incantation (buff) | Allure (1) |
| Cendres fertiles *(gardé)* | 2 | +1,5 PV/s (buff) | Combustible (1) ou Allure (1) |
| **Corps-torche** | 1 | **+30 % dégâts de feu ⇄ −30 résistance au feu** : la combustion vous brûle en feu, elle mord d'autant plus — remplace Feu dévorant | Brasier intérieur (1) ou Peau de braise (1) |
| Holocauste *(gardé)* | 1 | +20 % dégâts de feu plus (buff) | Corps-torche (1) ou Brasier intérieur (3) |
| **Toucher brûlant** *(neuf)* | 2 | **un ennemi qui vous frappe au corps à corps s'embrase**, 50 % de chance par point | Peau de braise (1) |
| **Point d'éclair** *(neuf)* | 3 | **tant que la combustion brûle, chaque coup de feu dépose une charge sur l'ennemi** ; à la huitième, il éclate en une pulsation de feu autour de lui, 2 % de ses PV max par point (Hero Siege) | Brasier intérieur (1) |
| **Embrasement final** *(neuf)* | 2 | **quand la combustion s'éteint, vous explosez** : 25 % par point de la vie qu'elle vous a brûlée, en feu, autour de vous | Combustible (2) |
| ↳ **Étincelle jumelle** *(neuf)* | 1 | la pulsation du point d'éclair **dépose deux charges** sur ce qu'elle touche — les éclats s'enchaînent dans la meute | Point d'éclair (2) |
| ↳ **Feu bleu** *(neuf)* | 2 | tant que la combustion se paie en mana, **+8 % dégâts de feu plus par point** | Combustible (2) |
| ↳ **Brasier contenu** *(neuf)* | 2 | plus la combustion a duré, plus l'explosion finale est large : **+4 px par seconde allumée et par point**, 20 s au plus | Embrasement final (1) |

*Retirés* : Cendres froides, Feu dévorant (la brûlure subie va à l'Immolation).

### Récapitulatif

- **51 → 90 nœuds**, dont **25 suites** ; ~35 nombres neufs dans `SkillStats`. Deux
  interactions (Feu nourri, Charmeur et sa Danse), dans deux arbres sur cinq. Pas
  d'interaction avec un autre manuel ici : elle viendra plus naturellement de la foudre
  ou du froid.
- **L'embrasement prend une force** (`ignite_effect`, Brûlure profonde) : avec la Fonte,
  l'Immolation devient l'arbre de l'embrasement, comme la Boule de feu est celui de la
  zone et la Ruée celui du terrain.
- **Dessin** : la mini-météorite, l'escarbille en vol, le crachat et la charge du point
  d'éclair passent par `/dessiner-un-effet`. Le serpent qui grossit réutilise son échelle ;
  la Mèche, le Départ et la Mue de croissance réutilisent `Explosion` ; l'Onde brûlante
  l'anneau de `FrostRing`.
- **La page de l'arbre** : 21 nœuds tiennent-ils dans la grille autour de la compétence ?
  À vérifier sur capture avant d'écrire les positions — c'est elle qui décide si une suite
  pousse l'arbre au-delà de ±3 cases.
- **Livraison en deux temps** si la taille l'exige : les nœuds sans nombre neuf
  d'abord (réorganisation, leviers, suites de nombres existants), puis les mécaniques
  arbre par arbre, chacune avec son test.
- **`docs/ARBRES.md` se régénère** ; les couloirs d'équilibrage se relèvent avant →
  après, sans les corriger (jalon 13, §7).

## 4. La lecture de l'arbre — livrée

L'utilisateur : « séparer visuellement les nœuds basiques des nœuds qui transforment
fondamentalement le gameplay, ainsi que leur suite ». Jusqu'ici tous les nœuds étaient le
même carré de 28 px ; seule une pastille de 2 px dans un coin marquait une mécanique.

**Choisi sur planche** (`hns-captures-arbre-noeuds/planche-noeuds.png`, l'arbre proposé de la
Boule de feu, six variantes : l'actuel, tailles, **losanges**, double liseré, fond teinté,
octogones) : la **3**.

- nœud de nombres : **petit carré** (22 px) ;
- ce qui change le jeu : **grand losange** (rayon 15), pastille de sa sorte à la pointe ;
- suite : **petit losange** (rayon 11), relié par un **tireté** de la couleur de ce qu'elle
  prolonge, assombri tant qu'elle n'est pas prise.

Le liseré garde l'état (verrouillé, ouvert, plein) : la sorte passe par la silhouette, pas
par la couleur du contour. **Une suite se déduit des liens** (`ManualCell.is_suite()`) : tous
ses parents changent le jeu ou en sont une. Rien à déclarer dans les `.tres`, et la règle
des suites du §2 se lira sur la page sans qu'on l'écrive deux fois.

**La grille passe à ±3 × ±2** (`TREE_SPAN`) : à ±1, vingt places pour les vingt et un nœuds
de la Boule de feu. La page n'offre que **164 px** entre l'en-tête et l'aide ; cinq rangées
à 44 px en demandaient 204. D'où **32 px entre deux rangées** et les silhouettes plus petites
que sur la planche (24 / 18 / 13 px).

**Vu à la capture** (`1-arbre-boule-de-feu`, `2-arbre-ruee-ardente`) : à 2 px, le tireté
d'une suite se confondait avec les grains « ••• » des points demandés au parent ; à 4 px
(`SUITE_DASH`), il s'en distingue. Le test des liens qui passent sous un nœud mesure
désormais contre la silhouette dessinée — carré sur l'axe le plus lâche, losange en somme
des deux —, plus contre le carré de survol.

## 5. La Boule de feu — livrée

L'arbre du §3, **21 nœuds, 43 points**, sur la grille ±3 × ±2 :

```
              Feu nourri
 Poudrière  Réaction  Étincelles  Souffle  Prise d'air  Perforation
 Givre      Ardeur    Attisement  [BOULE]  Vélocité     Fragmentation  Cascade
 Gel intense Surchauffe Noyau dense Météore   ·          Double langue  Convergence
                                  Pluie     Chute libre
```

**Écarts avec la proposition** :

- **« Givre profond » devient Gel intense** : le nom était déjà celui d'un nœud de l'arbre
  de passifs.
- **La Convergence n'est pas une suite** au sens de la page : son parent, Double langue, est
  un nœud de nombres. Elle se dessine en grand losange, comme toute mécanique.
- **Le sol brûlant quitte la boule** avec Braises dispersées : `Fireball.burst()`, qui ne
  faisait plus que l'explosion, disparaît — la boule et le Météore appellent `Explosion.put()`.
- **Trois libellés raccourcis** pour tenir sur la fiche (le test des largeurs) : « dégâts et
  rayon par 100 px », « dégâts et rayon attisés », « état assuré aux explosions ».
- **La Poudrière ajoute de la chance** (`SURE_STATE`, 500 points : ×6 sur les 20 % de base)
  plutôt que de contourner le tirage : le nombre de tirages ne change pas (invariant 3).

**Ce qui est neuf dans le moteur** : sept nombres de `SkillStats` (ARCHITECTURE, « Qu'est-ce
qu'un nœud peut allumer ? ») et **l'état `OVERHEAT`**, le dixième — des charges portées par sa
force, posées par `StatusEffects.charge()`, lues par `against_factor()`. Il a son icône, son
article du guide et sa couleur. **L'icône, choisie sur planche** (`planche-surchauffe.png`) :
le **soleil** ; le thermomètre d'abord posé avait, à 9 px, la silhouette de la flamme de
l'embrasement — vu à la capture, juste à côté d'elle sur la barre de vie.

**Captures** (`hns-captures-boule-de-feu`) : l'arbre tient sur ses cinq rangées ; les
mini-météorites (la boule de 13 px, trois petites langues, sans secousse) tombent en couronne
après l'impact, leur ombre grandit au sol.

**Le banc** (`only=fireball`), relevé avant → après, **sans rien corriger** (§7 du jalon 13) :

| build | avant | après |
|---|---|---|
| meilleur au paquet | ×12,4 | ×23,5 |
| meilleur au duel | ×3,39 | ×12,1 |

Le duel est porté par **Noyau dense + Surchauffe + Météore + Chute libre** : la Chute libre
efface tout le prix du Météore, qui n'est plus qu'un gain. Jamais pris : Perforation, Prise
d'air, Feu nourri (le banc n'allume pas d'Immolation), Pluie de météorites, Gel intense (le
banc ne voit pas le ralenti), Éclats en cascade, Poudrière. À reprendre à l'équilibrage.

## 6. Les retours sur la Boule de feu

L'utilisateur, après la livraison du §5 :

1. **« Agrandir l'interface des manuels »**. Choisi sur planche (`hns-captures-interface-manuels`,
   trois dispositions sur une vraie capture) : **B, plein écran**. L'arbre ouvert prend
   624 × 283 px, à 8 px des bords, par-dessus le sac ; les dos des livres s'effacent le
   temps de l'arbre — on change de livre depuis la grille. Grille ±4 × ±2, pas de 64 × 44,
   nœuds à 26 / 18 / 13 px. Ce qui remplace le §4 : les 32 px entre deux rangées étaient
   le prix d'une page de 164 px. La fiche d'un nœud se pose à côté de lui, du côté où il y
   a la place : hors du panneau, il n'y en a plus.
2. **Une suite de la Prise d'air qui fait grossir la boule** : le **Gonflement** (2 points,
   +15 % de taille par point et par 100 px volés, ×2 au plus). La forme de touche grandit —
   une copie de celle de la scène, jamais elle (invariant 2). **Le dessin, choisi sur
   planche** (`planche-gonflement.png`) : la boule **fabriquée à sa taille** dans la rampe de
   la boule dessinée (`EffectForge.grown_balls()`), plutôt qu'une couronne de braises ou le
   palier de la planche du Météore. **Mesuré** : la cuisson coûte 0,6 ms à 15 px, 1,5 ms à
   21 px, 1,9 ms à 27 px, **une fois** par teinte et par taille (2 µs en relecture) ; sept
   tailles au plus, cuites une à une au premier vol.
3. **Une suite d'un point qui fait suivre au rayon les bonus de zone** : la
   **Déflagration**. Les lignes de rayon qui visent la zone s'appliquent à la boule ; ses
   dégâts de zone non, et la boule ne prend pas le mot-clé.
4. **La Surchauffe dans la fenêtre Alt** : posée à chaque coup (100 %), et ce que vaut une
   charge.
5. **Le Météore coûte 50 % de mana en plus.** Le coût devient un nombre que les nœuds
   peuvent viser — **les nœuds seuls** : la règle qui écarte toute ligne d'objet visant le
   coût tient (`test_only_named_things_are_modified`). La barre grise sa case sur le coût
   résolu (`Player.cost_of()`).
6. **Le Noyau dense ne se sentait pas** sous le Météore : −75 % **accrus** s'ajoutaient aux
   +200 % de la chute (83 → 68 px relevés par l'utilisateur). Il devient un **« moins »**, qui
   multiplie après les accrus : le quart du rayon, Météore ou non.

Au passage : la Prise d'air, la Surchauffe, le Feu nourri et le Gonflement s'affichent en
pourcentage sur la fiche (`StatMod.PERCENT_POINTS`) — « +30 » se lisait comme des pixels.

L'arbre compte **23 nœuds, 46 points** : la Déflagration (1, −2) et le Gonflement (2, −2),
au-dessus de la Prise d'air.

## 7. Le Serpent infernal — livré

L'arbre du §3, **20 nœuds, 38 points**, sur la grille ±4 × ±2 :

```
 Spirale    Ouroboros  Queue      Longue vie  Vif
 Étau  Constriction  Chasseur  Crocs  [SERPENT]  Mue  Couvée  Hydre  Venin d'hydre
 Morsure nécr.  Venin      ·      Sifflement  Crachat  Gloutonnerie
                                              Gerbe    Mue de croissance
```

**Écarts avec la proposition** :

- **Le Sifflement vise l'intervalle des morsures** (−8 % par point), plus le temps du geste :
  celui-ci est déjà la ligne de la Chute libre, et le manuel du feu entrera dans
  `UNIQUE_TREES`.
- **Le Crachat ne s'ouvre que par le Sifflement** : venu du Vif, son lien traversait la Mue.
- **L'Hydre se lit en suite** sur la page : ses deux parents, la Couvée et la Gloutonnerie,
  changent le jeu (`ManualCell.is_suite()`). Son Venin d'hydre est la suite d'une suite.
- **Une suite n'est plus proposée comme entrée de son parent** sur la fiche : « ou Venin
  d'hydre à 1 » s'affichait sous l'Hydre, alors qu'on n'atteint le Venin que par elle
  (`ManualPanel._requirement_lines()`). Le test de la fiche de l'Hydre l'a vu.
- **La Mue explosive part, et le code qui la portait** : `HellSnake._die()` ne lit plus
  `end_burst`. Le test de la mort du serpent ne garde que les petits.
- **L'Étau n'est pas un état** : un compteur de prises (`StatusEffects.hold()`) qui met
  `speed_factor` à zéro. Pas d'icône à dessiner, et deux serpents sur la même proie ne la
  lâchent qu'au départ du second. Sa limite : le gonflement du Bloater et l'élan de la
  Brute ne lisent pas le gel, ils continuent.
- **La Morsure nécrosante plafonne à la pleine durée** : sans plafond, une morsure toutes
  les 0,4 s qui rend 1 s rendait la pourriture éternelle.

**Ce qui est neuf dans le moteur** : onze nombres de `SkillStats` (ARCHITECTURE, « Qu'est-ce
qu'un nœud peut allumer ? »), deux lancers dérivés (`hatchling()`, `spark()`, que les Escarbilles reprennent au §8),
`StatusEffects.extend()` et `hold()`. **Rien de dessiné** : l'anneau, l'étreinte et la spirale
sont des trajectoires du corps existant (`HellSnake._circle()`), le crachat est l'éclat de la
Fragmentation, la gerbe de la mue une `Explosion`, et la Gloutonnerie grossit le serpent par
`_size`, l'échelle des petits de l'Hydre.

**La Gloutonnerie reconnaît ses proies au lancer qui les tue.** La couvée partageait un même
lancer pour ses trois serpents : un tué aurait nourri les trois. Sous la Gloutonnerie, chaque
serpent a sa copie (`SkillStats.echoed()`). La gerbe de la mue a aussi la sienne : ses tués
nourrissant le serpent, une mue en aurait déclenché une autre dans la même meute.

**Captures** (`hns-captures-serpent`) : l'arbre, la fiche posée à côté du nœud des deux côtés ;
l'**anneau de feu** se ferme en une seconde et demie, le serpent passe ensuite à l'intérieur
de son propre anneau (la Spirale), et les boules crachées en sortent vers le paquet ;
l'**étreinte** fait un anneau de braise autour de la proie, qui ne bouge plus. **Vu à la
capture** : au niveau 1 de zone, une proie meurt en une ou deux morsures, l'étreinte ne se
voit qu'un instant — la capture a gonflé les PV du paquet pour la montrer. Et le Chasseur va
au plus proche de sa tête, souvent le lanceur ennemi qui tient sa distance, pas la mêlée
collée au joueur.

**Le banc** (`only=hell_snake`), relevé avant → après, **sans rien corriger** :

| build | avant | après |
|---|---|---|
| sans arbre | 139/s, 113/s | 128/s, 98/s |
| meilleur au paquet | ×3,28 | ×4,07 |
| meilleur au duel | ×2,48 | **×10,5** |

Le duel est porté par la **Constriction** : la cible du banc ne meurt jamais, le serpent ne la
lâche plus et mord deux fois plus vite toute sa vie, avec le **Crachat** et sa **Gerbe** par
dessus. Le paquet prend Sifflement, Crachat et Gerbe. Jamais pris : Longue vie, Vif, Couvée,
Hydre, Ouroboros, Spirale, Étau (le banc ne voit pas l'immobilité), Mue de croissance, Venin
d'hydre, Morsure nécrosante. La base sans arbre bouge d'environ 10 % sans qu'aucun nœud n'y
soit : à vérifier à l'équilibrage, le bruit connu du serpent est de ±0,1 sur un rapport.

## 8. L'Immolation — livrée

L'arbre du §3, **17 nœuds, 43 points** :

```
                       Veillée    Escarbilles  Œil du brasier
                       Feu de camp  Brasier    Tirage
 Âmes  Flamme noire  Pouls lent  Fournaise  [BRASIER]  Cœur tiède  Phénix  Renaissance  Cendres
                       Brûlure prof.            Offrandes
                       Fonte
```

**Écarts avec la proposition** :

- **Les Offrandes sont le Siphon de la sorcière** (`siphon`) : le brasier est un geste
  allumé, `Player._siphon()` le lisait déjà. Elles rendent donc du mana pour tout ennemi tué
  **par un sort** tant que le brasier brûle, pas seulement par lui — sans une ligne de code.
- **La Renaissance laisse 20 % des PV**, plus 1 PV : à 1 PV, la brûlure du brasier — doublée
  sous le Phénix — tuait dans les huit images suivantes, et le nœud ne valait rien sans sa
  suite.
- **Le Feu de camp porte un seul nombre**, +5 % par point et par seconde, aux dégâts comme au
  rayon (la proposition disait 6 et 5).
- **La Fonte et la Renaissance se dessinent en grands losanges**, pas en suites : leurs
  parents, la Brûlure profonde et le Phénix, sont des nœuds de nombres. La Brûlure profonde
  est une force d'état, comme le Froid mordant ; le Phénix, un échange.
- **Le sol sous les tués d'une aura disparaît** avec les Cendres vivantes
  (`Player._on_slew()`), et son test : plus aucun nœud ne le donnait.
- **L'impulsion n'est plus `Targets.strike_circle()`** : l'Œil du brasier frappe plus fort au
  cœur sur le même tirage, et le Tirage y ramène par un recul négatif. Toujours un tirage
  par impulsion (invariant 3).

**Ce qui est neuf dans le moteur** : neuf nombres de `SkillStats`, l'embrasement dans
`EFFECT_OF` (le dernier état sans force), `StatusEffects.melt()` et le `melt` de son état,
`Player._reborn()` en tête de `_die()` et `Player.phoenix_ashes`. **`Fireball.spark()`**
rassemble ce que le Crachat du serpent écrivait seul : la petite boule des éclats, sans gel,
l'auteur posé à la main — les Escarbilles s'en servent, et `SkillStats.spat()` devient
`spark(part)`. **Rien de dessiné** : le brasier qui monte est son propre rayon, les
escarbilles des étincelles, la renaissance une `Explosion`.

**Captures** (`hns-captures-immolation`) : l'arbre ; le brasier qui s'élargit tant qu'on ne
bouge pas, les ennemis tirés vers le cœur, et les escarbilles qui partent du bord vers ceux
restés dehors. **Vu à la capture** : le rayon monte par paliers, à chaque impulsion
(0,5 s) — il se résout à l'impulsion, comme tout le brasier.

**Le banc** (`only=immolation`), relevé avant → après, **sans rien corriger** :

| build | avant | après |
|---|---|---|
| meilleur au paquet | ×5,42 | ×8,03 |
| meilleur au duel | ×2,28 | ×4,18 |

Le paquet est porté par le **Feu de camp** et les **Escarbilles** — le banc ne bouge jamais,
le feu de camp y est toujours à pleine montée. Le duel prend aussi le Tirage et l'Œil du
brasier. Jamais pris : Offrandes, Fonte, Renaissance, Cendres du phénix, Veillée, Âmes
consumées — le banc est aveugle au mana, aux PV et à la mort ; la Fonte ne joue que sur un
embrasé, à 15 points de résistance.

## 9. La Ruée ardente — livrée

L'arbre du §3, **17 nœuds, 35 points** :

```
                                              Danse du charmeur
 Mèche courte  Mèche  Brûle-pavé  Sillage  Braises  Charmeur  Départ en trombe
               Tison  Bûcher  [RUÉE]  Élan  Atterrissage  Onde de choc
                                      Seconde foulée  Bond  Onde brûlante
                                      Foulée de feu
```

**Écarts avec la proposition** :

- **La Mèche fait exploser une sonde sur deux** du couloir : à chaque sonde (0,9 rayon), les
  explosions se chevauchaient et une cible en prenait trois.
- **La Foulée de feu renforce toute la seconde ruée** — traînée, explosion d'arrivée, onde —
  par une copie du lancer (`echoed()`), plutôt que la traînée seule.
- **L'Onde brûlante est l'anneau de `FrostRing`**, qui prend désormais sa portée
  (`spread(…, reach_factor)`) et se dessine en feu quand sa nature l'est.
- **La Seconde foulée demande un nouvel appui.** Relevé par l'utilisateur : « elle ne marche
  pas ». La touche tenue relance la case à chaque image où elle le peut, et la ruée gratuite
  partait l'image d'après la première, au même point — invisible et dépensée. Le test
  appelait `cast_slot()` sans passer par la touche ; il passe maintenant par elle.
- **La barre ne montre pas la Seconde foulée** : la case reste voilée par sa recharge pendant
  la fenêtre où elle se relance gratuitement.

**Choisi sur planche** (`hns-captures-onde-brulante`, cinq partis pris à trois moments de
l'onde) : **la couronne alternée**, une grande langue, une petite, tous les 14 px, qui
s'éteignent une à une comme les javelots de l'Onde de givre. Écartées : la double couronne,
le front serré de petites langues, les éclats projetés, les langues suivies de bouffées. Les
trois premières versions de la planche — bouffées, brûlures au sol, sol roussi — ne se
lisaient pas sur la terre et ont été remplacées avant d'être montrées.

**Captures** (`hns-captures-ruee`) : l'arbre ; l'onde du Bond qui s'étend et s'éteint ; les
deux explosions du Départ en trombe ; le serpent du Charmeur à l'arrivée ; la Mèche qui court
du départ vers l'arrivée. **Vu à la capture** : le paquet rendu résistant pour la capture
tuait le joueur avant l'extinction de la traînée — la capture le rend invulnérable.

**Le banc** (`only=flame_dash`), relevé avant → après, **sans rien corriger** :

| build | avant | après |
|---|---|---|
| meilleur au paquet | ×4,32 | ×6,31 |
| meilleur au duel | ×3,82 | **×17,0** |
| Bond au paquet | ×4,35 | ×9,03 |

Le duel est porté par **le Bond, l'Onde brûlante, la Seconde foulée et la Foulée de feu** :
deux bonds par recharge, dont un plus fort, chacun avec son onde. Jamais pris : Départ en
trombe, Charmeur, Danse du charmeur — le banc n'apprend pas le Serpent. Le Bond au paquet
prend la Mèche et la Mèche courte, qu'il ignore : des points restés sans meilleur usage.

## 10. Le manuel des flammes — clos sans l'Ignition

L'utilisateur : « pas besoin de faire ignition, je ne pense pas garder le spell à l'avenir ».
Son arbre reste tel quel.

**`UNIQUE_TREES` exempte les échanges entiers** (§2) : un nœud dont une ligne est une perte
(`StatMod.is_loss()`) n'est pas un second levier — le Pouls lent, le Phénix, Vif, Brûle-pavé.
Essayé avec le feu, le test ne relève plus qu'**une** ligne : les Cendres froides de
l'Ignition visent la brûlure subie, comme le Cœur tiède de l'Immolation. **Le feu entre dans
`UNIQUE_TREES` quand l'Ignition sort**, plutôt qu'une exception écrite pour un sort qui part.


## 11. Le Brasero, à la place de l'Ignition — la proposition

L'utilisateur : « remplacer l'Ignition par un nouveau skill avec son arbre complet ». Cinq
pistes proposées (mur de flammes, souffle canalisé, brasero, marque, éruption) ; retenu : le
**Brasero**, avec « un nœud qui transforme sa boule de feu en la Boule de feu du manuel, si
elle est allouée, et sans que Météore marche ».

**La compétence** : un sort, posé au point visé (`PLACEMENT_RANGE`). Un brasero planté au sol
crache une petite boule de feu vers l'ennemi le plus proche à 150 px, toutes les 0,9 s,
pendant 8 s. **Deux à la fois** par lanceur, le plus ancien s'éteint (la limite des
invocations). Niveau de manuel 12 et case (1, 1), ceux de l'Ignition. Premier réglage : 20 de
mana, 0,5 s d'incantation, 6 à 16 de dégâts par point.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Tisonnier | 4 | +8 % dégâts plus | — |
| Bûches | 3 | +20 % durée | — |
| Soufflet | 3 | −10 % intervalle des tirs | — |
| Vigie | 2 | +40 px de portée de visée | Soufflet (1) |
| **Salve** *(neuf)* | 2 | **+1 boule par tir**, en éventail vers la cible | Tisonnier (2) |
| **Batterie** ⇄ | 2 | **+1 brasero à la fois** ⇄ −15 % plus | Bûches (2) |
| **Feu sacré** *(neuf)* | 3 | **chaque ennemi que le brasero tue lui rend 0,5 s par point** | Bûches (1) ou Tisonnier (1) |
| **Phare** *(neuf)* | 1 | **les ennemis proches s'en prennent au brasero plutôt qu'à vous** : il a des PV (une part des vôtres) et tombe s'ils l'abattent — comme la Poupée de chiffon | Vigie (1) |
| **Dernier souffle** *(neuf)* | 2 | **à son extinction, il crache d'un coup une couronne de boules**, une par seconde qui lui restait à tirer, à 60 % par point | Bûches (2) |
| **Foyer du mage** 🔗 *(neuf)* | 1 | **ses boules deviennent votre Boule de feu**, si vous la savez lancer : vos points, votre arbre — Prise d'air, Fragmentation, Surchauffe… — **sans le Météore**, qui reste une boule. Le brasero n'y ajoute que son rythme et son nombre de tirs ⇄ ses propres nœuds de dégâts ne comptent plus | Salve (1) ou Tisonnier (3) |
| **Lanterne d'orage** | 1 | conversion à la foudre : des éclairs au lieu des boules | Soufflet (2) |
| ↳ **Main d'appoint** 🔗 *(neuf)* | 1 | **quand vous lancez la Boule de feu, chaque brasero en tire une avec vous**, vers votre visée | Foyer du mage (1) |
| ↳ **Triangulation** *(neuf)* | 1 | **deux braseros relient leurs flammes** : un trait de feu entre eux brûle ce qui le traverse | Batterie (1) |
| ↳ **Mitraille** *(neuf)* | 1 | les boules de la salve **rebondissent une fois** vers un autre ennemi | Salve (2) |
| ↳ **Brasier ravivé** *(neuf)* | 2 | chaque tué le fait **tirer aussitôt**, sans attendre son intervalle — une fois par seconde au plus, puis deux | Feu sacré (2) |
| ↳ **Électrisé** | 2 | la lanterne engourdit plus fort : +15 % d'effet de l'engourdi par point | Lanterne d'orage (1) |

**16 nœuds, 31 points**, pour un pool de 20.

**Les interactions** : le Foyer du mage et sa Main d'appoint font **trois arbres sur cinq** avec
une interaction (la Boule de feu par le Feu nourri, la Ruée par le Charmeur) — au-delà des deux
du §2. C'est la demande de l'utilisateur ; le Feu nourri ou le Charmeur pourraient céder la
place, à lui de dire.

**Ce que demande le moteur** : une forme neuve (la tourelle, sur le modèle du serpent pour la
limite et de la Poupée de chiffon pour les PV du Phare) ; « résoudre la Boule de feu sans sa
transformation » pour le Foyer du mage ; le dessin du brasero, **sur planche**. La boule, elle,
est celle de la forge.

**Ce qui part avec l'Ignition** : sa compétence, son arbre, ses références dans les tests et le
catalogue. Le feu entre alors dans `UNIQUE_TREES` (§10).

## 12. Le Brasero — livré

L'arbre du §11, **16 nœuds, 31 points** ; l'Ignition est partie, sa compétence, son arbre, son
icône et ses vingt traductions. Une vieille sauvegarde perd ses points d'Ignition sans erreur :
`Character._manual_from_dict()` ne garde que ce que le livre connaît, et ils reviennent à
placer.

```
                         Dernières braises
 Brasier ravivé  Feu sacré  Bûches   Batterie  Triangulation
 Mitraille  Salve  Tisonnier  [BRASERO]  Soufflet  Vigie  Phare
 Main d'appoint  Foyer du mage          Lanterne d'orage  Électrisé
```

**Choisis sur planche** :

- **le dessin**, `planche-brasero.png` (cinq silhouettes à côté de la sorcière) : le
  **trépied de fer** (`EffectForge.brazier()`), contre la vasque de pierre, la jarre fendue,
  le bûcher et la torchère ;
- **l'icône**, `planche-icone-brasero.png` : les quatre sujets de SDXL seul sortaient sur
  fond gris, la silhouette noyée. Refaits **sur calque** (`icon_layouts.brazier`, sur le
  cramoisi du feu), à `denoise` 0,7 — à 0,4 et 0,55, les aplats restaient plats à côté des
  icônes du manuel. Graine 777.

**Écarts avec la proposition** :

- **Dernier souffle devient Dernières braises** : le nom était déjà celui d'un nœud de la
  nécromancie.
- **Le Soufflet est un échange** (−15 % d'intervalle ⇄ −10 % de durée) : l'intervalle est
  déjà la ligne du Sifflement du serpent.
- **La Vigie a son propre nombre** (`sight`) : `seek_radius` est la ligne du Chasseur.
- **Les boules du Brasero ont l'explosion des étincelles** (`SPARK_RADIUS`), plus un rayon
  de la compétence : la fiche du Brasero, la plus haute du jeu, sortait du cadrage de 23 px.
- **La fiche écrit l'écart sur la ligne des projectiles** (« 2 · 8° ») : la ligne qui
  manquait encore, pour toutes les compétences à plusieurs projectiles. Trois assertions de
  `test_manual_panel` lisent ce format.
- **Le Brasero porte `projectile`** (`KEYWORD_OF_SHAPE`) : la Salve et la Mitraille sont
  `projectiles` et `bounces`, que l'étincelle lit déjà.

**Vu en route** : retirer les nœuds de l'Ignition a emporté la ligne de rayon du Noyau
dense, collée sans ligne vide derrière le dernier d'entre eux — `test_talents` ne l'a pas
vu, le chargement du manuel si. Rendue (−75 % « moins », §6).

**`UNIQUE_TREES` compte le feu** (§10) : ses cinq arbres ne partagent plus ni nom ni ligne.

**Captures** (`hns-captures-brasero`) : l'arbre ; deux braseros reliés par le trait de la
Triangulation, que les ennemis frappent sous le Phare ; sous le Foyer du mage, le brasero
tire de vraies Boules de feu, et la Main d'appoint en ajoute une au Météore du joueur.

**Le banc** (`only=brazier`), relevé **sans rien corriger** :

| build | paquet | duel |
|---|---|---|
| sans arbre | 31/s | 31/s |
| meilleur au paquet | ×32,4 | ×26,6 |
| meilleur au duel | ×23,3 | ×30,3 |

Les deux portent la **Batterie et la Triangulation** : chaque brasero relance un trait de
feu à pleine force, et le banc relance sans cesse. Jamais pris : Vigie, Phare, Dernières
braises (le banc ne voit ni la portée, ni les coups reçus, ni les fins), Foyer du mage et
Main d'appoint (il n'apprend pas la Boule de feu).

## 13. Les retours sur le Brasero

1. **Ses boules ne font plus de dégâts de zone** : `Fireball.spark(…, burst = false)`, la
   touche directe seule — les Dernières braises aussi. Une `Fireball` sans rayon n'explose
   plus.
2. **Le trait de la Triangulation s'éteint avec le premier de ses deux braseros**, remplacé,
   abattu ou consumé : chacun le garde et l'éteint en partant. Avant, il durait jusqu'à la
   fin prévue du premier, sans voir le Feu sacré ni le Phare.
3. **Le Foyer du mage a un prix** : chaque tir paie le mana de la Boule de feu — Main
   d'appoint comprise —, et à court, rien ne part ; le brasero retente au pas suivant.
4. **La Mitraille ne marchait pas sous le Foyer**, et la Salve non plus : la boule tirée
   était celle du joueur, sans les nœuds du brasero. Elles s'y ajoutent désormais — des
   boules en plus, en éventail, et un rebond. Ses nœuds de dégâts, non.

Le banc (`only=brazier`), relevé après : **×19,4 au paquet, ×15,0 au duel** (×32,4 et ×30,3
au §12). Le trait qui s'éteint avec son brasero et la fin des éclaboussures en ont repris
la moitié ; la Triangulation reste dans tous les meilleurs builds.
