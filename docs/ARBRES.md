# Banc des arbres

<!-- Fichier généré par tools/balance.sh trees — ne pas éditer à la main. -->

Chaque compétence de dégâts des manuels repris, lancée sans relâche sur des cibles
immobiles par les vraies fonctions du jeu (`BenchTrees`) : **paquet**, 9 grunts de
zone 40 qui renaissent à leur mort ; **duel**, une cible qui ne meurt pas. Au contact
(24 px) ou au point visé (140 px), la meilleure des deux. Dégâts par seconde après
défenses, brûlures comprises, sur 12 s après 6 s de chauffe, avec la réserve du Sort
« Équipé » de zone 40 : 380 mana et 11,3/s. Compétence à 5 points, arbre à 20.

Les builds sont **cherchés** et non écrits : à chaque pas, le nœud — avec le chemin le
moins cher qui l'ouvre — qui rend le plus par point dans la scène visée. Une
transformation ou une conversion est prise d'abord, puis la recherche reprend. ×N :
le rapport à la compétence sans arbre, dans la même scène. Les buffs (Ignition,
Électricité statique, Tombeau de glace) ne sont pas mesurés : ce qu'ils valent se lit
sur une autre compétence. Ce que le banc ne voit pas — ralentir, tirer, esquiver,
survivre — ne rend rien ici.

## Manuel des flammes

### Boule de feu

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 147/s | 125/s |
| meilleur au paquet | Vélocité 2, Perforation 2, Double langue 2, Souffle ardent 3, Fragmentation 3 | 1816/s ×12,4 | 280/s ×2,23 |
| meilleur au duel | Vélocité 2, Double langue 2, Attisement 4, Souffle ardent 1, Braises dispersées 3, Ardeur 2, Étincelles 3 | 733/s ×5,00 | 425/s ×3,39 |
| Givre au paquet (conversion) | Attisement 4, Ardeur 1, Givre 1, Vélocité 2, Perforation 2, Double langue 2, Souffle ardent 3, Braises dispersées 3, Fragmentation 2 | 1816/s ×12,4 | 386/s ×3,08 |
| Givre au duel (conversion) | Attisement 4, Ardeur 2, Givre 1, Vélocité 2, Double langue 2, Souffle ardent 1, Braises dispersées 3 | 657/s ×4,48 | 397/s ×3,17 |
| Météore au paquet (transformation) | Attisement 4, Météore 1, Vélocité 2, Double langue 2, Souffle ardent 1, Étincelles 3, Réaction en chaîne 1, Braises dispersées 3, Ardeur 2 | 1807/s ×12,3 | 357/s ×2,85 |
| Météore au duel (transformation) | Attisement 4, Météore 1, Vélocité 2, Double langue 2, Fragmentation 3, Souffle ardent 1, Braises dispersées 3, Ardeur 2, Étincelles 2 | 1243/s ×8,48 | 488/s ×3,89 |

Jamais pris : aucun.

### Serpent infernal

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 91,3/s | 103/s |
| meilleur au paquet | Mue 2, Couvée 2, Hydre 1, Crocs 2, Longue vie 3, Vif 2 | 1066/s ×11,7 | 262/s ×2,54 |
| meilleur au duel | Mue 4, Couvée 2, Crocs 2, Hydre 1, Longue vie 3, Queue de flammes 3 | 1031/s ×11,3 | 620/s ×6,00 |
| Venin au paquet (conversion) | Crocs 2, Venin 1, Mue 4, Couvée 2, Hydre 1, Longue vie 3, Queue de flammes 3 | 1097/s ×12,0 | 599/s ×5,79 |
| Venin au duel (conversion) | Crocs 2, Venin 1, Mue 4, Couvée 2, Hydre 1, Longue vie 3, Vif 1, Mue explosive 3 | 1173/s ×12,8 | 622/s ×6,01 |

Jamais pris : Chasseur.

### Immolation

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 95,6/s | 42,4/s |
| meilleur au paquet | Brasier 4, Cœur tiède 2, Phénix 1, Fournaise 5, Contagion ardente 1, Cendres vivantes 3, Pouls lent 2, Étincelles 2 | 518/s ×5,42 | 96,7/s ×2,28 |
| meilleur au duel | Cœur tiède 2, Phénix 1, Fournaise 5, Pouls lent 2 | 182/s ×1,91 | 96,7/s ×2,28 |
| Flamme noire au paquet (conversion) | Fournaise 2, Pouls lent 2, Flamme noire 1, Brasier 4, Cœur tiède 2, Phénix 1, Contagion ardente 1, Cendres vivantes 3 | 476/s ×4,98 | 70,7/s ×1,67 |
| Flamme noire au duel (conversion) | Fournaise 5, Pouls lent 2, Flamme noire 1, Cœur tiède 2, Phénix 1 | 175/s ×1,83 | 85,4/s ×2,02 |

Jamais pris : aucun.

### Ruée ardente

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 83,6/s | 15,5/s |
| meilleur au paquet | Sillage 3, Braises 3, Brûle-pavé 2, Élan 2, Bûcher 2, Tison 2, Étincelles 3 | 361/s ×4,32 | 50,1/s ×3,23 |
| meilleur au duel | Sillage 3, Élan 2, Bûcher 4, Tison 2, Brûle-pavé 2, Atterrissage 3, Étincelles 3 | 47,3/s ×0,57 | 59,3/s ×3,82 |
| Bond au paquet (transformation) | Élan 2, Atterrissage 3, Bond 1, Onde de choc 2, Bûcher 4 | 363/s ×4,35 | 63,3/s ×4,08 |
| Bond au duel (transformation) | Élan 2, Atterrissage 1, Bond 1, Bûcher 4, Tison 2 | 89,0/s ×1,06 | 68,3/s ×4,40 |

Jamais pris : aucun.

## Manuel de la foudre

### Éclair vif

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 102/s | 122/s |
| meilleur au paquet | Célérité 1, Transpercement 2, Surcharge 4, Fourche 2, Éclats 2, Rebond 3, Étincelles 3, Surtension 1 | 1211/s ×11,9 | 370/s ×3,03 |
| meilleur au duel | Surcharge 4, Fourche 2, Point chaud 3 | 262/s ×2,58 | 383/s ×3,13 |
| Trait de glace au paquet (conversion) | Surcharge 2, Trait de glace 1, Fourche 2, Rebond 3, Célérité 1, Transpercement 2, Éclats 2, Étincelles 3, Surtension 1 | 1273/s ×12,5 | 355/s ×2,90 |
| Trait de glace au duel (conversion) | Surcharge 4, Trait de glace 1, Fourche 2, Point chaud 3 | 262/s ×2,58 | 418/s ×3,42 |
| Orbe statique au paquet (transformation) | Point chaud 3, Orbe statique 1, Surcharge 4, Fourche 2, Étincelles 3 | 1032/s ×10,2 | 443/s ×3,63 |
| Orbe statique au duel (transformation) | Point chaud 3, Orbe statique 1, Surcharge 4, Fourche 2 | 1011/s ×9,95 | 443/s ×3,63 |

Jamais pris : aucun.

### Chaîne d'éclairs

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 155/s | 60,6/s |
| meilleur au paquet | Ramification 2, Crescendo 3, Réflexe 2, Foudre au bout 3, Haute tension 4, Court-circuit 1, Étincelles 3, Surtension 1, Point chaud 1 | 979/s ×6,30 | 134/s ×2,20 |
| meilleur au duel | Haute tension 4, Court-circuit 1, Réflexe 2 | 206/s ×1,33 | 134/s ×2,20 |
| Toile d'arcs au paquet (transformation) | Ramification 2, Toile d'arcs 1, Réflexe 2, Arc tendu 1, Foudre au bout 3, Haute tension 4, Court-circuit 1, Étincelles 3, Surtension 1, Point chaud 2 | 957/s ×6,16 | 140/s ×2,31 |
| Toile d'arcs au duel (transformation) | Ramification 2, Toile d'arcs 1, Haute tension 4, Court-circuit 1, Réflexe 2 | 355/s ×2,28 | 140/s ×2,31 |

Jamais pris : aucun.

### Nuage d'orage

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 89,4/s | 78,8/s |
| meilleur au paquet | Orage durable 3, Orage errant 1, Front orageux 3, Cumulonimbus 4, Averse 2, Coup de tonnerre 3, Point chaud 3, Étincelles 1 | 714/s ×7,99 | 228/s ×2,89 |
| meilleur au duel | Orage durable 3, Cumulonimbus 4, Averse 2, Coup de tonnerre 3, Point chaud 3 | 229/s ×2,56 | 228/s ×2,89 |
| Grêle au paquet (conversion) | Cumulonimbus 4, Grêle 1, Orage durable 3, Orage errant 1, Front orageux 3, Averse 2, Coup de tonnerre 3 | 684/s ×7,65 | 201/s ×2,55 |
| Grêle au duel (conversion) | Cumulonimbus 4, Grêle 1, Orage durable 3, Averse 2, Coup de tonnerre 3, Point chaud 3 | 228/s ×2,55 | 207/s ×2,63 |
| Orage portatif au paquet (transformation) | Orage durable 3, Orage portatif 1, Front orageux 3, Cumulonimbus 1, Averse 2, Point chaud 3, Étincelles 3 | 629/s ×7,03 | 203/s ×2,57 |
| Orage portatif au duel (transformation) | Orage durable 3, Orage portatif 1, Cumulonimbus 4, Averse 2, Coup de tonnerre 3, Point chaud 3 | 276/s ×3,09 | 266/s ×3,37 |

Jamais pris : aucun.

### Ruée d'orage

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 0,00/s | 0,00/s |
| meilleur au paquet | Élan 2, Coup de tonnerre 3 | 54,4/s | 17,1/s |
| meilleur au duel | Élan 2, Coup de tonnerre 3, Sillage statique 2, Étincelles 3 | 51,5/s | 20,7/s |

Jamais pris : Persistance, Foulée, Réflexes, Insaisissable, Sans répit.

## Manuel du froid

### Pics de glace

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 61,1/s | 32,7/s |
| meilleur au paquet | Réflexe 3, Tranchant 4, Éclats 2, Engelure 3, Froid mordant 1, Acharnement 3, Bris 1, Poussée 1, Givre persistant 2 | 225/s ×3,68 | 94,5/s ×2,89 |
| meilleur au duel | Réflexe 3, Poussée 1, Givre persistant 2, Tranchant 4, Engelure 3, Froid mordant 1, Acharnement 3 | 159/s ×2,61 | 94,5/s ×2,89 |
| Sillon de glace au paquet (transformation) | Poussée 2, Sillon de glace 1, Tranchant 4, Éclats 2, Engelure 2, Froid mordant 1, Acharnement 3, Réflexe 3, Givre persistant 2 | 227/s ×3,72 | 92,9/s ×2,84 |
| Sillon de glace au duel (transformation) | Poussée 2, Sillon de glace 1, Tranchant 4, Éclats 2, Réflexe 3, Engelure 1, Froid mordant 1, Acharnement 3, Givre persistant 2 | 206/s ×3,38 | 92,9/s ×2,84 |

Jamais pris : aucun.

### Nova de glace

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 54,6/s | 26,1/s |
| meilleur au paquet | Souffle 3, Givre persistant 2, Morsure 4, Réflexe 2, Froid mordant 1, Acharnement 3, Engelure 3, Bris 1 | 335/s ×6,14 | 69,4/s ×2,66 |
| meilleur au duel | Souffle 2, Givre persistant 2, Froid mordant 1, Acharnement 3, Morsure 4, Engelure 3 | 234/s ×4,29 | 72,3/s ×2,77 |
| Onde de givre au paquet (transformation) | Souffle 3, Onde de givre 1, Réflexe 2, Morsure 4, Froid mordant 1, Acharnement 3, Engelure 3, Bris 1 | 363/s ×6,66 | 36,0/s ×1,38 |
| Onde de givre au duel (transformation) | Souffle 2, Onde de givre 1, Réflexe 2, Morsure 4, Froid mordant 1, Acharnement 3 | 279/s ×5,11 | 36,0/s ×1,38 |

Jamais pris : aucun.

### Désastre hivernal

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 64,3/s | 37,0/s |
| meilleur au paquet | Blizzard 2, Bourrasque 3, Avalanche 3, Œil du cyclone 4, Rafales 2, Engelure 3, Bris 1 | 240/s ×3,74 | 84,8/s ×2,29 |
| meilleur au duel | Blizzard 2, Œil du cyclone 4, Rafales 2, Avalanche 3 | 83,6/s ×1,30 | 84,8/s ×2,29 |
| Implosion au paquet (transformation) | Blizzard 2, Avalanche 1, Implosion 1, Œil du cyclone 4, Rafales 2, Bourrasque 3 | 232/s ×3,61 | 89,1/s ×2,41 |
| Implosion au duel (transformation) | Blizzard 2, Avalanche 1, Implosion 1, Œil du cyclone 4, Rafales 2, Bourrasque 3 | 232/s ×3,61 | 89,1/s ×2,41 |

Jamais pris : Aspiration, Froid mordant.

