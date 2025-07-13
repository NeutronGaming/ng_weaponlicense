ESX = exports["es_extended"]:getSharedObject()
local currentApplications = {}
local examInProgress = false
local currentQuestionIndex = 1
local examAnswers = {}
local examQuestions = {}
local replacementNPC = nil
local currentLicenseDisplay = nil


-- Initialize targets when resource starts
Citizen.CreateThread(function()
    spawnReplacementNPC()
    
    for _, location in pairs(WeaponLicenseConfig.ApplicationLocations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = location.size,
            rotation = location.rotation,
            debug = location.debug,
            options = {
                {
                    name = 'weapon_license_application',
                    icon = 'fas fa-clipboard',
                    label = 'Submit Weapon License Application',
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:checkApplicationEligibility')
                    end
                },
                {
                    name = 'weapon_license_police',
                    icon = 'fas fa-clipboard',
                    label = 'Review Applications (Police)',
                    groups = WeaponLicenseConfig.PoliceJobs,
                    canInteract = function()
                        if not WeaponLicenseConfig.RankRequirements.enabled then
                            return true
                        end
                        
                        local playerData = ESX.GetPlayerData()
                        if not playerData or not playerData.job then return false end
                        
                        local requiredGrade = WeaponLicenseConfig.RankRequirements.applications[playerData.job.name]
                        if requiredGrade and playerData.job.grade >= requiredGrade then
                            return true
                        end
                        return false
                    end,
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:getApplications')
                    end
                }
            }
        })
    end
    
    for _, location in pairs(WeaponLicenseConfig.RecordsLocations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = location.size,
            rotation = location.rotation,
            debug = location.debug,
            options = {
                {
                    name = 'weapon_license_records',
                    icon = 'fas fa-folder-open',
                    label = 'Weapon License Records (Police)',
                    groups = WeaponLicenseConfig.PoliceJobs,
                    canInteract = function()
                        if not WeaponLicenseConfig.RankRequirements.enabled then
                            return true
                        end
                        
                        local playerData = ESX.GetPlayerData()
                        if not playerData or not playerData.job then return false end
                        
                        local requiredGrade = WeaponLicenseConfig.RankRequirements.records[playerData.job.name]
                        if requiredGrade and playerData.job.grade >= requiredGrade then
                            return true
                        end
                        return false
                    end,
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:getLicenseRecords')
                    end
                }
            }
        })
    end
    
    for _, location in pairs(WeaponLicenseConfig.ExamLocations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = location.size,
            rotation = location.rotation,
            debug = location.debug,
            options = {
                {
                    name = 'weapon_license_exam',
                    icon = 'fas fa-clipboard-check',
                    label = 'Take Weapon License Exam',
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:checkExamEligibility')
                    end
                }
            }
        })
    end
end)

-- Open application menu
function openApplicationMenu()
    TriggerServerEvent('weaponlicense:checkApplicationEligibility')
end

-- Show applications to police
RegisterNetEvent('weaponlicense:showApplications')
AddEventHandler('weaponlicense:showApplications', function(applications)
    currentApplications = applications
    
    if #applications == 0 then
        lib.notify({
            title = 'No Applications',
            description = 'There are no pending applications',
            type = 'info',
            position = 'top'
        })
        return
    end
    
    local options = {}
    
    for _, app in pairs(applications) do
        local genderDisplay = "Unknown"
        if app.gender then
            if string.lower(app.gender) == "m" then
                genderDisplay = "Male"
            elseif string.lower(app.gender) == "f" then
                genderDisplay = "Female"
            else
                genderDisplay = app.gender
            end
        end

        local titleText = genderDisplay .. " | " .. app.firstname .. " " .. app.lastname
        
        table.insert(options, {
            title = titleText,
            description = 'DOB: ' .. app.dateofbirth .. ' | Submitted: ' .. (app.formatted_date or 'Unknown'),
            icon = 'user',
            onSelect = function()
                showApplicationActions(app.id, app.firstname .. ' ' .. app.lastname)
            end
        })
    end
    
    lib.registerContext({
        id = 'weapon_license_applications',
        title = 'Weapon License Applications',
        options = options
    })
    
    lib.showContext('weapon_license_applications')
end)

-- Show the actual application form
function showApplicationForm()
    local dialogTitle = 'Weapon License Application'
    if WeaponLicenseConfig.ApplicationCost.enabled then
        dialogTitle = dialogTitle .. ' - Cost: $' .. WeaponLicenseConfig.ApplicationCost.amount
    end
    
    local input = lib.inputDialog(dialogTitle, {
        {
            type = 'input',
            label = 'First Name',
            description = 'Enter your first name',
            required = true,
            max = 50
        },
        {
            type = 'input',
            label = 'Last Name',
            description = 'Enter your last name',
            required = true,
            max = 50
        },
        {
            type = 'input',
            label = 'Date of Birth',
            description = 'Enter your date of birth (MM/DD/YYYY)',
            required = true,
            max = 10
        },
        {
            type = 'input',
            label = 'Discord Username',
            description = 'Enter your Discord username (e.g., username#0000 or username)',
            required = true,
            max = 50
        }
    })
    
    if input then
        local firstname = input[1]
        local lastname = input[2]
        local dob = input[3]
        local discord = input[4]
        
        if firstname and lastname and dob and discord then
            TriggerServerEvent('weaponlicense:submitApplication', firstname, lastname, dob, discord)
        end
    end
end

-- Event to show the application form if eligible
RegisterNetEvent('weaponlicense:showApplicationForm')
AddEventHandler('weaponlicense:showApplicationForm', function()
    showApplicationForm()
end)

function showApplicationActions(applicationId, playerName)
    lib.registerContext({
        id = 'weapon_license_actions',
        title = 'Application: ' .. playerName,
        menu = 'weapon_license_applications',
        options = {
            {
                title = 'Approve Application',
                description = 'Allow this player to take the weapon license exam',
                icon = 'check',
                iconColor = 'green',
                onSelect = function()
                    TriggerServerEvent('weaponlicense:processApplication', applicationId, 'approve')
                end
            },
            {
                title = 'Deny Application',
                description = 'Reject this application',
                icon = 'times',
                iconColor = 'red',
                onSelect = function()
                    TriggerServerEvent('weaponlicense:processApplication', applicationId, 'deny')
                end
            }
        }
    })
    
    lib.showContext('weapon_license_actions')
end

-- Refresh applications
RegisterNetEvent('weaponlicense:refreshApplications')
AddEventHandler('weaponlicense:refreshApplications', function()
    lib.hideContext()
end)

-- Start exam
RegisterNetEvent('weaponlicense:startExam')
AddEventHandler('weaponlicense:startExam', function()
    if examInProgress then return end
    examQuestions = {}
    local allQuestions = {}
    
    for i, question in pairs(WeaponLicenseConfig.ExamQuestions) do
        table.insert(allQuestions, question)
    end
    
    for i = #allQuestions, 2, -1 do
        local j = math.random(i)
        allQuestions[i], allQuestions[j] = allQuestions[j], allQuestions[i]
    end
    
    for i = 1, WeaponLicenseConfig.ExamSettings.totalQuestions do
        if allQuestions[i] then
            table.insert(examQuestions, allQuestions[i])
        end
    end
    
    examInProgress = true
    currentQuestionIndex = 1
    examAnswers = {}
    
    showExamQuestion()
end)

-- Show exam question
function showExamQuestion()
    if currentQuestionIndex > #examQuestions then
        finishExam()
        return
    end
    
    local question = examQuestions[currentQuestionIndex]
    
    local selectOptions = {}
    for letter, answer in pairs(question.answers) do
        table.insert(selectOptions, {
            value = letter,
            label = letter .. ") " .. answer
        })
    end
    
    local isMultiple = string.find(question.correct, ',')
    local description = isMultiple and 'Choose the best answer (multiple answers may be correct)' or 'Choose the correct answer'
    
    local input = lib.inputDialog('Weapon License Exam - Question ' .. currentQuestionIndex .. '/' .. #examQuestions, {
        {
            type = 'select',
            label = question.question,
            description = description,
            required = true,
            options = selectOptions
        }
    })
    
    if input and input[1] then
        examAnswers[currentQuestionIndex] = input[1]
        currentQuestionIndex = currentQuestionIndex + 1
        
        Citizen.Wait(500)
        showExamQuestion()
    else
        examInProgress = false
        lib.notify({
            title = 'Exam Cancelled',
            description = 'You cancelled the exam',
            type = 'error',
            position = 'top'
        })
    end
end

-- Finish exam and calculate score
function finishExam()
    local score = 0
    
    for i, question in pairs(examQuestions) do
        local userAnswer = examAnswers[i]
        local correctAnswer = question.correct
        
        if string.find(correctAnswer, ',') then
            local correctAnswers = {}
            for answer in string.gmatch(correctAnswer, '([^,]+)') do
                correctAnswers[string.gsub(answer, '%s+', '')] = true
            end
            
            if correctAnswers[userAnswer] then
                score = score + 1
            end
        else
            if userAnswer == correctAnswer then
                score = score + 1
            end
        end
    end
    
    examInProgress = false
    
    TriggerServerEvent('weaponlicense:submitExamResults', score, #examQuestions)
end

RegisterNetEvent('weaponlicense:examResults')
AddEventHandler('weaponlicense:examResults', function(passed, score, totalQuestions, requiredScore)
    if passed then
        lib.notify({
            title = 'Exam Passed!',
            description = 'Congratulations! You scored ' .. score .. '/' .. totalQuestions .. ' and have been awarded a weapon license',
            type = 'success',
            duration = 8000,
            position = 'top'
        })
    else
        lib.notify({
            title = 'Exam Failed',
            description = 'You scored ' .. score .. '/' .. totalQuestions .. '. You need at least ' .. requiredScore .. ' correct answers to pass',
            type = 'error',
            duration = 8000,
            position = 'top'
        })
    end
end)

-- Show license records to police
RegisterNetEvent('weaponlicense:showLicenseRecords')
AddEventHandler('weaponlicense:showLicenseRecords', function(records)
    if #records == 0 then
        lib.notify({
            title = 'No Records',
            description = 'There are no weapon license records',
            type = 'info',
            position = 'top'
        })
        return
    end
    
    local options = {}
    
    for _, record in pairs(records) do
        local genderDisplay = "Unknown"
        if record.gender then
            if string.lower(record.gender) == "m" then
                genderDisplay = "Male"
            elseif string.lower(record.gender) == "f" then
                genderDisplay = "Female"
            else
                genderDisplay = record.gender
            end
        end
        
        local titleText = genderDisplay .. " | " .. (record.firstname or "Unknown") .. " " .. (record.lastname or "Unknown")
        
        local description = 'DOB: ' .. (record.dateofbirth or 'Unknown')
        if record.discord then
            description = description .. ' | Discord: ' .. record.discord
        end
        if record.issued_date then
            description = description .. ' | Issued: ' .. record.issued_date
        end
        
        if record.is_banned and record.is_banned == 1 then
            description = description .. ' | STATUS: BANNED'
        else
            description = description .. ' | STATUS: ACTIVE'
        end
        
        table.insert(options, {
            title = titleText,
            description = description,
            icon = record.is_banned and record.is_banned == 1 and 'ban' or 'id-card',
            iconColor = record.is_banned and record.is_banned == 1 and 'red' or 'green',
            onSelect = function()
                showLicenseRecordActions(record)
            end
        })
    end
    
    lib.registerContext({
        id = 'weapon_license_records',
        title = 'Weapon License Records',
        options = options
    })
    
    lib.showContext('weapon_license_records')
end)

-- Show license record actions
function showLicenseRecordActions(record)
    local playerName = (record.firstname or "Unknown") .. " " .. (record.lastname or "Unknown")
    local isBanned = record.is_banned and record.is_banned == 1
    
    local options = {}
    
    if not isBanned then
        table.insert(options, {
            title = 'Revoke License',
            description = 'Remove this player\'s weapon license',
            icon = 'times-circle',
            iconColor = 'red',
            onSelect = function()
                TriggerServerEvent('weaponlicense:revokeLicense', record.identifier)
            end
        })
    end
    
    if isBanned then
        table.insert(options, {
            title = 'Unban from Applications',
            description = 'Allow this player to apply for licenses again',
            icon = 'check-circle',
            iconColor = 'green',
            onSelect = function()
                TriggerServerEvent('weaponlicense:unbanPlayer', record.identifier)
            end
        })
    else
        table.insert(options, {
            title = 'Ban from Applications',
            description = 'Prevent this player from applying for licenses and revoke current license',
            icon = 'ban',
            iconColor = 'red',
            onSelect = function()
                TriggerServerEvent('weaponlicense:banPlayer', record.identifier)
            end
        })
    end
    
    lib.registerContext({
        id = 'weapon_license_record_actions',
        title = 'License Record: ' .. playerName,
        menu = 'weapon_license_records',
        options = options
    })
    
    lib.showContext('weapon_license_record_actions')
end

-- Refresh records
RegisterNetEvent('weaponlicense:refreshRecords')
AddEventHandler('weaponlicense:refreshRecords', function()
    lib.hideContext()
end)

-- Spawn replacement NPC
function spawnReplacementNPC()
    local npcConfig = WeaponLicenseConfig.ReplacementNPC
    
    RequestModel(npcConfig.model)
    while not HasModelLoaded(npcConfig.model) do
        Wait(1)
    end
    
    replacementNPC = CreatePed(4, npcConfig.model, npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z - 1.0, npcConfig.coords.w, false, true)
    
    SetEntityHeading(replacementNPC, npcConfig.coords.w)
    FreezeEntityPosition(replacementNPC, true)
    SetEntityInvincible(replacementNPC, true)
    SetBlockingOfNonTemporaryEvents(replacementNPC, true)
    
    exports.ox_target:addLocalEntity(replacementNPC, {
        {
            name = 'weapon_license_replacement',
            icon = 'fas fa-id-card',
            label = 'Replacement Weapon License',
            canInteract = function()
                return checkReplacementEligibility()
            end,
            onSelect = function()
                TriggerServerEvent('weaponlicense:checkReplacementEligibility')
            end
        }
    })
end

-- Check if player is eligible for replacement (client-side check for target visibility)
function checkReplacementEligibility()
    local playerData = ESX.GetPlayerData()
    if not playerData then return false end
    return true
end

-- Show replacement menu
RegisterNetEvent('weaponlicense:showReplacementMenu')
AddEventHandler('weaponlicense:showReplacementMenu', function(playerData)
    local costText = ""
    if WeaponLicenseConfig.ReplacementCost.enabled then
        costText = " (Cost: $" .. WeaponLicenseConfig.ReplacementCost.amount .. ")"
    end
    
    lib.registerContext({
        id = 'weapon_license_replacement',
        title = 'License Replacement',
        options = {
            {
                title = 'Purchase Replacement License',
                description = 'Get a replacement weapon license' .. costText,
                icon = 'id-card',
                onSelect = function()
                    TriggerServerEvent('weaponlicense:purchaseReplacement', playerData)
                end
            }
        }
    })
    
    lib.showContext('weapon_license_replacement')
end)

-- Export function for using weapon license item
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

-- Display license to target player
RegisterNetEvent('weaponlicense:displayLicense')
AddEventHandler('weaponlicense:displayLicense', function(licenseData, ownerSrc)
    local metadata = licenseData.slot.metadata or {}
    local playerData = ESX.GetPlayerData()
    local isPolice = false
    
    if playerData and playerData.job then
        for _, job in pairs(WeaponLicenseConfig.PoliceJobs) do
            if playerData.job.name == job then
                isPolice = true
                break
            end
        end
    end
    
    _G.currentLicenseMetadata = metadata
    _G.currentLicenseOwner = ownerSrc
    _G.currentIsPolice = isPolice
    _G.currentLicenseData = licenseData
    _G.licenseMenuShown = false
    TriggerServerEvent('weaponlicense:validateLicenseOwnership', ownerSrc, metadata)
end)

-- Function to create the license menu
function createLicenseMenu(metadata, isPolice, licenseData, ownerSrc, isValid, isVerified)
    local strikesText = (metadata.strikes or 0) .. "/" .. WeaponLicenseConfig.StrikeSystem.maxStrikes
    local nameIcon = 'id-badge'
    local nameColor = nil
    local nameDescription = 'Full legal name'
    local nameDisabled = false
    
    if isVerified then
        if isValid then
            nameIcon = 'check-circle'
            nameColor = 'green'
            nameDescription = 'Full legal name - License verified'
        else
            nameIcon = 'exclamation-triangle'
            nameColor = 'red'
            nameDescription = 'Full legal name - WARNING: License does not belong to holder!'
            nameDisabled = true
        end
    end

    local mainOptions = {
        {
            title = 'License Holder Information',
            description = 'Personal details of the license holder',
            icon = 'user',
            disabled = false
        },
        {
            title = 'Name: ' .. (metadata.firstname or 'Unknown') .. ' ' .. (metadata.lastname or 'Unknown'),
            description = nameDescription,
            icon = nameIcon,
            iconColor = nameColor,
            disabled = nameDisabled
        },
        {
            title = 'Date of Birth: ' .. (metadata.dateofbirth or 'Unknown'),
            description = 'Date of birth',
            icon = 'calendar',
            disabled = true
        },
        {
            title = 'Gender: ' .. (metadata.gender or 'Unknown'),
            description = 'Gender',
            icon = 'venus-mars',
            disabled = true
        },
        {
            title = 'Issue Date: ' .. (metadata.issued_date or 'Unknown'),
            description = 'Date license was issued',
            icon = 'calendar-check',
            disabled = true
        },
        {
            title = 'Strikes: ' .. strikesText,
            description = 'Current strikes on license',
            icon = 'exclamation-triangle',
            iconColor = (metadata.strikes or 0) > 0 and 'red' or 'green',
            disabled = true
        }
    }
    
    if isPolice then
        table.insert(mainOptions, {
            title = 'Police Actions',
            description = 'Available police actions',
            icon = 'shield-alt',
            iconColor = 'blue',
            onSelect = function()
                lib.showContext('weapon_license_actions')
            end
        })
    end
    
    table.insert(mainOptions, {
        title = 'Close License',
        description = 'Close license view',
        icon = 'times',
        onSelect = function()
            lib.hideContext()
        end
    })
    
    lib.registerContext({
        id = 'weapon_license_display',
        title = metadata.license_type or 'Weapon License',
        options = mainOptions
    })
    
    if isPolice then
        lib.registerContext({
            id = 'weapon_license_actions',
            title = 'Police Actions',
            menu = 'weapon_license_display',
            options = {
                {
                    title = 'Add Strike',
                    description = 'Add a strike to this license',
                    icon = 'exclamation-triangle',
                    iconColor = 'orange',
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:addStrike', ownerSrc, licenseData.slot.slot)
                        lib.hideContext()
                    end
                },
                {
                    title = 'Revoke License',
                    description = 'Revoke this weapon license',
                    icon = 'times-circle',
                    iconColor = 'red',
                    onSelect = function()
                        TriggerServerEvent('weaponlicense:revokeLicenseInspection', ownerSrc, licenseData.slot.slot)
                        lib.hideContext()
                    end
                },
                {
                    title = 'Back',
                    description = 'Return to license view',
                    icon = 'arrow-left',
                    onSelect = function()
                        lib.showContext('weapon_license_display')
                    end
                }
            }
        })
    end
    
    if not _G.licenseMenuShown then
        _G.licenseMenuShown = true
        lib.showContext('weapon_license_display')
    end
end

-- Handle license ownership validation result
RegisterNetEvent('weaponlicense:updateLicenseOwnership')
AddEventHandler('weaponlicense:updateLicenseOwnership', function(isValid)
    if not _G.currentLicenseMetadata then return end
    
    createLicenseMenu(
        _G.currentLicenseMetadata, 
        _G.currentIsPolice, 
        _G.currentLicenseData, 
        _G.currentLicenseOwner, 
        isValid, 
        true
    )
end)

-- Refresh license display after strike is added
RegisterNetEvent('weaponlicense:refreshLicenseDisplay')
AddEventHandler('weaponlicense:refreshLicenseDisplay', function(licenseData, ownerSrc)
    lib.hideContext()
    Citizen.Wait(100)
    TriggerEvent('weaponlicense:displayLicense', licenseData, ownerSrc)
end)

-- Close license display
RegisterNetEvent('weaponlicense:closeLicenseDisplay')
AddEventHandler('weaponlicense:closeLicenseDisplay', function()
    lib.hideContext()
end)

-- Handle exam timeout
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if examInProgress then
            -- You can add a timer here if needed
            -- For now, we'll let the exam run without a strict time limit
            -- But you could implement a countdown timer
        end
    end
end)


-- Clean up NPC on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if replacementNPC then
            DeleteEntity(replacementNPC)
        end
    end
end)


-- Export the function for ox_inventory
exports('useWeaponLicense', useWeaponLicense)