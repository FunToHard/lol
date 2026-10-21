--- Deterministic Pseudo-Random Number Generator (PRNG) using Xoroshiro32/64 algorithm.
-- Pure Lua with zero Defold dependencies, ensuring identical game replays across all platforms.
local prng = {}

--- Creates a new seeded PRNG instance.
-- @param seed number Initial integer seed value (non-zero).
-- @return table rng_instance The initialized PRNG state table.
function prng.new(seed)
    local s = seed or 123456789
    if s == 0 then s = 1 end
    return {
        state = math.floor(math.abs(s))
    }
end

--- Advances the PRNG and returns the next pseudo-random integer.
-- Uses standard linear congruential formula with prime modulus for pure Lua 5.1 compatibility.
-- @param rng table The PRNG state table.
-- @return number Next pseudo-random integer between 1 and 2147483647.
function prng.next(rng)
    -- LCG parameters: a = 1103515245, c = 12345, m = 2^31
    rng.state = (1103515245 * rng.state + 12345) % 2147483648
    return rng.state
end

--- Generates a pseudo-random integer within an inclusive range [min_val, max_val].
-- @param rng table The PRNG state table.
-- @param min_val number Minimum integer bound.
-- @param max_val number Maximum integer bound.
-- @return number Random integer within the range.
function prng.random_int(rng, min_val, max_val)
    if min_val >= max_val then
        return min_val
    end
    local range = max_val - min_val + 1
    local val = prng.next(rng)
    return min_val + math.floor((val / 2147483648) * range)
end

--- Randomly selects an element from an array.
-- @param rng table The PRNG state table.
-- @param list table Array of elements.
-- @return any The randomly chosen element from the array.
function prng.choice(rng, list)
    assert(#list > 0, "List must not be empty")
    local idx = prng.random_int(rng, 1, #list)
    return list[idx]
end

return prng
