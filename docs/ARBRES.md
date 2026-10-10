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
| meilleur au paquet | Point chaud 3, Orbe statique 1, Orbe chargé 2, Surcharge 4, Fourche 2, Emballement 3, Trait de glace 1, Glace vive 3, Plein régime 1 | 1743/s ×17,2 | 852/s ×6,97 |
| meilleur au duel | Surcharge 4, Fourche 2, Emballement 3, Plein régime 1, Trait de glace 1, Glace vive 3, Point chaud 3 | 601/s ×5,91 | 1201/s ×9,83 |
| Trait de glace au paquet (conversion) | Surcharge 4, Trait de glace 1, Point chaud 3, Orbe statique 1, Orbe chargé 2, Fourche 2, Emballement 3, Plein régime 1 | 1743/s ×17,2 | 852/s ×6,97 |
| Trait de glace au duel (conversion) | Surcharge 4, Trait de glace 1, Fourche 2, Emballement 3, Plein régime 1, Glace vive 3, Point chaud 3 | 601/s ×5,91 | 1201/s ×9,83 |
| Orbe statique au paquet (transformation) | Point chaud 3, Orbe statique 1, Surcharge 4, Fourche 2, Orbe chargé 2, Emballement 3, Trait de glace 1, Glace vive 3, Plein régime 1 | 1743/s ×17,2 | 852/s ×6,97 |
| Orbe statique au duel (transformation) | Point chaud 3, Orbe statique 1, Surcharge 4, Fourche 2, Emballement 3, Plein régime 1, Trait de glace 1, Glace vive 3 | 1323/s ×13,0 | 852/s ×6,97 |

Jamais pris : Célérité, Transpercement, Rebond, Esquilles, Paratonnerre, Électrocution, Foudre héritée, Cible de l'orage, Carambolage, Satellite.

### Chaîne d'éclairs

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 155/s | 60,6/s |
| meilleur au paquet | Ramification 2, Toile d'arcs 1, Ramure 2, Vif-argent 2, Haute tension 4, Fourmillements 3, Surtension 1, Court-circuit 1 | 817/s ×5,26 | 140/s ×2,31 |
| meilleur au duel | Haute tension 4, Court-circuit 1, Vif-argent 2, Toile d'arcs 1, Ramure 2 | 357/s ×2,30 | 140/s ×2,31 |
| Toile d'arcs au paquet (transformation) | Ramification 2, Toile d'arcs 1, Ramure 2, Vif-argent 2, Haute tension 4, Fourmillements 3, Surtension 1, Court-circuit 1 | 817/s ×5,26 | 140/s ×2,31 |
| Toile d'arcs au duel (transformation) | Ramification 2, Toile d'arcs 1, Haute tension 4, Court-circuit 1, Vif-argent 2 | 355/s ×2,28 | 140/s ×2,31 |

Jamais pris : Arc tendu, Crescendo, Conductance, Bifurcation, Retour par la masse, Relais, Survoltage, Réamorçage.

### Nuage d'orage

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 89,4/s | 78,8/s |
| meilleur au paquet | Orage durable 3, Orage errant 1, Front orageux 3, Débordement 2, Cumulonimbus 4, Averse 2, Accumulation 3 | 1377/s ×15,4 | 226/s ×2,87 |
| meilleur au duel | Orage durable 3, Cumulonimbus 4, Averse 2, Foudre jumelle 2, Orage portatif 1, Front mobile 2 | 289/s ×3,23 | 290/s ×3,68 |
| Grêle au paquet (conversion) | Cumulonimbus 4, Grêle 1, Orage durable 3, Orage errant 1, Front orageux 3, Débordement 2, Averse 2, Foudre jumelle 2, Accumulation 2 | 1402/s ×15,7 | 235/s ×2,99 |
| Grêle au duel (conversion) | Cumulonimbus 4, Grêle 1, Orage durable 3, Averse 2, Foudre jumelle 2, Orage portatif 1, Front mobile 2 | 270/s ×3,02 | 264/s ×3,34 |
| Orage portatif au paquet (transformation) | Orage durable 3, Orage portatif 1, Front orageux 3, Débordement 2, Cumulonimbus 2, Averse 2, Grêle 1, Verglas 2 | 701/s ×7,85 | 193/s ×2,45 |
| Orage portatif au duel (transformation) | Orage durable 3, Orage portatif 1, Cumulonimbus 4, Averse 2, Foudre jumelle 2 | 289/s ×3,23 | 290/s ×3,68 |

Jamais pris : Appel d'air, Point de rupture, Traque.

## Manuel du froid

### Pics de glace

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 61,1/s | 32,7/s |
| meilleur au paquet | Arête 4, Réplique 2, Secousses 2, Engelure 1, Acharnement 1, Glacier 1, Sérac 1, Poussée 2, Sillon de glace 1, Crevasse 1, Éclats 2, Grésil 2 | 742/s ×12,1 | 426/s ×13,0 |
| meilleur au duel | Arête 4, Réplique 2, Secousses 2, Poussée 1, Plein centre 3, Glacier 1, Engelure 1, Acharnement 3, Sérac 1 | 481/s ×7,87 | 254/s ×7,77 |
| Sillon de glace au paquet (transformation) | Poussée 2, Sillon de glace 1, Crevasse 1, Arête 4, Réplique 2, Secousses 2, Engelure 1, Acharnement 1, Glacier 1, Sérac 1, Éclats 2, Grésil 2 | 742/s ×12,1 | 426/s ×13,0 |
| Sillon de glace au duel (transformation) | Poussée 2, Sillon de glace 1, Crevasse 1, Arête 4, Réplique 2, Secousses 2, Éclats 2, Grésil 2, Engelure 1, Acharnement 3 | 740/s ×12,1 | 509/s ×15,6 |

Jamais pris : Bosquet, Cristallisation.

### Nova de glace

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 54,6/s | 26,1/s |
| meilleur au paquet | Souffle 2, Onde de givre 1, Reflux 1, Réflexe 2, Morsure 4, Froid mordant 2, Bris 1, Frimas 3 | 496/s ×9,10 | 58,4/s ×2,23 |
| meilleur au duel | Souffle 2, Givre persistant 2, Morsure 4, Réflexe 1, Sursaut 1, Froid mordant 1, Grand froid 3 | 238/s ×4,35 | 62,3/s ×2,38 |
| Onde de givre au paquet (transformation) | Souffle 2, Onde de givre 1, Reflux 1, Réflexe 2, Morsure 4, Froid mordant 2, Bris 1, Frimas 3 | 496/s ×9,10 | 58,4/s ×2,23 |
| Onde de givre au duel (transformation) | Souffle 2, Onde de givre 1, Reflux 1, Réflexe 2, Morsure 4 | 436/s ×7,98 | 58,4/s ×2,23 |

Jamais pris : Repoussoir, Gelée blanche, Glace noire, Qui-vive.

### Désastre hivernal

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 64,3/s | 37,0/s |
| meilleur au paquet | Blizzard 2, Implosion 1, Singularité 1, Bourrasque 3, Coulée 1, Œil du cyclone 4, Accalmie 2, Rafales 2, Boule de neige 3, Ornière 1 | 388/s ×6,03 | 61,8/s ×1,67 |
| meilleur au duel | Blizzard 2, Œil du cyclone 4, Rafales 2 | 72,1/s ×1,12 | 79,1/s ×2,14 |
| Implosion au paquet (transformation) | Blizzard 2, Implosion 1, Singularité 1, Bourrasque 3, Coulée 1, Œil du cyclone 4, Accalmie 2, Rafales 2, Boule de neige 3, Ornière 1 | 388/s ×6,03 | 61,8/s ×1,67 |
| Implosion au duel (transformation) | Blizzard 2, Implosion 1, Œil du cyclone 4, Rafales 2, Bourrasque 3 | 232/s ×3,61 | 89,1/s ×2,41 |

Jamais pris : Aspiration, Givrage, Supraconduction, Meule.

### Orbe gelée

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 94,5/s | 15,2/s |
| meilleur au paquet | Long cours 3, Toupie 1, Guidage 1, Viseur 1, Noyau 4, Aiguilles 2, Fracture 3, Pluie d'éclats 2 | 908/s ×9,61 | 496/s ×32,6 |
| meilleur au duel | Long cours 3, Toupie 3, Guidage 1, Viseur 1, Stase 1, Pluie d'éclats 2, Noyau 4, Cristallin 2, Bise 2, Orbe mordante 1 | 592/s ×6,26 | 1005/s ×65,9 |

Jamais pris : Constellation, Kaléidoscope.

## Manuel de magie nécrotique

### Peste

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 90,2/s | 96,4/s |
| meilleur au paquet | Virulence 5, Nuée 1, Dispersion 2, Fléau rampant 2, Fléaux jumeaux 2, Incubation 2, Bubons 3, Projection 2 | 1731/s ×19,2 | 637/s ×6,60 |
| meilleur au duel | Fléau rampant 2, Fléaux jumeaux 2, Virulence 5, Nuée 1, Dispersion 2, Incubation 4 | 1456/s ×16,1 | 948/s ×9,84 |
| Nuée au paquet (transformation) | Virulence 5, Nuée 1, Fléau rampant 2, Fléaux jumeaux 2, Incubation 2, Bubons 3, Projection 2 | 1731/s ×19,2 | 637/s ×6,60 |
| Nuée au duel (transformation) | Virulence 5, Nuée 1, Fléau rampant 2, Fléaux jumeaux 2, Incubation 4 | 1456/s ×16,1 | 948/s ×9,84 |

Jamais pris : Condamnation, Contagion, Vecteur, Germe, Épidémie, Pandémie, Pustules.

### Relève

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 56,7/s | 60,3/s |
| meilleur au paquet | Moelle 5, Colosse d'os 1, Marche funèbre 1, Rappel 1 | 332/s ×5,85 | 159/s ×2,64 |
| meilleur au duel | Légion d'os 1, Marche funèbre 2, Rappel 1, Moelle 5, Cliquetis 3, Curée 3, Guet 3 | 222/s ×3,91 | 319/s ×5,30 |

Jamais pris : Ossature, Rempart d'os, Dernier souffle, Os rapiécés, Lanceurs d'os, Éboulis d'os, Martyr.

### Déferlante toxique

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 89,4/s | 37,5/s |
| meilleur au paquet | Miasme 3, Haleine 1, Quinte 1, Caustique 5, Apnée 3, Haleine fétide 4, Dessiccation 3 | 1207/s ×13,5 | 195/s ×5,19 |
| meilleur au duel | Haleine fétide 2, Dessiccation 3, Caustique 5, Apnée 3, Miasme 2, Haleine 1, Quinte 1, Plongée 1, Asphyxie 2 | 716/s ×8,01 | 203/s ×5,42 |
| Haleine au paquet (transformation) | Miasme 3, Haleine 1, Quinte 1, Caustique 5, Apnée 3, Haleine fétide 4, Dessiccation 3 | 1207/s ×13,5 | 195/s ×5,19 |
| Haleine au duel (transformation) | Miasme 2, Haleine 1, Quinte 1, Haleine fétide 2, Dessiccation 3, Caustique 5, Apnée 3, Plongée 1, Asphyxie 2 | 716/s ×8,01 | 203/s ×5,42 |

Jamais pris : Marais, Langueur, Succion, Détonation, Râle.

### Porte pourrissante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 87,3/s | 45,5/s |
| meilleur au paquet | Ponte 4, Essaim 5, Boursouflure 3, Progéniture 3, Lignée 1, Fécondité 3, Rampants véloces 1 | 985/s ×11,3 | 657/s ×14,4 |
| meilleur au duel | Essaim 5, Boursouflure 1, Progéniture 3, Lignée 1, Ponte 4, Fécondité 3, Gestation 2, Rampants véloces 1 | 687/s ×7,87 | 675/s ×14,8 |
| Nid porté au paquet (transformation) | Ponte 4, Nid porté 1, Essaim 1, Boursouflure 3, Progéniture 3, Lignée 1, Fécondité 3, Rampants véloces 1, Flair 1, Laisse 1 | 651/s ×7,45 | 396/s ×8,69 |
| Nid porté au duel (transformation) | Ponte 4, Nid porté 1, Essaim 5, Boursouflure 1, Progéniture 3, Lignée 1, Fécondité 3, Gestation 2 | 547/s ×6,26 | 571/s ×12,6 |

Jamais pris : Amalgame, Grouillement, Masse critique.

## Manuel du chevalier

### Frappe lourde

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 85,7/s | 80,7/s |
| meilleur au paquet | Fracas 5, Brise-sol 1, Tremblement 2, Lame ardente 1, Fer rouge 2, Pesée 2, Coup sûr 1, Brèche 3 | 854/s ×9,96 | 269/s ×3,34 |
| meilleur au duel | Fracas 5, Pesée 3, Coup sûr 1, Brèche 3, Lame ardente 1, Fer rouge 2 | 345/s ×4,02 | 313/s ×3,87 |
| Lame ardente au paquet (conversion) | Fracas 5, Lame ardente 1, Brise-sol 1, Tremblement 2, Pesée 2, Coup sûr 1, Brèche 3 | 854/s ×9,96 | 260/s ×3,22 |
| Lame ardente au duel (conversion) | Fracas 5, Lame ardente 1, Pesée 3, Coup sûr 1, Brèche 3, Fer rouge 2 | 345/s ×4,02 | 313/s ×3,87 |
| Brise-sol au paquet (transformation) | Fracas 5, Brise-sol 1, Tremblement 2, Lame ardente 1, Fer rouge 2, Pesée 2, Coup sûr 1, Brèche 3 | 854/s ×9,96 | 269/s ×3,34 |
| Brise-sol au duel (transformation) | Fracas 5, Brise-sol 1, Lame ardente 1, Fer rouge 2, Pesée 3, Coup sûr 1, Brèche 3 | 424/s ×4,94 | 279/s ×3,46 |

Jamais pris : Coup de bélier, Hargne, Cratère, Coup de massue, Collision, Quilles.

### Coup en croix

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 84,8/s | 82,7/s |
| meilleur au paquet | Taille 5, Lame sainte 1, Ordalie 1, Plaie ouverte 3, Estoc 2, Tierce 1, Quarte 1, Entaille 1, Hémorragie 2, Gerbe de sang 3 | 1086/s ×12,8 | 522/s ×6,31 |
| meilleur au duel | Taille 5, Plaie ouverte 3, Estoc 3, Tierce 1, Entaille 1, Lacération 2, Hémorragie 4 | 494/s ×5,83 | 608/s ×7,35 |
| Lame sainte au paquet (conversion) | Taille 5, Lame sainte 1, Estoc 2, Tierce 1, Quarte 1, Entaille 1, Hémorragie 2, Gerbe de sang 3, Plaie ouverte 3, Ordalie 1 | 1086/s ×12,8 | 522/s ×6,31 |
| Lame sainte au duel (conversion) | Taille 5, Lame sainte 1, Plaie ouverte 3, Estoc 3, Tierce 1, Ordalie 1, Entaille 1, Hémorragie 3, Saignée 2 | 594/s ×7,00 | 610/s ×7,38 |

Jamais pris : Riposte, Transfusion, Éclaboussure.

### Épée spirale

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 38,6/s | 20,7/s |
| meilleur au paquet | Tranchant 5, Volée d'épées 1, Ronde 3, Affûtage 3, Valse 3, Arsenal 3, Orbite large 2 | 492/s ×12,7 | 160/s ×7,73 |
| meilleur au duel | Tranchant 5, Volée d'épées 1, Ronde 3, Valse 3, Arsenal 3, Affûtage 3, Endurance 2 | 362/s ×9,38 | 171/s ×8,25 |

Jamais pris : Bouclier de lames, Parade, Brise-lames, Grenaille, Escorte, Ralliement.

### Vague tranchante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 150/s | 64,8/s |
| meilleur au paquet | Fil de l'arc 5, Vagues jumelles 3, Grand arc 4, Houle 3, Ressac 1, Va-et-vient 1, Course 3 | 3268/s ×21,8 | 564/s ×8,69 |
| meilleur au duel | Fil de l'arc 5, Vagues jumelles 3, Proue 3, Ressac 1, Va-et-vient 1, Grand arc 1, Houle 3, Course 3 | 2723/s ×18,2 | 766/s ×11,8 |
| Ressac au paquet (transformation) | Course 3, Ressac 1, Fil de l'arc 5, Vagues jumelles 3, Grand arc 4, Houle 3, Va-et-vient 1 | 3268/s ×21,8 | 564/s ×8,69 |
| Ressac au duel (transformation) | Course 2, Ressac 1, Fil de l'arc 5, Vagues jumelles 3, Va-et-vient 1, Proue 3, Grand arc 1, Houle 3 | 2546/s ×17,0 | 766/s ×11,8 |

Jamais pris : Sillon d'acier, Retenue, Lame de fond, Brisants, Herse.

### Cyclone

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 48,3/s | 20,5/s |
| meilleur au paquet | Envergure 3, Derviches 1, Trombe 1, Fauchage 5, Moulinet 3, Vertige 3, Sirocco 2 | 288/s ×5,97 | 80,8/s ×3,94 |
| meilleur au duel | Fauchage 5, Moulinet 3, Vertige 3, Derviches 1, Sirocco 2 | 121/s ×2,51 | 80,8/s ×3,94 |

Jamais pris : Souffle long, Tourbillon, Fauche vorace, Pied ferme, Dénouement, Coup de vent, Ronde folle.

### Ruée tranchante

| build | points | paquet | duel |
|---|---|---|---|
| sans arbre | — | 27,7/s | 9,07/s |
| meilleur au paquet | Andain 3, Fil tranchant 1, Charge 2, Relance 1, Hallali 2, Lame traînante 3, Choc d'arrivée 4, Trouée 2, Enchaînement 1, Pas chassé 1 | 1607/s ×58,1 | 52,0/s ×5,73 |
| meilleur au duel | Andain 1, Lame traînante 3, Fil tranchant 5, Charge 4, Choc d'arrivée 1, Trouée 2 | 203/s ×7,33 | 129/s ×14,2 |
| Saut de guerre au paquet (transformation) | Fil tranchant 5, Saut de guerre 1, Andain 3, Choc d'arrivée 4, Charge 4, Relance 1, Trouée 2 | 477/s ×17,2 | 36,9/s ×4,07 |
| Saut de guerre au duel (transformation) | Fil tranchant 5, Saut de guerre 1, Charge 4, Andain 1, Choc d'arrivée 1, Trouée 2 | 79,1/s ×2,86 | 36,9/s ×4,07 |

Jamais pris : Voltige, Coupe-jarret, Retombée.

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

