item_auto_precache = class({})

local _auto_precached = _auto_precached or {}

function item_auto_precache:Spawn()
	if not IsServer() then return end
	if self._precache_requested then return end
	if not IsValidEntity(self) then return end

	local name = self:GetAbilityName()

	if not _auto_precached[name] then
		PrecacheItemByNameAsync(name, function(id)
			if not IsValidEntity(self) then return end
			print("[Precache] auto-precache completed for", name, id)
			_auto_precached[name] = true
		end)
	else
		print("repeated precache call declined for", name)
	end

	self._precache_requested = true

	if self._Spawn then self:_Spawn() end
end
