-- well, we could put the require() and new() calls in our own Lua
-- modules to save overhead. here we put them below just for
-- convenience.

local limit_conn = require "resty.limit.conn"
local ctx = ngx.ctx

-- limit the requests under 200 concurrent requests (normally just
-- incoming connections unless protocols like SPDY is used) with
-- a burst of 100 extra concurrent requests, that is, we delay
-- requests under 300 concurrent connections and above 200
-- connections, and reject any new requests exceeding 300
-- connections.
-- also, we assume a default request time of 0.5 sec, which can be
-- dynamically adjusted by the leaving() call in log_by_lua below.
local lim, err = limit_conn.new("limit_conn_store", 20, 10, 1)
if not lim then
  ngx.log(ngx.ERR,
    "failed to instantiate a resty.limit.conn object: ", err)
  return ngx.exit(500)
end

-- the following call must be per-request.
-- here we use the remote (IP) address as the limiting key
local key = ngx.var.binary_remote_addr
local delay, err = lim:incoming(key, true)
if not delay then
  if err == "rejected" then
    return ngx.exit(503)
  end
  ngx.log(ngx.ERR, "failed to limit req: ", err)
  return ngx.exit(500)
end

if lim:is_committed() then
  ctx.limit_conn = lim
  ctx.limit_conn_key = key
  ctx.limit_conn_delay = delay
end

-- the 2nd return value holds the current concurrency level
-- for the specified key.
local conn = err

if delay >= 0.001 then
  -- the request exceeding the 200 connections ratio but below
  -- 300 connections, so
  -- we intentionally delay it here a bit to conform to the
  -- 200 connection limit.
  -- ngx.log(ngx.WARN, "delaying")
  ngx.sleep(delay)
end

