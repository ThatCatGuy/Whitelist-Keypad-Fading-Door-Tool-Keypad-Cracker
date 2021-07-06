include( 'shared.lua' )

local dots = ""
local startTime
local endTime
local nextDot = 0
local crackTime

net.Receive("Keypad.Start", function()
	startTime = CurTime()
	crackTime = net.ReadUInt(5)
	endTime = CurTime() + crackTime 
end)

function ENT:Think()
	if (CurTime() >= nextDot) then
		nextDot = CurTime() + 1
		dots = dots .. "."

		if (dots:len() > 10) then
			dots = ""
		end
	end
end

function ENT:Draw()
	self:DrawModel()

    local Pos = self:GetPos()
	
	local dist = Pos:DistToSqr(LocalPlayer():GetPos())
	
	if (dist > 30000) then return end

	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), -90)

	cam.Start3D2D(self:GetPos() + ang:Up() * 4.5 - ang:Right() * 1.9 + ang:Forward() * 2.3, ang, 0.01)
		if (isnumber(endTime) and endTime > CurTime()) then
			local timeleft = endTime - CurTime()
			local frac = math.Clamp(timeleft / (endTime - startTime), 0, 1)
			local w, h = 260, 100
			local x, y = -130, -8
			surface.SetDrawColor(40, 40, 40, 100)
			surface.DrawRect(x - 2, y - 2, w + 4, h + 4)
			surface.SetDrawColor(255 * frac, 255 * (1 - frac), 0, 100)
			surface.DrawRect(x, y, w * (1 - frac), h)
		
			draw.SimpleTextOutlined("Cracking", "GModToolName", 0, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
			draw.SimpleTextOutlined(dots, "GModToolName", 0, 60, Color(0, 138, 7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
		end
	cam.End3D2D()
end

net.Receive("KeypadCracker_Sparks", function()
	local ent = net.ReadEntity()
	
	if IsValid(ent) then
		local vPoint = ent:GetPos()
		local effect = EffectData()
		effect:SetStart(vPoint)
		effect:SetOrigin(vPoint)
		effect:SetEntity(ent)
		effect:SetScale(2)
		util.Effect("cball_bounce", effect)
		
		ent:EmitSound("buttons/combine_button7.wav", 100, 100)
	end
end)