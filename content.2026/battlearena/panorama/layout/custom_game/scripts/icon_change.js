function GetPortraitHero(hero)
{
    if (hero == "npc_dota_hero_meepo")
    {
        hero = "npc_dota_hero_aghanim"
    }
    if (hero == "npc_dota_hero_chen")
    {
        hero = "npc_dota_hero_creep"
    }
    if (hero == "npc_dota_hero_arc_warden")
    {
        hero = "npc_dota_hero_roshan_alt"
    }
    return hero
}