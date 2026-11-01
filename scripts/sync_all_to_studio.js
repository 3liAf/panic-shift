const fs = require('fs');
const path = require('path');

function getScriptType(filePath) {
    if (filePath.endsWith('.server.lua')) return 'Script';
    if (filePath.endsWith('.client.lua')) return 'LocalScript';
    return 'ModuleScript';
}

function getCleanName(fileName) {
    return fileName.replace(/\.server\.lua$/, '').replace(/\.client\.lua$/, '').replace(/\.lua$/, '');
}

const items = [
    // Shared
    { parent: 'game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")', file: 'src/ReplicatedStorage/Shared/Config.lua' },
    { parent: 'game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")', file: 'src/ReplicatedStorage/Shared/Constants.lua' },
    { parent: 'game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")', file: 'src/ReplicatedStorage/Shared/Types.lua' },
    { parent: 'game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")', file: 'src/ReplicatedStorage/Shared/Utility.lua' },
    { parent: 'game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")', file: 'src/ReplicatedStorage/Shared/Network.lua' },

    // Services
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/DisasterService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/EconomyService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/PurchaseService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/TaskService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/RoundService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/DataService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/InventoryService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/ChallengeService.lua' },
    { parent: 'game:GetService("ServerScriptService"):WaitForChild("Services")', file: 'src/ServerScriptService/Services/AnalyticsService.lua' },

    // Controllers
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/UIBuilder.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/EffectsController.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/InteractionController.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Controllers")', file: 'src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua' },

    // Bootstraps
    { parent: 'game:GetService("ServerScriptService")', file: 'src/ServerScriptService/Bootstrap.server.lua' },
    { parent: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")', file: 'src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua' },
];

const outDir = path.join(__dirname, 'sync_payloads');
fs.mkdirSync(outDir, { recursive: true });

for (const item of items) {
    const filePath = path.join(__dirname, '..', item.file);
    const source = fs.readFileSync(filePath, 'utf8');
    const fileName = path.basename(item.file);
    const name = getCleanName(fileName);
    const className = getScriptType(fileName);

    const lua = `local parent = ${item.parent}
local s = parent:FindFirstChild(${JSON.stringify(name)})
if not s or s.ClassName ~= ${JSON.stringify(className)} then
    if s then s:Destroy() end
    s = Instance.new(${JSON.stringify(className)})
    s.Name = ${JSON.stringify(name)}
    s.Parent = parent
end
s.Source = ${JSON.stringify(source)}
return { success = true, name = ${JSON.stringify(name)}, bytes = #s.Source }
`;

    fs.writeFileSync(path.join(outDir, `${name}.lua`), lua);
    console.log(`Generated sync_payloads/${name}.lua (${lua.length} bytes)`);
}
