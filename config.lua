-- PRECONFIGURED FOR GABZ MRPD

WeaponLicenseConfig = {}


WeaponLicenseConfig.DiscordWebhook = {
    enabled = true, -- Set to false to disable webhook notifications
    url = "https://discord.com/api/webhooks/1393773813472432271/yfu1tw1rYzdQb2LYIf9GrNzZ6k5gSsAsapySxlOk5lARiK7uF2KBGR1J89vUZrxu2fXD", -- Replace with your actual webhook URL
    botName = "Weapon License System",
    color = 3447003 -- Blue color (you can change this to any decimal color code)
}

-- Police rank requirements
WeaponLicenseConfig.RankRequirements = {
    enabled = true, -- Set to false to disable rank requirements
    applications = {
        -- Jobs and their minimum required grades to review applications
        police = 2,    -- Grade 2 and above can review applications
        sheriff = 2,   -- Grade 1 and above can review applications  
        fbi = 2        -- Grade 0 and above can review applications
    },
    records = {
        -- Jobs and their minimum required grades to access license records
        police = 2,    -- Grade 3 and above can access records
        sheriff = 2,   -- Grade 2 and above can access records
        fbi = 2        -- Grade 1 and above can access records
    }
}

-- Target locations for applications
WeaponLicenseConfig.ApplicationLocations = {
    {
        coords = vector3(442.2148, -981.9189, 30.6000), -- Mission Row PD
        size = vector3(0.7, 0.7, 0.7),
        rotation = 45,
        debug = false,
        label = "Weapon License Application"
    }
}

-- Target locations for license records management
WeaponLicenseConfig.RecordsLocations = {
    {
        coords = vector3(446.0097, -996.9143, 30.7000), -- Mission Row PD
        size = vector3(1.0, 1.0, 1.0),
        rotation = 45,
        debug = false,
        label = "Weapon License Records"
    }
}

-- Target locations for taking the exam
WeaponLicenseConfig.ExamLocations = {
    {
        coords = vector3(447.1645, -988.0897, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    },
    {
        coords = vector3(444.8314, -988.0372, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    },
    {
        coords = vector3(442.8742, -987.9954, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    },
    {
        coords = vector3(442.8940, -983.4362, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    },
    {
        coords = vector3(444.9651, -983.3702, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    },
    {
        coords = vector3(447.2507, -983.3260, 35.0000), -- Mission Row PD
        size = vector3(1.5, 1.5, 1.5),
        rotation = 45,
        debug = false,
        label = "Weapon License Exam"
    }
}

-- Police jobs that can approve applications
WeaponLicenseConfig.PoliceJobs = {
    'police',
    'sheriff',
    'fbi'
}

-- Exam settings
WeaponLicenseConfig.ExamSettings = {
    questionsToPass = 15, -- How many questions must be answered correctly
    totalQuestions = 20,  -- Total number of questions in the exam
    timeLimit = 300,      -- Time limit in seconds (5 minutes)
}

-- Inventory item settings
WeaponLicenseConfig.GiveItem = true -- Set to false to disable item giving
WeaponLicenseConfig.ItemName = 'weaponlicense'
WeaponLicenseConfig.ItemLabel = 'Weapon License'

WeaponLicenseConfig.ApplicationCost = {
    enabled = true,  -- Set to false to disable application cost
    amount = 10000     -- Cost in dollars to submit application
}

-- License settings
WeaponLicenseConfig.LicenseType = 'weapon' -- License type to add to player in the database

-- Replacement NPC location
WeaponLicenseConfig.ReplacementNPC = {
    coords = vector4(442.7125, -982.0085, 30.6896, 90.8691), -- Mission Row PD (x, y, z, heading)
    model = 's_m_y_cop_01', -- NPC model
    label = "License Replacement Officer"
}

-- Replacement cost
WeaponLicenseConfig.ReplacementCost = {
    enabled = true,
    amount = 100
}

-- Strike system
WeaponLicenseConfig.StrikeSystem = {
    enabled = true,
    maxStrikes = 3 -- License gets revoked after this many strikes
}

-- Exam questions
WeaponLicenseConfig.ExamQuestions = {
    {
        question = "A person approaches you aggressively but is unarmed. They shove you and threaten to beat you up. When can you legally draw your weapon?",
        answers = {
            A = "Only if they produce a weapon or you reasonably believe they can cause great bodily harm",
            B = "When they make verbal threats",
            C = "Never, since they are unarmed",
            D = "Immediately when they shove you"
        },
        correct = 'A'
    },
    {
        question = "You witness an armed robbery in progress at a store. The robber hasn't seen you. What is the most appropriate action?",
        answers = {
            A = "Immediately engage the robber with your weapon",
            B = "Leave the area immediately",
            C = "Confront the robber verbally to distract them",
            D = "Call police, observe from a safe distance, only intervene if lives are in immediate danger"
        },
        correct = 'D'
    },
    {
        question = "During a traffic stop, when should you inform the officer about your concealed weapon?",
        answers = {
            A = "Immediately upon first contact, with hands visible",
            B = "After they run your license",
            C = "Only if they ask about weapons",
            D = "Never mention it unless they discover it"
        },
        correct = 'A'
    },
    {
        question = "You're legally carrying in a store when an armed robber enters. You have a clear shot but there are civilians behind the target. What should you do?",
        answers = {
            A = "Take the shot anyway to stop the threat",
            B = "Immediately leave the store",
            C = "Wait for a clear shot or find better positioning, prioritizing civilian safety",
            D = "Shout a warning to distract the robber"
        },
        correct = 'C'
    },
    {
        question = "What constitutes 'reasonable fear of imminent death or great bodily harm' for justified use of deadly force?",
        answers = {
            A = "Any time someone threatens you verbally",
            B = "When a reasonable person in your situation would believe death or serious injury is about to occur",
            C = "Whenever you feel scared or uncomfortable",
            D = "When someone is larger than you"
        },
        correct = 'B'
    },
    {
        question = "You accidentally expose your concealed weapon in public (muscle spasm, etc.). What should you do?",
        answers = {
            A = "Immediately cover it and be more careful in the future",
            B = "Nothing, it was accidental",
            C = "Leave the area quickly",
            D = "Announce to everyone that you have a license"
        },
        correct = 'A'
    },
    {
        question = "Someone breaks into your home at night. You hear them downstairs. What is your best course of action?",
        answers = {
            A = "Immediately go downstairs to confront them",
            B = "Shout warnings from upstairs",
            C = "Try to sneak out of the house",
            D = "Call police, secure yourself in a safe room, be prepared to defend if they come to you"
        },
        correct = 'D'
    },
    {
        question = "A licensed weapon holder's responsibilities include all of the following EXCEPT:",
        answers = {
            A = "Maintaining proficiency with their weapon",
            B = "Acting as an auxiliary police officer when needed",
            C = "Understanding local and state laws",
            D = "Avoiding confrontational situations when possible"
        },
        correct = 'B'
    },
    {
        question = "You're in your car when someone approaches aggressively and starts hitting your windows. When can you use deadly force?",
        answers = {
            A = "Only if they have a weapon or you cannot safely drive away",
            B = "When they break the window",
            C = "As soon as they touch your car",
            D = "Never, you should always try to drive away first"
        },
        correct = 'A'
    },
    {
        question = "What is the 'duty to retreat' and how does it apply to concealed carry?",
        answers = {
            A = "You must always run away from any confrontation",
            B = "You never have to retreat if you have a license",
            C = "You must attempt to avoid or escape a threatening situation if safely possible before using deadly force",
            D = "Only applies to police officers"
        },
        correct = 'C'
    },
    {
        question = "A friend asks to borrow your licensed firearm for 'protection' during a drug deal. What should you do?",
        answers = {
            A = "Refuse and report the planned illegal activity to authorities",
            B = "Lend it since they're a friend",
            C = "Go with them to supervise",
            D = "Lend it but remove the ammunition"
        },
        correct = 'A'
    },
    {
        question = "You're carrying concealed at a family gathering where alcohol is being served. What should you do?",
        answers = {
            A = "Drink moderately since you're with family",
            B = "Hide your weapon better so no one knows",
            C = "Only drink beer, not hard liquor",
            D = "Not drink any alcohol while carrying"
        },
        correct = 'D'
    },
    {
        question = "After using your weapon in self-defense, what should be your first priority?",
        answers = {
            A = "Leave the scene immediately",
            B = "Ensure the threat is neutralized, call 911, and wait for ems/pd to arrive",
            C = "Call your lawyer",
            D = "Secure evidence at the scene"
        },
        correct = 'B'
    },
    {
        question = "You're at a public event when someone recognizes you as having a weapon (that is legal) and loudly announces it to everyone nearby. What should you do?",
        answers = {
            A = "Proudly show everyone your weapon and license",
            B = "Deny having a weapon and leave immediately",
            C = "Calmly leave the area to avoid unwanted attention and potential targeting",
            D = "Threaten the person to keep them quiet"
        },
        correct = 'C'
    },
    {
        question = "You're legally carrying when a fight breaks out nearby between strangers. What should you do?",
        answers = {
            A = "Leave the area and call police, only intervene if someone's life is clearly in danger",
            B = "Draw your weapon to intimidate them into stopping",
            C = "Intervene immediately to stop the fight",
            D = "Stay and watch to be a witness"
        },
        correct = 'A'
    },
    {
        question = "Which statement about warning shots is correct?",
        answers = {
            A = "Warning shots are always legal if you have a license",
            B = "Warning shots are recommended before using deadly force",
            C = "Warning shots should be fired into the air",
            D = "Warning shots are generally illegal and dangerous - never fire unless you intend to stop a threat"
        },
        correct = 'D'
    },
    {
        question = "You're carrying a concealed pistol when police respond to an unrelated incident nearby. What should you do?",
        answers = {
            A = "Approach officers and identify yourself as armed",
            B = "Keep your distance, hands visible, follow any commands given",
            C = "Immediately leave the area",
            D = "Hide your weapon temporarily"
        },
        correct = 'B'
    },
    {
        question = "What is the primary difference between 'cover' and 'concealment' in a defensive situation?",
        answers = {
            A = "Cover stops bullets, concealment only hides you from view",
            B = "There is no difference",
            C = "Concealment stops bullets, cover only hides you",
            D = "Cover is for police, concealment is for civilians"
        },
        correct = 'A'
    },
    {
        question = "A person with a knife is 25 feet away and threatening you. They start running toward you. What is the appropriate response?",
        answers = {
            A = "Wait until they get closer to be sure of the threat",
            B = "Try to reason with them while they approach",
            C = "Turn and run immediately",
            D = "Prepare to use deadly force - a knife-wielding attacker can cover 25 feet in about 1.5 seconds"
        },
        correct = 'D'
    },
    {
        question = "What should you do if your concealed weapon license is revoked?",
        answers = {
            A = "Continue carrying since you already paid for the license",
            B = "Immediately surrender all weapons and stop carrying until you can reapply (unless banned) - revocation means you've lost the privilege",
            C = "Only carry unloaded weapons until you can reapply",
            D = "Switch to carrying knives or other weapons instead"
        },
        correct = 'B'
    }
}