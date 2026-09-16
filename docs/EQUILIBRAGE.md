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
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,58 · 2,20 s | 🟥 0,82 · 1,41 s | 🟥 2,47 · 1,65 s | 🟥 7,80 · 1,14 s | 🟥 44,3 · 0,78 s | 🟥 257 · 0,59 s |
| Sous-équipé | 🟩 1,01 · 13,1 s | 🟨 0,48 · 4,40 s | 🟥 0,79 · 2,77 s | 🟨 1,85 · 5,73 s | 🟥 3,10 · 3,23 s | 🟥 9,23 · 7,46 s | 🟥 153 · 2,37 s |
| Équipé | 🟩 1,28 · 11,8 s | 🟨 0,52 · 5,40 s | 🟨 0,79 · 5,71 s | 🟨 1,66 · 7,81 s | 🟨 6,44 · 11,9 s | 🟥 39,9 · 3,80 s | 🟥 163 · 4,15 s |
| Sur-équipé | 🟩 0,82 · 809 s | 🟨 0,36 · 7,46 s | 🟨 0,43 · 5,22 s | 🟩 2,22 · 10,6 s | 🟨 5,58 · 6,12 s | 🟥 22,1 · 2,91 s | 🟥 231 · 3,40 s |

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
| Nu | 10 | 13 | Chaîne d'éclairs | 0,58 | 0,38 | 1,15 | 0,08 | 0,16 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 0,82 | 0,55 | 1,64 | 0,11 | 0,23 | 1,41 |
| Nu | 40 | 34 | Chaîne d'éclairs | 2,47 | 1,65 | 4,94 | 0,33 | 0,65 | 1,65 |
| Nu | 60 | 53 | Chaîne d'éclairs | 7,80 | 5,20 | 15,6 | 1,03 | 2,06 | 1,14 |
| Nu | 90 | 100 | Chaîne d'éclairs | 44,3 | 29,5 | 88,6 | 5,85 | 11,7 | 0,78 |
| Nu | 120 | 133 | Chaîne d'éclairs | 257 | 171 | 514 | 33,9 | 67,8 | 0,59 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,01 | 0,67 | 2,02 | 0,18 | 0,35 | 13,1 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,48 | 0,32 | 0,95 | 0,06 | 0,11 | 4,40 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,79 | 0,53 | 1,58 | 0,09 | 0,19 | 2,77 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 1,85 | 1,23 | 3,70 | 0,21 | 0,42 | 5,73 |
| Sous-équipé | 60 | 53 | Nova de foudre | 3,10 | 2,06 | 6,19 | 0,33 | 0,65 | 3,23 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 9,23 | 6,15 | 18,5 | 0,84 | 1,68 | 7,46 |
| Sous-équipé | 120 | 133 | Chaîne d'éclairs | 153 | 102 | 306 | 12,8 | 25,5 | 2,37 |
| Équipé | 1 | 1 | Éclair vif | 1,28 | 0,86 | 2,57 | 0,44 | 0,87 | 11,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,52 | 0,35 | 1,05 | 0,06 | 0,13 | 5,40 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,79 | 0,53 | 1,58 | 0,08 | 0,17 | 5,71 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 1,66 | 1,11 | 3,32 | 0,17 | 0,34 | 7,81 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 6,44 | 4,29 | 12,9 | 0,65 | 1,31 | 11,9 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 39,9 | 26,6 | 79,7 | 3,64 | 7,27 | 3,80 |
| Équipé | 120 | 133 | Chaîne d'éclairs | 163 | 109 | 327 | 14,6 | 29,2 | 4,15 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,82 | 0,54 | 1,63 | 0,21 | 0,42 | 809 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,36 | 0,24 | 0,72 | 0,04 | 0,07 | 7,46 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,43 | 0,29 | 0,86 | 0,04 | 0,08 | 5,22 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 2,22 | 1,48 | 4,44 | 0,20 | 0,39 | 10,6 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 5,58 | 3,72 | 11,2 | 0,51 | 1,01 | 6,12 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 22,1 | 14,7 | 44,2 | 2,19 | 4,39 | 2,91 |
| Sur-équipé | 120 | 133 | Chaîne d'éclairs | 231 | 154 | 462 | 19,9 | 39,9 | 3,40 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,30 · 4,68 s | 🟥 2,92 · 2,20 s | 🟥 6,55 · 1,39 s | 🟥 28,2 · 0,80 s | 🟥 109 · 0,56 s | 🟥 740 · 0,39 s | 🟥 4672 · 0,30 s |
| Nu | 🟨 1,30 · 4,68 s | 🟨 0,43 · 4,16 s | 🟨 0,78 · 5,20 s | 🟨 2,18 · 4,79 s | 🟥 7,07 · 3,09 s | 🟥 40,5 · 2,01 s | 🟥 228 · 1,49 s |
| Sous-équipé | 🟩 1,06 · 12,1 s | 🟨 0,36 · 9,18 s | 🟩 0,64 · 12,1 s | 🟩 1,68 · 18,1 s | 🟨 4,94 · 11,7 s | 🟥 32,3 · 6,02 s | 🟥 175 · 12,9 s |
| Équipé | 🟩 1,21 · 14,0 s | 🟨 0,37 · 8,95 s | 🟩 0,71 · 19,1 s | 🟩 1,23 · 43,2 s | 🟨 3,95 · 15,3 s | 🟥 10,1 · 11,7 s | 🟥 173 · 6,30 s |
| Sur-équipé | 🟩 1,07 · 39,1 s | 🟦 0,28 · 15,0 s | 🟩 0,69 · 12,7 s | 🟩 1,50 · 79,2 s | 🟨 4,99 · 29,0 s | 🟥 16,1 · 19,0 s | 🟥 112 · 10,0 s |

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
| Nu | 10 | 13 | Frappe lourde | 0,43 | 0,29 | 0,86 | 0,15 | 0,30 | 4,16 |
| Nu | 20 | 19 | Frappe lourde | 0,78 | 0,52 | 1,56 | 0,28 | 0,56 | 5,20 |
| Nu | 40 | 34 | Frappe lourde | 2,18 | 1,45 | 4,36 | 0,76 | 1,52 | 4,79 |
| Nu | 60 | 53 | Frappe lourde | 7,07 | 4,72 | 14,1 | 2,57 | 5,14 | 3,09 |
| Nu | 90 | 100 | Frappe lourde | 40,5 | 27,0 | 81,1 | 14,9 | 29,9 | 2,01 |
| Nu | 120 | 133 | Frappe lourde | 228 | 152 | 457 | 84,1 | 168 | 1,49 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,06 | 0,71 | 2,12 | 0,42 | 0,85 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,36 | 0,24 | 0,72 | 0,10 | 0,21 | 9,18 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,64 | 0,43 | 1,28 | 0,18 | 0,35 | 12,1 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,68 | 1,12 | 3,35 | 0,45 | 0,91 | 18,1 |
| Sous-équipé | 60 | 53 | Frappe lourde | 4,94 | 3,30 | 9,89 | 1,26 | 2,53 | 11,7 |
| Sous-équipé | 90 | 100 | Frappe lourde | 32,3 | 21,5 | 64,6 | 8,55 | 17,1 | 6,02 |
| Sous-équipé | 120 | 133 | Frappe lourde | 175 | 116 | 349 | 37,5 | 75,0 | 12,9 |
| Équipé | 1 | 1 | Frappe lourde | 1,21 | 0,80 | 2,41 | 0,44 | 0,87 | 14,0 |
| Équipé | 10 | 13 | Frappe lourde | 0,37 | 0,24 | 0,73 | 0,10 | 0,20 | 8,95 |
| Équipé | 20 | 19 | Frappe lourde | 0,71 | 0,47 | 1,41 | 0,18 | 0,35 | 19,1 |
| Équipé | 40 | 34 | Frappe lourde | 1,23 | 0,82 | 2,45 | 0,27 | 0,54 | 43,2 |
| Équipé | 60 | 53 | Frappe lourde | 3,95 | 2,63 | 7,89 | 0,97 | 1,94 | 15,3 |
| Équipé | 90 | 100 | Frappe lourde | 10,1 | 6,77 | 20,3 | 1,63 | 3,27 | 11,7 |
| Équipé | 120 | 133 | Frappe lourde | 173 | 115 | 345 | 41,2 | 82,3 | 6,30 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,07 | 0,71 | 2,14 | 0,33 | 0,67 | 39,1 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,28 | 0,19 | 0,56 | 0,07 | 0,14 | 15,0 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,69 | 0,46 | 1,38 | 0,17 | 0,35 | 12,7 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,50 | 1,00 | 3,00 | 0,33 | 0,66 | 79,2 |
| Sur-équipé | 60 | 53 | Frappe lourde | 4,99 | 3,32 | 9,97 | 0,90 | 1,81 | 29,0 |
| Sur-équipé | 90 | 100 | Frappe lourde | 16,1 | 10,7 | 32,2 | 2,80 | 5,60 | 19,0 |
| Sur-équipé | 120 | 133 | Frappe lourde | 112 | 75,0 | 225 | 27,4 | 54,9 | 10,0 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
