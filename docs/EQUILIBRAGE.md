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
| Sous-équipé | 🟩 1,01 · 13,1 s | 🟨 0,57 · 4,58 s | 🟥 0,97 · 3,24 s | 🟥 1,53 · 3,49 s | 🟥 2,13 · 2,53 s | 🟨 6,84 · 10,5 s | 🟥 96,6 · 4,25 s |
| Équipé | 🟩 1,28 · 11,8 s | 🟨 0,63 · 5,61 s | 🟨 0,97 · 6,52 s | 🟨 1,39 · 4,82 s | 🟨 3,94 · 7,70 s | 🟥 24,2 · 6,22 s | 🟥 103 · 5,94 s |
| Sur-équipé | 🟩 0,82 · 809 s | 🟨 0,44 · 7,46 s | 🟨 0,53 · 5,50 s | 🟨 1,75 · 5,96 s | 🟨 3,53 · 4,10 s | 🟥 14,6 · 5,75 s | 🟥 140 · 6,24 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,55 | 1,10 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,92 | 1,83 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,62 | 3,24 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 5,09 | 10,2 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 16,1 | 32,1 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 91,3 | 183 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 529 | 1058 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,55 | 1,10 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 0,69 | 0,46 | 1,39 | 0,10 | 0,20 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 1,01 | 0,67 | 2,02 | 0,13 | 0,26 | 1,62 |
| Nu | 40 | 34 | Chaîne d'éclairs | 1,95 | 1,30 | 3,91 | 0,19 | 0,38 | 1,21 |
| Nu | 60 | 53 | Chaîne d'éclairs | 4,74 | 3,16 | 9,49 | 0,41 | 0,82 | 1,05 |
| Nu | 90 | 100 | Chaîne d'éclairs | 27,0 | 18,0 | 53,9 | 2,24 | 4,48 | 2,20 |
| Nu | 120 | 133 | Chaîne d'éclairs | 156 | 104 | 313 | 13,0 | 26,0 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,01 | 0,67 | 2,02 | 0,18 | 0,35 | 13,1 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,57 | 0,38 | 1,15 | 0,07 | 0,14 | 4,58 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,65 | 1,95 | 0,11 | 0,22 | 3,24 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 1,53 | 1,02 | 3,06 | 0,13 | 0,26 | 3,49 |
| Sous-équipé | 60 | 53 | Chaîne d'éclairs | 2,13 | 1,42 | 4,27 | 0,15 | 0,30 | 2,53 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 6,84 | 4,56 | 13,7 | 0,41 | 0,82 | 10,5 |
| Sous-équipé | 120 | 133 | Chaîne d'éclairs | 96,6 | 64,4 | 193 | 5,53 | 11,1 | 4,25 |
| Équipé | 1 | 1 | Éclair vif | 1,28 | 0,86 | 2,57 | 0,44 | 0,87 | 11,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,63 | 0,42 | 1,26 | 0,08 | 0,16 | 5,61 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,65 | 1,95 | 0,10 | 0,20 | 6,52 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 1,39 | 0,93 | 2,78 | 0,11 | 0,21 | 4,82 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 3,94 | 2,62 | 7,87 | 0,27 | 0,54 | 7,70 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 24,2 | 16,1 | 48,4 | 1,48 | 2,96 | 6,22 |
| Équipé | 120 | 133 | Chaîne d'éclairs | 103 | 68,8 | 206 | 6,20 | 12,4 | 5,94 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,82 | 0,54 | 1,63 | 0,21 | 0,42 | 809 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,44 | 0,29 | 0,87 | 0,05 | 0,09 | 7,46 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,53 | 0,36 | 1,07 | 0,05 | 0,10 | 5,50 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 1,75 | 1,17 | 3,51 | 0,12 | 0,24 | 5,96 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 3,53 | 2,36 | 7,07 | 0,22 | 0,44 | 4,10 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 14,6 | 9,73 | 29,2 | 0,94 | 1,88 | 5,75 |
| Sur-équipé | 120 | 133 | Chaîne d'éclairs | 140 | 93,5 | 280 | 8,05 | 16,1 | 6,24 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,30 · 4,68 s | 🟥 2,92 · 2,20 s | 🟥 6,55 · 1,39 s | 🟥 28,2 · 0,80 s | 🟥 109 · 0,56 s | 🟥 740 · 0,39 s | 🟥 4672 · 0,30 s |
| Nu | 🟨 1,30 · 4,68 s | 🟨 0,49 · 4,44 s | 🟨 0,92 · 6,32 s | 🟨 2,11 · 6,05 s | 🟨 3,99 · 5,59 s | 🟥 22,0 · 4,04 s | 🟥 120 · 2,97 s |
| Sous-équipé | 🟩 1,06 · 12,1 s | 🟨 0,41 · 9,34 s | 🟩 0,75 · 13,2 s | 🟩 1,67 · 19,9 s | 🟨 3,02 · 16,6 s | 🟥 18,1 · 10,1 s | 🟥 93,5 · 19,2 s |
| Équipé | 🟩 1,21 · 14,0 s | 🟨 0,43 · 9,40 s | 🟩 0,83 · 20,1 s | 🟩 1,27 · 80,3 s | 🟩 2,52 · 20,4 s | 🟨 7,17 · 18,6 s | 🟥 95,2 · 10,2 s |
| Sur-équipé | 🟩 1,07 · 39,1 s | 🟦 0,32 · 14,1 s | 🟩 0,81 · 13,1 s | 🟩 1,48 · 150 s | 🟩 2,86 · 53,3 s | 🟥 10,2 · 34,9 s | 🟥 69,3 · 15,3 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 1,30 | 0,87 | 2,60 | 0,56 | 1,12 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 2,92 | 1,95 | 5,84 | 1,26 | 2,53 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 6,55 | 4,36 | 13,1 | 2,83 | 5,66 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 28,2 | 18,8 | 56,3 | 12,2 | 24,4 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 109 | 72,5 | 217 | 47,0 | 94,0 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 740 | 493 | 1479 | 320 | 640 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 4672 | 3115 | 9345 | 2022 | 4043 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 1,30 | 0,87 | 2,60 | 0,56 | 1,12 | 4,68 |
| Nu | 10 | 13 | Frappe lourde | 0,49 | 0,33 | 0,99 | 0,16 | 0,31 | 4,44 |
| Nu | 20 | 19 | Frappe lourde | 0,92 | 0,61 | 1,83 | 0,30 | 0,59 | 6,32 |
| Nu | 40 | 34 | Frappe lourde | 2,11 | 1,41 | 4,23 | 0,76 | 1,53 | 6,05 |
| Nu | 60 | 53 | Frappe lourde | 3,99 | 2,66 | 7,99 | 1,21 | 2,41 | 5,59 |
| Nu | 90 | 100 | Frappe lourde | 22,0 | 14,7 | 44,0 | 6,88 | 13,8 | 4,04 |
| Nu | 120 | 133 | Frappe lourde | 120 | 80,2 | 241 | 38,6 | 77,1 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,06 | 0,71 | 2,12 | 0,42 | 0,85 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,41 | 0,28 | 0,83 | 0,11 | 0,22 | 9,34 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,75 | 0,50 | 1,51 | 0,19 | 0,38 | 13,2 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,67 | 1,11 | 3,33 | 0,48 | 0,95 | 19,9 |
| Sous-équipé | 60 | 53 | Frappe lourde | 3,02 | 2,01 | 6,03 | 0,69 | 1,38 | 16,6 |
| Sous-équipé | 90 | 100 | Frappe lourde | 18,1 | 12,1 | 36,2 | 4,06 | 8,11 | 10,1 |
| Sous-équipé | 120 | 133 | Frappe lourde | 93,5 | 62,3 | 187 | 17,2 | 34,3 | 19,2 |
| Équipé | 1 | 1 | Frappe lourde | 1,21 | 0,80 | 2,41 | 0,44 | 0,87 | 14,0 |
| Équipé | 10 | 13 | Frappe lourde | 0,43 | 0,28 | 0,85 | 0,10 | 0,21 | 9,40 |
| Équipé | 20 | 19 | Frappe lourde | 0,83 | 0,55 | 1,66 | 0,19 | 0,39 | 20,1 |
| Équipé | 40 | 34 | Frappe lourde | 1,27 | 0,85 | 2,54 | 0,30 | 0,60 | 80,3 |
| Équipé | 60 | 53 | Frappe lourde | 2,52 | 1,68 | 5,04 | 0,57 | 1,14 | 20,4 |
| Équipé | 90 | 100 | Frappe lourde | 7,17 | 4,78 | 14,3 | 1,13 | 2,25 | 18,6 |
| Équipé | 120 | 133 | Frappe lourde | 95,2 | 63,5 | 190 | 19,2 | 38,4 | 10,2 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,07 | 0,71 | 2,14 | 0,33 | 0,67 | 39,1 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,32 | 0,22 | 0,65 | 0,08 | 0,15 | 14,1 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,81 | 0,54 | 1,62 | 0,19 | 0,37 | 13,1 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,48 | 0,99 | 2,96 | 0,33 | 0,66 | 150 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,86 | 1,91 | 5,73 | 0,44 | 0,88 | 53,3 |
| Sur-équipé | 90 | 100 | Frappe lourde | 10,2 | 6,83 | 20,5 | 1,62 | 3,24 | 34,9 |
| Sur-équipé | 120 | 133 | Frappe lourde | 69,3 | 46,2 | 139 | 15,4 | 30,9 | 15,3 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
