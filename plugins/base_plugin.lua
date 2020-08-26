
local utils = require("rainbow.common.utils")
local Object = require("rainbow.lib.classic")

local BasePlugin = Object:extend()

function BasePlugin:new(name)
    self._name = name
	utils.debug_log("BasePlugin executing plugin \""..self._name.."\": new")
end

function BasePlugin:get_name()
    return self._name
end

function BasePlugin:init_worker()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": init_worker")
end

function BasePlugin:redirect()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": redirect")
end

function BasePlugin:rewrite()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": rewrite")
end

function BasePlugin:access()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": access")
end

function BasePlugin:header_filter()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": header_filter")
end

function BasePlugin:body_filter()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": body_filter")
end

function BasePlugin:log()
    utils.debug_log("BasePlugin executing plugin \""..self._name.."\": log")
end

return BasePlugin
