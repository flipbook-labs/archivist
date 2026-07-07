--[[
	A small, portable JSON encoder.

	The library can't use `@std/json` (Lute-only) or `HttpService:JSONEncode`
	(Roblox-only) in portable code, so machine-readable output gets this
	dependency-free encoder instead. Encode-only; decoding is out of scope.

	Conventions:
	- Tables with contiguous 1..n integer keys encode as arrays; everything else
	  encodes as an object with stringified keys, sorted for stable output.
	- NaN/±inf encode as null (JSON has no representation for them).
	- Unrepresentable values (functions, threads, userdata) encode as their
	  tostring, so records containing them stay loggable instead of erroring.
	- Cycles encode as the string "<cycle>".
]]

local ESCAPES: { [string]: string } = {
	['"'] = '\\"',
	["\\"] = "\\\\",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
}

local function encodeString(value: string): string
	local escaped = value:gsub('[%c"\\]', function(char: string): string
		return ESCAPES[char] or string.format("\\u%04x", string.byte(char))
	end)
	return `"{escaped}"`
end

local function isArray(value: { [any]: any }): boolean
	local count = 0
	for key in value do
		if type(key) ~= "number" then
			return false
		end
		count += 1
	end
	-- Empty tables encode as objects: log payloads are maps far more often
	-- than they are empty lists.
	if count == 0 then
		return false
	end
	-- Contiguous 1..n exactly when the length operator agrees with the count.
	return count == #value
end

local function encodeValue(value: any, seen: { [any]: boolean }): string
	local valueType = type(value)

	if value == nil then
		return "null"
	elseif valueType == "boolean" then
		return tostring(value)
	elseif valueType == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return "null"
		end
		return tostring(value)
	elseif valueType == "string" then
		return encodeString(value)
	elseif valueType == "table" then
		if seen[value] then
			return encodeString("<cycle>")
		end
		seen[value] = true

		local encoded: string
		if isArray(value) then
			local parts = table.create(#value)
			for index = 1, #value do
				parts[index] = encodeValue(value[index], seen)
			end
			encoded = `[{table.concat(parts, ",")}]`
		else
			-- Sort keys so output is deterministic regardless of hash order.
			local keys = {}
			for key in value do
				table.insert(keys, key)
			end
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)

			local parts = table.create(#keys)
			for index, key in keys do
				parts[index] = `{encodeString(tostring(key))}:{encodeValue(value[key], seen)}`
			end
			encoded = `\{{table.concat(parts, ",")}\}`
		end

		seen[value] = nil
		return encoded
	end

	-- Functions, threads, userdata: represent rather than reject.
	return encodeString(tostring(value))
end

local function encodeJson(value: any): string
	return encodeValue(value, {})
end

return encodeJson
