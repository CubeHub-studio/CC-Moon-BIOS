-- Moon Kernel 1.0
-- Lightweight software kernel for Moon BIOS.
-- CC:Tweaked

local Kernel = {
    VERSION = "Moon Kernel 1.0",
    running = false,
    processes = {},
    nextPid = 1,
    liveBoot = true
}

function Kernel.init(options)
    options = options or {}
    Kernel.running = true
    Kernel.liveBoot = options.liveBoot ~= false
    Kernel.processes = {}
    Kernel.nextPid = 1
    return Kernel
end

function Kernel.log(message)
    local line = "[KERNEL] " .. tostring(message)
    pcall(function()
        fs.makeDir("/.moonbios")
        local f = fs.open("/.moonbios/kernel.log", "a")
        if f then
            f.writeLine(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. line)
            f.close()
        end
    end)
    return line
end

function Kernel.status()
    return {
        version = Kernel.VERSION,
        running = Kernel.running,
        processCount = #Kernel.processes,
        liveBoot = Kernel.liveBoot
    }
end

function Kernel.devices()
    local result = {}
    if peripheral and peripheral.getNames then
        for _, name in ipairs(peripheral.getNames()) do
            result[#result + 1] = {
                name = name,
                type = peripheral.getType(name)
            }
        end
    end
    return result
end

function Kernel.spawn(name)
    local pid = Kernel.nextPid
    Kernel.nextPid = Kernel.nextPid + 1
    Kernel.processes[#Kernel.processes + 1] = {
        pid = pid,
        name = tostring(name or "process"),
        state = "created"
    }
    return pid
end

function Kernel.setProcessState(pid, state)
    for _, process in ipairs(Kernel.processes) do
        if process.pid == pid then
            process.state = state
            return true
        end
    end
    return false
end

function Kernel.run(path, options)
    options = options or {}
    local pid = Kernel.spawn(path)
    Kernel.setProcessState(pid, "starting")
    Kernel.log("Starting process " .. tostring(pid) .. ": " .. tostring(path))

    local ok, result, reason = pcall(function()
        if options.env and type(loadfile) == "function" then
            local program, loadReason = loadfile(path, "t", options.env)
            if not program then
                return false, nil, loadReason
            end

            local success, value = pcall(program, table.unpack(options.args or {}))
            if not success then
                return false, nil, value
            end

            return value ~= false, value, nil
        end

        local success = shell.run(path, table.unpack(options.args or {}))
        return success, nil, nil
    end)

    if not ok then
        Kernel.setProcessState(pid, "crashed")
        Kernel.log("Process " .. tostring(pid) .. " crashed: " .. tostring(result))
        return false, nil, result, pid
    end

    if result == false then
        Kernel.setProcessState(pid, "failed")
        Kernel.log("Process " .. tostring(pid) .. " failed: " .. tostring(reason or "returned failure"))
        return false, nil, reason, pid
    end

    Kernel.setProcessState(pid, "stopped")
    Kernel.log("Process " .. tostring(pid) .. " exited successfully.")
    return true, result, nil, pid
end

function Kernel.panic(message)
    Kernel.running = false
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1, 1)
    print("MOON KERNEL PANIC")
    print()
    print(tostring(message or "Unknown kernel error"))
    print()
    print("Kernel: " .. Kernel.VERSION)
    print("Press ENTER for recovery.")

    while true do
        local event, key = os.pullEvent("key")
        if key == keys.enter then
            return
        end
    end
end

return Kernel
