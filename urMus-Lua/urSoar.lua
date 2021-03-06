soar_version=Region('region','v',UIParent)
soar_version:SetWidth(ScreenWidth())
soar_version:SetHeight(ScreenHeight())
soar_version:SetLayer("BACKGROUND")
soar_version:SetAnchor("BOTTOMLEFT", 0, 0)
soar_version.t=soar_version:Texture(255,255,255,255)
soar_version.tl=soar_version:TextLabel()
soar_version.tl:SetLabel(soar_version:SoarExec("version"))
soar_version.tl:SetColor(0,0,0,255)
soar_version:Show()

-- page button
pagebutton=Region()
pagebutton:SetWidth(pagersize)
pagebutton:SetHeight(pagersize)
pagebutton:SetLayer("TOOLTIP")
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4) 
pagebutton:EnableClamping(true)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png")
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0)
pagebutton:EnableInput(true)
pagebutton:Show()