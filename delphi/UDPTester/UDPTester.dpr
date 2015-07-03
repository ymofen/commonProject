program UDPTester;

uses
  Forms,
  ufrmMain in 'ufrmMain.pas' {Form1},
  diocp.udp in 'diocp.udp.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
