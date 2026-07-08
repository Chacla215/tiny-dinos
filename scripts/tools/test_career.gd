extends SceneTree
# Throwaway headless test for the CAREER data layer. Run:
#   /opt/homebrew/bin/godot --headless -s scripts/tools/test_career.gd
# Uses the LIVE autoloads (MetaSave/MatchConfig) and restores the real save.

var _ran := false

func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true
	_run()
	return false

func _run() -> void:
	var ok := true
	var MetaSave = root.get_node("/root/MetaSave")
	var MC = root.get_node("/root/MatchConfig")

	# NON-DESTRUCTIVE: stash the real save, restore it at the end.
	var SAVE := "user://gauntlet_save.cfg"
	var backup := ""
	if FileAccess.file_exists(SAVE):
		backup = FileAccess.get_file_as_string(SAVE)

	MetaSave.career_begin("ralph", "REX")
	print("begin: dino=%s name=%s level=%d mood=%d xp=%d" % [MetaSave.career_dino, MetaSave.career_name, MetaSave.career_level(), MetaSave.career_mood, MetaSave.career_xp])
	ok = ok and MetaSave.career_started and MetaSave.career_dino == "ralph"

	var stops: Array = MC.career_stops()
	print("journey: %d stops, rival=%s" % [stops.size(), MC.career_rival()])
	ok = ok and stops.size() == MC.CAREER_STOP_COUNT
	ok = ok and str(MC.career_stops()) == str(stops)  # deterministic rebuild
	for i in [0, 5, 8, 14, 20]:
		var s: Dictionary = stops[i]
		print("  stop %2d: %-16s %-7s vs %-7s [%s]%s%s" % [i, s.island, s.mode, s.foe, s.difficulty, "  RIVAL" if s.rival else "", "  BOSS" if s.boss else ""])
	ok = ok and stops[5].foe == MC.career_rival() and stops[20].boss and stops[20].foe == MC.career_rival()
	ok = ok and stops[0].foe != "ralph"  # never fight yourself

	# TRAIN: give XP, buy pips, check the stat bonus grows and cost rises.
	MetaSave.career_xp = 300
	var base_dmg: float = MC.career_stat_bonus().attack_damage[1]
	var cost0: int = MetaSave.career_pip_cost("power")
	var t1: bool = MetaSave.career_train("power")
	var cost1: int = MetaSave.career_pip_cost("power")
	print("train power: pip1=%s cost0=%d cost1=%d dmg_mul %.3f -> %.3f" % [t1, cost0, cost1, base_dmg, MC.career_stat_bonus().attack_damage[1]])
	ok = ok and t1 and cost1 > cost0 and MC.career_stat_bonus().attack_damage[1] > base_dmg
	MetaSave.career_train("toughness")
	print("toughness pip -> +%d max_hp" % MC.career_stat_bonus().max_hp[1])
	ok = ok and MC.career_stat_bonus().max_hp[1] == MetaSave.CAREER_PIP_TOUGH

	# Mood buff: low mood penalizes, high mood buffs.
	MetaSave.career_mood = 20
	var low: float = MC.career_stat_bonus().max_speed[1]
	MetaSave.career_mood = 90
	var high: float = MC.career_stat_bonus().max_speed[1]
	print("mood: speed_mul low(20)=%.3f high(90)=%.3f" % [low, high])
	ok = ok and high > low

	# FEED needs coins; REST refills HP carry.
	MetaSave.coins = 100
	var moodb: int = MetaSave.career_mood
	MetaSave.career_feed()
	print("feed: mood %d -> %d, coins=%d" % [moodb, MetaSave.career_mood, MetaSave.coins])
	MetaSave.career_hp_carry = 30
	MetaSave.career_rest()
	print("rest: hp_carry -> %d" % MetaSave.career_hp_carry)
	ok = ok and MetaSave.career_hp_carry == -1

	# WIN + advance, then LOSS (still advances, scar logged).
	var rew: Dictionary = MC.career_win_reward()
	print("stop0 reward: xp=%d coins=%d" % [rew.xp, rew.coins])
	var before_stop: int = MetaSave.career_stop
	MetaSave.career_record_fight(true, rew.xp, rew.coins, 45, "")
	MetaSave.career_advance_stop()
	print("win+advance: stop %d->%d wins=%d mood=%d" % [before_stop, MetaSave.career_stop, MetaSave.career_wins, MetaSave.career_mood])
	ok = ok and MetaSave.career_stop == before_stop + 1 and MetaSave.career_wins == 1
	MetaSave.career_record_fight(false, 25, 0, -1, "LOST TO THE RIVAL AT THE FALLS")
	print("loss: losses=%d scars=%s mood=%d" % [MetaSave.career_losses, str(MetaSave.career_scars), MetaSave.career_mood])
	ok = ok and MetaSave.career_losses == 1 and MetaSave.career_scars.size() == 1

	# PERSISTENCE round-trip.
	var reload = preload("res://scripts/meta_save.gd").new()
	reload._load()
	print("reload: started=%s dino=%s stop=%d wins=%d power_pips=%d" % [reload.career_started, reload.career_dino, reload.career_stop, reload.career_wins, reload.career_pip_count("power")])
	ok = ok and reload.career_started and reload.career_dino == "ralph" and reload.career_pip_count("power") == 1

	# Restore the real save (or remove the file we created if there was none).
	if backup != "":
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		f.store_string(backup); f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	print("\n=== CAREER TEST %s ===" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
