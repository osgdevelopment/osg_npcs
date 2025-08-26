-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'
    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    local resource = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resource, 'version', 0)
    local githubURL = 'https://raw.githubusercontent.com/osgdevelopment/osg-versioncheckers/main/'..resource..'/version.txt?t=' .. os.time()

    PerformHttpRequest(githubURL, function(err, text, headers)
        if err ~= 200 or not text then
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return
        end

        -- split into lines
        local lines = {}
        for line in text:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        local latestVersion = lines[1] or "unknown"

        versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        versionCheckPrint('success', ('Latest Version: %s'):format(latestVersion))

        if latestVersion == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(latestVersion))
        end

        -- optional: print changelog
        if #lines > 1 then
            print("^5[Changelog]^7")
            for i = 2, #lines do
                print("^3 - " .. lines[i] .. "^7")
            end
        end
    end, "GET", "")
end

-----------------------------------------------------------------------
-- start version check
-----------------------------------------------------------------------
CheckVersion()
