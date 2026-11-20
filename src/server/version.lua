---@diagnostic disable: undefined-global, undefined-field
local VersionCheck = function(url)
    if not Config.CheckForUpdates then
       return
    end
    local resource = GetInvokingResource() or GetCurrentResourceName()
 
    local currentVersion = GetResourceMetadata(resource, "version", 0)
    if currentVersion then
       currentVersion = currentVersion:match("%d+%.%d+%.%d+")
    end
 
    if not currentVersion then
       return print(("^1Unable to determine current resource version for '%s' ^0"):format(resource))
    end
 
    SetTimeout(1000, function()
       PerformHttpRequest(url, function(status, response)
          if status ~= 200 then
            --  print("^1Failed to fetch latest version info. Status code: " .. status .. "^0")
             return
          end
 
          local latestVersion = response:match("%d+%.%d+%.%d+")
          if not latestVersion or latestVersion == currentVersion then
             print("^2You are using the latest version!^0")
             return
          end
 
          local cv = { string.strsplit(".", currentVersion) }
          local lv = { string.strsplit(".", latestVersion) }
 
          for i = 1, #cv do
             local current, latest = tonumber(cv[i]), tonumber(lv[i])
 
             if current ~= latest then
                if current < latest then
                   return print(
                      ("^3An update is available for %s (current version: %s)\r^0"):format(
                         resource,
                         currentVersion
                      )
                   )
                else
                   break
                end
             end
          end
       end, "GET")
    end)
 end
 
 VersionCheck("https://raw.githubusercontent.com/MrGrootx/g-updates/master/g-vehicle-control.txt")