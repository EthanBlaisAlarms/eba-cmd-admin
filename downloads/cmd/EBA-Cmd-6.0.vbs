'EBA Command Center 6
'Copyright EBA Tools 2021
Option Explicit

'Var Setup - Objects
Dim fs : Set fs = CreateObject("Scripting.FileSystemObject")
Dim cmd : Set cmd = CreateObject("Wscript.Shell")
Dim sys, File, objShort
Dim runAdmin : Set runAdmin = CreateObject("Shell.Application")

'Var Setup - String
Dim eba : eba = ""
Dim nowDate, nowTime, nowHour
Dim fileDir : fileDir = "C:"
Dim data : data = ""
Dim exeValue : exeValue = "eba.null"
Dim status : status = "EBA Command Center"
Dim logIn : logIn = ""
Dim uName : uName = ""
Dim pWord : pWord = ""
Dim logInType : logInType = ""
Dim strPM : strPM = "AM"
Dim errStatus : errStatus = ""
Dim importData : importData = ""
Dim logData

'Var Setup - Const
Dim startupType : startupType = "install"
Dim nls : nls = vblf & vblf
Dim scriptLoc : scriptLoc = Wscript.ScriptFullName
Dim scriptDir : scriptDir = fs.GetParentFolderName(scriptLoc)
Dim ver : ver = 6
Dim title : title = "EBA Command Center Debug"
Dim line : line = vblf & "---------------------------------------" & vbLf
Dim logDir : logDir = "C:\EBA\Logs.txt"
Dim oldVer : oldVer = 0
Dim desktop : desktop = cmd.SpecialFolders("Desktop")

'Var Setup - Boolean & Int
Dim missFiles : missFiles = False
Dim logging : logging = False
Dim isPM : isPM = False
Dim isDev : isDev = False
Dim saveLogin : saveLogin = False
Dim secureShutdown : secureShutdown = False
Dim setupStat : setupStat = 0
Dim isInstalled : isInstalled = False

'Var Setup - EBA Paths
Dim pathHome : pathHome = "EBA-Cmd "
Dim pathConfig : pathConfig = "> Config "
Dim pathAccount : pathAccount = "> Account "
Dim pathCommand : pathCommand = "> Commands "
Dim pathDev : pathDev = "> Dev "
Dim pathRead : pathRead = "> Read "
Dim pathWrite : pathWrite = "> Write "
Dim pathSetup : pathSetup = "> Setup "
Dim pathActivate : pathActivate = "> Activation "

'Var Setup - Arrays
Dim temp(4),count(3),auth(5)
Call clearTemps
Call clearCounts
auth(0) = "ETHANBLAISALARMS"
auth(1) = "379-EBA-30194-ET"
auth(2) = "692-EBA-59204-JD"
auth(3) = "582-EBA-48592-HF"
auth(4) = "930-EBA-49602-KD"
auth(5) = "290-EBA-85829-YT"



'Check for imports
For each File In Wscript.Arguments
 importData = File
Next

'Startup
If fExists("C:\EBA\logging.ebacmd") Then
 Call read("C:\EBA\logging.ebacmd","l")
 logging = data
Else
 logging = "true"
End if
If fExists("C:\EBA\EBA.vbs") Then
 If scriptLoc = "C:\EBA\EBA.vbs" Then
  If fExists("C:\EBA\startupType.ebacmd") Then
   Call read("C:\EBA\startupType.ebacmd","n")
   startupType = data
  Else
   startupType = "normal"
  End If
 Else
  startupType = "update"
 End If
Else
 startupType = "install"
End If

If LCase(Right(importData, 7)) = ".ebacmd" Then
 Call read(importData,"l")
 If data = "eba.repair.dev" Then
  Call giveWarn("EBA Command Center is starting in recovery mode.")
  startupType = "recovery"
 Else
  Call giveError("Invalid startup key. Starting normally.")
 End If
End If

If startupType = "normal" Then
 
 title = "EBA Command Center " & ver
 
 'Data File Checks
 Call dataExists("C:\EBA\EBA.vbs")
 Call dataExists("C:\EBA\isLoggedIn.ebacmd")
 Call dataExists("C:\EBA\logging.ebacmd")
 Call dataExists("C:\EBA\saveLogin.ebacmd")
 Call dataExists("C:\EBA\loginType.ebacmd")
 Call dataExists("C:\EBA\secureShutdown.ebacmd")
 Call dataExists("C:\EBA\startupType.ebacmd")
 Call dataExists("C:\EBA\Commands\Execute\logs.ebacmd")
 
 If Not missFiles = false Then
  Call giveError("Unable to start EBA Command Center because the following data file was not found:" & vblf & missFiles)
  Call endOp("f")
 End If
 
 'Startup
 If Not fExists(logDir) Then
  Call log("Log File Created")
 End If
 
 Call read("C:\EBA\secureShutdown.ebacmd","l")
 secureShutdown = data
 Call read("C:\EBA\saveLogin.ebacmd","l")
 saveLogin = data
 
 If saveLogin = "false" Then
  Call write("C:\EBA\isLoggedIn.ebacmd","")
  Call write("C:\EBA\loginType.ebacmd","")
 End If
 
 If secureShutdown = "false" Then
  Call giveWarn(title & " did not shut down correctly the last time it was used. Make sure to shut down " & title & " correctly next time!")
  Call endOp("n")
 End If
 
 'EBA Command Center Runtime
 eba = msgbox("Start " & title & "?", 4+32, title)
 If eba = vbNo Then Call endOp("c")
 Call log(title & " started up")
 Call write("C:\EBA\secureShutdown.ebacmd","false")
 Do
  Call read("C:\EBA\isLoggedIn.ebacmd","n")
  logIn = data
  Call read("C:\EBA\loginType.ebacmd","l")
  loginType = data
  
  If logIn = "" Then
   status = "Not Logged In"
  Else
   status = "Logged in as " & logIn
  End If
  
  'User Input
  eba = LCase(inputbox("Enter Command Below:" & vblf & pathHome & line & status, title))
  If fExists("C:\EBA\Commands\Shortcut\" & eba & ".ebacmd") Then
   Call read("C:\EBA\Commands\Shortcut\" & eba & ".ebacmd","l")
   eba = data
  End If
  Call log("Command Executed: " & eba)
  If eba = "" Then
   eba = msgbox("Exit EBA Command Center?", 4+32, title)
   If eba = vbYes Then Call endOp("s")
  Elseif eba = "crash" Then
   Call endOp("c")
  Elseif fExists("C:\EBA\Commands\Internet\" & eba & ".url") Then
   cmd.run "C:\EBA\Commands\Internet\" & eba & ".url"
  Elseif fExists("C:\EBA\Commands\Administrators\Internet\" & eba & ".url") Then
   If loginType = "admin" Then
    cmd.run "C:\EBA\Commands\Administrators\Internet\" & eba & ".url"
   Else
    Call log("Failed to execute " & eba & " as " & logIn & " (command requires admin login!)")
    Call giveError("You need to be logged in as an administrator to run this command.")
   End If
  Elseif fExists("C:\EBA\Commands\Execute\" & eba & ".ebacmd") Then
   Call read("C:\EBA\Commands\Execute\" & eba & ".ebacmd","l")
   cmd.run data
  Elseif fExists("C:\EBA\Commands\Administrators\" & eba & ".ebacmd") Then
   If loginType = "admin" Then
    Call read("C:\EBA\Commands\Administrators\" & eba & ".ebacmd","l")
    cmd.run data
   Else
    Call log("Failed to execute " & eba & " as " & logIn & " (command requires admin login!)")
    Call giveError("You need to be logged in as an administrator to run this command.")
   End If
  Elseif fExists("C:\EBA\Commands\Main\" & eba & ".ebacmd") Then
   Call read("C:\EBA\Commands\Main\" & eba & ".ebacmd","l")
   exeValue = data
  Elseif fExists("C:\EBA\Commands\Administrators\Main\" & eba & ".ebacmd") Then
   If loginType = "admin" Then
    Call read("C:\EBA\Commands\Administrators\Main\" & eba & ".ebacmd","l")
    exeValue = data
   Else
    Call log("Failed to execute " & eba & " as " & logIn & " (command requires admin login)")
    Call giveError("You need to be logged in as an administrator to run this command.")
   End If
  Else
   Call giveError("That command was not found on this device." & vblf & eba)
  End If
  
  
  'Execution Values
  If exeValue = "eba.login" Then
   eba = inputbox("Please enter your username:",title)
   If fExists("C:\EBA\Users\Administrators\" & eba & ".ebacmd") Or fExists("C:\EBA\Users\General\" & eba & ".ebacmd") Then
    uName = eba
    If fExists("C:\EBA\Users\Administrators\" & uName & ".ebacmd") Then
     Call read("C:\EBA\Users\Administrators\" & uName & ".ebacmd","n")
   	 pWord = data
    Elseif fExists("C:\EBA\Users\General\" & uName & ".ebacmd") Then
     Call read("C:\EBA\Users\General\" & uName & ".ebacmd","n")
	    pWord = data
    Else
     Call log("Password failure for " & uName)
     Call giveError("There was a problem loading the password for that account.")
    End If
    eba = inputbox("Enter the password for " & uName,title)
    If eba = pWord Then
     If fExists("C:\EBA\Users\Administrators\" & uName & ".ebacmd") Then
      Call write("C:\EBA\isLoggedIn.ebacmd",uName)
      Call write("C:\EBA\loginType.ebacmd","admin")
     Elseif fExists("C:\EBA\Users\General\" & uName & ".ebacmd") Then
      Call write("C:\EBA\isLoggedIn.ebacmd",uName)
      Call write("C:\EBA\loginType.ebacmd","general")
     Else
      Call log("Account type error for " & uName)
      Call giveError("There was a problem loading the account type for that account.")
     End If
     Call log("Logged in as " & uName)
     Call giveNote("Logged in as " & uName)
    Else
     Call log("Login failed: " & uName)
     Call giveError("Incorrect password.")
    End If
   Else
    Call giveError("Username " & eba & " not found on this device.")
   End If
  Elseif exeValue = "eba.logout" Then
   Call write("C:\EBA\isLoggedIn.ebacmd","")
   Call write("C:\EBA\loginType.ebacmd","")
   Call log("Logged out all accounts")
   Call giveNote("Logged out.")
  Elseif exeValue = "sys.run" Then
   eba = inputbox("Enter the file path of the file you would like to run:", title)
   If fExists(eba) Then
    cmd.run eba
    Call log("File Executed: " & eba)
   Else
    Call giveError(eba & " was not found on this PC.")
   End If
  Elseif exeValue = "sys.shutdown" Then
   eba = msgbox("Shutdown your PC?", 4+32, title)
   If eba = vbYes Then
    cmd.run "shutdown /s /t 10 /c ""EBA Command Center requested a system shutdown"" "
    Call write("C:\EBA\secureShutdown.ebacmd","true")
    Call giveWarn("Your PC will shut down in 10 seconds! Press OK to cancel.")
    cmd.run "shutdown /a"
    Call write("C:\EBA\secureShutdown.ebacmd","false")
   End If
  Elseif exeValue = "sys.reset" Then
   If isDev = false Then
    Call giveError("This command can only be ran in EBA Developer Mode!")
   Else
    cmd.run "systemreset -cleanpc"
   End If
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
  Elseif exeValue = "eba.read" Then
   If isDev = false Then
    Call giveError("This command can only be ran in EBA Developer Mode!")
   Else
    eba = inputbox(pathHome & pathRead, title)
    If fExists(eba) Then
     Call read(eba,"n")
     Call log("File read: " & eba)
     msgbox pathHome & pathRead & "> " & eba & vblf & vblf & data,0,title
    Else
     Call log("Failed to read " & eba)
     Call giveError("File " & eba & " not found!")
    End If
   End If
  Elseif exeValue = "eba.write" Then
   If isDev = false Then
    Call giveError("This command can only be ran in EBA Developer Mode!")
   Else
    eba = inputbox(pathHome & pathWrite, title)
    If fExists(eba) Then
     temp(0) = eba
     eba = inputbox(pathHome & pathWrite & "> " & eba,title)
     If Lcase(eba) = "cancel" Then
      Call giveNote("Operation Canceled")
     Else
      Call log("Wrote data to " & temp(0) & ": " & eba)
      Call write(temp(0),eba)
     End If
    Else
     Call log("Failed to write to " & eba)
     Call giveError("File " & eba & " not found!")
    End If
   End If
  Elseif exeValue = "eba.refresh" Then
   If isDev = false Then
    Call giveError("This command can only be used in EBA Developer Mode!")
   Else
    eba = msgbox("EBA Command Center will restart and open in reinstall mode.", 48, title)
    Call write("C:\EBA\startupType.ebacmd","refresh")
    Call endOp("r")
   End If
  Elseif exeValue = "eba.uninstall" Then
   If isDev = false Then
    Call giveError("This command can only be ran in EBA Developer Mode!")
   Else
    eba = msgbox("Warning:" & line & "This will unistall EBA Command Center completely! Your EBA Command Center data will be erased! Your PC will restart after uninstall. Continue?", 4+48, title)
    Call addWarn
    If eba = vbYes Then
     For each File in fs.GetFolder("C:\EBA").SubFolders
      File.Delete TRUE
     Next
     For Each File in fs.GetFolder("C:\EBA").Files
      File.Delete
     Next
     cmd.run "shutdown /r /f /t 0"
     Call endOp("c")
    End If
    Call giveNote("Uninstallation canceled!")
   End If
  
  'Configuration Mode
  Elseif exeValue = "eba.config" Then
   eba = LCase(inputbox("Enter Command Below:" & vblf & pathHome & pathConfig & line & status, title))
   
   'Accounts
   If eba = "account" or eba = "acc" Then
    eba = LCase(inputbox("Enter Command Below:" & vblf & pathHome & pathConfig & pathAccount & line & status, title))
    
    'New Account
    If eba = "new" Then
     uName = inputbox("Create your username below:", title)
     If Len(uName) < 3 Then
      Call giveWarn("That username is too short!")
     Elseif Len(uName) > 15 Then
      Call giveWarn("That username is too long!")
     Else
      If inStr(1,uName,"\") > 0 Then
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
       temp(2) = true
      End If
     End If
     If fExists("C:\EBA\Users\Administrators\" & uName & ".ebacmd") or fExists("C:\EBA\Users\General\" & uName & ".ebacmd") Then
      Call giveWarn("That username already exists on this system.")
     Elseif temp(2) = True Then
      Call clearTemps
      temp(0) = uName
      eba = inputbox("Create a password for " & temp(0), title)
      If Len(eba) < 8 Then
       Call giveWarn("Password is too short.")
      Elseif Len(pWord) > 30 Then
       Call giveWarn("Password is too long.")
      Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
       Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
      Else
       temp(1) = eba
       eba = inputbox("Confirm password:", title)
       If eba = temp(1) Then
        temp(2) = true
       Else
        Call giveWarn("Those passwords did not match.")
       End If
      End If
      If temp(2) = true Then
       eba = msgbox("Make " & temp(0) & " an administrator?", 4+32+256, title)
       If eba = vbYes Then
        Call write("C:\EBA\Users\Administrators\" & temp(0) & ".ebacmd",temp(1))
        Call log("New administrator account created: " & temp(0))
       Else
        Call write("C:\EBA\Users\General\" & temp(0) & ".ebacmd",temp(1))
        Call log("Account created: " & temp(0))
       End If
      End If
     End If
    
    'Change Password
    Elseif eba = "pword" or eba = "password" Then
     eba = inputbox("Enter the username:",title)
     If fExists("C:\EBA\Users\Administrators\" & eba & ".ebacmd") or fExists("C:\EBA\Users\General\" & eba & ".ebacmd") Then
      temp(0) = eba
      If fExists("C:\EBA\Users\Administrators\" & eba & ".ebacmd") Then Call read("C:\EBA\Users\Administrators\" & eba & ".ebacmd","n")
      If fExists("C:\EBA\Users\General\" & eba & ".ebacmd") Then Call read("C:\EBA\Users\General\" & eba & ".ebacmd","n")
      pWord = data
      eba = inputbox("Enter the current password for " & temp(0), title)
      If eba = pWord Then
       eba = inputbox("Create a password for " & temp(0), title)
       If Len(eba) < 8 Then
        Call giveWarn("Password is too short.")
       Elseif Len(pWord) > 30 Then
        Call giveWarn("Password is too long.")
       Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
        Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
       Else
        temp(1) = eba
        eba = inputbox("Confirm password:", title)
        If eba = temp(1) Then
         temp(2) = true
        Else
         Call giveWarn("Those passwords did not match.")
        End If
       End If
       If temp(2) = true Then
        Call log("Password for " & temp(0) & " changed.")
        Call giveNote("Password changed!")
        If fExists("C:\EBA\Users\Administrators\" & temp(0) & ".ebacmd") Then
         Call write("C:\EBA\Users\Administrators\" & temp(0) & ".ebacmd",temp(1))
        Elseif fs.FileExists("C:\EBA\Users\General\" & temp(0) & ".ebacmd") Then
         Call write("C:\EBA\Data\Users\General\" & temp(0) & ".ebacmd",temp(1))
        End If
       End If
      Else
       Call giveError("Incorrect password!")
       Call log("Attempt to change password for " & temp(0) & " failed. Attempt made by " & logIn)
      End If
     Else
      Call giveError("The username " & eba & " was not found.")
     End If
    Else
     Call giveError(eba & " was not found in the configuration settings.")
    End If
    
   'Commands
   Elseif eba = "command" or eba = "cmd" Then
    eba = LCase(inputbox("Enter Command Below:" & vblf & pathHome & pathConfig & pathCommand & line & status, title))
    
    'New Command
    If eba = "new" Then
     eba = LCase(inputbox("Create the command name:" , title))
     If fExists("C:\EBA\Commands\Main\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Internet\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Execute\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Shortcut\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Administrators\Main\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Administrators\Internet\" & eba & ".ebacmd")_
     or fExists("C:\EBA\Commands\Administrators\Execute\" & eba & ".ebacmd") Then
      Call giveError("The command " & eba & " already exists!")
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
      temp(0) = eba
      eba = LCase(inputbox("What is the type?" & line & "'CMD': Execute a file or command" & vblf & "'URL': Web shortcut" & vblf & "'SHORT': Shortcut to another command", title))
      temp(1) = eba
      If eba = "cmd" Then
       eba = inputbox("Enter the file path or command:", title)
       temp(2) = eba
      Elseif eba = "url" Then
       eba = inputbox("Enter target URL (include https://)",title)
       temp(2) = eba
      Elseif eba = "short" Then
       eba = inputbox("Enter command to link to:",title)
       temp(2) = eba
      Else
       Call giveError(eba & " was not found in the configuration settings.")
      End If
      If temp(1) = "cmd" or temp(1) = "url" or temp(1) = "short" Then
       If Not temp(1) = "short" Then
        temp(3) = msgbox("Require an administrator login to execute this command?", 4+32, title)
       Else
        temp(3) = vbNo
       End If
       If temp(3) = vbNo Then temp(3) = "No"
       If temp(3) = vbYes Then temp(3) = "Yes"
       eba = msgbox("Confirm the following command:" & line & "Command: " & temp(0) & vblf & "Type: " & temp(1) & vblf & "Target: " & temp(2) & vblf & "Require admin:" & temp(3), 4+32, title)
       If eba = vbYes Then
        If temp(1) = "cmd" Then
         If temp(3) = "Yes" Then Call write("C:\EBA\Commands\Administrators\" & temp(0) & ".ebacmd",temp(2))
         If temp(3) = "No" Then Call write("C:\EBA\Commands\Execute\" & temp(0) & ".ebacmd",temp(2))
        ElseIf temp(1) = "short" Then
         Call write("C:\EBA\Commands\Shortcut\" & temp(0) & ".ebacmd",temp(2))
        ElseIf temp(1) = "url" Then
         If temp(3) = "No" Then
          Set objShort = cmd.CreateShortcut("C:\EBA\Commands\Internet\" & temp(0) & ".url")
          objShort.TargetPath = temp(2)
          objShort.Save
         Else
          Set objShort = cmd.CreateShortcut("C:\EBA\Commands\Administrators\Internet\" & temp(0) & ".url")
          objShort.TargetPath = temp(2)
          objShort.Save
         End If
        End If
       Else
        Call giveWarn("Creation of command " & temp(0) & " has been canceled")
       End If
      End If
     End If
    Else
     Call giveError(eba & " was not found in the configuration settings.")
    End If
   
   'Logging
   Elseif eba = "logging" or eba = "log" Then
    eba = msgbox("Logs are set to " & logging & ". Would you like to enable EBA Logs? (EBA Command Center will restart)", 4+32, title)
    If eba = vbYes Then
     Call write("C:\EBA\Logging.ebacmd","true")
     Call log("Logging enabled by " & logIn)
    Else
     Call write("C:\EBA\Logging.ebacmd","false")
     Call log("Logging disabled by " & logIn)
    End If
    Call endOp("r")
    
   Elseif eba = "savelogin" or eba = "login" Then
    eba = msgbox("Save login is set to " & saveLogin & ". Would you like to enable Save Login? (EBA Command Center will restart)", 4+32, title)
    If eba = vbYes Then
     Call write("C:\EBA\saveLogin.ebacmd","true")
     Call log("Save Login enabled by " & logIn)
    Else
     Call write("C:\EBA\saveLogin.ebacmd","false")
     Call log("Save login disabled by " & logIn)
    End If
    Call endOp("r")
   Else
    Call giveError(eba & " was not found in the configuration settings.")
   End If
  End If
  Call endOp("n")
 Loop
Elseif startupType = "install" Then
 
 title = "EBA Command Center " & ver & " Setup"
 'Get old version
 If foldExists("C:\EBA\Cmd") Then isInstalled = True
 If foldExists("C:\EBA\EBA-Cmd") Then isInstalled = True
 If isInstalled = True Then
  eba = msgbox("A legacy EBA Command Center (4.2 and below) installation was found on your system. When you update, this installation will be erased. Continue?", 4+48, title)
  If eba = vbNo Then Call endOp("c")
 End If
 
 'Legal Stuff
 eba = msgbox("Installing EBA Command Center is like installing other programs. You need to agree to our ""Terms of Service"". Please review the terms of service below:" & line & "1. Posting/Sharing EBA Keys is prohibited." & vblf & "2. Releasing the source code for EBA Command Center is prohibited." & vblf & "3. You are responsible for all actions taken using EBA Command Center." & vblf & "Do you agree to our terms of service?", 4+64, title)
 If eba = vbNo Then
  Call giveError("You cannot install EBA Command Center because you did not agree to the terms of service.")
  Call endOp("c")
 End If
 
 'Install Setup
 eba = msgbox("EBA Command Center " & ver & " is ready to install! We'll install to:" & vblf & "C:\EBA" & nls & "Is this ok?", 4+64, title)
 If eba = vbNo Then Call endOp("c")
 setupStat = 0
 
 'EBA Key
 Do while setupStat = 0
  eba = UCase(inputbox("Before we can install EBA Command Center, we need some basic info. Please enter your EBA Key below:",title))
  If eba = auth(0) or eba = auth(1) or eba = auth(2) or eba = auth(3) or eba = auth(4) or eba = auth(5) Then temp(0) = True
  If Len(eba) = 0 Then
   eba = msgbox("Do you have an EBA Key?", 4+32, title)
   If eba = vbNo Then
    Call giveError("An EBA Key is required to use EBA Command Center!")
    Call endOp("c")
   End If
  Elseif Len(eba) = 14 Then
   Call giveWarn("That EBA Key seems to be for version 4.2 and below. Try to locate a new EBA Key (XXX-EBA-XXXXX-XX)")
  Elseif Len(eba) = 16 Then
   If temp(0) = True Then
    Call giveNote("EBA Command Center has been activated!")
    setupStat = 1
   Else
    Call giveWarn("That EBA Key didnt work. Check the key and try again.")
   End If
  Else
   Call giveWarn("Something is wrong with that EBA Key, and was not recognized by EBA Command Center.")
  End If
 Loop
 
 'Username
 Do while setupStat = 1
  uName = inputbox("Lets create your first User Account! Create your username below:", title)
  If Len(uName) = 0 then
   eba = msgbox("Would you like to cancel installation?", 4+48, title)
   If eba = vbYes Then Call endOp("c")
  Elseif Len(uName) < 3 Then
   Call giveWarn("That username is too short!")
  Elseif Len(uName) > 15 Then
   Call giveWarn("That username is too long!")
  Else
   If inStr(1,uName,"\") > 0 Then
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
    setupStat = 2
   End If
  End If
 Loop
 
 'Password
 Do while setupStat = 2
  pWord = inputbox("Create a password for " & uName, title)
  If Len(pword) = 0 Then
   eba = msgbox("Would you like to cancel installation?", 4+48, title)
   If eba = vbYes Then wscript.quit
  Elseif Len(pWord) < 8 Then
   Call giveWarn("Password is too short.")
  Elseif Len(pWord) > 30 Then
   Call giveWarn("Password is too long.")
  Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
   Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
  Else
   temp(0) = inputbox("Confirm password:", title)
   If temp(0) = pword Then
    setupStat = 3
   Else
    Call giveWarn("Those passwords did not match.")
   End If
  End If
 Loop
 
 eba = msgbox("You are now one click away from installing EBA Command Center! Installing will clear data in C:\EBA. Install now?", 4+32, title)
 If eba = vbNo Then endOp("c")
 
 'Create Data Folders
 If foldExists("C:\EBA") Then fs.DeleteFolder("C:\EBA")
 newFolder("C:\EBA")
 newFolder("C:\EBA\Users")
 newFolder("C:\EBA\Users\Administrators")
 newFolder("C:\EBA\Users\General")
 newFolder("C:\EBA\Commands")
 newFolder("C:\EBA\Commands\Main")
 newFolder("C:\EBA\Commands\Internet")
 newFolder("C:\EBA\Commands\Execute")
 newFolder("C:\EBA\Commands\Shortcut")
 newFolder("C:\EBA\Commands\Administrators")
 newFolder("C:\EBA\Commands\Administrators\Main")
 newFolder("C:\EBA\Commands\Administrators\Internet")
 newFolder("C:\EBA\Commands\Administrators\Execute")
 
 'Create Command Files
 fs.CopyFile scriptLoc, "C:\EBA\EBA.vbs"
 Call update("C:\EBA\Commands\Execute\logs.ebacmd",logDir,"overwrite")
 Call update("C:\EBA\Commands\Administrators\Main\config.ebacmd","eba.config","overwrite")
 Call update("C:\EBA\Commands\Main\dev.ebacmd","eba.dev","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\logout.ebacmd","eba.logout","overwrite")
 Call update("C:\EBA\Commands\Main\read.ebacmd","eba.read","overwrite")
 Call update("C:\EBA\Commands\Main\refresh.ebacmd","eba.refresh","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\reset.ebacmd","sys.reset","overwrite")
 Call update("C:\EBA\Commands\Main\run.ebacmd","sys.run","overwrite")
 Call update("C:\EBA\Commands\Main\shutdown.ebacmd","sys.shutdown","overwrite")
 Call update("C:\EBA\Commands\Main\uninstall.ebacmd","eba.uninstall","overwrite")
 Call update("C:\EBA\Commands\Main\write.ebacmd","eba.write","overwrite")
 
 'Create Storage Files
 Call update("C:\EBA\isLoggedIn.ebacmd", "false","")
 Call update("C:\EBA\logging.ebacmd","true","")
 Call update("C:\EBA\loginType.ebacmd","","")
 Call update("C:\EBA\saveLogin.ebacmd","false","")
 Call update("C:\EBA\secureShutdown.ebacmd","true","")
 
 'Apply Setup Options
 Call write("C:\EBA\Users\Administrators\" & uName & ".ebacmd",pWord)
 If Not fExists(logDir) Then Call log("Log File Created")
 Call log("Installed EBA Command Center " & ver)
 Call log("New administrator account created: " & uName)
 Call update("C:\EBA\startupType.ebacmd","normal","overwrite")
 
 'Installation Complete
 eba = msgbox("Create a Desktop icon?", 4+32, title)
  If eba = vbYes Then
  Set objShort = cmd.CreateShortcut(desktop & "\EBA Command.lnk")
  With objShort
   .TargetPath = "C:\EBA\EBA.vbs"
   .IconLocation = "C:\Windows\System32\imageres.dll, 5323"
   .Save
  End With
 End If
 msgbox "EBA Command Center has been set up and installed!", 64, title
 Call endOp("r")
 
Elseif startupType = "update" Then
 
 title = "EBA Command Center " & ver & " Setup"
 
 'Legal Stuff
 eba = msgbox("Updating EBA Command Center is like installing other programs. You need to agree to our ""Terms of Service"". Please review the terms of service below:" & line & "1. Posting/Sharing EBA Keys is prohibited." & vblf & "2. Releasing the source code for EBA Command Center is prohibited." & vblf & "3. You are responsible for all actions taken using EBA Command Center." & vblf & "Do you agree to our terms of service?", 4+64, title)
 If eba = vbNo Then
  Call giveError("You cannot update EBA Command Center because you did not agree to the terms of service.")
  Call endOp("c")
 End If
 
 'Update Setup
 eba = msgbox("Lets update EBA Command Center! Updating will not delete any data. Start update?", 4+32, title)
 If eba = vbNo Then Call endOp("c")
 
 'Create Data Folders
 newFolder("C:\EBA")
 newFolder("C:\EBA\Users")
 newFolder("C:\EBA\Users\Administrators")
 newFolder("C:\EBA\Users\General")
 newFolder("C:\EBA\Commands")
 newFolder("C:\EBA\Commands\Main")
 newFolder("C:\EBA\Commands\Internet")
 newFolder("C:\EBA\Commands\Execute")
 newFolder("C:\EBA\Commands\Shortcut")
 newFolder("C:\EBA\Commands\Administrators")
 newFolder("C:\EBA\Commands\Administrators\Main")
 newFolder("C:\EBA\Commands\Administrators\Internet")
 newFolder("C:\EBA\Commands\Administrators\Execute")
 
 'Create Command Files
 fs.CopyFile scriptLoc, "C:\EBA\EBA.vbs"
 Call update("C:\EBA\Commands\Execute\logs.ebacmd",logDir,"overwrite")
 Call update("C:\EBA\Commands\Administrators\Main\config.ebacmd","eba.config","overwrite")
 Call update("C:\EBA\Commands\Main\dev.ebacmd","eba.dev","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\logout.ebacmd","eba.logout","overwrite")
 Call update("C:\EBA\Commands\Main\read.ebacmd","eba.read","overwrite")
 Call update("C:\EBA\Commands\Main\refresh.ebacmd","eba.refresh","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\reset.ebacmd","sys.reset","overwrite")
 Call update("C:\EBA\Commands\Main\run.ebacmd","sys.run","overwrite")
 Call update("C:\EBA\Commands\Main\shutdown.ebacmd","sys.shutdown","overwrite")
 Call update("C:\EBA\Commands\Main\uninstall.ebacmd","eba.uninstall","overwrite")
 Call update("C:\EBA\Commands\Main\write.ebacmd","eba.write","overwrite")
 
 'Create Storage Files
 Call update("C:\EBA\isLoggedIn.ebacmd", "false","")
 Call update("C:\EBA\logging.ebacmd","true","")
 Call update("C:\EBA\loginType.ebacmd","","")
 Call update("C:\EBA\saveLogin.ebacmd","false","")
 Call update("C:\EBA\secureShutdown.ebacmd","true","")
 
 'Apply Setup Options
 Call log("Installed EBA Command Center " & ver & " as an update")
 Call update("C:\EBA\startupType.ebacmd","normal","overwrite")
 If foldExists("C:\EBA\Data") Then
  For Each File In fs.GetFolder("C:\EBA\Data").Files
   fs.CopyFile File, Replace(File,"\Data\","\")
  Next
  For Each File In fs.GetFolder("C:\EBA\Data").SubFolders
   fs.CopyFolder File, Replace(File,"\Data\","\")
  Next
  fs.DeleteFolder("C:\EBA\Data")
 End If
 msgbox "EBA Command Center " & ver & " was successfully installed!", 64, title
 Call endOp("c")
 
Elseif startupType = "refresh" Then
 
 title = "EBA Command Center " & ver & " Reinstallation"
 
 'Reinstallation
 eba = msgbox("Lets reinstall EBA Command Center! Just a quick important warning, your EBA Command Center data will be erased. Continue with reinstallation?", 4+48, title)
 If eba = vbNo Then
  Call write("C:\EBA\startupType.ebacmd","null")
  Call endOp("r")
 End If
 setupStat = 1
 
 'Username
 Do while setupStat = 1
  uName = inputbox("Lets create a User Account that will be used after reinstallation! Create your username below:", title)
  If Len(uName) = 0 then
   eba = msgbox("Would you like to cancel reinstallation?", 4+48, title)
   If eba = vbYes Then Call endOp("c")
  Elseif Len(uName) < 3 Then
   Call giveWarn("That username is too short!")
  Elseif Len(uName) > 15 Then
   Call giveWarn("That username is too long!")
  Else
   If inStr(1,uName,"\") > 0 Then
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
    setupStat = 2
   End If
  End If
 Loop
 
 'Password
 Do while setupStat = 2
  pWord = inputbox("Create a password for " & uName, title)
  If Len(pword) = 0 Then
   eba = msgbox("Would you like to cancel reinstallation?", 4+48, title)
   If eba = vbYes Then wscript.quit
  Elseif Len(pWord) < 8 Then
   Call giveWarn("Password is too short.")
  Elseif Len(pWord) > 30 Then
   Call giveWarn("Password is too long.")
  Elseif InStr(1,lcase(pWord),"password") > 0 or Instr(1,pword,"1234") > 0 Then
   Call giveWarn("Ok, really..." & nls & "Ok, that password is too easy to figure out. Choose a strong password with a mix of letters and numbers.")
  Else
   temp(0) = inputbox("Confirm password:", title)
   If temp(0) = pword Then
    setupStat = 3
   Else
    Call giveWarn("Those passwords did not match.")
   End If
  End If
 Loop
 
 eba = msgbox("This is your last chance! Once you confirm, EBA Command Center will be reinstalled. Reinstall now?", 4+48, title)
 If eba = vbNo Then endOp("c")
 
 fs.MoveFile scriptLoc, "C:\EBA.vbs"
 If foldExists("C:\EBA") Then fs.DeleteFolder("C:\EBA")
 newFolder("C:\EBA")
 fs.MoveFile "C:\EBA.vbs", "C:\EBA\EBA.vbs"
 
 'Create Data Folders
 newFolder("C:\EBA\Users")
 newFolder("C:\EBA\Users\Administrators")
 newFolder("C:\EBA\Users\General")
 newFolder("C:\EBA\Commands")
 newFolder("C:\EBA\Commands\Main")
 newFolder("C:\EBA\Commands\Internet")
 newFolder("C:\EBA\Commands\Execute")
 newFolder("C:\EBA\Commands\Shortcut")
 newFolder("C:\EBA\Commands\Administrators")
 newFolder("C:\EBA\Commands\Administrators\Main")
 newFolder("C:\EBA\Commands\Administrators\Internet")
 newFolder("C:\EBA\Commands\Administrators\Execute")
 
 'Create Command Files
 fs.CopyFile scriptLoc, "C:\EBA\EBA.vbs"
 Call update("C:\EBA\Commands\Execute\logs.ebacmd",logDir,"overwrite")
 Call update("C:\EBA\Commands\Administrators\Main\config.ebacmd","eba.config","overwrite")
 Call update("C:\EBA\Commands\Main\dev.ebacmd","eba.dev","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\logout.ebacmd","eba.logout","overwrite")
 Call update("C:\EBA\Commands\Main\read.ebacmd","eba.read","overwrite")
 Call update("C:\EBA\Commands\Main\refresh.ebacmd","eba.refresh","overwrite")
 Call update("C:\EBA\Commands\Main\login.ebacmd","eba.login","overwrite")
 Call update("C:\EBA\Commands\Main\reset.ebacmd","sys.reset","overwrite")
 Call update("C:\EBA\Commands\Main\run.ebacmd","sys.run","overwrite")
 Call update("C:\EBA\Commands\Main\shutdown.ebacmd","sys.shutdown","overwrite")
 Call update("C:\EBA\Commands\Main\uninstall.ebacmd","eba.uninstall","overwrite")
 Call update("C:\EBA\Commands\Main\write.ebacmd","eba.write","overwrite")
 
 'Create Storage Files
 Call update("C:\EBA\isLoggedIn.ebacmd", "false","")
 Call update("C:\EBA\logging.ebacmd","true","")
 Call update("C:\EBA\loginType.ebacmd","","")
 Call update("C:\EBA\saveLogin.ebacmd","false","")
 Call update("C:\EBA\secureShutdown.ebacmd","true","")
 
 'Apply Setup Options
 Call write("C:\EBA\Users\Administrators\" & uName & ".ebacmd",pWord)
 If Not fExists(logDir) Then Call log("Log File Created")
 Call log("Reinstalled EBA Command Center " & ver)
 Call log("New administrator account created: " & uName)
 Call update("C:\EBA\startupType.ebacmd","normal","overwrite")
 
 'Installation Complete
 eba = msgbox("Create a Desktop icon?", 4+32, title)
  If eba = vbYes Then
  Set objShort = cmd.CreateShortcut(desktop & "\EBA Command.lnk")
  With objShort
   .TargetPath = "C:\EBA\EBA.vbs"
   .IconLocation = "C:\Windows\System32\imageres.dll, 5323"
   .Save
  End With
 End If
 msgbox "EBA Command Center has been reinstalled!", 64, title
 Call endOp("r")
 
Elseif startupType = "recovery" Then
 title = "EBA Recovery Mode"
 
 temp(4) = True
 Do while temp(4) = True
  eba = LCase(inputbox("EBA-Cmd > Recovery",title))
  If eba = "repair" Then
   eba = LCase(inputbox("EBA-Cmd > Recovery > Repair",title))
   If eba = "file" Then
    eba = LCase(inputbox("EBA-Cmd > Recovery > Repair > File",title))
    Call fileRepair(eba)
   Elseif eba = "refresh" Then
    Call write("C:\EBA\startupType.ebacmd","refresh")
    Call endOp("r")
   End If
  Elseif Len(eba) = 0 Then
   Call endOp("c")
  End If
 Loop
Else
 Call giveError("Your startup type is not valid. Your startup type will be reset.")
 If fExists("C:\EBA\startupType.ebacmd") Then Call write("C:\EBA\startupType.ebacmd","normal")
 Call log("Invalid startup type was reset to normal: " & startupType)
End If



'Subs

'Read File Data
Sub read(dir,args)
 Set sys = fs.OpenTextFile (dir, 1)
 data = sys.ReadAll
 Call cutDataEnd
 sys.Close
 If args = "l" Then data = LCase(data)
 If args = "u" Then data = UCase(data)
End Sub 

'Cut vbCrLf from the end of file data
Sub cutDataEnd
 data = Left(data, Len(data) - 2)
End Sub

'Get Current Time
Sub getTime
 isPM = false
 nowDate = DatePart("m",Date) & "/" & DatePart("d",Date) & "/" & DatePart("yyyy",Date)
 nowHour = Hour(Now)
 If nowHour > 12 Then
  nowHour = nowHour - 12
  isPM = True
 Elseif nowHour = 0 Then
  nowHour = 12
 End If
 If isPM = true Then strPM = " PM"
 If isPM = false Then strPM = " AM"
 nowTime = Right("0" & nowHour, 2) & ":" & Right("0" & Minute(Now), 2) & ":" & Right("0" & Second(Now), 2) & strPM
End Sub

'End Operations
Sub endOp(arg)
 If arg = "c" Then wscript.quit
 If arg = "f" Then
  Call write("C:\EBA\secureShutdown.ebacmd","true")
  Call log("EBA Command Center was forced to shut down")
  wscript.quit
 End If
 If arg = "n" or arg = "s" or arg = "r" Then
  count(0) = count(0) + 1
  msgbox "Operation " & count(0) & " Completed:" & nls & "Errors: " & count(3) & vblf &_
  "Warnings: " & count(2) & vblf & "Notices: " & count(1), 64, title
  Call clearCounts
  Call clearTemps
  If arg = "s" Then
   Call write("C:\EBA\secureShutdown.ebacmd","true")
   Call log("EBA Command Center was shut down")
   wscript.quit
  End If
  If arg = "r" Then
   Call write("C:\EBA\secureShutdown.ebacmd","true")
   cmd.run("C:\EBA\EBA.vbs")
   Call log("EBA Command Center was restarted")
   wscript.quit
  End If
 End If
End Sub

'Write data to a file
Sub write(dir,writeData)
 If fExists(dir) Then
  Set sys = fs.OpenTextFile (dir, 2)
  sys.WriteLine writeData
  sys.Close
 Else
  Set sys = fs.CreateTextFile (dir, 2)
  sys.WriteLine writeData
  sys.Close
 End If
End Sub

'Append data to a file
Sub append(dir,writeData)
 If fExists(dir) Then
  Set sys = fs.OpenTextFile (dir, 8)
  sys.WriteLine writeData
  sys.Close
 Else
  Set sys = fs.CreateTextFile (dir, 8)
  sys.WriteLine writeData
  sys.Close
 End If
End Sub

'Log info to the log file
Sub log(logInput)
 If logging = "true" Then
  Call getTime
  logData = "[" & nowTime & " - " & nowDate & "] " & logInput
  Call append(logDir,logData)
 End If
End Sub

'Add an error to the operation completion message
Sub addError
 count(3) = count(3) + 1
End Sub

'Add a warning to the operation completion message
Sub addWarn
 count(2) = count(2) + 1
End Sub

'Add a notice to the operation completion message
Sub addNote
 count(1) = count(1) + 1
End Sub

'Clears all data in Count array
Sub clearCounts
 count(1) = 0
 count(2) = 0
 count(3) = 0
End Sub

'Clears all data in Temp array
Sub clearTemps
 temp(0) = false
 temp(1) = false
 temp(2) = false
 temp(3) = false
 temp(4) = false
 exeValue = "eba.null"
End Sub

'Check if a data file exists
Sub dataExists(dir)
 If Not fExists(dir) Then
  temp(0) = false
  eba = msgbox("Error:" & line & "A required data file was not found. We may be able to restore this file:" & vblf & dir & line & "Attempt to restore this file?", 4+16, title)
  If eba = vbYes Then Call fileRepair(dir)
  If temp(0) = false Then missFiles = dir
  Call addError
 End If
End Sub

'Repair data files
Sub fileRepair(dir)
 temp(0) = false
 msgbox "Warning:" & line & "We were not able to repair that file!", 48, title
 Call addWarn
End Sub

'Display an error message
Sub giveError(msg)
 msgbox "Error:" & line & msg, 16, title
 Call addError
End Sub

'Display a warning
Sub giveWarn(msg)
 msgbox "Warning:" & line & msg, 48, title
 Call addWarn
End Sub

'Display a notice
Sub giveNote(msg)
 msgbox "Notice:" & line & msg, 64, title
 Call addNote
End Sub

'Update a file
Sub update(dir,writeData,args)
 If LCase(args) = "overwrite" Then
  Call write(dir,writeData)
 Else
  If Not fExists(dir) Then
   Call write(dir,writeData)
  End If
 End If
End Sub



'Functions

'Check if file exists
Function fExists(dir)
 fExists = fs.FileExists(dir)
End Function

'Check if folder exists
Function foldExists(dir)
 foldExists = fs.FolderExists(dir)
End Function

'Create new folder
Function newFolder(dir)
 If Not foldExists(dir) Then
  newFolder = fs.CreateFolder(dir)
 End If
End Function