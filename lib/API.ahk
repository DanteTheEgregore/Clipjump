; Plugin API for Clipjump

Act_API(D, k){
	static cbF := A_temp "\cjcb.txt"
	static rFuncs := "|getClipAt|getClipLoc|"

	fname := Substr(D, Strlen(k)+1, Instr(D, "`n")-Strlen(k)-1)
	p := Substr(D, Instr(D, "`n")+1) , ps := {}
	loop, parse, p, `n
		ps.Insert(A_LoopField)
	n := ps.MaxIndex()

	if n=1
		r := API[fname](ps.1)
	else if n=2
		r := API[fname](ps.1, ps.2)
	else if n=3
		r := API[fname](ps.1, ps.2, ps.3)
	else if n=4
		r := API[fname](ps.1, ps.2, ps.3, ps.4)

	if Instr(rFuncs, "|" fname "|")
		FileAppend, % r, % cbF
	return
}


class API
{
	; pastes clips from certain postion in certain channel
	paste(channel="", clipno=""){
		this.blockMonitoring(1)
		if  (channel="") && (clipno="")
		{
			if !IsCurCBActive
				try FileRead, Clipboard, *c %A_ScriptDir%\%CLIPS_dir%\%TEMPSAVE%.avc
		}
		else {
			r := this.getClipLoc(channel, clipno)
			try Fileread, Clipboard, *c %r%
		}

		Send ^{vk56}
		this.blockMonitoring(0)
	}

	; get Clip content
	; toreturn = 1 < return Clipboard text data > 
	; toreturn = 2 < return ClipboardAll binary data >
	getClipAt(channel=0, clipno=1, toreturn=1, Byref err=""){
		this.blockMonitoring(1)
		r := this.getClipLoc(channel, clipno)
		try Fileread, Clipboard, *c %r%
		err := GetClipboardformat()="" ? 0 : 1
		if toreturn=1
			ret := Clipboard
		else
			ret := ClipboardAll
		this.blockMonitoring(0)
		return ret
	}

	manageClip(new_channel=0, channel="", clip="", flag=0) 	; 0 = cut , 1 = copy
	{
		; if channel is empty, active channel is used
		; if clip is empty, active clip in paste mode (Clip x of y, "x") is used.
		if channel=
			channel := CN.NG
		c_info := this.getChInfo(channel)
		if clip=
			clip := c_info.realCURSAVE - c_info.realTEMPSAVE + 1
		f := "cache\clips" c_info.p "\" c_info.realTEMPSAVE ".avc"

		nc_info := this.getChInfo(new_channel)
		; process
		if flag
			FileCopy, % f, % "cache\clips" nc_info.p "\" nc_info.realCURSAVE + 1 ".avc", 1
		else
		{
			Filemove, % f, % "cache\clips" nc_info.p "\" nc_info.realCURSAVE + 1 ".avc", 1
			c_Folder1 := "cache\clips" c_info.p "\" , c_Folder2 := "cache\fixate" c_info.p "\" , c_Folder3 := "cache\thumbs" c_info.p "\"
			loop % c_info.realCURSAVE-c_info.realTEMPSAVE
			{
				FileMove, % c_Folder1 c_info.realTEMPSAVE+A_Index ".avc", % c_Folder1 c_info.realTEMPSAVE+A_Index-1 ".avc"
				FileMove, % c_Folder2 c_info.realTEMPSAVE+A_Index ".txt", % c_Folder2 c_info.realTEMPSAVE+A_index-1 ".txt"
				FileMove, % c_Folder3 c_info.realTEMPSAVE+A_Index ".jpg", % c_Folder3 c_info.realTEMPSAVE+A_index-1 ".jpg" 
			}
		}
		; fix vars
		CN["CURSAVE" nc_info.p] += 1
		if nc_info.isactive
			CURSAVE += 1 	; also cursave if it is active

		if !flag
		{
			CN["CURSAVE" c_info.p] -= 1
			CN["TEMPSAVE" c_info.p] -= (CN["TEMPSAVE" c_info.p] > CN["CURSAVE" c_info.p]) ? 1 : 0 	; if the 29th file of 29 files was deleted and 29 was active
			if c_info.isactive
				CURSAVE -= 1 , TEMPSAVE -= (TEMPSAVE > CURSAVE) ? 1 : 0
		}
		return
	}

	; p=1 enable incognito mode
	IncognitoMode(p=1){
		NOINCOGNITO := p  		; make it the opp as incognito: will change the sign
		gosub incognito
	}

	; get Clips file location wrt Clipjump's directory
	getClipLoc(channel=0, clipno=1){
		p := !channel ? "" : channel
		z := (CN.NG==channel) ? CURSAVE : CN["CURSAVE" p] 		;chnl CURSAVE is not updated everytime but when channel is changed. 
		f := A_ScriptDir "\cache\clips" p "\" z-clipno+1 ".avc"
		return FileExist(f) ? f : ""
	}

	;blocks CB monitoring
	blockMonitoring(yes=1){
		Critical, Off 		; necessary to let onclipboard break process if needed
		if yes
		{
			CALLER := 0 , ONCLIPBOARD := 0
			while CALLER
				sleep 10
		} else {
			while !ONCLIPBOARD
				sleep 20
			CALLER := CALLER_STATUS
		}
	}
	

	;---- API HELPER FUNCS --	
	getChInfo(c="", ret=1){
		; returns obj full of channel information data
		; ret=0 returns string
		if c=
			c := CN.NG
		o := {}
		if CN.NG == c
			o.isactive := 1
		o.p := p := !c ? "" : c
		o.realCURSAVE := o.isactive ? CURSAVE : CN["CURSAVE" p] , o.channelCURSAVE := CN["CURSAVE" p]
		o.realTEMPSAVE := o.isactive ? TEMPSAVE : CN["TEMPSAVE" p] , o.channelTEMPSAVE := CN["TEMPSAVE" p]
		if ret
			return o
		; make string
		for k,v in o
			str .= k "`t" v "`n"
		return str
	}
}