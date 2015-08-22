unit diocp.p2p;

interface

uses
  diocp.udp, SysUtils, utils.strings, Windows, utils.hashs;


type
  TSessionInfo = class(TObject)
  private
    FIP: string;
    FLastActivity: Integer;
    FPort: Integer;
    FSessionID: Integer;
  public
    function CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;
    property IP: string read FIP write FIP;
    property LastActivity: Integer read FLastActivity write FLastActivity;
    property Port: Integer read FPort write FPort;
    // 激活时生成的一个ID,或者客户端固定的一个ID
    property SessionID: Integer read FSessionID write FSessionID;

     
  end;
  
  TDiocpP2PManager = class(TObject)
  private
    FDiocpUdp: TDiocpUdp;
    FSessions: TDHashTableSafe;
    FSessionID: Integer;
    FKickTimeOut:Integer;
    procedure OnRecv(pvReqeust:TDiocpUdpRecvRequest);
    procedure Process2CMD(pvReqeust: TDiocpUdpRecvRequest; var lvCMDPtr: PAnsiChar);
  public
    constructor Create;
    destructor Destroy; override;
    property DiocpUdp: TDiocpUdp read FDiocpUdp;
    property KickTimeOut: Integer read FKickTimeOut write FKickTimeOut;
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


constructor TDiocpP2PManager.Create;
begin
  inherited Create;
  FDiocpUdp := TDiocpUdp.Create(nil);
  FDiocpUdp.OnRecv := OnRecv;
  FSessions := TDHashTableSafe.Create();
  FSessionID := 1000;    // Session起始值
  FKickTimeOut := 30000; // 30秒
end;

destructor TDiocpP2PManager.Destroy;
begin
  FDiocpUdp.Stop();
  FreeAndNil(FDiocpUdp);
  FSessions.FreeAllDataAsObject;
  FSessions.Free;
  inherited Destroy;
end;

procedure TDiocpP2PManager.OnRecv(pvReqeust:TDiocpUdpRecvRequest);
var
  lvCMD, lvTempStr:AnsiString;
  lvCMDPtr:PAnsiChar;
  lvSessionID:Integer;
  lvSession:TSessionInfo;
begin
   // 0                      : 请求激活，返回0, id
   // 1,id                   : 心跳包
   // 2,request_id, dest_id  : 请求打洞, 返回 2, id, ip, port(对方在线), 2, -1 (对方不在线)
   // 3,id                   : 主动断开
   SetLength(lvCMD, pvReqeust.RecvBufferLen);
   Move(pvReqeust.RecvBuffer^, PAnsiChar(lvCMD)^, pvReqeust.RecvBufferLen);

   lvCMDPtr := PAnsiChar(lvCMD);
   SkipChars(lvCMDPtr, [' ']);
   if lvCMDPtr^ = '0' then
   begin
     lvSessionID := InterlockedIncrement(FSessionID);
     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession = nil then
     begin
       lvSession := TSessionInfo.Create;
       lvSession.SessionID := lvSessionID;
       FSessions.Values[lvSessionID] := lvSession;
     end;
     lvSession.FIP   := pvReqeust.RemoteAddr;
     lvSession.FPort := pvReqeust.RemotePort;
     lvSession.FLastActivity := GetTickCount;
     FSessions.unLock;

     lvCMD := '0, ' + IntToStr(lvSessionID);
     pvReqeust.SendResponse(PAnsiChar(lvCMD), Length(lvCMD));
     sfLogger.logMessage('[%s:%d]请求激活, ID:%d', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
   end else if lvCMDPtr^ = '1' then
   begin     //1,id                   : 心跳包
     SkipUntil(lvCMDPtr, [' ', ',']);

     // 跳过命令符之后的分隔符
     SkipChars(lvCMDPtr, [' ', ',']);
     lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
     if Length(lvTempStr) = 0 then lvTempStr := lvCMDPtr;  //最后没有',' 去剩下所有的          
     lvSessionID := StrToIntDef(lvTempStr, 0);
     if lvSessionID = 0 then Exit;  // 请求ID无效


     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession <> nil then
     begin
       if lvSession.FIP <> pvReqeust.RemoteAddr then
       begin
         sfLogger.logMessage('[%s:%d]心跳更换ID(%d)原有地址:[%s,%d]', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID, lvSession.IP, lvSession.Port]);
       end;
     end else
     begin
       // 直接激活
       lvSession := TSessionInfo.Create;
       lvSession.SessionID := lvSessionID;
       FSessions.Values[lvSessionID] := lvSession;
       sfLogger.logMessage('[%s:%d]心跳激活, ID:%d', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
     end;
     lvSession.FLastActivity := GetTickCount;
     lvSession.FIP   := pvReqeust.RemoteAddr;
     lvSession.FPort := pvReqeust.RemotePort;
     FSessions.unLock;
   end else if lvCMDPtr^ = '2' then
   begin  // 2,request_id, dest_id  : 请求打洞, 返回 2, id, ip, port(对方在线), 2, -1 (对方不在线)
     Process2CMD(pvReqeust, lvCMDPtr);
   end else if lvCMDPtr^ = '3' then
   begin         // 3,id,                   : 主动断开
     // 跳过命令符
     SkipUntil(lvCMDPtr, [' ', ',']);

     // 跳过命令符之后的分隔符
     SkipChars(lvCMDPtr, [' ', ',']);
     lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
     if Length(lvTempStr) = 0 then lvTempStr := lvCMDPtr;  //最后没有',' 去剩下所有的          
     lvSessionID := StrToIntDef(lvTempStr, 0);
     if lvSessionID = 0 then Exit;  // 请求ID无效
     
     FSessions.Lock;
     lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
     if lvSession <> nil then
     begin
       if lvSession.FIP <> pvReqeust.RemoteAddr then
       begin
         sfLogger.logMessage('[%s:%d]非法请求其他连接[%d]断线:[%s,%d]', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID, lvSession.IP, lvSession.Port]);
       end else
       begin
         sfLogger.logMessage('[%s:%d-%d]请求断线', [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvSessionID]);
         
         // 释放Session, 可以改成对象池
         lvSession.Free;

         // Session列表中移除
         FSessions.DeleteFirst(lvSessionID);
       end;
     end;
     FSessions.unLock;
   end;

end;

procedure TDiocpP2PManager.Process2CMD(pvReqeust: TDiocpUdpRecvRequest; var
    lvCMDPtr: PAnsiChar);
var
  lvCMD, lvCMD2, lvTempStr, lvDestAddr:AnsiString;
  lvDestPort:Integer;

  lvSessionID, lvRequestID:Integer;
  lvSession:TSessionInfo;
  lvIsActive:Boolean;
begin
   // 跳过命令符
   SkipUntil(lvCMDPtr, [' ', ',']);

   // 跳过命令符之后的分隔符
   SkipChars(lvCMDPtr, [' ', ',']);
   lvTempStr := LeftUntil(lvCMDPtr, [',', ' ']);
   lvRequestID := StrToIntDef(lvTempStr, 0);
   if lvRequestID = 0 then Exit;  // 请求ID无效

   SkipChars(lvCMDPtr, [' ', ',']);
   lvTempStr := lvCMDPtr;
   lvSessionID := StrToIntDef(lvTempStr, 0);
   if lvSessionID = 0 then Exit;  // 对方ID无效

   FSessions.Lock;
   lvSession := TSessionInfo(FSessions.Values[lvSessionID]);
   if lvSession = nil then
   begin
      lvCMD := Format('2,%d,-1,', [lvSessionID]);
      lvIsActive := false;
   end else
   begin
     lvIsActive := lvSession.CheckActivity(GetTickCount, FKickTimeOut);
     if lvIsActive then
     begin
       lvDestAddr := lvSession.IP;
       lvDestPort := lvSession.Port;

       // 通知回去可以进行打洞(对方的ID,IP,Port)
       lvCMD := Format('2,%d,%s,%d', [lvSessionID, lvSession.FIP, lvSession.FPort]);

       // 通知对方进行打洞(请求方的ID, IP, Port)
       lvCMD2 := Format('2,%d,%s,%d', [lvRequestID, pvReqeust.RemoteAddr, pvReqeust.RemotePort]);

       // 通知对方进行打洞
       self.FDiocpUdp.WSASendTo(lvDestAddr, lvDestPort, PAnsiChar(lvCMD2), Length(lvCMD2));

       sfLogger.logMessage('[%s,%d:%d]请求打洞->[%s,%d:%d]',
         [pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvRequestID,
         lvSession.FIP, lvSession.FPort, lvSessionID]);
     end else
     begin       // 对方已经失去联系
       lvCMD := Format('2,%d,-1,', [lvSessionID]);

       sfLogger.logMessage('[%s:%d:%d]请求打洞->[%s,%d:%d]', [
         pvReqeust.RemoteAddr, pvReqeust.RemotePort, lvRequestID,
         lvSession.FIP, lvSession.FPort, lvSessionID]);

       // 释放Session, 可以改成对象池
       lvSession.Free;

       // Session列表中移除
       FSessions.DeleteFirst(lvSessionID);
     end;
   end;
   FSessions.unLock;

   // 回复 (打洞信息)
   pvReqeust.SendResponse(PAnsiChar(lvCMD), Length(lvCMD));
end;

function TSessionInfo.CheckActivity(pvTickcount: Cardinal; pvTimeOut: Integer): Boolean;
begin
  Result :=tick_diff(FLastActivity, GetTickCount) < pvTimeOut;
end;

end.
