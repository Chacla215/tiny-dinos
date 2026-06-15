extends Node
# Persistent cross-run progression for the roguelike GAUNTLET. Tracks the best
# wave ever reached and the lifetime run count; milestone unlocks are *derived*
# from best_wave (so they can never be lost) and auto-apply to future runs.
# Saved to user:// via ConfigFile so it survives between sessions.

const SAVE_PATH := "user://gauntlet_save.cfg"

var best_wave: int = 0
var runs: int = 0
# SEASON MODE progression: lifetime seasons won. Winning your first season unlocks
# the additive CHAMPION GOLD skin (a shader recolor — no art). Persisted below.
var seasons_won: int = 0

# Cosmetic skin chosen per dino id -> SKINS index (see MatchConfig.SKINS).
# Display-only progression; defaults to 0 (DEFAULT) for any dino not set.
var skins: Dictionary = {}

# Reach this wave (ever) to permanently unlock the perk. Ordered by threshold.
const UNLOCKS := [
	{"id": "extra_draft",   "wave": 3,  "name": "EXTRA DRAFT",   "blurb": "DRAFTS OFFER 4 UPGRADES"},
	{"id": "veteran_start", "wave": 6,  "name": "VETERAN START", "blurb": "BEGIN EACH RUN WITH AN UPGRADE"},
	{"id": "hardened",      "wave": 10, "name": "HARDENED",      "blurb": "+20 STARTING MAX HP"},
]

func _ready() -> void:
	_load()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_wave = int(cfg.get_value("gauntlet", "best_wave", 0))
		runs = int(cfg.get_value("gauntlet", "runs", 0))
		seasons_won = int(cfg.get_value("season", "seasons_won", 0))
		skins = cfg.get_value("cosmetics", "skins", {})

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gauntlet", "best_wave", best_wave)
	cfg.set_value("gauntlet", "runs", runs)
	cfg.set_value("season", "seasons_won", seasons_won)
	cfg.set_value("cosmetics", "skins", skins)
	cfg.save(SAVE_PATH)

# Selected skin index for a dino (0 = DEFAULT).
func get_skin(dino_id: String) -> int:
	return int(skins.get(dino_id, 0))

# Equip + persist a dino's skin.
func set_skin(dino_id: String, idx: int) -> void:
	skins[dino_id] = int(idx)
	_save()

func has_unlock(id: String) -> bool:
	for u in UNLOCKS:
		if u["id"] == id:
			return best_wave >= int(u["wave"])
	return false

func hp_bonus() -> int:
	return 20 if has_unlock("hardened") else 0

# Record a finished run; returns the unlock dicts this run newly crossed (for the
# RUN OVER "NEW UNLOCK!" banner), then persists.
func record_run(wave_reached: int) -> Array:
	runs += 1
	var newly: Array = []
	if wave_reached > best_wave:
		for u in UNLOCKS:
			if best_wave < int(u["wave"]) and wave_reached >= int(u["wave"]):
				newly.append(u)
		best_wave = wave_reached
	_save()
	return newly

# Record a won SEASON; returns true if this win newly unlocked the CHAMPION skin
# (i.e. it was the player's first), for the champion banner. Then persists.
func record_season() -> bool:
	var was_first: bool = seasons_won == 0
	seasons_won += 1
	_save()
	return was_first

# The additive CHAMPION GOLD skin is earned by winning a season (see MatchConfig.SKINS).
func champion_skin_unlocked() -> bool:
	return seasons_won >= 1
