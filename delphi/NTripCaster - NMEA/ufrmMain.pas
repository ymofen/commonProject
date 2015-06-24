unit ufrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, diocp.ex.ntrip, Vcl.StdCtrls,
  Vcl.ComCtrls, System.Actions, Vcl.ActnList, utils.base64, IniFiles,
  Vcl.ExtCtrls, diocp.tcp.client, utils.queues, System.SyncObjs, diocp.sockets;

type
  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    tsConfig: TTabSheet;
    edtPort: TEdit;
    Label1: TLabel;
    tsMonitor: TTabSheet;
    actlstMain: TActionList;
    btnStart: TButton;
    actStart: TAction;
    tmrCheck: TTimer;
    tsLog: TTabSheet;
    mmoLog: TMemo;
    edtNMEAHost: TEdit;
    edtNMEAPort: TEdit;
    procedure actStartExecute(Sender: TObject);
  private
    FLocker:TCriticalSection;


    FNtripServer:TDiocpNtripServer;

    FRequestNMEAClients:TDiocpTcpClient;
    FRequestContextPool: TSafeQueue;

    FNtripSourcePass:String;

    function GetRequestContext: TIocpRemoteContext;

    procedure OnRequestContextDisconnected(pvContext: TDiocpCustomContext);
    procedure OnRequestContextRecvBuffer(pvContext: TDiocpCustomContext; buf:
        Pointer; len: cardinal; pvErrorCode: Integer);

    procedure OnNTripRequest(pvRequest: TDiocpNTripRequest);
    procedure OnNTripRequestAccept(pvRequest: TDiocpNTripRequest; var vIsNMEA:Boolean);

    procedure OnNTripSourceRecvBuffer(pvContext:TDiocpNtripClientContext;buf: Pointer; len: Cardinal);

    // 请求NMEA数据
    procedure RequestNMEA(pvRequest: TDiocpNTripRequest);


    procedure ReloadConfig;
    procedure SaveConfig;
  public

    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;


  end;

var
  frmMain: TfrmMain;

implementation

uses
  uFMMonitor, utils.strings, utils.safeLogger, ntrip.handler;

{$R *.dfm}

{ TForm1 }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FLocker := TCriticalSection.Create;

  FRequestNMEAClients := TDiocpTcpClient.Create(Self);
  FRequestNMEAClients.OnContextDisconnected := OnRequestContextDisconnected;
  FRequestNMEAClients.OnReceivedBuffer := OnRequestContextRecvBuffer;
  FRequestNMEAClients.Open;
  FRequestContextPool := TSafeQueue.Create;


  FNtripServer := TDiocpNtripServer.Create(Self);
  FNtripServer.OnDiocpNtripRequest := OnNTripRequest;
  FNtripServer.OnDiocpRecvNtripSourceBuffer := OnNTripSourceRecvBuffer;
  FNtripServer.OnRequestAcceptEvent := OnNTripRequestAccept;
  FNtripServer.CreateDataMonitor;

  TFMMonitor.CreateAsChild(tsMonitor, FNtripServer);
  ReloadConfig();


  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  sfLogger.AppendInMainThread := true;
end;

destructor TfrmMain.Destroy;
begin
  FRequestContextPool.Free;
  FLocker.Free;

  inherited;
end;

procedure TfrmMain.actStartExecute(Sender: TObject);
begin
  if FNtripServer.Active then
  begin
    FNtripServer.Active := false;
    actStart.Caption := '点击开启';
  end else
  begin
    ReloadSourceTable;
    __NMEAPort := StrToIntDef(edtNMEAPort.Text, 4001);
    __NMEAHost := edtNMEAHost.Text;
    SaveConfig;
    FNtripServer.Port := StrToInt(edtPort.Text);
    FNtripServer.Active := true;
    actStart.Caption := '点击停止';
  end;
end;

function TfrmMain.GetRequestContext: TIocpRemoteContext;
begin
  Result :=TIocpRemoteContext(FRequestContextPool.DeQueue);
  if Result = nil then
  begin
    FLocker.Enter;
    try
      Result := FRequestNMEAClients.Add;
    finally
      FLocker.Leave;
    end;
  end;
end;

procedure TfrmMain.OnNTripRequest(pvRequest: TDiocpNTripRequest);
var
  lvAuth, lvValue, lvUser, lvPass:string;
  p:PChar;
  lvContext, lvNtripSourceContext:TDiocpNtripClientContext;
  lvAuthentication, lvIsNMEA:Boolean;
begin
  lvContext := pvRequest.Connection;
  lvAuthentication := false;
  if pvRequest.ExtractBasicAuthenticationInfo(lvUser, lvPass) then
  begin
    // 准备进行验证
    // lvAuthentication := __ntripCasterDataCenter.Authentication(lvUser, lvPass);
    lvAuthentication := true;
    if lvAuthentication then
    begin   // 认证成功
      if pvRequest.MountPoint <> '' then
      begin
        lvIsNMEA := true;
        if lvIsNMEA then         // NMEA 的挂载点
        begin
          sfLogger.logMessage(pvRequest.ExtractNMEAString);

          RequestNMEA(pvRequest);


        end else
        begin
          // 请求的NtripSource
          lvNtripSourceContext := FNtripServer.FindNtripSource(pvRequest.MountPoint);
          if lvNtripSourceContext = nil then
          begin  // 找不到在线的NtripSource
            ResponseSourceTableAndOK(pvRequest);
            pvRequest.CloseContext;
            Exit;
          end else
          begin  // 验证成功
            // 加入待分发队列
            lvNtripSourceContext.AddNtripClient(lvContext);

            // 回复客户端
            pvRequest.Response.ICY200OK;
            Exit;
          end;
        end;
      end else
      begin
        ResponseSourceTableAndOK(pvRequest);

        pvRequest.CloseContext;
        Exit;
      end;
    end;
  end;

  if not lvAuthentication then      // 认证失败
  begin
    if pvRequest.MountPoint = '' then
    begin  // 获取MountPoint数据
      ResponseSourceTableAndOK(pvRequest);

      pvRequest.CloseContext;
    end else
    begin
      pvRequest.Response.Unauthorized;
      pvRequest.Response.InvalidPasswordMsg(pvRequest.MountPoint);
      pvRequest.CloseContext;
    end;
  end;


end;

procedure TfrmMain.OnNTripRequestAccept(pvRequest: TDiocpNTripRequest;
  var vIsNMEA: Boolean);
begin
  //  if pvRequest.MountPoint = '' then
  vIsNMEA := true;

end;

procedure TfrmMain.OnNTripSourceRecvBuffer(pvContext: TDiocpNtripClientContext;
  buf: Pointer; len: Cardinal);
begin
  // 分发GNSS数据
  pvContext.DispatchGNSSDATA(buf, len);
end;

procedure TfrmMain.OnRequestContextDisconnected(pvContext: TDiocpCustomContext);
begin
  pvContext.Data := nil;
  FRequestContextPool.EnQueue(pvContext);
end;

procedure TfrmMain.OnRequestContextRecvBuffer(pvContext: TDiocpCustomContext;
    buf: Pointer; len: cardinal; pvErrorCode: Integer);
var
  lvContext:TDiocpNtripClientContext;
begin
  lvContext := TDiocpNtripClientContext(pvContext.Data);
  if lvContext = nil then
  begin
    // 对应的请求客户端不存在
    pvContext.Close;
    exit;
  end;

  if not lvContext.Active then
  begin
    // 对应的请求客户端断开
    pvContext.Close;
    exit;
  end;

  if lvContext.Data <> pvContext then
  begin  // 对应的请求客户端绑定的不是该连接
    pvContext.Close;
    exit;
  end;

  /// 投递回客户端
  lvContext.PostWSASendRequest(buf, len, true);
end;

procedure TfrmMain.ReloadConfig;
var
  lvINIFile:TINIFile;
  lvIntValue:Integer;
  lvStrValue:String;
begin
  lvINIFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
  try
    lvIntValue := lvINIFile.ReadInteger('main', 'port', 0);
    if lvIntValue = 0 then
    begin
      lvIntValue := 2101;
      lvINIFile.WriteInteger('main', 'port', lvIntValue);
    end;

    lvStrValue := lvINIFile.ReadString('main', 'sourcePass', '');
    if lvStrValue = '' then
    begin
      lvStrValue := 'admin';
      lvINIFile.WriteString('main', 'sourcePass', lvStrValue);
    end;
    edtPort.Text := intToStr(lvIntValue);
    FNtripServer.NtripSourcePassword := lvStrValue;

    edtNMEAHost.Text := lvINIFile.ReadString('main', 'NMEAHost', '127.0.0.1');
    edtNMEAPort.Text := lvINIFile.ReadString('main', 'NMEAPort', '4001');
  finally
    lvINIFile.Free;
  end;

end;

procedure TfrmMain.RequestNMEA(pvRequest: TDiocpNTripRequest);
var
  lvRequestClient:TIocpRemoteContext;
  lvNMEAData:AnsiString;
begin
  lvRequestClient :=TIocpRemoteContext(pvRequest.Connection.Data);
  if lvRequestClient = nil then
  begin
    lvRequestClient := GetRequestContext;

    // 相互绑定
    pvRequest.Connection.Data := lvRequestClient;
    lvRequestClient.Data := pvRequest.Connection;
  end;

  if (not lvRequestClient.Active) then
  begin
    try
      lvRequestClient.Host := __NMEAHost;
      lvRequestClient.Port := __NMEAPort;
      lvRequestClient.Connect;
    except
      on e:Exception do
      begin
        sfLogger.logMessage('转发NMEA请求时出现了异常:' + e.Message);
      end;
    end;
  end;



  lvNMEAData := trim(pvRequest.ExtractNMEAString);
  lvRequestClient.PostWSASendRequest(PAnsiChar(lvNMEAData), Length(lvNMEAData));
end;

procedure TfrmMain.SaveConfig;
var
  lvINIFile:TINIFile;
  lvIntValue:Integer;
begin
  lvINIFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
  try
    lvIntValue := StrToIntDef(edtPort.Text, 2101);
    lvINIFile.WriteInteger('main', 'port', lvIntValue);

    lvINIFile.WriteString('main', 'NMEAHost', edtNMEAHost.Text);

    lvIntValue := StrToIntDef(edtNMEAPort.Text, 2101);
    lvINIFile.WriteInteger('main', 'NMEAPort', lvIntValue);
  finally
    lvINIFile.Free;
  end;
end;

end.
