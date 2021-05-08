
-- assert(loadfile("E:\\DCS\\UglySkyfire\\AutoATIS\\StorePositions.lua"))()

Ugly.AtisStatics = {}

local AllStatics = SET_STATIC:New():FilterStart()
AllStatics:ForEachStatic (function (theStatic)

  local _name = theStatic:GetName()

  env.info("UGLY: Checking static: " .. _name)

  Ugly.AtisStatics[_name] =
  {
    ["CountryID"]=theStatic:GetCountry(),
    ["CategoryID"]=theStatic:GetCategory(),
    ["y"]=theStatic:GetVec2().y, 
    ["x"]=theStatic:GetVec2().x,
    ["heading"]=routines.utils.toRadian(theStatic:GetHeading()),
    ["name"]=theStatic:GetName(),
    ["CoalitionID"]=theStatic:GetCoalition(),
    ["type"]=theStatic:GetTypeName(),
    ["shape_name"]=theStatic:GetTypeName(),
    ["dead"] = false,
  }
end)



local RelevantGroups = SET_GROUP:New():FilterStart()
RelevantGroups:ForEachGroup(function (grp)
  local DCSgroup = Group.getByName(grp:GetName() )
  local size = DCSgroup:getSize()

  local _unittable={}

  for i = 1, size do
  local tmpTable =
  {   
    ["type"]=grp:GetUnit(i):GetTypeName(),
    ["y"]=grp:GetUnit(i):GetVec2().y,
    ["x"]=grp:GetUnit(i):GetVec2().x,
    ["name"]=grp:GetUnit(i):GetName(),
    ["heading"]=routines.utils.toRadian(grp:GetUnit(i):GetHeading()),
    ["shape_name"]=grp:GetTypeName(),
  }

--	  trigger.action.outText("Unit: "..grp:GetName()..", Heading: "..grp:GetUnit(i):GetHeading()..", Heading Rad: "..routines.utils.toRadian(grp:GetUnit(i):GetHeading()), 10)
  table.insert(_unittable,tmpTable) --add units to a temporary table
  end

  Ugly.SaveUnits[grp:GetName()] =
  {
    ["CountryID"]=grp:GetCountry(),
    ["CategoryID"]=grp:GetCategory(),
    ["units"]= _unittable,
    ["y"]=grp:GetVec2().y, 
    ["x"]=grp:GetVec2().x,
    ["name"]=grp:GetName(),
    ["CoalitionID"]=grp:GetCoalition(),
  }
end)

local newMissionStr = Ugly.IntegratedserializeWithCycles("Ugly.SaveUnits", Ugly.SaveUnits) --save the Table as a serialised type with key Ugly.SaveUnits
newMissionStr = newMissionStr .. Ugly.IntegratedserializeWithCycles("Ugly.AtisStatics", Ugly.AtisStatics) --save the Table as a serialised type with key Ugly.SaveUnits
Ugly.writemission(newMissionStr, "C:\\temp\\Persistence\\ATIS_Pos.lua")--write the file from the above to Ugly.SaveUnits.lua

env.info("UGLY: Positions saved")
