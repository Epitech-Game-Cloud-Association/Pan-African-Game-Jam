# THE WEAVER — Base Projet Godot 4
**GameCloud · Pan African Game Jam**

---

## 📁 STRUCTURE DE FICHIERS

```
the_weaver/
├── project.godot
├── export_presets.cfg
│
├── scenes/
│   ├── core/
│   │   ├── GameManager.tscn        # Autoload — état global du jeu
│   │   ├── SceneTransition.tscn    # Fondu entre scènes
│   │   └── InputHandler.tscn       # Gestion input mobile/desktop
│   │
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn                # Needle cooldown, health thread
│   │   ├── PauseMenu.tscn
│   │   ├── LoreFragment.tscn       # Modal fragment de lore
│   │   └── EndScreen.tscn          # Choix final repair/tear
│   │
│   ├── world/
│   │   ├── zones/
│   │   │   └── ZoneInverse.tscn    # La zone prototype
│   │   ├── Checkpoint.tscn
│   │   ├── UnstableZone.tscn
│   │   ├── LorePickup.tscn
│   │   └── ExitRift.tscn           # La grande déchirure de sortie
│   │
│   └── player/
│       ├── Player.tscn
│       └── NeedleEffect.tscn       # VFX du pli spatial
│
├── scripts/
│   ├── core/
│   │   ├── GameManager.gd
│   │   ├── SceneTransition.gd
│   │   └── InputHandler.gd
│   │
│   ├── player/
│   │   ├── Player.gd
│   │   ├── PlayerMovement.gd
│   │   ├── PlayerNeedle.gd         # Mécanique de pli spatial
│   │   └── PlayerState.gd          # State machine du joueur
│   │
│   ├── world/
│   │   ├── ZoneBase.gd             # Classe parente pour toutes les zones
│   │   ├── ZoneInverse.gd
│   │   ├── Checkpoint.gd
│   │   ├── UnstableZone.gd
│   │   └── ExitRift.gd
│   │
│   └── ui/
│       ├── HUD.gd
│       └── LoreFragment.gd
│
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── world/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
│
└── resources/
    ├── PlayerData.tres             # Resource custom état joueur
    ├── ZoneConfig.tres             # Config par zone (gravité, palette...)
    └── LoreFragmentData.tres
```

---
