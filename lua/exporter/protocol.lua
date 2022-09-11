local protocol = {}

local SPACE_REPLACER = {' ', '\\ '}
local COMMA_REPLACER = {',', '\\,'}
local EQUAL_REPLACER = {'=', '\\='}

local FIELD_TAG_REPLACERS = {
	SPACE_REPLACER,
	COMMA_REPLACER,
	EQUAL_REPLACER
}

local MEASUREMENT_REPLACERS = {
	SPACE_REPLACER,
	COMMA_REPLACER
}

local function escape_chars(replacers, value)
	for _, v in ipairs(replacers) do
		value = value:gsub(v[1], v[2])
	end

	return value
end

do
	local META = {}
	META.__index = META
	META._is_point = true

	function META:__tostring()
		return 'Point{}'
	end

	function META:build_tag_string()
		local tags = self.tags || {}
		local tbl = {}

		for k, v in pairs(tags) do
			table.insert(tbl,
				escape_chars(FIELD_TAG_REPLACERS, k)..
				'='..
				escape_chars(FIELD_TAG_REPLACERS, v)
			)
		end

		return table.concat(tbl, ',')
	end

	function META:build_field_string()
		local fields = self.fields || {}
		local tbl = {}

		for k, v in pairs(fields) do
			table.insert(tbl,
				escape_chars(FIELD_TAG_REPLACERS, k)..
				'='..
				(isstring(v) && '"'..escape_chars(FIELD_TAG_REPLACERS, v):gsub('"', '\"')..'"' || tostring(v))
			)
		end

		return table.concat(tbl, ',')
	end

	function META:build()
		local tags = ''

		if (self.tags && !table.IsEmpty(self.tags)) then
			tags = ','..self:build_tag_string()
		end

		return escape_chars(MEASUREMENT_REPLACERS, self.measurement)..
			tags..
			' '..
			self:build_field_string()
	end

	function META:add_tag(tag, value)
		assert(type(tag) == 'string', 'tag is not string')
		assert(type(value) == 'string', 'value is not string')

		self.tags = self.tags || {}
		self.tags[tag:Trim()] = value

		return self
	end

	function META:add_field(field, value)
		assert(type(field) == 'string', 'field is not string')
		assert(type(value) == 'number' || type(value) == 'string' || type(value) == 'boolean', 'value can be integer, float, strings or boolean only')

		self.fields = self.fields || {}
		self.fields[field:Trim()] = value

		return self
	end

	function META:set_timestamp(value)
		assert(type(value) == 'number', 'value is not string')
		assert(value >= 0, 'value cannot be lower than 0')

		self.timestamp = value

		return self
	end

	function protocol.Point(measurement)
		assert(type(measurement) == 'string', 'measurement is not string')

		measurement = measurement:Trim()

		assert(measurement != '', 'measurement cannot be empty')

		local point = {
			measurement = measurement,
			tags = {},
			fields = {},
			timestamp = os.time()
		}

		setmetatable(point, META)

		return point
	end
end

return protocol
