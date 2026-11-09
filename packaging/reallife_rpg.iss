; Inno Setup script for the RealLife RPG Windows installer.
; Built on a Windows host by .github/workflows/release.yml;
; never built here. The app keeps its data under %APPDATA%\RealLifeRPG,
; outside the install folder, so uninstalling does not delete any task.
#define AppName "RealLife RPG"
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

[Setup]
AppId={{96A4E2C1-C8DD-44EE-B7A9-A839C1B51762}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=RealLife RPG
DefaultDirName={autopf}\RealLife RPG
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=RealLife-RPG-Windows-Kurulum
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\reallife_rpg.exe

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\reallife_rpg.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\reallife_rpg.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Masaüstüne kısayol oluştur"; GroupDescription: "Kısayollar:"

[Run]
Filename: "{app}\reallife_rpg.exe"; Description: "RealLife RPG'i aç"; Flags: nowait postinstall skipifsilent
