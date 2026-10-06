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
| meilleur au paquet | Attisement 3, Météore 1, Chute libre 1, Souffle ardent 1, Étincelles 3, Réaction en chaîne 1, Vélocité 2, Double langue 1, Convergence 1, Noyau dense 1, Surchauffe 3, Fragmentation 2 | 3450/s ×23,5 | 862/s ×6,88 |
| meilleur au duel | Attisement 4, Noyau dense 1, Surchauffe 3, Vélocité 2, Double langue 2, Météore 1, Chute libre 1, Fragmentation 3, Ardeur 2, Étincelles 1 | 1816/s ×12,4 | 1513/s ×12,1 |
| Givre au paquet (conversion) | Attisement 3, Ardeur 1, Givre 1, Météore 1, Chute libre 1, Étincelles 3, Réaction en chaîne 1, Vélocité 2, Double langue 1, Convergence 1, Noyau dense 1, Surchauffe 3 | 3450/s ×23,5 | 801/s ×6,39 |
| Givre au duel (conversion) | Attisement 4, Ardeur 2, Givre 1, Noyau dense 1, Vélocité 2, Double langue 2, Surchauffe 3, Météore 1, Chute libre 1, Fragmentation 3 | 1816/s ×12,4 | 1442/s ×11,5 |
| Météore au paquet (transformation) | Attisement 3, Météore 1, Chute libre 1, Souffle ardent 1, Étincelles 3, Réaction en chaîne 1, Vélocité 2, Double langue 1, Convergence 1, Noyau dense 1, Surchauffe 3, Fragmentation 2 | 3450/s ×23,5 | 862/s ×6,88 |
| Météore au duel (transformation) | Attisement 4, Météore 1, Noyau dense 1, Chute libre 1, Vélocité 2, Double langue 2, Surchauffe 3, Fragmentation 3, Ardeur 2, Étincelles 1 | 1816/s ×12,4 | 1513/s ×12,1 |

Jamais pris : Perforation, Prise d'air, Feu nourri, Pluie de météorites, Gel intense, Éclats en cascade, Poudrière.

### Serpent infernal

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 128/s | 98,0/s |
| meilleur au paquet | Crocs 1, Chasseur 1, Queue de flammes 3, Mue 4, Sifflement 3, Crachat 1, Gerbe 2 | 520/s ×4,07 | 291/s ×2,97 |
| meilleur au duel | Crocs 2, Chasseur 1, Constriction 1, Mue 4, Sifflement 3, Crachat 2, Gerbe 2, Queue de flammes 3 | 395/s ×3,10 | 1030/s ×10,5 |
| Venin au paquet (conversion) | Crocs 2, Venin 1, Chasseur 1, Queue de flammes 3, Sifflement 1, Crachat 1, Gerbe 2 | 464/s ×3,64 | 191/s ×1,95 |
| Venin au duel (conversion) | Crocs 2, Venin 1, Chasseur 1, Constriction 1, Mue 4, Sifflement 3, Crachat 2, Gerbe 2, Queue de flammes 3, Gloutonnerie 1 | 396/s ×3,10 | 1027/s ×10,5 |

Jamais pris : Longue vie, Vif, Couvée, Hydre, Ouroboros, Spirale, Étau, Mue de croissance, Venin d'hydre, Morsure nécrosante.

### Immolation

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 95,6/s | 42,4/s |
| meilleur au paquet | Brasier 4, Feu de camp 3, Escarbilles 3, Cœur tiède 2, Phénix 1, Fournaise 5, Brûlure profonde 2 | 767/s ×8,03 | 124/s ×2,93 |
| meilleur au duel | Cœur tiède 2, Phénix 1, Brasier 2, Feu de camp 3, Fournaise 5, Pouls lent 2, Tirage 2, Œil du brasier 2, Brûlure profonde 1 | 413/s ×4,33 | 177/s ×4,18 |
| Flamme noire au paquet (conversion) | Fournaise 2, Pouls lent 2, Flamme noire 1, Feu de camp 3, Brasier 4, Cœur tiède 2, Phénix 1, Escarbilles 3 | 725/s ×7,59 | 103/s ×2,42 |
| Flamme noire au duel (conversion) | Fournaise 5, Pouls lent 2, Flamme noire 1, Feu de camp 3, Cœur tiède 2, Phénix 1 | 270/s ×2,83 | 124/s ×2,92 |

Jamais pris : Offrandes, Fonte, Renaissance, Cendres du phénix, Veillée, Âmes consumées.

### Ruée ardente

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 83,6/s | 15,5/s |
| meilleur au paquet | Sillage 3, Braises 3, Brûle-pavé 2, Élan 2, Mèche 3, Bûcher 4, Tison 2, Seconde foulée 1 | 527/s ×6,31 | 129/s ×8,28 |
| meilleur au duel | Élan 2, Atterrissage 1, Bond 1, Onde brûlante 2, Seconde foulée 1, Foulée de feu 2, Bûcher 4, Tison 2 | 202/s ×2,41 | 263/s ×17,0 |
| Bond au paquet (transformation) | Élan 2, Atterrissage 3, Bond 1, Seconde foulée 1, Onde brûlante 2, Onde de choc 2, Sillage 1, Brûle-pavé 1, Mèche 1, Mèche courte 1 | 754/s ×9,03 | 119/s ×7,67 |
| Bond au duel (transformation) | Élan 2, Atterrissage 1, Bond 1, Seconde foulée 1, Onde brûlante 2, Foulée de feu 2, Bûcher 4, Tison 2 | 202/s ×2,41 | 263/s ×17,0 |

Jamais pris : Départ en trombe, Charmeur, Danse du charmeur.

### Brasero

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 31,0/s | 31,2/s |
| meilleur au paquet | Tisonnier 4, Salve 2, Mitraille 1, Soufflet 3, Bûches 2, Batterie 2, Triangulation 1, Lanterne d'orage 1, Électrisé 2, Vigie 1, Phare 1 | 602/s ×19,4 | 468/s ×15,0 |
| meilleur au duel | Tisonnier 4, Salve 2, Soufflet 3, Bûches 2, Batterie 2, Triangulation 1, Lanterne d'orage 1, Électrisé 2 | 348/s ×11,2 | 468/s ×15,0 |
| Lanterne d'orage au paquet (conversion) | Soufflet 3, Lanterne d'orage 1, Tisonnier 4, Salve 2, Mitraille 1, Bûches 2, Batterie 2, Triangulation 1, Électrisé 2, Vigie 1, Phare 1 | 602/s ×19,4 | 468/s ×15,0 |
| Lanterne d'orage au duel (conversion) | Soufflet 3, Lanterne d'orage 1, Tisonnier 4, Salve 2, Bûches 2, Batterie 2, Triangulation 1, Électrisé 2 | 348/s ×11,2 | 468/s ×15,0 |

Jamais pris : Feu sacré, Dernières braises, Foyer du mage, Main d'appoint, Brasier ravivé.

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

## Manuel du chevalier

### Frappe lourde

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 85,7/s | 80,7/s |
| meilleur au paquet | Élan 5, Brise-sol 1, Cratère 3, Pesée 3 | 409/s ×4,77 | 111/s ×1,38 |
| meilleur au duel | Élan 5 | 216/s ×2,52 | 152/s ×1,89 |
| Lame ardente au paquet (conversion) | Élan 5, Lame ardente 1, Brise-sol 1, Cratère 3, Pesée 3 | 539/s ×6,28 | 185/s ×2,30 |
| Lame ardente au duel (conversion) | Élan 5, Lame ardente 1, Pesée 3 | 262/s ×3,06 | 192/s ×2,38 |
| Brise-sol au paquet (transformation) | Élan 5, Brise-sol 1, Cratère 3, Pesée 3 | 409/s ×4,77 | 111/s ×1,38 |
| Brise-sol au duel (transformation) | Élan 5, Brise-sol 1 | 208/s ×2,42 | 111/s ×1,38 |

Jamais pris : Coup de bélier, Hargne.

### Coup en croix

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 84,8/s | 82,7/s |
| meilleur au paquet | Taille 5, Plaie ouverte 3, Estoc 3, Entaille 3, Hémorragie 3, Gerbe de sang 3 | 692/s ×8,16 | 458/s ×5,53 |
| meilleur au duel | Taille 5, Plaie ouverte 3, Estoc 3, Entaille 3, Hémorragie 4 | 443/s ×5,23 | 460/s ×5,56 |
| Lame sainte au paquet (conversion) | Taille 5, Lame sainte 1, Estoc 3, Plaie ouverte 3, Entaille 3, Hémorragie 2, Gerbe de sang 3 | 615/s ×7,25 | 439/s ×5,30 |
| Lame sainte au duel (conversion) | Taille 5, Lame sainte 1, Plaie ouverte 3, Estoc 3, Entaille 1, Hémorragie 4 | 441/s ×5,20 | 440/s ×5,32 |

Jamais pris : aucun.

### Épée spirale

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 38,6/s | 20,7/s |
| meilleur au paquet | Tranchant 5, Volée d'épées 1, Ronde 3 | 192/s ×4,98 | 94,1/s ×4,55 |
| meilleur au duel | Tranchant 5, Volée d'épées 1, Ronde 3, Arsenal 3 | 189/s ×4,90 | 109/s ×5,28 |

Jamais pris : Endurance, Bouclier de lames, Orbite large.

### Vague tranchante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 150/s | 64,8/s |
| meilleur au paquet | Fil de l'arc 5, Vagues jumelles 3, Grand arc 4, Course 4 | 1204/s ×8,03 | 318/s ×4,90 |
| meilleur au duel | Fil de l'arc 5, Vagues jumelles 3, Course 1, Sillon d'acier 4 | 934/s ×6,23 | 319/s ×4,92 |
| Ressac au paquet (transformation) | Course 4, Ressac 1, Fil de l'arc 5, Vagues jumelles 3, Grand arc 4 | 1644/s ×11,0 | 410/s ×6,33 |
| Ressac au duel (transformation) | Course 2, Ressac 1, Fil de l'arc 5, Vagues jumelles 3 | 1074/s ×7,16 | 413/s ×6,37 |

Jamais pris : aucun.

### Cyclone

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 48,3/s | 20,5/s |
| meilleur au paquet | Fauchage 5, Envergure 3, Tourbillon 3, Moulinet 3 | 150/s ×3,10 | 55,1/s ×2,69 |
| meilleur au duel | Fauchage 5, Moulinet 3 | 81,5/s ×1,69 | 55,1/s ×2,69 |

Jamais pris : Souffle long, Fauche vorace.

### Ruée tranchante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 27,7/s | 9,07/s |
| meilleur au paquet | Andain 3, Choc d'arrivée 4, Fil tranchant 5, Charge 4, Lame traînante 3 | 207/s ×7,47 | 122/s ×13,4 |
| meilleur au duel | Andain 1, Lame traînante 3, Fil tranchant 5, Charge 4, Choc d'arrivée 4 | 202/s ×7,32 | 122/s ×13,4 |
| Saut de guerre au paquet (transformation) | Fil tranchant 2, Saut de guerre 1, Andain 1, Choc d'arrivée 4 | 107/s ×3,87 | 12,4/s ×1,37 |
| Saut de guerre au duel (transformation) | Fil tranchant 5, Saut de guerre 1, Charge 4 | 68,4/s ×2,47 | 29,1/s ×3,21 |

Jamais pris : Enchaînement.

## Manuel sacré

### Frappe sacrée

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 113/s | 39,9/s |
| meilleur au paquet | Allonge du trait 1, Réfraction 2, Percée 5, Réprobation 3 | 363/s ×3,21 | 101/s ×2,52 |
| meilleur au duel | Percée 5, Réprobation 3 | 191/s ×1,69 | 101/s ×2,52 |
| Croix de lumière au paquet (transformation) | Percée 5, Croix de lumière 1, Allonge du trait 3, Réfraction 2 | 476/s ×4,20 | 63,9/s ×1,60 |
| Croix de lumière au duel (transformation) | Percée 5, Croix de lumière 1, Réprobation 3 | 161/s ×1,42 | 101/s ×2,52 |

Jamais pris : Sanctification, Bénédiction profonde.

### Pilier sacré

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 126/s | 74,1/s |
| meilleur au paquet | Colonne 3, Veille 4, Jugement 1, Glas 3, Effondrement 3 | 637/s ×5,08 | 221/s ×2,99 |
| meilleur au duel | Veille 4, Jugement 5, Glas 3, Effondrement 3 | 370/s ×2,95 | 316/s ×4,27 |
| Pilier errant au paquet (transformation) | Jugement 5, Pilier errant 1, Colonne 3, Veille 4, Glas 3, Effondrement 3 | 1038/s ×8,27 | 316/s ×4,27 |
| Pilier errant au duel (transformation) | Jugement 5, Pilier errant 1, Veille 4, Glas 3, Effondrement 3 | 581/s ×4,63 | 316/s ×4,27 |

Jamais pris : Appel céleste.

### Pulsation sacrée

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 108/s | 24,0/s |
| meilleur au paquet | Litanie 4, Ferveur 1, Cantique 3 | 238/s ×2,20 | 67,7/s ×2,83 |
| meilleur au duel | Litanie 4, Exaltation 3, Ferveur 5, Cantique 3 | 358/s ×3,32 | 145/s ×6,06 |

Jamais pris : Rayonnement, Absolution.

## Manuel de la sorcière

### Projectile élémentaire

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 97,2/s | 111/s |
| meilleur au paquet | Fulgurance 4, Ricochet 2, Prisme 2, Arcanes 5, Affinité croisée 3, Électrochoc 4 | 807/s ×8,30 | 602/s ×5,40 |
| meilleur au duel | Fulgurance 1, Ricochet 1, Prisme 2, Arcanes 5, Affinité croisée 3, Électrochoc 4 | 507/s ×5,21 | 602/s ×5,40 |
| Triade au paquet (transformation) | Arcanes 5, Triade 1, Affinité croisée 3, Électrochoc 4 | 363/s ×3,74 | 259/s ×2,32 |
| Triade au duel (transformation) | Arcanes 5, Triade 1, Affinité croisée 3, Électrochoc 4 | 363/s ×3,74 | 259/s ×2,32 |

Jamais pris : aucun.

### Catalyse

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 372/s | 54,0/s |
| meilleur au paquet | Concentré 5, Amorce 1, Grand cercle 3, Exothermie 4, Nappe brûlante 3 | 1816/s ×4,87 | 271/s ×5,01 |
| meilleur au duel | Concentré 5, Amorce 1, Exothermie 4, Nappe brûlante 3 | 1159/s ×3,11 | 271/s ×5,01 |

Jamais pris : Arc fourchu, Conductivité.

### Poupée de chiffon

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 82,1/s | 18,5/s |
| meilleur au paquet | Appeau 2, Jumelles 1, Bourre de poudre 5 | 121/s ×1,47 | 27,8/s ×1,50 |
| meilleur au duel | Bourre de poudre 5 | 80,5/s ×0,98 | 27,8/s ×1,50 |

Jamais pris : Rembourrage, Rancune, Transfert.

