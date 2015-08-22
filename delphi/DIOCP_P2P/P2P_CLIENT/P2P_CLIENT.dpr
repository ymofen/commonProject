program P2P_CLIENT;

uses
  Forms,
  ufrmMain in 'ufrmMain.pas' {Form2},
  diocp.p2p.client in 'diocp.p2p.client.pas',
  ufrmP2P in 'ufrmP2P.pas' {frmP2P};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TfrmP2P, frmP2P);
  Application.Run;
end.
