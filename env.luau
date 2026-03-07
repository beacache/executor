local loadfile = function(path, chunkname)
    local success, content = pcall(readfile, path)
    if not success or not content then
        return nil, "cannot open " .. tostring(path) .. ": No such file or directory"
    end
    
    local chunk_name = chunkname or ("@" .. path)
    return loadstring(content, chunk_name)
end

local dofile = function(path)
    local func, err = loadfile(path)
    if not func then
        error(err, 2)
    end
    return func()
end

getgenv().loadfile = loadfile
getgenv().load_file = loadfile
getgenv().loadfromfile = loadfile
getgenv().load_from_file = loadfile

getgenv().dofile = dofile
getgenv().do_file = dofile

if not getgenv().file then
    getgenv().file = {}
end

getgenv().file.load = loadfile
getgenv().file.loadfile = loadfile
getgenv().file.load_file = loadfile
getgenv().file["do"] = dofile
getgenv().file.dofile = dofile
getgenv().file.do_file = dofile

if not getgenv().folder then
    getgenv().folder = {}
end

pcall(function()
    local common = game:GetService("CoreGui").RobloxGui.Modules.Common
    local commonutil = common.CommonUtil
    if commonutil and not common:FindFirstChild("Constants") then
        local constants = commonutil:Clone()
        constants.Name = "Constants"
        constants.Parent = common
    end
end)

local http = {}
http.request = request or http_request or syn_request
getgenv().http = http
getgenv().syn = getgenv().syn or {}
getgenv().syn.request = http.request

local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    self._waiting = {}
    return self
end

function Signal:Connect(callback)
    local connection = {
        Connected = true,
        Callback = callback,
    }
    function connection:Disconnect()
        self.Connected = false
    end
    table.insert(self._connections, connection)
    return connection
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection.Callback, ...)
        end
    end
    for _, thread in ipairs(self._waiting) do
        task.spawn(thread, ...)
    end
    table.clear(self._waiting)
end

function Signal:Wait()
    local thread = coroutine.running()
    table.insert(self._waiting, thread)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    for _, connection in ipairs(self._connections) do
        connection.Connected = false
    end
    table.clear(self._connections)
    table.clear(self._waiting)
end

getgenv().Signal = Signal

local bit32 = bit32 or {}

local MODULUS = 2^32

local function normalize(n)
    n = n % MODULUS
    if n < 0 then n = n + MODULUS end
    return math.floor(n)
end

if not bit32.band then
    bit32.band = function(...)
        local args = {...}
        if #args == 0 then return 0xFFFFFFFF end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            local bitval = 1
            for _ = 0, 31 do
                if result % 2 == 1 and b % 2 == 1 then
                    r = r + bitval
                end
                bitval = bitval * 2
                result = math.floor(result / 2)
                b = math.floor(b / 2)
            end
            result = r
        end
        return result
    end
end

if not bit32.bor then
    bit32.bor = function(...)
        local args = {...}
        if #args == 0 then return 0 end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            local bitval = 1
            for _ = 0, 31 do
                if result % 2 == 1 or b % 2 == 1 then
                    r = r + bitval
                end
                bitval = bitval * 2
                result = math.floor(result / 2)
                b = math.floor(b / 2)
            end
            result = r
        end
        return result
    end
end

if not bit32.bxor then
    bit32.bxor = function(...)
        local args = {...}
        if #args == 0 then return 0 end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            local bitval = 1
            for _ = 0, 31 do
                if (result % 2) ~= (b % 2) then
                    r = r + bitval
                end
                bitval = bitval * 2
                result = math.floor(result / 2)
                b = math.floor(b / 2)
            end
            result = r
        end
        return result
    end
end

if not bit32.bnot then
    bit32.bnot = function(n)
        n = normalize(n)
        return (MODULUS - 1) - n
    end
end

if not bit32.lshift then
    bit32.lshift = function(n, disp)
        n = normalize(n)
        disp = disp % 32
        if disp < 0 then
            return bit32.rshift(n, -disp)
        end
        return normalize(n * (2 ^ disp))
    end
end

if not bit32.rshift then
    bit32.rshift = function(n, disp)
        n = normalize(n)
        disp = disp % 32
        if disp < 0 then
            return bit32.lshift(n, -disp)
        end
        return math.floor(n / (2 ^ disp))
    end
end

if not bit32.arshift then
    bit32.arshift = function(n, disp)
        n = normalize(n)
        disp = disp % 32
        if disp == 0 then return n end
        local sign = (n >= 2^31) and 1 or 0
        local result = math.floor(n / (2 ^ disp))
        if sign == 1 then
            local mask = (2^disp - 1) * 2^(32 - disp)
            result = bit32.bor(result, mask)
        end
        return result
    end
end

if not bit32.lrotate then
    bit32.lrotate = function(n, disp)
        n = normalize(n)
        disp = disp % 32
        if disp == 0 then return n end
        return bit32.bor(bit32.lshift(n, disp), bit32.rshift(n, 32 - disp))
    end
end

if not bit32.rrotate then
    bit32.rrotate = function(n, disp)
        n = normalize(n)
        disp = disp % 32
        if disp == 0 then return n end
        return bit32.bor(bit32.rshift(n, disp), bit32.lshift(n, 32 - disp))
    end
end

if not bit32.extract then
    bit32.extract = function(n, field, width)
        width = width or 1
        assert(field >= 0 and field < 32, "field out of range")
        assert(width > 0 and field + width <= 32, "width out of range")
        n = normalize(n)
        return bit32.band(bit32.rshift(n, field), (2 ^ width) - 1)
    end
end

if not bit32.replace then
    bit32.replace = function(n, v, field, width)
        width = width or 1
        assert(field >= 0 and field < 32, "field out of range")
        assert(width > 0 and field + width <= 32, "width out of range")
        n = normalize(n)
        v = normalize(v)
        local mask = (2 ^ width) - 1
        local clearedN = bit32.band(n, bit32.bnot(bit32.lshift(mask, field)))
        return bit32.bor(clearedN, bit32.lshift(bit32.band(v, mask), field))
    end
end

if not bit32.btest then
    bit32.btest = function(...)
        return bit32.band(...) ~= 0
    end
end

if not bit32.countlz then
    bit32.countlz = function(n)
        n = normalize(n)
        if n == 0 then return 32 end
        local count = 0
        for i = 31, 0, -1 do
            if n >= 2^i then
                return count
            end
            count = count + 1
        end
        return 32
    end
end

if not bit32.countrz then
    bit32.countrz = function(n)
        n = normalize(n)
        if n == 0 then return 32 end
        local count = 0
        while n % 2 == 0 do
            count = count + 1
            n = math.floor(n / 2)
        end
        return count
    end
end

if not bit32.byteswap then
    bit32.byteswap = function(n)
        n = normalize(n)
        local b0 = bit32.band(n, 0xFF)
        local b1 = bit32.band(bit32.rshift(n, 8), 0xFF)
        local b2 = bit32.band(bit32.rshift(n, 16), 0xFF)
        local b3 = bit32.band(bit32.rshift(n, 24), 0xFF)
        return bit32.bor(
            bit32.lshift(b0, 24),
            bit32.lshift(b1, 16),
            bit32.lshift(b2, 8),
            b3
        )
    end
end

getgenv().bit32 = bit32
getgenv().bit = bit32

local utf8 = utf8 or {}

local utf8_readonly = not pcall(function()
    utf8.charpattern = "test"
end)

if utf8_readonly then
    local utf8_new = {}
    
    for k, v in pairs(utf8) do
        utf8_new[k] = v
    end
    
    utf8_new.charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"
    
    utf8 = utf8_new
else
    if not utf8.charpattern then
        utf8.charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"
    end
end

if not utf8.char then
    utf8.char = function(...)
        local result = {}
        for i, codepoint in ipairs({...}) do
            assert(type(codepoint) == "number", "bad argument #" .. i .. " (number expected)")
            assert(codepoint >= 0 and codepoint <= 0x10FFFF, "invalid codepoint")
            
            if codepoint < 0x80 then
                table.insert(result, string.char(codepoint))
            elseif codepoint < 0x800 then
                table.insert(result, string.char(
                    0xC0 + math.floor(codepoint / 64),
                    0x80 + (codepoint % 64)
                ))
            elseif codepoint < 0x10000 then
                table.insert(result, string.char(
                    0xE0 + math.floor(codepoint / 4096),
                    0x80 + math.floor((codepoint % 4096) / 64),
                    0x80 + (codepoint % 64)
                ))
            else
                table.insert(result, string.char(
                    0xF0 + math.floor(codepoint / 262144),
                    0x80 + math.floor((codepoint % 262144) / 4096),
                    0x80 + math.floor((codepoint % 4096) / 64),
                    0x80 + (codepoint % 64)
                ))
            end
        end
        return table.concat(result)
    end
end

if not utf8.codepoint then
    utf8.codepoint = function(s, i, j)
        i = i or 1
        j = j or i
        
        if i < 0 then i = #s + i + 1 end
        if j < 0 then j = #s + j + 1 end
        
        local result = {}
        local pos = 1
        local index = 0
        
        while pos <= #s do
            index = index + 1
            local byte = string.byte(s, pos)
            local codepoint, size
            
            if byte < 0x80 then
                codepoint = byte
                size = 1
            elseif byte < 0xE0 then
                codepoint = bit32.band(byte, 0x1F) * 64 + bit32.band(string.byte(s, pos + 1) or 0, 0x3F)
                size = 2
            elseif byte < 0xF0 then
                codepoint = bit32.band(byte, 0x0F) * 4096 + 
                           bit32.band(string.byte(s, pos + 1) or 0, 0x3F) * 64 +
                           bit32.band(string.byte(s, pos + 2) or 0, 0x3F)
                size = 3
            else
                codepoint = bit32.band(byte, 0x07) * 262144 +
                           bit32.band(string.byte(s, pos + 1) or 0, 0x3F) * 4096 +
                           bit32.band(string.byte(s, pos + 2) or 0, 0x3F) * 64 +
                           bit32.band(string.byte(s, pos + 3) or 0, 0x3F)
                size = 4
            end
            
            if index >= i and index <= j then
                table.insert(result, codepoint)
            end
            
            if index > j then break end
            pos = pos + size
        end
        
        return unpack(result)
    end
end

if not utf8.codes then
    utf8.codes = function(s)
        return function(str, pos)
            if pos >= #str then return nil end
            
            local byte = string.byte(str, pos + 1)
            if not byte then return nil end
            
            local codepoint, size
            if byte < 0x80 then
                codepoint = byte
                size = 1
            elseif byte < 0xE0 then
                codepoint = bit32.band(byte, 0x1F) * 64 + bit32.band(string.byte(str, pos + 2) or 0, 0x3F)
                size = 2
            elseif byte < 0xF0 then
                codepoint = bit32.band(byte, 0x0F) * 4096 + 
                           bit32.band(string.byte(str, pos + 2) or 0, 0x3F) * 64 +
                           bit32.band(string.byte(str, pos + 3) or 0, 0x3F)
                size = 3
            else
                codepoint = bit32.band(byte, 0x07) * 262144 +
                           bit32.band(string.byte(str, pos + 2) or 0, 0x3F) * 4096 +
                           bit32.band(string.byte(str, pos + 3) or 0, 0x3F) * 64 +
                           bit32.band(string.byte(str, pos + 4) or 0, 0x3F)
                size = 4
            end
            
            return pos + size, codepoint
        end, s, 0
    end
end

if not utf8.len then
    utf8.len = function(s, i, j)
        i = i or 1
        j = j or #s
        
        if i < 0 then i = #s + i + 1 end
        if j < 0 then j = #s + j + 1 end
        
        local count = 0
        local pos = i
        
        while pos <= j do
            local byte = string.byte(s, pos)
            if not byte then break end
            
            if byte < 0x80 then
                pos = pos + 1
            elseif byte < 0xE0 then
                pos = pos + 2
            elseif byte < 0xF0 then
                pos = pos + 3
            elseif byte < 0xF8 then
                pos = pos + 4
            else
                return nil, pos
            end
            count = count + 1
        end
        
        return count
    end
end

if not utf8.offset then
    utf8.offset = function(s, n, i)
        i = i or (n >= 0 and 1 or #s + 1)
        
        if n == 0 then
            while i > 1 do
                local byte = string.byte(s, i)
                if byte and (byte < 0x80 or byte >= 0xC0) then
                    return i
                end
                i = i - 1
            end
            return 1
        elseif n > 0 then
            local count = 0
            local pos = i
            while pos <= #s and count < n do
                local byte = string.byte(s, pos)
                if byte < 0x80 then
                    pos = pos + 1
                elseif byte < 0xE0 then
                    pos = pos + 2
                elseif byte < 0xF0 then
                    pos = pos + 3
                else
                    pos = pos + 4
                end
                count = count + 1
            end
            if count == n then
                return pos
            end
            return nil
        else
            local pos = i
            local count = 0
            while pos > 0 and count > n do
                pos = pos - 1
                local byte = string.byte(s, pos)
                if byte and (byte < 0x80 or byte >= 0xC0) then
                    count = count - 1
                end
            end
            if count == n then
                return pos
            end
            return nil
        end
    end
end

if not utf8.graphemes then
    utf8.graphemes = function(s, i, j)
        i = i or 1
        j = j or #s
        
        return function(str, pos)
            if pos >= j then return nil end
            
            local startPos = pos + 1
            local byte = string.byte(str, startPos)
            if not byte then return nil end
            
            local size
            if byte < 0x80 then
                size = 1
            elseif byte < 0xE0 then
                size = 2
            elseif byte < 0xF0 then
                size = 3
            else
                size = 4
            end
            
            local endPos = startPos + size - 1
            return endPos, string.sub(str, startPos, endPos)
        end, s, i - 1
    end
end

if not utf8.nfcnormalize then
    utf8.nfcnormalize = function(s)
        return s
    end
end

if not utf8.nfdnormalize then
    utf8.nfdnormalize = function(s)
        return s
    end
end

getgenv().utf8 = utf8

if not table.clear then
    table.clear = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

if not table.clone then
    table.clone = function(t)
        local new = {}
        for k, v in pairs(t) do
            new[k] = v
        end
        return setmetatable(new, getmetatable(t))
    end
end

if not table.create then
    table.create = function(count, value)
        local t = {}
        for i = 1, count do
            t[i] = value
        end
        return t
    end
end

if not table.find then
    table.find = function(t, value, init)
        init = init or 1
        for i = init, #t do
            if t[i] == value then
                return i
            end
        end
        return nil
    end
end

if not table.freeze then
    table.freeze = function(t)
        return setmetatable({}, {
            __index = t,
            __newindex = function()
                error("Attempt to modify a frozen table", 2)
            end,
            __metatable = "frozen"
        })
    end
end

if not table.isfrozen then
    table.isfrozen = function(t)
        return getmetatable(t) == "frozen"
    end
end

if not table.move then
    table.move = function(a1, f, e, t, a2)
        a2 = a2 or a1
        if t > f then
            for i = e - f, 0, -1 do
                a2[t + i] = a1[f + i]
            end
        else
            for i = 0, e - f do
                a2[t + i] = a1[f + i]
            end
        end
        return a2
    end
end

if not table.pack then
    table.pack = function(...)
        return {n = select("#", ...), ...}
    end
end

if not table.unpack then
    table.unpack = unpack
end

if not table.maxn then
    table.maxn = function(t)
        local max = 0
        for k in pairs(t) do
            if type(k) == "number" and k > max then
                max = k
            end
        end
        return max
    end
end

-- String library extensions with readonly check
do
    local string_writable = pcall(function()
        local test_key = "__leafy_test_" .. tostring(math.random())
        rawset(string, test_key, true)
        rawset(string, test_key, nil)
    end)
    
    local string_extensions = {}
    local string_extended = false
    
    local function ensureStringExtended()
        if string_extended then return end
        if not string_writable then
            local new_string = {}
            for k, v in pairs(string) do
                new_string[k] = v
            end
            for k, v in pairs(string_extensions) do
                new_string[k] = v
            end
            getgenv().string = setmetatable(new_string, {
                __index = string,
                __newindex = function(t, k, v)
                    rawset(new_string, k, v)
                end
            })
            string_extended = true
        end
    end
    
    local function addStringFunc(name, func)
        if string[name] then return end
        string_extensions[name] = func
        if string_writable then
            pcall(function()
                rawset(string, name, func)
            end)
        else
            ensureStringExtended()
            if getgenv().string and getgenv().string ~= string then
                getgenv().string[name] = func
            end
        end
    end
    
    addStringFunc("split", function(s, separator)
        separator = separator or ","
        local result = {}
        if separator == "" then
            for i = 1, #s do
                result[i] = string.sub(s, i, i)
            end
        else
            local pattern = "(.-)" .. separator:gsub("([^%w])", "%%%1")
            for part in (s .. separator):gmatch(pattern) do
                table.insert(result, part)
            end
        end
        return result
    end)
    
    addStringFunc("trim", function(s)
        return s:match("^%s*(.-)%s*$")
    end)
end

-- Math library extensions with readonly check
do
    local math_writable = pcall(function()
        local test_key = "__leafy_test_" .. tostring(math.random())
        rawset(math, test_key, true)
        rawset(math, test_key, nil)
    end)
    
    local math_extensions = {}
    local math_extended = false
    
    local function ensureMathExtended()
        if math_extended then return end
        if not math_writable then
            local new_math = {}
            for k, v in pairs(math) do
                new_math[k] = v
            end
            for k, v in pairs(math_extensions) do
                new_math[k] = v
            end
            getgenv().math = setmetatable(new_math, {
                __index = math,
                __newindex = function(t, k, v)
                    rawset(new_math, k, v)
                end
            })
            math_extended = true
        end
    end
    
    local function addMathFunc(name, func)
        if math[name] then return end
        math_extensions[name] = func
        if math_writable then
            pcall(function()
                rawset(math, name, func)
            end)
        else
            ensureMathExtended()
            if getgenv().math and getgenv().math ~= math then
                getgenv().math[name] = func
            end
        end
    end
    
    addMathFunc("sign", function(n)
        if n > 0 then return 1
        elseif n < 0 then return -1
        else return 0 end
    end)
    
    addMathFunc("clamp", function(n, min, max)
        if n < min then return min end
        if n > max then return max end
        return n
    end)
    
    addMathFunc("round", function(n)
        return math.floor(n + 0.5)
    end)
    
    addMathFunc("lerp", function(a, b, t)
        return a + (b - a) * t
    end)
    
    addMathFunc("map", function(n, inMin, inMax, outMin, outMax)
        return (n - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    end)
    
    -- Noise function with permutation table
    do
        local permutation = {}
        for i = 0, 255 do permutation[i] = i end
        for i = 255, 1, -1 do
            local j = math.random(0, i)
            permutation[i], permutation[j] = permutation[j], permutation[i]
        end
        for i = 0, 255 do permutation[256 + i] = permutation[i] end

        local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
        local function lerp(t, a, b) return a + t * (b - a) end
        local function grad(hash, x, y, z)
            local h = hash % 16
            local u = h < 8 and x or y
            local v = h < 4 and y or (h == 12 or h == 14) and x or z
            return ((h % 2 == 0) and u or -u) + ((h % 4 < 2) and v or -v)
        end

        addMathFunc("noise", function(x, y, z)
            y = y or 0
            z = z or 0
            local X = math.floor(x) % 256
            local Y = math.floor(y) % 256
            local Z = math.floor(z) % 256
            x = x - math.floor(x)
            y = y - math.floor(y)
            z = z - math.floor(z)
            local u, v, w = fade(x), fade(y), fade(z)
            local A  = permutation[X] + Y
            local AA = permutation[A] + Z
            local AB = permutation[A + 1] + Z
            local B  = permutation[X + 1] + Y
            local BA = permutation[B] + Z
            local BB = permutation[B + 1] + Z
            return lerp(w,
                lerp(v, lerp(u, grad(permutation[AA],     x,     y,     z),
                                grad(permutation[BA],     x - 1, y,     z)),
                        lerp(u, grad(permutation[AB],     x,     y - 1, z),
                                grad(permutation[BB],     x - 1, y - 1, z))),
                lerp(v, lerp(u, grad(permutation[AA + 1], x,     y,     z - 1),
                                grad(permutation[BA + 1], x - 1, y,     z - 1)),
                        lerp(u, grad(permutation[AB + 1], x,     y - 1, z - 1),
                                grad(permutation[BB + 1], x - 1, y - 1, z - 1))))
        end)
    end
end

-- Coroutine library extensions with readonly check
do
    local coroutine_writable = pcall(function()
        local test_key = "__leafy_test_" .. tostring(math.random())
        rawset(coroutine, test_key, true)
        rawset(coroutine, test_key, nil)
    end)
    
    local coroutine_extensions = {}
    local coroutine_extended = false
    
    local function ensureCoroutineExtended()
        if coroutine_extended then return end
        if not coroutine_writable then
            local new_coroutine = {}
            for k, v in pairs(coroutine) do
                new_coroutine[k] = v
            end
            for k, v in pairs(coroutine_extensions) do
                new_coroutine[k] = v
            end
            getgenv().coroutine = setmetatable(new_coroutine, {
                __index = coroutine,
                __newindex = function(t, k, v)
                    rawset(new_coroutine, k, v)
                end
            })
            coroutine_extended = true
        end
    end
    
    local function addCoroutineFunc(name, func)
        if coroutine[name] then return end
        coroutine_extensions[name] = func
        if coroutine_writable then
            pcall(function()
                rawset(coroutine, name, func)
            end)
        else
            ensureCoroutineExtended()
            if getgenv().coroutine and getgenv().coroutine ~= coroutine then
                getgenv().coroutine[name] = func
            end
        end
    end
    
    addCoroutineFunc("isyieldable", function(co)
        co = co or coroutine.running()
        if not co then return true end
        return coroutine.status(co) ~= "dead"
    end)
    
    addCoroutineFunc("close", function(co)
        return true
    end)
end

-- OS library
if not getgenv().os then
    getgenv().os = {}
end

local os_lib = getgenv().os or os or {}

if not os_lib.clock then
    local start = tick()
    os_lib.clock = function()
        return tick() - start
    end
end

if not os_lib.difftime then
    os_lib.difftime = function(t2, t1)
        return t2 - t1
    end
end

if not os_lib.time then
    os_lib.time = function(t)
        if t then
            local success, result = pcall(function()
                return DateTime.fromUniversalTime(
                    t.year or 1970, t.month or 1, t.day or 1,
                    t.hour or 0, t.min or 0, t.sec or 0
                ).UnixTimestamp
            end)
            if success then return result end
            return 0
        end
        local success, result = pcall(function()
            return DateTime.now().UnixTimestamp
        end)
        if success then return result end
        return tick()
    end
end

if not os_lib.date then
    os_lib.date = function(format, time)
        time = time or os_lib.time()
        format = format or "%c"
        
        local success, result = pcall(function()
            local dt = DateTime.fromUnixTimestamp(time)
            local utc = format:sub(1, 1) == "!"
            if utc then format = format:sub(2) end
            
            local t = utc and dt:ToUniversalTime() or dt:ToLocalTime()
            
            if format == "*t" then
                return {
                    year = t.Year,
                    month = t.Month,
                    day = t.Day,
                    hour = t.Hour,
                    min = t.Minute,
                    sec = t.Second,
                    wday = (t.Day % 7) + 1,
                    yday = t.Day,
                    isdst = false
                }
            end
            
            return dt:FormatUniversalTime(format:gsub("%%", ""), "en-us")
        end)
        
        if success then return result end
        return tostring(time)
    end
end

getgenv().os = os_lib

-- Buffer library
if not buffer then
    local bufferLib = {}
    
    function bufferLib.create(size)
        local buf = {
            _data = table.create(size, 0),
            _size = size
        }
        return setmetatable(buf, {__index = bufferLib})
    end
    
    function bufferLib.fromstring(str)
        local buf = bufferLib.create(#str)
        for i = 1, #str do
            buf._data[i] = string.byte(str, i)
        end
        return buf
    end
    
    function bufferLib.tostring(buf)
        local chars = {}
        for i = 1, buf._size do
            chars[i] = string.char(buf._data[i] or 0)
        end
        return table.concat(chars)
    end
    
    function bufferLib.len(buf)
        return buf._size
    end
    
    function bufferLib.readi8(buf, offset)
        local v = buf._data[offset + 1] or 0
        return v >= 128 and v - 256 or v
    end
    
    function bufferLib.readu8(buf, offset)
        return buf._data[offset + 1] or 0
    end
    
    function bufferLib.writei8(buf, offset, value)
        buf._data[offset + 1] = value % 256
    end
    
    function bufferLib.writeu8(buf, offset, value)
        buf._data[offset + 1] = value % 256
    end
    
    function bufferLib.readi16(buf, offset)
        local b1 = buf._data[offset + 1] or 0
        local b2 = buf._data[offset + 2] or 0
        local v = b1 + b2 * 256
        return v >= 32768 and v - 65536 or v
    end
    
    function bufferLib.readu16(buf, offset)
        local b1 = buf._data[offset + 1] or 0
        local b2 = buf._data[offset + 2] or 0
        return b1 + b2 * 256
    end
    
    function bufferLib.writei16(buf, offset, value)
        value = value % 65536
        buf._data[offset + 1] = value % 256
        buf._data[offset + 2] = math.floor(value / 256)
    end
    
    function bufferLib.writeu16(buf, offset, value)
        buf._data[offset + 1] = value % 256
        buf._data[offset + 2] = math.floor(value / 256) % 256
    end
    
    function bufferLib.readi32(buf, offset)
        local b1 = buf._data[offset + 1] or 0
        local b2 = buf._data[offset + 2] or 0
        local b3 = buf._data[offset + 3] or 0
        local b4 = buf._data[offset + 4] or 0
        local v = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
        return v >= 2147483648 and v - 4294967296 or v
    end
    
    function bufferLib.readu32(buf, offset)
        local b1 = buf._data[offset + 1] or 0
        local b2 = buf._data[offset + 2] or 0
        local b3 = buf._data[offset + 3] or 0
        local b4 = buf._data[offset + 4] or 0
        return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
    end
    
    function bufferLib.writei32(buf, offset, value)
        if value < 0 then value = value + 4294967296 end
        buf._data[offset + 1] = value % 256
        buf._data[offset + 2] = math.floor(value / 256) % 256
        buf._data[offset + 3] = math.floor(value / 65536) % 256
        buf._data[offset + 4] = math.floor(value / 16777216) % 256
    end
    
    function bufferLib.writeu32(buf, offset, value)
        buf._data[offset + 1] = value % 256
        buf._data[offset + 2] = math.floor(value / 256) % 256
        buf._data[offset + 3] = math.floor(value / 65536) % 256
        buf._data[offset + 4] = math.floor(value / 16777216) % 256
    end
    
    function bufferLib.readf32(buf, offset)
        local u = bufferLib.readu32(buf, offset)
        if u == 0 then return 0 end
        local sign = bit32.extract(u, 31, 1)
        local exp = bit32.extract(u, 23, 8)
        local frac = bit32.extract(u, 0, 23)
        
        if exp == 255 then
            return frac == 0 and (sign == 0 and math.huge or -math.huge) or 0/0
        elseif exp == 0 then
            return (sign == 0 and 1 or -1) * frac * 2^(-149)
        else
            return (sign == 0 and 1 or -1) * (1 + frac / 8388608) * 2^(exp - 127)
        end
    end
    
    function bufferLib.readf64(buf, offset)
        local lo = bufferLib.readu32(buf, offset)
        local hi = bufferLib.readu32(buf, offset + 4)
        
        local sign = bit32.extract(hi, 31, 1)
        local exp = bit32.extract(hi, 20, 11)
        local frac = bit32.extract(hi, 0, 20) * 4294967296 + lo
        
        if exp == 2047 then
            return frac == 0 and (sign == 0 and math.huge or -math.huge) or 0/0
        elseif exp == 0 then
            return (sign == 0 and 1 or -1) * frac * 2^(-1074)
        else
            return (sign == 0 and 1 or -1) * (1 + frac / 4503599627370496) * 2^(exp - 1023)
        end
    end
    
    function bufferLib.writef32(buf, offset, value)
        local u
        if value ~= value then
            u = 0x7FC00000
        elseif value == math.huge then
            u = 0x7F800000
        elseif value == -math.huge then
            u = 0xFF800000
        elseif value == 0 then
            u = 0
        else
            local sign = value < 0 and 1 or 0
            value = math.abs(value)
            local exp = math.floor(math.log(value) / math.log(2))
            local frac = (value / 2^exp - 1) * 8388608
            exp = exp + 127
            if exp <= 0 then
                frac = value * 2^149
                exp = 0
            elseif exp >= 255 then
                exp = 255
                frac = 0
            end
            u = bit32.lshift(sign, 31) + bit32.lshift(exp, 23) + math.floor(frac)
        end
        bufferLib.writeu32(buf, offset, u)
    end
    
    function bufferLib.writef64(buf, offset, value)
        local lo, hi
        if value ~= value then
            lo = 0
            hi = 0x7FF80000
        elseif value == math.huge then
            lo = 0
            hi = 0x7FF00000
        elseif value == -math.huge then
            lo = 0
            hi = 0xFFF00000
        elseif value == 0 then
            lo = 0
            hi = 0
        else
            local sign = value < 0 and 1 or 0
            value = math.abs(value)
            local exp = math.floor(math.log(value) / math.log(2))
            local frac = (value / 2^exp - 1) * 4503599627370496
            exp = exp + 1023
            if exp <= 0 then
                frac = value * 2^1074
                exp = 0
            elseif exp >= 2047 then
                exp = 2047
                frac = 0
            end
            lo = frac % 4294967296
            hi = bit32.lshift(sign, 31) + bit32.lshift(exp, 20) + math.floor(frac / 4294967296)
        end
        bufferLib.writeu32(buf, offset, lo)
        bufferLib.writeu32(buf, offset + 4, hi)
    end
    
    function bufferLib.copy(target, targetOffset, source, sourceOffset, count)
        sourceOffset = sourceOffset or 0
        count = count or source._size - sourceOffset
        for i = 0, count - 1 do
            target._data[targetOffset + 1 + i] = source._data[sourceOffset + 1 + i] or 0
        end
    end
    
    function bufferLib.fill(buf, offset, value, count)
        count = count or buf._size - offset
        for i = 0, count - 1 do
            buf._data[offset + 1 + i] = value % 256
        end
    end
    
    function bufferLib.readstring(buf, offset, count)
        local chars = {}
        for i = 1, count do
            chars[i] = string.char(buf._data[offset + i] or 0)
        end
        return table.concat(chars)
    end
    
    function bufferLib.writestring(buf, offset, value, count)
        count = count or #value
        for i = 1, count do
            buf._data[offset + i] = string.byte(value, i) or 0
        end
    end
    
    getgenv().buffer = bufferLib
end

-- Utility functions
if not typeof then
    getgenv().typeof = function(v)
        local t = type(v)
        if t == "userdata" then
            local mt = getmetatable(v)
            if mt and mt.__type then
                return mt.__type
            end
        end
        return t
    end
end

if not warn then
    getgenv().warn = function(...)
        local args = {...}
        local str = ""
        for i, v in ipairs(args) do
            str = str .. tostring(v)
            if i < #args then str = str .. " " end
        end
        print("[WARN]:", str)
    end
end

if not printidentity then
    getgenv().printidentity = function(prefix)
        local id = getthreadidentity and getthreadidentity() or 0
        print((prefix or "Current identity is") .. " " .. tostring(id))
    end
end
