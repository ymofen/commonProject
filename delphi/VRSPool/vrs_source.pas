unit vrs_source;

interface

uses
  diocp.tcp.client, SysUtils, utils.hashs, diocp.sockets, utils_BufferPool, Classes;

type
  TOnVRSSourceBufferEvent = procedure(pvMountPoint, pvNMEA: string; buf: Pointer;
      len: Cardinal) of object;
  TVRSClientContext = class;

  PVRSRecord = ^TVRSRecord;
  TVRSRecord = record
    Context:TVRSClientContext;
    refcounter:Integer;
  end;

  TVRSClientContext = class(TIocpRemoteContext)
  private
    FNMEA:AnsiString;
    FRequestMountPoint: String;
    FAuthenticationData: String;
  protected
    procedure OnConnected; override;
    procedure OnDisconnected; override;
  public      
    procedure SetNMEA(pvNMEA:string);
    procedure SetAuthentication(pvData:string);
    property RequestMountPoint: String read FRequestMountPoint write  FRequestMountPoint;
  end;
  
  TVRSSoruce = class(TObject)
  private
    //用于处理逻辑时，分发数据时做引用计数
    FVRSRecvBuffPool:PBufferPool;

    FDiocpTcpClient: TDiocpTcpClient;
    FContextMap: TDHashTableSafe;
    FOnRecvVRSBuffer: TOnVRSSourceBufferEvent;
    procedure OnRecvBuffer(pvContext: TDiocpCustomContext; buf: Pointer; len:
        cardinal; pvErrorCode: Integer);
    procedure ClearVRSContexts;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///  提交一个NMEA请求
    /// </summary>
    function PostNMEARequest(pvRequestMountPoint, pvNMEA: string): Integer;

    /// <summary>
    ///   释放连接
    /// </summary>
    procedure ReleaseRequestNMEA(pvMountPoint, pvNMEA: string);

    /// <summary>
    ///   一个连接引用了这个类
    /// </summary>
    procedure AddRefRequestNMEA(pvMountPoint, pvNMEA: string);

    procedure Start;
    procedure Stop;





    property DiocpTcpClient: TDiocpTcpClient read FDiocpTcpClient;
    property OnRecvVRSBuffer: TOnVRSSourceBufferEvent read FOnRecvVRSBuffer write FOnRecvVRSBuffer;


  end;

implementation

uses
  utils_base64, utils.safeLogger, DataCenter, ntrip_source;

procedure TVRSSoruce.AddRefRequestNMEA(pvMountPoint, pvNMEA: string);
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvDisconnect:Boolean;
  lvMapID:String;
begin
  lvMapID := pvMountPoint + '_' + pvNMEA;
  lvDisconnect := false;
  FContextMap.Lock;

  lvPVRSRecord := FContextMap.ValueMap[lvMapID];
  Assert(lvPVRSRecord <> nil, 'TVRSSoruce.AddRefRequestNMEA Data Error');
  Inc(lvPVRSRecord.refcounter);  
  FContextMap.unLock;
end;

constructor TVRSSoruce.Create;
begin
  inherited Create;
  FDiocpTcpClient := TDiocpTcpClient.Create(nil);
  FDiocpTcpClient.CreateDataMonitor;
  FDiocpTcpClient.RegisterContextClass(TVRSClientContext);
  FDiocpTcpClient.OnReceivedBuffer := OnRecvBuffer;
  FDiocpTcpClient.WorkerCount := 3;
  FContextMap := TDHashTableSafe.Create(0);
  FVRSRecvBuffPool := NewBufferPool(FDiocpTcpClient.WSARecvBufferSize);
  FVRSRecvBuffPool.FName := 'vrsrecv_buff';
end;

destructor TVRSSoruce.Destroy;
begin
  Stop;
  FContextMap.Free;
  FreeAndNil(FDiocpTcpClient);
  FreeBufferPool(FVRSRecvBuffPool);
  inherited Destroy;
end;

procedure TVRSSoruce.OnRecvBuffer(pvContext: TDiocpCustomContext; buf: Pointer;
    len: cardinal; pvErrorCode: Integer);
var
  lvBuff:PByte;
begin
  lvBuff := GetBuffer(FVRSRecvBuffPool);
  Assert(len<=FVRSRecvBuffPool.FBlockSize,
    Format('OnRecvBuffer len(%d)超出长度%d', [len, FVRSRecvBuffPool.FBlockSize]));
  Move(buf^, lvBuff^, len);
  AddRef(lvBuff);
  try
    if Assigned(FOnRecvVRSBuffer) then
    begin
      FOnRecvVRSBuffer(TVRSClientContext(pvContext).FRequestMountPoint, TVRSClientContext(pvContext).FNMEA, lvBuff, len);
    end;
  finally
    ReleaseRef(lvBuff);
  end;
end;

function TVRSSoruce.PostNMEARequest(pvRequestMountPoint, pvNMEA: string):
    Integer;
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvConnect:Boolean;
  lvNtripSource:TNtripSource;
  lvMapID:String;
  lvUser, lvPass, lvHost:String;
  lvPort: Integer;
begin
  lvConnect := false;
  ntripSourceList.Lock;
  lvNtripSource := ntripSourceList.FindSource(pvRequestMountPoint);
  lvHost := lvNtripSource.DValue.GetStrValueByName('host', '');
  lvPort := lvNtripSource.DValue.GetIntValueByName('port', 0);
  lvUser := lvNtripSource.DValue.GetStrValueByName('auth_user', '');
  lvPass := lvNtripSource.DValue.GetStrValueByName('auth_pass', '');
  ntripSourceList.UnLock;
  if lvNtripSource = nil then
  begin
    Result := -1;
    Exit;
  end;
  
  lvMapID := pvRequestMountPoint + '_' + pvNMEA;
  FContextMap.Lock;
  lvPVRSRecord := FContextMap.ValueMap[lvMapID];
  if lvPVRSRecord = nil then
  begin
    New(lvPVRSRecord);
    lvContext := TVRSClientContext(FDiocpTcpClient.Add);
    lvPVRSRecord.Context := lvContext;
    lvPVRSRecord.refcounter := 0;
    lvContext.FNMEA := pvNMEA;
    lvContext.RequestMountPoint := pvRequestMountPoint;
    lvConnect := true;
    FContextMap.ValueMap[lvMapID] := lvPVRSRecord;
  end else
  begin
    lvContext := lvPVRSRecord.Context;
  end;  

  FContextMap.UnLock;

  /// 连接已经处于闲置状态
  if lvContext.AutoReConnect = False then
  begin
    lvConnect := True;
  end;
  

  if lvConnect then
  begin
    if lvHost = '' then raise Exception.CreateFmt('请求[%s]连接配置不完整', [pvRequestMountPoint]);
    lvContext.Host := lvHost;
    lvContext.Port := lvPort;
    if lvUser <> '' then
    begin
      lvContext.SetAuthentication(Base64Encode(Format('%s:%s', [lvUser, lvPass])));
    end;

    lvContext.AutoReConnect := True;
    
    /// 异步连接
    lvContext.ConnectASync;
  end;

  
end;

procedure TVRSSoruce.ReleaseRequestNMEA(pvMountPoint, pvNMEA: string);
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvDisconnect:Boolean;
  lvMapID:String;
begin
  lvDisconnect := false;
  lvMapID := pvMountPoint + '_' + pvNMEA;
  FContextMap.Lock;
  lvPVRSRecord := FContextMap.ValueMap[lvMapID];
  if lvPVRSRecord <> nil then
  begin
    Dec(lvPVRSRecord.refcounter);
    lvDisconnect := lvPVRSRecord.refcounter = 0;
  end;
  FContextMap.unLock;

  if lvDisconnect then
  begin
    lvPVRSRecord.Context.AutoReConnect := False;
    lvPVRSRecord.Context.Close;
  end;
end;

procedure TVRSSoruce.ClearVRSContexts;
begin
  FDiocpTcpClient.DisconnectAll;
  FDiocpTcpClient.ClearContexts;
  FContextMap.DisposeAllDataAsPointer;
  FContextMap.Clear;
end;

procedure TVRSSoruce.Start;
begin
  FDiocpTcpClient.DisableAutoConnect := False;
  FDiocpTcpClient.Open;
end;

procedure TVRSSoruce.Stop;
begin
  FDiocpTcpClient.DisableAutoConnect := true;
  FDiocpTcpClient.Close;
  ClearVRSContexts;
end;

procedure TVRSClientContext.OnConnected;
var
  lvRequest:AnsiString;
begin
  inherited;
  lvRequest := Format('GET /%s HTTP/1.1'#13#10, [FRequestMountPoint]);
  lvRequest := lvRequest + 'User-Agent: NTRIP Survey-Controller-15.0' + #13#10;
  if FAuthenticationData <> '' then
  begin
    lvRequest := lvRequest + 'Authorization: Basic ' + FAuthenticationData +#13#10
  end;

  lvRequest := lvRequest + #13#10;

  if FNMEA <> '' then
  begin
    lvRequest := lvRequest + FNMEA + #13#10;
  end;
  sfLogger.logMessage('发起数据源(%s:%d/%s)请求:%s', [self.Host, self.Port, self.FRequestMountPoint,lvRequest]);
  Self.PostWSASendRequest(PAnsiChar(lvRequest), Length(lvRequest));
end;

procedure TVRSClientContext.OnDisconnected;
begin
  inherited;
  sfLogger.logMessage('与请求数据源(%s)断开连接(%s:%d)', [self.RequestMountPoint, self.Host, self.Port]);
end;

procedure TVRSClientContext.SetAuthentication(pvData:string);
begin
  FAuthenticationData := pvData;
end;

procedure TVRSClientContext.SetNMEA(pvNMEA:string);
begin
  FNMEA := pvNMEA;
end;

end.
