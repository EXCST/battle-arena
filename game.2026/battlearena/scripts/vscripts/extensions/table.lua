function table.contains(t, value)
	for _, v in pairs(t) do
		if v == value then
			return true
		end
	end

	return false
end

function table.clone(t)
	local result = {}
	for k, v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.shuffled(t)
	t = table.clone(t)
	for i = #t, 1, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end

	return t
end

function table.merge(input1, input2)
	for i,v in pairs(input2) do
		input1[i] = v
	end
	return input1
end


function table.count(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end

    return c
end

function table.has_element_fit(t, func)
    for k, v in pairs(t) do
        if func(t, k, v) then
            return k, v
        end
    end
end

function table.find_element(t, func)
    for k, v in pairs(t) do
        if func(t, k, v) then
            return k, v
        end
    end
end

function table.findkey(t, v)
    for k, _v in pairs(t) do
        if _v == v then
            return k
        end
    end

    return nil
end

function table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.random(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    local key = keys[RandomInt(1, # keys)]
    return t[key], key
end

function table.shuffle(tbl)
    -- Must be a hash table
    local t = table.shallowcopy(tbl)
    for i = # t, 2, - 1 do
        local j    = RandomInt(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function table.deepshuffle(tbl)
    -- Must be a hash table
    local t = table.deepcopy(tbl)
    for i = # t, 2, - 1 do
        local j    = RandomInt(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function table.random_some(t, count)
    local key_table = table.make_key_table(t)
    key_table       = table.shuffle(key_table)
    local r         = {}
    for i = 1, count do
        local key = key_table[i]
        table.insert(r, t[key])
    end
    return r
end

-- Randomly select an element, with conditions
function table.random_with_condition(t, func)
    local keys = {}
    for k, v in pairs(t) do
        if func(t, k, v) then
            table.insert(keys, k)
        end
    end

    local key = keys[RandomInt(1, # keys)]
    return t[key], key
end

function table.random_some_with_condition(t, count, func)
	local key_table = {}

	for k, v in pairs(t) do
        if func(t, k, v) then
            table.insert(key_table, k)
        end
    end

    key_table = table.shuffle(key_table)
    local r = {}
    for i = 1, count do
        local key = key_table[i]
        table.insert(r, t[key])
    end
    return r
end

function table.random_some_keys_with_condition(t, count, func)
	local key_table = {}

	for k, v in pairs(t) do
        if func(t, k, v) then
            table.insert(key_table, k)
        end
    end

    key_table = table.shuffle(key_table)
	return {
		unpack(key_table, 1, count)
	}
end

-- Return all keys as a table
function table.make_key_table(t)
    local r = {}
    for k, _ in pairs(t) do
        table.insert(r, k)
    end
    return r
end

-- Return all values as a table
function table.make_value_table(t)
    local r = {}
    for _, v in pairs(t) do
        table.insert(r, v)
    end
    return r
end

function table.print(t, i)
	if not i then i = 0 end
	if not t then return end
    for k, v in pairs(t) do
    	if type(v) == "table" then
    		print(string.rep(" ", i) .. k .. " : ")
    		table.print(v, i+1)
    	else
        	print(string.rep(" ", i) .. k, v)
        end
    end
end

function table.join(...)
    local arg = {...}
    local r = {}
    for _, t in pairs(arg) do
        if type(t) == "table" then
            for _, v in pairs(t) do
                table.insert(r, v)
            end
        else
            -- If it is a value, insert it directly into the table
            table.insert(r, t)
        end
    end

    return r
end


function table.extend(t1, t2)
	for _, item in ipairs(t2) do
		table.insert(t1, item)
	end
end


-- remove item
function table.remove_item(tbl,item)
	if not tbl then return end
    local i,max=1,#tbl
    while i<=max do
        if tbl[i] == item then
            table.remove(tbl,i)
            i = i-1
            max = max-1
        end
        i= i+1
    end
    return tbl
end

function table.deepmerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                table.deepmerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end


function table.exclude_keys(t1, t2)
	for _, v in pairs(t2) do
		if t1[v] then
			t1[v] = nil
		end
	end
end


--- Returns a key-value pair with maximum value from associative table
---@param t table
function table.max_value(t)
	local key = next(t)
	local max_val = t[key]

	for k, v in pairs(t) do
		if v > max_val then
			key, max_val = k, v
		end
	end

	return key, max_val
end


function table.min_value(t)
	local key = next(t)
	local min_val = t[key]

	for k, v in pairs(t) do
		if v < min_val then
			key, min_val = k, v
		end
	end

	return key, min_val
end


--- Filters table with callback
--- NOTE: returns table with keys as they were in original table, therefore might not be suitable for filtering arrays
--- If you expect returned table to also be array with proper indices - use table.array_filter
---@param t table
---@param callback function
function table.filter(t, callback)
	local result = {}

	for k, v in pairs(t) do
		if callback(k, v, t) then
			result[k] = v
		end
	end

	return result
end


--- Return a copy of a table with all values of original table as keys
--- Useful if you need to turn array ({1, 2, 3}) into dict ({1: true, 2: true, 3: true})
---@param t table
---@param new_default_value any
function table.values_to_keys(t, new_default_value)
	local t2 = {}

	if new_default_value == nil then new_default_value = true end

	for _, v in pairs(t or {}) do
		t2[v] = new_default_value
	end

	return t2
end


local function value_to_string(v)
	if type(v) == "string" then
		v = string.gsub(v, "\n", "\\n")
		if string.match(string.gsub(v, "[^'\"]", ""), "^\"+$") then return "'" .. v .. "'" end
		return "\"" .. string.gsub(v, "\"", "\\\"") .. "\""
	else
		return type(v) == "table" and table.to_string(v) or tostring(v)
	end
end


local function key_to_string(k)
	if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
		return k
	else
		return "[" .. value_to_string(k) .. "]"
	end
end


--- Converts table content into single string recursively (inline)
---@param t table
---@return string
function table.to_string(t)
	local result, done = {}, {}

	for k, v in ipairs(t) do
		table.insert(result, value_to_string(v))
		done[k] = true
	end

	for k, v in pairs(t) do
		if not done[k] then table.insert(result, key_to_string(k) .. " = " .. value_to_string(v)) end
	end

	return "{" .. table.concat(result, ", ") .. "}"
end


function table.filter_array(t, filter_func)
	local out = {}

	for k, v in ipairs(t) do
		if filter_func(t, k, v) then table.insert(out, v) end
	end

	return out
end


--- Returns a new table, that is a result of adding contents of two passed tables
--- Unlike merge, keys present in both are added up (if possible, currently only supports numbers, other types are overwritten)
---@param t1 table @ source table
---@param t2 table @ source table
---@return table
function table.combine(t1, t2)
	local new_t = table.deepcopy(t1 or {})

	for k, v in pairs(t2 or {}) do
		if type(v) == "number" then
			new_t[k] = (new_t[k] or 0) + v
		elseif type(v) == "table" then
			new_t[k] = table.combine(new_t[k], v)
		else
			new_t[k] = v
		end
	end

	return new_t
end


local __weightened_stream = CreateUniformRandomStream(RandomInt(1, 15000000))

--- Rolls a weigtened random based on table like <name> : <weight> (i.e. [AUGMENT_RARITY.BRONZE] = 65)
---@param t table
function table.random_weighted(t)
	local weight_pool = {}
	local total_weight = 0

	for name, weight in pairs(t or {}) do
		weight_pool[name] = weight
		total_weight = total_weight + weight
	end

	local rolled_value = __weightened_stream:RandomInt(0, total_weight)

	for name, weight in pairs(weight_pool) do
		rolled_value = rolled_value - weight
		if rolled_value <= 0 then
			return name
		end
	end
end


--- Rolls a weigtened random based on table like <name> : <weight> (i.e. [AUGMENT_RARITY.BRONZE] = 65)
---@param t table
function table.random_weighted_count(t, count)
	local already_rolled = {}

	for i = 1, count do
		local weight_pool = {}
		local total_weight = 0

		for name, weight in pairs(t or {}) do
			if not already_rolled[name] then
				weight_pool[name] = weight
				total_weight = total_weight + weight
			end
		end

		local rolled_value = __weightened_stream:RandomInt(0, total_weight)

		for name, weight in pairs(weight_pool) do
			rolled_value = rolled_value - weight
			if rolled_value <= 0 then
				already_rolled[name] = true
				break
			end
		end
	end

	return already_rolled
end


function table.max_at_index(t, search_index)
	local max_value = 0

	for index, values in pairs(t) do
		-- print(index, ":", table.to_string(values))
		if values[search_index] > max_value then
			max_value = values[search_index]
		end
	end

	return max_value
end



function table.min_at_index(t, search_index)
	local min_value = 99999

	for index, values in pairs(t) do
		-- print(index, ":", table.to_string(values))
		if values[search_index] < min_value then
			min_value = values[search_index]
		end
	end

	return min_value
end



function table.compare_arrays(t1, t2)
	if #t1 ~= #t2 then return false end

	for k1, v1 in ipairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or v2 ~= v1 then return false end
	end

	return true
end

---@param o1 any|table First object to compare
---@param o2 any|table Second object to compare
function table.deep_compare(t1, t2)
	if t1 == t2 then return true end
	local t1_type = type(t1)
	local t2_type = type(t2)
	if t1_type ~= t2_type then return false end
	if t1_type ~= "table" then return false end

	local key_set = {}

	for key1, value1 in pairs(t1) do
		local value2 = t2[key1]
		if value2 == nil or table.deep_compare(value1, value2) == false then
			return false
		end
		key_set[key1] = true
	end

	for key2, _ in pairs(t2) do
		if not key_set[key2] then return false end
	end

	return true
end