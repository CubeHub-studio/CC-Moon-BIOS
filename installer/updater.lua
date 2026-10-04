-- Moon BIOS Updater
-- Updates the installed Moon BIOS core through the installer architecture.

local ROOT = "/.moonbios"
local MANIFEST = ROOT .. "/manifest"
local BIOS = ROOT .. "/core/bios.lua"
local KERNEL = ROOT .. "/kernel.lua"
local TEMP = ROOT .. "/core/bios.lua.new"
local BACKUP = ROOT .. "/core/bios.lua.backup"

local BASE = "https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/"

local function stop(message)
    term.setTextColor(colors.red)
    print("ERROR: " .. message)
    term.setTextColor(colors.white)
end

if not http then
    stop("HTTP is not available.")
    return
end

if not fs.exists(MANIFEST) then
    stop("Moon BIOS is not installed. Run mooninstaller.")
    return
end

local f = fs.open(MANIFEST, "r")
local manifest = f and textutils.unserialize(f.readAll()) or nil
if f then f.close() end

if type(manifest) ~= "table" then
    stop("The Moon BIOS installation manifest is invalid.")
    return
end

local version = manifest.version or "1.3"
local source

if version == "1.3-pocket" then
    source = "https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/71e375c32353637d68014db2fbc1a8297f070c86/versions/v1.3-pocket/startup"
else
    source = BASE .. "core/v1.3/bios.lua"
end

print("MOON BIOS UPDATER")
print()
print("Installed version: " .. tostring(version))
print("Downloading BIOS update...")

local response = http.get(source)
if not response then
    stop("Could not download the update.")
    return
end

local data = response.readAll()
response.close()

print("Downloading Moon Kernel update...")
local kernelResponse = http.get(BASE .. "core/v1.3/kernel.lua")
if not kernelResponse then
    stop("Could not download the Moon Kernel update.")
    return
end

local kernelData = kernelResponse.readAll()
kernelResponse.close()

if not kernelData or kernelData == "" then
    stop("Downloaded Moon Kernel is empty.")
    return
end

if not data or data == "" then
    stop("Downloaded update is empty.")
    return
end

if fs.exists(TEMP) then fs.delete(TEMP) end
local out = fs.open(TEMP, "w")
if not out then
    stop("Could not create the temporary update.")
    return
end
out.write(data)
out.close()

if fs.exists(BACKUP) then fs.delete(BACKUP) end
if fs.exists(BIOS) then fs.move(BIOS, BACKUP) end
fs.move(TEMP, BIOS)

local kernelBackup = KERNEL .. ".backup"
if fs.exists(kernelBackup) then fs.delete(kernelBackup) end
if fs.exists(KERNEL) then fs.move(KERNEL, kernelBackup) end
local kernelOut = fs.open(KERNEL, "w")
if not kernelOut then
    stop("Could not write the Moon Kernel update.")
    return
end
kernelOut.write(kernelData)
kernelOut.close()

manifest.updatedAt = os.epoch("utc")
local mf = fs.open(MANIFEST, "w")
mf.write(textutils.serialize(manifest))
mf.close()

print("Update installed successfully.")
print("Rebooting in 3 seconds...")
sleep(3)
os.reboot()
