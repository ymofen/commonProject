unit udmService;

interface

uses
  SysUtils, Classes,
  diocp.tcp.server, IniFiles,  diocp.task,

  utils_async, Windows, vrs_source, utils_rawPackage, utils.strings,
  NtripRequest, utils_BufferPool, utils.queues, utils.hashs, ntrip_source;

const
  END_BYTES :array[0..1] of Byte = (13,10);

type
  TMyClientContext = class(TIocpClientContext)
  private
    FRequest: TNtripRequest;
    FRawRequest:String;
    FRequestNMEA: String;
    FRequestMountPoint:String;
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
    FConvertNMEA:Integer;
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

    procedure AddNMEARequest(pvRequestMountPoint, pvNMEA: string; pvContext:
        TMyClientContext);

    procedure RemoveNMEARequest(pvRequestMountPoint, pvNMEA: string; pvContext:
        TMyClientContext);

    procedure DispatchBuffer(pvMountPoint, pvNMEA: string; pvBuf: Pointer; len:
        Cardinal);

    procedure OnASyncWorker(pvWorker:TASyncWorker);

    procedure DoRecvRequest(pvContext: TMyClientContext;
        pvMountPoint, pvData: string);

    procedure OnRecvVRSBuffer(pvMountPoint, pvNMEA: string; buf: Pointer; len:
        Cardinal);

    function ConvertRequestNMEA(pvData:String): String;

    procedure OnSendBufferCompleted(pvContext: TIocpClientContext; pvBuff: Pointer;
        len: Cardinal; pvBufferTag, pvErrorCode: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    ///  初始化信息
    /// </summary>
    procedure ReloadForCommand;
    procedure Start;
    procedure Stop;

    property TcpSvr: TDiocpTcpServer read FTcpSvr;
    property VRSSource: TVRSSoruce read FVRSSource;
  end;

  

var
  dmService: TdmService;

function GetNmeaW(InNmea: PWideChar): PWideChar; external 'libNmeaGrid.dll';

implementation

uses
  utils.safeLogger, ComObj, DateUtils, ntrip_tools, DataCenter;

{$R *.dfm}

const
  cache_time_interval = 1000 * 60 * 60 * 24;

{ TdmService }

constructor TdmService.Create(AOwner: TComponent);
begin
  inherited;
  ntripSourceList := TNtripSources.Create;

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

  ntripSourceList.Free;

  FASync.Free;
  __finalizeRequestBufferPool;
  inherited;
end;

procedure TdmService.AddNMEARequest(pvRequestMountPoint, pvNMEA: string;
    pvContext: TMyClientContext);
var
  lvSource:TSourceNodes;
  lvMapID:String;
begin
  lvMapID := pvRequestMountPoint+'_'+ pvNMEA;
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[lvMapID]);
  if lvSource = nil then
  begin
    lvSource := TSourceNodes.Create;
    FRequestNMEAMap.ValueMap[lvMapID] := lvSource;
  end;
  FRequestNMEAMap.unLock;

  lvSource.AddRequest(pvContext);

  sfLogger.logMessage('绑定请求数据源:%s<=>([%d]%s:%d)', [lvMapID, pvContext.SocketHandle, pvContext.RemoteAddr, pvContext.RemotePort]);
end;

procedure TdmService.RemoveNMEARequest(pvRequestMountPoint, pvNMEA: string;
    pvContext: TMyClientContext);
var
  lvSource:TSourceNodes;
  lvMapID:String;
begin
  lvMapID := pvRequestMountPoint+'_'+ pvNMEA;
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[lvMapID]);
  FRequestNMEAMap.unLock;

  sfLogger.logMessage('取消绑定请求数据源:%s<=>([%d]%s:%d)',
    [lvMapID, pvContext.SocketHandle, pvContext.RemoteAddr, pvContext.RemotePort]);

  if lvSource <> nil then
    lvSource.RemoveRequest(pvContext);
end;


function TdmService.ConvertRequestNMEA(pvData:String): String;
var
  lvTmpWStr:WideString;
begin
  lvTmpWStr := pvData;
  Result :=  GetNmeaW(PWideChar(lvTmpWStr));
  
end;

procedure TdmService.DispatchBuffer(pvMountPoint, pvNMEA: string; pvBuf:
    Pointer; len: Cardinal);
var
  lvSource:TSourceNodes;
  i, j: Integer;
  lvMapID:String;
begin
  lvMapID := pvMountPoint + '_' + pvNMEA;
  FRequestNMEAMap.Lock;
  lvSource := TSourceNodes(FRequestNMEAMap.ValueMap[lvMapID]);
  FRequestNMEAMap.unLock;

  if lvSource <> nil then
  begin
    lvSource.Lock;
    try
      j := 0;
      for i := lvSource.FRequestHandleList.Count - 1 downto 0 do
      begin
        AddRef(pvBuf);
        if TIocpClientContext(lvSource.FRequestHandleList[i]).PostWSASendRequest(pvBuf, len, dtNone, 1) then
        begin
          inc(j);
        end else
        begin
          //lvSource.FRequestHandleList.Delete(i);
          ReleaseRef(pvBuf);
        end;
      end;
    finally
      lvSource.UnLock;
    end;
    sfLogger.logMessage('转发数据源[%s]数据(%d), 转发数量:%d/%d', [lvMapID, len,
      j, lvSource.FRequestHandleList.Count]);
  end else
  begin
    sfLogger.logMessage('转发数据源[%s]数据(%d)时发现没有请求的客户端连接', [lvMapID, len]);
  end;
end;

procedure TdmService.DoRecvRequest(pvContext: TMyClientContext; pvMountPoint,
    pvData: string);
var
  lvRequestNMEA:String;
  lvPtr:PChar;
begin
  try
    if FConvertNMEA = 1 then
    begin
      lvRequestNMEA := pvData;
      lvPtr := PChar(lvRequestNMEA);
      if StartWith(lvPtr, '$PCMD,', False) then
      begin
        Inc(lvPtr, 6);
        SkipUntil(lvPtr, ['$']);
        lvRequestNMEA := lvPtr;
      end;       
      sfLogger.logMessage('(%s:%d)接收到请求数据:%s_convert_start', [pvContext.RemoteAddr, pvContext.RemotePort,pvData]);
      lvRequestNMEA := ConvertRequestNMEA(lvRequestNMEA);
      sfLogger.logMessage('(%s:%d)接收到请求数据:%s_convert_end', [pvContext.RemoteAddr, pvContext.RemotePort,lvRequestNMEA]);
    end else
    begin
      lvRequestNMEA := pvData;
    end;

    // 非法的位置数据(不要取消当前绑定)
    if lvRequestNMEA = '' then Exit;

    if lvRequestNMEA <> pvContext.FRequestNMEA then
    begin
      if pvContext.FRequestNMEA <> '' then
      begin
        //引用计数
        FVRSSource.ReleaseRequestNMEA(pvContext.FRequestMountPoint, pvContext.FRequestNMEA);
        RemoveNMEARequest(pvContext.FRequestMountPoint, pvContext.FRequestNMEA, pvContext);
      end;

      if lvRequestNMEA <> '' then
      begin
        pvContext.FRawRequest := pvData;
        pvContext.FRequestNMEA := lvRequestNMEA;
        pvContext.FRequestMountPoint := pvMountPoint;

        FVRSSource.PostNMEARequest(pvMountPoint, lvRequestNMEA);
        
        //引用计数
        FVRSSource.AddRefRequestNMEA(pvMountPoint, lvRequestNMEA);

        AddNMEARequest(pvMountPoint, pvContext.FRequestNMEA, pvContext);
      end;
    end;
  except on e:Exception do
    begin
      sfLogger.logMessage('DoRecvRequest(%s, %s) 异常:%s', [pvMountPoint, pvData, e.Message]);
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

    if tick_diff(lvCheckTimeOut, lvTickCount) > 10000 then
    begin
      s := FTcpSvr.GetContextWorkingInfo();
      if s <> '' then
      begin
        sfLogger.logMessage('接入服务检测到发现长时间工作连接:' + s, '监测日志', lgvWarning);
      end;

      s := FTcpSvr.IocpEngine.GetWorkerStateInfo();
      if s <> '' then
      begin
        sfLogger.logMessage('接入服务检测到发现长时间线程工作:' + s, '监测日志', lgvWarning);
      end;

      s := FVRSSource.DiocpTcpClient.IocpEngine.GetWorkerStateInfo();
      if s <> '' then
      begin
        sfLogger.logMessage('数据源接收服务检测到发现长时间线程工作:' + s, '监测日志', lgvWarning);
      end;
      lvCheckTimeOut := lvTickCount;
    end;
    Sleep(10);
  end;
end;

procedure TdmService.OnRecvVRSBuffer(pvMountPoint, pvNMEA: string; buf:
    Pointer; len: Cardinal);
begin
  DispatchBuffer(pvMountPoint, pvNMEA, buf, len);
end;

procedure TdmService.OnSendBufferCompleted(pvContext: TIocpClientContext;
    pvBuff: Pointer; len: Cardinal; pvBufferTag, pvErrorCode: Integer);
begin
  if pvBufferTag = 1 then
  begin
    ReleaseRef(pvBuff);
  end;
end;

procedure TdmService.ReloadConfig;
var
  lvIniFile:TIniFile;
  i: Integer;
  lvNtripSource:TNtripSource;

begin
  ReloadSourceTable;
  ntripSourceList.Lock;
  try
    ntripSourceList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'sourceTable.txt');
  
    lvIniFile:= TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
    try
      lvIniFile.WriteString('vrs_histroy', 'start', FormatDateTime('yyyy-MM-dd hh:nn:ss', Now));
      FTcpSvr.DefaultListenAddress := lvIniFile.ReadString('vrs_config', 'ip', '0.0.0.0');
      FTcpSvr.Port := lvIniFile.ReadInteger('vrs_config', 'Port', 2101);
      FTcpSvr.WorkerCount := lvIniFile.ReadInteger('vrs_config', 'Worker', 0);

      FConvertNMEA := lvIniFile.ReadInteger('vrs_config', 'convert_nmea', 0);

      if ntripSourceList.Count = 0 then
      begin
        sfLogger.logMessage('警告:没有挂载点配置,无法进行正常服务!');
      end else
      begin  
        for i := 0 to ntripSourceList.Count - 1 do
        begin
          lvNtripSource := ntripSourceList.Items[i];
          lvNtripSource.DValue.ForceByName('host').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.host', '127.0.0.1');
          lvNtripSource.DValue.ForceByName('port').AsInteger :=
            lvIniFile.ReadInteger('vrs_source', lvNtripSource.MountPoint + '.port', 9984);
          lvNtripSource.DValue.ForceByName('auth_user').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.auth.user', '');
          lvNtripSource.DValue.ForceByName('auth_pass').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.auth.pass', '');
          lvNtripSource.DValue.ForceByName('mountpoint').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.mountpoint', lvNtripSource.MountPoint);

          sfLogger.logMessage('挂载点[%s->%s]请求数据源配置:%s:%d',
            [lvNtripSource.MountPoint,
            lvNtripSource.DValue.ForceByName('mountpoint').AsString,
            lvNtripSource.DValue.ForceByName('host').AsString,
            lvNtripSource.DValue.ForceByName('port').AsInteger]);             
        end;
      end;
    finally
      lvIniFile.Free;
    end;
  finally
    ntripSourceList.UnLock;
  end;


end;

procedure TdmService.ReloadForCommand;
var
  lvIniFile:TIniFile;
  i: Integer;
  lvNtripSource:TNtripSource;

begin
  ReloadSourceTable;
  ntripSourceList.Lock;
  try
    ntripSourceList.Clear;
    ntripSourceList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'sourceTable.txt');
  
    lvIniFile:= TIniFile.Create(ChangeFileExt(ParamStr(0), '.config.ini'));
    try
      FConvertNMEA := lvIniFile.ReadInteger('vrs_config', 'convert_nmea', 0);

      if ntripSourceList.Count = 0 then
      begin
        sfLogger.logMessage('警告:没有挂载点配置,无法进行正常服务!');
      end else
      begin  
        for i := 0 to ntripSourceList.Count - 1 do
        begin
          lvNtripSource := ntripSourceList.Items[i];
          lvNtripSource.DValue.ForceByName('host').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.host', '127.0.0.1');
          lvNtripSource.DValue.ForceByName('port').AsInteger :=
            lvIniFile.ReadInteger('vrs_source', lvNtripSource.MountPoint + '.port', 9984);
          lvNtripSource.DValue.ForceByName('auth_user').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.auth.user', '');
          lvNtripSource.DValue.ForceByName('auth_pass').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.auth.pass', '');
          lvNtripSource.DValue.ForceByName('mountpoint').AsString :=
            lvIniFile.ReadString('vrs_source', lvNtripSource.MountPoint + '.mountpoint', lvNtripSource.MountPoint);

          sfLogger.logMessage('挂载点[%s->%s]请求数据源配置:%s:%d',
            [lvNtripSource.MountPoint,
            lvNtripSource.DValue.ForceByName('mountpoint').AsString,
            lvNtripSource.DValue.ForceByName('host').AsString,
            lvNtripSource.DValue.ForceByName('port').AsInteger]);             
        end;
      end;
    finally
      lvIniFile.Free;
    end;
  finally
    ntripSourceList.UnLock;
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
    dmService.VRSSource.ReleaseRequestNMEA(FRequestMountPoint, FRequestNMEA);
    dmService.RemoveNMEARequest(FRequestMountPoint, FRequestNMEA, Self);
    FRequestNMEA := '';
  end;
end;

procedure TMyClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD);
var
  I, r: Integer;
  lvPtr:PByte;
  lvNMEA:String;
  lvFindSource:Boolean;
  {$IFDEF DEBUG}
  lvRecvStr:AnsiString;
  {$ENDIF}
begin
  RecordWorkerStartTick;
  try
    {$IFDEF DEBUG}
    SetLength(lvRecvStr, len);
    move(buf^, PAnsiChar(lvRecvStr)^, len);
    sfLogger.logMessage('接收到来自(%s:%d)数据:%s', [self.RemoteAddr, Self.RemotePort, lvRecvStr], '', lgvDebug);
    {$ENDIF}

    i := 0;
    lvPtr := PByte(buf);
    while i < len do
    begin
       r := FRequest.InputBuffer(lvPtr^);
       if r = 1 then
       begin
         lvFindSource := FRequest.MountPoint <> '';
         if lvFindSource then
         begin
           ntripSourceList.Lock;
           lvFindSource := ntripSourceList.FindSource(FRequest.MountPoint) <> nil;
           ntripSourceList.UnLock;

           if not lvFindSource then
           begin
             sfLogger.logMessage('(%s:%d)请求的挂载点:%s不存在。', [self.RemoteAddr, Self.RemotePort, FRequest.MountPoint]);
           end;
         end;

         if not lvFindSource then
         begin
           self.PostWSASendRequest(PAnsiChar(__sourceTable), Length(__sourceTable), dtNone);
           self.PostWSACloseRequest;
           Exit;
         end;

         self.PostWSASendRequest(PAnsiChar(ICY_200_OK), length(ICY_200_OK), dtNone);
         sfLogger.logMessage('(%s:%d)接收到请求数据,挂载点:%s', [self.RemoteAddr, Self.RemotePort,FRequest.MountPoint]);
         Inc(lvPtr);
         Inc(i);
       end else if r = 2 then
       begin  // 接收到请求数据
         lvNMEA := Trim(FRequest.Context);
         if lvNMEA <> '' then
         begin   
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
        sfLogger.logMessage('(%s:%d)接收到的客户端请求数据, 解码异常:%d', [self.RemoteAddr, Self.RemotePort,r]);
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
