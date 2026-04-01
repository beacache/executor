local _sv = Instance.new("StringValue")

local function isparallel()
    local ok = pcall(function()
        local v = _sv.Value
        _sv.Value = v
    end)
    return not ok
end

local env = getgenv(function() end)

env.isparallel          = isparallel
env.checkparallel       = isparallel
env.inparallel          = isparallel
