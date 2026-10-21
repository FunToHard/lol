--- Narrative lore catalog and character dialogue registry for Lantern Grove.
-- Provides backstory, NPC profiles, contextual conversations, and idle chatter.
-- @module lore_catalog

local lore_catalog = {}

-- The overarching narrative backstory of Lantern Grove
lore_catalog.BACKSTORY = {
    title = "The Legend of the Great Hearth",
    summary = "Long ago, the Great Lantern burned with an eternal, comforting twilight flame that shielded the woodland creatures from the cold. When the Shadow Mist swept through the canopy, the Great Flame shattered into countless Lantern Sparks. The ancient hearth grew cold, and the grove fell into a deep slumber. You, the newly awakened Lantern Keeper, must gather the lost Sparks through match-3 trials to rekindle the village and dispel the mist forever."
}

-- NPC Character Profiles
lore_catalog.NPCS = {
    bramble = {
        id = "bramble",
        name = "Elder Bramble",
        title = "Village Elder & Guide",
        avatar = "village_bramble",
        bio = "A venerable hedgehog clad in a moss-woven traveling cloak, carrying an ancient lantern-topped staff.",
        default_dialogue = "Ah, young Keeper. Feel the chill in the air? The Grove remembers its warmth—we need only rekindle the hearth."
    },
    pip = {
        id = "pip",
        name = "Pip",
        title = "Apprentice Companion",
        avatar = "village_pip",
        bio = "An enthusiastic young burrowing owl with golden eyes and a leafy satchel, always eager to spot hidden sparks.",
        default_dialogue = "Hoo-hoo! The breeze feels friendlier already! Where should we place our next lantern?"
    },
    maeve = {
        id = "maeve",
        name = "Maeve",
        title = "Herbalist & Tea Mistress",
        avatar = "ingredient_acorn",
        bio = "A serene badger who brews calming wild teas and tends the blooming floral beds.",
        unlock_task = "rebuild_teahouse_kiosk",
        default_dialogue = "Welcome to the Teahouse, traveler. A cup of dried wisteria blossom tea warms even the coldest evening."
    },
    rowan = {
        id = "rowan",
        name = "Rowan",
        title = "Master Carpenter",
        avatar = "village_bench",
        bio = "A sturdy beaver craftsman dedicated to timber restoration and river engineering.",
        unlock_task = "rebuild_wooden_benches",
        default_dialogue = "Good timber never forgets its grain. With a few Sparks, this cedar will stand for a hundred winters."
    }
}

-- Narrative Dialogue Scripts (Indexed by trigger ID)
local CONVERSATIONS = {
    ["bramble_intro"] = {
        npc_id = "bramble",
        lines = {
            "Welcome, Lantern Keeper. I feared the Grove would remain in eternal twilight.",
            "The Great Lantern shattered when the Shadow Mist rolled across our valley.",
            "Each match you make in the puzzle groves gathers a Spark of that lost light.",
            "Start by clearing the autumn debris and lighting the central stone hearth. I shall guide your journey."
        }
    },
    ["bramble_hearth_restored"] = {
        npc_id = "bramble",
        lines = {
            "Look at those embers dance! The stones remember the ancient warmth.",
            "Now the path to the teahouse and well begins to clear. Keep gathering Sparks, Keeper!"
        }
    },
    ["bramble_courtyard_complete"] = {
        npc_id = "bramble",
        lines = {
            "Extraordinary! Hearthstone Courtyard is completely aglow with living light!",
            "Beyond the ancient stone archway lies Area 2: The Whispering Willow Pond.",
            "Its arched bridge and water-lanterns await your lantern's touch."
        }
    },
    ["pip_cheer"] = {
        npc_id = "pip",
        lines = {
            "Hoo-hoo! You did it! Did you see how the sparks fluttered into place?",
            "I'm keeping watch from the rafters! Let's restore another corner!"
        }
    },
    ["maeve_greeting"] = {
        npc_id = "maeve",
        lines = {
            "Ah, Keeper! The kettle is finally whistling again.",
            "The scent of roasted acorns and wild mint always brings peace to the Grove."
        }
    },
    ["rowan_greeting"] = {
        npc_id = "rowan",
        lines = {
            "Now that's a sturdy bench! No wobble, smooth cedar finish.",
            "When you're ready to cross the river to the Willow Pond, my hammer is at your service."
        }
    }
}

--- Retrieves the full profile descriptor for an NPC.
-- @param npc_id string Unique NPC identifier ('bramble', 'pip', 'maeve', 'rowan').
-- @return table|nil profile Character descriptor or nil if not found.
function lore_catalog.get_npc(npc_id)
    return lore_catalog.NPCS[npc_id]
end

--- Retrieves a scripted multi-line dialogue sequence by trigger key.
-- @param conversation_id string Conversation identifier.
-- @return table|nil conversation Table containing npc_id and array of lines.
function lore_catalog.get_conversation(conversation_id)
    return CONVERSATIONS[conversation_id]
end

--- Checks whether an NPC is unlocked based on village completed tasks.
-- @param npc_id string Unique NPC identifier.
-- @param completed_tasks table Array of completed task records.
-- @return boolean is_unlocked True if the NPC is available to interact with.
function lore_catalog.is_npc_unlocked(npc_id, completed_tasks)
    local npc = lore_catalog.NPCS[npc_id]
    if not npc then return false end
    if not npc.unlock_task then return true end

    if not completed_tasks then return false end
    for _, t in ipairs(completed_tasks) do
        if t.task_id == npc.unlock_task then
            return true
        end
    end
    return false
end

--- Returns random idle chatter for an NPC when tapped in the village.
-- @param npc_id string Unique NPC identifier.
-- @param rng_index number|nil Optional integer index to select deterministic line.
-- @return string text Spoken dialogue string.
function lore_catalog.get_idle_chatter(npc_id, rng_index)
    local npc = lore_catalog.NPCS[npc_id]
    if not npc then return "..." end

    local chatter_pool = {
        bramble = {
            "Patience, Keeper. Even the largest oak grew from a single acorn.",
            "The lanterns do more than illuminate—they keep the woodland safe.",
            "Listen closely... you can hear the whispering willows across the brook."
        },
        pip = {
            "Flap-flap! I spotted a golden firefly near the teahouse!",
            "My satchel is ready for more Sparks whenever you want to play a level!",
            "Hoo-hoo! Isn't this the coziest courtyard in the whole forest?"
        },
        maeve = {
            "Breathe in the morning mist. Nature always heals in time.",
            "Wisteria tea is brewing. Take a restful moment between puzzles."
        },
        rowan = {
            "Measure twice, cut once, and always oil your timber.",
            "That wishing well has river stone foundations older than all of us."
        }
    }

    local lines = chatter_pool[npc_id] or { npc.default_dialogue }
    local idx = rng_index and (((rng_index - 1) % #lines) + 1) or 1
    return lines[idx] or npc.default_dialogue
end

return lore_catalog
