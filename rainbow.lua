
local utils = require("rainbow.common.utils")
local config_loader = require("rainbow.common.config_loader")

local function load_node_plugins(config)
	utils.debug_log("===========load_node_plugins============");
	local plugins = config.plugins --插件列表
	local sorted_plugins = {} --按照优先级的插件集合
	for _, v in ipairs(plugins) do
		local loaded, plugin_handler = utils.load_module_if_exists("rainbow.plugins." .. v .. ".handler")
		if not loaded then
            utils.warn_log("The following plugin is not installed or has no handler: " .. v)
        else
            utils.debug_log("Loading plugin: " .. v)
            table.insert(sorted_plugins, {
                name = v,
                handler = plugin_handler(), --插件
            })
        end
	end
	--表按照优先级排序
	table.sort(sorted_plugins, function(a, b)
        local priority_a = a.handler.PRIORITY or 0
        local priority_b = b.handler.PRIORITY or 0
        return priority_a > priority_b
    end)
	
	return sorted_plugins
end


local rainbow = {}
local loaded_plugins = {}

--根据配置文件初始化
function rainbow.init(options)
	options = options or {}
	local config
	local status, err = pcall(function()
		--rainbow的配置文件路径
        local conf_file_path = options.config
        config = config_loader.load(conf_file_path)
		--加载配置的插件
        loaded_plugins = load_node_plugins(config)
    end)
	
	if not status or err then
        utils.error_log("Startup error: " .. err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)  
    end
	
	utils.debug_log("===========rainbow.init============");
end

function rainbow.init_worker()
	utils.debug_log("===========rainbow.init_worker============");
end

function rainbow.redirect()
	utils.debug_log("===========rainbow.redirect============");
end

function rainbow.rewrite()
	utils.debug_log("===========rainbow.rewrite============");
end

function rainbow.access()
	utils.debug_log("===========rainbow.access============");
	for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:access()
    end
end

function rainbow.header_filter()
	utils.debug_log("===========rainbow.header_filter============");
end

function rainbow.body_filter()
	utils.debug_log("===========rainbow.body_filter============");
end

function rainbow.log()
	utils.debug_log("===========rainbow.log============");
end

return rainbow;









