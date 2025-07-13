# 🔫 NG Weapon License System #

A comprehensive weapon license management system for FiveM ESX servers with application processing,
exam system, police management tools, and advanced license verification features.

## Disclaimer
Any of my free releases are scripts I have made for my server and decided to distribute for free! I am happy to collaberate with any other creators on upcoming projects as I have many more in the works! Tebex and Discord for support and more free releases coming soon!

## 🛠️ Installation

### 1. Database Setup
The script automatically creates the required database tables (make sure to restart again after ensuring to make sure the database properly inputs):
- `weapon_license_applications` - Pending applications
- `weapon_license_accepted` - Approved applications awaiting exam
- `weapon_license_bans` - Banned players
- `weapon_licenses` - License records with strike tracking

### 2. Item Installation
Add this item to your `ox_inventory/data/items.lua` & the item image to your `ox_inventory/web/images/`

```lua
['weaponlicense'] = {
    label = 'Weapon License',
    weight = 10,
    stack = false,
    close = true,
    description = 'Official weapon license',
    client = {
        export = 'ng_weaponlicense.useWeaponLicense'
    }
}
```

### 3. Configuration
Edit `config.lua` to your liking (all locations and costs are preconfigured to be drag and drop but feel free to change them!)

### 4. File Installation
1. Download and extract the script to your resources folder
2. Add `ensure ng_weaponlicense` to your server.cfg
3. Restart your server




## 📋 Features

### 🎯 Core System
- **Complete Application Process**: Players can submit applications with personal information and Discord username
- **Interactive Exam System**: 20 randomized questions from a pool of realistic scenarios
- **Police Review System**: Officers can approve/deny applications and manage license records
- **License Verification**: Real-time validation to prevent fake licenses
- **Strike System**: Progressive discipline system with automatic revocation
- **Replacement System**: NPC-based license replacement for lost items

### 👮 Police Management
- **Application Review**: View and process pending applications
- **License Records**: Complete database of all license holders
- **Ban System**: Prevent problematic players from reapplying
- **Strike Management**: Add strikes and track violations
- **Instant Revocation**: Remove licenses during inspections
- **Rank-Based Permissions**: Configurable access levels for different police ranks

### 💰 Economic Features
- **Application Fees**: Configurable cost for submitting applications
- **Replacement Fees**: Charge for replacement licenses
- **Automatic Payment**: Handles cash and bank account deductions

### 🔧 Advanced Features
- **Discord Integration**: Webhook notifications for new applications
- **Metadata System**: Rich license information with verification
- **Target System**: ox_target integration for all interactions
- **Multi-Location Support**: Multiple exam and application locations
- **Real-time Updates**: Live refresh of police menus

## 📦 Dependencies

- **ESX Framework** (es_extended)
- **ox_lib** - For UI components and notifications
- **ox_target** - For interaction zones
- **ox_inventory** - For license items and metadata
- **MySQL** - Database operations


## 🎮 Usage

### For Players
1. **Apply**: Visit application locations to submit your application
2. **Wait**: Police review your application
3. **Exam**: Take the weapon license exam once approved
4. **License**: Receive your license item upon passing
5. **Show**: Use the license item to show it to other players
6. **Replace**: Visit the replacement NPC if you lose your license

### For Police
1. **Review Applications**: Access pending applications at designated locations
2. **Manage Records**: View all license holders and their status
3. **Add Strikes**: Discipline license holders during inspections
4. **Revoke Licenses**: Remove licenses immediately when needed
5. **Ban Players**: Prevent problematic players from reapplying

## 🔍 Exam Questions

This system includes 20 preconfigured scenario-based roleplay questions covering:
- Self-defense laws
- Proper weapon handling
- Legal responsibilities
- De-escalation techniques
- Police interaction protocols

Questions are randomized for each exam attempt.

## 🛡️ Security Features

- **License Verification**: Prevents fake or tampered licenses
- **Server-side Validation**: All critical operations validated server-side
- **Rank Checking**: Proper permission validation for police actions
- **Database Integrity**: Comprehensive database structure with proper relationships

## 🐛 Troubleshooting

### Common Issues
1. **Items not working**: Ensure ox_inventory export is properly configured
2. **Database errors**: Check MySQL connection and permissions
3. **Target zones not appearing**: Verify ox_target is running
4. **Notifications not showing**: Confirm ox_lib is properly installed

## 📝 License

Custom - Non-Commercial, No Redistribution, Attribution Required
See LICENSE for full terms.

## 🔄 Updates

I DO NOT WORK ON QBCORE CURRENTLY! I WORK ON ESX FRAMWORK ONLY IF YOU NEED THIS CONVERTED TO QBCORE YOU WILL HAVE TO ASK SOMEONE ELSE TO DO IT FOR YOU. I CANNOT TEST QBCORE PROPERLY AS I DONT HAVE A TEST SERVER SETUP FOR IT YET. In the future on my paid releases I plan to make them for both frameworks! Sorry for any inconvenience!
Any updates will be uploaded to github as I make them. Enjoy!

---

**Made with ❤️ by NeutronGaming for the FiveM community**
