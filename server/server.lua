ESX = exports["es_extended"]:getSharedObject()

-- Function to send Discord webhook
function sendDiscordWebhook(applicationData)
    if not WeaponLicenseConfig.DiscordWebhook.enabled or not WeaponLicenseConfig.DiscordWebhook.url then
        return
    end

    local genderDisplay = "Unknown"
    if applicationData.gender then
        if string.lower(applicationData.gender) == "m" then
            genderDisplay = "Male"
        elseif string.lower(applicationData.gender) == "f" then
            genderDisplay = "Female"
        else
            genderDisplay = applicationData.gender
        end
    end
    
    local embed = {
        {
            title = "New Weapon License Application",
            color = WeaponLicenseConfig.DiscordWebhook.color,
            fields = {
                {
                    name = "Applicant",
                    value = genderDisplay .. " | " .. applicationData.firstname .. " " .. applicationData.lastname,
                    inline = false
                },
                {
                    name = "Date of Birth",
                    value = applicationData.dateofbirth,
                    inline = true
                },
                {
                    name = "Submitted",
                    value = applicationData.formatted_date or os.date("%m/%d/%Y %H:%M"),
                    inline = true
                },
                {
                    name = "Player Identifier",
                    value = applicationData.identifier,
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    local payload = {
        username = WeaponLicenseConfig.DiscordWebhook.botName,
        embeds = embed
    }
    
    PerformHttpRequest(WeaponLicenseConfig.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Create database tables
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `weapon_license_applications` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(60) NOT NULL,
            `firstname` varchar(50) NOT NULL,
            `lastname` varchar(50) NOT NULL,
            `dateofbirth` varchar(10) NOT NULL,
            `discord` varchar(50) NOT NULL DEFAULT '',
            `submitted_date` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `weapon_license_accepted` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(60) NOT NULL,
            `firstname` varchar(50) NOT NULL,
            `lastname` varchar(50) NOT NULL,
            `dateofbirth` varchar(10) NOT NULL,
            `discord` varchar(50) NOT NULL DEFAULT '',
            `submitted_date` timestamp NULL,
            `accepted_date` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `weapon_license_bans` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(60) NOT NULL,
            `banned_date` timestamp DEFAULT CURRENT_TIMESTAMP,
            `banned_by` varchar(60) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `weapon_licenses` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(60) NOT NULL,
            `firstname` varchar(50) NOT NULL,
            `lastname` varchar(50) NOT NULL,
            `dateofbirth` varchar(10) NOT NULL,
            `gender` varchar(10) NOT NULL,
            `discord` varchar(50) NOT NULL DEFAULT '',
            `issued_date` timestamp DEFAULT CURRENT_TIMESTAMP,
            `strikes` int(11) DEFAULT 0,
            `revoked` tinyint(1) DEFAULT 0,
            `revoked_date` timestamp NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        )
    ]])
    
    MySQL.Async.fetchAll("SHOW COLUMNS FROM weapon_license_applications LIKE 'discord'", {}, function(result)
        if #result == 0 then
            MySQL.Async.execute('ALTER TABLE weapon_license_applications ADD COLUMN discord VARCHAR(50) NOT NULL DEFAULT ""', {}, function() end)
        end
    end)
    
    MySQL.Async.fetchAll("SHOW COLUMNS FROM weapon_license_accepted LIKE 'discord'", {}, function(result)
        if #result == 0 then
            MySQL.Async.execute('ALTER TABLE weapon_license_accepted ADD COLUMN discord VARCHAR(50) NOT NULL DEFAULT ""', {}, function() end)
        end
    end)
end)

-- Get license records for police
RegisterServerEvent('weaponlicense:getLicenseRecords')
AddEventHandler('weaponlicense:getLicenseRecords', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    local hasRankAccess = false
    
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            
            if WeaponLicenseConfig.RankRequirements.enabled then
                local requiredGrade = WeaponLicenseConfig.RankRequirements.records[job]
                if requiredGrade and xPlayer.job.grade >= requiredGrade then
                    hasRankAccess = true
                end
            else
                hasRankAccess = true
            end
            break
        end
    end
    
    if not isPolice then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to access this',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    if not hasRankAccess then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Insufficient Rank',
            description = 'Your rank is too low to access license records',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    MySQL.Async.fetchAll([[
        SELECT 
            COALESCE(ul.owner, wlb.identifier) as identifier,
            u.sex as gender,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            wla.discord,
            DATE_FORMAT(wla.accepted_date, "%m/%d/%Y %H:%i") as issued_date,
            CASE WHEN wlb.identifier IS NOT NULL THEN 1 ELSE 0 END as is_banned
        FROM (
            SELECT DISTINCT owner as identifier FROM user_licenses WHERE type = ?
            UNION
            SELECT DISTINCT identifier FROM weapon_license_bans
        ) AS all_identifiers
        LEFT JOIN user_licenses ul ON all_identifiers.identifier = ul.owner AND ul.type = ?
        LEFT JOIN users u ON all_identifiers.identifier = u.identifier
        LEFT JOIN weapon_license_accepted wla ON all_identifiers.identifier = wla.identifier
        LEFT JOIN weapon_license_bans wlb ON all_identifiers.identifier = wlb.identifier
        ORDER BY u.firstname, u.lastname
    ]], {WeaponLicenseConfig.LicenseType, WeaponLicenseConfig.LicenseType}, function(result)
        TriggerClientEvent('weaponlicense:showLicenseRecords', src, result)
    end)
end)

-- Revoke weapon license
RegisterServerEvent('weaponlicense:revokeLicense')
AddEventHandler('weaponlicense:revokeLicense', function(targetIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end
    
    if not isPolice then return end
    
    MySQL.Async.execute('DELETE FROM user_licenses WHERE owner = ? AND type = ?', {
        targetIdentifier,
        WeaponLicenseConfig.LicenseType
    }, function(rowsChanged)
        if rowsChanged > 0 then
            local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
            if targetPlayer and WeaponLicenseConfig.GiveItem then
                exports.ox_inventory:RemoveItem(targetPlayer.source, WeaponLicenseConfig.ItemName, 1)
            end
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'License Revoked',
                description = 'The weapon license has been revoked',
                type = 'success',
                position = 'top'
            })
            
            TriggerClientEvent('weaponlicense:refreshRecords', -1)
        end
    end)
end)

-- Ban player from applications
RegisterServerEvent('weaponlicense:banPlayer')
AddEventHandler('weaponlicense:banPlayer', function(targetIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end
    
    if not isPolice then return end
    
    MySQL.Async.execute('DELETE FROM user_licenses WHERE owner = ? AND type = ?', {
        targetIdentifier,
        WeaponLicenseConfig.LicenseType
    }, function(licenseRowsChanged)
        if licenseRowsChanged > 0 then
            local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
            if targetPlayer and WeaponLicenseConfig.GiveItem then
                exports.ox_inventory:RemoveItem(targetPlayer.source, WeaponLicenseConfig.ItemName, 1)
            end
        end
        
        MySQL.Async.execute('DELETE FROM weapon_license_accepted WHERE identifier = ?', {
            targetIdentifier
        }, function()
            MySQL.Async.execute('DELETE FROM weapon_license_applications WHERE identifier = ?', {
                targetIdentifier
            }, function()
                MySQL.Async.execute('INSERT INTO weapon_license_bans (identifier, banned_by) VALUES (?, ?) ON DUPLICATE KEY UPDATE banned_date = CURRENT_TIMESTAMP, banned_by = ?', {
                    targetIdentifier,
                    xPlayer.identifier,
                    xPlayer.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        local message = 'The player has been banned from weapon licenses'
                        if licenseRowsChanged > 0 then
                            message = message .. ' and their current license has been revoked'
                        end
                        
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Player Banned',
                            description = message,
                            type = 'success',
                            position = 'top'
                        })
                        
                        TriggerClientEvent('weaponlicense:refreshRecords', -1)
                    end
                end)
            end)
        end)
    end)
end)

-- Unban player from applications
RegisterServerEvent('weaponlicense:unbanPlayer')
AddEventHandler('weaponlicense:unbanPlayer', function(targetIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end
    
    if not isPolice then return end
    
    MySQL.Async.execute('DELETE FROM weapon_license_bans WHERE identifier = ?', {
        targetIdentifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Player Unbanned',
                description = 'The player can now apply for weapon licenses again',
                type = 'success',
                position = 'top'
            })
            
            TriggerClientEvent('weaponlicense:refreshRecords', -1)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Player was not banned or error occurred',
                type = 'error',
                position = 'top'
            })
        end
    end)
end)

-- Submit application
RegisterServerEvent('weaponlicense:submitApplication')
AddEventHandler('weaponlicense:submitApplication', function(firstname, lastname, dob, discord)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if not string.match(dob, "^%d%d/%d%d/%d%d%d%d$") then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Invalid Date Format',
            description = 'Please use MM/DD/YYYY format',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    if not discord or string.len(discord) < 2 or string.len(discord) > 50 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Invalid Discord Username',
            description = 'Please enter a valid Discord username',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    if WeaponLicenseConfig.ApplicationCost.enabled then
        local cost = WeaponLicenseConfig.ApplicationCost.amount
        local playerMoney = xPlayer.getMoney()
        local playerBank = xPlayer.getAccount('bank').money
        
        if (playerMoney + playerBank) < cost then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Insufficient Funds',
                description = 'You need $' .. cost .. ' to submit an application',
                type = 'error',
                position = 'top'
            })
            return
        end
    end
    
    MySQL.Async.fetchAll('SELECT * FROM weapon_license_applications WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if #result > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Application Already Submitted',
                description = 'You already have a pending application',
                type = 'error',
                position = 'top'
            })
            return
        end
        
        MySQL.Async.fetchAll('SELECT * FROM weapon_license_accepted WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(acceptedResult)
            if #acceptedResult > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Already Approved',
                    description = 'You are already approved to take the exam',
                    type = 'error',
                    position = 'top'
                })
                return
            end
            
            MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE owner = @identifier AND type = @type', {
                ['@identifier'] = xPlayer.identifier,
                ['@type'] = WeaponLicenseConfig.LicenseType
            }, function(licenseResult)
                if #licenseResult > 0 then
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'License Already Owned',
                        description = 'You already have a weapon license',
                        type = 'error',
                        position = 'top'
                    })
                    return
                end
                
                if WeaponLicenseConfig.ApplicationCost.enabled then
                    local cost = WeaponLicenseConfig.ApplicationCost.amount
                    local playerMoney = xPlayer.getMoney()
                    
                    if playerMoney >= cost then
                        xPlayer.removeMoney(cost)
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Payment Processed',
                            description = 'Paid $' .. cost .. ' from cash',
                            type = 'info',
                            position = 'top'
                        })
                    else
                        local remainingCost = cost - playerMoney
                        if playerMoney > 0 then
                            xPlayer.removeMoney(playerMoney)
                        end
                        xPlayer.removeAccountMoney('bank', remainingCost)
                        
                        local cashUsed = playerMoney
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Payment Processed',
                            description = 'Paid $' .. cost .. ' ($' .. cashUsed .. ' cash, $' .. remainingCost .. ' bank)',
                            type = 'info',
                            position = 'top'
                        })
                    end
                end
                
                MySQL.Async.execute('INSERT INTO weapon_license_applications (identifier, firstname, lastname, dateofbirth, discord) VALUES (@identifier, @firstname, @lastname, @dob, @discord)', {
                    ['@identifier'] = xPlayer.identifier,
                    ['@firstname'] = firstname,
                    ['@lastname'] = lastname,
                    ['@dob'] = dob,
                    ['@discord'] = discord
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        sendDiscordWebhook({
                            identifier = xPlayer.identifier,
                            firstname = firstname,
                            lastname = lastname,
                            dateofbirth = dob,
                            gender = xPlayer.get('sex'),
                            formatted_date = os.date("%m/%d/%Y %H:%M", os.time() - (6 * 3600)) -- EST is UTC-5
                        })
                        
                        local message = 'Your weapon license application has been submitted for review'
                        if WeaponLicenseConfig.ApplicationCost.enabled then
                            message = message .. ' (Cost: $' .. WeaponLicenseConfig.ApplicationCost.amount .. ')'
                        end
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Application Submitted',
                            description = message,
                            type = 'success',
                            position = 'top'
                        })
                    end
                end)
            end)
        end)
    end)
end)

-- Get applications for police
RegisterServerEvent('weaponlicense:getApplications')
AddEventHandler('weaponlicense:getApplications', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    local hasRankAccess = false
    
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            
            if WeaponLicenseConfig.RankRequirements.enabled then
                local requiredGrade = WeaponLicenseConfig.RankRequirements.applications[job]
                if requiredGrade and xPlayer.job.grade >= requiredGrade then
                    hasRankAccess = true
                end
            else
                hasRankAccess = true
            end
            break
        end
    end
    
    if not isPolice then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to access this',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    if not hasRankAccess then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Insufficient Rank',
            description = 'Your rank is too low to review applications',
            type = 'error',
            position = 'top'
        })
        return
    end
    
    MySQL.Async.fetchAll([[
        SELECT 
            wla.*, 
            DATE_FORMAT(DATE_SUB(wla.submitted_date, INTERVAL 4 HOUR), "%m/%d/%Y %H:%i") as formatted_date,
            u.sex as gender
        FROM weapon_license_applications wla
        LEFT JOIN users u ON wla.identifier = u.identifier
        ORDER BY wla.submitted_date DESC
    ]], {}, function(result)
        TriggerClientEvent('weaponlicense:showApplications', src, result)
    end)
end)

-- Validate license ownership
RegisterServerEvent('weaponlicense:validateLicenseOwnership')
AddEventHandler('weaponlicense:validateLicenseOwnership', function(targetSrc, licenseMetadata)
    local src = source
    local targetPlayer = ESX.GetPlayerFromId(targetSrc)
    
    if not targetPlayer then 
        TriggerClientEvent('weaponlicense:updateLicenseOwnership', src, false)
        return 
    end
    
    MySQL.Async.fetchAll('SELECT ul.owner FROM user_licenses ul WHERE ul.owner = ? AND ul.type = ?', {
        targetPlayer.identifier,
        WeaponLicenseConfig.LicenseType
    }, function(licenseResult)
        if #licenseResult == 0 then
            TriggerClientEvent('weaponlicense:updateLicenseOwnership', src, false)
            return
        end
        
        MySQL.Async.fetchAll('SELECT firstname, lastname, dateofbirth, sex FROM users WHERE identifier = ?', {
            targetPlayer.identifier
        }, function(result)
            local isValid = false
            
            if #result > 0 then
                local playerData = result[1]
                local firstnameMatch = (licenseMetadata.firstname or ''):lower() == (playerData.firstname or ''):lower()
                local lastnameMatch = (licenseMetadata.lastname or ''):lower() == (playerData.lastname or ''):lower()
                local playerDOB = playerData.dateofbirth or ''
                if playerDOB ~= '' and string.match(playerDOB, "^%d%d/%d%d/%d%d%d%d$") then
                    local day, month, year = string.match(playerDOB, "(%d%d)/(%d%d)/(%d%d%d%d)")
                    if day and month and year then
                        playerDOB = month .. "/" .. day .. "/" .. year
                    end
                end
                
                local dobMatch = (licenseMetadata.dateofbirth or '') == playerDOB
                local playerGender = "Unknown"
                if playerData.sex then
                    if string.lower(playerData.sex) == "m" then
                        playerGender = "Male"
                    elseif string.lower(playerData.sex) == "f" then
                        playerGender = "Female"
                    else
                        playerGender = playerData.sex
                    end
                end
                
                local genderMatch = (licenseMetadata.gender or '') == playerGender
                isValid = firstnameMatch and lastnameMatch and dobMatch and genderMatch
            end
            TriggerClientEvent('weaponlicense:updateLicenseOwnership', src, isValid)
        end)
    end)
end)

-- Process application (approve/deny)
RegisterServerEvent('weaponlicense:processApplication')
AddEventHandler('weaponlicense:processApplication', function(applicationId, action)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end
    
    if not isPolice then return end
    
    if action == 'approve' then
        MySQL.Async.fetchAll('SELECT * FROM weapon_license_applications WHERE id = @id', {
            ['@id'] = applicationId
        }, function(result)
            if #result > 0 then
                local app = result[1]
                
                -- Move to accepted table - use NOW() instead of the timestamp
                MySQL.Async.execute('INSERT INTO weapon_license_accepted (identifier, firstname, lastname, dateofbirth, discord, submitted_date) VALUES (@identifier, @firstname, @lastname, @dob, @discord, NOW())', {
                    ['@identifier'] = app.identifier,
                    ['@firstname'] = app.firstname,
                    ['@lastname'] = app.lastname,
                    ['@dob'] = app.dateofbirth,
                    ['@discord'] = app.discord
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        MySQL.Async.execute('DELETE FROM weapon_license_applications WHERE id = @id', {
                            ['@id'] = applicationId
                        })
                        
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Application Approved',
                            description = 'The application has been approved',
                            type = 'success',
                            position = 'top'
                        })
                        
                        TriggerClientEvent('weaponlicense:refreshApplications', -1)
                    end
                end)
            end
        end)
    elseif action == 'deny' then
        MySQL.Async.execute('DELETE FROM weapon_license_applications WHERE id = @id', {
            ['@id'] = applicationId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Application Denied',
                    description = 'The application has been denied',
                    type = 'success',
                    position = 'top'
                })
                
                TriggerClientEvent('weaponlicense:refreshApplications', -1)
            end
        end)
    end
end)

-- Check if player can take exam
RegisterServerEvent('weaponlicense:checkExamEligibility')
AddEventHandler('weaponlicense:checkExamEligibility', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local isPolice = false
    for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end
    
    if isPolice then
        TriggerClientEvent('weaponlicense:startExam', src)
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM weapon_license_accepted WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if #result > 0 then
            MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE owner = @identifier AND type = @type', {
                ['@identifier'] = xPlayer.identifier,
                ['@type'] = WeaponLicenseConfig.LicenseType
            }, function(licenseResult)
                if #licenseResult > 0 then
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'License Already Owned',
                        description = 'You already have a weapon license',
                        type = 'error',
                        position = 'top'
                    })
                    return
                end
                
                TriggerClientEvent('weaponlicense:startExam', src)
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Not Eligible',
                description = 'You need to submit an application and get approved first',
                type = 'error',
                position = 'top'
            })
        end
    end)
end)

-- Check application eligibility before showing form
RegisterServerEvent('weaponlicense:checkApplicationEligibility')
AddEventHandler('weaponlicense:checkApplicationEligibility', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    MySQL.Async.fetchAll('SELECT * FROM weapon_license_bans WHERE identifier = ?', {
        xPlayer.identifier
    }, function(banResult)
        if #banResult > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Application Banned',
                description = 'You are banned from applying for weapon licenses',
                type = 'error',
                position = 'top'
            })
            return
        end

        MySQL.Async.fetchAll('SELECT * FROM weapon_license_applications WHERE identifier = ?', {
            xPlayer.identifier
        }, function(result)
            if #result > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Application Already Submitted',
                    description = 'You already have an application placed, please be patient',
                    type = 'error',
                    position = 'top'
                })
                return
            end

            MySQL.Async.fetchAll('SELECT * FROM weapon_license_accepted WHERE identifier = ?', {
                xPlayer.identifier
            }, function(acceptedResult)
                if #acceptedResult > 0 then
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Already Approved',
                        description = 'You are already approved to take the exam',
                        type = 'error',
                        position = 'top'
                    })
                    return
                end

                MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE owner = ? AND type = ?', {
                    xPlayer.identifier,
                    WeaponLicenseConfig.LicenseType
                }, function(licenseResult)
                    if #licenseResult > 0 then
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'License Already Owned',
                            description = 'You already have a weapon license',
                            type = 'error',
                            position = 'top'
                        })
                        return
                    end
                    TriggerClientEvent('weaponlicense:showApplicationForm', src)
                end)
            end)
        end)
    end)
end)

-- Process exam results
RegisterServerEvent('weaponlicense:submitExamResults')
AddEventHandler('weaponlicense:submitExamResults', function(score, totalQuestions)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local passed = score >= WeaponLicenseConfig.ExamSettings.questionsToPass
    
    if passed then
        MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = ?', {
            xPlayer.identifier
        }, function(usersResult)
            MySQL.Async.fetchAll('SELECT * FROM weapon_license_accepted WHERE identifier = ?', {
                xPlayer.identifier
            }, function(acceptedResult)
                MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (?, ?)', {
                    WeaponLicenseConfig.LicenseType,
                    xPlayer.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        if WeaponLicenseConfig.GiveItem then
                            local metadata = {
                                firstname = "Unknown",
                                lastname = "Unknown",
                                dateofbirth = "Unknown",
                                gender = "Unknown",
                                issued_date = os.date("%m/%d/%Y"),
                                license_type = "Weapon License",
                                strikes = 0
                            }
                            if #usersResult > 0 then
                                local userData = usersResult[1]
                                
                                metadata.firstname = userData.firstname or "Unknown"
                                metadata.lastname = userData.lastname or "Unknown"
                                local dob = userData.dateofbirth or "Unknown"
                                if dob ~= "Unknown" and string.match(dob, "^%d%d/%d%d/%d%d%d%d$") then
                                    local day, month, year = string.match(dob, "(%d%d)/(%d%d)/(%d%d%d%d)")
                                    if day and month and year then
                                        metadata.dateofbirth = month .. "/" .. day .. "/" .. year
                                    else
                                        metadata.dateofbirth = dob
                                    end
                                else
                                    metadata.dateofbirth = dob
                                end
                                
                                if userData.sex == 'm' then
                                    metadata.gender = "Male"
                                elseif userData.sex == 'f' then
                                    metadata.gender = "Female"
                                else
                                    metadata.gender = "Unknown"
                                end
                            end
                            
                            local success = exports.ox_inventory:AddItem(src, WeaponLicenseConfig.ItemName, 1, metadata)
                            
                            if success then
                            else
                            end
                        end
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Exam Passed!',
                            description = 'Congratulations! You scored ' .. score .. '/' .. totalQuestions .. ' and have been awarded a weapon license',
                            type = 'success',
                            position = 'top'
                        })
                    else
                    end
                end)
            end)
        end)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Exam Failed',
            description = 'You scored ' .. score .. '/' .. totalQuestions .. '. You need at least ' .. WeaponLicenseConfig.ExamSettings.questionsToPass .. ' correct answers to pass',
            type = 'error',
            position = 'top'
        })
    end
end)

-- Check replacement eligibility
RegisterServerEvent('weaponlicense:checkReplacementEligibility')
AddEventHandler('weaponlicense:checkReplacementEligibility', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    MySQL.Async.fetchAll([[
        SELECT 
            ul.owner as identifier,
            u.sex as gender,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            wla.discord,
            DATE_FORMAT(wla.accepted_date, "%m/%d/%Y") as issued_date,
            CASE WHEN wlb.identifier IS NOT NULL THEN 1 ELSE 0 END as is_banned
        FROM user_licenses ul
        LEFT JOIN users u ON ul.owner = u.identifier
        LEFT JOIN weapon_license_accepted wla ON ul.owner = wla.identifier
        LEFT JOIN weapon_license_bans wlb ON ul.owner = wlb.identifier
        WHERE ul.type = ? AND ul.owner = ?
    ]], {WeaponLicenseConfig.LicenseType, xPlayer.identifier}, function(result)
        if #result > 0 and result[1].is_banned == 0 then
            TriggerClientEvent('weaponlicense:showReplacementMenu', src, result[1])
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Not Eligible',
                description = 'You do not have an active weapon license or are banned',
                type = 'error',
                position = 'top'
            })
        end
    end)
end)

-- Purchase replacement license
RegisterServerEvent('weaponlicense:purchaseReplacement')
AddEventHandler('weaponlicense:purchaseReplacement', function(playerData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    if WeaponLicenseConfig.ReplacementCost.enabled then
        local cost = WeaponLicenseConfig.ReplacementCost.amount
        local playerMoney = xPlayer.getMoney()
        local playerBank = xPlayer.getAccount('bank').money
        if (playerMoney + playerBank) < cost then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Insufficient Funds',
                description = 'You need $' .. cost .. ' for a replacement license',
                type = 'error',
                position = 'top'
            })
            return
        end
        if playerMoney >= cost then
            xPlayer.removeMoney(cost)
        else
            local remainingCost = cost - playerMoney
            if playerMoney > 0 then
                xPlayer.removeMoney(playerMoney)
            end
            xPlayer.removeAccountMoney('bank', remainingCost)
        end
    end
    MySQL.Async.fetchAll([[
        SELECT 
            u.sex as gender,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            wla.discord,
            DATE_FORMAT(wla.accepted_date, "%m/%d/%Y") as issued_date
        FROM users u
        LEFT JOIN weapon_license_accepted wla ON u.identifier = wla.identifier
        WHERE u.identifier = ?
    ]], {xPlayer.identifier}, function(result)
        
        local metadata = {
            firstname = "Unknown",
            lastname = "Unknown",
            dateofbirth = "Unknown",
            gender = "Unknown",
            issued_date = os.date("%m/%d/%Y"),
            license_type = "Weapon License",
            strikes = 0
        }
        
        if #result > 0 then
            local userData = result[1]
            metadata.firstname = userData.firstname or "Unknown"
            metadata.lastname = userData.lastname or "Unknown"
            
            local dob = userData.dateofbirth or "Unknown"
            if dob ~= "Unknown" and string.match(dob, "^%d%d/%d%d/%d%d%d%d$") then
                local day, month, year = string.match(dob, "(%d%d)/(%d%d)/(%d%d%d%d)")
                if day and month and year then
                    metadata.dateofbirth = month .. "/" .. day .. "/" .. year
                else
                    metadata.dateofbirth = dob
                end
            else
                metadata.dateofbirth = dob
            end

            if userData.gender then
                if string.lower(userData.gender) == "m" then
                    metadata.gender = "Male"
                elseif string.lower(userData.gender) == "f" then
                    metadata.gender = "Female"
                else
                    metadata.gender = userData.gender
                end
            end
            
            metadata.issued_date = userData.issued_date or os.date("%m/%d/%Y")
        end
        
        exports.ox_inventory:AddItem(src, WeaponLicenseConfig.ItemName, 1, metadata)
        
        local message = 'Replacement weapon license issued'
        if WeaponLicenseConfig.ReplacementCost.enabled then
            message = message .. ' (Cost: $' .. WeaponLicenseConfig.ReplacementCost.amount .. ')'
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'License Issued',
            description = message,
            type = 'success',
            position = 'top'
        })
    end)
end)

-- Show license to another player
RegisterServerEvent('weaponlicense:showLicenseToPlayer')
AddEventHandler('weaponlicense:showLicenseToPlayer', function(targetId, licenseData)
    local src = source
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Player Not Found',
            description = 'Player with ID ' .. targetId .. ' not found',
            type = 'error',
            position = 'top'
        })
        return
    end

    TriggerClientEvent('weaponlicense:displayLicense', targetId, licenseData, src)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'License Shown',
        description = 'License shown to player ID: ' .. targetId,
        type = 'success',
        position = 'top'
    })
end)

-- Add strike to license
RegisterServerEvent('weaponlicense:addStrike')
AddEventHandler('weaponlicense:addStrike', function(targetSrc, licenseSlot)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local targetPlayer = ESX.GetPlayerFromId(targetSrc)
    
    if not xPlayer or not targetPlayer then return end
    
    local isPolice = false
    if WeaponLicenseConfig.PoliceJobs then
        for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
            if xPlayer.job.name == job then
                isPolice = true
                break
            end
        end
    end
    
    if not isPolice then return end
    
    local item = exports.ox_inventory:GetSlot(targetSrc, licenseSlot)
    if not item or item.name ~= WeaponLicenseConfig.ItemName then return end
    
    local metadata = item.metadata or {}
    local currentStrikes = metadata.strikes or 0
    local newStrikes = currentStrikes + 1
    
    if newStrikes >= WeaponLicenseConfig.StrikeSystem.maxStrikes then
        exports.ox_inventory:RemoveItem(targetSrc, WeaponLicenseConfig.ItemName, 1, metadata, licenseSlot)
        MySQL.Async.execute('DELETE FROM user_licenses WHERE owner = ? AND type = ?', {
            targetPlayer.identifier,
            WeaponLicenseConfig.LicenseType
        })
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'License Revoked',
            description = 'License revoked due to maximum strikes (' .. WeaponLicenseConfig.StrikeSystem.maxStrikes .. ')',
            type = 'success',
            position = 'top'
        })
        
        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'License Revoked',
            description = 'Your weapon license has been revoked due to strikes',
            type = 'error',
            position = 'top'
        })
        
        TriggerClientEvent('weaponlicense:closeLicenseDisplay', src)
    else
        metadata.strikes = newStrikes
        exports.ox_inventory:SetMetadata(targetSrc, licenseSlot, metadata)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Strike Added',
            description = 'Strike added. Total strikes: ' .. newStrikes .. '/' .. WeaponLicenseConfig.StrikeSystem.maxStrikes,
            type = 'success',
            position = 'top'
        })
        
        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Strike Added',
            description = 'A strike has been added to your weapon license (' .. newStrikes .. '/' .. WeaponLicenseConfig.StrikeSystem.maxStrikes .. ')',
            type = 'warning',
            position = 'top'
        })
        
        TriggerClientEvent('weaponlicense:refreshLicenseDisplay', src, {
            metadata = metadata,
            slot = licenseSlot,
            owner = targetSrc
        }, targetSrc)
    end
end)

-- Revoke license via inspection
RegisterServerEvent('weaponlicense:revokeLicenseInspection')
AddEventHandler('weaponlicense:revokeLicenseInspection', function(targetSrc, licenseSlot)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local targetPlayer = ESX.GetPlayerFromId(targetSrc)
    
    if not xPlayer or not targetPlayer then return end
    
    local isPolice = false
    if WeaponLicenseConfig.PoliceJobs then
        for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
            if xPlayer.job.name == job then
                isPolice = true
                break
            end
        end
    end
    
    if not isPolice then return end
    
    local item = exports.ox_inventory:GetSlot(targetSrc, licenseSlot)
    if not item or item.name ~= WeaponLicenseConfig.ItemName then return end
    
    exports.ox_inventory:RemoveItem(targetSrc, WeaponLicenseConfig.ItemName, 1, item.metadata, licenseSlot)
    
    MySQL.Async.execute('DELETE FROM user_licenses WHERE owner = ? AND type = ?', {
        targetPlayer.identifier,
        WeaponLicenseConfig.LicenseType
    })
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'License Revoked',
        description = 'Weapon license has been revoked',
        type = 'success',
        position = 'top'
    })
    
    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'License Revoked',
        description = 'Your weapon license has been revoked by police',
        type = 'error',
        position = 'top'
    })
    
    TriggerClientEvent('weaponlicense:closeLicenseDisplay', src)
end)