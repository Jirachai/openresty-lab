local ctx = ngx.ctx
local lim = ctx.limit_conn
if lim then
  local latency = tonumber(ngx.var.request_time) - ctx.limit_conn_delay
  local key = ctx.limit_conn_key
  assert(key)
  local conn, err = lim:leaving(key, latency)
  if not conn then
    ngx.log(ngx.ERR,
      "failed to record the connection leaving ",
      "request: ", err)
    return
  end
end

