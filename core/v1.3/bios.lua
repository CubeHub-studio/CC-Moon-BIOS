-- ============================================================
-- Moon BIOS v1.3
-- CC:Tweaked
--
-- Complete fixed release
--
-- Controls:
--   UP/DOWN     Navigate
--   ENTER       Select
--   BACKSPACE   Back
--
-- Boot shortcuts:
--   1 = BIOS
--   2 = Boot Manager
--   3 = Safe Mode
--
-- Escape is intentionally not used.
-- ============================================================

local VERSION = "Moon BIOS v1.3"

local BOOT_DEFAULT = "bootfile"
local CFG_FILE = "moonbios.cfg"
local SEC_FILE = "moonbios.secure"
local LOG_FILE = "moonbios.log"
local LAST_FILE = "moonbios.last"

local C = colors

local cfg = {
    bootFile = BOOT_DEFAULT,
    bootDelay = 5,
    autoBoot = true,
    post = true,
    safe = false,
    secure = false,
    strict = false,
    animations = true,
    showLogo = true,
    bootLog = true
}

-- ============================================================
-- Safe Calls
-- ============================================================

local function safeCall(fn, ...)
    return pcall(fn, ...)
end

-- ============================================================
-- Terminal Helpers
-- ============================================================

local function terminalWidth()
    local w = term.getSize()
    return w
end

local function terminalHeight()
    local _, h = term.getSize()
    return h
end

local function fitText(text, width)
    text = tostring(text or "")
    width = math.max(1, tonumber(width) or 1)

    if #text <= width then
        return text
    end

    if width <= 3 then
        return text:sub(1, width)
    end

    return text:sub(1, width - 3) .. "..."
end

local function fitLine(text)
    return fitText(
        text,
        math.max(1, terminalWidth())
    )
end

local function clear(bg)
    term.setBackgroundColor(bg or C.black)
    term.setTextColor(C.white)
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
end

local function writeAt(x, y, text, colour)
    local w = terminalWidth()

    x = math.max(1, math.floor(x or 1))
    y = math.max(1, math.floor(y or 1))

    if x > w then
        return
    end

    local available = w - x + 1

    term.setCursorPos(x, y)
    term.setTextColor(colour or C.white)
    term.write(
        fitText(text, available)
    )
end

local function center(y, text, colour)
    local w = terminalWidth()

    text = fitText(
        text,
        math.max(1, w)
    )

    local x = math.max(
        1,
        math.floor((w - #text) / 2) + 1
    )

    term.setCursorPos(
        x,
        math.max(1, y)
    )

    term.setTextColor(
        colour or C.white
    )

    term.write(text)
end

local function line(y, colour)
    local w = terminalWidth()

    term.setCursorPos(
        1,
        math.max(1, y)
    )

    term.setTextColor(
        colour or C.gray
    )

    term.write(
        string.rep("-", w)
    )
end

local function footer(text)
    local h = terminalHeight()

    center(
        h,
        text,
        C.gray
    )
end

local function pause(message)
    footer(
        message or "ENTER = Continue"
    )

    while true do
        local event, key =
            os.pullEvent("key")

        if key == keys.enter then
            return
        end
    end
end

-- ============================================================
-- Logging
-- ============================================================

local function log(message)
    if not cfg.bootLog then
        return
    end

    safeCall(function()
        local f = fs.open(
            LOG_FILE,
            "a"
        )

        if f then
            f.writeLine(
                os.date(
                    "%Y-%m-%d %H:%M:%S"
                )
                .. " | "
                .. tostring(message)
            )

            f.close()
        end
    end)
end

-- ============================================================
-- Configuration
-- ============================================================

local function defaultConfig()
    return {
        bootFile = BOOT_DEFAULT,
        bootDelay = 5,
        autoBoot = true,
        post = true,
        safe = false,
        secure = false,
        strict = false,
        animations = true,
        showLogo = true,
        bootLog = true
    }
end

local function saveConfig()
    safeCall(function()
        local f = fs.open(
            CFG_FILE,
            "w"
        )

        if f then
            f.write(
                textutils.serialize(cfg)
            )

            f.close()
        end
    end)
end

local function resetConfig()
    cfg = defaultConfig()
    saveConfig()
end

local function loadConfig()
    if not fs.exists(CFG_FILE) then
        cfg = defaultConfig()
        saveConfig()
        return
    end

    local ok, data = safeCall(
        function()
            local f = fs.open(
                CFG_FILE,
                "r"
            )

            if not f then
                return nil
            end

            local raw = f.readAll()
            f.close()

            return textutils.unserialize(
                raw
            )
        end
    )

    if ok and type(data) == "table" then
        local defaults = defaultConfig()

        for key, value in pairs(defaults) do
            if data[key] == nil then
                data[key] = value
            end
        end

        cfg = data
    else
        cfg = defaultConfig()

        log(
            "Invalid configuration. Defaults restored."
        )

        saveConfig()
    end

    if type(cfg.bootFile) ~= "string"
        or cfg.bootFile == "" then
        cfg.bootFile = BOOT_DEFAULT
    end

    if type(cfg.bootDelay) ~= "number" then
        cfg.bootDelay = 5
    end

    cfg.bootDelay = math.max(
        0,
        math.min(
            30,
            math.floor(cfg.bootDelay)
        )
    )

    cfg.autoBoot = cfg.autoBoot ~= false
    cfg.post = cfg.post ~= false
    cfg.safe = cfg.safe == true
    cfg.secure = cfg.secure == true
    cfg.strict = cfg.strict == true
    cfg.animations = cfg.animations ~= false
    cfg.showLogo = cfg.showLogo ~= false
    cfg.bootLog = cfg.bootLog ~= false

    saveConfig()
end

-- ============================================================
-- Moon Logo
-- ============================================================

local function moonLogo(y, colour)
    local moon = {
        "             ######",
        "           #######",
        "        #########",
        "      #########",
        "     ########",
        "    #######",
        "    #####",
        "     #######",
        "      ########",
        "       ########",
        "        #########",
        "           #######",
        "             ######"
    }

    for i, row in ipairs(moon) do
        center(
            y + i,
            row,
            colour or C.lightBlue
        )
    end
end

-- ============================================================
-- Logo Screen
-- ============================================================

local function logo()
    clear()

    local h = terminalHeight()

    local y = math.max(
        1,
        math.floor((h - 13) / 2) - 2
    )

    moonLogo(
        y,
        C.lightBlue
    )

    center(
        y + 15,
        "MOON BIOS",
        C.white
    )

    center(
        y + 16,
        VERSION,
        C.gray
    )

    if cfg.animations then
        sleep(0.8)
    else
        sleep(0.2)
    end
end

-- ============================================================
-- POST Tests
-- ============================================================

local function memoryTest()
    local blocks = {}

    for i = 1, 16 do
        blocks[i] =
            string.rep(
                "MOON",
                128
            )
    end

    blocks = nil

    if collectgarbage then
        collectgarbage("collect")
    end

    return true
end

local function filesystemTest()
    local path = ".moonbios_test"

    if fs.exists(path) then
        fs.delete(path)
    end

    local f = fs.open(
        path,
        "w"
    )

    if not f then
        return false
    end

    f.write(
        "MOON BIOS 1.3"
    )

    f.close()

    f = fs.open(
        path,
        "r"
    )

    if not f then
        if fs.exists(path) then
            fs.delete(path)
        end

        return false
    end

    local data = f.readAll()

    f.close()

    if fs.exists(path) then
        fs.delete(path)
    end

    return data == "MOON BIOS 1.3"
end

local function terminalTest()
    local x, y = term.getCursorPos()
    local w, h = term.getSize()

    if not x
        or not y
        or not w
        or not h then
        return false
    end

    term.setCursorPos(1, 1)

    term.setCursorPos(
        math.min(x, w),
        math.min(y, h)
    )

    return true
end

local function peripheralTest()
    local names = peripheral.getNames()
    return type(names) == "table"
end

local function eventTest()
    return type(os.pullEvent) == "function"
        and type(os.queueEvent) == "function"
end

local function shellTest()
    return type(shell) == "table"
        and type(shell.run) == "function"
end

local function storageTest()
    local total = 0

    for _, name in ipairs(
        fs.list("/")
    ) do
        local path =
            fs.combine(
                "/",
                name
            )

        if not fs.isDir(path) then
            local size = fs.getSize(path)

            if type(size) ~= "number" then
                return false, total
            end

            total =
                total + size
        end
    end

    return true, total
end

local function graphicsTest()
    return type(
        term.setGraphicsMode
    ) == "function"
end

-- ============================================================
-- POST
-- ============================================================

local function post()
    if not cfg.post then
        return true
    end

    clear()

    center(
        2,
        "POWER-ON SELF TEST",
        C.lightBlue
    )

    center(
        3,
        VERSION,
        C.gray
    )

    line(
        4,
        C.gray
    )

    local tests = {
        {
            "Computer",
            function()
                return os.getComputerID() ~= nil
            end
        },

        {
            "Memory",
            memoryTest
        },

        {
            "Filesystem",
            filesystemTest
        },

        {
            "Terminal",
            terminalTest
        },

        {
            "Peripherals",
            peripheralTest
        },

        {
            "Events",
            eventTest
        },

        {
            "Shell",
            shellTest
        },

        {
            "Storage",
            function()
                return storageTest()
            end
        },

        {
            "Graphics API",
            graphicsTest
        }
    }

    local y = 6
    local all = true

    for _, test in ipairs(tests) do
        writeAt(
            3,
            y,
            test[1],
            C.white
        )

        local ok, result =
            safeCall(test[2])

        local status

        if ok and result then
            status = "[ OK ]"

            writeAt(
                math.max(
                    1,
                    terminalWidth() - #status - 2
                ),
                y,
                status,
                C.green
            )
        else
            status = "[FAIL]"
            all = false

            writeAt(
                math.max(
                    1,
                    terminalWidth() - #status - 2
                ),
                y,
                status,
                C.red
            )
        end

        y = y + 1

        if y >= terminalHeight() - 2 then
            break
        end
    end

    line(
        math.min(
            y,
            terminalHeight() - 1
        ),
        C.gray
    )

    if all then
        center(
            math.min(
                y + 2,
                terminalHeight() - 1
            ),
            "POST PASSED",
            C.green
        )

        log(
            "POST passed."
        )
    else
        center(
            math.min(
                y + 2,
                terminalHeight() - 1
            ),
            "POST WARNING",
            C.yellow
        )

        log(
            "POST completed with warnings."
        )
    end

    sleep(1.2)

    return all
end

-- ============================================================
-- Hashing
-- ============================================================

local function hashFile(path)
    if not fs.exists(path) then
        return nil
    end

    if fs.isDir(path) then
        return nil
    end

    local f = fs.open(
        path,
        "r"
    )

    if not f then
        return nil
    end

    local data = f.readAll()

    f.close()

    local hash = 2166136261

    for i = 1, #data do
        hash = bit32.bxor(
            hash,
            string.byte(
                data,
                i
            )
        )

        hash =
            (hash * 16777619)
            % 4294967296
    end

    return string.format(
        "%08x",
        hash
    )
end

-- ============================================================
-- Secure Boot
-- ============================================================

local function verifyBootFile(path)
    if not cfg.secure then
        return true
    end

    local current =
        hashFile(path)

    if not current then
        return false
    end

    if not fs.exists(SEC_FILE) then
        return not cfg.strict
    end

    local f = fs.open(
        SEC_FILE,
        "r"
    )

    if not f then
        return false
    end

    local found = false
    local valid = false

    local contents =
        f.readAll()

    f.close()

    for entry in contents:gmatch(
        "[^\r\n]+"
    ) do
        local p, expected =
            entry:match(
                "^(.-)|(.+)$"
            )

        if p == path then
            found = true
            valid =
                expected == current
        end
    end

    if not found then
        return not cfg.strict
    end

    return valid
end

-- ============================================================
-- Integrity Record
-- ============================================================

local function createIntegrityRecord()
    clear()

    center(
        2,
        "SECURE BOOT",
        C.lightBlue
    )

    if not fs.exists(
        cfg.bootFile
    )
    or fs.isDir(
        cfg.bootFile
    ) then

        center(
            6,
            "BOOT FILE NOT FOUND",
            C.red
        )

        center(
            8,
            cfg.bootFile,
            C.white
        )

        pause()

        return
    end

    local hash =
        hashFile(
            cfg.bootFile
        )

    if not hash then
        center(
            6,
            "FAILED TO READ BOOT FILE",
            C.red
        )

        pause()

        return
    end

    local f = fs.open(
        SEC_FILE,
        "w"
    )

    if not f then
        center(
            6,
            "FAILED TO CREATE RECORD",
            C.red
        )

        pause()

        return
    end

    f.writeLine(
        cfg.bootFile
        .. "|"
        .. hash
    )

    f.close()

    center(
        6,
        "INTEGRITY RECORD CREATED",
        C.green
    )

    center(
        8,
        cfg.bootFile,
        C.white
    )

    center(
        9,
        hash,
        C.gray
    )

    log(
        "Created integrity record for "
        .. cfg.bootFile
    )

    pause()
end

-- ============================================================
-- Last Boot
-- ============================================================

local function saveLastBoot(status)
    safeCall(function()
        local f = fs.open(
            LAST_FILE,
            "w"
        )

        if f then
            f.writeLine(
                "file="
                .. tostring(
                    cfg.bootFile
                )
            )

            f.writeLine(
                "status="
                .. tostring(status)
            )

            f.writeLine(
                "time="
                .. tostring(os.date())
            )

            f.close()
        end
    end)
end

local function showLastBoot()
    clear()

    center(
        2,
        "LAST BOOT",
        C.lightBlue
    )

    line(
        3,
        C.gray
    )

    if not fs.exists(
        LAST_FILE
    ) then

        center(
            7,
            "No previous boot record.",
            C.gray
        )

        pause()

        return
    end

    local f = fs.open(
        LAST_FILE,
        "r"
    )

    if not f then
        center(
            7,
            "Unable to read boot record.",
            C.red
        )

        pause()

        return
    end

    local y = 6

    for text in f.readAll():gmatch(
        "[^\r\n]+"
    ) do

        if y >= terminalHeight() - 2 then
            break
        end

        writeAt(
            3,
            y,
            text,
            C.white
        )

        y = y + 1
    end

    f.close()

    pause()
end

-- ============================================================
-- Boot Error
-- ============================================================

local function bootError(reason)
    clear()

    center(
        3,
        "MOON BIOS",
        C.lightBlue
    )

    center(
        5,
        "BOOT ERROR",
        C.red
    )

    center(
        7,
        reason or "Unknown boot error",
        C.white
    )

    footer(
        "ENTER = Recovery"
    )

    log(
        "BOOT ERROR: "
        .. tostring(reason)
    )

    pause()
end

-- ============================================================
-- Boot File
-- ============================================================

local function runBootFile(path)
    if not path
        or path == "" then

        bootError(
            "No boot file configured."
        )

        return false
    end

    if not fs.exists(path) then
        bootError(
            "Boot file not found: "
            .. path
        )

        return false
    end

    if fs.isDir(path) then
        bootError(
            "Boot path is a directory."
        )

        return false
    end

    if not verifyBootFile(path) then
        bootError(
            "Secure Boot blocked the file."
        )

        return false
    end

    log(
        "Booting "
        .. path
    )

    clear()

    local ok, result =
        safeCall(
            function()
                return shell.run(path)
            end
        )

    if not ok then
        bootError(
            "Boot program crashed."
        )

        return false
    end

    if result == false then
        bootError(
            "Boot program returned failure."
        )

        return false
    end

    return true
end

-- ============================================================
-- System Information
-- ============================================================

local function showSystemInfo()
    clear()

    center(
        2,
        "SYSTEM INFORMATION",
        C.lightBlue
    )

    line(
        3,
        C.gray
    )

    local w, h =
        term.getSize()

    local storageOK, storage =
        storageTest()

    local info = {
        "BIOS: " .. VERSION,
        "Computer ID: "
            .. tostring(os.getComputerID()),
        "Label: "
            .. tostring(
                os.getComputerLabel()
                or "Not set"
            ),
        "Boot File: "
            .. cfg.bootFile,
        "Boot Delay: "
            .. cfg.bootDelay
            .. " sec",
        "Auto Boot: "
            .. tostring(cfg.autoBoot),
        "POST: "
            .. tostring(cfg.post),
        "Safe Mode: "
            .. tostring(cfg.safe),
        "Secure Boot: "
            .. tostring(cfg.secure),
        "Strict Secure Boot: "
            .. tostring(cfg.strict),
        "Terminal: "
            .. w
            .. "x"
            .. h,
        "Storage Used: "
            .. tostring(storage)
            .. " bytes",
        "Storage Test: "
            .. tostring(storageOK),
        "CC:Tweaked: "
            .. tostring(
                _HOST
                or "Unknown"
            ),
        "Graphics API: "
            .. tostring(
                graphicsTest()
            )
    }

    local maxLines =
        math.max(
            1,
            terminalHeight() - 7
        )

    for i = 1,
        math.min(
            #info,
            maxLines
        ) do

        writeAt(
            3,
            4 + i,
            info[i],
            C.white
        )
    end

    pause()
end

-- ============================================================
-- File Viewer
-- ============================================================

local function viewFile(path)
    local f = fs.open(
        path,
        "r"
    )

    if not f then
        return
    end

    local data =
        f.readAll()

    f.close()

    local lines = {}

    for text in data:gmatch(
        "[^\r\n]*"
    ) do
        if text ~= "" then
            lines[#lines + 1] =
                text
        end
    end

    if #lines == 0 then
        lines[1] = ""
    end

    local top = 1

    while true do
        clear()

        center(
            2,
            path,
            C.lightBlue
        )

        line(
            3,
            C.gray
        )

        local h =
            terminalHeight()

        local visible =
            math.max(
                1,
                h - 6
            )

        for i = 1, visible do
            local text =
                lines[
                    top + i - 1
                ]

            if text then
                writeAt(
                    2,
                    3 + i,
                    text,
                    C.white
                )
            end
        end

        footer(
            "UP/DOWN Scroll | BACKSPACE Back"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            top =
                math.max(
                    1,
                    top - 1
                )

        elseif key == keys.down then
            local maximum =
                math.max(
                    1,
                    #lines - visible + 1
                )

            top =
                math.min(
                    maximum,
                    top + 1
                )

        elseif key == keys.backspace then
            return
        end
    end
end

-- ============================================================
-- File Manager
-- ============================================================

local function fileManager()
    local dir = "/"

    while true do
        local list =
            fs.list(dir)

        table.sort(list)

        local selected = 1

        if #list == 0 then
            selected = 0
        end

        while true do
            clear()

            center(
                2,
                "FILE MANAGER",
                C.lightBlue
            )

            center(
                3,
                dir,
                C.gray
            )

            line(
                4,
                C.gray
            )

            local h =
                terminalHeight()

            local maxItems =
                math.max(
                    1,
                    h - 7
                )

            if #list == 0 then
                center(
                    7,
                    "Directory is empty.",
                    C.gray
                )
            else
                local start = 1

                if selected > maxItems then
                    start =
                        selected
                        - maxItems
                        + 1
                end

                for i = start,
                    math.min(
                        #list,
                        start + maxItems - 1
                    ) do

                    local row =
                        5
                        + i
                        - start

                    local prefix

                    if i == selected then
                        prefix = "> "
                    else
                        prefix = "  "
                    end

                    local path =
                        fs.combine(
                            dir,
                            list[i]
                        )

                    local label

                    if fs.isDir(path) then
                        label =
                            "[DIR] "
                            .. list[i]
                    else
                        label =
                            list[i]
                    end

                    local colour =
                        C.white

                    if i == selected then
                        colour = C.lime
                    elseif fs.isDir(path) then
                        colour = C.cyan
                    end

                    writeAt(
                        3,
                        row,
                        prefix .. label,
                        colour
                    )
                end
            end

            footer(
                "ENTER Open | BACKSPACE Back"
            )

            local event, key =
                os.pullEvent("key")

            if key == keys.up
                and #list > 0 then

                selected =
                    selected - 1

                if selected < 1 then
                    selected = #list
                end

            elseif key == keys.down
                and #list > 0 then

                selected =
                    selected + 1

                if selected > #list then
                    selected = 1
                end

            elseif key == keys.enter
                and #list > 0
                and list[selected] then

                local path =
                    fs.combine(
                        dir,
                        list[selected]
                    )

                if fs.isDir(path) then
                    dir = path
                    break
                else
                    viewFile(path)
                end

            elseif key == keys.backspace then

                if dir == "/" then
                    return
                end

                dir =
                    fs.getDir(dir)

                if dir == "" then
                    dir = "/"
                end

                break
            end
        end
    end
end

-- ============================================================
-- Boot Scanner
-- ============================================================

local function scanBootFiles()
    local list = {}

    for _, name in ipairs(
        fs.list("/")
    ) do

        if not fs.isDir(name) then
            local lower =
                string.lower(name)

            if lower == "bootfile"
                or lower == "startup"
                or lower:match("^boot")
                or lower:match("%.lua$") then

                list[#list + 1] =
                    name
            end
        end
    end

    table.sort(list)

    return list
end

-- ============================================================
-- Boot Manager
-- ============================================================

local function bootManager()
    local list =
        scanBootFiles()

    if #list == 0 then
        clear()

        center(
            6,
            "NO BOOT FILES FOUND",
            C.yellow
        )

        pause()

        return
    end

    local selected = 1

    while true do
        clear()

        center(
            2,
            "BOOT MANAGER",
            C.lightBlue
        )

        center(
            3,
            "Select a program to boot",
            C.gray
        )

        line(
            4,
            C.gray
        )

        local h =
            terminalHeight()

        local maxItems =
            math.max(
                1,
                h - 7
            )

        local start = 1

        if selected > maxItems then
            start =
                selected
                - maxItems
                + 1
        end

        for i = start,
            math.min(
                #list,
                start + maxItems - 1
            ) do

            local row =
                4
                + i
                - start

            local prefix

            if i == selected then
                prefix = "> "
            else
                prefix = "  "
            end

            writeAt(
                4,
                row,
                prefix .. list[i],
                i == selected
                    and C.lime
                    or C.white
            )
        end

        footer(
            "ENTER Boot | BACKSPACE Back"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            selected =
                selected - 1

            if selected < 1 then
                selected = #list
            end

        elseif key == keys.down then
            selected =
                selected + 1

            if selected > #list then
                selected = 1
            end

        elseif key == keys.enter then

            cfg.bootFile =
                list[selected]

            saveConfig()

            if runBootFile(
                cfg.bootFile
            ) then

                saveLastBoot(
                    "success"
                )

                return
            end

            saveLastBoot(
                "failed"
            )

        elseif key == keys.backspace then
            return
        end
    end
end

-- ============================================================
-- Diagnostics
-- ============================================================

local function diagnostics()
    clear()

    center(
        2,
        "DIAGNOSTICS CENTER",
        C.lightBlue
    )

    line(
        3,
        C.gray
    )

    local tests = {
        {
            "Computer",
            function()
                return os.getComputerID() ~= nil
            end
        },

        {
            "Memory",
            memoryTest
        },

        {
            "Filesystem",
            filesystemTest
        },

        {
            "Terminal",
            terminalTest
        },

        {
            "Peripherals",
            peripheralTest
        },

        {
            "Events",
            eventTest
        },

        {
            "Shell",
            shellTest
        },

        {
            "Storage",
            function()
                return storageTest()
            end
        },

        {
            "Graphics API",
            graphicsTest
        },

        {
            "Boot File",
            function()
                return fs.exists(
                    cfg.bootFile
                )
                and not fs.isDir(
                    cfg.bootFile
                )
            end
        },

        {
            "Secure Boot",
            function()
                return verifyBootFile(
                    cfg.bootFile
                )
            end
        }
    }

    local y = 5

    for _, test in ipairs(tests) do
        if y >= terminalHeight() - 2 then
            break
        end

        writeAt(
            3,
            y,
            test[1],
            C.white
        )

        local ok, result =
            safeCall(test[2])

        local status
        local colour

        if ok and result then
            status = "[ OK ]"
            colour = C.green
        else
            status = "[FAIL]"
            colour = C.red
        end

        writeAt(
            math.max(
                1,
                terminalWidth()
                    - #status
                    - 2
            ),
            y,
            status,
            colour
        )

        y = y + 1
    end

    pause()
end

-- ============================================================
-- Settings
-- ============================================================

local function editBootFile()
    clear()

    center(
        3,
        "BOOT FILE",
        C.lightBlue
    )

    writeAt(
        3,
        6,
        "File: ",
        C.white
    )

    term.setCursorBlink(true)

    local value =
        read()

    term.setCursorBlink(false)

    if value
        and value ~= "" then

        cfg.bootFile =
            value

        saveConfig()

        log(
            "Boot file changed to "
            .. value
        )
    end
end

local function editBootDelay()
    clear()

    center(
        3,
        "BOOT DELAY",
        C.lightBlue
    )

    writeAt(
        3,
        6,
        "Seconds 0-30: ",
        C.white
    )

    term.setCursorBlink(true)

    local value =
        tonumber(
            read()
        )

    term.setCursorBlink(false)

    if value then
        cfg.bootDelay =
            math.max(
                0,
                math.min(
                    30,
                    math.floor(value)
                )
            )

        saveConfig()
    end
end

local function settings()
    local selected = 1

    while true do
        local list = {
            "Boot File: "
                .. cfg.bootFile,

            "Boot Delay: "
                .. cfg.bootDelay,

            "Auto Boot: "
                .. (
                    cfg.autoBoot
                    and "ON"
                    or "OFF"
                ),

            "POST: "
                .. (
                    cfg.post
                    and "ON"
                    or "OFF"
                ),

            "Safe Mode: "
                .. (
                    cfg.safe
                    and "ON"
                    or "OFF"
                ),

            "Secure Boot: "
                .. (
                    cfg.secure
                    and "ON"
                    or "OFF"
                ),

            "Strict Secure Boot: "
                .. (
                    cfg.strict
                    and "ON"
                    or "OFF"
                ),

            "Animations: "
                .. (
                    cfg.animations
                    and "ON"
                    or "OFF"
                ),

            "Show Logo: "
                .. (
                    cfg.showLogo
                    and "ON"
                    or "OFF"
                ),

            "Boot Logging: "
                .. (
                    cfg.bootLog
                    and "ON"
                    or "OFF"
                ),

            "Create Integrity Record",

            "Reset BIOS Settings",

            "Back"
        }

        clear()

        center(
            2,
            "BIOS SETTINGS",
            C.lightBlue
        )

        line(
            3,
            C.gray
        )

        local h =
            terminalHeight()

        local maxItems =
            math.max(
                1,
                h - 6
            )

        local start = 1

        if selected > maxItems then
            start =
                selected
                - maxItems
                + 1
        end

        for i = start,
            math.min(
                #list,
                start + maxItems - 1
            ) do

            local row =
                4
                + i
                - start

            local prefix

            if i == selected then
                prefix = "> "
            else
                prefix = "  "
            end

            writeAt(
                3,
                row,
                prefix .. list[i],
                i == selected
                    and C.lime
                    or C.white
            )
        end

        footer(
            "UP/DOWN Navigate | ENTER Select | BACKSPACE Back"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            selected =
                selected - 1

            if selected < 1 then
                selected = #list
            end

        elseif key == keys.down then
            selected =
                selected + 1

            if selected > #list then
                selected = 1
            end

        elseif key == keys.backspace then
            return

        elseif key == keys.enter then

            if selected == 1 then
                editBootFile()

            elseif selected == 2 then
                editBootDelay()

            elseif selected == 3 then
                cfg.autoBoot =
                    not cfg.autoBoot
                saveConfig()

            elseif selected == 4 then
                cfg.post =
                    not cfg.post
                saveConfig()

            elseif selected == 5 then
                cfg.safe =
                    not cfg.safe
                saveConfig()

            elseif selected == 6 then
                cfg.secure =
                    not cfg.secure
                saveConfig()

            elseif selected == 7 then
                cfg.strict =
                    not cfg.strict
                saveConfig()

            elseif selected == 8 then
                cfg.animations =
                    not cfg.animations
                saveConfig()

            elseif selected == 9 then
                cfg.showLogo =
                    not cfg.showLogo
                saveConfig()

            elseif selected == 10 then
                cfg.bootLog =
                    not cfg.bootLog
                saveConfig()

            elseif selected == 11 then
                createIntegrityRecord()

            elseif selected == 12 then
                resetConfig()

                log(
                    "BIOS settings reset."
                )

            elseif selected == 13 then
                return
            end
        end
    end
end

-- ============================================================
-- Safe Mode
-- ============================================================

local function safeMode()
    local selected = 1

    while true do
        local list = {
            "CraftOS Shell",
            "Boot Manager",
            "File Manager",
            "Diagnostics",
            "Recovery",
            "Restart",
            "Shutdown"
        }

        clear()

        center(
            2,
            "MOON BIOS SAFE MODE",
            C.yellow
        )

        center(
            3,
            "Normal automatic boot is disabled.",
            C.white
        )

        line(
            4,
            C.gray
        )

        for i, text in ipairs(list) do
            writeAt(
                4,
                5 + i,
                (i == selected
                    and "> "
                    or "  ")
                    .. text,
                i == selected
                    and C.lime
                    or C.white
            )
        end

        footer(
            "UP/DOWN Navigate | ENTER Select"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            selected =
                selected - 1

            if selected < 1 then
                selected = #list
            end

        elseif key == keys.down then
            selected =
                selected + 1

            if selected > #list then
                selected = 1
            end

        elseif key == keys.enter then

            if selected == 1 then
                shell.run("shell")

            elseif selected == 2 then
                bootManager()

            elseif selected == 3 then
                fileManager()

            elseif selected == 4 then
                diagnostics()

            elseif selected == 5 then
                return "recovery"

            elseif selected == 6 then
                os.reboot()

            elseif selected == 7 then
                os.shutdown()
            end
        end
    end
end

-- ============================================================
-- Recovery Center
-- ============================================================

local function recovery()
    local selected = 1

    while true do
        local list = {
            "Retry Normal Boot",
            "Safe Mode",
            "CraftOS Shell",
            "Boot Manager",
            "File Manager",
            "Diagnostics",
            "Last Boot Record",
            "Reset BIOS Settings",
            "Restart",
            "Shutdown",
            "Back"
        }

        clear()

        center(
            2,
            "RECOVERY CENTER",
            C.lightBlue
        )

        line(
            3,
            C.gray
        )

        local h =
            terminalHeight()

        local maxItems =
            math.max(
                1,
                h - 6
            )

        local start = 1

        if selected > maxItems then
            start =
                selected
                - maxItems
                + 1
        end

        for i = start,
            math.min(
                #list,
                start + maxItems - 1
            ) do

            local row =
                4
                + i
                - start

            writeAt(
                4,
                row,
                (i == selected
                    and "> "
                    or "  ")
                    .. list[i],
                i == selected
                    and C.lime
                    or C.white
            )
        end

        footer(
            "UP/DOWN Navigate | ENTER Select | BACKSPACE Back"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            selected =
                selected - 1

            if selected < 1 then
                selected = #list
            end

        elseif key == keys.down then
            selected =
                selected + 1

            if selected > #list then
                selected = 1
            end

        elseif key == keys.backspace then
            return

        elseif key == keys.enter then

            if selected == 1 then

                if runBootFile(
                    cfg.bootFile
                ) then

                    saveLastBoot(
                        "success"
                    )

                    return
                end

            elseif selected == 2 then
                return "safe"

            elseif selected == 3 then
                shell.run("shell")

            elseif selected == 4 then
                bootManager()

            elseif selected == 5 then
                fileManager()

            elseif selected == 6 then
                diagnostics()

            elseif selected == 7 then
                showLastBoot()

            elseif selected == 8 then
                resetConfig()

                log(
                    "BIOS settings reset from recovery."
                )

            elseif selected == 9 then
                os.reboot()

            elseif selected == 10 then
                os.shutdown()

            elseif selected == 11 then
                return
            end
        end
    end
end

-- ============================================================
-- Main BIOS Menu
-- ============================================================

local function biosMenu()
    local selected = 1

    while true do
        local list = {
            "Boot",
            "Boot Manager",
            "System Information",
            "Last Boot Record",
            "File Manager",
            "BIOS Settings",
            "Diagnostics Center",
            "Recovery Center",
            "CraftOS Shell",
            "Restart",
            "Shutdown"
        }

        clear()

        local h =
            terminalHeight()

        if cfg.showLogo
            and h >= 25 then

            local y =
                math.max(
                    1,
                    math.floor(
                        (h - 13) / 2
                    ) - 9
                )

            moonLogo(
                y,
                C.lightBlue
            )

            center(
                y + 15,
                VERSION,
                C.gray
            )

        else

            center(
                2,
                "MOON BIOS",
                C.lightBlue
            )

            center(
                3,
                VERSION,
                C.gray
            )

            line(
                4,
                C.gray
            )
        end

        local startY

        if cfg.showLogo
            and h >= 25 then

            startY =
                math.max(
                    18,
                    math.floor(h / 2)
                )

        else
            startY = 5
        end

        local maxVisible =
            math.max(
                1,
                h - startY - 2
            )

        local start = 1

        if selected > maxVisible then
            start =
                selected
                - maxVisible
                + 1
        end

        for i = start,
            math.min(
                #list,
                start + maxVisible - 1
            ) do

            writeAt(
                5,
                startY
                    + i
                    - start,
                (i == selected
                    and "> "
                    or "  ")
                    .. list[i],
                i == selected
                    and C.lime
                    or C.white
            )
        end

        footer(
            "UP/DOWN Navigate | ENTER Select"
        )

        local event, key =
            os.pullEvent("key")

        if key == keys.up then
            selected =
                selected - 1

            if selected < 1 then
                selected = #list
            end

        elseif key == keys.down then
            selected =
                selected + 1

            if selected > #list then
                selected = 1
            end

        elseif key == keys.enter then

            if selected == 1 then
                return "boot"

            elseif selected == 2 then
                bootManager()

            elseif selected == 3 then
                showSystemInfo()

            elseif selected == 4 then
                showLastBoot()

            elseif selected == 5 then
                fileManager()

            elseif selected == 6 then
                settings()

            elseif selected == 7 then
                diagnostics()

            elseif selected == 8 then

                local result =
                    recovery()

                if result == "safe" then
                    return "safe"
                end

            elseif selected == 9 then
                shell.run("shell")

            elseif selected == 10 then
                os.reboot()

            elseif selected == 11 then
                os.shutdown()
            end
        end
    end
end

-- ============================================================
-- Boot Countdown
-- ============================================================

local function countdown()
    if cfg.bootDelay <= 0 then
        return "boot"
    end

    local left =
        cfg.bootDelay

    local timer =
        os.startTimer(1)

    while left > 0 do
        clear()

        local h =
            terminalHeight()

        local y =
            math.max(
                1,
                math.floor(
                    (h - 13) / 2
                ) - 3
            )

        moonLogo(
            y,
            C.lightBlue
        )

        center(
            y + 15,
            "MOON BIOS",
            C.white
        )

        center(
            y + 17,
            "Booting "
                .. cfg.bootFile
                .. " in "
                .. left,
            C.white
        )

        center(
            y + 19,
            "1 BIOS   2 Boot Manager   3 Safe Mode",
            C.gray
        )

        local event, value =
            os.pullEvent()

        if event == "key" then

            if value == keys.one then
                return "bios"
            end

            if value == keys.two then
                return "manager"
            end

            if value == keys.three then
                return "safe"
            end

            if value == keys.enter then
                return "boot"
            end

        elseif event == "timer"
            and value == timer then

            left =
                left - 1

            if left > 0 then
                timer =
                    os.startTimer(1)
            end
        end
    end

    return "boot"
end

-- ============================================================
-- START MOON BIOS
-- ============================================================

loadConfig()

log(
    "Moon BIOS v1.3 started."
)

if cfg.showLogo then
    logo()
end

post()

if cfg.safe then

    safeMode()

else

    local choice =
        countdown()

    if choice == "bios" then

        biosMenu()

    elseif choice == "manager" then

        bootManager()

    elseif choice == "safe" then

        safeMode()

    else

        if cfg.autoBoot then

            if runBootFile(
                cfg.bootFile
            ) then

                saveLastBoot(
                    "success"
                )

            else

                saveLastBoot(
                    "failed"
                )

                local result =
                    recovery()

                if result == "safe" then
                    safeMode()
                end
            end

        else

            biosMenu()
        end
    end
end
