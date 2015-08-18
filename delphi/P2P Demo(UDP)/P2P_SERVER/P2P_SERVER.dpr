program P2P_SERVER;

uses
  Forms,
  UnitMainForm in 'UnitMainForm.pas' {MainForm},
  WinSock2 in '..\P2P_COMMON\Winsock2.pas',
  Protocol in '..\P2P_COMMON\Protocol.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'P2P SERVER';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
