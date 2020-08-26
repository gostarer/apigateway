
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

--检验请求的sign签名是否正确
--params:传入的参数值组成的table
--secret:项目secret，根据appid找到secret
local function signcheck(params,secret)
	--判断参数是否为空，为空报异常
	if utils.isTableEmpty(params) then
		local mess="params table is empty"
        utils.error_log(mess)
        return false,mess
	end
	
	--判断是否有签名参数
	local sign = params["sign"]
	if sign == nil then
		local mess="params sign is nil"
        utils.error_log(mess)
        return false,mess
	end
	
	--是否存在时间戳的参数
	local timestamp = params["time"]
	if timestamp == nil then
		local mess="params timestamp is nil"
        utils.error_log(mess)
        return false,mess
	end
	--时间戳有没有过期，10秒过期
	local now_mill = ngx.now() * 1000 --毫秒级
	if now_mill - timestamp > 10000 then
		local mess="params timestamp is 过期"
        utils.error_log(mess)
        return false,mess
	end
	
	local keys, tmp = {}, {}

    --提出所有的键名并按字符顺序排序
    for k, _ in pairs(params) do 
		if k ~= "sign" then --去除掉
			keys[#keys+1]= k
		end
    end
	table.sort(keys)
	--根据排序好的键名依次读取值并拼接字符串成key=value&key=value
    for _, k in pairs(keys) do
        if type(params[k]) == "string" or type(params[k]) == "number" then 
            tmp[#tmp+1] = k .. "=" .. tostring(params[k])
        end
    end
	--将salt添加到最后，计算正确的签名sign值并与传入的sign签名对比，
    local signchar = table.concat(tmp, "&") .."&"..secret
    local rightsign = ngx.md5(signchar);
	if sign ~= rightsign then
        --如果签名错误返回错误信息并记录日志，
        local mess="sign error: sign,"..sign .. " right sign:" ..rightsign.. " sign_char:" .. signchar
        utils.error_log(mess)
        return false,mess
    end
    return true
end

local BasePlugin = require("rainbow.plugins.base_plugin")

local SignAuthHandler = BasePlugin:extend()
SignAuthHandler.PRIORITY = 0

function SignAuthHandler:new()
    SignAuthHandler.super.new(self, "sign_auth-plugin")
    utils.debug_log("===========SignAuthHandler.new============");
end

function SignAuthHandler:access()
    SignAuthHandler.super.access(self)
	utils.debug_log("===========SignAuthHandler.access============");
	local params = {}

	local get_args = ngx.req.get_uri_args();
	
	local appid = get_args["appid"];
	
	if appid == nil then
		ngx.say("appid is empty,非法请求");
		return ngx.exit(ngx.HTTP_FORBIDDEN) --直接返回403
	end
	
	ngx.req.read_body()
	local post_args = ngx.req.get_post_args();

	utils.union(params,get_args)
	params = utils.union(params,post_args)
	
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
	
	--得到此appid对应的secret
	local resp, err = red:hget("apphash",appid)
	if not resp or (resp == ngx.null) then  
		close_redis(red)
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR) --redis 获取值失败
	end 
	--resp存放着就是appid对应的secret		
	local checkResult,mess = signcheck(params,resp)

	if not checkResult then
		ngx.say(mess);
		return ngx.exit(ngx.HTTP_FORBIDDEN) --直接返回403
	end
end

return SignAuthHandler;