if (SERVER) then
	CreateConVar('sbox_maxkeypads', 10)
end

TOOL.Category = "Construction"
TOOL.Name = "Keypad"
TOOL.Command = nil

TOOL.ClientConVar['weld'] = '1'
TOOL.ClientConVar['freeze'] = '1'

TOOL.ClientConVar['password'] = ''
TOOL.ClientConVar['secure'] = '1'

TOOL.ClientConVar['repeats_granted'] = '0'
TOOL.ClientConVar['repeats_denied'] = '0'

TOOL.ClientConVar['length_granted'] = '0.1'
TOOL.ClientConVar['length_denied'] = '0.1'

TOOL.ClientConVar['delay_granted'] = '0'
TOOL.ClientConVar['delay_denied'] = '0'

TOOL.ClientConVar['init_delay_granted'] = '0'
TOOL.ClientConVar['init_delay_denied'] = '0'

TOOL.ClientConVar['key_granted'] = '0'
TOOL.ClientConVar['key_denied'] = '0'

cleanup.Register("keypads")

if CLIENT then
	language.Add("tool.keypad_willox.name", "Keypad")
	language.Add("tool.keypad_willox.0", "Left Click: Create, Right Click: Update")
	language.Add("tool.keypad_willox.desc", "Creates Keypads for secure access")

	language.Add("Undone_Keypad", "Undone Keypad")
	language.Add("Cleanup_keypads", "Keypads")
	language.Add("Cleaned_keypads", "Cleaned up all Keypads")

	language.Add("SBoxLimit_keypads", "You've hit the Keypad limit!")
end

function TOOL:SetupKeypad(ent, pass)
	local data = {
		Password = pass,

		RepeatsGranted = self:GetClientNumber("repeats_granted"),
		RepeatsDenied = self:GetClientNumber("repeats_denied"),

		LengthGranted = self:GetClientNumber("length_granted"),
		LengthDenied = self:GetClientNumber("length_denied"),

		DelayGranted = 0,--self:GetClientNumber("delay_granted"),
		DelayDenied = 0,--self:GetClientNumber("delay_denied"),

		InitDelayGranted = self:GetClientNumber("init_delay_granted"),
		InitDelayDenied = self:GetClientNumber("init_delay_denied"),

		KeyGranted = self:GetClientNumber("key_granted"),
		KeyDenied = self:GetClientNumber("key_denied"),

		Secure = util.tobool(1),
		Whitelist = {},
		J_Whitelist = {}
	}

	ent:SetKeypadOwner(self:GetOwner())
	ent:SetData(data)
end

function TOOL:RightClick(tr)
	if not IsValid(tr.Entity) or tr.Entity:GetClass():lower() != "keypad" then return false end

	if CLIENT  then return true end

	local ply = self:GetOwner()
	local password = tonumber(ply:GetInfo("keypad_willox_password"))

	local spawn_pos = tr.HitPos
	local trace_ent = tr.Entity

	if password == nil or (string.len(tostring(password)) > 4) or (string.find(tostring(password), "0")) then
		ply:PrintMessage(3, "Invalid password!")
		return false
	end
	if trace_ent:GetKeypadOwner() == ply then
		self:SetupKeypad(trace_ent, password)

		return true
	end
end

function TOOL:LeftClick(tr)
	if IsValid(tr.Entity) and tr.Entity:GetClass():lower() == "player" then return false end

	if CLIENT then return true end

	local ply = self:GetOwner()
	local password = self:GetClientNumber("password")

	local spawn_pos = tr.HitPos + tr.HitNormal
	local trace_ent = tr.Entity

	if password == nil or (string.len(tostring(password)) > 4) or (string.find(tostring(password), "0")) then
		ply:PrintMessage(3, "Invalid password!")
		return false
	end

	if not self:GetWeapon():CheckLimit("keypads") then return false end

	local ent = ents.Create("keypad")
	ent:SetPos(spawn_pos)
	ent:SetAngles(tr.HitNormal:Angle())
	ent:Spawn()

	ent:SetPlayer(ply)

	local freeze = util.tobool(self:GetClientNumber("freeze"))
	local weld = util.tobool(self:GetClientNumber("weld"))

	if freeze or weld then
		local phys = ent:GetPhysicsObject() 

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end

	if weld then
		local weld = constraint.Weld(ent, trace_ent, 0, 0, 0, true, false)
	end

	self:SetupKeypad(ent, password)

	undo.Create("Keypad")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCount("keypads", ent)
	ply:AddCleanup("keypads", ent)

	return true
end


if CLIENT then
	local function ResetSettings(ply)
		ply:ConCommand("keypad_willox_repeats_granted 0")
		ply:ConCommand("keypad_willox_repeats_denied 0")
		ply:ConCommand("keypad_willox_length_granted 0.1")
		ply:ConCommand("keypad_willox_length_denied 0.1")
		ply:ConCommand("keypad_willox_delay_granted 0")
		ply:ConCommand("keypad_willox_delay_denied 0")
		ply:ConCommand("keypad_willox_init_delay_granted 0")
		ply:ConCommand("keypad_willox_init_delay_denied 0")
	end

	concommand.Add("keypad_willox_reset", ResetSettings)

	function TOOL.BuildCPanel(CPanel)
		local r, l = CPanel:TextEntry("Access Password", "keypad_willox_password")
		r:SetTall(22)

		CPanel:ControlHelp("Max Length: 4\nAllowed Digits: 1-9")

		local ctrl = vgui.Create("CtrlNumPad", CPanel)
			ctrl:SetConVar1("keypad_willox_key_granted")
			ctrl:SetConVar2("Keypad_willox_key_denied")
			ctrl:SetLabel1("Access Granted Key")
			ctrl:SetLabel2("Access Denied Key")
		CPanel:AddPanel(ctrl)

		local faq = CPanel:Help("Information")
			faq:SetFont("GModWorldtip")

		CPanel:Help("You can enter your password with your numpad when numlock is enabled!")
	end
end
