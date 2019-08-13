#define AppName "Pixelpulse2"
#define AppVersion "1.0.4"
#define AppPublisher "Analog Devices, Inc."
#define AppURL "http://www.analog.com"
#define AppExeName "Pixelpulse2.exe"

[Setup]
AppId={{258C031E-98C7-4609-9122-65A4D36274AF}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={pf}\Analog Devices\{#AppName}
DefaultGroupName=Analog Devices\{#AppName}
OutputDir="C:\"
OutputBaseFilename=Pixelpulse2_win_setup
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "corsican"; MessagesFile: "compiler:Languages\Corsican.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "greek"; MessagesFile: "compiler:Languages\Greek.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "scottishgaelic"; MessagesFile: "compiler:Languages\ScottishGaelic.isl"
Name: "serbiancyrillic"; MessagesFile: "compiler:Languages\SerbianCyrillic.isl"
Name: "serbianlatin"; MessagesFile: "compiler:Languages\SerbianLatin.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: drivers; Description: Install WinUSB drivers for the M1K;

[Files]
Source: "c:\projects\pixelpulse2\release\pixelpulse2.exe"; DestDir: "{app}"
Source: "c:\projects\pixelpulse2\distrib\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
Source: "C:\WinDDK\7600.16385.1\redist\DIFx\dpinst\EngMui\x86\dpinst.exe"; DestDir: "{app}\drivers"; Tasks: drivers; Check: not IsWin64
Source: "C:\WinDDK\7600.16385.1\redist\DIFx\dpinst\EngMui\amd64\dpinst.exe"; DestDir: "{app}\drivers"; Tasks: drivers; Check: IsWin64
Source: "c:\projects\pixelpulse2\distrib\driver\m1k-winusb.inf"; DestDir: "{app}\drivers"; Tasks: drivers
Source: "c:\projects\pixelpulse2\distrib\driver\m1k-winusb.cat"; DestDir: "{app}\drivers"; Tasks: drivers

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent unchecked
Filename: {app}\pp2trayer.exe; Description: "Launch Pixelpulse2 Trayer"; Flags: nowait postinstall skipifsilent
Filename: "{app}\drivers\dpinst.exe"; Parameters: "/path ""{app}\drivers"""; Flags: waituntilterminated; Tasks: drivers

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C""taskkill /im pp2trayer.exe /f /t"; Flags: runhidden

[Registry]
; Make Pixelpulse2 Trayer run every time Windows boots
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Pixelpulse2Trayer"; ValueData: """{app}\pp2trayer.exe"""; Flags: uninsdeletevalue

; Functions GetNumber(), CompareInner(), CompareVersion() and InitializeSetup() can be used to detect
; differences between the version being installed and the version that might be already installed.
[Code]
function GetNumber(var temp: String): Integer;
var
  part: String;
  pos1: Integer;
begin
  if Length(temp) = 0 then
  begin
    Result := -1;
    Exit;
  end;
    pos1 := Pos('.', temp);
    if (pos1 = 0) then
    begin
      Result := StrToInt(temp);
    temp := '';
    end
    else
    begin
    part := Copy(temp, 1, pos1 - 1);
      temp := Copy(temp, pos1 + 1, Length(temp));
      Result := StrToInt(part);
    end;
end;

function CompareInner(var temp1, temp2: String): Integer;
var
  num1, num2: Integer;
begin
    num1 := GetNumber(temp1);
  num2 := GetNumber(temp2);
  if (num1 = -1) or (num2 = -1) then
  begin
    Result := 0;
    Exit;
  end;
      if (num1 > num2) then
      begin
        Result := 1;
      end
      else if (num1 < num2) then
      begin
        Result := -1;
      end
      else
      begin
        Result := CompareInner(temp1, temp2);
      end;
end;

function CompareVersion(str1, str2: String): Integer;
var
  temp1, temp2: String;
begin
    temp1 := str1;
    temp2 := str2;
    Result := CompareInner(temp1, temp2);
end;

// function InitializeSetup(): Boolean;
// var
  // oldVersion: String;
  // uninstaller: String;
  // ErrorCode: Integer;
  // vCurID      :String;
  // vCurAppName :String;
// begin
  // vCurID:= '{#SetupSetting("AppName")}';
  // vCurAppName:= '{#SetupSetting("AppName")}';

  // if RegKeyExists(HKLM,
    // 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + vCurID + '_is1') then
  // begin
    // RegQueryStringValue(HKLM,
      // 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + vCurID + '_is1',
      // 'DisplayVersion', oldVersion);
    // if (not (CompareVersion(oldVersion, '{#SetupSetting("AppVersion")}') = 0)) then
    // begin
      // if MsgBox('An older version ' + oldVersion + ' of ' + vCurAppName + ' is already installed. Continue to use this version?',
        // mbConfirmation, MB_YESNO) = IDYES then
      // begin
        // Result := False;
      // end
      // else
      // begin
          // RegQueryStringValue(HKLM,
            // 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + vCurID + '_is1',
            // 'UninstallString', uninstaller);
          // ShellExec('runas', uninstaller, '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
          // Result := True;
      // end;
    // end
    // else
    // begin
      // if MsgBox('Version ' + oldVersion + ' of ' + vCurAppName + ' is already installed. Continue with the install?',
        // mbConfirmation, MB_YESNO) = IDNO then
      // begin
        // Result := False;
      // end
      // else
      // begin
          // RegQueryStringValue(HKLM,
            // 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + vCurID + '_is1',
            // 'UninstallString', uninstaller);
          // ShellExec('runas', uninstaller, '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
          // Result := True;
      // end;
    // end
  // end
  // else
  // begin
    // Result := True;
  // end;
// end;
