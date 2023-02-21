local limit_req = require "resty.limit.req"

-- limit the requests under 20 req/sec with a burst of 10 req/sec,
-- that is, we delay requests under 30 req/sec and above 20
-- req/sec, and reject any requests exceeding 30 req/sec.

local lim, err = limit_req.new("limit_req_store", 2, 1)
if not lim then
  ngx.log(ngx.ERR,
    "failed to instantiate a resty.limit.req object: ", err)
  return ngx.exit(500)
end

-- the following call must be per-request.
-- here we use the remote (IP) address as the limiting key
local key = ngx.var.binary_remote_addr -- IP address
local delay, err = lim:incoming(key, true)
if not delay then
  if err == "rejected" then
    return ngx.exit(429)
  end
  ngx.log(ngx.ERR, "failed to limit req: ", err)
  return ngx.exit(500)
end

if delay >= 0.001 then
  -- the 2nd return value holds  the number of excess requests
  -- per second for the specified key. for example, number 31
  -- means the current request rate is at 231 req/sec for the
  -- specified key.
  local excess = err

  -- the request exceeding the 200 req/sec but below 300 req/sec,
  -- so we intentionally delay it here a bit to conform to the
  -- 200 req/sec rate.
  ngx.sleep(delay)
end

