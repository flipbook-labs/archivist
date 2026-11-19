local Middleware = require("@root/formatters/Middleware")

local function nameMiddleware(line: string, context: Middleware.FormatContext): string
	local name = context.style(context.platform.styles.levels[context.record.level])(`[{context.record.name}]`)
	return `{name} {line}`
end

return nameMiddleware
