include('deferred.lua')

local protocol = include('protocol.lua')
local InfluxDB = include('client.lua')
local Point = protocol.Point
local config = Exporter.config
local client = InfluxDB({
	url = config['INFLUXDB_URL'],
	token = config['INFLUXDB_TOKEN']
})

do
	local delay = isnumber(config['DELAY']) && math.max(config['DELAY'], 1) || 5
	local server = isstring(config['SERVER_ID']) && config['SERVER_ID'] || 'default'
	local org = isstring(config['INFLUXDB_ORG']) && config['INFLUXDB_ORG'] || 'default'
	local bucket = isstring(config['INFLUXDB_BUCKET']) && config['INFLUXDB_BUCKET'] || 'default'

	timer.Create('Exporter::write_data', delay, 0, function()
		local points = {}
		local point = Point('server')
			:add_tag('server_id', server)
			:add_field('uptime', CurTime())
			:add_field('humans', #player.GetHumans())
			:add_field('bots', #player.GetBots())
			:add_field('players', player.GetCount())
			:add_field('edicts', ents.GetEdictCount())

		if (serverstat) then
			local data = serverstat.AllProcess()

			point
				:add_field('cpu_usage', data.ProcessCPUUsage)
				:add_field('memory_bytes', data.ProcessMemoryUsage)
		end

		for k, v in pairs(player.GetHumans()) do
			local point = Point('player')
				:add_tag('server_id', server)
				:add_field('steamid', v:SteamID())
				:add_field('ping', v:Ping())

			table.insert(points, point)
		end

		table.insert(points, point)

		client:write_data(org, bucket, points)
			:next(function(data)
				if (data.code == 401) then
					Exporter.log('Unable to write data to the bucket, timer paused. Check the token or its access rights.')
					Exporter.log('err: '..data.data.message)

					timer.Pause('Exporter::write_data')
				end
		end)
	end)
end
