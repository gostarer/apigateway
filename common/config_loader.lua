local json = require("rainbow.common.json")
local IO = require("rainbow.common.io")

local _M = {}

function _M.load(config_path)
    config_path = config_path or "/etc/rainbow/rainbow.conf"
    local config_contents = IO.read_file(config_path)

    if not config_contents then
        ngx.log(ngx.ERR, "No configuration file at: ", config_path)
        os.exit(1)
    end

    local config = json.decode(config_contents)
    return config, config_path
end

return _M
