TOOL.Category = "Construction";

TOOL.Name = "#Fading Door";

TOOL.ClientConVar["key"] = "5"
TOOL.ClientConVar["noeffect"] = "0"

TOOL.Information = {
	{ name = "left" },
	{ name = "reload" }
}

local noKeyboard = CreateConVar("fading_door_nokeyboard", "1", FCVAR_ARCHIVE, "Set to 1 to disable using fading doors with the keyboard")
local FadingLimit = CreateConVar("fading_doors_limit", "6", FCVAR_ARCHIVE, "Set how many fading doors your allowed")


local function checkTrace(tr)
  return (tr.Entity and tr.Entity:IsValid() and not (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsVehicle() or tr.HitWorld))
end

if (CLIENT) then
  language.Add( "Tool.fading_door.name", "Fading Door" )
  language.Add( "Tool.fading_door.desc", "Makes an object fade away when activated by the player." )
  language.Add( "Tool.fading_door.left", "Left Click: Makes prop fading door/window.")
  language.Add( "Tool.fading_door.reload", "Reload: Removes targeted fading door/window.")
  language.Add( "Undone_fading_door", "Undone Fading Door" )

  function TOOL:BuildCPanel()
    self:AddControl("Header",   {Text = "#Tool.fading_door.name", Description = "#Tool.fading_door.desc"})
    self:AddControl("Numpad",   {Label = "Fade", ButtonSize = "22", Command = "fading_door_key"})
  end

  TOOL.LeftClick = checkTrace
  return
end



local function fadeActivate(self)
  local owner = self:CPPIGetOwner()
  if SERVER then
    print("FADE: Active - " .. (owner and owner:Nick() .. "(" .. owner:SteamID() .. ")") or "no owner")
  end
  self.fadeActive = true
  self.fadeMaterial = self:GetMaterial()
  self:SetMaterial("sprites/heatwave")
  self:DrawShadow(false)
  self:SetNotSolid(true)

  local phys = self:GetPhysicsObject()

  if (IsValid(phys)) then
    self.fadeMoveable = phys:IsMoveable()
    phys:EnableMotion(false)
  end
end



local function fadeDeactivate(self)
  local owner = self:CPPIGetOwner()
  if SERVER then
    print("FADE: Deactivate - " .. (owner and owner:Nick() .. "(" .. owner:SteamID() .. ")") or "no owner")
  end
  self.fadeActive = false
  self:SetMaterial(self.fadeMaterial or "")
  self:DrawShadow(true)
  self:SetNotSolid(false)

  local phys = self:GetPhysicsObject()

  if (IsValid(phys)) then
    phys:EnableMotion(self.fadeMoveable or false)
  end
end

local function fadeToggleActive(self)
  local keypadowner = self:CPPIGetOwner()
  if noKeyboard:GetBool() and not numpad.FromButton() then 
    if keypadowner.msgcd && keypadowner.msgcd > CurTime() then return end
      keypadowner.msgcd = CurTime()+2
      keypadowner:ChatPrint("You cannot FDA please use the keypad/buttons linkned to the fading door instead.")
    return
  end 

  if self.inUse then return end
  if SERVER then
    print("FADE: Toggle")
  end
  if (self.fadeActive) then
    self.inUse = true
    timer.Simple(4, function()
      self.inUse = false
      if self.fadeActive then
        self:fadeDeactivate()
      end
    end)
  else
    self:fadeActivate()
  end
end

local function onUp(ply, ent)
  if (not (ent:IsValid() and ent.fadeToggleActive and not ent.fadeToggle)) then
    return
  end
  ent:fadeToggleActive()
end

numpad.Register("Fading Door onUp", onUp)

local function onDown(ply, ent)
  if (not (ent:IsValid() and ent.fadeToggleActive)) then
    return
  end
  ent:fadeToggleActive()
end

numpad.Register("Fading Door onDown", onDown)

local function onRemove(self)
  numpad.Remove(self.fadeUpNum)
  numpad.Remove(self.fadeDownNum)
end

-- Handling Duplications

local function dooEet(ply, ent, stuff)

  if (ent.isFadingDoor) then
    ent:fadeDeactivate()
    onRemove(ent)
  else
    ent.isFadingDoor = true
    ent.fadeActivate = fadeActivate
    ent.fadeDeactivate = fadeDeactivate
    ent.fadeToggleActive = fadeToggleActive
    ent:CallOnRemove("Fading Door", onRemove)
  end

  ent.fadeUpNum = numpad.OnUp(ply, stuff.key, "Fading Door onUp", ent)
  ent.fadeDownNum = numpad.OnDown(ply, stuff.key, "Fading Door onDown", ent)
  ent.fadeToggle = stuff.toggle

  duplicator.StoreEntityModifier(ent, "Fading Door", stuff)
  return true
end

duplicator.RegisterEntityModifier("Fading Door", dooEet)



if (not FadingDoor) then
  local function legacy(ply, ent, data)
    return dooEet(ply, ent, {
      key      = data.Key;
      toggle   = 1;
      reversed = 1;
      noeffect = data.NoEffect;
    })
  end
  duplicator.RegisterEntityModifier("FadingDoor", legacy)
end

function TOOL:LeftClick(tr)
  if (not checkTrace(tr)) then
    return false
  end
  local ent = tr.Entity
  local ply = self:GetOwner()

  if ent.isFadingDoor then return end

  if ply.FadingDoors and ply.FadingDoors >= FadingLimit:GetInt() then ply:ChatPrint("You have hit your fading door limit.") return end

  dooEet(ply, ent, {
    key      = self:GetClientNumber("key");
  })

  if !ply.FadingDoors then
    ply.FadingDoors = 0
  end
  ply.FadingDoors = ply.FadingDoors + 1
  ply:ChatPrint("Fading door/window created (" .. ply.FadingDoors .. "/".. FadingLimit:GetInt() ..")")
  return true
end

function TOOL:Reload(tr)
  local ent = tr.Entity
  local ply = self:GetOwner()

  if IsValid(ent) and ent.isFadingDoor then
    local owner = ent:CPPIGetOwner()
    if IsValid(owner) and owner.FadingDoors then
      owner.FadingDoors = owner.FadingDoors - 1
    end
    onRemove(ent)
    ent:fadeDeactivate()
    ent.isFadingDoor = false
    ply:ChatPrint("Fading door/window removed (" .. ply.FadingDoors .. "/".. FadingLimit:GetInt() ..")")
  end
	return true
end

hook.Add("EntityRemoved", "FadingDoor.LimitReset", function(ent)
  if ent.isFadingDoor then
    local owner = ent:CPPIGetOwner()
    if IsValid(owner) and owner.FadingDoors then
      owner.FadingDoors = owner.FadingDoors - 1
    end
  end
end)