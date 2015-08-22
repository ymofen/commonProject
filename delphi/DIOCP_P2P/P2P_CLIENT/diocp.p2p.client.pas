unit diocp.p2p.client;

interface

uses
  diocp.udp, SysUtils, utils.strings, Windows, utils.hashs, Classes,
  utils.queues, SyncObjs;


type
  TDiocpP2PClient = class;

  /// <summary>
  ///  激活状态
  /// </summary>
  TActiveState = (asNone, asActiving, asActive, asFault);

  /// <summary>
  ///  工作线程
  /// </summary>
  TWorkThread = class(TThread)
  private
    FP2PClient: TDiocpP2PClient;
  public
    constructor Create(AP2PClient: TDiocpP2PClient);
    procedure Execute; override;
  end;

  TSessionInfo = class(TObject)
  private
    FP2PState: Integer;
    FIP: string;
    FLastActivity: Integer;
    FPort: Integer;
    FSessionID: Integer;
    FHoleTime : Integer;
    FHoleLastActivity: Integer;
  public
    function CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;

    /// <summary>
    ///  检测是否需要再次进行打洞
    /// </summary>
    function CheckHoleActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;

    /// <summary>
    ///  重置状态
    /// </summary>
    procedure Reset();

    /// <summary>
    ///   P2P状态, 0:初始状态， 1：已经打通， 2：打洞失败, 3: 对方不在线
    /// </summary>
    property P2PState: Integer read FP2PState write FP2PState;

    /// <summary>
    ///  对方IP
    /// </summary>
    property IP: string read FIP write FIP;

    /// <summary>
    ///   对方Port
    /// </summary>
    property Port: Integer read FPort write FPort; 
    

    property LastActivity: Integer read FLastActivity write FLastActivity;

    // 激活时生成的一个ID,或者客户端固定的一个ID
    property SessionID: Integer read FSessionID write FSessionID;
    
  end;
  
  TDiocpP2PClient = class(TObject)
  private
    FActiveState: TActiveState;
    FLastDoActive:Cardinal;
    FDoActiveTime:Integer;
    FLastActivity: Cardinal;
    
    FDiocpUdp: TDiocpUdp;

    FLock: TCriticalSection;

    /// <summary>
    ///  打洞任务队列
    /// </summary>
    FMakeHoleList: TList;

    FWorkThread: TWorkThread;    

    FSessions: TDHashTableSafe;
    FSessionID: Integer;
    FKickTimeOut:Integer;


    FP2PServerAddr: String;
    FP2PServerPort: Integer;

    procedure OnRecv(pvReqeust:TDiocpUdpRecvRequest);

    /// <summary>
    ///  检测是否为P2P服务的请求
    /// </summary>
    function CheckServerRequest(pvReqeust:TDiocpUdpRecvRequest): Boolean;

    /// <summary>
    ///   进行打洞
    /// </summary>
    procedure MakeAHole(pvID:Integer; pvRemoteAddr:String; pvRemotePort:Integer);

    /// <summary>
    ///  处理服务端发送过来的请求
    /// </summary>
    procedure ProcessServerRequest(pvReqeust:TDiocpUdpRecvRequest);

    /// <summary>
    ///   接收到打洞信息，成功打洞
    /// </summary>
    procedure ProcessHoleRequest(pvReqeust:TDiocpUdpRecvRequest);

    /// <summary>
    ///  处理一次列表请求
    /// </summary>
    procedure DoMakeHole();
  public
    constructor Create;

    destructor Destroy; override;  

    property DiocpUdp: TDiocpUdp read FDiocpUdp;

    /// <summary>
    ///   激活
    /// </summary>
    procedure DoActive();

    procedure DoHeart();

    /// <summary>
    ///   请求建立连接
    /// </summary>
    procedure RequestConnect(pvID:Integer);   

    procedure Start();

    procedure Stop();

    /// <summary>
    ///  查询P2P连接状态
    ///  P2P状态, 0:初始状态， 1：已经打通， 2：打洞失败, 3: 对方不在线
    /// </summary>
    function QueryP2PState(pvID:Integer): Integer;

    /// <summary>
    ///  激活状态
    /// </summary>
    property ActiveState: TActiveState read FActiveState;
    
    property KickTimeOut: Integer read FKickTimeOut write FKickTimeOut;

    property P2PServerAddr: String read FP2PServerAddr write FP2PServerAddr;
    
    property P2PServerPort: Integer read FP2PServerPort write FP2PServerPort;

    property SessionID: Integer read FSessionID;

    

  end;

implementation

uses
  utils.safeLogger;

/// <summary>
///   计算两个TickCount时间差，避免超出49天后，溢出
///      感谢 [佛山]沧海一笑  7041779 提供
///      copy自 qsl代码 
/// </summary>
function tick_diff(tick_start, tick_end: Cardinal): Cardinal;
begin
  if tick_end >= tick_start then
    result := tick_end - tick_start
  else
    result := High(Cardinal) - tick_start + tick_end;
end;


constructor TDiocpP2PClient.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FMakeHoleList := TList.Create;
  
  FDiocpUdp := TDiocpUdp.Create(nil);
  FDiocpUdp.OnRecv := OnRecv;
  FSessions := TDHashTableSafe.Create();

  FKickTimeOut := 30000; // 30秒

  FWorkThread := TWorkThread.Create(Self);
  FWorkThread.Resume();
end;

destructor TDiocpP2PClient.Destroy;
begin
  FWorkThread.Terminate();
  FWorkThread.WaitFor();
  FDiocpUdp.Stop();
  FreeAndNil(FDiocpUdp);
  FSessions.FreeAllDataAsObject;
  FSessions.Free;
  FWorkThread.Free;
  FLock.Free;
  FMakeHoleList.Free;
  inherited Destroy;
end;

procedure TDiocpP2PClient.DoActive;
var
  lvCMD:AnsiString;
begin
  if FDoActiveTime > 5 then
  begin
    FActiveState := asFault;
    Exit;
  end;

  if (tick_diff(FLastDoActive, GetTickCount) > 5000) then
  begin
    if FActiveState = asNone then FActiveState := asActiving;

    // 请求激活
    lvCMD:= '0';
    FDiocpUdp.WSASendTo(FP2PServerAddr, FP2PServerPort, PAnsiChar(lvCMD), Length(lvCMD));
    Inc(FDoActiveTime);
    FLastDoActive := GetTickCount;
  end;
end;

procedure TDiocpP2PClient.DoHeart;
var
  lvCMD:AnsiString;
begin
  if (FActiveState = asActive) and (FSessionID > 0) then
  begin
    if (tick_diff(FLastActivity, GetTickCount) > 5000) then
    begin
      if FActiveState = asNone then FActiveState := asActiving;

      // 心跳包
      lvCMD:= Format('1,%d', [FSessionID]);
      
      FDiocpUdp.WSASendTo(FP2PServerAddr, FP2PServerPort, PAnsiChar(lvCMD), Length(lvCMD));
      
      FLastActivity := GetTickCount;

      sfLogger.logMessage('发送心跳数据包[%s]!', [lvCMD]);
    end;
  end;
end;

procedure TDiocpP2PClient.DoMakeHole;
var
  I: Integer;
  lvSession:TSessionInfo;
  lvCMD:AnsiString;
begin
  FLock.Enter;
  for I := FMakeHoleList.Count - 1 downto 0 do
  begin
    lvSession := TSessionInfo(FMakeHoleList[i]);
    if lvSession.FP2PState = 1 then
    begin               // 打洞成功
      FMakeHoleList.Remove(lvSession);
    end else  if lvSession.FP2PState = 3 then  // 对方不在线
    begin
      FMakeHoleList.Remove(lvSession);
    end else if lvSession.FHoleTime > 10 then
    begin
      lvSession.FP2PState := 2;  // 打洞失败
      FMakeHoleList.Remove(lvSession);
    end else if lvSession.CheckHoleActivity(GetTickCount, 5000) then
    begin
      if lvSession.FIP = '' then
      begin    // 还没有请求到对方IP
         lvCMD := Format('2,%d, %d', [self.SessionID, lvSession.SessionID]);
         FDiocpUdp.WSASendTo(FP2PServerAddr, FP2PServerPort, PAnsiChar(lvCMD), Length(lvCMD));
      end else
      begin
        // 进行打洞
        MakeAHole(Self.FSessionID, lvSession.IP, lvSession.Port);
      end;
      lvSession.FHoleLastActivity := GetTickCount;
      Inc(lvSession.FHoleTime);
    end;
  end;
  FLock.Leave;
end;

procedure TDiocpP2PClient.MakeAHole(pvID: Integer; pvRemoteAddr: String;
  pvRemotePort: Integer);
var
  lvCMD:AnsiString;
begin
  // 发送打洞成功信息
  lvCMD:=Format('8,%d', [pvID]);
  FDiocpUdp.WSASendTo(pvRemoteAddr, pvRemotePort, PAnsiChar(lvCMD), Length(lvCMD));
end;

function TDiocpP2PClient.CheckServerRequest(pvReqeust:TDiocpUdpRecvRequest): Boolean;
begin
  Result := (pvReqeust.RemoteAddr = P2PServerAddr) and (pvReqeust.RemotePort = FP2PServerPort);   
end;

procedure TDiocpP2PClient.OnRecv(pvReqeust:TDiocpUdpRecvRequest);
begin
  // 打洞信息: 2, id, ip, port(对方在线), 2, -1 (对方不在线)
  if CheckServerRequest(pvReqeust) then
  begin
    ProcessServerRequest(pvReqeust);
  end else
  begin
    if pvReqeust.RecvBuffer^ = '8' then
    begin  // 接收到打洞成功信息
      ProcessHoleRequest(pvReqeust);    
    end;
  end; 
end;

procedure TDiocpP2PClient.ProcessHoleRequest(pvReqeust: TDiocpUdpRecvRequest);
var
  lvCMD :AnsiString;
  lvCMDPtr:PAnsiChar;
  lvSessionID:Integer;
  lvSession:TSessionInfo;
begin

  //8,id
  SetLength(lvCMD, pvReqeust.RecvBufferLen);
  Move(pvReqeust.RecvBuffer^, PAnsiChar(lvCMD)^, pvReqeust.RecvBufferLen);

  sfLogger.logMessage('[%s,%d]接收到打洞信息:%s, 进行处理', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvCMD]);
  
  lvCMDPtr := PAnsiChar(lvCMD);

  // 跳过命令符
  SkipUntil(lvCMDPtr, [' ', ',']);

  // 跳过命令符之后的分隔符
  SkipChars(lvCMDPtr, [' ', ',']);

  //
  lvSessionID := StrToIntDef(lvCMDPtr, 0);
  if lvSessionID = 0 then Exit;
  

  FSessions.Lock;
  lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
  if lvSession = nil then
  begin
    lvSession := TSessionInfo.Create;
    lvSession.SessionID := lvSessionID;
    FSessions.Values[lvSessionID] := lvSession;
  end;

  if (lvSession.P2PState <> 1) or (lvSession.IP <> pvReqeust.RemoteAddr) or (lvSession.Port <> pvReqeust.RemotePort)  then
  begin
    lvSession.P2PState := 1;    // 打洞成功
    lvSession.IP := pvReqeust.RemoteAddr;
    lvSession.Port := pvReqeust.RemotePort;

    // 回复打洞信息
    MakeAHole(lvSessionID, lvSession.IP, lvSession.Port);

    
    sfLogger.logMessage('[%s,%d:%d]接收到打洞信息, 并进行了回复', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
  end else
  begin  // 已经成功不进行回复, 否则造成了 不停的循环
    lvSession.P2PState := 1;    // 打洞成功
    sfLogger.logMessage('[%s,%d:%d,objAddr:%d]接收到打洞信息, 不进行回复, 已经成功', [pvReqeust.RemoteAddr,
    pvReqeust.RemotePort, lvSessionID, Integer(lvSession)]);
  end;
  FSessions.unLock;


end;

procedure TDiocpP2PClient.ProcessServerRequest(pvReqeust:TDiocpUdpRecvRequest);
var
  lvCMD, lvCMD2, lvTempStr:AnsiString;
  lvCMDPtr:PAnsiChar;
  lvSessionID, lvRequestID:Integer;
  lvIsActive:Boolean;

  lvIP: AnsiString;
  lvPort:Integer;

  lvSession:TSessionInfo;
begin
  SetLength(lvCMD, pvReqeust.RecvBufferLen);
  Move(pvReqeust.RecvBuffer^, PAnsiChar(lvCMD)^, pvReqeust.RecvBufferLen);


  lvCMDPtr := PAnsiChar(lvCMD);
  SkipChars(lvCMDPtr, [' ']);

  // 2,id,ip,port  //打洞信息
  if lvCMDPtr^ = '2' then
  begin      // 收到服务端的打洞信息
    sfLogger.logMessage('收到服务端请求打洞信息:' + lvCMD);
    // 跳过命令符
    SkipUntil(lvCMDPtr, [' ', ',']);

    // 跳过命令符之后的分隔符
    SkipChars(lvCMDPtr, [' ', ',']);
    lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
    lvSessionID := StrToIntDef(lvTempStr, 0);
    if lvSessionID = 0 then Exit;  // 对方ID无效

    // 跳过命令符之后的分隔符
    SkipChars(lvCMDPtr, [' ', ',']);
    lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
    lvIP := lvTempStr;
    if lvIP = '' then
    begin
      sfLogger.logMessage('收到的打洞信息缺少IP, ' + lvCMD);
      Exit;
    end else if lvIP = '-1' then
    begin
      FSessions.Lock;
      lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
      if lvSession <> nil then
      begin          // 对方不在线
        lvSession.FP2PState := 3;
      end;
      FSessions.unLock;
      sfLogger.logMessage('收到打洞回复对方[%d]不在线', [lvSessionID]);
      Exit;
    end;


    // 跳过命令符之后的分隔符
    SkipChars(lvCMDPtr, [' ', ',']);
    lvPort := StrToIntDef(lvCMDPtr, 0);
    if lvPort = 0 then
    begin
      sfLogger.logMessage('收到的打洞信息缺少端口号, ' + lvCMD);
      Exit;
    end;

    FSessions.Lock;
    lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
    if lvSession = nil then
    begin
      lvSession := TSessionInfo.Create;
      lvSession.SessionID := lvSessionID;
      FSessions.Values[lvSessionID] := lvSession;
    end;
    lvSession.IP := lvIP;
    lvSession.Port := lvPort;

    lvSession.FHoleTime := 0;
    lvSession.FHoleLastActivity := GetTickCount;

    // 发送打洞信息
    MakeAHole(lvSessionID, lvSession.IP, lvSession.Port);
    FSessions.unLock;
    
  end else if lvCMDPtr^ = '0' then
  begin           // 激活成功
    FActiveState := asActive;

    // 跳过命令符
    SkipUntil(lvCMDPtr, [' ', ',']);

    // 跳过命令符之后的分隔符
    SkipChars(lvCMDPtr, [' ', ',']);

    //
    FSessionID := StrToIntDef(lvCMDPtr, 0);

    FLastActivity := GetTickCount;
  end;
end;

function TDiocpP2PClient.QueryP2PState(pvID:Integer): Integer;
var
  lvSession:TSessionInfo;
begin
  FSessions.Lock;
  lvSession := TSessionInfo(FSessions.Values[pvID]);
  if lvSession = nil then
  begin
    Result := -1;
  end else
  begin
    Result := lvSession.P2PState;
  end;                           
  FSessions.unLock;
end;

procedure TDiocpP2PClient.RequestConnect(pvID: Integer);
var
  lvSession:TSessionInfo;
begin
  FSessions.Lock;
  // 创建Session
  lvSession := TSessionInfo(FSessions.Values[pvID]);
  if lvSession = nil then
  begin
    lvSession := TSessionInfo.Create;
    lvSession.FSessionID := pvID;
    FSessions.Values[pvID] := lvSession;
  end;
  lvSession.Reset;
  FSessions.unLock;

  FLock.Enter;
  if FMakeHoleList.IndexOf(lvSession) = -1 then
  begin
    FMakeHoleList.Add(lvSession);
  end;
  FLock.Leave;
end;

procedure TDiocpP2PClient.Start;
begin
  FActiveState := asNone;  
end;

procedure TDiocpP2PClient.Stop;
begin
  
end;

constructor TWorkThread.Create(AP2PClient: TDiocpP2PClient);
begin
  inherited Create(False);
  FP2PClient := AP2PClient;
end;

procedure TWorkThread.Execute;
begin
  while not self.Terminated do
  begin
    if FP2PClient.FDiocpUdp.Active then
    begin
      if FP2PClient.ActiveState = asActive then
      begin
        FP2PClient.DoHeart();

        // 处理打洞请求
        FP2PClient.DoMakeHole();
      end else
      begin
        FP2PClient.DoActive();
      end;
    end;
    Sleep(100);
  end;
end;

function TSessionInfo.CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer):
    Boolean;
begin
  Result :=tick_diff(FLastActivity, GetTickCount) < pvTimeOut;
end;

function TSessionInfo.CheckHoleActivity(pvTickcount: Cardinal; pvTimeOut:
    Integer): Boolean;
begin
  Result :=tick_diff(FHoleLastActivity, GetTickCount) > pvTimeOut;
end;

procedure TSessionInfo.Reset;
begin
  FIP := '';
  FPort := 0;
  FP2PState := 0;
  FHoleLastActivity := 0;
  FHoleTime := 0;  
end;

end.
