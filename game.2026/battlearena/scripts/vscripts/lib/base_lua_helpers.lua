function merge_table(tbl1, tbl2)
	--print(tbl1, tbl2)
	if type(tbl1) == 'number' then
	    print("Is number", tbl1)
		for k,v in pairs(tbl2) do
			print("Key!!!!!!!!!!!!!!! value !!!!!!!!!!!!!!!!!!11", k, v)
		end
	elseif type(tbl1) == 'string' then
	    print("Is string", tbl1)
	end
	for k,v in pairs(tbl2) do
		if type(v) == 'table' and tbl1[k] then
			merge_table(tbl1[k], v)
		else
			tbl1[k] = v
		end
	end
end

function dir(t) 
	local res = ""

	for i,x in pairs(t) do
		res = res .. tostring(i) .. ": " .. tostring(x) .. "\n"
	end 	

	return res:sub(0, #res-1)
end 

function print_table(t)
	print( dir(t) )
end

function ShuffleTable(someTable, randFunc)
	if not randFunc then
		randFunc = RandomInt
	end
	
	for idx, x in pairs(someTable) do
		local i = randFunc(1, #someTable)

		if i ~= idx then
			local temp = x
			someTable[idx] = someTable[i]
			someTable[i] = temp
		end
	end

	return someTable 
end

local function _format_force_print( ... )
	local text = ""

	local nArgs = select("#", ...)

	for i = 1, nArgs do
		text = text .. " " .. tostring( select(i, ...) )
	end

	return text
end

function force_print( ... )
	local text = _format_force_print( ... )

	CustomGameEventManager:Send_ServerToAllClients("DebugMessage", { msg = text })
end

function force_print_player( player, ... )
	local text = _format_force_print( ... )

	CustomGameEventManager:Send_ServerToPlayer(player, "DebugMessage", { msg = text })
end

function SafeCall(func, ...)
	local arg = {...}

	local status, result = xpcall(function() return func(unpack(arg)) end, 
								  function (msg)
									  local m = type(msg) == "string" and msg or tostring(msg)
									  return m .. '\n' .. debug.traceback() .. '\n'
								  end)

	return result
end

function Safe_Wrap(mt, name)
	local func = Dynamic_Wrap(mt, name)

	local result = function(...)
		return SafeCall( func, ... )
	end

	return result
end

-- stack helpers (used by stegius abilities, ported from angel-arena-black-star)
function ModifyStacks(ability, caster, unit, modifier, stack_amount, refresh)
	if stack_amount > 0 then
		return AddStacks(ability, caster, unit, modifier, stack_amount, refresh)
	elseif stack_amount < 0 then
		return RemoveStacks(ability, unit, modifier, -stack_amount)
	end
end

function AddStacks(ability, caster, unit, modifier, stack_amount, refresh)
	if unit:HasModifier(modifier) then
		if refresh then
			ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		end
		unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) + stack_amount)
	else
		ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		unit:SetModifierStackCount(modifier, ability, stack_amount)
	end
	return unit:FindModifierByNameAndCaster(modifier, caster)
end

function RemoveStacks(ability, unit, modifier, stack_amount)
	if unit:HasModifier(modifier) then
		if unit:GetModifierStackCount(modifier, ability) > stack_amount then
			unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) - stack_amount)
		else
			unit:RemoveModifierByName(modifier)
		end
	end
end