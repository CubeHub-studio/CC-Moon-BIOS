-- Moon BIOS Secure Boot verifier
-- Verifies the installed BIOS core, Moon Kernel, verifier and bootloader.

local ROOT = "/.moonbios"
local MANIFEST = ROOT .. "/manifest"

local function sha256(data)
    if textutils and type(textutils.sha256) == "function" then
        return textutils.sha256(data)
    end
    return nil, "Secure Boot requires CC:Tweaked textutils.sha256"
end

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil, "missing: " .. path end
    local data = h.readAll()
    h.close()
    return data
end

local function verifyFile(manifest, key, fallback)
    local path = manifest[key:gsub("Hash$", "")] or fallback
    local expected = manifest[key]
    if not expected then return false, "manifest is missing " .. key end

    local data, reason = read(path)
    if not data then return false, reason end

    local digest, hashReason = sha256(data)
    if not digest then return false, hashReason end

    if digest ~= expected then
        return false, "integrity check failed: " .. path
    end

    return true
end

local function verify()
    if not fs.exists(MANIFEST) then
        return false, "Secure Boot: installation manifest is missing"
    end

    local raw, reason = read(MANIFEST)
    if not raw then return false, "Secure Boot: " .. reason end

    local manifest = textutils.unserialize(raw)
    if type(manifest) ~= "table" then
        return false, "Secure Boot: invalid installation manifest"
    end

    if manifest.secureBoot ~= true then
        return false, "Secure Boot is not enabled in the installation manifest"
    end

    local checks = {
        { "coreHash", "/.moonbios/core/bios.lua" },
        { "kernelHash", "/.moonbios/kernel.lua" },
        { "verifierHash", "/.moonbios/core/verify.lua" },
        { "startupHash", "/startup" }
    }

    for _, check in ipairs(checks) do
        local ok, err = verifyFile(manifest, check[1], check[2])
        if not ok then
            return false, "Secure Boot: " .. tostring(err)
        end
    end

    return true, "Secure Boot: all protected components verified"
end

return verify
