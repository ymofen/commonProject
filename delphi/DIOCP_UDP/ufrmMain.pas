unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, diocp.core.rawWinSocket, StdCtrls, diocp.winapi.winsock2, diocp.udp, utils.safeLogger,
  ExtCtrls, ComCtrls, utils.base64, dxGDIPlusClasses;

type
  TForm1 = class(TForm)
    pnlTop: TPanel;
    btnStart: TButton;
    edtPort: TEdit;
    Label1: TLabel;
    pnlClient: TPanel;
    pnlSendPanel: TPanel;
    Panel1: TPanel;
    pnlRecvTop: TPanel;
    pnlSendTop: TPanel;
    mmoSend: TMemo;
    mmoRecv: TMemo;
    chkStringOut: TCheckBox;
    edtRemoteIP: TEdit;
    edtRemotPort: TEdit;
    btnSend: TButton;
    chkEcho: TCheckBox;
    Splitter1: TSplitter;
    chkOutTime: TCheckBox;
    chkWordWrap: TCheckBox;
    btnClear: TButton;
    edtSendInterval: TEdit;
    tmrSendTimer: TTimer;
    chkSendTimer: TCheckBox;
    btnAbout: TButton;
    procedure btnAboutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure chkEchoClick(Sender: TObject);
    procedure chkLogRecvClick(Sender: TObject);
    procedure chkOutTimeClick(Sender: TObject);
    procedure chkSendTimerClick(Sender: TObject);
    procedure chkWordWrapClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrSendTimerTimer(Sender: TObject);
  private
    { Private declarations }
    FRawSocket:TRawSocket;
    FDiocpUdp: TDiocpUdp;
    procedure RefreshState();
    procedure WriteHistoryInfo;
    procedure ReadHistoryInfo;
  public
    constructor Create(AOwner: TComponent); override;
    procedure OnRecv(pvReqeust:TDiocpUdpRecvRequest);



  end;

var
  Form1: TForm1;
  __logRecv:Boolean;
  __recvEcho:Boolean;

implementation

uses
  IniFiles, ufrmAbout;


{$R *.dfm}

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited;
  sfLogger.setAppender(TStringsAppender.Create(mmoRecv.Lines));

  sfLogger.AppendInMainThread := true;
  FDiocpUdp := TDiocpUdp.Create(Self);
  FDiocpUdp.OnRecv := OnRecv;  
end;

procedure TForm1.btnAboutClick(Sender: TObject);
begin
  with TfrmAbout.Create(Self) do
  try
    ShowModal();
  finally
    Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  RefreshState;
  ReadHistoryInfo;
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  mmoRecv.Clear;
end;

procedure TForm1.btnSendClick(Sender: TObject);
var
  s :AnsiString;
begin              
  s := mmoSend.Text;
  if s = '' then
  begin
    chkSendTimer.Checked := false;
    tmrSendTimer.Enabled := false;
    raise Exception.Create('请输入要发送的内容');
  end;
  FDiocpUdp.WSASendTo(edtRemoteIP.Text, StrToInt(edtRemotPort.Text), PAnsiChar(s), length(s));
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  if FDiocpUdp.Active then
  begin
    FDiocpUdp.Stop();
  end else
  begin
    FDiocpUdp.DefaultListener.Port := StrToInt(edtPort.Text);
    FDiocpUdp.Start();
    __logRecv := chkStringOut.Checked;
    __recvEcho := chkEcho.Checked;
  end;

  RefreshState;
end;

procedure TForm1.chkEchoClick(Sender: TObject);
begin
  __recvEcho := chkEcho.Checked;
end;

procedure TForm1.chkLogRecvClick(Sender: TObject);
begin
  __logRecv := chkStringOut.Checked;
end;

procedure TForm1.chkOutTimeClick(Sender: TObject);
begin
  TStringsAppender(sfLogger.Appender).AddTimeInfo := chkOutTime.Checked;
end;

procedure TForm1.chkSendTimerClick(Sender: TObject);
begin
  tmrSendTimer.Interval := StrToInt(edtSendInterval.Text);
  tmrSendTimer.Enabled := chkSendTimer.Checked;
end;

procedure TForm1.chkWordWrapClick(Sender: TObject);
begin
  mmoRecv.WordWrap := chkWordWrap.Checked;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  WriteHistoryInfo;
end;

procedure TForm1.OnRecv(pvReqeust:TDiocpUdpRecvRequest);
var
  s:AnsiString;
begin
  if __logRecv then
  begin
    s := PAnsiChar(pvReqeust.RecvBuffer);
    s[pvReqeust.RecvBufferLen + 1] := #0;
    sfLogger.logMessage(Format('[%s:%d]- %s', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, s]));
  end;
  if __recvEcho then
  begin
    pvReqeust.SendResponse(pvReqeust.RecvBuffer, pvReqeust.RecvBufferLen);
    Sleep(10);
  end;
end;

procedure TForm1.ReadHistoryInfo;
var
  lvIniFile:TIniFile;
  s:String;
begin
  lvIniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.history.ini'));
  try
    edtPort.Text :=  IntToStr(StrToIntDef(lvIniFile.ReadString('ui', 'listenPort', ''), 9984));
    edtRemoteIP.Text :=  lvIniFile.ReadString('ui', 'remoteHost', '127.0.0.1');
    edtRemotPort.Text :=  IntToStr(StrToIntDef(lvIniFile.ReadString('ui', 'remotePort', ''), 9984));
    edtSendInterval.Text :=  IntToStr(StrToIntDef(lvIniFile.ReadString('ui', 'sendInterval', ''), 1000));

    s := lvIniFile.ReadString('ui', 'sendstr', '');
    if s <> '' then
    begin
      mmoSend.Lines.Text := Base64ToStr(s);
    end;



    chkStringOut.Checked := lvIniFile.ReadBool('ui', 'stringOut', true);
    chkOutTime.Checked :=lvIniFile.ReadBool('ui', 'recvShowTime', True);
    chkEcho.Checked :=lvIniFile.ReadBool('ui', 'recvEcho', False);
    chkWordWrap.Checked :=lvIniFile.ReadBool('ui', 'recvWordWrap', True);
  finally
    lvIniFile.Free;
  end;
  
end;

procedure TForm1.RefreshState;
begin
  if FDiocpUdp.Active then
  begin
    btnStart.Caption := '点击关闭';
  end else
  begin
    btnStart.Caption := '点击开启';
  end;

  chkSendTimer.Enabled := FDiocpUdp.Active;
  btnSend.Enabled := FDiocpUdp.Active;
end;

procedure TForm1.tmrSendTimerTimer(Sender: TObject);
begin
  btnSend.Click;
end;

procedure TForm1.WriteHistoryInfo;
var
  lvIniFile:TIniFile;
  s:String;
begin
  s := mmoSend.Text;
  s := StrToBase64(s);
  lvIniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.history.ini'));
  try
    lvIniFile.WriteString('ui', 'listenPort', edtPort.Text);
    lvIniFile.WriteString('ui', 'remoteHost', edtRemoteIP.Text);
    lvIniFile.WriteString('ui', 'remotePort', edtRemotPort.Text);
    lvIniFile.WriteString('ui', 'sendInterval', edtSendInterval.Text);
    lvIniFile.WriteString('ui', 'sendstr', s);



    lvIniFile.WriteBool('ui', 'stringOut', chkStringOut.Checked);
    lvIniFile.WriteBool('ui', 'recvShowTime', chkOutTime.Checked);
    lvIniFile.WriteBool('ui', 'recvEcho', chkEcho.Checked);
    lvIniFile.WriteBool('ui', 'recvWordWrap', chkWordWrap.Checked);
  finally
    lvIniFile.Free;
  end;
end;

end.
