-- Moon BIOS Installer
-- Required installer for Moon BIOS.
-- CC:Tweaked

local ROOT = "/.moonbios"
local CORE = ROOT .. "/core"
local LEGACY = ROOT .. "/legacy"
local MANIFEST = ROOT .. "/manifest"
local INSTALLER = ROOT .. "/installer.lua"

local BASE = "https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/"
local BOOTLOADER = "startup"
local UPDATER = "updatemoonbios"

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
    if not http then
        return nil, "HTTP is unavailable"
    end
    local ok, response = pcall(http.get, url)
    if not ok or not response then
        return nil, "download failed"
    end
    local data = response.readAll()
    response.close()
    if not data or data == "" then
        return nil, "download was empty"
    end
    return data
end

local function detect()
    local isPocket = type(pocket) == "table"
    local advanced = false

    if type(term.isColor) == "function" then
        advanced = term.isColor()
    end

    if isPocket then
        return "1.3-pocket", "pocket"
    end

    if advanced then
        return "1.3", "advanced"
    end

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

-- Preserve the current startup before replacing it.
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

-- The regular payload is already stored in core/. The pocket payload is
-- assembled from its legacy source during the transition.
local biosData
if version == "1.3-pocket" then
    local data, reason = download("https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/71e375c32353637d68014db2fbc1a8297f070c86/versions/v1.3-pocket/startup")
    if not data then
        return fail("Could not download the pocket BIOS: " .. reason)
    end
    biosData = data
else
    local data, reason = download(BASE .. sourcePath)
    if not data then
        return fail("Could not download the BIOS core: " .. reason)
    end
    biosData = data
end

print("Installing BIOS core...")
if not write(CORE .. "/bios.lua", biosData) then
    return fail("Could not write the BIOS core.")
end

print("Installing updater...")
local updaterData, updaterReason = download(BASE .. "installer/updater.lua")
if not updaterData then
    return fail("Could not download the updater: " .. updaterReason)
end

if not write(CORE .. "/updater.lua", updaterData) then
    return fail("Could not write the updater.")
end

print("Installing bootloader...")
local bootloaderData, bootloaderReason = download(BASE .. "installer/startup")
if not bootloaderData then
    return fail("Could not download the bootloader: " .. bootloaderReason)
end

if not write("/startup", bootloaderData) then
    return fail("Could not install /startup.")
end

print("Installing installer command...")
local installerData, installerReason = download(BASE .. "installer/installer.lua")
if installerData then
    write("/mooninstaller", installerData)
else
    -- The installer is still usable even if this convenience copy fails.
    write("/mooninstaller", "-- Installer copy unavailable. Re-run installer.lua.\n")
end

local manifest = {
    format = 1,
    product = "Moon BIOS",
    version = version,
    device = device,
    installedAt = os.epoch("utc"),
    core = "/.moonbios/core/bios.lua",
    updater = "/.moonbios/core/updater.lua"
}

if not write(MANIFEST, textutils.serialize(manifest)) then
    return fail("Could not write the installation manifest.")
end

print()
print("========================================")
print("       INSTALLATION COMPLETE")
print("========================================")
print()
print("Moon BIOS " .. version .. " is installed.")
print()
print("Installed files:")
print("  /.moonbios/core/bios.lua")
print("  /.moonbios/core/updater.lua")
print("  /.moonbios/manifest")
print("  /startup")
print("  /mooninstaller")
print()
print("The computer will restart in 3 seconds.")
sleep(3)
os.reboot()
