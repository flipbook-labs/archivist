--!strict
--[[
	Platform seam.

	The Lute/Loom package ships the Lute implementation here. The Roblox build
	replaces this file with one that returns `./roblox` and drops `./lute` from
	the tree entirely, so no `@lute/*` require ever reaches darklua or Roblox.
]]

return require("@root/platform/lute")
