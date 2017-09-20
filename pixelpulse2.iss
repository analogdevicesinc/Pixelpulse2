#define AppName "Pixelpulse2"
#define AppVersion "0.90"
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
; Only allow driver installs for Windows 7 (version 6.2 maps to Windows 8).
Name: drivers; Description: Install WinUSB drivers for the M1K; OnlyBelowVersion: 6.2

[Files]
Source: "c:\projects\pixelpulse2\release\pixelpulse2.exe"; DestDir: "{app}"
Source: "c:\projects\pixelpulse2\distrib\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
Source: "C:\WinDDK\7600.16385.1\redist\DIFx\dpinst\EngMui\x86\dpinst.exe"; DestDir: "{app}\drivers"; Tasks: drivers; Check: not IsWin64
Source: "C:\WinDDK\7600.16385.1\redist\DIFx\dpinst\EngMui\amd64\dpinst.exe"; DestDir: "{app}\drivers"; Tasks: drivers; Check: IsWin64

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
