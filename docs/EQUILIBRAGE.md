# Banc d'équilibrage

<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->

Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits
par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par
les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages
restent une décision — voir `hack-n-slash-jalon-13.md`.

| verdict | coups pour tuer un grunt | survie au contact |
|---|---|---|
| 🟦 trivial | moins de 0,50 | plus de 10,0 s |
| 🟩 confortable | 0,50 à 3,00 | plus de 10,0 s |
| 🟨 tendu | 3,00 à 8,00 | 4,00 à 10,0 s |
| 🟥 mur | plus de 8,00 | moins de 4,00 s |

Le verdict est le pire des deux axes. Pour lire les nombres :

- **coups** : avec la compétence de la barre qui en demande le moins, critique en
  moyenne, après les défenses de l'ennemi ;
- **secondes** : par `average_per_second()`, *si tout touche* — les traits d'une
  nova comptent tous sur la même cible — et sans compter la réserve de mana ;
- **survie** : au contact de 3 grunts et 1 caster sans affixe, après armure,
  résistances et esquive, régénération déduite. ∞ : la régénération suffit.

## Niveau attendu

Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population
moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.

| zone | 1 | 10 | 20 | 40 | 60 | 90 | 120 |
|---|---|---|---|---|---|---|---|
| niveau | 1 | 13 | 19 | 34 | 53 | 100 | 133 |

## Sort — Manuel de la foudre, Esprit d'orage

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,69 · 2,20 s | 🟥 1,01 · 1,62 s | 🟥 1,95 · 1,21 s | 🟥 4,74 · 1,05 s | 🟥 27,0 · 2,20 s | 🟥 156 · 1,68 s |
| Sous-équipé | 🟩 1,04 · 13,1 s | 🟨 0,59 · 4,58 s | 🟥 1,00 · 3,24 s | 🟥 1,69 · 3,65 s | 🟥 2,30 · 2,11 s | 🟥 8,66 · 10,5 s | 🟥 124 · 4,25 s |
| Équipé | 🟩 1,33 · 12,8 s | 🟨 0,68 · 5,61 s | 🟨 1,00 · 6,52 s | 🟨 1,50 · 4,82 s | 🟨 4,49 · 7,70 s | 🟥 25,1 · 6,22 s | 🟥 125 · 5,94 s |
| Sur-équipé | 🟩 0,60 · 44,6 s | 🟨 0,46 · 7,46 s | 🟦 0,47 · 11,7 s | 🟨 1,92 · 5,96 s | 🟨 3,86 · 4,10 s | 🟥 17,6 · 5,75 s | 🟥 153 · 6,24 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,48 | 0,96 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,80 | 1,59 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,41 | 2,82 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 4,42 | 8,85 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 14,0 | 27,9 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 79,4 | 159 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 460 | 920 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,48 | 0,96 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 0,69 | 0,46 | 1,39 | 0,09 | 0,17 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 1,01 | 0,67 | 2,02 | 0,12 | 0,23 | 1,62 |
| Nu | 40 | 34 | Chaîne d'éclairs | 1,95 | 1,30 | 3,91 | 0,17 | 0,34 | 1,21 |
| Nu | 60 | 53 | Chaîne d'éclairs | 4,74 | 3,16 | 9,49 | 0,37 | 0,73 | 1,05 |
| Nu | 90 | 100 | Chaîne d'éclairs | 27,0 | 18,0 | 53,9 | 2,01 | 4,02 | 2,20 |
| Nu | 120 | 133 | Chaîne d'éclairs | 156 | 104 | 313 | 11,7 | 23,3 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,04 | 0,70 | 2,09 | 0,18 | 0,36 | 13,1 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,59 | 0,39 | 1,18 | 0,07 | 0,14 | 4,58 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 1,00 | 0,67 | 2,01 | 0,11 | 0,22 | 3,24 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 1,69 | 1,13 | 3,38 | 0,14 | 0,28 | 3,65 |
| Sous-équipé | 60 | 53 | Chaîne d'éclairs | 2,30 | 1,53 | 4,59 | 0,16 | 0,32 | 2,11 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 8,66 | 5,77 | 17,3 | 0,52 | 1,04 | 10,5 |
| Sous-équipé | 120 | 133 | Chaîne d'éclairs | 124 | 82,9 | 249 | 6,91 | 13,8 | 4,25 |
| Équipé | 1 | 1 | Éclair vif | 1,33 | 0,89 | 2,66 | 0,45 | 0,90 | 12,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,68 | 0,46 | 1,37 | 0,08 | 0,16 | 5,61 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 1,00 | 0,67 | 2,01 | 0,11 | 0,21 | 6,52 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 1,50 | 1,00 | 3,00 | 0,11 | 0,23 | 4,82 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 4,49 | 2,99 | 8,98 | 0,31 | 0,61 | 7,70 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 25,1 | 16,7 | 50,2 | 1,54 | 3,07 | 6,22 |
| Équipé | 120 | 133 | Chaîne d'éclairs | 125 | 83,6 | 251 | 7,54 | 15,1 | 5,94 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,60 | 0,40 | 1,19 | 0,17 | 0,34 | 44,6 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,46 | 0,31 | 0,92 | 0,05 | 0,10 | 7,46 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,47 | 0,31 | 0,93 | 0,04 | 0,09 | 11,7 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 1,92 | 1,28 | 3,83 | 0,14 | 0,27 | 5,96 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 3,86 | 2,58 | 7,73 | 0,24 | 0,48 | 4,10 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 17,6 | 11,7 | 35,1 | 1,13 | 2,27 | 5,75 |
| Sur-équipé | 120 | 133 | Chaîne d'éclairs | 153 | 102 | 307 | 8,81 | 17,6 | 6,24 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,03 · 12,1 s | 🟨 0,42 · 9,34 s | 🟩 0,75 · 13,2 s | 🟩 1,66 · 19,9 s | 🟩 2,51 · 16,5 s | 🟥 18,7 · 10,1 s | 🟥 105 · 19,2 s |
| Équipé | 🟩 1,18 · 14,0 s | 🟨 0,41 · 8,25 s | 🟩 0,82 · 20,1 s | 🟩 1,44 · 80,3 s | 🟩 2,59 · 20,4 s | 🟥 9,68 · 18,4 s | 🟥 98,5 · 8,06 s |
| Sur-équipé | 🟩 1,06 · 39,1 s | 🟦 0,33 · 14,1 s | 🟩 0,83 · 13,1 s | 🟩 1,57 · 150 s | 🟨 3,36 · 55,6 s | 🟥 12,0 · 34,9 s | 🟥 71,6 · 15,3 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 2,23 | 1,49 | 4,47 | 0,97 | 1,93 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,83 | 3,22 | 9,66 | 2,09 | 4,18 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 20,0 | 13,3 | 40,0 | 8,66 | 17,3 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 75,6 | 50,4 | 151 | 32,7 | 65,5 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 506 | 337 | 1012 | 219 | 438 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 3166 | 2111 | 6332 | 1370 | 2740 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Nu | 10 | 13 | Frappe lourde | 0,44 | 0,29 | 0,88 | 0,13 | 0,27 | 4,44 |
| Nu | 20 | 19 | Frappe lourde | 0,81 | 0,54 | 1,62 | 0,25 | 0,51 | 6,32 |
| Nu | 40 | 34 | Frappe lourde | 1,88 | 1,25 | 3,75 | 0,66 | 1,32 | 6,05 |
| Nu | 60 | 53 | Frappe lourde | 3,55 | 2,37 | 7,11 | 1,05 | 2,09 | 5,59 |
| Nu | 90 | 100 | Frappe lourde | 19,5 | 13,0 | 38,9 | 5,90 | 11,8 | 4,04 |
| Nu | 120 | 133 | Frappe lourde | 106 | 70,4 | 211 | 32,9 | 65,7 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,03 | 0,69 | 2,07 | 0,41 | 0,83 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,42 | 0,28 | 0,83 | 0,11 | 0,22 | 9,34 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,75 | 0,50 | 1,50 | 0,19 | 0,38 | 13,2 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,66 | 1,10 | 3,31 | 0,47 | 0,95 | 19,9 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,51 | 1,68 | 5,03 | 0,56 | 1,13 | 16,5 |
| Sous-équipé | 90 | 100 | Frappe lourde | 18,7 | 12,5 | 37,4 | 4,20 | 8,40 | 10,1 |
| Sous-équipé | 120 | 133 | Frappe lourde | 105 | 70,0 | 210 | 19,5 | 38,9 | 19,2 |
| Équipé | 1 | 1 | Frappe lourde | 1,18 | 0,79 | 2,36 | 0,43 | 0,85 | 14,0 |
| Équipé | 10 | 13 | Frappe lourde | 0,41 | 0,27 | 0,82 | 0,10 | 0,20 | 8,25 |
| Équipé | 20 | 19 | Frappe lourde | 0,82 | 0,55 | 1,64 | 0,19 | 0,38 | 20,1 |
| Équipé | 40 | 34 | Frappe lourde | 1,44 | 0,96 | 2,87 | 0,34 | 0,69 | 80,3 |
| Équipé | 60 | 53 | Frappe lourde | 2,59 | 1,73 | 5,19 | 0,59 | 1,18 | 20,4 |
| Équipé | 90 | 100 | Frappe lourde | 9,68 | 6,45 | 19,4 | 1,43 | 2,87 | 18,4 |
| Équipé | 120 | 133 | Frappe lourde | 98,5 | 65,7 | 197 | 19,1 | 38,2 | 8,06 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,06 | 0,70 | 2,11 | 0,33 | 0,66 | 39,1 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,33 | 0,22 | 0,67 | 0,08 | 0,16 | 14,1 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,83 | 0,56 | 1,67 | 0,19 | 0,39 | 13,1 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,57 | 1,05 | 3,15 | 0,34 | 0,68 | 150 |
| Sur-équipé | 60 | 53 | Frappe lourde | 3,36 | 2,24 | 6,72 | 0,55 | 1,11 | 55,6 |
| Sur-équipé | 90 | 100 | Frappe lourde | 12,0 | 8,02 | 24,1 | 2,22 | 4,43 | 34,9 |
| Sur-équipé | 120 | 133 | Frappe lourde | 71,6 | 47,7 | 143 | 16,0 | 32,0 | 15,3 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
