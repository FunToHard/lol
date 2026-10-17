--- Development and headless testing mock adapter for In-App Purchases.
-- Provides the verified store SKU catalog and simulates purchase confirmations offline.
-- @module mock_iap_adapter

local mock_iap_adapter = {}

local CATALOG = {
    {
        id = "pack_starter",
        type = "non_consumable",
        price_usd = 1.99,
        title = "Woodland Starter Bundle",
        contents = { coins = 1000, hammer = 2, rocket = 2, no_ads = true }
    },
    {
        id = "coins_small",
        type = "consumable",
        price_usd = 0.99,
        title = "Pouch of Coins",
        contents = { coins = 500 }
    },
    {
        id = "coins_medium",
        type = "consumable",
        price_usd = 2.99,
        title = "Chest of Coins & Boosters",
        contents = { coins = 1800, hammer = 1, rocket = 1, bomb = 1 }
    },
    {
        id = "coins_large",
        type = "consumable",
        price_usd = 7.99,
        title = "Treasure Trove",
        contents = { coins = 5500, hammer = 3, rocket = 3, bomb = 3 }
    },
    {
        id = "no_ads",
        type = "non_consumable",
        price_usd = 2.99,
        title = "Ad-Free Woodland Pass",
        contents = { no_ads = true }
    }
}

--- Creates a new mock IAP adapter instance.
-- @param auto_succeed boolean|nil Whether simulated purchases automatically succeed (defaults to true).
-- @return table adapter Initialized mock IAP adapter table.
function mock_iap_adapter.new(auto_succeed)
    local instance = {
        auto_succeed = (auto_succeed ~= false),
        purchased_history = {},
        restored_entitlements = {}
    }
    setmetatable(instance, { __index = mock_iap_adapter })
    return instance
end

--- Returns the registered store SKU product catalog.
-- @param self table Mock IAP adapter instance.
-- @return table catalog Array of product definition tables.
function mock_iap_adapter.get_catalog(self)
    return CATALOG
end

--- Retrieves a single product descriptor by ID.
-- @param self table Mock IAP adapter instance.
-- @param product_id string Registered product ID.
-- @return table|nil product Product definition or nil.
function mock_iap_adapter.get_product(self, product_id)
    for _, p in ipairs(CATALOG) do
        if p.id == product_id then
            return p
        end
    end
    return nil
end

--- Simulates purchasing a product from the store.
-- @param self table Mock IAP adapter instance.
-- @param product_id string Target product ID to purchase.
-- @param on_success function Success callback: `on_success(product, receipt)`.
-- @param on_failed function|nil Failure callback: `on_failed(err_msg)`.
function mock_iap_adapter.purchase(self, product_id, on_success, on_failed)
    local prod = mock_iap_adapter.get_product(self, product_id)
    if not prod then
        if on_failed then on_failed("PRODUCT_NOT_FOUND") end
        return
    end

    if not self.auto_succeed then
        if on_failed then on_failed("USER_CANCELLED_OR_PAYMENT_DECLINED") end
        return
    end

    local receipt = {
        order_id = "mock_order_" .. tostring(os.time()) .. "_" .. tostring(#self.purchased_history + 1),
        product_id = product_id,
        purchase_time = os.time and os.time() or 0,
        token = "mock_token_" .. product_id
    }

    self.purchased_history[#self.purchased_history + 1] = receipt
    if prod.type == "non_consumable" then
        self.restored_entitlements[product_id] = true
    end

    if on_success then
        on_success(prod, receipt)
    end
end

--- Restores previously purchased non-consumable entitlements.
-- @param self table Mock IAP adapter instance.
-- @param on_restored function Callback receiving array of product IDs: `on_restored(restored_ids)`.
function mock_iap_adapter.restore_purchases(self, on_restored)
    local restored = {}
    for pid in pairs(self.restored_entitlements) do
        restored[#restored + 1] = pid
    end
    if on_restored then
        on_restored(restored)
    end
end

return mock_iap_adapter
