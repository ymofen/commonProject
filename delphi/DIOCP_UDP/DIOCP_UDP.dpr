program DIOCP_UDP;

uses
  Forms,
  ufrmMain in 'ufrmMain.pas' {Form1},
  utils.base64 in 'utils.base64.pas',
  ufrmAbout in 'ufrmAbout.pas' {frmAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
