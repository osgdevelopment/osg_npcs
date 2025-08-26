-----------------------------------------------------------------------
-- version checker (single file for all resources)
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'
    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    local resource = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resource, 'version', 0)
    local githubURL = 'https://raw.githubusercontent.com/osgdevelopment/osg_npcs/refs/heads/main/version.txt?t=' .. os.time()

    PerformHttpRequest(githubURL, function(err, text, headers)
        if err ~= 200 or not text then
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return
        end

        -- parse lines
        local latestVersion
        for line in text:gmatch("[^\r\n]+") do
            local name, ver = line:match("([^:]+):([^:]+)")
            if name and ver and name == resource then
                latestVersion = ver:match("^%s*(.-)%s*$") -- trim
                break
            end
        end

        if not latestVersion then
            versionCheckPrint('error', 'No version entry found for this resource in version.txt.')
            return
        end

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
