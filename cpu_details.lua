---------------------------------
-- Network Interfaces
---------------------------------
function initNets()
	local netstatio = io.popen("ip link show | awk '{print substr($2, 1, length($2)-1)}'")
	local netstatout = netstatio:read("*all")

	function string.starts(String,Start)
	   return string.sub(String,1,string.len(Start))==Start
	end
	
	local outstr = ""
	for line in string.gmatch(netstatout,"[^\r\n]*") do
		if string.starts(line, "wl") or 
			string.starts(line, "enp") or
			string.starts(line, "eth") then
			
			local addr=conky_parse('${addr '..line..'}')
			if addr ~= "No Address" then
				outstr = outstr.."\n${voffset -5}${font ADELE:bold:size=15}${color1}${alignc}Interface "..line.."${font}\n"
				outstr = outstr.."Internal: ${font ADELE:bold:14}${alignr}"..addr.."\n"
				outstr = outstr.."${color1}${font ADELE:bold:size=9}UP : ${upspeed "..line.."} | DOWN : ${downspeed "..line.."}${alignr}${totalup "..line.."} / ${totaldown "..line.."}\n"
				outstr = outstr.."${color2}${upspeedgraph "..line.." 25,240 66241C FF5A45 0 -l}\n"
				outstr = outstr.."${color2}${voffset -10}${downspeedgraph "..line.." 25,240 66241C FF5A45 0 -l}\n"
			end
		end
	end
	
	return outstr
end

local output = ""
function conky_listNets()
	if output == "" then
		output = initNets()
	end
	return output
end

---------------------------------
-- Mounts
---------------------------------

function round(exact, quantum)
    local quant,frac = math.modf(exact/quantum)
    return quantum * (quant + (frac > 0.5 and 1 or 0))
end

function toGBFromB(num, pow)
	local gb = num / 1000 / 1000 / 1000
	return round(gb, pow)
end

function toGBFromK(num, pow)
	local gb = num / 1000 / 1000
	return round(gb, pow)
end

function decode (s)
      return (string.gsub(s, '\\x[0-9][0-9]', function (x)
		x = string.gsub(x,"\\","0")
               return string.char(tonumber(x))
             end))
end

function column(s,n)
    local p=string.rep("%s+.-",n-1).."(%S+)"
    return s:match(p)
end

json = require "json"
function conky_listMounts()
	local file_df = io.popen("df -B 1000 | grep -e '^/dev'")
	local dftext = file_df:read("*all")
	file_df:close()

	local file_devs = io.popen("lsblk --json --output NAME,MODEL,MOUNTPOINT,LABEL,SIZE --noheadings --bytes")
	local text = file_devs:read("*all")
	file_devs:close()

	local objline = json.decode(text).blockdevices
	
	local output = ""
	for rowCount = 1, #objline do
		local found_mount = false
		local model = objline[rowCount].model
		local childs = objline[rowCount].children
		if childs ~= nil then
			for partCount = 1, #childs do
				local partdevid = childs[partCount].name
				local mountpoint = childs[partCount].mountpoint
				local label = childs[partCount].label
				local size = childs[partCount].size
				size = toGBFromB(size, 1)
				
				if label == nil and mountpoint == "/" then
					label = "Root"
				elseif label == nil then
					label = size.." GB Volume"
				end
				
				if mountpoint ~= nil and mountpoint ~= "[SWAP]" and mountpoint ~= "System\\x20Reserved" and mountpoint ~= "/boot/efi" then 
					local perused = "?%"
					local used = ""
					for word in string.gmatch(dftext, "/dev/"..partdevid.."([^\n]*)") do 
						perused = column(word,5)
						used = column(word,3)
						used = toGBFromK(used,0.1)
					end
					if found_mount ~= true then 
						output = output.."${color1}${voffset -10}${hr 1}\n"
						output = output.."${color1}${font ADELE:bold:size=11}"..model.."\n"
						output = output.."${voffset 10}"
						found_mount = true
					else
						output = output.."${voffset -5}"
					end
					output = output.."${color1}${offset 5}${font ADELE:bold:size=12}"..label.."${font}\n"
					output = output.."${color1}${offset 5}${voffset -10}${font :size=7}"..mountpoint.." ${alignr}${offset -5}${font ADELE:bold:size=9}${color1}"..used.." / "..size.." ("..perused..")\n"
					output = output.."${color2}${offset 5}${voffset -2}${fs_bar 5,230 "..mountpoint.."}\n"
					output = output.."${color1}${offset 5}${font ADELE:bold:size=9}READ : ${diskio_read "..partdevid.."}/s | WRITE : ${diskio_write "..partdevid.."}/s${alignr}${font ADELE:bold:size=9}${offset -5}["..partdevid.."]${font}\n"
					output = output.."${color2}${offset 5}${voffset -10}${diskiograph_read "..partdevid.." 20,230 66241C FF5A45 0 -t}\n"
					output = output.."${color2}${offset 5}${voffset -15}${diskiograph_write "..partdevid.." 20,230 66241C FF5A45 0 -t}\n"
				end

			end
		end
	end

	return output
end