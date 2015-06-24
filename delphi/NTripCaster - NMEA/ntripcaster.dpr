program ntripcaster;

uses
  Vcl.Forms,
  ufrmMain in 'ufrmMain.pas' {frmMain},
  diocp.ex.ntrip in 'diocp.ex.ntrip.pas',
  uFMMonitor in 'Frames\uFMMonitor.pas' {FMMonitor: TFrame},
  uRunTimeINfoTools in 'Frames\uRunTimeINfoTools.pas',
  utils.base64 in 'utils.base64.pas',
  utils.url in 'utils.url.pas',
  ntrip.handler in 'ntrip.handler.pas';

{$R *.res}

begin
  Application.Initialize;
  //ReportMemoryLeaksOnShutdown := true;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
