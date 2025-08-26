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
    -- add ?t=os.time() to bust GitHub cache
    local githubURL = 'https://raw.githubusercontent.com/osgdevelopment/osg_npcs/refs/heads/main/version?t=' .. os.time()

    PerformHttpRequest(githubURL, function(err, text, headers)
        if err ~= 200 or not text then
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return
        end

        -- only take the first line (the version number)
        local latestVersion = text:match("([^\r\n]+)")

        versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        versionCheckPrint('success', ('Latest Version: %s'):format(latestVersion))

        if latestVersion == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(latestVersion))
        end
    end, "GET", "")
end

-----------------------------------------------------------------------
-- start version check
-----------------------------------------------------------------------
CheckVersion()
