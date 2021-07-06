AddCSLuaFile( "cl_init.lua" ) 
AddCSLuaFile( "shared.lua" ) 

include( 'shared.lua' )

CreateConVar( "keypad_crack_time", 10, FCVAR_SERVER_CAN_EXECUTE )
local keypad_crack_time = GetConVar( "keypad_crack_time" )

util.AddNetworkString("KeypadCracker_Sparks")

function ENT:Initialize()
	self:SetModel( "models/weapons/w_c4_planted.mdl" )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetModelScale(0.5)

    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self:Start()
	self.keypad = self:GetParent()
	self.HP = 200
end

function ENT:FallOff()
	local wep = ents.Create("keypadcracker_weapon")
	wep:SetPos(self:GetPos())
	wep:SetAngles(self:GetAngles())
	wep:Spawn()
	if IsValid(self.keypad) then
		self.keypad.IsBeingCracked = false
	end
	self:Remove()
end

function ENT:Finish()
	if IsValid(self.keypad) then
		net.Start("KeypadCracker_Sparks")
			net.WriteEntity(self.keypad)
		net.Broadcast()
		self.keypad.IsBeingCracked = false
		self.keypad:Process(true)
	end
	self:FallOff()
end

util.AddNetworkString("Keypad.Start")

function ENT:Start()
	net.Start("Keypad.Start")
		net.WriteUInt(keypad_crack_time:GetInt(), 5)
	net.Send(self:CPPIGetOwner())
	local count = 0
	timer.Create("KeypadCrack."..self:EntIndex(), 1, keypad_crack_time:GetInt(), function()
		if IsValid(self) then
			self:EmitSound("buttons/blip2.wav", 70)
			count = count + 1
			if count >= keypad_crack_time:GetInt() then
				self:Finish()
			end
		else
			timer.Remove("KeypadCrack."..self:EntIndex())
		end
	end)
end

function ENT:Use(ply)
	if IsValid(ply) then
		ply:Give("keypadcracker_weapon")
	end
	if IsValid(self.keypad) then
		self.keypad.IsBeingCracked = false
	end
	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	if dmginfo:IsBulletDamage() then
		self.HP = self.HP - dmginfo:GetDamage()
		if self.HP <= 0 then
			self:FallOff()
		end
	end
end