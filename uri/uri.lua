
--[[
Seed基础插件：uri

    版本：
        1.3

    最后修改日期：2013-1-6
    
    更新记录：
        2013-1-6:
            去除了可能引发问题的__FILE__ __LINE__ __FUNCTION__三个函数。
            不再对相对“当前代码文件”提供支持。相对路径转绝对路径时，都会相对"res://"进行。
        1.2 split函数修正
        1.1 增加了extension函数
]]


require("lua_ex")
module(..., package.seeall)

_G._URI_VER = 10003

local curdir = "."
local pardir = ".."
local sep = "/"
local sepm = "%/"

local dot = "."
local dotm = "%."

local archieve = "##"
local archievem = "%#%#"

function isabs(str)
    return str:find("%w+%:%/%/") == 1 or str:sub(1, 1) == '/'
end

function splitprotocol(uri)
	return uri:match("(%w+)(%:%/%/)(.*)")
end

function splitarchieve(uri)
	for i = #uri-1, 1, -1 do
		if (uri:sub(i,i+1) == archieve) then
			return uri:sub(1, i-1), archieve, uri:sub(i+2)
		end
	end
end

local function splitroot(uri, normarchieve)
	local archieve, mark, rest = splitarchieve(uri)
	if (archieve) then
		if (normarchieve) then
			archieve = normalize(archieve)
		end
		if (rest:sub(1, 1) == sep) then
			return archieve..mark..sep, rest:sub(2)
		end
		return archieve..mark..sep, rest
	end
	
	protocol, mark, rest = splitprotocol(uri)
	if (protocol) then
		if (_OS_NAME == "win32"  and protocol == "file") then
			--keep drive mark on windows
			local s, e = rest:find(sepm)
			return protocol..mark..rest:sub(1, e), rest:sub(e+1)
		end
		
		return protocol..mark, rest
	end
	
	if (uri:sub(1, 1) == sep) then
		return sep, uri:sub(2)
	end
	return "", uri
end

function normalize(uri)
    local orguri = uri
    
    if (uri == "") then
        return '.'
    end
   
    local prefix, uri = splitroot(uri, true)
    
    local comps = uri:split(sepm)
    local outt = {}
    local j = 0
    for i=1, #comps do
        if (comps[i] =='.' or comps[i] == '') then
        elseif (comps[i] == '..') then
            if (j > 0 and outt[j] ~= "..") then
                outt[j] = nil
                j = j-1
            elseif (j == 0 and prefix ~= "") then
            else
                j = j+1
                outt[j] = comps[i]
            end
        else
            j = j+1
            outt[j] = comps[i]
        end
    end
    if (prefix=='' and j == 0) then
        return '.'
    end
    
    return prefix .. table.concat(outt, sep)
end

function join(...)
    local t={...}
    local p="."
    for i,v in ipairs(t) do
        if (isabs(v)) then
			local pr, r = splitroot(v)
			if (pr == '/') then
				p = splitroot(p) .. r
			else
				p = v
			end
        else
            p = p .. '/' .. v
        end
    end
    return p
end

function split(p)
	local rsl = #splitroot(p)
	
    for i=#p,math.max(rsl+1, 1),-1 do
        if (p:sub(i, i):match(sepm)) then
            local j = i;
            while (j>rsl and p:sub(j, j):match(sepm)) do
                j = j - 1
                if (j == 0) then
                    j = i
                    break;
                end
            end
            return p:sub(1, j), p:sub(i+1)
        end
    end
    if (rsl > 0) then
		return p:sub(1, rsl), p:sub(rsl+1)
    end
    return "", p
end

function splitext(p)
    for i=#p-1,1,-1 do
        if (p:sub(i, i):match(dotm)) then
            return p:sub(1, i-1), p:sub(i)
        end
        if (p:sub(i, i):match(sepm) or p:sub(i, i+1):match(archievem)) then
			return p, ''
        end
    end
    return p, ''
end

--文件名
function basename(p)
    local b, t = split(p)
    return t
end

--路径名
function dirname(p)
    local b, t = split(p)
    return b
end

function normjoin(...)
    return normalize(join(...))
end

function extension(p)
	local b, ext = splitext(p)
	return ext
end

--取绝对路径
function absolute(uri, lvl)
	lvl = lvl or 1
    return normjoin("res://", uri)
end


function reluri(uri, start)
    start = start and absolute(start, 2) or "res://"
    uri = absolute(uri, 2)
    
    local start_prefix, start_list = splitroot(start)
    local uri_prefix, uri_list = splitroot(uri)
    
    if (start_prefix ~= uri_prefix) then
        return uri
    end
    
    start_list = start_list:split(sepm, false, true)
    uri_list = uri_list:split(sepm, false, true)
    
    i = 1
    while (i<=#start_list and i<=#uri_list and start_list[i] == uri_list[i]) do
        i = i + 1
    end
    
    local rel_list = {}
    for j = i, #start_list do
        table.insert(rel_list, pardir)
    end
    for j = i, #uri_list do
        table.insert(rel_list, uri_list[j])
    end
    if (#uri_list == 0) then
        return curdir
    end
    return table.concat(rel_list, sep)
end

