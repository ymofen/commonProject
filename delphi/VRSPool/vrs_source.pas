unit vrs_source;

interface

uses
  diocp.tcp.client, SysUtils, utils.hashs, diocp.sockets, utils_BufferPool, Classes;

type
  TOnVRSSourceBufferEvent = procedure(pvNMEA:string; buf:Pointer; len:Cardinal) of object;
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
  protected
    procedure OnConnected; override;
  public      
    procedure SetNMEA(pvNMEA:string);
    property RequestMountPoint: String read FRequestMountPoint write
        FRequestMountPoint;

  end;
  
  TVRSSoruce = class(TObject)
  private
    //用于处理逻辑时，分发数据时做引用计数
    FVRSRecvBuffPool:PBufferPool;

    FDiocpTcpClient: TDiocpTcpClient;
    FContextMap: TDHashTableSafe;
    FHost: string;
    FOnRecvVRSBuffer: TOnVRSSourceBufferEvent;
    FPort: Integer;
    procedure OnRecvBuffer(pvContext: TDiocpCustomContext; buf: Pointer; len:
        cardinal; pvErrorCode: Integer);
    procedure ClearVRSContexts;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///  提交一个NMEA请求
    /// </summary>
    procedure PostNMEARequest(pvRequestMountPoint, pvNMEA: string);

    /// <summary>
    ///
    /// </summary>
    procedure ReleaseRequestNMEA(pvNMEA:String);

    /// <summary>
    ///   一个连接引用了这个类
    /// </summary>
    procedure AddRefRequestNMEA(pvNMEA:string);

    procedure Start;
    procedure Stop;

    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;



    property OnRecvVRSBuffer: TOnVRSSourceBufferEvent read FOnRecvVRSBuffer write FOnRecvVRSBuffer;


  end;

implementation

procedure TVRSSoruce.AddRefRequestNMEA(pvNMEA: string);
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvDisconnect:Boolean;
begin
  lvDisconnect := false;
  FContextMap.Lock;

  lvPVRSRecord := FContextMap.ValueMap[pvNMEA];
  Assert(lvPVRSRecord <> nil, 'TVRSSoruce.AddRefRequestNMEA Data Error');
  Inc(lvPVRSRecord.refcounter);  
  FContextMap.unLock;
end;

constructor TVRSSoruce.Create;
begin
  inherited Create;
  FDiocpTcpClient := TDiocpTcpClient.Create(nil);
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
  Assert(len<FVRSRecvBuffPool.FBlockSize, 'OnRecvBuffer len超出长度');
  Move(buf^, lvBuff^, len);
  AddRef(lvBuff);
  try
    if Assigned(FOnRecvVRSBuffer) then
    begin
      FOnRecvVRSBuffer(TVRSClientContext(pvContext).FNMEA, lvBuff, len);
    end;
  finally
    ReleaseRef(lvBuff);
  end;
end;

procedure TVRSSoruce.PostNMEARequest(pvRequestMountPoint, pvNMEA: string);
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvConnect:Boolean;
begin
  lvConnect := false;
  FContextMap.Lock;
  lvPVRSRecord := FContextMap.ValueMap[pvNMEA];
  if lvPVRSRecord = nil then
  begin
    New(lvPVRSRecord);
    lvContext := TVRSClientContext(FDiocpTcpClient.Add);
    lvPVRSRecord.Context := lvContext;
    lvPVRSRecord.refcounter := 0;
    lvContext.FNMEA := pvNMEA;
    lvContext.RequestMountPoint := pvRequestMountPoint;
    lvConnect := true;
    FContextMap.ValueMap[pvNMEA] := lvPVRSRecord;
  end;
  lvContext := lvPVRSRecord.Context;
  FContextMap.UnLock;

  /// 连接已经处于闲置状态
  if lvContext.AutoReConnect = False then
  begin
    lvConnect := True;
  end;
  

  if lvConnect then
  begin
    lvContext.Host := FHost;
    lvContext.Port := FPort;

    lvContext.AutoReConnect := True;
    
    /// 异步连接
    lvContext.ConnectASync;
  end;

  
end;

procedure TVRSSoruce.ReleaseRequestNMEA(pvNMEA: String);
var
  lvContext:TVRSClientContext;
  lvPVRSRecord:PVRSRecord;
  lvDisconnect:Boolean;
begin
  lvDisconnect := false;
  FContextMap.Lock;
  lvPVRSRecord := FContextMap.ValueMap[pvNMEA];
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
  ClearVRSContexts;
  FDiocpTcpClient.Close;
end;

procedure TVRSClientContext.OnConnected;
var
  lvRequest:AnsiString;
begin
  inherited;
  lvRequest := Format('GET /%s HTTP/1.1'#13#10#13#10'%s'#13#10#13#10, [FRequestMountPoint, FNMEA]);
  Self.PostWSASendRequest(PAnsiChar(lvRequest), Length(lvRequest));
end;

procedure TVRSClientContext.SetNMEA(pvNMEA:string);
begin
  FNMEA := pvNMEA;
end;

end.
