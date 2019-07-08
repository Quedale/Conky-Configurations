local cpu_initialized = false

function initCPUs()
	--TODO CPU temperature ${alignr 10}${exec sensors|grep 'Core "..tostring(i-1).."'|awk '{print $3}'}
	local file = io.popen("grep -c processor /proc/cpuinfo")
	local numcpus = file:read("*n")
	file:close()
	listcpus = ""

	for i = 1, numcpus do 
		listcpus = listcpus.."${goto 10}${voffset 0}${color1}CPU"..tostring(i)..": ${cpu cpu"..tostring(i).."}%\n"
		listcpus = listcpus.."${goto 10}${voffset -5}${color2}${cpugraph cpu"..tostring(i).." 25,220 66241C FF5A45}\n"
	end
	cpu_initialized = true
end

function conky_listCPUGraphs()
	if cpu_initialized == false then
		initCPUs()
	end
	return listcpus
end