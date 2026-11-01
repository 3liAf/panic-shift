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

function escapeLuaString(str) {
    return JSON.stringify(str);
}

// Generate sync scripts for each service/module
const targets = [
    {
        name: 'Shared',
        dir: 'src/ReplicatedStorage/Shared',
        parentExpr: 'getOrCreateFolder(game:GetService("ReplicatedStorage"), "PanicShiftShared")'
    },
    {
        name: 'DisasterModules',
        dir: 'src/ServerStorage/DisasterModules',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerStorage"), "DisasterModules")'
    },
    {
        name: 'Services',
        dir: 'src/ServerScriptService/Services',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")'
    },
    {
        name: 'Controllers',
        dir: 'src/StarterPlayer/StarterPlayerScripts/Controllers',
        parentExpr: 'getOrCreateFolder(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Controllers")'
    }
];

const singleFiles = [
    {
        path: 'src/ServerScriptService/ServerBootstrap.server.lua',
        parentExpr: 'game:GetService("ServerScriptService")'
    },
    {
        path: 'src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua',
        parentExpr: 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")'
    }
];

let lua = `
local function getOrCreateFolder(parent, name)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

local function setScript(parent, name, className, source)
    local s = parent:FindFirstChild(name)
    if not s or s.ClassName ~= className then
        if s then s:Destroy() end
        s = Instance.new(className)
        s.Name = name
        s.Parent = parent
    end
    s.Source = source
    return s
end
`;

for (const target of targets) {
    const fullDir = path.join(__dirname, '..', target.dir);
    if (!fs.existsSync(fullDir)) continue;
    const files = fs.readdirSync(fullDir);
    for (const f of files) {
        if (!f.endsWith('.lua')) continue;
        const filePath = path.join(fullDir, f);
        const source = fs.readFileSync(filePath, 'utf8');
        const className = getScriptType(f);
        const name = getCleanName(f);
        lua += `\nsetScript(${target.parentExpr}, ${escapeLuaString(name)}, ${escapeLuaString(className)}, ${escapeLuaString(source)})`;
    }
}

for (const sf of singleFiles) {
    const filePath = path.join(__dirname, '..', sf.path);
    if (!fs.existsSync(filePath)) continue;
    const f = path.basename(sf.path);
    const source = fs.readFileSync(filePath, 'utf8');
    const className = getScriptType(f);
    const name = getCleanName(f);
    lua += `\nsetScript(${sf.parentExpr}, ${escapeLuaString(name)}, ${escapeLuaString(className)}, ${escapeLuaString(source)})`;
}

lua += `\nreturn { success = true, timestamp = os.time() }`;

fs.writeFileSync(path.join(__dirname, 'studio_sync_payload.lua'), lua);
console.log("Generated studio_sync_payload.lua (" + lua.length + " bytes)");
