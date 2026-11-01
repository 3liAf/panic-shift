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

const header = `
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

const batches = [
    {
        name: 'batch1_shared',
        parentExpr: 'getOrCreateFolder(game:GetService("ReplicatedStorage"), "PanicShiftShared")',
        dir: 'src/ReplicatedStorage/Shared'
    },
    {
        name: 'batch2_disasters',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerStorage"), "DisasterModules")',
        dir: 'src/ServerStorage/DisasterModules'
    },
    {
        name: 'batch3_services',
        parentExpr: 'getOrCreateFolder(game:GetService("ServerScriptService"), "Services")',
        dir: 'src/ServerScriptService/Services'
    },
    {
        name: 'batch4_controllers',
        parentExpr: 'getOrCreateFolder(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Controllers")',
        dir: 'src/StarterPlayer/StarterPlayerScripts/Controllers'
    },
    {
        name: 'batch5_bootstraps',
        custom: true
    }
];

for (const b of batches) {
    let lua = header;
    if (b.dir) {
        const fullDir = path.join(__dirname, '..', b.dir);
        const files = fs.readdirSync(fullDir);
        for (const f of files) {
            if (!f.endsWith('.lua')) continue;
            const source = fs.readFileSync(path.join(fullDir, f), 'utf8');
            lua += `\nsetScript(${b.parentExpr}, ${escapeLuaString(getCleanName(f))}, ${escapeLuaString(getScriptType(f))}, ${escapeLuaString(source)})`;
        }
    } else if (b.name === 'batch5_bootstraps') {
        const sBootstrap = fs.readFileSync(path.join(__dirname, '../src/ServerScriptService/Bootstrap.server.lua'), 'utf8');
        lua += `\nsetScript(game:GetService("ServerScriptService"), "Bootstrap", "Script", ${escapeLuaString(sBootstrap)})`;
        const mapBuilder = fs.readFileSync(path.join(__dirname, '../src/ServerScriptService/MapBuilder.lua'), 'utf8');
        lua += `\nsetScript(game:GetService("ServerScriptService"), "MapBuilder", "ModuleScript", ${escapeLuaString(mapBuilder)})`;
        const cBootstrap = fs.readFileSync(path.join(__dirname, '../src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua'), 'utf8');
        lua += `\nsetScript(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "ClientBootstrap", "LocalScript", ${escapeLuaString(cBootstrap)})`;
    }
    lua += `\nreturn { batch = "${b.name}", count = 5, success = true }`;
    const outPath = path.join(__dirname, `${b.name}.lua`);
    fs.writeFileSync(outPath, lua);
    console.log(`Wrote ${b.name}.lua (${lua.length} bytes)`);
}
