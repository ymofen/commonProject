program DValueTester;

uses
  Forms,
  ufrmMain in 'ufrmMain.pas' {Form1},
  utils_dvalue_multiparts in '..\..\..\diocp-v5\source\utils_dvalue_multiparts.pas';

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := true;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
