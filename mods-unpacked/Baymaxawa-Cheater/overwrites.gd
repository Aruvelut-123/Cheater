extends Node

const MOD_NAME := "Cheater"

func _init():
    if ModLoaderMod.is_mod_loaded("GlitchedData-MultiPlayer"):
        var overwrite_0 = preload("res://mods-unpacked/Baymaxawa-Cheater/overwrites/InviteMenu.gd").new().get_script()
        overwrite_0.take_over_path("res://mods-unpacked/GlitchedData-MultiPlayer/utils/InviteMenu.gd")
        ModLoaderLog.warning("Multiplayer chat hacked!", MOD_NAME)
    else:
        ModLoaderLog.warning("Multiplayer mod not loaded, skipping hack chat...", MOD_NAME)