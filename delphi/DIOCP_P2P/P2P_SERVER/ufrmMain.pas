unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, diocp.udp, StdCtrls, ExtCtrls, diocp.p2p, ComCtrls;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    Label1: TLabel;
    btnStart: TButton;
    edtPort: TEdit;
    btnAbout: TButton;
    PageControl1: TPageControl;
    tsLog: TTabSheet;
    TabSheet2: TTabSheet;
    mmoLog: TMemo;
    procedure btnStartClick(Sender: TObject);
  private
    { Private declarations }
    FP2PManager:TDiocpP2PManager;
    procedure RefreshState;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  utils.safeLogger;

{$R *.dfm}

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FP2PManager := TDiocpP2PManager.Create;
  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  TStringsAppender(sfLogger.Appender).AddTimeInfo := True;
  sfLogger.AppendInMainThread := true;
end;

destructor TfrmMain.Destroy;
begin
  FP2PManager.Free;
  inherited;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if FP2PManager.DiocpUdp.Active then
  begin
    FP2PManager.DiocpUdp.Stop();
  end else
  begin
    FP2PManager.DiocpUdp.DefaultListener.Port := StrToInt(edtPort.Text);
    FP2PManager.DiocpUdp.Start();
  end;
  RefreshState;

end;

procedure TfrmMain.RefreshState;
begin
  if FP2PManager.DiocpUdp.Active then
  begin
    btnStart.Caption := '点击关闭';
  end else
  begin
    btnStart.Caption := '点击开启';
  end;
end;

end.
