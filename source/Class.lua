local MetaClass
local Class

MetaClass = {}
MetaClass.__call = function(object, ...)
	local newObject = {}
	object.__index = object
	object.__call = MetaClass.__call
	setmetatable(newObject, object)
	if newObject.init then
		newObject:init(...)
	end
	return newObject
end

Class = {}
setmetatable(Class, MetaClass)

return Class