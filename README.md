# Analyse de la Performance Commerciale et du Risque Client — FINBANK IVOIR

Projet réalisé dans le cadre du module **SAS**  Master 1 DATA-IA, Université Polytechnique de Bingerville (UPB), Année académique : 2025-2026.

**Auteur :** YAO MIÉZAN SAM WILLIAM
**Enseignant :** M. N'DRAMAN

## Contexte

La banque FINBANK IVOIR souhaite exploiter plus efficacement ses données pour :
- évaluer la rentabilité de ses clients,
- identifier les clients à risque élevé,
- analyser la performance de ses agences,
- formuler des recommandations pour la gestion de la clientèle.

Le projet construit une base analytique unique (`CLIENT_ANALYSE`) à partir de quatre fichiers sources : **300 clients**, **449 comptes**, **180 crédits** et **4 000 transactions**.

## Structure du dépôt

```
finbank-ivoir-analysis/
├── data/                  # Fichiers sources bruts (CSV)
│   ├── CLIENTS_PROJET.csv
│   ├── COMPTES_PROJET.csv
│   ├── CREDITS_PROJET.csv
│   └── TRANSACTIONS_PROJET.csv
├── code/                  # Script SAS complet
│   └── EXAMEN_PROJET_MIEZAN_SAM_YAO.sas
├── resultats/             # Sortie HTML générée par SAS (tableaux, graphiques)
│   └── EXAMEN_PROJET_MIEZAN_SAM_YAO-résultats.html
├── rapport/               # Rapport final au format PDF
│   └── Rapport_EXAMEN_PROJET_MIEZAN_SAM_YAO.pdf
└── README.md
```

## Démarche

1. **Contrôle qualité des données** : détection des valeurs manquantes (PROC MEANS / PROC FREQ), des doublons et des incohérences (âges, revenus, soldes, taux).
2. **Préparation des données** : nettoyage, agrégation des comptes/crédits/transactions par client, fusion en une base unique `CLIENT_ANALYSE`.
3. **Calcul de 6 indicateurs** : taux d'endettement, revenu annuel, ancienneté catégorisée, fréquence de transactions, score de fidélité, score de risque.
4. **Segmentation des clients** en 4 segments (À risque, Premium, Gold, Standard) via une logique IF/THEN/ELSE priorisant le risque.
5. **Visualisations** : histogrammes, diagrammes en barres, boxplots (PROC SGPLOT / PROC UNIVARIATE).
6. **Note de synthèse** au Directeur Général avec recommandations opérationnelles.

## Principaux résultats

| Segment   | Clients | Part    |
|-----------|---------|---------|
| Gold      | 146     | 48.7 %  |
| Standard  | 116     | 38.7 %  |
| À risque  | 23      | 7.7 %   |
| Premium   | 15      | 5.0 %   |

- Score de risque moyen : **23,11/100**
- Agence la plus équilibrée (revenu élevé, risque faible) : **Cocody**
- Agence avec le plus fort volume d'activité et de risque : **Plateau**

Le détail complet des analyses, graphiques et recommandations est disponible dans le [rapport PDF](rapport/Rapport_EXAMEN_PROJET_MIEZAN_SAM_YAO.pdf).

## Outils utilisés

- SAS (PROC MEANS, PROC FREQ, PROC SQL, PROC SORT, PROC SGPLOT, PROC UNIVARIATE, PROC TABULATE, DATA STEP)

## Licence

Projet académique à usage pédagogique.
