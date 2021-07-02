AddCSLuaFile "cl_init.lua"
AddCSLuaFile "cl_maths.lua"
AddCSLuaFile "cl_panel.lua"
AddCSLuaFile "sh_init.lua"

include "sh_init.lua"
util.AddNetworkString("Keypad")
util.AddNetworkString("Keypad_Wl")
util.AddNetworkString("Keypad_WlAdd")
util.AddNetworkString("Keypad_WlRem")
hook.Add( "PlayerInitialSpawn", "Keypad:InitWhitelist", function(ply)
	ply.KeypadJobWL = ply.KeypadJobWL or {}
	ply.KeypadWL = ply.KeypadWL or {}
end)

local function SyncKeypad(ply)
	net.Start("Keypad_Wl")
		net.WriteTable(ply.KeypadWL)
		net.WriteTable(ply.KeypadJobWL)
	net.Send(ply)
end
net.Receive("Keypad_WlAdd", function(_, ply)
	local stid = net.ReadString()
	local isJob = net.ReadBool()
	if !stid then return end
	if isJob then
		if table.HasValue(ply.KeypadJobWL,stid) then return end
		table.insert(ply.KeypadJobWL, stid)
	else
		if table.HasValue(ply.KeypadWL,stid) then return end
		table.insert(ply.KeypadWL, stid)
	end
	SyncKeypad(ply)

end)

net.Receive("Keypad_WlRem", function(_, ply)
	local stid = net.ReadString()
	local isJob = net.ReadBool()
	if !stid then return end
	
	if isJob then
		if !table.HasValue(ply.KeypadJobWL,stid) then return end
		table.RemoveByValue(ply.KeypadJobWL, stid)
	else
		if !table.HasValue(ply.KeypadWL,stid) then return end
		table.RemoveByValue(ply.KeypadWL, stid)
	end
	SyncKeypad(ply)
end)

net.Receive("Keypad", function(_, ply)
	local ent = net.ReadEntity()

	if not IsValid(ply) or not IsValid(ent) or ent:GetClass():lower() ~= "keypad" then
		return
	end

	if ent:GetStatus() ~= ent.Status_None then
		return
	end

	if ply:EyePos():Distance(ent:GetPos()) >= 120 then
		return
	end

	if ent.Next_Command_Time and ent.Next_Command_Time > CurTime() then
		return
	end

	ent.Next_Command_Time = CurTime() + 0.05
	
	local command = net.ReadUInt(4)

	if command == ent.Command_Enter then
		local val = tonumber(ent:GetValue() .. net.ReadUInt(8))

		if val and val > 0 and val <= 9999 then
			ent:SetValue(tostring(val))
			ent:EmitSound("buttons/button15.wav")
		end
	elseif command == ent.Command_Abort then
		ent:SetValue("")
	elseif command == ent.Command_ID then
		local owner = ent:GetKeypadOwner()
		if !IsValid(owner) then
			ent:Process(false)		
		elseif ply == owner then
			ent:Process(true)
		elseif table.HasValue(owner.KeypadWL, ply:SteamID()) then
			ent:Process(true)
		elseif table.HasValue(owner.KeypadJobWL, team.GetName(ply:Team())) then
			ent:Process(true)
		elseif owner:GetNVar("gang") && !ply:isCP() && (ply:GetNVar("gang") == owner:GetNVar("gang")) then
			ent:Process(true)
		else
			ent:Process(false)
		end
	elseif command == ent.Command_Manage then
		local owner = ent:GetKeypadOwner()
		if IsValid(owner) && ply == owner then
			net.Start("Keypad_Wl")
			net.WriteTable(ply.KeypadWL)
			net.WriteTable(ply.KeypadJobWL)
			net.Send(ply)
		else
			ent:Process(false)
		end
	elseif command == ent.Command_Accept then
		if ent:GetValue() == ent:GetPassword() then
			ent:Process(true)
		else
			ent:Process(false)
		end
	end
end)

function ENT:SetValue(val)
	self.Value = val

	if self:GetSecure() then
		self:SetText(string.rep("*", #val))
	else
		self:SetText(val)
	end
end

function ENT:GetValue()
	return self.Value
end

function ENT:Process(granted)
	self:GetData()
	
	local length, repeats, delay, initdelay, key
	
	if(granted) then
		self:SetStatus(self.Status_Granted)

		length    = 0--self.KeypadData.LengthGranted
		repeats   = math.min(self.KeypadData.RepeatsGranted, 50)
		delay     = 0--self.KeypadData.DelayGranted
		initdelay = 0--self.KeypadData.InitDelayGranted
		key       = tonumber(self.KeypadData.KeyGranted) or 0
	else
		self:SetStatus(self.Status_Denied)

		length    = 0--self.KeypadData.LengthDenied
		repeats   = math.min(self.KeypadData.RepeatsDenied, 50)
		delay     = 0--self.KeypadData.DelayDenied
		initdelay = 0--self.KeypadData.InitDelayDenied
		key       = tonumber(self.KeypadData.KeyDenied) or 0
	end

	local owner = self:GetKeypadOwner()

	timer.Simple(math.max(initdelay + length * (repeats + 1) + delay * repeats + 0.25, 2), function() -- 0.25 after last timer
		if(IsValid(self)) then
			self:Reset()
		end
	end)

	timer.Simple(initdelay, function()
		if(IsValid(self)) then
			for i = 0, repeats do
				timer.Simple(length * i + delay * i, function()
					if(IsValid(self) and IsValid(owner)) then
						numpad.Activate(owner, key, true)
					end
				end)

				timer.Simple(length * (i + 1) + delay * i, function()
					if(IsValid(self) and IsValid(owner)) then
						numpad.Deactivate(owner, key, true)
					end
				end)
			end
		end
	end)

	if(granted) then
		self:EmitSound("buttons/button9.wav")
	else
		self:EmitSound("buttons/button11.wav")
	end
end

function ENT:SetData(data)
	self.KeypadData = data

	self:SetPassword(data.Password or "1337")
	self:Reset()
	duplicator.StoreEntityModifier(self, "keypad_password_passthrough", self.KeypadData)
end

function ENT:GetData()
	if not self.KeypadData then
		self:SetData( {
			Password = 1337,

			RepeatsGranted = 0,
			RepeatsDenied = 0,

			LengthGranted = 0,
			LengthDenied = 0,

			DelayGranted = 0,
			DelayDenied = 0,

			InitDelayGranted = 0,
			InitDelayDenied = 0,

			KeyGranted = 0,
			KeyDenied = 0,

			Secure = true
		} )
	end

	return self.KeypadData
end

function ENT:Reset()
	self:SetValue("")
	self:SetStatus(self.Status_None)
	self:SetSecure(self:GetData().Secure)
end



duplicator.RegisterEntityModifier( "keypad_password_passthrough", function(ply, entity, data)
	entity:SetKeypadOwner(ply)
    entity:SetData(data)
end)
