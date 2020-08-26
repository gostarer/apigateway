--限流，可以控制每个客户端的访问频次
local utils = require("rainbow.common.utils")
local redis = require "resty.redis"  --引入redis模块

local function close_redis(red)  
    if not red then  
        return
    end  
    --释放连接(连接池实现)  
    local pool_max_idle_time = 10000 --毫秒  
    local pool_size = 100 --连接池大小  
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)  
    if not ok then  
        utils.error_log("set keepalive error : "..err)  
    end  
end

local BasePlugin = require("rainbow.plugins.base_plugin")

local LimitFrequencyHandler = BasePlugin:extend()
LimitFrequencyHandler.PRIORITY = 1 --优先级

function LimitFrequencyHandler:new()
    LimitFrequencyHandler.super.new(self, "limit_frequency-plugin")
    utils.debug_log("===========LimitFrequencyHandler.new============");
end

function LimitFrequencyHandler:access()
    LimitFrequencyHandler.super.access(self)
	utils.debug_log("===========LimitFrequencyHandler.access============");
	
	local red = redis:new()  --创建一个对象，注意是用冒号调用的

	--设置超时（毫秒）  
	red:set_timeout(1000) 
	--建立连接  
	local host = "192.168.0.100"  
	local port = 6379
	local ok, err = red:connect(host, port)
	if not ok then  
		close_redis(red)
		utils.error_log("Cannot connect");
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)   
	end  

	local key = "limit:frequency:login:"..utils.get_ip();
		
	--得到此客户端IP的频次
	local resp, err = red:get(key)
	if not resp then  
		close_redis(red)
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR) --redis 获取值失败
	end 

	if resp == ngx.null then   
		red:set(key, 1) -- 单位时间 第一次访问
		red:expire(key, 10) --10秒时间 过期
	end  

	if type(resp) == "string" then 
		if tonumber(resp) > 10 then -- 超过10次
			close_redis(red)
			return ngx.exit(ngx.HTTP_FORBIDDEN) --直接返回403
		end
	end

	--调用API设置key  
	ok, err = red:incr(key)  
	if not ok then  
		close_redis(red)
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR) --redis 报错 
	end  

	close_redis(red)  
end

return LimitFrequencyHandler;