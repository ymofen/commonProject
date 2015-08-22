unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, diocp.p2p.client, IniFiles;

type
  TForm2 = class(TForm)
    pnlTop: TPanel;
    Label1: TLabel;
    edtPort: TEdit;
    btnAbout: TButton;
    btnP2PEngine: TButton;
    edtRemoteIP: TEdit;
    edtRemotPort: TEdit;
    edtMyID: TEdit;
    Label2: TLabel;
    tmrSendTimer: TTimer;
    mmoLog: TMemo;
    edtRemoteID: TEdit;
    btnRequestConnect: TButton;
    procedure btnP2PEngineClick(Sender: TObject);
    procedure btnRequestConnectClick(Sender: TObject);
    procedure tmrSendTimerTimer(Sender: TObject);
  private
    { Private declarations }
    FP2PClient: TDiocpP2PClient;
    procedure ReadHistoryInfo;
    procedure RefreshState;
    procedure WriteHistoryInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses
  utils.safeLogger, ufrmP2P;

{$R *.dfm}

constructor TForm2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FP2PClient := TDiocpP2PClient.Create();
  ReadHistoryInfo;

  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  TStringsAppender(sfLogger.Appender).AddTimeInfo := True;
  sfLogger.AppendInMainThread := true;
end;

destructor TForm2.Destroy;
begin
  WriteHistoryInfo;
  FP2PClient.Free;
  inherited Destroy;
end;

procedure TForm2.btnP2PEngineClick(Sender: TObject);
begin
  if FP2PClient.DiocpUdp.Active then
  begin
    FP2PClient.DiocpUdp.Stop();
  end else
  begin
    FP2PClient.P2PServerAddr := edtRemoteIP.Text;
    FP2PClient.P2PServerPort := StrToInt(edtRemotPort.Text);
    FP2PClient.DiocpUdp.DefaultListener.Port := StrToInt(edtPort.Text);
    FP2PClient.DiocpUdp.Start();
    FP2PClient.Start();
  end;
  RefreshState;              
end;

procedure TForm2.btnRequestConnectClick(Sender: TObject);
begin
  FP2PClient.RequestConnect(StrToInt(edtRemoteID.Text));
  
  btnRequestConnect.Enabled := false;
  btnRequestConnect.Caption := '请求连接中...';

end;

procedure TForm2.ReadHistoryInfo;
var
  lvIniFile:TIniFile;
  s:String;
begin
  lvIniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.history.ini'));
  try
    edtPort.Text :=  IntToStr(StrToIntDef(lvIniFile.ReadString('ui', 'listenPort', ''), 9984));
    edtRemoteIP.Text :=  lvIniFile.ReadString('ui', 'remoteHost', '127.0.0.1');
    edtRemotPort.Text :=  IntToStr(StrToIntDef(lvIniFile.ReadString('ui', 'remotePort', ''), 9984));
  finally
    lvIniFile.Free;
  end;
  
end;

procedure TForm2.RefreshState;
begin
  if FP2PClient.DiocpUdp.Active then
  begin
    btnP2PEngine.Caption := '点击关闭';
  end else
  begin
    btnP2PEngine.Caption := '点击开启';
  end;
end;

procedure TForm2.tmrSendTimerTimer(Sender: TObject);
var
  lvP2PState:Integer;
begin
  if not FP2PClient.DiocpUdp.Active then
  begin
    edtMyID.Text := '服务关闭';
    Exit;
  end;

  if FP2PClient.ActiveState = asActiving then
  begin
    edtMyID.Text := '正在激活...';
  end else if FP2PClient.ActiveState = asFault then
  begin
    edtMyID.Text := '激活失败!';
  end else if FP2PClient.ActiveState = asActive then
  begin
    edtMyID.Text := IntToStr(FP2PClient.SessionID);

    if btnRequestConnect.Enabled = False then
    begin
      lvP2PState := FP2PClient.QueryP2PState(StrToInt(edtRemoteID.Text));
      if lvP2PState = 1 then  // 已经打通
      begin
        btnRequestConnect.Caption := '连接成功';
        btnRequestConnect.Enabled := True;
        CreateP2PForm(StrToInt(edtRemoteID.Text)); 
      end else if lvP2PState = 2 then // 打洞失败
      begin
        btnRequestConnect.Caption := '失败';
        btnRequestConnect.Enabled := True;
      end else if lvP2PState = 3 then
      begin  //打洞失败
        btnRequestConnect.Caption := '对方不在线';
        btnRequestConnect.Enabled := True;
      end else if lvP2PState = -1 then
      begin
        btnRequestConnect.Caption := 'SESSION不存在...';
        btnRequestConnect.Enabled := True;
      end else
      begin
        btnRequestConnect.Caption := Format('当前状态:%d', [lvP2PState]);
      end;

    end;
  end;
end;

procedure TForm2.WriteHistoryInfo;
var
  lvIniFile:TIniFile;
  s:String;
begin
  lvIniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.history.ini'));
  try
    lvIniFile.WriteString('ui', 'listenPort', edtPort.Text);
    lvIniFile.WriteString('ui', 'remoteHost', edtRemoteIP.Text);
    lvIniFile.WriteString('ui', 'remotePort', edtRemotPort.Text);

  finally
    lvIniFile.Free;
  end;
end;

end.
