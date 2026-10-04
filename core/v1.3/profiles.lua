-- Moon BIOS Phase 2: Boot Profiles
-- Stores selectable boot configurations separately from the main BIOS config.

local Profiles = {}
Profiles.VERSION = 1
Profiles.FILE = "/.moonbios/profiles"

local defaults = {
    Normal = {
        bootFile = "bootfile",
        safe = false,
        liveBoot = true,
        post = true
    },
    Safe = {
        bootFile = "bootfile",
        safe = true,
        liveBoot = true,
        post = true
    },
    Minimal = {
        bootFile = "bootfile",
        safe = false,
        liveBoot = false,
        post = false
    },
    Debug = {
        bootFile = "bootfile",
        safe = false,
        liveBoot = true,
        post = true,
        bootLog = true
    }
}

local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = clone(v) end
    return result
end

function Profiles.defaults()
    return clone(defaults)
end

function Profiles.load()
    if not fs.exists(Profiles.FILE) then
        return clone(defaults)
    end

    local h = fs.open(Profiles.FILE, "r")
    if not h then return clone(defaults) end
    local data = textutils.unserialize(h.readAll())
    h.close()

    if type(data) ~= "table" then return clone(defaults) end
    return data
end

function Profiles.save(data)
    if type(data) ~= "table" then return false end
    fs.makeDir("/.moonbios")
    local h = fs.open(Profiles.FILE, "w")
    if not h then return false end
    h.write(textutils.serialize(data))
    h.close()
    return true
end

function Profiles.get(name)
    local data = Profiles.load()
    if data[name] then return clone(data[name]) end
    return nil
end

function Profiles.set(name, profile)
    if type(name) ~= "string" or name == "" or type(profile) ~= "table" then
        return false, "invalid profile"
    end
    local data = Profiles.load()
    data[name] = clone(profile)
    return Profiles.save(data)
end

function Profiles.delete(name)
    if defaults[name] then return false, "built-in profiles cannot be deleted" end
    local data = Profiles.load()
    if not data[name] then return false, "profile does not exist" end
    data[name] = nil
    return Profiles.save(data)
end

function Profiles.names()
    local data = Profiles.load()
    local names = {}
    for name in pairs(data) do names[#names + 1] = name end
    table.sort(names)
    return names
end

return Profiles
