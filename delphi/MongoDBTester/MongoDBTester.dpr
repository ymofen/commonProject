program MongoDBTester;

uses
  Vcl.Forms,
  ufrmMain in 'ufrmMain.pas' {frmMain},
  DriverBson in 'MongoDBAPI\DriverBson.pas',
  DriverMongo in 'MongoDBAPI\DriverMongo.pas',
  MongoDBAPI in 'MongoDBAPI\MongoDBAPI.pas';

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := true;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
