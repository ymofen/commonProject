unit udmService;

interface

uses
  SysUtils, Classes,
  diocp.tcp.server, IniFiles,  diocp.task,

  utils_async, Windows, vrs_source, utils_rawPackage, utils.strings,
  NtripRequest, utils_BufferPool, utils.queues, utils.hashs;

const
  END_BYTES :array[0..1] of Byte = (13,10);

type
  TMyClientContext = class(TIocpClientContext)
  private
    FRequest: TNtripRequest;
    FRawRequest:String;
    FRequestNMEA: String;
  protected
    procedure DoCleanUp; override;
    procedure OnConnected; override;
    procedure OnDisconnected; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    /// <summary>
    ///  处理客户端发送过来的数据
    /// </summary>
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD); override;
  end;

  /// <summary>
  ///   数据源对应的请求列表
  /// </summary>
  TSourceNodes = class(TObject)
  private
    FRequestHandleList: TList;
    FLocker:Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock();
    procedure UnLock;
    
    procedure AddRequest(pvContext: TMyClientContext);
    function RemoveRequest(pvContext:TMyClientContext): Boolean;
  end;

  TdmService = class(TDataModule)
  private
    FTcpSvr: TDiocpTcpServer;
    FVRSSource: TVRSSoruce;
    FASync:TASyncInvoker;
    FSourceTable:String;

    /// NMEA-> 请求列表
    FRequestNMEAMap: TDHashTableSafe;

    /// <summary>
    ///  初始化信息
    /// </summary>
    procedure ReloadConfig;

    procedure KickContextByHandle(pvSocketHandle:THandle);

    procedure AddNMEARequest(pvNMEA:String; pvContext:TMyClientContext);

    procedure RemoveNMEARequest(pvNMEA:string; pvContext:TMyClientContext);

    procedure DispatchBuffer(pvNMEA:String; pvBuf:Pointer; len:Cardinal);

    procedure OnASyncWorker(pvWorker:TASyncWorker);

    procedure DoRecvRequest(pvContext: TMyClientContext; pvMountPoint, pvData:
        string);

    procedure OnRecvVRSBuffer(pvNMEA:string; buf:Pointer; len:Cardinal);

    function ConvertRequestNMEA(pvData:String): String;

    procedure OnSendBufferCompleted(pvContext: TIocpClientContext; pvBuff: Pointer;
        len: Cardinal; pvBufferTag, pvErrorCode: Integer);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Reload;

    procedure Start;
    procedure Stop;
    
    property TcpSvr: TDiocpTcpServer read FTcpSvr;
    property VRSSource: TVRSSoruce read FVRSSource;
  end;

  

var
  dmService: TdmService;

implementation

uses
  utils.safeLogger, ComObj, DateUtils, ntrip_tools;

{$R *.dfm}

const
  cache_time_interval = 1000 * 60 * 60 * 24;

{ TdmService }

constructor TdmService.Create(AOwner: TComponent);
begin
  inherited;

  FASync := TASyncInvoker.Create;
  FVRSSource := TVRSSoruce.Create;
  FVRSSource.OnRecvVRSBuffer:= OnRecvVRSBuffer;
  FTcpSvr := TDiocpTcpServer.Create(Self);
  FTcpSvr.Port := 8081;
  FTcpSvr.CreateDataMonitor;
  FTcpSvr.RegisterContextClass(TMyClientContext);

  FTcpSvr.OnSendBufferCompleted := OnSendBufferCompleted;

  FRequestNMEAMap := TDHashTableSafe.Create(0);

  __initalizeRequestBufferPool;

end;

destructor TdmService.Destroy;
begin
  FVRSSource.Stop;
  FTcpSvr.SafeStop;
  FTcpSvr.Free;
  FVRSSource.Free;
  
  FRequestNMEAMap.FreeAllDataAsObject;
  FRequestNMEAMap.Free;

  FASync.Free;
  __finalizeRequestBufferPool;
  inherited;
end;

procedure TdmService.AddNMEARequest(pvNMEA:String; pvContext:TMyClientContext);
var
  lvSource:TSourceNodes;
begin
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[pvNMEA]);
  if lvSource = nil then
  begin
    lvSource := TSourceNodes.Create;
    FRequestNMEAMap.ValueMap[pvNMEA] := lvSource;
  end;
  FRequestNMEAMap.unLock;

  lvSource.AddRequest(pvContext);
end;

procedure TdmService.RemoveNMEARequest(pvNMEA:string;
    pvContext:TMyClientContext);
var
  lvSource:TSourceNodes;
begin
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[pvNMEA]);
  FRequestNMEAMap.unLock;

  if lvSource <> nil then
    lvSource.RemoveRequest(pvContext);
end;


function TdmService.ConvertRequestNMEA(pvData:String): String;
begin
  Result := pvData;
end;

procedure TdmService.DispatchBuffer(pvNMEA:String; pvBuf:Pointer; len:Cardinal);
var
  lvSource:TSourceNodes;
  i: Integer;
  
begin
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[pvNMEA]);
  FRequestNMEAMap.unLock;

  if lvSource <> nil then
  begin
    lvSource.Lock;
    try
      for i := 0 to lvSource.FRequestHandleList.Count - 1 do
      begin
        AddRef(pvBuf);
        TIocpClientContext(lvSource.FRequestHandleList[i]).PostWSASendRequest(pvBuf, len, dtNone, 1);
      end;
    finally
      lvSource.UnLock;
    end; 
  end;
end;

procedure TdmService.DoRecvRequest(pvContext: TMyClientContext; pvMountPoint,
    pvData: string);
var
  lvRequestNMEA:String;
begin
  lvRequestNMEA := ConvertRequestNMEA(pvData);
  if lvRequestNMEA <> pvContext.FRequestNMEA then
  begin
    if pvContext.FRequestNMEA <> '' then
    begin
      FVRSSource.ReleaseRequestNMEA(pvContext.FRequestNMEA);
      RemoveNMEARequest(pvContext.FRequestNMEA, pvContext);
    end;

    if lvRequestNMEA <> '' then
    begin
      pvContext.FRawRequest := pvData;
      pvContext.FRequestNMEA := lvRequestNMEA;
      FVRSSource.PostNMEARequest(pvMountPoint, lvRequestNMEA);
      FVRSSource.AddRefRequestNMEA(lvRequestNMEA);
      AddNMEARequest(pvContext.FRequestNMEA, pvContext);
    end;
  end;
end;

procedure TdmService.KickContextByHandle(pvSocketHandle:THandle);
var
  lvContext:TMyClientContext;
begin
  lvContext := TMyClientContext(FTcpSvr.FindContext(pvSocketHandle));
  if lvContext <> nil then
  begin          
    lvContext.PostWSACloseRequest();
  end;
end;

procedure TdmService.OnASyncWorker(pvWorker:TASyncWorker);
var
  s: String;
  lvTickCount, lvKickTickout, lvCheckTimeOut, lvCacheTimeOut, c:Cardinal;
begin
  lvKickTickout := 0;
  lvCheckTimeOut := 0;
  while not FASync.Terminated do
  begin
    lvTickCount := GetTickCount;

    if tick_diff(lvKickTickout, lvTickCount) > 30000 then
    begin // 30秒执行一次
      // 120秒内无响应
      FTcpSvr.KickOut(120000);
      lvKickTickout := lvTickCount;
    end;

    if tick_diff(lvCheckTimeOut, lvTickCount) > 3000 then
    begin
      s := FTcpSvr.GetContextWorkingInfo();
      if s <> '' then
      begin
        sfLogger.logMessage('检测到发现长时间工作连接:' + s, '监测日志', lgvWarning);
      end;

      s := FTcpSvr.IocpEngine.GetWorkerStateInfo();
      if s <> '' then
      begin
        sfLogger.logMessage('检测到发现长时间线程工作:' + s, '监测日志', lgvWarning);
      end;
      lvCheckTimeOut := lvTickCount;
    end;
    Sleep(10);
  end;
end;

procedure TdmService.OnRecvVRSBuffer(pvNMEA:string; buf:Pointer; len:Cardinal);
begin
  DispatchBuffer(pvNMEA, buf, len);
end;

procedure TdmService.OnSendBufferCompleted(pvContext: TIocpClientContext;
    pvBuff: Pointer; len: Cardinal; pvBufferTag, pvErrorCode: Integer);
begin
  if pvBufferTag = 1 then
  begin
    ReleaseRef(pvBuff);
  end;
end;

procedure TdmService.Reload;
begin
  try
    FSourceTable := GetSourceTable(FVRSSource.Host, FVRSSource.Port);
    sfLogger.logMessage('加载SourceTable成功, 长度:%d', [Length(FSourceTable)]);
  except
    on e:Exception do
    begin
      sfLogger.logMessage('获取SourceTable数据失败:%s', [e.Message]);
    end;                                                                 
  end;  
end;

procedure TdmService.ReloadConfig;
var
  lvIniFile:TIniFile;
begin
  lvIniFile:= TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
  try
    lvIniFile.WriteString('vrs_histroy', 'start', FormatDateTime('yyyy-MM-dd hh:nn:ss', Now));
    FTcpSvr.DefaultListenAddress := lvIniFile.ReadString('vrs_config', 'ip', '0.0.0.0');
    FTcpSvr.Port := lvIniFile.ReadInteger('vrs_config', 'Port', 9983);
    FTcpSvr.WorkerCount := lvIniFile.ReadInteger('vrs_config', 'Worker', 0);

    FVRSSource.Host := lvIniFile.ReadString('vrs_config', 'vrsource.host', '127.0.0.1');
    FVRSSource.Port := lvIniFile.ReadInteger('vrs_config', 'vrsource.port', 9984);

  finally
    lvIniFile.Free;
  end;
end;


procedure TdmService.Start;
begin
  ReloadConfig;
  FTcpSvr.Active := True;
  FVRSSource.Start;
  FASync.Start(OnASyncWorker);
end;

procedure TdmService.Stop;
begin
  FASync.Terminate;
  FVRSSource.Stop;
  FTcpSvr.Active := False;

  FASync.WaitForStop;
  
end;

constructor TMyClientContext.Create;
begin
  inherited Create;
  FRequest := TNtripRequest.Create();
end;

destructor TMyClientContext.Destroy;
begin
  FreeAndNil(FRequest);
  inherited Destroy;
end;

procedure TMyClientContext.DoCleanUp;
begin
  inherited DoCleanup;
  FRequest.DoCleanUp;
end;

procedure TMyClientContext.OnConnected;
begin
  inherited;
  FRequest.DoCleanUp;
end;

procedure TMyClientContext.OnDisconnected;
begin
  inherited;
  if FRequestNMEA <> '' then
  begin
    dmService.VRSSource.ReleaseRequestNMEA(FRequestNMEA);
    dmService.RemoveNMEARequest(FRequestNMEA, Self);
    FRequestNMEA := '';
  end;
end;

procedure TMyClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD);
var
  I, r: Integer;
  lvPtr:PByte;
  lvNMEA:String;
begin
  RecordWorkerStartTick;
  try     
    lvPtr := PByte(buf);
    while i < len do
    begin
       r := FRequest.InputBuffer(lvPtr^);
       if r = 1 then
       begin
         sfLogger.logMessage('接收到请求数据,挂载点:%s', [FRequest.MountPoint]);
         Inc(lvPtr);
         Inc(i);
       end else if r = 2 then
       begin  // 接收到请求数据
         lvNMEA := Trim(FRequest.Context);
         if lvNMEA <> '' then
         begin
           sfLogger.logMessage('接收到请求数据:%s', [lvNMEA]);
           dmService.DoRecvRequest(self, FRequest.MountPoint, lvNMEA);
         end;
         Inc(lvPtr);
         Inc(i);
       end else if r = 0 then
       begin
         Inc(lvPtr);
         Inc(i);
       end else
       begin
        sfLogger.logMessage('接收到的客户端请求数据, 解码异常:%d', [r]);
        self.RequestDisconnect(Format('接收到的客户端请求数据, 解码异常:%d', [r]));
        Break;
       end; 
    end;
    
    
  finally
    RecordWorkerEndTick;
  end;

end;

constructor TSourceNodes.Create;
begin
  inherited Create;
  FRequestHandleList := TList.Create();
  FLocker := 0;
end;

destructor TSourceNodes.Destroy;
begin
  FreeAndNil(FRequestHandleList);
  inherited Destroy;
end;

procedure TSourceNodes.Lock;
begin
  SpinLock(FLocker); 
end;

procedure TSourceNodes.AddRequest(pvContext: TMyClientContext);
begin
  SpinLock(FLocker);
  FRequestHandleList.Add(pvContext);
  SpinUnLock(FLocker);
end;

function TSourceNodes.RemoveRequest(pvContext:TMyClientContext): Boolean;
begin
  SpinLock(FLocker);
  Result := FRequestHandleList.Remove(pvContext) >= 0;
  SpinUnLock(FLocker);
end;

procedure TSourceNodes.UnLock;
begin
  SpinUnLock(FLocker);
end;

end.
