local scene = {}
scene.state = {}
function scene:__exit()
    if self.state.onExit then self.state:onExit() end
end

function scene:__load()
    if self.onLoad then self:onLoad() end
end

function scene:setScene(s)
    self:__exit()
    if self.current then
        package.loaded[self.current] = nil
        self.current = nil
    end
    self.state = nil
    collectgarbage("collect")
    self.state = require(s)
    self.current = s
    self:__load()
end

function scene:reload()
    self:__exit()
    if self.current then
        package.loaded[self.current] = nil
    end
    self.state = nil
    collectgarbage("collect")
    self.state = require(self.current)
    self:__load()
end

local mt = {
    __index = function(table, key)
        if table.state[key] then return table.state[key] end
    end
}
setmetatable(scene, mt)
return scene
