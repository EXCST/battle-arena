function math.clamp(number, min, max)
	return math.max(min, math.min(number, max))
end


function math.sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end


function math.lerp(x, y, alpha)
    if x == y then return x end
    if alpha == 0 then return x end
    if alpha == 1 then return y end

    return x + (y - x) * alpha
end


function math.round(x)
	if x % 2 ~= 0.5 then
		return math.floor(x + 0.5)
	end
	return x - 0.5
end
