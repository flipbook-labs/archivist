--[[
	The two dispatch modes a logger can run in.

	Dev writes each record to its sinks synchronously, like `print`. Prod queues
	records and drains them to each sink in one batched write.
]]

export type LogMode = "Dev" | "Prod"

local LogMode = table.freeze({
	Dev = "Dev" :: "Dev",
	Prod = "Prod" :: "Prod",
})

return LogMode
