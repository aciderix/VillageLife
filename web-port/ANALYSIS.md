# 🏘️ Village Life — Analyse Complète pour Portage Web

## 1. Identification du Projet

| Champ | Valeur |
|-------|--------|
| **Package** | `com.playdemic.villagelife.android` |
| **Version** | `241.0.5.270.0` |
| **Développeur** | Playdemic Ltd |
| **Activité principale** | `VillageLife` (extends `PDApplication`) |
| **Moteur** | Playdemic Engine (custom, natif C++) |
| **Fichiers** | **8 124 fichiers** dans le repo |

---

## 2. Architecture Technique du APK

### 2.1 Bibliothèques natives (.so)
```
lib/armeabi-v7a/
├── libpdandroid.so   ← Moteur principal Playdemic (C++)
├── libjs.so          ← Moteur JavaScript embarqué (SpiderMonkey?)
└── libadcolony.so    ← SDK publicitaire AdColony
```

**Observation clé :** La présence de `libjs.so` indique que le moteur exécute du **JavaScript** pour la logique de jeu. C'est un énorme avantage pour le portage web — la logique de jeu est potentiellement scriptée en JS et non compilée en code natif.

### 2.2 Code Dalvik
```
classes.dex     ← Code Java principal (Playdemic SDK, Google Play Services, Facebook SDK, etc.)
classes2.dex    ← Overflow code (multidex)
```
Le Java gère uniquement le wrapper Android (activités, services, push notifications, achats). Pas de logique de jeu ici.

### 2.3 Rendu Graphique
- **OpenGL ES 2.0** (confirmé par les shaders)
- Shaders GLSL : `Shader_3D_UBER.fsh` (34KB) + `Shader_3D_UBER.vsh` (16KB)
- Rendu avancé : normal mapping, specular, reflection, emissive, shadow maps, bone animation, Phong lighting
- Les shaders utilisent un système de **#define** pour des variantes (avec/sans ombres, reflets, etc.)

---

## 3. Inventaire des Formats Propriétaires

| Extension | Quantité | Description | Lisible ? |
|-----------|----------|-------------|-----------|
| `.bin` | 3 873 | Props d'avatars (maillages/données binaires) | ❌ Binaire propriétaire |
| `.tga` | 1 528 | Textures (format Targa standard) | ✅ Format standard |
| `.png` | 1 035 | Images (UI Android principalement) | ✅ Standard |
| `.anx` | 607 | Animations de personnages | ❌ Binaire propriétaire |
| `.wav` | 442 | Effets sonores | ✅ Standard |
| `.xml` | 423 | Données de jeu (tables), localisations, config | ✅ XML lisible |
| `.bsh` | 18 | Données de modèles 3D (mesh binaire, pas BeanShell) | ❌ Binaire avec header texte |
| `.mp3` | 16 | Musique de fond | ✅ Standard |
| `.dta` | 4 | Données de zones (`rc_main`, `rc_ftue`, `rc_area3`, `rc_area4`) | ❌ Binaire |
| `.t3t` | 4 | Polices bitmap (format Playdemic) | ❌ Propriétaire |
| `.bdl` | 2 | Bundles 3D (modèle locket) | ❌ Binaire |
| `.tcf` | 1 | Config principale (`main.tcf` = 1MB, format TCF1+SPK1) | ❌ Compressé SPK1 |
| `.smv` | 1 | Données de mouvement/animation | ❌ Binaire |
| `.t3g` | 1 | `gui/village.t3g` — GUI principal (référencé dans origmanifest) | ❌ Propriétaire |
| `.arsc` | 1 | Ressources Android compilées | ❌ Standard Android |

---

## 4. Données de Jeu (XML) — Le Trésor 🎯

Les XML sont **le cœur logique du jeu**, parfaitement lisibles et structurés. Voici les tables identifiées :

### Tables de gameplay (sam1)
| Table | Lignes | Description |
|-------|--------|-------------|
| `building_type` | 375 | Types de bâtiments |
| `building_task` | 364 | Tâches de construction |
| `crafting_task` | 608 | Tâches d'artisanat |
| `farming_task` | 284 | Tâches agricoles |
| `fishing_task` | 41 | Tâches de pêche |
| `HuntingTask` | 31 | Tâches de chasse |
| `fire_task` | 6 | Tâches de feu |
| `decor_item` | 555 | Objets de décoration |
| `equipment` | 1 105 | Équipements |
| `avatar_animation` | 3 679 | Animations de personnages |
| `collision_component` | 742 | Collisions |
| `critter` | 31 | Créatures |
| `global` | 342 | Variables globales du jeu |
| `game_rate` | 47 | Taux/vitesse du jeu |

### Tables d'économie (sam0 + sam2)
| Table | Lignes | Description |
|-------|--------|-------------|
| `currency_payment` | 813 | Système de paiement |
| `material_type` | 3 126 | Types de matériaux |
| `reward_set` | 2 356 | Ensembles de récompenses |
| `reward_set_item` | 3 841 | Items de récompenses |
| `requirement_set_item` | 4 146 | Items de prérequis |
| `material_mastery` | 140 | Maîtrise des matériaux |

### Tables de contenu narratif (loc1 + loc2)
| Table | Lignes | Description |
|-------|--------|-------------|
| `game_text` | 6 822 | Textes du jeu |
| `art_dialog` | 1 010 | Dialogues avec JSON embarqué |
| `quest_type` | 24 | Types de quêtes |
| `user_level` | 1 000 | Niveaux utilisateur |
| `fun_building` | 124 | Bâtiments de loisir |
| `fun_activity` | 209 | Activités de loisir |
| `shelter` | 49 | Abris |
| `liveops_event` | 48 | Événements live |

### Tables de séquences/scripting (sam2)
| Table | Lignes | Description |
|-------|--------|-------------|
| `seq_state_tablet_ftue` | 772 | Tutorial (First Time User Experience) |
| `seq_state_tablet_seasonal` | 2 878 | Événements saisonniers |
| `seq_state_tablet_area3` | 875 | Zone 3 |
| `seq_state_tablet_area4` | 152 | Zone 4 |
| `seq_state_tablet_marriage` | 31 | Mariage |
| `seq_state_tablet_retirement` | 65 | Retraite |

---

## 5. Assets Visuels

### 5.1 Textures de jeu (`tex/`)
```
tex/
├── cache/                    ← UI du jeu (23 sous-dossiers)
│   ├── achievementcomplete/  ← Succès
│   ├── buttons/              ← Boutons
│   ├── dialogs/              ← Dialogues
│   ├── hud/                  ← Interface en jeu
│   ├── newhud/               ← Nouvelle interface
│   ├── panels/               ← Panneaux
│   ├── worldmap/             ← Carte du monde
│   ├── storypanels/          ← Panneaux d'histoire
│   └── ...
├── environment/              ← Textures d'environnement
├── map/                      ← Carte/terrain
├── particles/                ← Particules
├── weather/                  ← Météo
├── charm_textures/           ← Charmes
├── expandedmaps/             ← Cartes étendues
└── logos/                    ← Logos
```

### 5.2 Audio
- **8 MP3** : musiques (thème, idle, quêtes, intro)
- **442+ WAV** : effets sonores (voix des personnages, UI, ambiance)

### 5.3 Polices
- `teen-regular.ttf` / `teen-bold.ttf` — Police principale
- `komika-hand-regular.ttf` — Police secondaire
- `goodfoot_currency_font.ttf` — Police monétaire
- Polices Noto pour langues non latines (arabe, japonais, devanagari, thaï)

---

## 6. Compression SPK1

Le repo inclut un outil Python (`tools/spk1_decompress.py`) qui reverse-engineer l'algorithme de compression `SPK1` du moteur Playdemic :

```
Format : "SPK1" + uint32_le(taille_décompressée) + données_compressées

Algorithme (GSINTPACK::UNPACKOLD depuis libpdandroid.so) :
- 0x00 : END
- 0x01-0x3F : LITERAL (copier N octets)
- 0x40-0x7F : SHORT BACKREF (2 octets)
- 0x80-0xBF : MEDIUM BACKREF (3 octets)
- 0xC0-0xFF : LONG BACKREF (4 octets)
```

Fallback zlib disponible. Le fichier `main.tcf` (1MB) est compressé en SPK1.

---

## 7. Localisations

7 langues complètes :
🇬🇧 Anglais, 🇫🇷 Français, 🇩🇪 Allemand, 🇪🇸 Espagnol, 🇯🇵 Japonais, 🇧🇷 Portugais, 🇹🇷 Turc

Plus un filtre de mots (`words.xml`) multilingue.

---

## 8. Stratégie de Portage Web

### 8.1 Ce qui est DIRECTEMENT réutilisable ✅

| Asset | Usage Web | Notes |
|-------|-----------|-------|
| **XML game data** (toutes les tables) | Parser en JSON côté client | C'est la logique du jeu entière |
| **TGA textures** (1528) | Convertir en PNG/WebP | TGA → PNG via ImageMagick |
| **PNG images** (1035) | Utiliser tel quel | Surtout UI Android, mais certaines utiles |
| **WAV/MP3 audio** | Web Audio API | Formats supportés nativement |
| **Polices TTF/OTF** | @font-face CSS | Support direct |
| **Shaders GLSL** | WebGL | Très proche d'OpenGL ES 2.0, adaptation mineure |
| **common.xml** (i18n) | Système de localisation | 7 langues prêtes |
| **art_dialog** (JSON) | Logique UI/dialogues | JSON embarqué dans les rows |
| **SPK1 decompressor** | Portage en JS | Algorithme simple, déjà en Python |

### 8.2 Ce qui nécessite du REVERSE-ENGINEERING ⚠️

| Format | Difficulté | Approche |
|--------|-----------|----------|
| `.bin` (avatar props) | 🔴 Haute | Maillages 3D propriétaires — nécessite analyse hexadécimale |
| `.anx` (animations) | 🔴 Haute | Format d'animation squelettale propriétaire |
| `.tcf` / `.t3g` (main config + GUI) | 🔴 Haute | Format conteneur principal — clé du portage |
| `.dta` (zone data) | 🟠 Moyenne | Données de zones, probablement structure simple |
| `.bsh` (mesh data) | 🟠 Moyenne | Header texte avec nom + chemin texture, puis mesh binaire |
| `.bdl` (bundles 3D) | 🟠 Moyenne | Seulement 2 fichiers (locket) |
| `.t3t` (bitmap fonts) | 🟡 Basse | 4 fichiers, remplaçables par TTF |
| `.smv` (movement) | 🟡 Basse | 1 fichier |

### 8.3 Ce qu'il faut REMPLACER 🔄

| Composant Android | Remplacement Web |
|-------------------|-----------------|
| `libpdandroid.so` (moteur C++) | Nouveau moteur en **JavaScript + WebGL** (ou PixiJS/Three.js) |
| `libjs.so` (SpiderMonkey) | Moteur JS du navigateur (V8/SpiderMonkey natif) |
| `classes.dex` (Google Play, etc.) | Supprimer (pub, achats, push) |
| OpenGL ES 2.0 | **WebGL** (API quasi identique) |
| Système de fichiers Android | **IndexedDB** + fetch API |
| `libadcolony.so` | Supprimer ou remplacer par ads web |

---

## 9. Plan de Portage Recommandé

### Phase 1 : Extraction et Conversion des Assets
1. **Décompresser** `main.tcf` avec SPK1 → analyser le contenu
2. **Convertir** les 1528 TGA en PNG/WebP
3. **Parser** tous les XML en JSON
4. **Copier** les WAV/MP3/TTF tels quels

### Phase 2 : Moteur de Rendu Web
1. **Adapter les shaders** GLSL → WebGL (changements mineurs : `precision`, `varying` → `in/out` si WebGL2)
2. **Créer un renderer 2D** (le jeu est principalement isométrique 2D avec effets 3D)
3. Option : utiliser **PixiJS** (2D optimisé) ou **Three.js** (si le 3D des modèles locket est important)

### Phase 3 : Logique de Jeu
1. **Implémenter** le moteur de tables XML (building, crafting, farming, etc.)
2. **Reproduire** le système de quêtes/séquences depuis les `seq_state_tablet_*`
3. **Implémenter** le système économique (matériaux, récompenses, niveaux)
4. **Sauvegarde** : LocalStorage / IndexedDB

### Phase 4 : Formats Propriétaires (optionnel/avancé)
1. Reverse-engineer `.bin` pour les avatars 3D → ou les remplacer par des sprites 2D
2. Reverse-engineer `.anx` pour les animations → ou les remplacer par des spritesheets
3. Décoder `village.t3g` pour l'interface principale

---

## 10. Estimation de Faisabilité

| Aspect | Score | Commentaire |
|--------|-------|-------------|
| **Données de jeu** | 🟢 95% | Tout est en XML lisible, c'est exceptionnel |
| **Audio** | 🟢 100% | Formats web standard |
| **Textures UI** | 🟢 90% | TGA facile à convertir |
| **Localisations** | 🟢 100% | 7 langues complètes en XML |
| **Shaders** | 🟡 70% | GLES → WebGL adapté, mais complexe |
| **Modèles 3D** | 🔴 20% | Formats propriétaires, gros reverse-engineering |
| **Animations** | 🔴 20% | `.anx` propriétaire |
| **GUI système** | 🔴 30% | `.t3g` propriétaire, à recréer |

### Verdict : **Portage partiel très faisable, portage complet ambitieux**

Un **portage fonctionnel** avec toute la logique de jeu, les données, les textures converties, l'audio et les textes est tout à fait réalisable. Le plus gros défi sera de recréer le **rendu visuel** (personnages 3D, animations) si on ne décode pas les formats propriétaires. Une approche 2D/sprite-based serait plus pragmatique.
