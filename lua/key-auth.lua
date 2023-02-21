local unauthorized = function()
    ngx.exit(401)
end

local demo_apikeys = {
  ['demo'] = true,
  ['test'] = true,
  ['secretapikey'] = true
}
local apikey = ngx.req.get_headers()['apikey']
if not apikey then
  unauthorized()
end

if not demo_apikeys[apikey] then
  unauthorized()
end
