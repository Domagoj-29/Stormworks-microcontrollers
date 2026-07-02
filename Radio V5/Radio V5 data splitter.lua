-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

DataChannel = {}
UpdateFirstHalf = true

function onTick()
	for i = 1, 32 do
		DataChannel[i] = {Number = input.getNumber(i), Logic = input.getBool(i)}
	end

	if UpdateFirstHalf then
		for i = 1, 16 do
			output.setNumber(i + 16, DataChannel[i].Number)
			output.setBool(i + 16, DataChannel[i].Logic)
		end
	else
		for i = 17, 32 do
			output.setNumber(i, DataChannel[i].Number)
			output.setBool(i, DataChannel[i].Logic)
		end
	end
	output.setBool(1, UpdateFirstHalf)

	UpdateFirstHalf = not UpdateFirstHalf
end