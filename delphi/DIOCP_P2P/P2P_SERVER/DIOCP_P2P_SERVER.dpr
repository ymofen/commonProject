program DIOCP_P2P_SERVER;

uses
  Forms,
  ufrmMain in 'ufrmMain.pas' {frmMain},
  diocp.p2p in 'diocp.p2p.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
