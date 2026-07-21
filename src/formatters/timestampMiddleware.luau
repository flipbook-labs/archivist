local Middleware = require("@root/formatters/Middleware")

local function timestampMiddleware(line: string, context: Middleware.FormatContext): string
	local clock = os.date("%H:%M:%S", context.record.timestamp) :: string
	return `{context.style(context.platform.styles.dim)(clock)} {line}`
end

return timestampMiddleware
