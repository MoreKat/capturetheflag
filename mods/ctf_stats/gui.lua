function ctf_stats.get_formspec_match_summary(stats)
	local players = {}
	for name, pstat in pairs(stats.red) do
		pstat.name = name
		pstat.color = ctf.flag_colors.red
		table.insert(players, pstat)
	end
	for name, pstat in pairs(stats.blue) do
		pstat.name = name
		pstat.color = ctf.flag_colors.blue
		table.insert(players, pstat)
	end
	local ret = ctf_stats.get_formspec("Match Summary", players)
	ret = ret .. "label[3.5,6.2;Tip: type /rankings for league tables]"
	return ret
end

local function calc_scores(players)
	for i = 1, #players do
		local pstat = players[i]
		pstat.kills = pstat.kills or 0
		pstat.deaths = pstat.deaths or 0
		pstat.captures = pstat.captures or 0
		pstat.attempts = pstat.attempts or 0
		local kd = pstat.kills / (pstat.deaths + 1)
		if pstat.deaths < 1 and kd > 30 then
			kd = 30
		end
		local ca = 0
		if pstat.attempts > 0 then
			ca = pstat.captures / pstat.attempts
		end
		local killbonus = 0
		if pstat.kills > 50 and pstat.kills < 200 then
			killbonus = pstat.kills - 50
		elseif pstat.kills >= 200 then
			killbonus = 150
		end
		pstat.score = killbonus +
		              10 * pstat.captures * ca +
				      5  * kd
	end
	table.sort(players, function(one, two)
		return one.score > two.score
	end)
end

function ctf_stats.get_formspec(title, players)
	calc_scores(players)

	local ret = "size[12,6.5]"
	ret = ret .. "vertlabel[0,0;" .. title .. "]"
	ret = ret .. "tablecolumns[color;text;text;text;text;text;text;text;text]"
	ret = ret .. "tableoptions[highlight=#00000000]"
	ret = ret .. "table[0.5,0;11.25,6;scores;"
	ret = ret .. "#ffffff,,username,kills,deaths,K/D ratio,captures,attempts,score"

	for i = 1, #players do
		local pstat = players[i]
		local color = pstat.color or "#ffffff"
		ret = ret ..
			"," .. string.gsub(color, "0x", "#") ..
			"," .. i ..
			"," .. pstat.name ..
			"," .. pstat.kills ..
			"," .. pstat.deaths ..
			"," .. math.floor(pstat.kills / (pstat.deaths + 1)*10)/10 ..
			"," .. pstat.captures ..
			"," .. pstat.attempts ..
			"," .. math.floor(pstat.score*10)/10
		if i > 40 then
			break
		end
	end

	ret = ret .. ";-1]"
	ret = ret .. "button_exit[0.5,6;3,1;close;Close]"
	return ret
end

function ctf_stats.get_html(title, players)
	calc_scores(players)

	local ret = "<h1>" .. title .. "</h1>"
	ret = ret .. "<table>" ..
		"<tr><th></th>" ..
		"<th>username</th>" ..
		"<th>kills</th>" ..
		"<th>deaths</th>" ..
		"<th>K/D ratio</th>" ..
		"<th>captures</th>" ..
		"<th>attempts</th>" ..
		"<th>score</th></tr>"

	for i = 1, #players do
		local pstat = players[i]
		local color = pstat.color or "#ffffff"
		ret = ret ..
			"<tr><td>" .. i ..
			"</td><td>" .. pstat.name ..
			"</td><td>" .. pstat.kills ..
			"</td><td>" .. pstat.deaths ..
			"</td><td>" .. math.floor(pstat.kills / (pstat.deaths + 1)*10)/10 ..
			"</td><td>" .. pstat.captures ..
			"</td><td>" .. pstat.attempts ..
			"</td><td>" .. math.floor(pstat.score*10)/10 .. "</td></tr>"
		if i > 40 then
			break
		end
	end

	ret = ret .. "</table>\n"
	return ret
end

function ctf_stats.html_to_file(filepath)
	local players = {}
	for name, pstat in pairs(ctf_stats.players) do
		pstat.name = name
		pstat.color = nil
		table.insert(players, pstat)
	end
	local html = ctf_stats.get_html("Player Rankings", players)
	local f = io.open(filepath, "w")
	f:write("<!doctype html>\n")
	f:write("<html><head>\n")
	f:write("<meta charset=\"utf-8\">\n")
	f:write("<title>Player Rankings</title>\n")
	f:write("<link rel=\"stylesheet\" href=\"score_style.css\">\n")
	f:write("</head><body>\n")
	f:write(html)
	f:write("</body></html>\n")
	f:close()
end

minetest.register_chatcommand("rankings", {
	func = function(name)
		local players = {}
		for name, pstat in pairs(ctf_stats.players) do
			pstat.name = name
			pstat.color = nil
			table.insert(players, pstat)
		end
		local fs = ctf_stats.get_formspec("Player Rankings", players)
		minetest.show_formspec(name, "ctf_stats:rankings", fs)
	end
})