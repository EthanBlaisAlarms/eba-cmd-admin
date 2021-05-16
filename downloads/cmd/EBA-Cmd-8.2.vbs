'EBA Command Center 8.2
'Copyright EBA Tools 2021
Option Explicit
On Error Resume Next

'Objects
Dim fs : Set fs = CreateObject("Scripting.FileSystemObject")
Dim cmd : Set cmd = CreateObject("Wscript.shell")
Dim objApp : Set objApp = CreateObject("Shell.Application")
Dim WMI : Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Dim objHttps : Set objHttps = CreateObject("MSXML2.XMLHTTP.6.0")
Dim objOS : Set objOS = WMI.ExecQuery("Select * from Win32_OperatingSystem")
Dim sys,forVar,objShort,backup1,backup2

'Const
Const ver = 8.2
Const regLoc = "HKLM\SOFTWARE\EBA-Cmd"

'Dim Const
Dim nls : nls = vblf & vblf
Dim dataLoc : dataLoc = cmd.ExpandEnvironmentStrings("%AppData%") & "\EBA"
Dim scriptLoc : scriptLoc = Wscript.ScriptFullName
Dim scriptDir : scriptDir = fs.GetParentFolderName(scriptLoc)
Dim line : line = vblf & "---------------------------------------" & vblf
Dim logDir : logDir = dataLoc & "\EBA.log"
Dim startupType : startupType = "install"
Dim title : title = "EBA Cmd " & ver & " | Debug"
Dim desktop : desktop = cmd.SpecialFolders("AllUsersDesktop")
Dim startMenu : startMenu = cmd.SpecialFolders("AllUsersStartMenu") & "\Programs\EBA"
Dim isAdmin : isAdmin = true
Dim onlineData, programLoc
Dim startup : startup = cmd.SpecialFolders("Startup")

'System Strings
Dim exeValue : exeValue = "eba.null"
Dim exeValueExt : exeValueExt = "eba.null"
Dim status : status = "EBA Cmd"
Dim nowTime, nowDate, logData, data, fileDir, curEdit

'Web Strings
Dim curVer
Dim htmlContent

'User Strings
Dim user : user = "false"
Dim userType : userType = "false"
Dim uName, pWord, eba, importData, installEdit, ebaKey, logIn, logInType

'Bool, Int, Settings
Dim missFiles : missFiles = False
Dim logging : logging = False
Dim saveLogin : saveLogin = False
Dim shutdownTimer : shutdownTimer = 10
Dim secureShutdown : secureShutdown = False
Dim prog : prog = 0
Dim isInstalled : isInstalled = False
Dim skipDo : skipDo = False
Dim defaultShutdown : defaultShutdown = "shutdown"
Dim enableEndOp : enableEndOp = 1
Dim connectRetry : connectRetry = 5
Dim curConnectRetry : curConnectRetry = 1
Dim disableErrHandle : disableErrHandle = 0
Dim enableLegacyEndOp : enableLegacyEndOp = False

'Arrays
Dim temp(9), count(4), lines(30)
Call clearTemps
Call clearCounts
Call clearLines
count(0) = 0
count(4) = 0

Call checkWScript

Call readSettings

'Check Uninstallation
If fExists(cmd.SpecialFolders("Startup") & "\uninstallEBA.vbs") Then
	Call giveError("Cannot start EBA Command Center.","EBA_UNINSTALLION_SCHEDULED")
	Call endOp("c")
End If

'Check Admin
Call checkWScript
cmd.RegRead("HKEY_USERS\s-1-5-19\")
If Not Err.Number = 0 Then
	isAdmin = False
Else
	isAdmin = True
End If
Err.Clear

If Not disableErrHandle = 0 Then On Error GoTo 0
'Check OS
temp(0) = LCase(checkOS())
If InStr(temp(0),"microsoft") Then
	If InStr(temp(0),"windows") Then
		If InStr(temp(0),"10") or InStr(temp(0),"7") or InStr(temp(0),"8") Then
			Call clearTemps
		Elseif InStr(temp(0),"vista") Then
			Call giveWarn("Windows Vista might not support EBA Command Center.")
		Else
			Call giveError("Your version of Windows does not support EBA Command Center.","Invalid_Windows_Version")
		End If
	Else
		Call giveError("EBA Command Center will not run in Windows Recovery. Please boot into Windows to use EBA Cmd.","Windows_RE")
		Call endOp("c")
	End If
Else
	Call giveError("EBA Command Center will not run on your OS. EBA Command Center is designed for Windows 10, but will support as early as Windows 7.")
	Call endOp("c")
End If

'Get Imports
For Each forVar In Wscript.Arguments
	importData = forVar
Next

'Get Retry Count
If fExists(dataLoc & "\connect.ebacmd") Then
	Call read(dataLoc & "\connect.ebacmd","l")
	curConnectRetry = CInt(data)
End If

'Get Startup Type
If fExists(programLoc & "\EBA.vbs") Then
	If LCase(scriptLoc) = LCase(programLoc & "\EBA.vbs") Then
		If fExists(dataLoc & "\startupType.ebacmd") Then
			Call read(dataLoc & "\startupType.ebacmd","l")
			startupType = data
		Else
			startupType = "normal"
		End If
	Elseif LCase(scriptLoc) = LCase(startup & "\uninstallEBA.vbs") Then
		startupType = "uninstall"
	Else
		startupType = "update"
	End If
Else
	startupType = "install"
End If

'Check Imports
Call checkImports

'Secure Shutdown
'Call write(dataLoc & "\secureShutdown.ebacmd","false")

'Check if EBA-Cmd is running
If scriptRunning() Then
	Call giveError("Cannot start EBA Command Center.","EBA_ALREADY_RUNNING")
	Call endOp("s")
End If

'Launch
Do
	If startupType = "firstrepair" Then
		Call modeFirstrepair
	Elseif startupType = "firstrun" Then
		Call modeFirstrun
	Elseif startupType = "install" Then
		Call modeInstall
	Elseif startupType = "normal" Then
		Call modeNormal
	Elseif startupType = "recover" Then
		Call modeRecover
	Elseif startupType = "refresh" Then
		Call modeRefresh
	Elseif startupType = "repair" Then
		Call modeRepair
	Elseif startupType = "uninstall" Then
		Call modeUninstall
	Elseif startupType = "update" Then
		Call modeUpdate
	Else
		eba = msgbox("Warning:" & line & "There is a problem with startupType " & startupType & ". Do you want to reset it?",4+48,title)
		If eba = vbYes Then
			Call write(dataLoc & "\startupType.ebacmd","normal")
		End If
		Call endOp("s")
	End If
Loop







'Modes
Sub modeFirstrepair
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Automatic Repair"
	Call checkWScript
	
	Call giveNote("Hello!")
	Call giveNote("EBA Command Center is almost done repairing.")
	Call giveNote("All thats left to do is check if your User Account is functional.")
	Do
		eba = inputbox("Check your user accounts below. Afterwards, press Cancel to stop checking." & line & "Enter your Username:",title)
		If eba = "" Then
			Exit Do
		Elseif fExists(dataLoc & "\Users\" & eba & ".ebacmd") Then
			Call readLines(dataLoc & "\Users\" & eba & ".ebacmd",2)
			If LCase(lines(2)) = "owner" Then
				Call giveNote("That User Account exists on this device, and has administrator permissions.")
			Else
				Call giveWarn("That User Account exists, but the account is either corrupt, or was not the original account.")
			End If
		Else
			Call giveWarn("That User Account does not exist!")
		End If
	Loop
	
	eba = msgbox("Do you need to re-add an Administrator User Account?",4+32,title)
	If eba = vbYes Then
		Call giveNote("EBA Command Center will launch Initial Setup.")
		startupType = "firstrun"
		Exit Sub
	End If
	Call giveNote("EBA Command Center will restart.")
	Call endOp("r")
End Sub
Sub modeFirstrun
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Initial Setup"
	Call checkWScript
	
	Call giveNote("Welcome!")
	Call giveNote("Thanks for choosing EBA Command Center!")
	Call giveNote("We're about to perform initial setup.")
	Call giveNote("If this is your first time using EBA Command Center, we recommend checking out the EBA Wiki (on our website).")
	Call giveNote("Ok, enough chit-chat. Lets begin setup!")
	wscript.sleep 2000
	
	'Username
	Call giveNote("Lets begin with a User Account. Your account is stored locally on your PC.")
	
	prog = 1
	Do while prog = 1
		uName = inputbox("Type the username you want on the account:",title)
		If Len(uName) < 3 Then
			Call giveWarn("Too short! Usernames must be at least 3 characters long!")
		Elseif Len(uName) > 15 Then
			Call giveWarn("Too long! Usernames cannot be longer than 15 characters.")
		Else
			If inStr(1,uName,"\") > 0 Then
				Call giveWarn("Back-slash(\) is not allowed in usernames!")
			Elseif inStr(1,uName,"/") > 0 Then
				Call giveWarn("Slash(/) is not allowed in usernames!")
			Elseif inStr(1,uName,":") > 0 Then
				Call giveWarn("Colon(:) is not allowed in usernames!")
			Elseif inStr(1,uName,"*") > 0 Then
				Call giveWarn("Asterisk(*) is not allowed in usernames!")
			Elseif inStr(1,uName,"?") > 0 Then
				Call giveWarn("Question-mark(?) is not allowed in usernames!")
			Elseif inStr(1,uName,"""") > 0 Then
				Call giveWarn("Quote("") is not allowed in usernames!")
			Elseif inStr(1,uName,"<") > 0 Then
				Call giveWarn("Less-than(<) is not allowed in usernames!")
			Elseif inStr(1,uName,">") > 0 Then
				Call giveWarn("Greater-than(>) is not allowed in usernames!")
			Elseif inStr(1,uName,"|") > 0 Then
				Call giveWarn("Vertical-line(|) is not allowed in usernames!")
			Else
				prog = 2
			End If
		End If
	Loop
	
	'Password
	Do while prog = 2
		pWord = inputbox("Create a password for " & uName, title)
		If pWord = "" Then
			eba = msgbox("Continue without a password?", 4+48+4096, title)
			If eba = vbYes Then
				prog = 3
			End If
		Else
			temp(0) = inputbox("Confirm password:", title)
			If temp(0) = pword Then
				prog = 3
			Else
				Call giveWarn("Passwords did not match.")
			End If
		End If
	Loop
	
	'Config
	Call giveNote("Your User Account has been set up! Now lets take a look at your preferences.")
	
	eba = msgbox("Do you want to enable this option?" & line & "Logging | Logs important events to the EBA.log file.",4+32,title)
	If eba = vbYes Then
		Call write(dataLoc & "\settings\logging.ebacmd","true")
	Else
		Call write(dataLoc & "\settings\logging.ebacmd","false")
	End If
	
	eba = msgbox("Do you want to enable this option?" & line & "SaveLogin | Saves your login status when you exit EBA Command Center.",4+32,title)
	If eba = vbYes Then
		Call write(dataLoc & "\settings\saveLogin.ebacmd","true")
	Else
		Call write(dataLoc & "\settings\saveLogin.ebacmd","false")
	End If
	
	Call giveNote("You can edit more settings in the Config menu. Advanced settings can be found in the Windows Registry (at " & regLoc & "). Be sure to check out the EBA Wiki for more details.")
	
	Call write(dataLoc & "\Users\" & uName & ".ebacmd",pWord & vblf & "owner")
	Call log("Critical Alert | New Admin Account created: " & uName)
	Call write(dataLoc & "\startupType.ebacmd","normal")
	Call giveNote("EBA Command Center has been set up! EBA Command Center will now load.")
	Call endOp("r")
End Sub
Sub modeInstall
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Installation"
	Call checkWScript
	If isAdmin = False Then Call endOp("fa")
	
	Call clearTemps
	
	'Search Legacy
	If foldExists("C:\EBA") Or foldExists("C:\EBA-Installer") Then isInstalled = True
	If isInstalled = True Then
		Call giveWarn("A legacy EBA Cmd Installation (6.1 and below) was found on this device. Note that when you install EBA Cmd " & ver & ", this version will be uninstalled.")
	End If
	
	'Installation
	eba = msgbox("Thanks for choosing EBA Command Center! Are you trying to INSTALL version " & ver & "?",4+64,title)
	If eba = vbNo Then
		Call giveNote("The EBA Installer will now close.")
		Call endOp("c")
	End If
	
	'Install Directory
	programLoc = inputbox("We're ready to install EBA Command Center! Where would you like to install to?",title,programLoc)
	If Not foldExists(fs.GetParentFolderName(programLoc)) Then
		Call giveError("The directory does not exist: " & fs.GetParentFolderName(programLoc),"DIRECTORY_NOT_FOUND")
		Call endOp("c")
	End If
	
	'Edition
	prog = 0
	Do until prog = 1
		eba = UCase(inputbox("If you have an EBA Key, enter it below. If you want to install BASIC, type 'BASIC'. For more details, type 'HELP'",title,"BASIC"))
		If eba = "BASIC" Then
			installEdit = "basic"
			ebaKey = "BASIC"
			prog = 1
		Elseif eba = "HELP" Then
			msgbox "EBA Command Center Basic contains:" & line & "Creation of File, Url, and Exe commands" & vblf & "1 User Account" & vblf & "All built-in commands" & vblf & "Export/Import" & vblf & "EBA Automatic Repair and EBA StartFail recovery options" & vblf & "Reinstall recovery options" & line & "Recommended for Beginners",64+4096,title
			msgbox "EBA Command Center Pro contains:" & line & "Everything from EBA Basic" & vblf & "3 User Accounts" & vblf & "No Ads" & vblf & "Creation of Cmd and Short commands." & vblf & "Backups" & vblf & line & "Recommended for Shared Computers/Developers",64+4096,title
			msgbox "EBA Command Center Enterprise contains:" & line & "Everything from EBA Basic and EBA Pro" & vblf & "100 User Accounts" & vblf & line & "Recommended for Businesses",64+4096,title
			eba = msgbox("Would you like to purchase a copy of EBA Pro or EBA Enterprise?",4+32+4096,title)
			If eba = vbYes Then
				Set objShort = cmd.CreateShortcut("C:\eba.temp.url")
				With objShort
					.TargetPath = "https://ethanblaisalarms.github.io/cmd/purchase"
					.Save
				End With
				cmd.run "C:\eba.temp.url"
				fs.DeleteFile("C:\eba.temp.url")
			End If
		Else
			Call getKeys("pro")
			If InStr(data,eba & ",") > 0 Then
				ebaKey = eba
				installEdit = "pro"
				prog = 1
			Else
				Call getKeys("ent")
				If InStr(data,eba & ",") > 0 Then
					ebaKey = eba
					installEdit = "ent"
					prog = 1
				Else
					Call giveError("That EBA Key didnt work. Try again.","INVALID_EBA_KEY")
				End If
			End If
		End If
	Loop
	
	'Confirm
	If installEdit = "basic" Then temp(0) = "Basic"
	If installEdit = "pro" Then temp(0) = "Pro"
	If installEdit = "ent" Then temp(0) = "Enterprise"
	eba = msgbox("Confirm the installation:" & line & "Install directory: " & programLoc & vblf & "Edition: EBA " & temp(0) & vblf & "EBA Key: " & ebaKey,4+32,title)
	If eba = vbNo Then Call endOp("c")
	
	'Registry
	cmd.RegWrite regLoc, ""
	cmd.RegWrite regLoc & "\enableOperationCompletedMenu", enableEndOp, "REG_DWORD"
	cmd.RegWrite regLoc & "\disableErrorHandle", disableErrHandle, "REG_DWORD"
	cmd.RegWrite regLoc & "\enableLegacyOperationCompletedMenu", enableLegacyEndOp, "REG_DWORD"
	cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\installDir", programLoc, "REG_SZ"
	cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\timesToAutoRetryInternetConnection", connectRetry, "REG_DWORD"
	
	'Folders
	delete("C:\EBA")
	delete("C:\EBA-Installer")
	delete(programLoc)
	delete(dataLoc)
	newFolder(programLoc)
	newFolder(dataLoc)
	newFolder(dataLoc & "\Users")
	newFolder(dataLoc & "\Commands")
	newFolder(dataLoc & "\Settings")
	
	'Create Commands
	Call updateCommands
	
	'Data Files
	Call update(dataLoc & "\isLoggedIn.ebacmd","" & vblf & "","")
	Call update(dataLoc & "\settings\logging.ebacmd","true","")
	Call update(dataLoc & "\settings\saveLogin.ebacmd","false","")
	Call update(dataLoc & "\settings\shutdownTimer.ebacmd","10","")
	Call update(dataLoc & "\settings\defaultShutdown.ebacmd","shutdown","")
	Call update(dataLoc & "\secureShutdown.ebacmd","true","")
	Call update(dataLoc & "\ebaKey.ebacmd",ebaKey,"")
	
	'Apply Setup
	If Not fExists(logDir) Then Call log("Created Log File")
	Call log("Installation | Installed EBA Cmd " & ver)
	Call update(dataLoc & "\startupType.ebacmd","firstrun","overwrite")
	
	'Create Icons
	eba = msgbox("Create Desktop and Start Menu icons?",4+32,title)
	If eba = vbYes Then
		Set objShort = cmd.CreateShortcut(desktop & "\EBA Cmd " & ver & ".lnk")
		With objShort
			.TargetPath = programLoc & "\EBA.vbs"
			.IconLocation = "C:\Windows\System32\cmd.exe"
			.Save
		End With
		Set objShort = cmd.CreateShortcut(startMenu & "\EBA Cmd " & ver & ".lnk")
		With objShort
			.TargetPath = programLoc & "\EBA.vbs"
			.IconLocation = "C:\Windows\System32\cmd.exe"
			.Save
		End With
	End If
	
	'Installed!
	eba = msgbox("EBA Command Center finished installing! Do you want to launch EBA Command Center, and perform Initial Setup now?",4+32,title)
	If eba = vbYes Then Call endOp("r")
	Call endOp("c")
End Sub
Sub modeNormal
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Debug"
	Call checkWScript
	
	htmlContent = goOnline("https://ethanblaisalarms.github.io/cmd")
	
	If Not Err.Number = 0 Then
		Err.Clear
		If connectRetry < curConnectRetry Then
			eba = msgbox("We were unable to check for updates. Do you want to try again?",4+48,title)
			If eba = vbYes Then
				Call endOp("r")
			Else
				htmlContent = line & vblf & ver
			End If
		Else
			Call write(dataLoc & "\connect.ebacmd",(curConnectRetry + 1))
			Call write(dataLoc & "\secureShutdown.ebacmd",true)
			Call endOp("fd")
		End If
	End If
	Call write(dataLoc & "\htmlData.ebacmd",htmlContent)
	Call readLines(dataLoc & "\htmlData.ebacmd",4)
	delete(dataLoc & "\htmlData.ebacmd")
	curVer = CDbl(lines(4))
	
	Call read(dataLoc & "\ebaKey.ebacmd","u")
	temp(3) = data & ","
	If data = "BASIC" or data = "" Then
		curEdit = "basic"
		title = "EBA " & ver & " | Basic Edition"
	Else
		Call getKeys("pro")
		If InStr(data,temp(3)) > 0 Then
			curEdit = "pro"
			title = "EBA " & ver & " | Professional"
		Else
			Call getKeys("ent")
			If InStr(data,temp(3)) > 0 Then
				curEdit = "ent"
				title = "EBA " & ver & " | Enterprise"
			Else
				curEdit = "basic"
				title = "EBA " & ver & " | Basic Edition"
				
				If connectRetry < curConnectRetry Then
					Call giveWarn("There is something wrong with your EBA Key. This may be caused by a bad internet connected, or your EBA Key is not valid. If you continue to have issues, contact us.")
				Else
					Call write(dataLoc & "\connect.ebacmd",(curConnectRetry + 1))
					Call endOp("fd")
				End If
			End If
		End If
	End If
	If ver < curVer Then
		Call giveNote("There is an update available for EBA Command Center. Download and install this update with the 'update' command." & line & "Current Version: " & ver & vblf & "Latest Version: " & curVer)
	Elseif ver > curVer Then
		Call giveNote("Your using a beta version of EBA Command Center! Be sure to leave feedback!" & line & "Current Version: " & ver & vblf & "Latest Version: " & curVer)
	End If
	
	'Data File Checks
	
	Call dataExists(programLoc & "\EBA.vbs")
	Call dataExists(dataLoc & "\ebaKey.ebacmd")
	Call dataExists(dataLoc & "\Commands\config.ebacmd")
	Call dataExists(dataLoc & "\Commands\end.ebacmd")
	Call dataExists(dataLoc & "\Commands\login.ebacmd")
	
	If Not missFiles = False Then
		skipDo = True
		eba = msgbox("EBA Command Center didn't start correctly." & line & "'ABORT': Exit EBA Command Center." & vblf & "'RETRY': Restart EBA Cmd." & vblf & "'IGNORE': Continue to recovery.",2+16,"EBA Cmd " & ver & " | StartFail")
		If eba = vbAbort Then Call endOp("c")
		If eba = vbRetry Then Call endOp("r")
		If eba = vbIgnore Then
			eba = LCase(inputbox("Select recovery options:" & line & "'START': Bypass this menu and start EBA Command Center" & vblf & "'RETRY': Restart EBA Command Center" & vblf & "'RECOVERY': Start EBA Command Center in Recovery Mode." & vblf & "'AUTO': Start automatic repair.",title))
			If eba = "retry" Then
				Call endOp("r")
			Elseif eba = "recovery" Then
				startupType = "recover"
				skipDo = True
			Elseif eba = "auto" Then
				startupType = "repair"
				skipDo = True
			Elseif eba = "start" Then
				eba = msgbox("Warning:" & line & "EBA Command Center didnt start correctly. We recommend running recovery options instead of starting. Continue anyways?",4+48,title)
				If eba = vbYes Then skipDo = False
			End If
		End If
	End If
	
	If skipDo = False Then		
		Call checkWScript
		Call clearTemps
		
		Call write(dataLoc & "\connect.ebacmd",1)
		
		If Not fExists(logDir) Then Call log("Log File Created")
		
		Call read(dataLoc & "\secureShutdown.ebacmd","l")
		secureShutdown = data
		
		If saveLogin = "false" Then Call write(dataLoc & "\isLoggedIn.ebacmd",vblf)
		
		delete(dataLoc & "\susActivity.ebacmd")
		
		If secureShutdown = "false" Then
			Call giveAlert("EBA Command Center did not shut down without executing shutdown actions. Make sure to shut down EBA Command Center correctly next time.")
			Call endOp("n")
		End If
		
		eba = msgbox("Start EBA Cmd " & ver & "?",4+32,title)
		If eba = vbNo Then Call endOp("c")
		Call log(title & " was launched.")
		'Call write(dataLoc & "\secureShutdown.ebacmd","false")
	End If
	
	Call checkWScript
	
	Do
		If skipDo = True Then Exit Do
		If Not Err.Number = 0 Then
			Call giveError("A critical error occurred within EBA Cmd. Crashing...","WS/" & Err.Number & "?Mode=CriticalError")
			Call endOp("c")
		End If
		
		Call dataExists(programLoc & "\EBA.vbs")
		Call dataExists(dataLoc & "\ebaKey.ebacmd")
		Call dataExists(dataLoc & "\Commands\config.ebacmd")
		Call dataExists(dataLoc & "\Commands\end.ebacmd")
		Call dataExists(dataLoc & "\Commands\login.ebacmd")
		
		If Not missFiles = False Then
			eba = msgbox("A critical error occurred within EBA Command Center. We recommend closing EBA Command Center. Close now?",4+16,title)
			If eba = vbYes Then Call endOp("c")
		End If
		
		Call readLines(dataLoc & "\isLoggedIn.ebacmd",2)
		logIn = lines(1)
		logInType = lines(2)
		If logIn = "" Then
			status = "Not Logged In"
		Else
			status = "Logged In: " & logIn
		End If
		
		'User Input
		If curEdit = "basic" Then msgbox "Thanks for trying out EBA Command Center! You're using EBA Basic! We recommend upgrading your edition of EBA Command Center to unlock more features. You can upgrade with the 'upgrade' command.", 64+4096, title
		eba = LCase(inputbox("Enter Command Below:" & vblf & "EBA" & line & status, title))
		exeValue = "eba.null"
		If eba = "" Then eba = "end"
		If fExists(dataLoc & "\Commands\" & eba & ".ebacmd") Then
			Call readLines(dataLoc & "\Commands\" & eba & ".ebacmd",3)
			If LCase(lines(2)) = "short" Then
				eba = lines(1)
				If fExists(dataLoc & "\Commands\" & lines(1) & ".ebacmd") Then
					Call readLines(dataLoc & "\Commands\" & lines(1) & ".ebacmd",3)
				Else
					Call giveError("That command contains invalid data or is corrupt.","INVALID_COMMAND")
				End If
			End If
			If LCase(lines(3)) = "no" Then
				temp(0) = True
			Elseif logInType = "admin" or logInType = "owner" Then
				temp(0) = True
			Else
				temp(0) = False
			End If
			If LCase(lines(2)) = "exe" Then
				If temp(0) = True Then
					If InStr(lines(1)," ") Then
						exeValue = LCase(Left(lines(1),InStr(lines(1)," ")-1))
						exeValueExt = LCase(Replace(lines(1),exeValue & " ",""))
					Else
						exeValue = LCase(lines(1))
					End If
				Else
					Call giveError("That command requires a quick login to an administrator account. You can do so by running 'login'.","LOGIN_REQUIRED")
				End If
			Elseif LCase(lines(2)) = "cmd" Then
				If temp(0) = True Then
					cmd.run lines(1)
				Else
					Call giveError("That command requires a quick login to an administrator account. You can do so by running 'login'.","LOGIN_REQUIRED")
				End If
			Elseif LCase(lines(2)) = "file" Then
				If temp(0) = True Then
					cmd.run DblQuote(lines(1))
				Else
					Call giveError("That command requires a quick login to an administrator account. You can do so by running 'login'.","LOGIN_REQUIRED")
				End If
			Elseif LCase(lines(2)) = "url" Then
				Set objShort = cmd.CreateShortcut(dataLoc & "\temp.url")
				With objShort
					.TargetPath = lines(1)
					.Save
				End With
				cmd.run DblQuote(dataLoc & "\temp.url")
			Else
				Call giveError("That command contains invalid data or is corrupt.","INVALID_COMMAND")
			End If
		Else
			Call giveError("That command could not be found or is corrupt.","INVALID_COMMAND")
		End If
		Call log("Command Executed: " & eba)
		
		'Execution Values
		If exeValue = "eba.admin" Then
			If isAdmin = False Then
				Call endOp("ra")
			End If
			Call giveNote("EBA Command Center is already running as administrator.")
		Elseif exeValue = "eba.backup" Then
			If Not curEdit = "basic" Then
				eba = msgbox("Your backup will be saved to " & dataLoc & "\backup.ebabackup" & line & "Note that the file at that location will be overwrote. Continue?",4+32+4096,title)
				If eba = vbYes Then
					eba = LCase(inputbox("What type of backup do you want to run?" & line & "'USER': Backs up user accounts." & vblf & "'CMD': Backs up commands." & vblf & "'SETTINGS': Backs up settings.",title))
					If eba = "user" or eba = "cmd" or eba = "settings" Then
						If fExists(dataLoc & "\backup.ebabackup") Then fs.DeleteFile(dataLoc & "\backup.ebabackup")
						Call checkWScript
						If Not fExists(dataLoc & "\backup.zip") Then Call write(dataLoc & "\backup.zip", Chr(80) & Chr(75) & Chr(5) & Chr(6) & String(18, 0))
						temp(0) = fs.GetAbsolutePathName(dataLoc & "\backup.zip")
						If eba = "user" Then
							Set backup1 = objApp.NameSpace(temp(0))
							temp(1) = fs.GetAbsolutePathName(dataLoc & "\Users")
							Set backup2 = objApp.NameSpace(temp(1))
							backup1.CopyHere backup2.items, 4
							If Err.Number = 0 Then
								Call giveNote("Backed up all files in " & dataLoc & "\Users")
							Else
								Call giveError("Backup failed. See WScript Error for more info.","WS/" & Err.Number & "?Mode=BackupError")
							End If
							Call checkWScript
						Elseif eba = "cmd" Then
							Set backup1 = objApp.NameSpace(dataLoc & "\backup.zip")
							temp(1) = fs.GetAbsolutePathName(dataLoc & "\Commands")
							Set backup2 = objApp.NameSpace(temp(1))
							backup1.CopyHere backup2.items, 4
							If Err.Number = 0 Then
								Call giveNote("Backed up all files in " & dataLoc & "\Commands")
							Else
								Call giveError("Backup failed. See WScript Error for more info.","WS/" & Err.Number & "?Mode=BackupError")
							End If
							Call checkWScript
						Elseif eba = "settings" Then
							Set backup1 = objApp.NameSpace(dataLoc & "\backup.zip")
							temp(1) = fs.GetAbsolutePathName(dataLoc & "\Settings")
							Set backup2 = objApp.NameSpace(temp(1))
							backup1.CopyHere backup2.items, 4
							If Err.Number = 0 Then
								Call giveNote("Backed up all files in " & dataLoc & "\Settings")
							Else
								Call giveError("Backup failed. See WScript Error for more info.","WS/" & Err.Number & "?Mode=BackupError")
							End If
							Call checkWScript
						End If
						If fExists(dataLoc & "\backup.zip") Then fs.MoveFile dataLoc & "\backup.zip", dataLoc & "\backup.ebabackup"
					Else
						Call giveWarn("Invalid argument.")
					End If
				End If
			Else
				Call giveError("This feature requires EBA Enterprise! Upgrade with the 'upgrade' command.","INCORRECT_EDITION")
			End If
		Elseif exeValue = "eba.config" Then
			If exeValueExt = "eba.cmd" Then
				eba = "cmd"
			Elseif exeValueExt = "eba.cmdnew" Then
				eba = "cmd"
			Elseif exeValueExt = "eba.cmdedit" Then
				eba = "cmd"
			Elseif exeValueExt = "eba.acc" Then
				eba = "acc"
			Elseif exeValueExt = "eba.accnew" Then
				eba = "acc"
			Elseif exeValueExt = "eba.accedit" Then
				eba = "acc"
			Elseif exeValueExt = "eba.defaultshutdown" Then
				eba = "defaultshutdown"
			Elseif exeValueExt = "eba.logs" Then
				eba = "logs"
			Elseif exeValueExt = "eba.savelogin" Then
				eba = "savelogin"
			Elseif exeValueExt = "eba.shutdowntimer" Then
				eba = "shutdowntimer"
			Elseif exeValueExt = "eba.null" Then
				eba = LCase(inputbox("EBA Config:" & vblf & "EBA > Config" & line & status, title))
			Else
				Call giveError("Unknown Exe Value Extension." & vblf & exeValueExt,"INVALID_EXE_EXT")
			End If
			If eba = "cmd" Then
				If exeValueExt = "eba.cmd" or exeValueExt = "eba.null" Then
					eba = LCase(inputbox("Modify Commands:" & vblf & "EBA > Config > Commands" & line & status, title))
				Elseif exeValueExt = "eba.cmdnew" Then
					eba = "new"
				Elseif exeValueExt = "eba.cmdedit" Then
					eba = "edit"
				Else
					Call giveError("Unknown Error","INVALID_EXE_EXT")
				End If
				If eba = "new" Then
					status = "This is what you will type to execute the command."
					eba = LCase(inputbox("Create Command Below:" & vblf & "EBA > Config > Commands > New" & line & status, title))
					If fExists(dataLoc & "\Commands\" & eba & ".ebacmd") Then
						Call giveError("That command already exists.","DUPLICATE_FILE_DETECTED")
					ElseIf inStr(1,eba,"\") > 0 Then
						Call giveWarn("""\"" is not allowed in command names!")
					Elseif inStr(1,eba,"/") > 0 Then
						Call giveWarn("""/"" is not allowed in command names!")
					Elseif inStr(1,eba,":") > 0 Then
						Call giveWarn(""":"" is not allowed in command names!")
					Elseif inStr(1,eba,"*") > 0 Then
						Call giveWarn("""*"" is not allowed in command names!")
					Elseif inStr(1,eba,"?") > 0 Then
						Call giveWarn("""?"" is not allowed in command names!")
					Elseif inStr(1,eba,"""") > 0 Then
						Call giveWarn("' "" ' is not allowed in command names!")
					Elseif inStr(1,eba,"<") > 0 Then
						Call giveWarn("""<"" is not allowed in command names!")
					Elseif inStr(1,eba,">") > 0 Then
						Call giveWarn(""">"" is not allowed in command names!")
					Elseif inStr(1,eba,"|") > 0 Then
						Call giveWarn("""|"" is not allowed in command names!")
					Else
						temp(0) = false
						temp(3) = eba
						eba = LCase(inputbox("What is the type?" & line & "'CMD': Execute a command" & vblf & "'FILE': Execute a file" & vblf & "'URL': Web shortcut" & vblf & "'SHORT': Shortcut to another command", title))
						If eba = "cmd" Then
							If curEdit = "basic" Then
								Call giveError("Sorry, that feature is only available in EBA Pro! You have EBA Basic.","INCORRECT_EDITION")
							Else
								temp(0) = True
								temp(1) = "cmd"
								temp(2) = LCase(inputbox("Type the command to execute:",title))
							End If
						Elseif eba = "file" Then
							temp(1) = "file"
							temp(2) = LCase(inputbox("Type the target file/folder:",title))
							temp(2) = Replace(temp(2),"""","")
							If fExists(temp(2)) or foldExists(temp(2)) Then
								temp(0) = True
							Else
								Call giveError("The target file was not found.","BAD_DIRECTORY")
							End If
						Elseif eba = "url" Then
							temp(0) = True
							temp(1) = "url"
							temp(2) = LCase(inputbox("Type the URL below. Include https://",title,"https://example.com"))
						Elseif eba = "short" Then
							If curEdit = "basic" Then
								Call giveError("Sorry, that feature is only available in EBA Pro! You have EBA Basic.","INCORRECT_EDITION")
							Else
								temp(1) = "short"
								temp(2) = LCase(inputbox("Type the target command below:",title))
								If fExists(dataLoc & "\Commands\" & temp(2) & ".ebacmd") Then
									temp(0) = True
								Else
									Call giveError("The target command was not found or is corrupt.","INVALID COMMAND")
								End If
							End If
						Elseif eba = "exe" Then
							temp(0) = True
							temp(1) = "exe"
							temp(2) = LCase(inputbox("Type the execution value below:",title))
						End If
						If temp(0) = False Then
							Call giveWarn("The command could not be created.")
						Else
							If temp(1) = "short" Then
								temp(4) = "no"
							Else
								eba = msgbox("Require administrator login to execute?",4+32+4096,title)
								If eba = vbNo Then
									temp(4) = "no"
								Else
									temp(4) = "yes"
								End If
							End If
							eba = msgbox("Confirm the command:" & line & "Name: " & temp(3) & vblf & "Type: " & temp(1) & vblf & "Target: " & temp(2) & vblf & "Login Required: " & temp(4),4+32+4096,title)
							If eba = vbNo Then
								Call giveWarn("Creation of command canceled.")
							Else
								Call log("Command Created: " & temp(3))
								Call write(dataLoc & "\Commands\" & temp(3) & ".ebacmd",temp(2) & vblf & temp(1) & vblf & temp(4) & vblf & "no")
							End If
						End If
					End If
				Elseif eba = "edit" Then
					eba = LCase(inputbox("Enter Command Below:" & vblf & "EBA > Config > Commands > Modify" & line & status, title))
					If fExists(dataLoc & "\Commands\" & eba & ".ebacmd") Then
						temp(1) = eba
						Call readLines(dataLoc & "\Commands\" & eba & ".ebacmd",4)
						temp(0) = True
						If LCase(lines(4)) = "builtin" Then
							eba = msgbox("Warning:" & line & "That is a built-in command. If you modify this command, it could mess up EBA Command Center. Continue?",4+48+4096,title)
							If eba = vbNo Then temp(0) = False
						End If
						If temp(0) = True Then
							eba = LCase(inputbox("What do you want to modify?" & line & "'TARGET': Edit the target" & vblf & "'NAME': Rename the command" & vblf & "'LOGIN': Change login requirements" & vblf & "'DELETE': Delete the command.",title))
							If eba = "target" Then
								temp(2) = "target"
								temp(3) = LCase(inputbox("Enter new target:",title,lines(1)))
								lines(1) = temp(3)
								temp(4) = True
							Elseif eba = "name" Then
								temp(2) = "name"
								temp(3) = LCase(inputbox("Enter new name:",title,temp(1)))
								temp(4) = True
							Elseif eba = "login" Then
								temp(2) = "login"
								temp(3) = msgbox("Require login to execute?",4+32+4096,title)
								If temp(3) = vbNo Then
									temp(3) = "no"
								Else
									temp(3) = "yes"
								End If
								lines(3) = temp(3)
								temp(4) = True
							Elseif eba = "delete" Then
								temp(2) = "delete"
								eba = msgbox("Warning:" & line & "Deleting a command cannot be undone. Delete anyways?",4+48+4096,title)
								If eba = vbYes Then
									fs.DeleteFile(dataLoc & "\Commands\" & temp(1) & ".ebacmd")
									Call log("Command deleted: " & temp(1))
									temp(4) = True
								End If
							End If
							If temp(4) = True Then
								If Not temp(2) = "delete" Then
									eba = msgbox("Confirm command modification:" & line & "Modification: " & temp(2) & vblf & "New Value: " & temp(3),4+32+4096,title)
									If eba = vbYes Then
										If temp(2) = "name" Then
											fs.MoveFile dataLoc & "\Commands\" & temp(1) & ".ebacmd", dataLoc & "\Commands\" & temp(3) & ".ebacmd"
											Call log("Command renamed from " & temp(1) & " to " & temp(3))
										Else
											Call write(dataLoc & "\Commands\" & temp(1) & ".ebacmd",lines(1) & vblf & lines(2) & vblf & lines(3) & vblf & lines(4))
											Call log("Command Modified: " & temp(1))
										End If
									End If
								End If
							Else
								Call giveWarn("The command could not be modified.")
							End If
						End If
					Else
						Call giveError("Command not found.","INVALID_COMMAND")
					End If
				Else
					Call giveError("Config option not found.","INVALID_ARGUMENT")
				End If
			Elseif eba = "acc" or eba = "account" Then
				If exeValueExt = "eba.acc" or exeValueExt = "eba.null" Then
					eba = LCase(inputbox("Modify Accounts:" & vblf & "EBA > Config > Accounts" & line & status, title))
				Elseif exeValueExt = "eba.accnew" Then
					eba = "new"
				Elseif exeValueExt = "eba.accedit" Then
					eba = "edit"
				Else
					Call giveError("Unknown Error","UNKNOWN_ERROR")
				End If
				If eba = "new" Then
					temp(0) = fs.GetFolder(dataLoc & "\Users").Files.Count
					If curEdit = "basic" Then temp(1) = 1
					If curEdit = "pro" Then temp(1) = 3
					If curEdit = "ent" Then temp(1) = 100
					If curEdit = "unk" Then temp(1) = 1
					If temp(0) < temp(1) Then
						eba = inputbox("You are using " & temp(0) & " of " & temp(1) & " accounts." & line & "Create a username:",title)
						uName = eba
						If fExists(dataLoc & "\Users\" & eba & ".ebacmd") Then
							Call giveError("That user already exists.","DUPLICATE_FILE_DETECTED")
						Elseif Len(uName) < 3 Then
							Call giveWarn("That username is too short!")
						Elseif Len(uName) > 15 Then
							Call giveWarn("That username is too long!")
						Elseif inStr(1,uName,"\") > 0 Then
							Call giveWarn("""\"" is not allowed in usernames!")
						Elseif inStr(1,uName,"/") > 0 Then
							Call giveWarn("""/"" is not allowed in usernames!")
						Elseif inStr(1,uName,":") > 0 Then
							Call giveWarn(""":"" is not allowed in usernames!")
						Elseif inStr(1,uName,"*") > 0 Then
							Call giveWarn("""*"" is not allowed in usernames!")
						Elseif inStr(1,uName,"?") > 0 Then
							Call giveWarn("""?"" is not allowed in usernames!")
						Elseif inStr(1,uName,"""") > 0 Then
							Call giveWarn("' "" ' is not allowed in usernames!")
						Elseif inStr(1,uName,"<") > 0 Then
							Call giveWarn("""<"" is not allowed in usernames!")
						Elseif inStr(1,uName,">") > 0 Then
							Call giveWarn(""">"" is not allowed in usernames!")
						Elseif inStr(1,uName,"|") > 0 Then
							Call giveWarn("""|"" is not allowed in usernames!")
						Else
							pWord = inputbox("Create a password for " & uName,title)
							If pWord = "" Then
								eba = msgbox("Continue without a password?",4+48+4096,title)
								If eba = vbYes Then
									eba = msgbox("Make this an administrator account?",4+32+256+4096,title)
									If eba = vbYes Then
										Call write(dataLoc & "\Users\" & uName & ".ebacmd",pWord & vblf & "admin")
										Call log("New administrator account created: " & uName)
									Else
										Call write(dataLoc & "\Users\" & uName & ".ebacmd",pword & vblf & "general")
										Call log("New account created: " & uName)
									End If
								End If
							Elseif Len(pWord) < 8 Then
								Call giveWarn("Password is too short.")
							Elseif Len(pWord) > 30 Then
								Call giveWarn("Password is too long.")
							Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
								Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
							Else
								eba = inputbox("Confirm password:",title)
								If eba = pWord Then
									eba = msgbox("Make this an administrator account?",4+32+256+4096,title)
									If eba = vbYes Then
										Call write(dataLoc & "\Users\" & uName & ".ebacmd",pWord & vblf & "admin")
										Call log("New administrator account created: " & uName)
									Else
										Call write(dataLoc & "\Users\" & uName & ".ebacmd",pword & vblf & "general")
										Call log("New account created: " & uName)
									End If
								Else
									Call giveError("Passwords do not match.","PASSWORDS_NO_MATCH")
								End If
							End If
						End If
					Else
						Call giveError("Your current edition of EBA Command Center has an account limit of " & temp(1) & ". You are using " & temp(0) & " accounts, and cannot add more.","INCORRECT_EDITION")
					End If
				Elseif eba = "edit" Then
					eba = inputbox("Enter the username:",title)
					If fExists(dataLoc & "\Users\" & eba & ".ebacmd") Then
						Call readLines(dataLoc & "\Users\" & eba & ".ebacmd",2)
						temp(0) = eba
						eba = LCase(inputbox("What do you want to modify?" & line & "'PWORD': Change password" & vblf & "'ADMIN': Change admin status" & vblf & "'DELETE': Delete account",title))
						If eba = "pword" Then
							eba = inputbox("Enter current password:",title)
							If eba = lines(1) Then
								pWord = inputbox("Create new password:",title)
								If pWord = "" Then
									eba = msgbox("Continue without a password?",4+48+4096,title)
									If eba = vbYes Then
										Call write(dataLoc & "\Users\" & temp(0) & ".ebacmd",pWord & vblf & lines(2))
										Call log("Password changed for " & temp(0))
									End If
								Elseif Len(pWord) < 8 Then
									Call giveWarn("Password is too short.")
								Elseif Len(pWord) > 30 Then
									Call giveWarn("Password is too long.")
								Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
									Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
								Else
									eba = inputbox("Confirm password:",title)
									If eba = pWord Then
										Call write(dataLoc & "\Users\" & temp(0) & ".ebacmd",pWord & vblf & lines(2))
										Call log("Password changed for " & temp(0))
									Else
										Call giveError("Passwords did not match.","PASSWORD_NO_MATCH")
									End If
								End If
							Else
								Call giveError("Incorrect password.","INCORRECT_PASSWORD")
							End If
						Elseif eba = "admin" Then
							If lines(2) = "owner" Then
								Call giveWarn("That modification cannot be applied to this account. This is the account that was created on setup.")
							Else
								eba = msgbox("Make this account an administrator?",4+32+256+4096,title)
								If eba = vbNo Then
									Call write(dataLoc & "\Users\" & temp(0) & ".ebacmd",lines(1) & vblf & "general")
									Call log("Made " & temp(0) & " a general account.")
								Else
									Call write(dataLoc & "\Users\" & temp(0) & ".ebacmd",lines(1) & vblf & "admin")
									Call log("Made " & temp(0) & " an administrator.")
								End If
							End If
						Elseif eba = "delete" Then
							If lines(2) = "owner" Then
								Call giveWarn("That modification cannot be applied to this account. This is the account that was created on setup.")
							Else
								eba = msgbox("Confirm delete?",4+32+256+4096,title)
								If eba = vbYes Then
									fs.DeleteFile(dataLoc & "\Users\" & temp(0) & ".ebacmd")
									Call log("Account deleted: " & temp(0))
								End If
							End If
						Else
							Call giveError("Config option not found.","INVALID_ARGUMENT")
						End If
					Else
						Call giveError("Username not found.","FILE_NOT_FOUND")
					End If
				Else
					Call giveError("Config option not found.","INVALID_ARGUMENT")
				End If
			Elseif eba = "logs" Then
				eba = msgbox("Logs are set to " & logging & ". Would you like to enable EBA Logs? (EBA Command Center will restart)", 4+32+4096, title)
				If eba = vbYes Then
					Call write(dataLoc & "\settings\logging.ebacmd","true")
					Call log("Logging enabled by " & logIn)
				Else
					Call write(dataLoc & "\settings\logging.ebacmd","false")
					Call log("Logging disabled by " & logIn)
				End If
				Call endOp("r")
			Elseif eba = "savelogin" Then
				eba = msgbox("Save Login are set to " & saveLogin & ". Would you like to enable Save Login? (EBA Command Center will restart)", 4+32+4096, title)
				If eba = vbYes Then
					Call write(dataLoc & "\settings\saveLogin.ebacmd","true")
					Call log("Save Login enabled by " & logIn)
				Else
					Call write(dataLoc & "\settings\saveLogin.ebacmd","false")
					Call log("Save Login disabled by " & logIn)
				End If
				Call endOp("r")
			Elseif eba = "shutdowntimer" Then
				eba = inputbox("Shutdown Timer is currently set to " & shutdownTimer & ". Please set a new value (must be at least 0, and must be an integer). EBA Command Center will restart.",title,10)
				If eba = "" Then eba = 0
				Call checkWscript
				If CInt(eba) > -1 Then
					If Err.Number = 0 Then
						Call write(dataLoc & "\settings\shutdownTimer.ebacmd",eba)
						Call endOp("r")
					Else
						Call giveWarn("A WScript Error occurred while converting that value to an integer. Your settings were not changed.")
					End If
				Else
					Call giveWarn("That value didnt work. " & eba & " is not a positive integer.")
				End If
			Elseif eba = "defaultshutdown" Then
				eba = LCase(inputbox("Default Shutdown Method is currently set to " & defaultShutdown & ". Please set a new value:" & line & "'SHUTDOWN', 'RESTART', or 'HIBERNATE'. EBA Command Center will restart.",title,"shutdown"))
				If eba = "" Then eba = "shutdown"
				If eba = "shutdown" or eba = "restart" or eba = "hibernate" Then
					Call write(dataLoc & "\settings\defaultShutdown.ebacmd",eba)
					Call endOp("r")
				Else
					Call giveError("That value is not valid. Nothing was changed.","INVALID_ARGUMENT")
				End If
			Else
				Call giveError("Config option not found.","INVALID_ARGUMENT")
			End If
		Elseif exeValue = "eba.crash" Then
			wscript.sleep 2500
			msgbox "EBA Command Center just crashed! Please restart EBA Command Center.",16+4096,"EBA Crash Handler"
			Call endOp("c")
		Elseif exeValue = "eba.dev" Then
			If isDev = true Then
				isDev = false
				Call log("Dev mode disabled")
				Call giveWarn("Developer Mode has been disabled. EBA Command Center will now restart.")
				Call endOp("r")
			ElseIf isDev = false Then
				isDev = true
				title = "EBA Command Center - Developer Mode"
				Call log("Dev mode enabled")
				Call giveWarn("Developer Mode has been enabled.")
			End If
		Elseif exeValue = "eba.end" Then
			eba = msgbox("Exit EBA Command Center?",4+32+4096,title)
			If eba = vbYes Then Call endOp("s")
		Elseif exeValue = "eba.error" Then
			Call giveWarn("WScript Errors have been enabled. If you encounter a WScript error, EBA Command Center will crash. To disable WScript Errors, restart EBA Command Center.")
			On Error GoTo 0
		Elseif exeValue = "eba.export" Then
			eba = LCase(inputbox("EBA Config:" & vblf & "EBA > Export" & line & status, title))
			If fExists(dataLoc & "\Commands\" & eba & ".ebacmd") Then
				temp(0) = eba
				eba = inputbox("Where do you want the exported file?",title,desktop)
				If foldExists(eba) Then
					Call readLines(dataLoc & "\Commands\" & temp(0) & ".ebacmd",3)
					Call write(eba & "\EBA_Export.ebaimport","Type: Command" & vblf & temp(0) & vblf & lines(2) & vblf & lines(1) & vblf & lines(3))
					Call log("Command Exported: " & temp(0))
				Else
					Call giveError("Cannot export to the given location.","BAD_DIRECTORY")
				End If
			Else
				Call giveError("Command does not exist.","INVALID_COMMAND")
			End If
		Elseif exeValue = "eba.help" Then
			Call giveNote("The online tutorial is available at:" & vblf & "https://sites.google.com/view/ebatools/home/cmd/support")
		Elseif exeValue = "eba.import" Then
			importData = inputbox("Enter the path of the file you want to import.",title)
			importData = Replace(importData,"""","")
			If fExists(importData) Then
				Call checkImports
			Else
				Call giveError("Path not found.","FILE_NOT_FOUND")
			End If
		Elseif exeValue = "eba.login" Then
			uName = inputbox("Enter your username:",title)
			If fExists(dataLoc & "\Users\" & uName & ".ebacmd") Then
				Call readLines(dataLoc & "\Users\" & uName & ".ebacmd",2)
				If Not lines(1) = "" Then
					pWord = inputbox("Enter the password:",title)
					If pWord = lines(1) Then
						Call log("Logged in: " & uName)
						Call giveNote("Logged in as " & uName)
						Call write(dataLoc & "\isLoggedIn.ebacmd",uName & vblf & lines(2))
					Else
						Call log("Failed to log in: " & uName)
						Call giveError("Incorrect Password.","INCORRECT_PASSWORD")
					End If
				Else
					Call log("Logged in: " & uName)
					Call giveNote("Logged in as " & uName)
					Call write(dataLoc & "\isLoggedIn.ebacmd",uName & vblf & lines(2))
				End If
			Else
				Call giveError("Username not found.","USERNAME_NOT_FOUNT")
			End If
		Elseif exeValue = "eba.logout" Then
			Call write(dataLoc & "\isLoggedIn.ebacmd","" & vblf & "")
			Call log("Logged out all accounts")
			Call giveNote("Logged out.")
		Elseif exeValue = "eba.null" Then
			exeValue = "eba.null"
		Elseif exeValue = "eba.read" Then
			If isDev = false Then
				Call giveError("This command can only be ran in EBA Developer Mode!","DEV_DISABLE")
			Else
				eba = inputbox("EBA > Read", title)
				If fExists(eba) Then
					Call read(eba,"n")
					Call log("File read: " & eba)
					msgbox "EBA > Read > " & eba & line & data,4096,title
				Else
					Call log("Failed to read " & eba)
					Call giveError("File " & eba & " not found!","FILE_NOT_FOUND")
				End If
			End If
		Elseif exeValue = "eba.refresh" Then
			If isDev = false Then
				Call giveError("This command can only be used in EBA Developer Mode!","DEV_DISABLED")
			Else
				eba = msgbox("EBA Command Center will restart and open in reinstall mode.", 48+4096, title)
				Call write(dataLoc & "\startupType.ebacmd","refresh")
				Call endOp("r")
			End If
		Elseif exeValue = "eba.restart" Then
			Call endOp("r")
		Elseif exeValue = "eba.reset" Then
			eba = msgbox("Are you sure you want to reset your PC?",4+48,title)
			If eba = vbYes Then
				eba = msgbox("This cannot be undone. Resetting your PC will uninstall all apps, reset all settings, and delete your files! Proceed?",4+48,title)
				If eba = vbYes Then
					cmd.run "systemreset"
					Call giveNote("Your PC is being reset. Follow all on-screen prompts. Press OK to cancel.",48,title)
				End If
			End If
		Elseif exeValue = "sys.run" Then
			eba = inputbox("Please enter the file, folder, or command you would like to execute:", title)
			If fExists(eba) Then
				cmd.run DblQuote(eba)
				Call log("File Executed: " & eba)
			Elseif foldExists(eba) Then
				cmd.run DblQuote(eba)
				Call log("Folder Opened: " & eba)
			Else
				cmd.run eba
				Call log("Command Executed: " & eba)
			End If
		Elseif exeValue = "sys.shutdown" Then
			If exeValueExt = "eba.null" Or exeValueExt = "eba.default" Then
				eba = msgbox("Are you sure you want to " & defaultShutdown & " your PC? Make sure you save any unsaved data first!", 4+32+4096, title)
				If eba = vbYes Then
					Call shutdown(defaultShutdown)
				End If
			Elseif exeValueExt = "eba.shutdown" Then
				eba = msgbox("Are you sure you want to shutdown your PC? All unsaved data will be lost!", 4+32+4096, title)
				If eba = vbYes Then
					Call shutdown("shutdown")
				End If
			Elseif exeValueExt = "eba.restart" Then
				eba = msgbox("Are you sure you want to restart your PC? All unsaved data will be lost!", 4+32+4096, title)
				If eba = vbYes Then
					Call shutdown("restart")
				End If
			Elseif exeValueExt = "eba.hibernate" Then
				eba = msgbox("Are you sure you want to hibernate your PC? We recommend saving unsaved data first!", 4+32+4096, title)
				If eba = vbYes Then
					Call shutdown("hibernate")
				End If
			Else
				Call giveError("Unknown Exe Value Extension.","UNKNOWN_ERROR")
			End If
		Elseif exeValue = "eba.uninstall" Then
			If isDev = false Then
				Call giveError("This command can only be ran in EBA Developer Mode!","UNKNOWN_ERROR")
			Else
				eba = msgbox("Warning:" & line & "This will unistall EBA Command Center completely! Your EBA Command Center data will be erased! Uninstallation will require a system restart. Continue?", 4+48+4096, title)
				Call addWarn
				If eba = vbYes Then
					fs.CopyFile scriptLoc, startup & "\uninstallEBA.vbs"
					Call giveWarn("EBA Command Center has been uninstalled. You will need to restart to finish uninstallation")
					Call endOp("c")
				End If
				Call giveNote("Uninstallation canceled!")
			End If
		Elseif exeValue = "eba.upgrade" Then
			eba = LCase(inputbox("Upgrade options:" & line & "'BUY': Visit the website to buy a new EBA Key." & vblf & "'KEY': Change your EBA Key.",title))
			If eba = "buy" Then
				Set objShort = cmd.CreateShortcut(dataLoc & "\eba.temp.url")
				With objShort
					.TargetPath = "https://ethanblaisalarms.github.io/cmd/purchase"
					.Save
				End With
				cmd.run DblQuote(dataLoc & "\eba.temp.url")
				fs.DeleteFile(dataLoc & "\eba.temp.url")
				Call giveNote("You've been directed to our website to purchase your EBA Key.")
			Elseif eba = "key" Then
				ebaKey = ""
				eba = UCase(inputbox("Enter your EBA Key",title,"XXX-EBA-XXXXX-XX"))
				Call getKeys("pro")
				If eba = "" Then
					Call giveWarn("Canceled.")
				Elseif InStr(data,eba & ",") > 0 Then
					ebaKey = eba
				Else
					Call getKeys("ent")
					If InStr(data,eba & ",") > 0 Then
						ebaKey = eba
					Else
						Call giveError("That EBA Key did not work. Please ensure you typed the code correctly.","")
					End If
				End If
				If Not ebaKey = "" Then
					Call write(dataLoc & "\ebaKey.ebacmd",ebaKey)
				End If
			End If
		Elseif exeValue = "eba.version" Then
			If curEdit = "basic" Then temp(0) = "Basic"
			If curEdit = "pro" Then temp(0) = "Pro"
			If curEdit = "ent" Then temp(0) = "Enterprise"
			If curEdit = "unk" Then temp(0) = "Basic"
			Call read(dataLoc & "\ebaKey.ebacmd","u")
			msgbox "EBA Command Center:" & line & "Version: " & ver & vblf & "Edition: EBA " & temp(0) & vblf & "EBA Key: " & data & vblf & "Installed in: " & programLoc,64+4096,title
		Elseif exeValue = "eba.write" Then
			If isDev = false Then
				Call giveError("This command can only be ran in EBA Developer Mode!","")
			Else
				eba = inputbox("EBA > Write", title)
				If fExists(eba) Then
					temp(0) = eba
					eba = inputbox("EBA > Write > " & eba,title)
					If Lcase(eba) = "cancel" Then
						Call giveNote("Operation Canceled")
					Else
						Call log("Wrote data to " & temp(0) & ": " & eba)
						Call write(temp(0),eba)
					End If
				Else
					Call log("Failed to write to " & eba)
					Call giveError("File " & eba & " not found!","")
				End If
			End If
		Else
			Call giveError("The Execution Value is not valid." & vblf & exeValue,"")
		End If
		Call endOp("n")
	Loop
End Sub
Sub modeRecover
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Recovery"
	Call checkWScript
	
	Call giveWarn("EBA Command Center has launched into Recovery Mode.")
	
	temp(9) = enableLegacyEndOp
	enableLegacyEndOp = 1
	
	Do
		eba = LCase(inputbox("Enter Command Below:" & line & "Path: EBA > Recovery" & vblf & "Not Logged In",title))
		If eba = "repair" Then
			Call giveError("EBA File Repair has been removed. It has been replaced with EBA Automatic Repair.","EBA_FILE_REPAIR_REPLACED")
		Elseif eba = "startup" Then
			eba = LCase(inputbox("Enter a startupType:",title))
			Call write(dataLoc & "\startupType.ebacmd",eba)
		Elseif eba = "auto" Then
			startupType = "repair"
			Exit Do
		Elseif eba = "normal" Then
			startupType = "normal"
			Exit Do
		Elseif eba = "refresh" Then
			startupType = "refresh"
			Call write(dataLoc & "\startupType.ebacmd","refresh")
			Exit Sub
		Elseif eba = "" Then
			eba = msgbox("Exit EBA Cmd?",4+32,title)
			If eba = vbYes Then
				Call endOp("f")
			End If
		Else
			Call giveError("Unrecognized command: " & eba,"INVALID_RECOVERY_COMMAND")
		End If
		Call endOp("n")
	Loop
	enableLegacyEndOp = temp(9)
End Sub
Sub modeRefresh
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Reinstallation"
	Call checkWScript
	If isAdmin = False Then Call endOp("fa")
	
	eba = msgbox("You are about to refresh EBA Command Center. Refreshing will create a clean install of EBA Command Center. You can choose what data you would like to keep on the next screen. Continue?",4+48,title)
	If eba = vbNo Then
		Call write(dataLoc & "\startupType.ebacmd","normal")
		Call endOp("rd")
	End If
	
	temp(0) = False
	temp(1) = False
	temp(2) = False
	temp(3) = False
	
	eba = msgbox("Do you want to keep this data:" & line & "Commands",4+32,title)
	If eba = vbNo Then
		temp(0) = False
	Else
		temp(0) = True
	End If
	
	eba = msgbox("Do you want to keep this data:" & line & "Users",4+32,title)
	If eba = vbNo Then
		temp(1) = False
	Else
		temp(1) = True
	End If
	
	eba = msgbox("Do you want to keep this data:" & line & "Settings",4+32,title)
	If eba = vbNo Then
		temp(2) = False
	Else
		temp(2) = True
	End If
	
	eba = msgbox("Data you selected to keep:" & line & "EBA Cmd: True" & vblf & "EBA Registry: " & temp(2) & vblf & "Commands: " & temp(0) & vblf & "Users: " & temp(1) & vblf & "Settings: " & temp(2) & vblf & "Other: False" & line & "Are you sure you want to refresh EBA Command Center using the settings above? This cannot be undone!",4+48,title)
	If eba = vbNo Then
		Call write(dataLoc & "\startupType.ebacmd","normal")
		Call endOp("rd")
	End If
	
	Do
		temp(4) = inputbox("Where do you want to install EBA Command Center?",programLoc)
		If Not foldExists(fs.GetParentFolderName(temp(4))) Then
			Call giveError("The directory does not exist: " & fs.GetParentFolderName(programLoc),"DIRECTORY_NOT_FOUND")
		Else
			Exit Do
		End If
	Loop
	
	'Prepare to refresh
	fs.MoveFile scriptLoc, "C:\eba.temp"
	delete(programLoc)
	programLoc = temp(4)
	
	newFolder(programLoc)
	fs.MoveFile "C:\eba.temp", programLoc & "\EBA.vbs"
	
	'Customized
	If temp(0) = False Then
		delete(dataLoc & "\Commands")
	End If
	
	If temp(1) = False Then
		delete(dataLoc & "\Users")
	End If
	
	If temp(2) = False Then
		cmd.RegWrite regLoc, ""
		cmd.RegWrite regLoc & "\enableOperationCompletedMenu", 1, "REG_DWORD"
		cmd.RegWrite regLoc & "\disableErrorHandle", 0, "REG_DWORD"
		cmd.RegWrite regLoc & "\enableLegacyOperationCompletedMenu", 0, "REG_DWORD"
		cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\installDir", programLoc, "REG_SZ"
		cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\timesToAutoRetryInternetConnection", 5, "REG_DWORD"
		
		delete(dataLoc & "\Settings")
	End If
	
	'Folders
	newFolder(dataLoc)
	newFolder(dataLoc & "\Users")
	newFolder(dataLoc & "\Commands")
	newFolder(dataLoc & "\Settings")
	
	'Create Command Files
	Call updateCommands
	
	'Data Files
	Call update(dataLoc & "\isLoggedIn.ebacmd","" & vblf & "","overwrite")
	Call update(dataLoc & "\settings\logging.ebacmd","true","")
	Call update(dataLoc & "\settings\saveLogin.ebacmd","false","")
	Call update(dataLoc & "\settings\shutdownTimer.ebacmd","10","")
	Call update(dataLoc & "\settings\defaultShutdown.ebacmd","shutdown","")
	Call update(dataLoc & "\secureShutdown.ebacmd","true","overwrite")
	Call update(dataLoc & "\ebaKey.ebacmd",ebaKey,"")
	
	'Apply Setup
	If Not fExists(logDir) Then Call log("Log File Created")
	Call log("Critical Alert | EBA Command Center was refreshed.")
	
	'Create Icons
	eba = msgbox("Create Desktop and Start Menu icons?",4+32,title)
	If eba = vbYes Then
		Set objShort = cmd.CreateShortcut(desktop & "\EBA Cmd " & ver & ".lnk")
		With objShort
			.TargetPath = programLoc & "\EBA.vbs"
			.IconLocation = "C:\Windows\System32\cmd.exe"
			.Save
		End With
		Set objShort = cmd.CreateShortcut(startMenu & "\EBA Cmd " & ver & ".lnk")
		With objShort
			.TargetPath = programLoc & "\EBA.vbs"
			.IconLocation = "C:\Windows\System32\cmd.exe"
			.Save
		End With
	End If
	
	If temp(1) = False Then
		Call update(dataLoc & "\startupType.ebacmd","firstrun","overwrite")
		Call giveNote("EBA Command Center was refreshed. You'll need to run Initial Setup again (user accounts were erased!)")
		Call endOp("c")
	Else
		Call update(dataLoc & "\startupType.ebacmd","normal","overwrite")
		Call giveNote("EBA Command Center was refreshed.")
		Call endOp("c")
	End If
End Sub
Sub modeRepair
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Automatic Repair"
	Call checkWScript
	
	temp(9) = enableLegacyEndOp
	enableLegacyEndOp = 1
	
	eba = msgbox("Are you sure you want to perform Automatic Repair? This will reset your preferences. You may need to re-add your EBA Key.",4+48,title)
	
	If eba = vbNo Then
		Call endOp("r")
	Else
		If programLoc = scriptDir Then
			newFolder(dataLoc)
			newFolder(dataLoc & "\Users")
			newFolder(dataLoc & "\Commands")
			newFolder(dataLoc & "\Settings")
			If foldExists(dataLoc) Then
				Call updateCommands
				Call update(dataLoc & "\ebaKey.ebacmd","BASIC","overwrite")
				Call update(dataLoc & "\isLoggedIn.ebacmd","" & vblf & "","overwrite")
				Call update(dataLoc & "\settings\logging.ebacmd","true","overwrite")
				Call update(dataLoc & "\settings\saveLogin.ebacmd","false","overwrite")
				Call update(dataLoc & "\settings\shutdownTimer.ebacmd","10","overwrite")
				Call update(dataLoc & "\settings\defaultShutdown.ebacmd","shutdown","overwrite")
				Call update(dataLoc & "\secureShutdown.ebacmd","true","overwrite")
				Call update(dataLoc & "\startupType.ebacmd","firstrepair","overwrite")
				Call giveNote("Automatic repair has completed. EBA Command Center will now restart.")
				Call endOp("r")
			Else
				Call giveError("EBA Automatic Repair failed for an unknown reason. Please try again later.","AUTOMATIC_REPAIR_FAILED_TO_CREATE_OR_FIND_APPDATA_FOLDER")
				Call endOp("r")
			End If
		Else
			Call giveError("EBA Automatic Repai failed because EBA Command Center is running from the installer.","RUNNING_FROM_INSTALLER")
			Call endOp("r")
		End If
	End If
	
	enableLegacyEndOp = temp(9)
End Sub
Sub modeUninstall
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Uninstallation"
	Call checkWScript
	
	If isAdmin = False Then
		Call giveWarn("To continue with uninstallation, EBA Command Center will run as administrator.")
		Call endOp("fa")
	End If
	
	eba = msgbox("EBA Command Center is ready to uninstall. Do you want to uninstall now? This cannot be undon, and your data will be lost!",4+48,title)
	If eba = vbNo Then
		Call giveNote("Your EBA Command Center data has been restored. EBA Command Center will now close.")
	Else
		delete(programLoc)
		delete(dataLoc)
		cmd.RegDelete("HKLM\SOFTWARE\EBA-Cmd")
		
		Call giveNote("EBA Command Center has been uninstalled.")
	End If
	delete(scriptLoc)
	
	enableLegacyEndOp = 1
	Call endOp("n")
	Call endOp("c")
End Sub
Sub modeUpdate
	On Error Resume Next
	title = "EBA Cmd " & ver & " | Update"
	Call checkWScript
	If isAdmin = False Then Call endOp("fa")
	
	eba = msgbox("EBA Command Center is installed at " & programLoc & line & "Do you want to update EBA Command Center now?",4+32,title)
	If eba = vbNo Then Call endOp("c")
	
	'Registry
	cmd.RegWrite regLoc, ""
	cmd.RegWrite regLoc & "\enableOperationCompletedMenu", enableEndOp, "REG_DWORD"
	cmd.RegWrite regLoc & "\disableErrorHandle", disableErrHandle, "REG_DWORD"
	cmd.RegWrite regLoc & "\enableLegacyOperationCompletedMenu", enableLegacyEndOp, "REG_DWORD"
	cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\installDir", programLoc, "REG_SZ"
	cmd.RegWrite "HKLM\SOFTWARE\EBA-Cmd\timesToAutoRetryInternetConnection", connectRetry, "REG_DWORD"
	
	'Folders
	newFolder(programLoc)
	newFolder(dataLoc)
	newFolder(dataLoc & "\Users")
	newFolder(dataLoc & "\Commands")
	newFolder(dataLoc & "\Settings")
	delete(programLoc & "\Plugins")
	
	'Create Commands
	Call updateCommands
	
	'Data Files
	Call update(dataLoc & "\isLoggedIn.ebacmd","" & vblf & "","")
	Call update(dataLoc & "\settings\logging.ebacmd","true","")
	Call update(dataLoc & "\settings\saveLogin.ebacmd","false","")
	Call update(dataLoc & "\settings\shutdownTimer.ebacmd","10","")
	Call update(dataLoc & "\settings\defaultShutdown.ebacmd","shutdown","")
	Call update(dataLoc & "\secureShutdown.ebacmd","true","")
	Call update(dataLoc & "\ebaKey.ebacmd",ebaKey,"")
	
	'Apply Setup
	If Not fExists(logDir) Then Call log("Created Log File")
	Call log("Installation | Updated to EBA Cmd " & ver)
	Call update(dataLoc & "\startupType.ebacmd","normal","overwrite")
	
	'Update Complete
	Call giveNote("EBA Command Center was updated to version " & ver)
	
	Call endOp("s")
End Sub




'Subs
Sub addError
	On Error Resume Next
	count(3) = count(3) + 1
End Sub
Sub addNote
	On Error Resume Next
	On Error Resume Next
	count(1) = count(1) + 1
End Sub
Sub addWarn
	On Error Resume Next
	count(2) = count(2) + 1
End Sub
Sub append(dir,writeData)
	On Error Resume Next
	If fExists(dir) Then
		Set sys = fs.OpenTextFile (dir, 8)
		sys.WriteLine writeData
		sys.Close
	Elseif foldExists(fs.GetParentFolderName(dir)) Then
		Set sys = fs.CreateTextFile (dir, 8)
		sys.WriteLine writeData
		sys.Close
	Else
		Call giveError("Given file not found: " & dir,"BAD_FILE_DIRECTORY")
	End If
End Sub
Sub checkImports
	On Error Resume Next
	If LCase(Right(importData, 10)) = ".ebaimport" Or LCase(Right(importData, 10)) = ".ebabackup" Then
		If LCase(Right(importData, 10)) = ".ebaimport" Then
			Call readLines(importData,1)
			If lines(1) = "Type: Startup Key" Then
				Call readLines(importData,2)
				If lines(2) = "Data: eba.recovery" Then
					eba = msgbox("Start EBA Command Center in recovery mode?",4+32,title)
					If eba = vbYes Then startupType = "recover"
				Else
					Call giveError("Something is wrong with that file. EBA Command Center couldn't read it or couldn't understand its contents: " & importData,"INVALID_STARTUP_KEY")
				End If
			Elseif lines(1) = "Type: Command" Then
				Call readLines(importData,5)
				eba = msgbox("Do you want to import this command?" & line & "Name: " & lines(2) & vblf & "Type: " & lines(3) & vblf & "Target: " & lines(4) & vblf & "Require Login: " & lines(5),4+32,title)
				If eba = vbYes Then
					If fExists(dataLoc & "\Commands\" & lines(2) & ".ebacmd") Then
						Call giveError("Import failed. File already exists: " & dataLoc & "\Commands\" & lines(2) & ".ebacmd","COMMAND_ALREADY_EXISTS")
					Else
						fileDir = dataLoc & "\Commands\" & lines(2) & ".ebacmd"
						Call append(fileDir,lines(4))
						Call append(fileDir,lines(3))
						Call append(fileDir,lines(5))
						Call endOp("n")
					End If
				End If
			Else
				Call giveError("Something is wrong with that file. EBA Command Center couldn't read it or couldn't understand its contents: " & importData,"INVALID_IMPORT_FILE")
			End If
		Elseif eba = vbYes And LCase(Right(importData, 10)) = ".ebabackup" Then
			eba = msgbox("Do you want to import the contents of this backup file?", 4+32, title)
			If eba = vbYes Then
				eba = LCase(inputbox("EBA Command Center could not figure out this backup file type. What is it?" & line & "'USER': Backed up user accounts." & vblf & "'CMD': Backed up commands." & vblf & "'SETTINGS': Backed up settings.",title))
				If eba = "user" or eba = "cmd" or eba = "settings" Then
					Call checkWScript
					fs.CopyFile importData, importData & ".zip"
					importData = importData & ".zip"
					If eba = "user" Then
						Set backup1 = objApp.NameSpace(dataLoc & "\Users")
						Set backup2 = objApp.NameSpace(importData)
						backup1.CopyHere(backup2.Items)
						If Err.Number = 0 Then
							Call giveNote("Restored files to " & dataLoc & "\Users")
						Else
							Call giveError("Restore failed. See WScript Error for more info.","WS/" & Err.Number)
						End If
						Call checkWScript
					Elseif eba = "cmd" Then
						Set backup1 = objApp.NameSpace(dataLoc & "\Commands")
						Set backup2 = objApp.NameSpace(importData)
						backup1.CopyHere(backup2.Items)
						If Err.Number = 0 Then
							Call giveNote("Restored files to " & dataLoc & "\Commands")
						Else
							Call giveError("Restore failed. See WScript Error for more info.","WS/" & Err.Number)
						End If
						Call checkWScript
					Elseif eba = "settings" Then
						Set backup1 = objApp.NameSpace(dataLoc & "\Settings")
						Set backup2 = objApp.NameSpace(importData)
						backup1.CopyHere(backup2.Items)
						If Err.Number = 0 Then
							Call giveNote("Restored files to " & dataLoc & "\Settings")
						Else
							Call giveError("Restore failed. See WScript Error for more info.","WS/" & Err.Number)
						End If
						Call checkWScript
					End If
					fs.DeleteFile importData
				Else
					Call giveWarn("Argument not valid.")
				End If
			End If
		End If
	Elseif importData = "" Then
		importData = False
	Else
		Call giveError("Something is wrong with your imported file. EBA Command Center cannot import this file." & line & importData,"EXT_NOT_EBAIMPORT_OR_EBABACKUP")
	End If
End Sub
Sub checkWScript
	On Error Resume Next
	If Not Err.Number = 0 Then
		temp(9) = Err.Description
		If Err.Number = -2147024894 Then
			temp(9) = "Something went wrong accessing a file/registry key on your system."
		Elseif Err.Number = -2147024891 Then
			temp(9) = "Failed to access system registry."
		Elseif Err.Number = -2147483638 Then
			temp(9) = "Failed to download data from the EBA Website."
		Elseif Err.Number = 70 Then
			temp(9) = "EBA Command Center failed to access a file because your system denied access. The file might be in use."
		Else
			temp(9) = temp(9) & " (EBA Cmd did not recognize this error)."
		End If
		Call giveError("A WScript Error occurred during operation " & (count(0) + 1) & line & "Description: " & temp(9) & line & "Dev Description: " & Err.Description,"WS/" & Err.Number)
	End If
	Err.Clear
End Sub
Sub clearCounts
	On Error Resume Next
	For forVar = 1 to 3
		count(forVar) = 0
	Next
End Sub
Sub clearLines
	On Error Resume Next
	For forVar = 0 to 30
		lines(forVar) = False
	Next
End Sub
Sub clearTemps
	On Error Resume Next
	For forVar = 0 to 9
		temp(forVar) = False
	Next
	exeValue = "eba.null"
	exeValueExt = "eba.null"
End Sub
Sub dataExists(dir)
	On Error Resume Next
	If Not fExists(dir) Then
		missFiles = dir
	End If
End Sub
Sub endOp(arg)
	On Error Resume Next
	
	'Crash
	If arg = "c" Then wscript.quit
	
	Call checkWScript
	
	'Force Shutdown
	If arg = "f" Then
		Call write(dataLoc & "\secureShutdown.ebacmd","true")
		Call log("EBA Command Center was forced to shut down")
		wscript.quit
	End If
	
	'Force Restart as Admin
	If arg = "fa" Then
		objApp.ShellExecute "wscript.exe", DblQuote(scriptLoc), "", "runas", 1
		wscript.quit
	End If
	
	'Force Restart at Directory
	If arg = "fd" Then
		cmd.run DblQuote(scriptLoc)
		wscript.quit
	End If
	
	'Operation Complete
	count(0) = count(0) + 1
	If enableEndOp = 1 Then
		If enableLegacyEndOp = 1 Then
			msgbox "Operation " & count(0) & " Completed with " & count(3) & " errors, " & count(2) & " warnings, and " & count(1) & " notices.",64,title
		Else
			msgbox "Operation " & count(0) & " Completed:" & line & "Errors: " & count(3) & vblf & "Warnings: " & count(2) & vblf & "Notices: " & count(1),64,title
		End If
	End If
	Call clearCounts
	Call clearLines
	Call clearTemps
	If count(4) >= 30 Then Call write(dataLoc & "\susActivity.ebacmd","")
	
	'Shutdown
	If arg = "s" Then
		Call write(dataLoc & "\secureShutdown.ebacmd","true")
		Call log("EBA Command Center was shut down.")
		wscript.quit
	End If
	
	'Restart
	If arg = "r" Then
		Call write(dataLoc & "\secureShutdown.ebacmd","true")
		Call log("EBA Command Center restarted.")
		cmd.run DblQuote(programLoc & "\EBA.vbs")
		wscript.quit
	End If
	
	'Restart as Admin
	If arg = "ra" Then
		Call write(dataLoc & "\secureShutdown.ebacmd","true")
		Call endOp("fa")
	End If
	
	'Restart At Directory
	If arg = "rd" Then
		Call write(dataLoc & "\secureShutdown.ebacmd","true")
		cmd.run DblQuote(scriptLoc)
		Wscript.quit
	End If
End Sub
Sub getKeys(edition)
	On Error Resume Next
	Call checkWScript
	htmlContent = goOnline("https://ethanblaisalarms.github.io/cmd/auth/" & edition & ".txt")
	If Not Err.Number = 0 Then
		Call addWarn
		If Not startupType = "normal" Then
			Call giveError("We could not get the EBA Keys from the EBA Server. Try again later.","NO_INTERNET_CONNECTION")
		Else
			If connectRetry < curConnectRetry Then
				eba = msgbox("We were unable to download EBA Keys. Do you want to try again?",4+48,title)
				If eba = vbYes Then
					Call endOp("r")
				End If
			Else
				Call write(dataLoc & "\connect.ebacmd",(curConnectRetry + 1))
				Call write(dataLoc & "\secureShutdown.ebacmd",true)
				Call endOp("fd")
			End If
		End If
	End If
	Err.Clear
	data = UCase(htmlContent)
	Call checkWScript
End Sub
Sub getTime
	On Error Resume Next
	nowDate = DatePart("m",Date) & "/" & DatePart("d",Date) & "/" & DatePart("yyyy",Date)
	nowTime = Right(0 & Hour(Now),2) & ":" & Right(0 & Minute(Now),2) & ":" & Right(0 & Second(Now),2)
End Sub
Sub giveAlert(msg)
	On Error Resume Next
	msgbox "Alert:" & line & msg,48,title
	Call addWarn
End Sub
Sub giveError(msg, code)
	On Error Resume Next
	msgbox "Error:" & line & msg & line & "Error code: " & code,16,title
	Call addError
End Sub
Sub giveNote(msg)
	On Error Resume Next
	msgbox "Notice:" & line & msg,64,title
	Call addNote
End Sub
Sub giveWarn(msg)
	On Error Resume Next
	msgbox "Warning:" & line & msg,48,title
	Call addWarn
End Sub
Sub log(logInput)
	On Error Resume Next
	If logging = "true" Then
		Call getTime
		logData = "[" & nowTime & " - " & nowDate & "] " & logInput
		Call append(logDir, logData)
	End If
End Sub
Sub read(dir,arg)
	On Error Resume Next
	If fExists(dir) Then
		Set sys = fs.OpenTextFile (dir,1)
		data = sys.ReadAll
		data = Left(data, Len(data)	- 2)
		sys.Close
		If arg = "l" Then data = LCase(data)
		If arg = "u" Then data = UCase(data)
	Else
		Call giveError("Given file not found: " & dir,"BAD_FILE_DIRECTORY")
	End If
End Sub
Sub readLines(dir,lineInt)
	On Error Resume Next
	If fExists(dir) Then
		Set sys = fs.OpenTextFile (dir, 1)
		For forVar = 1 to lineInt
			lines(forVar) = sys.ReadLine
		Next
		sys.Close
	Else
		Call giveError("Given file not found: " & dir,"BAD_FILE_DIRECTORY")
	End If
End Sub
Sub readSettings
	On Error Resume Next
	
	'Program Files
	If foldExists("C:\Program Files (x86)") Then
		programLoc = "C:\Program Files (x86)\EBA"
	Else
		programLoc = "C:\Program Files\EBA"
	End If
	
	'Registry Read
	programLoc = cmd.RegRead(regLoc & "\installDir")
	enableEndOp = cmd.RegRead(regLoc & "\enableOperationCompletedMenu")
	connectRetry = cmd.RegRead(regLoc & "\timesToAutoRetryInternetConnection")
	disableErrHandle = cmd.RegRead(regLoc & "\disableErrorHandle")
	enableLegacyEndOp = cmd.RegRead(regLoc & "\enableLegacyOperationCompletedMenu")
	
	'Conversion
	enableEndOp = CInt(enableEndOp)
	connectRetry = CInt(connectRetry)
	disableErrHandle = CInt(disableErrHandle)
	enableLegacyEndOp = CInt(enableLegacyEndOp)
	Err.Clear
	
	'Read Files
	If fExists(dataLoc & "\settings\logging.ebacmd") Then
		Call read(dataLoc & "\settings\logging.ebacmd","l")
		logging = data
	Else
		logging = "true"
	End If
	
	If fExists(dataLoc & "\settings\saveLogin.ebacmd") Then
		Call read(dataLoc & "\settings\saveLogin.ebacmd","l")
		saveLogin = data
	Else
		saveLogin = "false"
	End If
	
	If fExists(dataLoc & "\settings\shutdownTimer.ebacmd") Then
		Call read(dataLoc & "\settings\shutdownTimer.ebacmd","l")
		shutdownTimer = data
	Else
		shutdownTimer = 10
	End If
	
	If fExists(dataLoc & "\settings\defaultShutdown.ebacmd") Then
		Call read(dataLoc & "\settings\defaultShutdown.ebacmd","l")
		defaultShutdown = data
	Else
		defaultShutdown = "shutdown"
	End If
	
	Err.Clear
End Sub
Sub shutdown(shutdownMethod)
	On Error Resume Next
	Call write(dataLoc & "\secureShutdown.ebacmd","true")
	If shutdownMethod = "shutdown" Then
		cmd.run "shutdown /s /t " & shutdownTimer & " /f /c ""You requested a system shutdown in EBA Command Center."""
		Call giveWarn("Your PC will shut down in " & shutdownTimer & " seconds. Press OK to cancel.")
	Elseif shutdownMethod = "restart" Then
		cmd.run "shutdown /r /t " & shutdownTimer & " /f /c ""You requested a system restart in EBA Command Center."""
		Call giveWarn("Your PC will restart in " & shutdownTimer & " seconds. Press OK to cancel.")
	Elseif shutdownMethod = "hibernate" Then
		cmd.run "shutdown /h"
	Else
		cmd.run "shutdown /s /t 15 /f /c ""There was an issue with the shutdown method, so EBA Cmd will shutdown your PC in 15 seconds."""
		Call giveWarn("Your PC will shutdown in 15 seconds (due to an error with the shutdownMethod). Press OK to cancel.")
	End If
	cmd.run "shutdown /a"
	Call write(dataLoc & "\secureShutdown.ebacmd","false")
End Sub
Sub update(dir,writeData,arg)
	On Error Resume Next
	If LCase(arg) = "overwrite" Then
		Call write(dir,writeData)
	Elseif LCase(arg) = "append" Then
		Call append(dir,writeData)
	Else
		If Not fExists(dir) Then
			Call write(dir,writeData)
		End If
	End If
End Sub
Sub updateCommands
	On Error Resume Next
	fs.CopyFile scriptLoc, programLoc & "\EBA.vbs"
	
	fileDir = dataLoc & "\Commands\admin.ebacmd"
	Call update(fileDir,"eba.admin","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\backup.ebacmd"
	Call update(fileDir,"eba.backup","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\config.ebacmd"
	Call update(fileDir,"eba.config","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"yes","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\crash.ebacmd"
	Call update(fileDir,"eba.crash","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\dev.ebacmd"
	Call update(fileDir,"eba.dev","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\end.ebacmd"
	Call update(fileDir,"eba.end","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\error.ebacmd"
	Call update(fileDir,"eba.error","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\export.ebacmd"
	Call update(fileDir,"eba.export","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\help.ebacmd"
	Call update(fileDir,"eba.help","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\import.ebacmd"
	Call update(fileDir,"eba.import","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\login.ebacmd"
	Call update(fileDir,"eba.login","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\logout.ebacmd"
	Call update(fileDir,"eba.logout","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\logs.ebacmd"
	Call update(fileDir,logDir,"overwrite")
	Call update(fileDir,"file","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\read.ebacmd"
	Call update(fileDir,"eba.read","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\refresh.ebacmd"
	Call update(fileDir,"eba.refresh","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"yes","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\restart.ebacmd"
	Call update(fileDir,"eba.restart","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\run.ebacmd"
	Call update(fileDir,"sys.run","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\shutdown.ebacmd"
	Call update(fileDir,"sys.shutdown","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\uninstall.ebacmd"
	Call update(fileDir,"eba.uninstall","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"yes","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\update.ebacmd"
	Call update(fileDir,"https://ethanblaisalarms.github.io/cmd","overwrite")
	Call update(fileDir,"url","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\upgrade.ebacmd"
	Call update(fileDir,"eba.upgrade","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"yes","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\version.ebacmd"
	Call update(fileDir,"eba.version","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
	
	fileDir = dataLoc & "\Commands\write.ebacmd"
	Call update(fileDir,"eba.write","overwrite")
	Call update(fileDir,"exe","append")
	Call update(fileDir,"no","append")
	Call update(fileDir,"builtin","append")
End Sub
Sub write(dir,writeData)
	On Error Resume Next
	If fExists(dir) Then
		Set sys = fs.OpenTextFile (dir, 2)
		sys.WriteLine writeData
		sys.Close
	Elseif foldExists(fs.GetParentFolderName(dir)) Then
		Set sys = fs.CreateTextFile (dir, 2)
		sys.WriteLine writeData
		sys.Close
	Else
		Call giveError("Given file not found: " & dir,"BAD_FILE_DIRECTORY")
	End If
End Sub

'Functions
Function checkOS()
	For Each forVar in objOS
		checkOS = forVar.Caption
	Next
End Function
Function DblQuote(str)
	DblQuote = Chr(34) & str & Chr(34)
End Function
Function delete(dir)
	If fExists(dir) Then
		fs.DeleteFile(dir)
	Elseif foldExists(dir) Then
		fs.DeleteFolder(dir)
	End If
End Function
Function fExists(dir)
	fExists = fs.FileExists(dir)
End Function
Function foldExists(dir)
	foldExists = fs.FolderExists(dir)
End Function
Function goOnline(url)
	On Error Resume Next
	objHttps.open "get", url, True
	objHttps.send
	goOnline = objHttps.responseText
End Function
Function newFolder(dir)
	If Not foldExists(dir) Then
		If foldExists(fs.GetParentFolderName(dir)) Then
			newFolder = fs.CreateFolder(dir)
		End If
	End If
End Function
Function scriptRunning()
	WMI.ExecQuery("SELECT * FROM Win32_Process WHERE CommandLine LIKE '%" & Replace(scriptLoc,"\","\\") & "%' AND CommandLine LIKE '%WScript%' OR CommandLine LIKE '%cscript%'")
End Function