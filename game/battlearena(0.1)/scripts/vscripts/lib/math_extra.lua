function clamp(v, mn, mx)
	return math.min(math.max(v, mn), mx)
end

function lerp(a, b, t)
	return a + t * (b - a)
end