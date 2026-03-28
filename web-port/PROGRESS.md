# Village Life — Portage Web : Rapport de Progrès

## 🎯 Objectif
Porter Village Life (Android/Playdemic) en version web en réutilisant directement les fichiers du jeu.

---

## ✅ Accomplissements

### 1. Analyse complète du moteur (libpdandroid.so)
- **16 535 symboles exportés** analysés et cartographiés
- Architecture modulaire identifiée : GSINTGCO (833 fonctions), GSINTGUI (122), GSINTFILE (61), GSINTPACK (6), GSINTPARSE (15), GSINTMODELLOAD (19), etc.
- **Tout le code est en mode ARM** (32-bit, pas Thumb)
- `libjs.so` = **JavaScriptCore** (moteur JS de WebKit) — la logique du jeu utilise un moteur JS natif

### 2. Émulation ARM fonctionnelle 🦄
- **Python + Unicorn Engine** : émulateur ARM qui charge et exécute `libpdandroid.so` directement
- Relocations ELF traitées (68 894 relatives + 230 imports)
- Stubs libc (malloc, free, memcpy, memset...) + hook du wrapper zlib interne
- **GSINTPACK::UNPACKZLIB testé et fonctionnel** ✓

### 3. Décompression de vraies données de jeu
- **main.tcf** décodé : container TCF1 avec SPK1 (zlib) — `gui/village.t3g` extrait
- **village.t3g** : 8.3 MB décompressé, contient 8 813 strings lisibles
  - Textes UI : "Villager Shop", "Art Dialog", "View Crafted Items"
  - Dialogues : "Welcome to your new population counter!"
  - Mécanique : "Married couples will stay with higher starred villagers!"
  - Debug : "Karl's Awesome Debug Dialog" (merci Karl !)

### 4. Formats de fichiers identifiés

| Format | Rôle | Statut |
|--------|------|--------|
| `.tcf` (TCF1) | Container principal | ✅ Parsé en Python |
| SPK1 + zlib | Compression | ✅ Décompressé via émulation ARM |
| `.t3g` | GUI/Scene graph | 🔍 Structure binaire avec strings embarquées |
| `.bin` | Sprites/Props avatar | 🔜 À parser |
| `.anx` | Animations | 🔜 À parser |
| `.dta` | Terrain/Collision | 🔜 À parser |
| `.bsh` | Scripts modèle | ✅ Texte lisible (JSON-like) |
| `.xml` | Données de jeu | ✅ 375 bâtiments, 608 crafts, 3126 matériaux, 1000 niveaux |
| `.tga` | Textures | ✅ Standard (loader JS existe) |
| `.wav/.mp3` | Audio | ✅ Standard |
| `.fsh/.vsh` | Shaders GLSL | ✅ Standard (adaptable WebGL) |

---

## 🏗️ Architecture de l'émulateur

```
Python + Unicorn Engine
│
├── Charge libpdandroid.so (6.3 MB ARM ELF)
├── Mappe les segments LOAD en mémoire Unicorn
├── Traite 69 124 relocations (relatives + imports)
├── Stubs libc : malloc/free/memcpy/memset...
├── Hook du wrapper inflate interne (0x216514)
│   └── Redirige vers zlib Python
│
└── Appelle les fonctions natives :
    ├── GSINTPACK::UNPACKZLIB  ← ✅ Fonctionne
    ├── GSINTPACK::UNPACKANY   ← Prêt à tester
    ├── GSINTPARSE::LOADFILE   ← Prêt à tester
    ├── GSINTFILE::OpenTCF     ← Nécessite init du filesystem
    ├── LoadBINFile            ← Nécessite init
    └── CheckBinANX            ← Nécessite init
```

---

## 📋 Prochaines étapes

1. **Parser les .bin** (avatar props) — 255 KB chacun, contiennent sprites/mesh
2. **Parser les .anx** (animations) — 75 KB, séquences d'animation
3. **Analyser village.t3g** en profondeur — identifier le scene graph, les coordonnées, les références textures
4. **Écrire les parsers JavaScript** équivalents pour le navigateur
5. **Choisir un moteur web** : PixiJS (2D) ou Three.js (3D) + recréer le rendu

---

## 📁 Fichiers sauvegardés

```
/agent/home/vl/
├── emu/
│   ├── arm_emulator.py       # Émulateur ARM principal (proof of concept)
│   ├── game_decompressor.py  # Décompresseur de vrais fichiers de jeu
│   └── tcf_parser.py         # Parser Python du format TCF1
├── symbols.txt               # 16 535 symboles exportés
└── repo_tree.txt             # Arborescence complète du repo
```

Les fichiers binaires lourds (.so, .tcf, .t3g) sont dans `/tmp/vl-libs/` et `/tmp/vl-data/` (session courante).
