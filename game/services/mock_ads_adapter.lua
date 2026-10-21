--- Development and headless testing mock adapter for ads presentation.
-- Simulates rewarded ad overlays, completion rewards, and interstitial cooldowns without network dependencies.
-- @module mock_ads_adapter

local mock_ads_adapter = {}

--- Creates a new mock ads adapter instance.
-- @param auto_succeed boolean|nil Whether simulated ads automatically grant rewards (defaults to true).
-- @return table adapter Initialized mock adapter table.
function mock_ads_adapter.new(auto_succeed)
    local instance = {
        auto_succeed = (auto_succeed ~= false),
        rewarded_ready = true,
        rewarded_shown_count = 0,
        interstitial_shown_count = 0,
        last_placement = nil
    }
    setmetatable(instance, { __index = mock_ads_adapter })
    return instance
end

--- Checks if a simulated rewarded ad is ready.
-- @param self table Mock adapter instance.
-- @return boolean is_ready Readiness flag.
function mock_ads_adapter.is_rewarded_ready(self)
    return self.rewarded_ready
end

--- Simulates displaying a rewarded video ad.
-- Immediately invokes on_reward if auto_succeed is true, or on_failed if false.
-- @param self table Mock adapter instance.
-- @param on_reward function Reward callback.
-- @param on_closed function|nil Dismissal callback.
-- @param on_failed function|nil Failure callback.
function mock_ads_adapter.show_rewarded(self, on_reward, on_closed, on_failed)
    self.rewarded_shown_count = self.rewarded_shown_count + 1

    if self.auto_succeed then
        if on_reward then on_reward() end
        if on_closed then on_closed() end
    else
        if on_failed then on_failed("SIMULATED_REWARDED_AD_ERROR") end
    end
end

--- Simulates presenting an interstitial ad between levels.
-- @param self table Mock adapter instance.
-- @param placement string Analytical placement string.
-- @param on_closed function|nil Completion callback.
function mock_ads_adapter.show_interstitial(self, placement, on_closed)
    self.interstitial_shown_count = self.interstitial_shown_count + 1
    self.last_placement = placement
    if on_closed then on_closed() end
end

return mock_ads_adapter
