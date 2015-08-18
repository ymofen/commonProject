program P2P_CLIENT;

uses
  Forms,
  UnitMainForm in 'UnitMainForm.pas' {MainForm},
  Protocol in '..\P2P_COMMON\Protocol.pas',
  WinSock2 in '..\P2P_COMMON\Winsock2.pas',
  CRC32 in 'CRC32.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'P2P CLIENT';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
