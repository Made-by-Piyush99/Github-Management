; Script generated for DevSync Studio
; Inno Setup 7 Script

#define MyAppName "DevSync Studio"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DevSync Studio"
#define MyAppURL "https://github.com"
#define MyAppExeName "DevSyncStudio.exe"
#define SourceDistDir "..\dist\DevSyncStudio"

[Setup]
AppId={{5E79805B-9A74-4C21-B2C1-3B52DF02E5A8}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\DevSync Studio
DefaultGroupName=DevSync Studio
AllowNoIcons=yes
OutputDir=..\dist\installer
OutputBaseFilename=DevSyncStudio_Setup_v1.0.0
SetupIconFile=..\assets\app.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=auto
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion=1.0.0.0
VersionInfoCompany=DevSync Studio
VersionInfoDescription=DevSync Studio Installer
VersionInfoProductVersion=1.0.0.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; Clean up any legacy loose scripts or logs from previous versions
Type: filesandordirs; Name: "{app}\backend"
Type: filesandordirs; Name: "{app}\__pycache__"
Type: files; Name: "{app}\*.log"

[Files]
; Dist files including Qt DLLs, plugins, and bundled DevSyncBackend native worker
Source: "{#SourceDistDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.log,*.pdb,*.ilk,backend\*"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\app.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\app.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
