local jwt = require "resty.jwt"
local dict = ngx.shared.cache
--local http = require "resty.http"
--local cjson = require "cjson"

-- Check existing cookies first
local cookies = ngx.var.http_cookie
if cookies then
	local token = string.match(cookies, "JTI=([^;]+)")
	if token then
		ngx.log(ngx.INFO, "Cookie with a token already available. Nothing to do here.")
		return
	end
end

-- Get JWT from URL parameter
local token = ngx.var.arg_jwt
if not token or token == "" then
	ngx.log(ngx.INFO, "No token found in the URL parameters. No cookie to you.")
	return
end

-- Make sure the public key read in init_by_lua is available
local public_key = dict:get("public_key")
if not public_key then
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
	ngx.say("Unable to read public key file")
	return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Get the JWT object and check if it is valid
local jwt_object = jwt:load_jwt(token)
if not jwt_object.valid then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say("Invalid token format: " .. jwt_object.reason)
	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-----------------------------------------------------------------------

-- Read public key from URL with JWKS
--local jwks_url = jwt_object.payload.iss .. "/jwks"

-- HTTP request to get the JWKS
--local httpc = http.new()
--local res, err = httpc:request_uri(jwks_url, {
--	method = "GET",
--	headers = {
--	    ["Accept"] = "application/json"
--	}
--})

--if not res then
--	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
--	ngx.say("Failed to fetch JWKS: " .. err)
--	return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
--end

-- Decode the response's body
--local jwks = cjson.decode(res.body)

-- Get JWT's "kid" to determine which key to use if there is more than one
--local kid = jwt_object.header.kid

-- Get the right key from the JWKS
--local public_key_pem
--for _, key in ipairs(jwks.keys) do
--	if key.kid == kid then
		-- Extract public key in PEM format
--		local n = key.n
--		local e = key.e
		-- Convert to PEM format
--		public_key_pem = "-----BEGIN PUBLIC KEY-----\n" ..
--					ngx.encode_base64(n) ..
--				"\n-----END PUBLIC KEY-----"
--		break
--	end
--end

--if not public_key_pem then
--	ngx.status = ngx.HTTP_UNAUTHORIZED
--	ngx.say("Public key not found in JWKS")
--	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
--end

----------------------------------------------------------------------

-- Verify the JWT with the public key
local jwt_obj = jwt:verify_jwt_obj(public_key, jwt_object)
if not jwt_obj or not jwt_obj.verified then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say("Invalid or expired token")
	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Validate JTI
local jti = jwt_obj.payload.jti
if not jti then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say("JTI is missing")
	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Check whether the JTI is already in shared dict
local username = dict:get("username:" .. jti)
if username then
	ngx.log(ngx.INFO, "JTI already exists in memory: " .. jti)
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say("Token has been used already")
	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Extract the username
local username = string.lower(jwt_obj.payload.sub)
if not username then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say("No username (sub) found in JWT")
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Register the JTI-username pair in shared dict with an expiration time (2 hours)
local ok, err = dict:set("username:" .. jti, username, 7200)
if not ok then
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
	ngx.log(ngx.ERR, "Error when registering JTI in shared dict.")
	return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Register the expiration of the session for this user
local ok, err = dict:set("exp:" .. username, jwt_obj.payload.exp, 7200)
if not ok then
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
	ngx.say(ngx.ERR, "Error when registering expiration time in shared dict.")
	return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local config = ngx.shared.config

-- Check iss
local req_issuer = config:get("issuer")
local issuer = jwt_obj.payload.iss
if not issuer or issuer ~= req_issuer then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say("Missing or invalid 'iss' claim.")
	return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Check aud
local req_audience = "https://" .. config:get("server_name") .. config:get("guac_uri")
local audience = jwt_obj.payload.aud
if not audience or audience ~= req_audience then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say("Missing or invalid 'aud' claim.")
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- Create the cookie and return it
local config = ngx.shared.config
local guac_uri = config:get("guac_uri")
ngx.header["Set-Cookie"] = "JTI=" .. jti .. "; Max-Age=30; Domain=" .. 
				ngx.var.server_name .. "; Path=" .. guac_uri .. ";"
ngx.log(ngx.INFO, "Cookie sent!")
