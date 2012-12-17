require("seed_ex")
local stringize = require("stringize")
local _filterUp
local _filterDown

Queue = {}


local _cmpMin = function (self,a,b)
    return a < b  
end
local _cmpMax = function (self,a,b)
    return a > b
end
--compare

function Queue:__init__(c)
	self._top  = 0
	self._elem = {}
    if  type(c) ~= "boolean"  then self._cmp = c;
	elseif c then self._cmp = function(self,a,b) return a < b end
	else self._cmp = function(self,a,b) return a > b end end
end

--c==true:minHeap c==false:maxHeap

function Queue:push(elem)
    self._top = self._top + 1
    self._elem[self._top] = elem
	_filterUp(self)
end

function Queue:empty()
	return self._top == 0
end

function Queue:top()
   if self:empty() then error("队列为空!") 
   else return self._elem[1] end
end

function Queue:pop()
   if self:empty() then error("队列为空!") 
   else
       local res = self._elem[1];
	   self._elem[1] = self._elem[self._top];
       self._top = self._top - 1
       _filterDown(self);
	   return res;
   end
end

function _filterUp(self)
    local j = self._top 
    local i = j / 2
	if j%2==1 then i = (j-1)/2 end
    local temp = self._elem[j]
    while j>1 do
        --if self._elem[i] < temp  then break 
        if self._cmp(self,self._elem[i],temp) then break 
        else        
            self._elem[j] = self._elem[i]
            j = i
            if i%2==0 then i = i / 2
			else i = (i-1)/2 end			
        end
    end
    self._elem[j] = temp
end

function _filterDown(self)
    local i = 1
    local j = i * 2 
    local temp = self._elem[i]
    while j<=self._top do
        if j<self._top then 	
            --if self._elem[j] > self._elem[j+1] then j = j + 1 end 
            if self._cmp(self,self._elem[j+1],self._elem[j]) then j = j + 1 end   
		end
        --if temp < self._elem[j]  then break
 	    if self._cmp(self,temp,self._elem[j]) then break
        else         
            self._elem[i] = self._elem[j]
            i = j
            j = i * 2 
        end
	end
    self._elem[i] = temp
end

define_type("Queue", Queue)



