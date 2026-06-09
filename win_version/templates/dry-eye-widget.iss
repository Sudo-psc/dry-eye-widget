; Inno Setup — instalador do Dry Eye Widget (Windows x64)
; Compile com:  ISCC.exe win_version\templates\dry-eye-widget.iss
; Pré-requisito: ter rodado `flutter build windows --release` antes.
;
; Mantenha MyAppVersion em sincronia com pubspec.yaml (version:) e
; AppInfo.version em lib/utils/constants.dart.

#define MyAppName "Dry Eye Widget"
#define MyAppVersion "1.6.2"
#define MyAppPublisher "Saraiva Vision Care"
#define MyAppURL "https://github.com/Sudo-psc/dry-eye-widget"
#define MyAppExeName "dry_eye_widget.exe"
; Pasta de saída da build do Flutter (relativa à raiz do repositório).
#define BuildDir "..\..\build\windows\x64\runner\Release"
; Ícone do app gerado por flutter_launcher_icons.
#define AppIcon "..\..\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{B2A7C3E1-9D4F-4A8B-9C2E-DRYEYE000001}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\Dry Eye Widget
DefaultGroupName=Dry Eye Widget
DisableProgramGroupPage=yes
; Instalação só para a arquitetura x64 (Flutter desktop é x64).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=DryEyeWidget-Setup-x64
SetupIconFile={#AppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Empacota toda a pasta Release (exe + DLLs + data\).
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
