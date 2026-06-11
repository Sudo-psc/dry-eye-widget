; Inno Setup — instalador do Dry Eye Widget (Windows x64)
; Compile com:  ISCC.exe win_version\templates\dry-eye-widget.iss
; Pré-requisito: ter rodado `flutter build windows --release` antes.
;
; O CI injeta MyAppVersion a partir do pubspec.yaml via /DMyAppVersion=...
; Fallback abaixo é usado apenas em builds manuais sem /D.

#define MyAppName "Dry Eye Widget"
#ifndef MyAppVersion
#define MyAppVersion "1.9.2"
#endif
#define MyAppPublisher "Saraiva Vision Care"
#define MyAppURL "https://github.com/Sudo-psc/dry-eye-widget"
#define MyAppExeName "dry_eye_widget.exe"
#define MyAppCopyright "Copyright (C) 2026 Saraiva Vision Care"
; Pasta de saída da build do Flutter (relativa à raiz do repositório).
#define BuildDir "..\..\build\windows\x64\runner\Release"
; Ícone do app gerado por flutter_launcher_icons.
#define AppIcon "..\..\windows\runner\resources\app_icon.ico"

[Setup]
; AppId identifica o app para upgrades/desinstalação. NÃO altere depois de
; publicado: trocar o GUID faz instalações existentes virarem "órfãs" (o
; instalador novo não as detecta como upgrade). Mantido estável de propósito.
AppId={{B2A7C3E1-9D4F-4A8B-9C2E-DRYEYE000001}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
AppCopyright={#MyAppCopyright}
DefaultDirName={autopf}\Dry Eye Widget
DefaultGroupName=Dry Eye Widget
DisableProgramGroupPage=yes
; Instalação só para a arquitetura x64 (Flutter desktop é x64).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Windows 10 1809+ (necessário para toasts confiáveis do Flutter desktop).
MinVersion=10.0.17763
OutputDir=..\..\dist
OutputBaseFilename=DryEyeWidget-Setup-x64
SetupIconFile={#AppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; PrivilegesRequired=admin instala em Program Files (todos os usuários) e dispara
; um prompt de UAC. Mantido em admin para que atalhos/notificações tenham caminho
; estável; veja CODE_SIGNING.md para a alternativa "lowest" (sem UAC, por-usuário).
PrivilegesRequired=admin
; Fecha instâncias em execução antes de atualizar (evita "arquivo em uso").
CloseApplications=yes
RestartApplications=no
; Metadados embutidos no PRÓPRIO instalador (.exe). Sem isso, o instalador fica
; "sem editor/descrição" e dispara heurísticas de SmartScreen/antivírus.
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}.0
VersionInfoCopyright={#MyAppCopyright}

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
