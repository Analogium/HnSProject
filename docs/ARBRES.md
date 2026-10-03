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
le rapport à la compétence sans arbre, dans la même scène. Ce qui ne frappe pas —
les buffs, la Malédiction putride — n'est pas mesuré : ce qu'ils valent se lit sur une
autre compétence. Ce que le banc ne voit pas — ralentir, tirer, esquiver,
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
| sans arbre | — | 149/s | 87,1/s |
| meilleur au paquet | Mue 4, Couvée 2, Hydre 1, Crocs 2, Longue vie 3, Queue de flammes 3, Vif 1, Mue explosive 3 | 1151/s ×7,74 | 560/s ×6,43 |
| meilleur au duel | Crocs 2, Mue 4, Couvée 2, Longue vie 3, Hydre 1, Chasseur 1 | 797/s ×5,35 | 622/s ×7,14 |
| Venin au paquet (conversion) | Crocs 2, Venin 1, Mue 4, Couvée 2, Hydre 1, Longue vie 3, Queue de flammes 3, Vif 1, Mue explosive 3 | 1125/s ×7,56 | 582/s ×6,68 |
| Venin au duel (conversion) | Crocs 2, Venin 1, Mue 4, Couvée 2, Longue vie 3, Hydre 1, Queue de flammes 3 | 1110/s ×7,46 | 627/s ×7,20 |

Jamais pris : aucun.

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

## Manuel de magie nécrotique

### Peste

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 90,2/s | 96,4/s |
| meilleur au paquet | Fléau rampant 2, Fléaux jumeaux 2, Virulence 5, Incubation 4, Bubons 3 | 1125/s ×12,5 | 445/s ×4,62 |
| meilleur au duel | Fléau rampant 2, Fléaux jumeaux 2, Virulence 5, Incubation 4 | 726/s ×8,05 | 445/s ×4,62 |
| Nuée au paquet (transformation) | Virulence 5, Nuée 1, Fléau rampant 2, Fléaux jumeaux 2, Incubation 2, Bubons 3 | 1542/s ×17,1 | 941/s ×9,76 |
| Nuée au duel (transformation) | Virulence 5, Nuée 1, Fléau rampant 2, Fléaux jumeaux 2, Incubation 4 | 1456/s ×16,1 | 948/s ×9,84 |

Jamais pris : Condamnation, Contagion.

### Relève

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 56,7/s | 60,3/s |
| meilleur au paquet | Moelle 5, Colosse d'os 1, Frénésie 3 | 292/s ×5,15 | 168/s ×2,78 |
| meilleur au duel | Légion d'os 1, Moelle 5, Frénésie 3, Guet 3 | 182/s ×3,21 | 201/s ×3,33 |

Jamais pris : Ossature, Rempart d'os, Dernier souffle.

### Déferlante toxique

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 89,4/s | 37,5/s |
| meilleur au paquet | Miasme 3, Marais 3, Caustique 5, Haleine fétide 4, Dessiccation 3 | 815/s ×9,13 | 141/s ×3,75 |
| meilleur au duel | Haleine fétide 2, Dessiccation 3, Caustique 5, Miasme 1, Marais 3, Asphyxie 4 | 413/s ×4,62 | 144/s ×3,83 |
| Haleine au paquet (transformation) | Miasme 3, Haleine 1, Caustique 5, Haleine fétide 4, Dessiccation 3, Asphyxie 4 | 610/s ×6,82 | 97,5/s ×2,60 |
| Haleine au duel (transformation) | Miasme 2, Haleine 1, Haleine fétide 2, Dessiccation 3, Caustique 5, Asphyxie 4 | 276/s ×3,09 | 97,5/s ×2,60 |

Jamais pris : aucun.

### Porte pourrissante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 87,3/s | 45,5/s |
| meilleur au paquet | Couvée 4, Essaim 5, Boursouflure 3, Progéniture 3, Rampants véloces 3 | 726/s ×8,32 | 303/s ×6,67 |
| meilleur au duel | Essaim 5, Boursouflure 1, Progéniture 3, Couvée 4 | 530/s ×6,07 | 303/s ×6,67 |
| Nid porté au paquet (transformation) | Couvée 4, Nid porté 1, Essaim 5, Boursouflure 3, Progéniture 3, Rampants véloces 1, Flair 3 | 499/s ×5,72 | 253/s ×5,56 |
| Nid porté au duel (transformation) | Couvée 4, Nid porté 1, Essaim 5, Boursouflure 1, Progéniture 3, Rampants véloces 1, Flair 3 | 361/s ×4,14 | 253/s ×5,56 |

Jamais pris : aucun.

