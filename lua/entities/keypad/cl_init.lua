include "sh_init.lua"
include "cl_maths.lua"
include "cl_panel.lua"

local mat = CreateMaterial("aeypad_baaaaaaaaaaaaaaaaaaase", "VertexLitGeneric", {
	["$basetexture"] = "white",
	["$color"] = "{ 36 36 36 }",
})

local bgcolor = Color( 35,35,35,255 )
local linecolor = Color(255,255,255,125)
local drugtrip = false

function ENT:Draw()
	render.SetMaterial(mat)

	render.DrawBox(self:GetPos(), self:GetAngles(), self.Mins, self.Maxs, color_white, true)

	local pos, ang = self:CalculateRenderPos(), self:CalculateRenderAng()

	local w, h = self.Width2D, self.Height2D
	local x, y = self:CalculateCursorPos()

	local scale = self.Scale -- A high scale avoids surface call integerising from ruining aesthetics

	cam.Start3D2D(pos, ang, self.Scale)
		self:Paint(w, h, x, y)
	cam.End3D2D()
end

function ENT:SendCommand(command, data)
	net.Start("Keypad")
		net.WriteEntity(self)
		net.WriteUInt(command, 4)

		if data then
			net.WriteUInt(data, 8)
		end
	net.SendToServer()
end

local PANEL = {}

net.Receive("Keypad_Wl", function()
	if kwhl then
		kwhl:Remove()
	end
	kwhl = vgui.Create( "key_wl")
	kwhl:MakePopup()
	--kwhl:SetSkin("bg_ui")
	kwhl:SetVisible(true)
end)

function AddWl(id, isJob)
	net.Start("Keypad_WlAdd")
		net.WriteString(id)
		net.WriteBool(isJob)
	net.SendToServer()
end

function RemoveWl(id, isJob)
	net.Start("Keypad_WlRem")
		net.WriteString(id)
		net.WriteBool(isJob)
	net.SendToServer()
end

function PANEL:Init()

	local width = ScrW()/3
	local height = ScrH()/1.15
	
	self:SetSize(width, height*2)
	self:SetPos((ScrW()/2)-(width/2),((ScrH()/2)-(height/2)))
	self:SetVisible( false )
	
	self:DrawFrame()
end

function PANEL:Paint( w, h )
	if drugtrip then
		local cin = (math.sin(CurTime()) + 1) / 2
		draw.RoundedBoxEx(8, 4, 4, ScrW()/6.5, ScrH()/1.15 , Color(cin * 255, 0, 255 - (cin * 255), 155), true, true, true, true)
		draw.RoundedBoxEx(8, ScrW()/6.4, 4, ScrW()/6.5, ScrH()/1.15 , Color(cin * 255, 0, 255 - (cin * 255), 155), true, true, true, true)
	else
		draw.RoundedBoxEx(8, 4, 4, ScrW()/6.5, ScrH()/1.15 , bgcolor, true, true, true, true)
		draw.RoundedBoxEx(8, ScrW()/6.4, 4, ScrW()/6.5, ScrH()/1.15 , bgcolor, true, true, true, true)
	end
end

function PANEL:DrawFrame()	
	
	local wl = net.ReadTable()
	local j_wl = net.ReadTable()
	if !wl or !j_wl then self:Remove() return end
	
	local CloseButton = vgui.Create( "DButton", self )
	CloseButton:SetPos( ScrW()/3.4, 5)
	CloseButton:SetSize( 17, 17 )
	CloseButton:SetTextColor(Color(230, 230, 230, 200))
	CloseButton.Paint = function() -- The paint function
    	surface.SetDrawColor( ( CloseButton:IsHovered() and Color( 255, 0, 0, 70 ) ) or Color( 200, 100, 100, 240 ) ) -- What color do You want to paint the button (R, B, G, A)
		surface.DrawRect( 0, 0, CloseButton:GetWide(), CloseButton:GetTall() ) -- Paint what coords (Used a function to figure that out)
	end
	CloseButton:SetText( "X" )
	CloseButton.DoClick = function( CloseButton )
		self:Remove()
	end
	---------------------------------------------------
	local PlayerList = vgui.Create( "DListView" )
	PlayerList:SetParent( self )
	PlayerList:SetPos( 8, 28 )
	PlayerList:SetSize( ScrW()/6.7, ScrH()/2.5 )
	PlayerList:SetMultiSelect( false )
	PlayerList:AddColumn( "Nick" )
	PlayerList:AddColumn( "SteamID" )
	PlayerList:SetPaintBackground(false)
	PlayerList.OnRowSelected = function( PlayerList )
		AddWl(PlayerList:GetLine(PlayerList:GetSelectedLine()):GetValue(2), false)
	end
	
	local JobsList = vgui.Create("DListView",self)
	JobsList:SetPos( 8, ScrH()/2.16 )
	JobsList:SetSize( ScrW()/6.7, ScrH()/2.5 )
	JobsList:SetMultiSelect( false )
	JobsList:AddColumn( "Title" )
	JobsList:SetPaintBackground(false)
	JobsList.OnRowSelected = function( JobsList )
		AddWl(JobsList:GetLine(JobsList:GetSelectedLine()):GetValue(1), true)
	end
	
	local RTitle = vgui.Create("DLabel", self)
	RTitle:SetText("Players Online")
	RTitle:SizeToContents()
	RTitle:SetTextColor(Color(220, 220, 220))
	RTitle:SetPos(ScrW()/12.8-(RTitle:GetWide()/2),8)
	
	local RDTitle = vgui.Create("DLabel", self)
	RDTitle:SetText("Jobs")
	RDTitle:SizeToContents()
	RDTitle:SetTextColor(Color(220, 220, 220))
	RDTitle:SetPos(ScrW()/12.8-(RDTitle:GetWide()/2),ScrH()/2.23)
	---------------------------
	local KeypadWhitelist = vgui.Create( "DListView" )
	KeypadWhitelist:SetParent( self )
	KeypadWhitelist:SetPos( ScrW()/6.4, 28 )
	KeypadWhitelist:SetSize( ScrW()/6.7, ScrH()/2.5 )
	KeypadWhitelist:SetMultiSelect( false )
	KeypadWhitelist:AddColumn( "Nick" )
	KeypadWhitelist:AddColumn( "SteamID" )
	KeypadWhitelist:SetPaintBackground(false)
	KeypadWhitelist.OnRowSelected = function( KeypadWhitelist )
		RemoveWl(KeypadWhitelist:GetLine(KeypadWhitelist:GetSelectedLine()):GetValue(2), false)
	end
	
	local JobsWhitelist = vgui.Create( "DListView" )
	JobsWhitelist:SetParent( self )
	JobsWhitelist:SetPos( ScrW()/6.4, ScrH()/2.16 )
	JobsWhitelist:SetSize( ScrW()/6.7, ScrH()/2.5 )
	JobsWhitelist:SetMultiSelect( false )
	JobsWhitelist:AddColumn( "Title" )
	JobsWhitelist:SetPaintBackground(false)
	JobsWhitelist.OnRowSelected = function( JobsWhitelist )
		RemoveWl(JobsWhitelist:GetLine(JobsWhitelist:GetSelectedLine()):GetValue(1), true)
	end
	
	
	local LTitle = vgui.Create("DLabel", self)
	LTitle:SetText("Keypad Whitelist")
	LTitle:SizeToContents()
	LTitle:SetTextColor(Color(220, 220, 220))
	LTitle:SetPos(ScrW()/4.3-(LTitle:GetWide()/2),8)
	
	local LDTitle = vgui.Create("DLabel", self)
	LDTitle:SetText("Jobs Whitelist")
	LDTitle:SizeToContents()
	LDTitle:SetTextColor(Color(220, 220, 220))
	LDTitle:SetPos(ScrW()/4.3-(LDTitle:GetWide()/2),ScrH()/2.23)
	------------------------------------------------------------
	
	if not IsValid( PlayerList ) then return end
	PlayerList:Clear()
	for k, v in pairs(player.GetAll()) do

		if (!table.HasValue(wl, v:SteamID()) && v != LocalPlayer()) then
			local l = PlayerList:AddLine( v:Nick(), v:SteamID())
			l.Paint = function( self, w, h )
				draw.RoundedBoxEx(8, 0, 0, w, h , linecolor)
				surface.SetTextColor(255,0,0,255)
			end
		end
	end
		
	KeypadWhitelist:Clear()
	for k, v in pairs(wl) do
		local nick = "Offline"
		if player.GetBySteamID(v) then nick = player.GetBySteamID(v):Nick() end
		local l = KeypadWhitelist:AddLine( nick, v )
		l.Paint = function( self, w, h )
			draw.RoundedBoxEx(8, 0, 0, w, h , linecolor)
			surface.SetTextColor(255,0,0,255)
		end
	end
	
	
	
	JobsWhitelist:Clear()
	for k, v in pairs(j_wl) do
		local l = JobsWhitelist:AddLine(v)
		l.Paint = function( self, w, h )
				draw.RoundedBoxEx(8, 0, 0, w, h , linecolor)
			surface.SetTextColor(255,0,0,255)
		end
	end
	
	JobsList:Clear()
	for k, v in pairs(RPExtraTeams) do
		if !table.HasValue(j_wl, v.name) then
			local l = JobsList:AddLine(v.name)
			l.Paint = function( self, w, h )
				draw.RoundedBoxEx(8, 0, 0, w, h, linecolor)
				surface.SetTextColor(255,0,0,255)
			end
		end
	end
	
end
vgui.Register("key_wl", PANEL, "Panel")

