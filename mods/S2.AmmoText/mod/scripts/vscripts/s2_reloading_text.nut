untyped
global function reloadingTextPrecache
global function reloadingTextSettings

void function reloadingTextSettings(){
    #if UI
    AddModTitle("S2.AmmoText")
    AddModCategory("Main")
    AddConVarSetting("s2_reload_main_pos", "Position", "vector")
    AddConVarSetting("s2_reload_main_size", "Font Size", "float")
    AddConVarSettingEnum("s2_reload_main_pilots", "Pilot Weapons", ["Off", "On"])
    AddConVarSettingEnum("s2_reload_main_titans", "Titan Weapons", ["Off", "On"])
    AddConVarSettingEnum("s2_reload_ads_fade", "ADS Fade Toggle", ["Off", "On"])
    AddConVarSetting("s2_reload_ads_fade_opa", "ASD Alpha", "float")

    AddModCategory("Low Ammo")
    AddConVarSetting("s2_reload_low_text", "Text", "string")
    AddConVarSetting("s2_reload_low_reserve_text", "No Extra Ammo Text", "string")
    AddConVarSetting("s2_reload_low_alpha", "Alpha", "float")
    AddConVarSetting("s2_reload_min_ammo", "Magazine %", "Int")
    AddConVarSetting("s2_reload_low_static_col", "Static Colour", "vector")
    AddConVarSettingEnum("s2_reload_low_is_static", "Static Colour Toggle", ["Off", "On"])
    AddConVarSetting("s2_reload_low_first_col", "First Colour", "vector")
    AddConVarSetting("s2_reload_low_second_col", "Second Colour", "vector")
    AddConVarSetting("s2_reload_flash_min_ammo", "Flash Magazine %", "Int")
    AddConVarSettingEnum("s2_reload_low_flash", "Flash Toggle", ["Off", "On"])
    AddConVarSettingEnum("s2_reload_low_rgb", "RGB Cycle Toggle", ["Off", "On :D"])

    AddModCategory("Reloading")
    AddConVarSetting("s2_reload_none_text", "Text","string")
    AddConVarSetting("s2_reload_none_alpha", "Alpha","float")
    AddConVarSetting("s2_reload_none_col", "Colour","vector")
    AddConVarSettingEnum("s2_reload_none_flash", "Flash Toggle", ["Off", "On"])
    AddConVarSettingEnum("s2_reload_none_rgb", "RGB Cycle Toggle",["Off", "On :D"])
    #endif
}

void function reloadingTextPrecache(){
    #if CLIENT
    thread reloadingTextMain()
    #endif
}

#if CLIENT

vector function GetConVarFloat3(string convar){
    array<string> value = split(GetConVarString(convar), " ")
    try{
        return Vector(value[0].tofloat(), value[1].tofloat(), value[2].tofloat()) 
    }
    catch(ex){
        throw "Invalid convar " + convar + "! make sure it is a float3 and formatted as \"X Y Z\""
    }
    unreachable
}

float function GetMinAmmoFrac(inputConVar){
    int percentConVar = GetConVarInt(inputConVar)
    if(percentConVar > 0)
        return float(percentConVar)/100
    else{
        SetConVarInt("s2_reload_min_ammo", 30)
        throw "Invalid input, Magazine % can't be below or equal to 0!\nIf you want to disable Low Ammo set its Alpha to 0.0!"
    }
    unreachable
}

void function reloadingTextMain(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, -1 )
    RuiSetInt(rui, "maxLines", 1)
    RuiSetInt(rui, "lineNum", 1)
    RuiSetFloat2(rui, "msgPos", <0.6, 0.6, 0.0>)
    RuiSetString(rui, "msgText", "Low Ammo")
    RuiSetFloat(rui, "msgFontSize", 20.0)
    RuiSetFloat(rui, "msgAlpha", 0.0)
    RuiSetFloat(rui, "thicken", 0.0)
    RuiSetFloat3(rui, "msgColor", <1.0, 1.0, 1.0>)
    for(;;){
        WaitFrame()

        ////    ModSettings

        //  main
        float mainSize = GetConVarFloat("s2_reload_main_size")
        float mainAdsAlpha = GetConVarFloat("s2_reload_ads_fade_opa")
        bool mainAdsToggle = (GetConVarInt("s2_reload_ads_fade") == 1)
        bool mainPilotWeapons = (GetConVarInt("s2_reload_main_pilots") == 1)
        bool mainTitanWeapons = (GetConVarInt("s2_reload_main_titans") == 1)
        vector mainPos = GetConVarFloat3("s2_reload_main_pos")

        //  low
        float lowAlpha = GetConVarFloat("s2_reload_low_alpha")
        float minAmmoFrac = GetMinAmmoFrac("s2_reload_min_ammo")
        float flashMinAmmoFrac = GetMinAmmoFrac("s2_reload_flash_min_ammo")
        bool lowIsStatic = (GetConVarInt("s2_reload_low_is_static") == 1)
        bool lowIsFlash = (GetConVarInt("s2_reload_low_flash") == 1)
        bool lowIsRGB = (GetConVarInt("s2_reload_low_rgb") == 1)
        vector lowStaticCol = GetConVarFloat3("s2_reload_low_static_col")
        vector lowFirstCol = GetConVarFloat3("s2_reload_low_first_col")
        vector lowSecondCol = GetConVarFloat3("s2_reload_low_second_col")
        string lowText = GetConVarString("s2_reload_low_text")
        string lowReserveText = GetConVarString("s2_reload_low_reserve_text")

        //  none
        float noneAlpha = GetConVarFloat("s2_reload_none_alpha")
        bool noneIsFlash = (GetConVarInt("s2_reload_none_flash") == 1)
        bool noneIsRGB = (GetConVarInt("s2_reload_none_rgb") == 1)
        vector noneCol = GetConVarFloat3("s2_reload_none_col")
        string noneText = GetConVarString("s2_reload_none_text")

        ////

        RuiSetFloat(rui, "msgAlpha", 0.0)
        RuiSetFloat(rui, "msgFontSize", mainSize)
        RuiSetFloat2(rui, "msgPos", mainPos)
        entity player = GetLocalClientPlayer()
        if(player == null || !IsValid(player))
			continue
        if(!IsAlive(player))
            continue
        if(IsWatchingKillReplay() || IsWatchingReplay() || IsWatchingSpecReplay())
            continue
        if(player != GetLocalViewPlayer())
            continue
        entity weapon = player.GetActiveWeapon()
        if(!IsValid(weapon))
			continue
        string currentWeaponName = weapon.GetWeaponClassName()
        if(weaponNameCheck(currentWeaponName, mainPilotWeapons, mainTitanWeapons)){
            float currentAmmo
            float maxAmmo
            float reserveAmmo = float(weapon.GetWeaponPrimaryAmmoCount())
            if(currentWeaponName != "mp_weapon_defender"){
                currentAmmo = float(weapon.GetWeaponPrimaryClipCount())
                maxAmmo = float(weapon.GetWeaponPrimaryClipCountMax())
            }
            else{
                currentAmmo = reserveAmmo
                maxAmmo = (weapon.HasMod("extended_ammo")) ? 25.0 : 20.0
            }
            float ammoFrac = currentAmmo/maxAmmo
            vector rainbow
            float zoomFrac = player.GetZoomFrac()
            if(weapon.IsReloading() || (currentAmmo == 0 && reserveAmmo > 0)){
                float noneFlashAlpha
                if(noneIsFlash)
                    noneFlashAlpha = (sin(Time() * PI * 2)) + 1
                else
                    noneFlashAlpha = 1
                if(!mainAdsToggle)
                    RuiSetFloat(rui, "msgAlpha", noneAlpha)
                else
                    RuiSetFloat(rui, "msgAlpha", (((zoomFrac/1)*mainAdsAlpha) + ((1-(zoomFrac/1))*noneAlpha))*noneFlashAlpha)
                if(weapon.IsReloading())
                    RuiSetString(rui, "msgText", noneText)
                else
                    RuiSetString(rui, "msgText", lowText)
                if(!noneIsRGB)
                    RuiSetFloat3(rui, "msgColor", noneCol)
                else{
                    rainbow.x = sin(Time() * PI * 2)
                    rainbow.y = sin((Time() + 1.0/3.0) * PI * 2)
                    rainbow.z = sin((Time() + 2.0/3.0) * PI * 2)
                    RuiSetFloat3(rui, "msgColor", rainbow)
                }
            }
            else if(ammoFrac <= minAmmoFrac){
                float lowFlashAlpha
                if(lowIsFlash && currentAmmo <= 1)
                    lowFlashAlpha = (sin(Time() * PI * 8))
                else if(lowIsFlash && ammoFrac <= flashMinAmmoFrac)
                    lowFlashAlpha = (sin(Time() * PI * 3)) + 1
                else
                    lowFlashAlpha = 1
                if(!mainAdsToggle)
                    RuiSetFloat(rui, "msgAlpha", lowAlpha)
                else
                    RuiSetFloat(rui, "msgAlpha", (((zoomFrac/1)*mainAdsAlpha) + ((1-(zoomFrac/1))*lowAlpha))*lowFlashAlpha)
                if(currentAmmo == 0)
                    RuiSetString(rui, "msgText", lowReserveText)
                else
                    RuiSetString(rui, "msgText", lowText)
                if(!lowIsRGB){
                    if(lowIsStatic)
                        RuiSetFloat3(rui, "msgColor", lowStaticCol)
                    else{
                        if(currentAmmo >= 1)
                            ammoFrac = (currentAmmo - 1)/(maxAmmo - 1)
                        else
                            ammoFrac = 0
                        RuiSetFloat3(rui, "msgColor", (((ammoFrac/minAmmoFrac) * lowFirstCol) + ((1 - (ammoFrac/minAmmoFrac)) * lowSecondCol)))
                    }
                }
                else{
                    rainbow.x = sin(Time() * PI * 2)
                    rainbow.y = sin((Time() + 1.0/3.0) * PI * 2)
                    rainbow.z = sin((Time() + 2.0/3.0) * PI * 2)
                    RuiSetFloat3(rui, "msgColor", rainbow)
                }
            }
        }
    }
}

array<string> compatiblePilotWeapons = [
    "mp_weapon_alternator_smg",
	"mp_weapon_arc_launcher",
	"mp_weapon_autopistol",
	"mp_weapon_car",
	"mp_weapon_defender",
	"mp_weapon_dmr",
	"mp_weapon_doubletake",
	"mp_weapon_epg",
	"mp_weapon_esaw",
	"mp_weapon_g2",
	"mp_weapon_hemlok",
	"mp_weapon_hemlok_smg",
	"mp_weapon_lmg",
	"mp_weapon_lstar",
	"mp_weapon_mastiff",
	"mp_weapon_mgl",
	"mp_weapon_pulse_lmg",
	"mp_weapon_r97",
	"mp_weapon_rocket_launcher",
	"mp_weapon_rspn101",
	"mp_weapon_rspn101_og",
	"mp_weapon_semipistol",
	"mp_weapon_shotgun",
	"mp_weapon_shotgun_pistol",
	"mp_weapon_smart_pistol",
	"mp_weapon_smr",
	"mp_weapon_sniper",
	"mp_weapon_softball",
	"mp_weapon_vinson",
	"mp_weapon_wingman",
	"mp_weapon_wingman_n"
]

array<string> compatibleTitanWeapons = [
    "mp_titanweapon_leadwall",
	"mp_titanweapon_meteor",
	"mp_titanweapon_particle_accelerator",
	"mp_titanweapon_predator_cannon",
	"mp_titanweapon_sniper",
	"mp_titanweapon_sticky_40mm",
	"mp_titanweapon_xo16_vanguard"
]

bool function weaponNameCheck(string weaponName, bool pilot, bool titan){
    if(pilot){
        foreach(entry in compatiblePilotWeapons){
            if(weaponName == entry)
                return true
        }
    }
    if(titan){
        foreach(entry in compatibleTitanWeapons){
            if(weaponName == entry)
                return true
        }
    }
    return false
}

#endif