local resource = require("resource")

local uri = require("uri")
local coroutine = require("coroutine")

local runtime = require("runtime")
local ipairs = ipairs
local select = select
local assert = assert
local table = table
local collectgarbage = collectgarbage

_ENV={}

local loadTexture = resource.loadTexture
local loadAudio = resource.loadAudio
local extMap = {
    png = loadTexture,
    bmp = loadTexture,
    jpg = loadTexture,

    wav = loadAudio,
    ogg = loadAudio,
}

local function loadRes(l)
    local ext = select(2, uri.splitext(l)):sub(2)
    assert(extMap[ext], "Unknown extension: " .. ext)
    return extMap[ext](l)
end

-- Cache resource ptr to avoid auto releasing.
local res_cache

local function waitComplete(cache, start, callback)
    for i,v in ipairs(cache) do
        if (not v:isLoaded()) then
            v:startLoad()
        end
    end
    
    --wait for tasks done.
    
    local sz = #cache
    local cy = coroutine.yield
    local cf
    local cw = coroutine.wrap(function()
        for i = start,sz do
            while (not cache[i]:isLoaded()) do
                cy()
            end
        end
        cf()
    end)
    
    runtime.enterFrame:addListener(cw)
    
    function cf()
        runtime.enterFrame:removeListener(cw)
        callback()
    end
end

function startLoad(reses, callback)
    local cache = {}
    for i,v in ipairs(reses) do
        local l = uri.absolute(v, 2)
        local res = loadRes(l)
        res.uri = l
        table.insert(cache, res)
    end
    
    res_cache = cache
    
    collectgarbage()
    
    waitComplete(cache, 1, callback)
end

function addLoad(reses, callback)
    local cache = res_cache
    local start = #cache + 1
    
    for i,v in ipairs(reses) do
        local l = uri.absolute(v, 2)
        local res = loadRes(l)
        res.uri = l
        table.insert(cache, res)
    end
    
    waitComplete(cache, start, callback)
end

return _ENV