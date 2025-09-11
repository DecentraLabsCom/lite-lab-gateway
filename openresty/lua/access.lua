local jwt = require "resty.jwt"
local dict = ngx.shared.cache

-- Check cookies
local cookies = ngx.var.http_cookie
if not cookies or cookies == "" then
	ngx.log(ngx.INFO, "No cookie found. Proceeding to backend without header for authentication.")
        return
end

-- Extract the JWT's JTI from the cookie
local jti = string.match(cookies, "JTI=([^;]+)")
if not jti or jti == "" then
	ngx.log(ngx.INFO, "No valid cookie found. Proceeding to backend without header for authentication.")
	return
end

-- Check if JTI is in shared dict to validate the cookie
local username = dict:get("username:" .. jti)
if not username then
        ngx.log(ngx.INFO, "JTI in cookie is not valid: " .. jti)
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say("Invalid or expired cookie")
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Set Authorization header with username
ngx.req.set_header("Authorization", username)
ngx.log(ngx.INFO, "Valid cookie. Authorization header set.")
