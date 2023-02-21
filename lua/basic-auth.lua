local re_match = ngx.re.match
local re_gmatch = ngx.re.gmatch
local decode_base64 = ngx.decode_base64

local realm = 'Basic realm="OpenResty"'

-- demo user database with username = password
local demo_users = {
  demo = 'dome'
}

local unauthorized = function()
    ngx.header['WWW-Authenticate'] = realm
    ngx.exit(401)
end

local username, password
local authorization_header = ngx.req.get_headers()['Authorization']

if not authorization_header then
    unauthorized()
end

local iterator, iter_err = re_gmatch(authorization_header, "\\s*[Bb]asic\\s*(.+)", "oj")
if not iterator then
  ngx.log(ngx.ERR, iter_err)
  unauthorized()
end

local m, err = iterator()
if not m or not m[1] then
  unauthorized()
end

local decoded_basic = decode_base64(m[1])
if not decoded_basic then
  unauthorized()
end

local basic_parts, err = re_match(decoded_basic, "([^:]+):(.*)", "oj")
if err then
  ngx.log(ngx.ERR, err)
  unauthorized()
end

if not basic_parts then
  ngx.log(ngx.ERR, "header has unrecognized format")
  unauthorized()
end

username = basic_parts[1]
password = basic_parts[2]

if not demo_users[username] or password ~= demo_users[username] then
  unauthorized()
end

