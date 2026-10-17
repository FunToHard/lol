--- Abstract service contract for In-App Purchases and digital entitlements.
-- Decouples store transactions and SKU catalogs from platform-specific billing SDKs.
-- @module iap_service

local iap_service = {}

--- Creates a new IAP service instance wrapping an underlying billing adapter.
-- @param adapter table The concrete billing adapter (e.g. mock_iap_adapter or extension-iap).
-- @return table service Configured IAP service instance.
function iap_service.new(adapter)
    assert(type(adapter) == "table", "iap_service requires an adapter implementation table")
    local instance = {
        adapter = adapter
    }
    setmetatable(instance, { __index = iap_service })
    return instance
end

--- Retrieves the registered SKU product catalog.
-- @param self table IAP service instance.
-- @return table catalog List of product descriptors { id, type, price_usd, title, contents }.
function iap_service.get_catalog(self)
    if self.adapter and self.adapter.get_catalog then
        return self.adapter.get_catalog(self.adapter)
    end
    return {}
end

--- Initiates a purchase flow for a specified product identifier.
-- @param self table IAP service instance.
-- @param product_id string Registered product identifier (e.g. "pack_starter").
-- @param on_success function Callback invoked upon verified transaction: `on_success(product, receipt)`.
-- @param on_failed function|nil Optional failure callback: `on_failed(err_msg)`.
function iap_service.purchase(self, product_id, on_success, on_failed)
    if not self.adapter or not self.adapter.purchase then
        if on_failed then on_failed("ADAPTER_NOT_CONFIGURED") end
        return
    end
    self.adapter.purchase(self.adapter, product_id, on_success, on_failed)
end

--- Restores non-consumable entitlements (e.g. "no_ads") across device reinstalls.
-- @param self table IAP service instance.
-- @param on_restored function Callback receiving list of restored product IDs: `on_restored(restored_ids)`.
function iap_service.restore_purchases(self, on_restored)
    if self.adapter and self.adapter.restore_purchases then
        self.adapter.restore_purchases(self.adapter, on_restored)
    elseif on_restored then
        on_restored({})
    end
end

return iap_service
