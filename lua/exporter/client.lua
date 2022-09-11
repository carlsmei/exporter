local META = {}
META.__index = META

function META:__tostring()
	return 'Client{url="'..self.url..'"}'
end

function META:_request(path, method, headers, data)
	local url = self.url .. path
	local options = {
		headers = istable(headers) && headers || {},
		url = url,
		method = method
	}

	if (data) then
		if (options.method == 'get') then
			options.parameters = data
		elseif (istable(data)) then
			options.body = util.TableToJSON(data)
		else
			options.body = data
		end
	end

	local promise = deferred.new()

	options.success = function(code, body, headers)
		if (code == 204) then
			promise:resolve({
				code = 204,
				headers = headers
			})
		elseif (body) then
			local data = util.JSONToTable(body)

			if data then
				promise:resolve({
					code = code,
					data = data,
					headers = headers
				})
			else
				promise:reject('Invalid response:'..body)
			end
		end
	end

	options.failed = function(reason)
		promise:reject(reason)
	end

	HTTP(options)

	return promise
end

do
	local methods = {
		'get',
		'post',
		'put',
		'patch',
		'delete'
	}

	for _, v in ipairs(methods) do
		META[v] = function(self, path, headers, data)
			return self:_request(path, v, headers, data)
		end
	end
end

function META:write_data(org, bucket, data)
	assert(isstring(org), 'org must be string')
	assert(org:Trim() != '', 'org cannot be empty')
	assert(isstring(bucket), 'bucket must be string')
	assert(bucket:Trim() != '', 'bucket cannot be empty')

	local token = self.token || ''
	local headers = {}

	if (token != '') then
		headers['Authorization'] = 'Token '..token
	end

	if (istable(data)) then
		if (data._is_point) then
			data = data:build()
		else
			for k, v in pairs(data) do
				if (v._is_point) then
					data[k] = v:build()
				else
					data[k] = nil
				end
			end

			data = table.concat(data, '\n')
		end
	end

	return self:post(('/api/v2/write?org=%s&bucket=%s&precision=s'):format(org, bucket), headers, data)
end

local function InfluxDB(data)
	if (isstring(data)) then
		data = {
			url = data
		}
	end

	assert(istable(data), 'data must be table')
	assert(data.url, 'No url specified!')

	setmetatable(data, META)

	return data
end

return InfluxDB
