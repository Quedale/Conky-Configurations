local file_gpu_name = io.popen("nvidia-smi --query-gpu=gpu_name --format=csv,noheader,nounits")
local gpuname = file_gpu_name:read("*all")
file_gpu_name:close()
gpuname = gpuname:gsub("\n$", "")

function conky_gpuName()
	return gpuname
end

function column(s,n)
    local p=string.rep("%s+.-",n-1).."(%S+)"
    return s:match(p)
end

function conky_listGPUProcesses()
	local file_df = io.popen("nvidia-smi pmon --select mu -c 1")
	local dftext = file_df:read("*all")
	file_df:close()
	
	local res = false
	local processes = {}
	local pid = 0
	for line in string.gmatch(dftext,"(.-)\n") do
		--processes.pid = column(line,2)
		res = string.find(line,"^#")

		if res == nil then
			p = {}
			p.pid= column(line,3)
			p.name= column(line,10)
			p.mem= column(line,5)
			p.memper= column(line,7)
			p.usage= column(line,6)
			table.insert(processes, p)
		end
	end

	table.sort(processes,function(a,b)
		return a.usage>b.usage
	end)

	local output = ""
	for key,value in pairs(processes) do 
		output = output.."${goto 10}"..value.name.."${alignr 10}"..value.usage.."%\n"
	end
	
	return output
end