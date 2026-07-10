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

# --- SETTINGS: audio volume steps (0 = mute .. Audio.VOL_STEPS = full mix).
# Stored per bus name; the Audio autoload reads + applies these at startup and
# the SETTINGS screen writes them live (see Audio.set_volume_step).
var volume_steps: Dictionary = {}

# The game is gamepad-only with no keyboard fallback, so a first-time player has
# no way to discover the buttons. The title screen opens HOW TO PLAY once, on the
# very first launch, then flips this and never does it again.
var seen_howto: bool = false

# --- CAREER MODE: the ONE persistent dino you raise across the journey. Unlike a
# gauntlet run (throwaway, lives on MatchConfig), a career survives quitting the
# game, so its whole state persists here. Forgiving-with-stakes: losses cost mood
# + leave a scar but never end the journey. See CAREER_MODE_PLAN.md. ---
var career_started: bool = false   # a career exists to RESUME
var career_dino: String = ""       # the bonded dino id — chosen ONCE
var career_name: String = ""       # player-given name (cute, optional)
var career_xp: int = 0             # spendable growth points (TRAIN spends these)
var career_pips: Dictionary = {}   # stat id -> pips bought {power,speed,toughness,guard}
var career_mood: int = 70          # 0..100 — FEED raises, losses lower, decays per stop
var career_hp_carry: int = -1      # HP into the next fight; -1 = full (REST restores)
var career_stop: int = 0           # index into the journey (MatchConfig builds it)
var career_wins: int = 0
var career_losses: int = 0
var career_scars: Array = []       # loss flavor lines — story texture, display-only

# Per-pip growth (longer-grind tuning). POWER/SPEED are multiplicative, TOUGHNESS/
# GUARD flat. Cost to buy the Nth pip in a stat rises so the grind lengthens.
const CAREER_STATS := ["power", "speed", "toughness", "guard"]
const CAREER_PIP_POWER := 0.06     # +6% dmg per POWER pip
const CAREER_PIP_SPEED := 0.04     # +4% move speed per SPEED pip
const CAREER_PIP_TOUGH := 14       # +14 max HP per TOUGHNESS pip
const CAREER_PIP_GUARD := 12       # +12 max block per GUARD pip
const CAREER_PIP_BASE_COST := 80   # XP for the first pip in a stat
const CAREER_PIP_STEP_COST := 40   # +this per pip already owned in that stat
const CAREER_MOOD_START := 70
const CAREER_MOOD_DECAY := 8        # mood lost per stop travelled
const CAREER_FEED_MOOD := 20        # mood gained per FEED
const CAREER_FEED_COST := 15        # coins per FEED
const CAREER_WIN_MOOD := 8
const CAREER_LOSS_MOOD := 15

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
		# A corrupt/old save could return a non-Array or a short one; downstream code
		# (record_season, division displays) assumes length 3 and would crash on a
		# negative/out-of-range index.
		if typeof(season_titles_by_division) != TYPE_ARRAY or season_titles_by_division.size() < 3:
			season_titles_by_division = [0, 0, 0]
		owned_skins = cfg.get_value("cosmetics", "owned_skins", {})
		skins = cfg.get_value("cosmetics", "skins", {})
		volume_steps = cfg.get_value("settings", "volume_steps", {})
		if typeof(volume_steps) != TYPE_DICTIONARY:
			volume_steps = {}
		seen_howto = bool(cfg.get_value("settings", "seen_howto", false))
		career_started = bool(cfg.get_value("career", "started", false))
		career_dino = str(cfg.get_value("career", "dino", ""))
		career_name = str(cfg.get_value("career", "name", ""))
		career_xp = int(cfg.get_value("career", "xp", 0))
		career_pips = cfg.get_value("career", "pips", {})
		career_mood = int(cfg.get_value("career", "mood", CAREER_MOOD_START))
		career_hp_carry = int(cfg.get_value("career", "hp_carry", -1))
		career_stop = int(cfg.get_value("career", "stop", 0))
		career_wins = int(cfg.get_value("career", "wins", 0))
		career_losses = int(cfg.get_value("career", "losses", 0))
		career_scars = cfg.get_value("career", "scars", [])
		if typeof(career_pips) != TYPE_DICTIONARY:
			career_pips = {}
		if typeof(career_scars) != TYPE_ARRAY:
			career_scars = []

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
	cfg.set_value("settings", "volume_steps", volume_steps)
	cfg.set_value("settings", "seen_howto", seen_howto)
	cfg.set_value("career", "started", career_started)
	cfg.set_value("career", "dino", career_dino)
	cfg.set_value("career", "name", career_name)
	cfg.set_value("career", "xp", career_xp)
	cfg.set_value("career", "pips", career_pips)
	cfg.set_value("career", "mood", career_mood)
	cfg.set_value("career", "hp_carry", career_hp_carry)
	cfg.set_value("career", "stop", career_stop)
	cfg.set_value("career", "wins", career_wins)
	cfg.set_value("career", "losses", career_losses)
	cfg.set_value("career", "scars", career_scars)
	cfg.save(SAVE_PATH)

# Selected skin index for a dino (0 = DEFAULT).
func get_skin(dino_id: String) -> int:
	return int(skins.get(dino_id, 0))

# Equip + persist a dino's skin.
func set_skin(dino_id: String, idx: int) -> void:
	skins[dino_id] = int(idx)
	_save()

# Persist one bus's volume step (the Audio autoload owns applying it).
func set_volume_step(bus: String, step: int) -> void:
	volume_steps[bus] = step
	_save()

func mark_howto_seen() -> void:
	if seen_howto:
		return
	seen_howto = true
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

# --- CAREER MODE helpers -----------------------------------------------------

# Begin a fresh career with a chosen bonded dino. Wipes any prior career.
func career_begin(dino_id: String, given_name: String = "") -> void:
	career_started = true
	career_dino = dino_id
	career_name = given_name
	career_xp = 0
	career_pips = {}
	career_mood = CAREER_MOOD_START
	career_hp_carry = -1
	career_stop = 0
	career_wins = 0
	career_losses = 0
	career_scars = []
	_save()

func career_pip_count(stat: String) -> int:
	return int(career_pips.get(stat, 0))

# Total pips bought = the dino's "growth level" (display + story gating).
func career_level() -> int:
	var n: int = 0
	for s in CAREER_STATS:
		n += career_pip_count(s)
	return n

# XP price of the NEXT pip in a stat (rises with pips already owned — the grind).
func career_pip_cost(stat: String) -> int:
	return CAREER_PIP_BASE_COST + CAREER_PIP_STEP_COST * career_pip_count(stat)

func career_can_train(stat: String) -> bool:
	return stat in CAREER_STATS and career_xp >= career_pip_cost(stat)

# TRAIN: spend XP to buy one permanent pip in a stat. True if it went through.
func career_train(stat: String) -> bool:
	if not career_can_train(stat):
		return false
	career_xp -= career_pip_cost(stat)
	career_pips[stat] = career_pip_count(stat) + 1
	_save()
	return true

# FEED: raise mood, costs coins. True if affordable.
func career_feed() -> bool:
	if not spend_coins(CAREER_FEED_COST):  # spend_coins already persists
		return false
	career_mood = clampi(career_mood + CAREER_FEED_MOOD, 0, 100)
	_save()
	return true

# REST: heal the carried HP back to full (a fresh fight) + a small mood lift.
func career_rest() -> void:
	career_hp_carry = -1
	career_mood = clampi(career_mood + 5, 0, 100)
	_save()

# Record a finished career fight, awarding XP/coins and moving mood + HP carry.
# Forgiving-with-stakes: a loss still advances but costs mood + leaves a scar.
func career_record_fight(won: bool, xp_gain: int, coin_gain: int, hp_left: int, scar: String = "") -> void:
	career_xp += maxi(0, xp_gain)
	if coin_gain > 0:
		coins += coin_gain
	career_hp_carry = hp_left
	if won:
		career_wins += 1
		career_mood = clampi(career_mood + CAREER_WIN_MOOD, 0, 100)
	else:
		career_losses += 1
		career_mood = clampi(career_mood - CAREER_LOSS_MOOD, 0, 100)
		if scar != "":
			career_scars.append(scar)
	_save()

# Travel to the next stop: mood drifts down a little each leg.
func career_advance_stop() -> void:
	career_stop += 1
	career_mood = clampi(career_mood - CAREER_MOOD_DECAY, 0, 100)
	_save()
