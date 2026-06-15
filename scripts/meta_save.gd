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

# --- Phase 3 season economy + standings (all persisted below) ---
# COINS: earned per matchday/season win (scaled by division), spent in the SHOP on
# coin-gated skins + CONTINUE TOKENS. Cosmetic / soft-safety only — never pay-to-win.
var coins: int = 0
# Skin indices the player has bought (free skins are implicitly owned — see
# MatchConfig.skin_unlocked). Stored as a set: {idx: true}.
var owned_skins: Dictionary = {}
# CONTINUE TOKENS: a consumable that revives a lost season at the failed matchday.
var continue_tokens: int = 0
# DIVISIONS: the campaign climbs ROOKIE(0) -> PRO(1) -> LEGEND(2). `best_division`
# is the highest ever CLEARED (won the finale of), for the trophy cabinet + as the
# division a fresh campaign can start in.
var best_division: int = 0
# Lifetime counters for the TROPHY CABINET (display-only milestones).
var matchdays_won: int = 0
var season_titles_by_division: Array = [0, 0, 0]  # championships won per division

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
		coins = int(cfg.get_value("season", "coins", 0))
		continue_tokens = int(cfg.get_value("season", "continue_tokens", 0))
		best_division = int(cfg.get_value("season", "best_division", 0))
		matchdays_won = int(cfg.get_value("season", "matchdays_won", 0))
		season_titles_by_division = cfg.get_value("season", "titles_by_division", [0, 0, 0])
		owned_skins = cfg.get_value("cosmetics", "owned_skins", {})
		skins = cfg.get_value("cosmetics", "skins", {})

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gauntlet", "best_wave", best_wave)
	cfg.set_value("gauntlet", "runs", runs)
	cfg.set_value("season", "seasons_won", seasons_won)
	cfg.set_value("season", "coins", coins)
	cfg.set_value("season", "continue_tokens", continue_tokens)
	cfg.set_value("season", "best_division", best_division)
	cfg.set_value("season", "matchdays_won", matchdays_won)
	cfg.set_value("season", "titles_by_division", season_titles_by_division)
	cfg.set_value("cosmetics", "owned_skins", owned_skins)
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

# Record a won SEASON in `division`; returns true if this win newly unlocked the
# CHAMPION skin (i.e. it was the player's first). Bumps best_division (promotion is
# permanent), tallies the per-division title, then persists.
func record_season(division: int = 0) -> bool:
	var was_first: bool = seasons_won == 0
	seasons_won += 1
	division = clampi(division, 0, season_titles_by_division.size() - 1)
	season_titles_by_division[division] += 1
	best_division = maxi(best_division, mini(division + 1, MAX_DIVISION))
	_save()
	return was_first

# The additive CHAMPION GOLD skin is earned by winning a season (see MatchConfig.SKINS).
func champion_skin_unlocked() -> bool:
	return seasons_won >= 1

# --- Phase 3: divisions ---
const DIVISION_NAMES := ["ROOKIE", "PRO", "LEGEND"]
const MAX_DIVISION := 2  # LEGEND is the top; index into DIVISION_NAMES

func division_name(d: int) -> String:
	return DIVISION_NAMES[clampi(d, 0, MAX_DIVISION)]

# The highest division a fresh campaign may start in (you keep your promotions).
func unlocked_division() -> int:
	return clampi(best_division, 0, MAX_DIVISION)

# --- Phase 3: coin economy ---
func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	_save()

func spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	_save()
	return true

func add_continue_token(n: int = 1) -> void:
	continue_tokens = maxi(0, continue_tokens + n)
	_save()

# Spend one CONTINUE TOKEN (to revive a lost season). True if one was available.
func use_continue_token() -> bool:
	if continue_tokens <= 0:
		return false
	continue_tokens -= 1
	_save()
	return true

func record_matchday_win() -> void:
	matchdays_won += 1
	_save()

# --- Phase 3: coin-purchased skin ownership ---
func owns_skin(idx: int) -> bool:
	return bool(owned_skins.get(idx, false))

func buy_skin(idx: int) -> void:
	owned_skins[idx] = true
	_save()
