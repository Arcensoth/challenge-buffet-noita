dofile_once("data/scripts/lib/utilities.lua")

local ns = dofile_once("mods/io__github__arcensoth__challenge_buffet/files/scripts/utils/namespacing.lua")
local log = dofile_once(ns.file("scripts/utils/logging.lua"))
local tags = dofile_once(ns.file("scripts/const/tags.lua"))
dofile_once(ns.file("scripts/utils/effects.lua"))

local data = {}

-- @@ PROPERTIES

data.name = "bane_of_midas"
data.perk_id = ns.key(data.name)
data.title = "Bane of Midas"
data.description = "You are cursed: gold is deadly and must be avoided"

data.gold_materials_that_damage = "gold,gold_static,gold_static_dark,gold_molten,gold_radioactive,gold_box2d,gold_b2,bloodgold_box2d"
data.gold_materials_how_much_damage = "0.00001,0.00001,0.00001,0.00001,0.00001,0.00001,0.00001,0.00001"
data.midas_materials_that_damage = "midas,midas_precursor"
data.midas_materials_how_much_damage = "0.00001,0.00001"

-- @@ METHODS

data.do_gold_death = function(entity)
    -- Make sure this only happens once.
    if (EntityHasTag(entity, tags.bane_of_midas_death)) then
        return nil
    end
    EntityAddTag(entity, tags.bane_of_midas_death)
    -- Get the player's coordinates.
    local x, y = EntityGetTransform(entity)
    log.debug("Spawning gold death at: " .. x, ", " .. y)
    -- Make sure they aren't invincible.
    purge_effects_and_stains(entity)
    -- Create a (custom) touch of gold projectile to convert the player body into gold dust.
    local projectile_id = EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/gold_death.xml"), x, y)
    EntityAddChild(entity, projectile_id)
    -- Play the freezing sound for effect.
    GamePlaySound(ns.base_sound("misc"), "game_effect/frozen/create", x, y)
    -- Place the gold player statue.
    EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/gold_burst.xml"), x, y)
    EntityLoad(ns.base_file("entities/animals/boss_centipede/rewards/gold_reward.xml"), x, y)
end

data.do_midas_death = function(entity)
    -- Make sure this only happens once.
    if (EntityHasTag(entity, tags.bane_of_midas_death)) then
        return nil
    end
    EntityAddTag(entity, tags.bane_of_midas_death)
    -- Get the player's coordinates.
    local x, y = EntityGetTransform(entity)
    log.debug("Spawning midas death at: " .. x, ", " .. y)
    -- Create a devastating touch of midas projectile.
    local projectile_id = EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/midas_death.xml"), x, y)
    EntityAddChild(entity, projectile_id)
    EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/midas_burst.xml"), x, y)
    EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/midas_conversion.xml"), x, y)
    EntityLoad(ns.file("perks/" .. data.name .. "/projectiles/midas_explosion.xml"), x, y)
end

-- @@ HANDLERS

data.on_init = function(entity_perk_item, entity_who_picked, item_name)
    log.debug("Picked up perk: " .. data.name)
    -- Add a tag that we can detect during gold pick-ups.
    EntityAddTag(entity_who_picked, tags.bane_of_midas)
    -- Make gold dust solid for the player.
    local suckers = EntityGetComponent(entity_who_picked, "MaterialSuckerComponent")
	if (suckers ~= nil) then
		for i, sucker in ipairs(suckers) do
			ComponentSetValue(sucker, "suck_gold", 0)
		end
    end
    -- Cause the player to take (negligible) damage from gold materials.
    EntityAddComponent(
        entity_who_picked,
        "DamageModelComponent",
        {
            air_needed=0,
            falling_damages=0,
            fire_damage_amount=0,
            materials_damage=1,
            material_damage_min_cell_count=4,
            materials_that_damage=data.gold_materials_that_damage,
            materials_how_much_damage=data.gold_materials_how_much_damage,
        }
    )
    EntityAddComponent(
        entity_who_picked,
        "DamageModelComponent",
        {
            air_needed=0,
            falling_damages=0,
            fire_damage_amount=0,
            materials_damage=1,
            material_damage_min_cell_count=1,
            materials_that_damage=data.midas_materials_that_damage,
            materials_how_much_damage=data.midas_materials_how_much_damage,
        }
    )
    -- Detect when the player takes damage (from gold materials).
    EntityAddComponent(
        entity_who_picked,
        "LuaComponent",
        {
            script_damage_received=ns.file("perks/" .. data.name .. "/handles/damage_received.lua"),
        }
    )
    -- Also handle material ingested/inhaled events to check for gold.
    -- TODO Why don't these work?
    -- EntityAddComponent(
    --     entity_who_picked,
    --     "LuaComponent",
    --     {
    --         script_ingested_material=ns.file("perks/" .. data.name .. "/handles/ingested_material.lua"),
    --     }
    -- )
    -- EntityAddComponent(
    --     entity_who_picked,
    --     "LuaComponent",
    --     {
    --         script_inhaled_material=ns.file("perks/" .. data.name .. "/handles/inhaled_material.lua"),
    --     }
    -- )
end

data.on_gold_item_pickup = function(entity_item, entity_who_picked, item_name)
    if (EntityHasTag(entity_who_picked, tags.bane_of_midas)) then
        log.debug("Picked up gold while cursed")
        data.do_gold_death(entity_who_picked)
    end
end

-- @@ PERK DEFINITION

data.definition = {
	id = data.perk_id,
	ui_name = data.title,
	ui_description = data.description,
	ui_icon = ns.file("perks/" .. data.name .. "/icon.png"),
	perk_icon = ns.file("perks/" .. data.name .. "/item.png"),
	stackable = false,
	usable_by_enemies = false,
	func = data.on_init,
}

-- @@ RETURN

return data
