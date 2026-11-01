const fs = require('fs');
const path = require('path');

function createSyncScript(parentExpr, name, className, filePath) {
    const source = fs.readFileSync(path.join(__dirname, '..', filePath), 'utf8');
    return `
local function getOrCreateFolder(parent, name)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

local parent = ${parentExpr}
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
}

const items = [
    {
        id: 'TaskService',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")',
        name: 'TaskService',
        className: 'ModuleScript',
        filePath: 'src/ServerScriptService/Services/TaskService.lua'
    },
    {
        id: 'RoundService',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")',
        name: 'RoundService',
        className: 'ModuleScript',
        filePath: 'src/ServerScriptService/Services/RoundService.lua'
    },
    {
        id: 'DisasterService',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")',
        name: 'DisasterService',
        className: 'ModuleScript',
        filePath: 'src/ServerScriptService/Services/DisasterService.lua'
    },
    {
        id: 'DataService',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")',
        name: 'DataService',
        className: 'ModuleScript',
        filePath: 'src/ServerScriptService/Services/DataService.lua'
    },
    {
        id: 'AngryCustomer',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerStorage"), "DisasterModules")',
        name: 'AngryCustomer',
        className: 'ModuleScript',
        filePath: 'src/ServerStorage/DisasterModules/AngryCustomer.lua'
    },
    {
        id: 'ManagerMadness',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerStorage"), "DisasterModules")',
        name: 'ManagerMadness',
        className: 'ModuleScript',
        filePath: 'src/ServerStorage/DisasterModules/ManagerMadness.lua'
    },
    {
        id: 'InteractionController',
        parentExpr: 'getOrCreateFolder(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Controllers")',
        name: 'InteractionController',
        className: 'ModuleScript',
        filePath: 'src/StarterPlayer/StarterPlayerScripts/Controllers/InteractionController.lua'
    },
    {
        id: 'UIBuilder',
        parentExpr: 'getOrCreateFolder(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Controllers")',
        name: 'UIBuilder',
        className: 'ModuleScript',
        filePath: 'src/StarterPlayer/StarterPlayerScripts/Controllers/UIBuilder.lua'
    },
    {
        id: 'UIController',
        parentExpr: 'getOrCreateFolder(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Controllers")',
        name: 'UIController',
        className: 'ModuleScript',
        filePath: 'src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.lua'
    }
];

fs.mkdirSync(path.join(__dirname, 'sync_payloads'), { recursive: true });

for (const item of items) {
    const lua = createSyncScript(item.parentExpr, item.name, item.className, item.filePath);
    fs.writeFileSync(path.join(__dirname, 'sync_payloads', `${item.id}.lua`), lua);
    console.log(`Generated sync_payloads/${item.id}.lua (${lua.length} bytes)`);
}
