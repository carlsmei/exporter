_G.Exporter = Exporter or {}

function Exporter.log(text)
	assert(isstring(text), 'text must be string')

	print('[EXPORTER] '..text)
end

Exporter.log('Loading addon...')

if (!serverstat) then
	Exporter.log('Loading serverstat module')

	local success, err = pcall(require, 'serverstat')

	if (!success) then
		Exporter.log('Cannot load serverstat module, error: ' .. err)
	else
		Exporter.log('Serverstat module loaded')
	end
end

Exporter.log('Loading config')

include('exporter/config.lua')
include('exporter/core.lua')
