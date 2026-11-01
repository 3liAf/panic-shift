local parent = game:GetService("ServerScriptService"):WaitForChild("Services")
local s = parent:FindFirstChild("AnalyticsService")
if not s or s.ClassName ~= "ModuleScript" then
    if s then s:Destroy() end
    s = Instance.new("ModuleScript")
    s.Name = "AnalyticsService"
    s.Parent = parent
end
s.Source = "--!strict\n--[[\n    PANIC SHIFT: AnalyticsService.lua\n    Server-side telemetry and event logging for gameplay funnels,\n    retention indicators, and balancing metrics.\n]]\n\nlocal AnalyticsService = {\n    Name = \"AnalyticsService\",\n}\n\nlocal services: { [string]: any } = {}\nlocal eventLog: { { Timestamp: number, Event: string, Params: { [string]: any } } } = {}\n\nfunction AnalyticsService:Init(serviceRegistry: { [string]: any })\n    services = serviceRegistry\nend\n\nfunction AnalyticsService:Start()\n    print(\"[PanicShift AnalyticsService] Initialized telemetry pipeline.\")\nend\n\n-- Records a structured telemetry event\nfunction AnalyticsService:LogEvent(eventName: string, params: { [string]: any }): ()\n    local entry = {\n        Timestamp = os.time(),\n        Event = eventName,\n        Params = params or {},\n    }\n\n    table.insert(eventLog, entry)\n    \n    -- Print structured telemetry for development/debugging\n    local details = \"\"\n    for k, v in pairs(entry.Params) do\n        details = details .. string.format(\" %s=%s\", tostring(k), tostring(v))\n    end\n    print(string.format(\"[Telemetry] %s:%s\", eventName, details))\n\n    -- Keep memory footprint capped\n    if #eventLog > 500 then\n        table.remove(eventLog, 1)\n    end\nend\n\nreturn AnalyticsService\n"
return { success = true, name = "AnalyticsService", bytes = #s.Source }
