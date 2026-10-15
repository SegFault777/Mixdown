; Inno Setup 6 script.  iscc /DQtMajor=5 mixdown.iss   (Windows 7/8/8.1, Qt 5.15)
;                         iscc /DQtMajor=6 mixdown.iss   (Windows 10 1809+, Qt 6.5)
#ifndef QtMajor
  #define QtMajor "6"
#endif
#define AppName "Mixdown"
#define AppVersion "1.0.0"

[Setup]
AppId={{6E0B2C5A-8F53-4B0E-9C41-3D7A5C1E9B24}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\..\dist
OutputBaseFilename=Mixdown-{#AppVersion}-win-qt{#QtMajor}-setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ChangesAssociations=yes
SetupIconFile=mixdown.ico
UninstallDisplayIcon={app}\Mixdown.exe
#if QtMajor == "5"
MinVersion=6.1sp1
#else
MinVersion=10.0.17763
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked
Name: "assoc"; Description: ".mxd"; GroupDescription: "File association"

[Files]
Source: "..\..\dist\win-qt{#QtMajor}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\Mixdown.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\Mixdown.exe"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\Classes\.mxd"; ValueType: string; ValueData: "Mixdown.Document"; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\Mixdown.Document"; ValueType: string; ValueData: "Mixdown Document"; Flags: uninsdeletekey; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\Mixdown.Document\DefaultIcon"; ValueType: string; ValueData: "{app}\Mixdown.exe,0"; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\Mixdown.Document\shell\open\command"; ValueType: string; ValueData: """{app}\Mixdown.exe"" ""%1"""; Tasks: assoc

[Run]
Filename: "{app}\Mixdown.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
