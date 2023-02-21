local method = ngx.req.get_method()

if method ~= 'PURGE' then
  return
end

local md5 = ngx.md5
local unescape_uri = ngx.unescape_uri
local key = ngx.var.escaped_key

if not key then
  return
end

local redis = require "resty.redis"
local red, err = redis:new()

if not red then
  ngx.log(ngx.ERR, "Failed to create redis variable, error -> ", err)
  return
end

assert(red:connect("redis", 6379))
if not red then
  ngx.log(ngx.ERR, "Failed to connect to redis, error -> ", err)
  return
end

key = md5(unescape_uri(key))

local ok, err = assert(red:del(key))
assert(red:set_keepalive(10000, 100))

if not ok then
  ngx.log(ngx.ERR, "Failed to delete redis key, error -> ", err)
  return
end

ngx.exit(204)
