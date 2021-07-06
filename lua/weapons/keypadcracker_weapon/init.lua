AddCSLuaFile ("cl_init.lua")
AddCSLuaFile ("shared.lua")
include ("shared.lua")

function SWEP:PrimaryAttack()
	if self.Deployed or not IsValid(self.Owner) then return end

	local tr = self.Owner:GetEyeTrace()
	local ent = tr.Entity

	local time = self.KeyCrackTime

	if IsValid(ent) and tr.HitPos:DistToSqr(self.Owner:GetShootPos()) <= 9000 and (ent.IsKeypad and !ent.IsBeingCracked and (!ent.NextCrack or ent.NextCrack < CurTime())) then
		self:CreateCracker(self.Owner, ent)
		self.Deployed = true
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		if self.Owner:HasWeapon("keys") then
			self.Owner:SelectWeapon("keys")
		end
		self:Remove()
	end
end

function SWEP:CreateCracker(ply, keypad)
	local ang = keypad:GetForward():Angle()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), -90)

	local ent = ents.Create("keypad_cracker_deploy")
	ent:CPPISetOwner(ply)
	ent:SetPos(keypad:GetPos() - ang:Right() - ang:Forward() * 0.75)
	ent:SetParent(keypad)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	keypad.IsBeingCracked = true
	keypad.NextCrack = CurTime() + 2.5
end

function SWEP:Reload()
	return true
end