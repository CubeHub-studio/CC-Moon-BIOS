-- Moon BIOS Installer
-- Required installer for Moon BIOS.
-- CC:Tweaked

local ROOT = "/.moonbios"
local CORE = ROOT .. "/core"
local KERNEL = ROOT .. "/kernel.lua"
local LEGACY = ROOT .. "/legacy"
local MANIFEST = ROOT .. "/manifest"
local INSTALLER = ROOT .. "/installer.lua"

local BASE = "https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/"

local function fail(message)
    term.setTextColor(colors.red)
    print("ERROR: " .. message)
    term.setTextColor(colors.white)
    print()
    print("Moon BIOS was not installed.")
    return false
end

local function write(path, data)
    local h = fs.open(path, "w")
    if not h then return false end
    h.write(data)
    h.close()
    return true
end

local function download(url)
    if not http then return nil, "HTTP is unavailable" end
    local ok, response = pcall(http.get, url)
    if not ok or not response then return nil, "download failed" end
    local data = response.readAll()
    response.close()
    if not data or data == "" then return nil, "download was empty" end
    return data
end

local function hash(data)
    if not textutils or type(textutils.sha256) ~= "function" then
        return nil, "This CC:Tweaked version does not provide SHA-256; Secure Boot cannot be installed safely."
    end
    return textutils.sha256(data)
end

local function detect()
    local isPocket = type(pocket) == "table"
    local advanced = type(term.isColor) == "function" and term.isColor()
    if isPocket then return "1.3-pocket", "pocket" end
    if advanced then return "1.3", "advanced" end
    return "1.3", "computer"
end

local function backup(path, destination)
    if not fs.exists(path) then return true end
    if fs.exists(destination) then fs.delete(destination) end
    return pcall(fs.copy, path, destination)
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("========================================")
print("          MOON BIOS INSTALLER")
print("========================================")
print()
print("Preparing installation...")

if not http then
    return fail("HTTP is not enabled. Enable HTTP in CC:Tweaked and run the installer again.")
end

local version, device = detect()
print("Device: " .. device)
print("Version: Moon BIOS " .. version)
print()

fs.makeDir(ROOT)
fs.makeDir(CORE)
fs.makeDir(LEGACY)

if fs.exists("/startup") and not fs.exists(LEGACY .. "/startup.backup") then
    print("Backing up existing startup...")
    if not backup("/startup", LEGACY .. "/startup.backup") then
        return fail("Could not back up /startup.")
    end
end

local sourcePath
if version == "1.3-pocket" then
    sourcePath = "versions/v1.3-pocket/startup"
else
    sourcePath = "core/v1.3/bios.lua"
end

local biosData, biosReason
if version == "1.3-pocket" then
    biosData, biosReason = download(BASE .. "versions/v1.3-pocket/startup")
else
    biosData, biosReason = download(BASE .. sourcePath)
end
if not biosData then
    return fail("Could not download the BIOS core: " .. biosReason)
end

print("Installing BIOS core...")
if not write(CORE .. "/bios.lua", biosData) then
    return fail("Could not write the BIOS core.")
end

print("Installing Moon Kernel...")
local kernelData, kernelReason = download(BASE .. "core/v1.3/kernel.lua")
if not kernelData then return fail("Could not download the Moon Kernel: " .. kernelReason) end
if not write(KERNEL, kernelData) then return fail("Could not write the Moon Kernel.") end

print("Installing Secure Boot verifier...")
local verifyData, verifyReason = download(BASE .. "core/v1.3/verify.lua")
if not verifyData then return fail("Could not download the Secure Boot verifier: " .. verifyReason) end
if not write(CORE .. "/verify.lua", verifyData) then return fail("Could not install the Secure Boot verifier.") end

print("Installing updater...")
local updaterData, updaterReason = download(BASE .. "installer/updater.lua")
if not updaterData then return fail("Could not download the updater: " .. updaterReason) end
if not write(CORE .. "/updater.lua", updaterData) then return fail("Could not write the updater.") end
if not write("/updatemoonbios", 'shell.run("/.moonbios/core/updater.lua")\n') then
    return fail("Could not install the updater command.")
end

print("Installing bootloader...")
local bootloaderData, bootloaderReason = download(BASE .. "versions/v1.3/startup")
if not bootloaderData then return fail("Could not download the bootloader: " .. bootloaderReason) end
if not write("/startup", bootloaderData) then return fail("Could not install /startup.") end

print("Installing installer command...")
local installerData = download(BASE .. "installer/installer.lua")
if installerData then write("/mooninstaller", installerData) end

local coreHash, hashReason = hash(biosData)
if not coreHash then return fail(hashReason) end
local kernelHash
kernelHash, hashReason = hash(kernelData)
if not kernelHash then return fail(hashReason) end
local verifyHash
verifyHash, hashReason = hash(verifyData)
if not verifyHash then return fail(hashReason) end
local startupHash
startupHash, hashReason = hash(bootloaderData)
if not startupHash then return fail(hashReason) end

local manifest = {
    format = 2,
    product = "Moon BIOS",
    version = version,
    device = device,
    installedAt = os.epoch("utc"),
    secureBoot = true,
    core = "/.moonbios/core/bios.lua",
    coreHash = coreHash,
    updater = "/.moonbios/core/updater.lua",
    kernel = "/.moonbios/kernel.lua",
    kernelHash = kernelHash,
    verifier = "/.moonbios/core/verify.lua",
    verifierHash = verifyHash,
    bootloader = "/startup",
    startupHash = startupHash,
    kernelVersion = "1.0"
}

if not write(MANIFEST, textutils.serialize(manifest)) then
    return fail("Could not write the installation manifest.")
end

print()
print("========================================")
print("       INSTALLATION COMPLETE")
print("========================================")
print()
print("Moon BIOS " .. version .. " is installed with Secure Boot.")
print("BIOS, Kernel, verifier, and bootloader hashes recorded.")
print()
print("The computer will restart in 3 seconds.")
sleep(3)
os.reboot()
