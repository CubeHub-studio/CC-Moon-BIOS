-- Moon BIOS Secure Boot verifier
-- Verifies the installed BIOS core and Moon Kernel against the installation manifest.

local ROOT = "/.moonbios"
local MANIFEST = ROOT .. "/manifest"

local function sha256(data)
    if textutils and textutils.sha256 then
        return textutils.sha256(data)
    end
    if fs and fs.getSize then
        -- CC:Tweaked versions without textutils.sha256 cannot perform a
        -- cryptographic verification. Refuse Secure Boot instead of using
        -- a weak substitute.
        return nil, "SHA-256 is unavailable in this CC:Tweaked version"
    end
    return nil, "SHA-256 unavailable"
end

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil, "missing: " .. path end
    local data = h.readAll()
    h.close()
    return data
end

local function fail(reason)
    return false, reason
end

if not fs.exists(MANIFEST) then
    return fail("Secure Boot: installation manifest is missing")
end

local raw = read(MANIFEST)
if not raw then
    return fail("Secure Boot: cannot read installation manifest")
end

local manifest = textutils.unserialize(raw)
if type(manifest) ~= "table" then
    return fail("Secure Boot: invalid installation manifest")
end

local files = {
    { key = "coreHash", path = manifest.core or (ROOT .. "/core/bios.lua") },
    { key = "kernelHash", path = manifest.kernel or (ROOT .. "/kernel.lua") }
}

for _, item in ipairs(files) do
    local data, reason = read(item.path)
    if not data then return fail("Secure Boot: " .. reason) end

    local digest, hashReason = sha256(data)
    if not digest then return fail(hashReason) end

    if not manifest[item.key] then
        return fail("Secure Boot: manifest has no " .. item.key)
    end

    if digest ~= manifest[item.key] then
        return fail("Secure Boot: integrity check failed for " .. item.path)
    end
end

return true, "Secure Boot: all protected components verified"
