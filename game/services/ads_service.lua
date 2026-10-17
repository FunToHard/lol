--- Abstract service contract for ad presentation and rewarded video continuations.
-- Decouples gameplay simulation and UI flows from specific ad network implementations.
-- @module ads_service

local ads_service = {}

--- Creates a new ads service wrapper wrapping an underlying adapter.
-- @param adapter table The concrete ad adapter (e.g. mock_ads_adapter or native admob adapter).
-- @return table service Configured ads service instance.
function ads_service.new(adapter)
    assert(type(adapter) == "table", "ads_service requires an adapter implementation table")
    local instance = {
        adapter = adapter
    }
    setmetatable(instance, { __index = ads_service })
    return instance
end

--- Checks if a rewarded video ad is loaded and ready for presentation.
-- @param self table Ads service instance.
-- @return boolean is_ready True if a rewarded ad is available.
function ads_service.is_rewarded_ready(self)
    if self.adapter and self.adapter.is_rewarded_ready then
        return self.adapter.is_rewarded_ready(self.adapter)
    end
    return false
end

--- Presents a rewarded video ad with asynchronous outcome callbacks.
-- Enforces fail-open policy: triggers on_failed if ad cannot be shown without crashing.
-- @param self table Ads service instance.
-- @param on_reward function Callback invoked when player successfully watches the ad: `on_reward()`.
-- @param on_closed function|nil Optional callback invoked when ad view is dismissed: `on_closed()`.
-- @param on_failed function|nil Optional callback invoked if ad presentation fails: `on_failed(err_msg)`.
function ads_service.show_rewarded(self, on_reward, on_closed, on_failed)
    if not self.adapter or not self.adapter.show_rewarded then
        if on_failed then on_failed("ADAPTER_NOT_CONFIGURED") end
        return
    end
    self.adapter.show_rewarded(self.adapter, on_reward, on_closed, on_failed)
end

--- Presents an interstitial ad between level transitions according to cooldown policy.
-- @param self table Ads service instance.
-- @param placement string Analytical placement tag (e.g. "level_end").
-- @param on_closed function|nil Optional completion callback.
function ads_service.show_interstitial(self, placement, on_closed)
    if self.adapter and self.adapter.show_interstitial then
        self.adapter.show_interstitial(self.adapter, placement, on_closed)
    elseif on_closed then
        on_closed()
    end
end

return ads_service
