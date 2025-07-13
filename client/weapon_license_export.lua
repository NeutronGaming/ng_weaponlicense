-- Export function for ox_inventory item usage
function useWeaponLicense(data, slot)
    local input = lib.inputDialog('Show License', {
        {
            type = 'number',
            label = 'Player Server ID',
            description = 'Enter the server ID of the player you want to show your license to',
            required = true,
            min = 1,
            max = 1024
        }
    })
    
    if input and input[1] then
        local targetId = tonumber(input[1])
        if targetId then
            TriggerServerEvent('weaponlicense:showLicenseToPlayer', targetId, {
                metadata = data,
                slot = slot,
                owner = GetPlayerServerId(PlayerId())
            })
        end
    end
end

-- Make it available globally
_G.useWeaponLicense = useWeaponLicense