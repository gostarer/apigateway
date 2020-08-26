local _M = {}

function _M.debug_log(msg)
	ngx.log(ngx.DEBUG, msg);
end

function _M.warn_log(msg)
	ngx.log(ngx.WARN, msg);
end

function _M.error_log(msg)
	ngx.log(ngx.ERR, msg);
end

function _M.load_module_if_exists(module_name)
    local status, res = pcall(require, module_name)
    if status then
        return true, res
        -- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
    elseif type(res) == "string" and string_find(res, "module '"..module_name.."' not found", nil, true) then
        return false
    else
        error(res)
    end
end

function _M.get_ip()
	local myIP = ngx.req.get_headers()["X-Real-IP"]
	if myIP == nil then
		myIP = ngx.req.get_headers()["x_forwarded_for"]
	end
	if myIP == nil then
		myIP = ngx.var.remote_addr
	end
	return myIP;
end

--判断table是否为空
function _M.isTableEmpty(t)
    return t == nil or next(t) == nil
end

--两个table合并
function _M.union(table1,table2)
	for k, v in pairs(table2) do
		table1[k] = v
    end
    return table1
end

return _M