(*
  *	 Unit owner: D10.Mofen, delphi iocp framework author
  *         homePage: http://www.Diocp.org
  *	       blog: http://www.cnblogs.com/dksoft

  *   2015-02-22 08:29:43
  *     DIOCP-V5 发布

  *    Http协议处理单元
  *    其中大部分思路来自于delphi iocp framework中的iocp.HttpServer
  *

// 验证
GET /1 HTTP/1.1
Host: 127.0.0.1
Ntrip-Version: Ntrip/2.0
User-Agent: NTRIP NtripClientPOSIX/1.49
Connection: close
Authorization: Basic dXNlcjpwYXNzd29yZA==


*)
unit diocp.ex.ntrip;

interface

/// 三个编译开关，只能开启一个
{$DEFINE INNER_IOCP}     // iocp线程触发事件
{.$DEFINE  QDAC_QWorker} // 用qworker进行调度触发事件
{.$DEFINE DIOCP_Task}    // 用diocp.task进行调度触发事件


uses
  Classes, StrUtils, SysUtils, utils.buffer, utils.strings

  {$IFDEF QDAC_QWorker}, qworker{$ENDIF}
  {$IFDEF DIOCP_Task}, diocp.task{$ENDIF}
  , diocp.tcp.server, utils.queues, utils.hashs;



const
  HTTPLineBreak = #13#10;

type
  TDiocpNtripState = (hsCompleted, hsRecevingNEMA, hsRequest { 接收请求 }, hsRecvingSource { 接收NtripSource数据 } );
  TDiocpNtripContextMode = (ncmNtripNone, ncmNtripSource, ncmNtripClient);
  TDiocpNtripResponse = class;
  TDiocpNtripClientContext = class;
  TDiocpNtripServer = class;
  TDiocpNtripRequest = class;

  TOnRequestAcceptEvent = procedure(pvRequest:TDiocpNtripRequest; var vIsNMEA:Boolean) of object;

  TDiocpNtripRequest = class(TObject)
  private
    /// <summary>
    ///   便于在Close时归还回对象池
    /// </summary>
    FDiocpNtripServer:TDiocpNtripServer;

    FDiocpContext: TDiocpNtripClientContext;

    /// 头信息
    FHttpVersion: Word; // 10, 11

    FRequestVersionStr: String;

    FRequestMethod: String;

    FMountPoint: String;

    /// <summary>
    ///  原始请求中的URL参数数据(没有经过URLDecode，因为在DecodeRequestHeader中要拼接RequestURL时临时进行了URLDecode)
    ///  没有经过URLDecode是考虑到参数值中本身存在&字符，导致DecodeURLParam出现不解码异常
    /// </summary>
    FRequestURLParamData: string;


    FRequestParamsList: TStringList; // TODO:存放http参数的StringList

    FContextType: string;
    FContextLength: Int64;
    FKeepAlive: Boolean;
    FRequestAccept: String;
    FRequestAcceptLanguage: string;
    FRequestAcceptEncoding: string;
    FRequestUserAgent: string;
    FRequestAuth: string;
    FRequestCookies: string;
    FRequestHostName: string;
    FRequestHostPort: string;

    FXForwardedFor: string;

    FRawHeaderData: TMemoryStream;

    /// <summary>
    ///   原始的POST数据
    /// </summary>
    FRawPostData: TMemoryStream;

    FPostDataLen: Integer;

    FRequestHeader: TStringList;

    FResponse: TDiocpNtripResponse;
    FSourceRequestPass: String;

    /// <summary>
    ///   不再使用了，归还回对象池
    /// </summary>
    procedure Close;
    /// <summary>
    /// 是否有效的Http 请求方法
    /// </summary>
    /// <returns>
    /// 0: 数据不足够进行解码
    /// 1: 有效的数据头
    /// 2: 无效的请求数据头
    /// </returns>
    function DecodeRequestMethod: Integer;

    /// <summary>
    /// 解码Http请求参数信息
    /// </summary>
    /// <returns>
    /// 1: 有效的Http参数数据
    /// </returns>
    function DecodeRequestHeader: Integer;

    /// <summary>
    /// 接收到的Buffer,写入数据
    /// </summary>
    procedure WriteRawBuffer(const buffer: Pointer; len: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;


    /// <summary>
    ///   将Post的原始数据解码，放到参数列表中
    ///   在OnDiocpNtripRequest中调用
    /// </summary>
    procedure DecodePostDataParam(
      {$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});

    function ExtractNMEAString():String;

    /// <summary>
    ///   清理
    /// </summary>
    procedure Clear;

    property ContextLength: Int64 read FContextLength;


    /// <summary>
    ///   与客户端建立的连接
    /// </summary>
    property Connection: TDiocpNtripClientContext read FDiocpContext;

    property HttpVersion: Word read FHttpVersion;
    /// <summary>
    ///   原始的Post过来的数据
    /// </summary>
    property RawPostData: TMemoryStream read FRawPostData;
    property RequestAccept: String read FRequestAccept;
    property RequestAcceptEncoding: string read FRequestAcceptEncoding;
    property RequestAcceptLanguage: string read FRequestAcceptLanguage;
    property RequestCookies: string read FRequestCookies;

    /// <summary>
    ///   请求的头信息
    /// </summary>
    property RequestHeader: TStringList read FRequestHeader;

    /// <summary>
    ///   挂节点
    /// </summary>
    property MountPoint: String read FMountPoint;

    /// <summary>
    ///   Source方法请求中的Password
    /// </summary>
    property SourceRequestPass: String read FSourceRequestPass write  FSourceRequestPass;

    /// <summary>
    ///  从头信息中读取的请求服务器请求方式
    /// </summary>
    property RequestMethod: string read FRequestMethod;

    /// <summary>
    ///   从头信息中读取的请求服务器IP地址
    /// </summary>
    property RequestHostName: string read FRequestHostName;

    /// <summary>
    ///   从头信息中读取的请求服务器端口
    /// </summary>
    property RequestHostPort: string read FRequestHostPort;

    /// <summary>
    /// Http响应对象，回写数据
    /// </summary>
    property Response: TDiocpNtripResponse read FResponse;

    /// <summary>
    ///   从Url和Post数据中得到的参数信息: key = value
    /// </summary>
    property RequestParamsList: TStringList read FRequestParamsList;


    /// <summary>
    ///   获取头信息中的用户名和密码信息
    /// </summary>
    /// <returns>
    ///   获取成功返回true
    /// </returns>
    /// <param name="vUser"> (string) </param>
    /// <param name="vPass"> (string) </param>
    function ExtractBasicAuthenticationInfo(var vUser, vPass:string): Boolean;


    /// <summary>
    ///  关闭连接
    /// </summary>
    procedure CloseContext;

    /// <summary>
    /// 得到http请求参数
    /// </summary>
    /// <params>
    /// <param name="ParamsKey">http请求参数的key</param>
    /// </params>
    /// <returns>
    /// 1: http请求参数的值
    /// </returns>
    function GetRequestParam(ParamsKey: string): string;

    /// <summary>
    /// 解析POST和GET参数
    /// </summary>
    /// <pvParamText>
    /// <param name="pvParamText">要解析的全部参数</param>
    /// </pvParamText>
    procedure ParseParams(pvParamText: string);


  end;

  TDiocpNtripResponse = class(TObject)
  private
    FResponseHeader: string;
    FData: TMemoryStream;
    FDiocpContext : TDiocpNtripClientContext;
  public
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    procedure WriteBuf(pvBuf: Pointer; len: Cardinal);
    procedure WriteString(pvString: string; pvUtf8Convert: Boolean = true);

    /// <summary>
    ///  发送ICY200OK信息
    /// </summary>
    procedure ICY200OK();

    /// <summary>
    ///   NtripSource认证时密码错误的回复，回复后，关闭连接
    /// </summary>
    procedure BadPassword();

    /// <summary>
    ///   发送SourceTableOK信息
    /// </summary>
    procedure SourceTableOK();

    /// <summary>
    ///   发送SourceTableOK和SourceTable数据
    /// </summary>
    procedure SourceTableOKAndData(pvSourceTable:AnsiString);

    /// <summary>
    ///   NtripClient验证失败
    /// </summary>
    procedure Unauthorized();

    /// <summary>
    ///   无效的用户认证信息
    /// </summary>
    /// <param name="pvMountpoint"> 挂节点 </param>
    procedure InvalidPasswordMsg(pvMountpoint: string);


    /// <summary>
    ///   与客户端建立的连接
    /// </summary>
    property Connection: TDiocpNtripClientContext read FDiocpContext;

  end;

  /// <summary>
  /// Http 客户端连接
  /// </summary>
  TDiocpNtripClientContext = class(TIocpClientContext)
  private
    // NtripSource，作为转发使用
    FNtripClients:TList;
    // 做分发数据时临时使用
    FTempNtripClients:TList;

    FContextMode: TDiocpNtripContextMode;
    FNtripState: TDiocpNtripState;
    FCurrentRequest: TDiocpNtripRequest;
    FMountPoint: String;
    FTag: Integer;
    FTagStr: String;
    {$IFDEF QDAC_QWorker}
    procedure OnExecuteJob(pvJob:PQJob);
    {$ENDIF}
    {$IFDEF DIOCP_Task}
    procedure OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
    {$ENDIF}

    // 执行事件
    procedure DoRequest(pvRequest:TDiocpNtripRequest);

    /// <summary>
    ///   进行NtripSource的验证工作
    /// </summary>
    procedure DoNtripSourceAuthentication(pvRequest:TDiocpNtripRequest);
  protected

    /// <summary>
    ///   触发本身的Request过程
    /// </summary>
    procedure OnRequest(pvRequest:TDiocpNtripRequest); virtual;

    procedure OnDisconnected; override;

  public
    constructor Create; override;
    destructor Destroy; override;
  protected
    /// <summary>
    /// 归还到对象池，进行清理工作
    /// </summary>
    procedure DoCleanUp; override;

    /// <summary>
    /// 接收到客户端的Http协议数据, 进行解码成TDiocpNtripRequest，响应Http请求
    /// </summary>
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: Word); override;
  public
    /// <summary>
    ///   添加到NtripSource的分发列表
    /// </summary>
    procedure AddNtripClient(pvContext:TDiocpNtripClientContext);

    /// <summary>
    ///   移除掉NtripSource的分发列表
    ///   在做分发数据时，有执行移除动作(对应的Context不是请求的mountpoint的数据，或者断开)
    /// </summary>
    procedure RemoveNtripClient(pvContext:TDiocpNtripClientContext);

    /// <summary>
    ///   分发GNSSData
    /// </summary>
    procedure DispatchGNSSDATA(buf: Pointer; len: Cardinal);





    property ContextMode: TDiocpNtripContextMode read FContextMode write FContextMode;

    property MountPoint: String read FMountPoint write FMountPoint;



    property Tag: Integer read FTag write FTag;

    property TagStr: String read FTagStr write FTagStr;


  end;

{$IFDEF UNICODE}
  /// <summary>
  /// Request事件类型
  /// </summary>
  TOnDiocpNtripRequestEvent = reference to procedure(pvRequest: TDiocpNtripRequest);

  /// <summary>
  /// 接收到NtripSource数据
  /// </summary>
  TDiocpRecvBufferEvent = reference to procedure(pvContext:TDiocpNtripClientContext; buf: Pointer; len: Cardinal);
{$ELSE}
  /// <summary>
  /// Request事件类型
  /// </summary>
  TOnDiocpNtripRequestEvent = procedure(pvRequest: TDiocpNtripRequest) of object;

  /// <summary>
  /// 接收到NtripSource数据
  /// </summary>
  TDiocpRecvBufferEvent = procedure(pvContext:TDiocpNtripClientContext;buf: Pointer; len: Cardinal) of object;
{$ENDIF}

  /// <summary>
  /// Http 解析服务
  /// </summary>
  TDiocpNtripServer = class(TDiocpTcpServer)
  private
    FNtripSourcePassword: String;
    FRequestPool: TBaseQueue;

    /// <summary>
    ///  存放Source列表
    /// </summary>
    FNtripSources: TDHashTableSafe;

    FOnDiocpNtripRequest: TOnDiocpNtripRequestEvent;
    FOnDiocpNtripRequestPostDone: TOnDiocpNtripRequestEvent;
    FOnDiocpRecvNtripSourceBuffer: TDiocpRecvBufferEvent;
    FOnRequestAcceptEvent: TOnRequestAcceptEvent;

    /// <summary>
    /// 响应Http请求， 执行响应事件
    /// </summary>
    procedure DoRequest(pvRequest: TDiocpNtripRequest);

    /// <summary>
    ///   响应Post数据事件
    /// </summary>
    procedure DoRequestPostDataDone(pvRequest: TDiocpNtripRequest);

    /// <summary>
    ///   从池中获取一个对象
    /// </summary>
    function GetRequest: TDiocpNtripRequest;

    /// <summary>
    ///   还回一个对象
    /// </summary>
    procedure GiveBackRequest(pvRequest:TDiocpNtripRequest);

  public
    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;



    /// <summary>
    ///   根据mountPoint查找NtripSource
    /// </summary>
    function FindNtripSource(pvMountPoint:string):TDiocpNtripClientContext;

    /// <summary>
    ///   NtripSourcePassword, 用于NtripSource接入时做认证
    /// </summary>
    property NtripSourcePassword: String read FNtripSourcePassword write FNtripSourcePassword;


    /// <summary>
    ///  请求进入
    /// </summary>
    property OnRequestAcceptEvent: TOnRequestAcceptEvent read FOnRequestAcceptEvent write FOnRequestAcceptEvent;

    /// <summary>
    ///   接收到NtripSource数据
    /// </summary>
    property OnDiocpRecvNtripSourceBuffer: TDiocpRecvBufferEvent read
        FOnDiocpRecvNtripSourceBuffer write FOnDiocpRecvNtripSourceBuffer;

    /// <summary>
    ///   当Http请求的Post数据完成后触发的事件
    ///   用来处理解码一些数据,比如Post的参数
    /// </summary>
    property OnDiocpNtripRequestPostDone: TOnDiocpNtripRequestEvent read
        FOnDiocpNtripRequestPostDone write FOnDiocpNtripRequestPostDone;

    /// <summary>
    /// 响应Http请求事件
    /// </summary>
    property OnDiocpNtripRequest: TOnDiocpNtripRequestEvent read FOnDiocpNtripRequest
        write FOnDiocpNtripRequest;









  end;



implementation

uses
  utils.base64;

function FixHeader(const Header: string): string;
begin
  Result := Header;
  if (RightStr(Header, 4) <> #13#10#13#10) then
  begin
    if (RightStr(Header, 2) = #13#10) then
      Result := Result + #13#10
    else
      Result := Result + #13#10#13#10;
  end;
end;

function MakeHeader(const Status, pvRequestVersionStr: string; pvKeepAlive:
    Boolean; const ContType, Header: string; pvContextLength: Integer): string;
var
  lvVersionStr:string;
begin
  Result := '';

  lvVersionStr := pvRequestVersionStr;
  if lvVersionStr = '' then lvVersionStr := 'HTTP/1.0';

  if (Status = '') then
    Result := Result + lvVersionStr + ' 200 OK' + #13#10
  else
    Result := Result + lvVersionStr + ' ' + Status + #13#10;

  if (ContType = '') then
    Result := Result + 'Content-Type: gnss/data' + #13#10    // 默认GNNS数据
  else
    Result := Result + 'Content-Type: ' + ContType + #13#10;

  if (pvContextLength > 0) then
    Result := Result + 'Content-Length: ' + IntToStr(pvContextLength) + #13#10;
  // Result := Result + 'Cache-Control: no-cache'#13#10;

  if pvKeepAlive then
    Result := Result + 'Connection: keep-alive'#13#10
  else
    Result := Result + 'Connection: close'#13#10;

  Result := Result + 'Server: DIOCP-V5/1.0'#13#10;

end;

procedure TDiocpNtripRequest.Clear;
begin
  FRawHeaderData.Clear;
  FRawPostData.Clear;
  FMountPoint := '';
  FSourceRequestPass := '';
  FRequestVersionStr := '';
  FRequestMethod := '';
  FRequestCookies := '';
  FRequestParamsList.Clear;
  FContextLength := 0;
  FPostDataLen := 0;
  FResponse.Clear;  
end;

procedure TDiocpNtripRequest.Close;
begin
  if FDiocpNtripServer = nil then exit;
  FDiocpNtripServer.GiveBackRequest(Self);
end;

procedure TDiocpNtripRequest.CloseContext;
begin
  FDiocpContext.PostWSACloseRequest();
end;

function TDiocpNtripRequest.GetRequestParam(ParamsKey: string): string;
var
  lvTemp: string; // 返回的参数值
  lvParamsCount: Integer; // 参数数量
  I: Integer;
begin
  Result := '';

  lvTemp := ''; // 返回的参数值默认值为空

  // 得到提交过来的参数的数量
  lvParamsCount := self.FRequestParamsList.Count;

  // 判断是否有提交过来的参数数据
  if lvParamsCount = 0 then exit;

  // 循环比较每一组参数的key，是否和当前输入一样
  for I := 0 to lvParamsCount - 1 do
  begin 
    if Trim(self.FRequestParamsList.Names[I]) = Trim(ParamsKey) then
    begin
      lvTemp := Trim(self.FRequestParamsList.ValueFromIndex[I]);
      Break;
    end;
  end; 

  Result := lvTemp;
end;

constructor TDiocpNtripRequest.Create;
begin
  inherited Create;
  FRawHeaderData := TMemoryStream.Create();
  FRawPostData := TMemoryStream.Create();
  FRequestHeader := TStringList.Create();
  FResponse := TDiocpNtripResponse.Create();

  FRequestParamsList := TStringList.Create; // TODO:创建存放http参数的StringList
end;

destructor TDiocpNtripRequest.Destroy;
begin
  FreeAndNil(FResponse);
  FRawPostData.Free;
  FRawHeaderData.Free;
  FRequestHeader.Free;

  FreeAndNil(FRequestParamsList); // TODO:释放存放http参数的StringList

  inherited Destroy;
end;

function TDiocpNtripRequest.DecodeRequestMethod: Integer;
var
  lvBuf: PAnsiChar;
begin
  Result := 0;
  if FRawHeaderData.Size <= 7 then
    Exit;

  lvBuf := FRawHeaderData.Memory;

  if FRequestMethod <> '' then
  begin
    Result := 1; // 已经解码
    Exit;
  end;

  // 请求方法（所有方法全为大写）有多种，各个方法的解释如下：
  // GET     请求获取Request-URI所标识的资源

  Result := 1;
  if (StrLIComp(lvBuf, 'GET', 3) = 0) then
  begin
    FRequestMethod := 'GET';
  end else if (StrLIComp(lvBuf, 'SOURCE', 6) = 0) then
  begin   // NtripSERVER
    FRequestMethod := 'SOURCE';
  end else
  begin
    Result := 2;
  end;
end;

function TDiocpNtripRequest.DecodeRequestHeader: Integer;
var
  lvRawString: AnsiString;
  lvMethod, lvRawTemp: AnsiString;
  lvRequestCmdLine, lvTempStr, lvRemainStr: String;
  I, J: Integer;
  p : PChar;
begin
  Result := 1;
  SetLength(lvRawString, FRawHeaderData.Size);
  FRawHeaderData.Position := 0;
  FRawHeaderData.Read(lvRawString[1], FRawHeaderData.Size);
  FRequestHeader.Text := lvRawString;

  // GET /test?v=abc HTTP/1.1
  // SOURCE letmein /Mountpoint
  lvRequestCmdLine := FRequestHeader[0];
  P := PChar(lvRequestCmdLine);
  FRequestHeader.Delete(0);

  // Method
  lvTempStr := LeftUntil(P, [' ']);
  if lvTempStr = '' then Exit;
  lvTempStr := UpperCase(lvTempStr);

  // 跳过空格
  SkipChars(P, [' ']);
  if lvTempStr = 'GET' then
  begin
    FMountPoint := LeftUntil(P, [' ']);

    if FMountPoint <> '' then
    begin
      FMountPoint := StrPas(PChar(@FMountPoint[2]));
    end;


    // 跳过空格
    SkipChars(P, [' ']);

    // 请求的HTTP版本
    lvTempStr := P;
    FRequestVersionStr := UpperCase(lvTempStr);
  end else
  begin    // SOURCE
    Inc(P);
    if P^=' ' then
    begin
      FSourceRequestPass := '';
    end else
    begin
      FSourceRequestPass := LeftUntil(P, [' ']);
    end;
    // 跳过空格
    SkipChars(P, [' ']);
    FMountPoint := P;

  end;
end;

procedure TDiocpNtripRequest.DecodePostDataParam({$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
var
  lvRawData : AnsiString;
  lvRawParams, s:String;
  i:Integer;
  lvStrings:TStrings;
{$IFDEF UNICODE}
var
  lvBytes:TBytes;
{$ELSE}
{$ENDIF}
begin
  // 读取原始数据
  SetLength(lvRawData, FRawPostData.Size);
  FRawPostData.Position := 0;
  FRawPostData.Read(lvRawData[1], FRawPostData.Size);

  lvStrings := TStringList.Create;
  try
    // 先放入到Strings
    SplitStrings(lvRawData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin
      lvRawData := URLDecode(lvStrings.ValueFromIndex[i]);
      if lvRawData <> '' then   // 不合法的Key-Value会导致空字符串
      begin
        {$IFDEF UNICODE}
        if pvEncoding <> nil then
        begin
          // 字符编码转换
          SetLength(lvBytes, length(lvRawData));
          Move(PByte(lvRawData)^, lvBytes[0], Length(lvRawData));
          s := pvEncoding.GetString(lvBytes);
        end else
        begin
          s := lvRawData;
        end;
        {$ELSE}
        if pvUseUtf8Decode then
        begin
          s := UTF8Decode(lvRawData);
        end else
        begin
          s := lvRawData;
        end;
        {$ENDIF}

        // 解码参数
        lvStrings.ValueFromIndex[i] := s;
      end;
    end;
    FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;
end;

function TDiocpNtripRequest.ExtractBasicAuthenticationInfo(var vUser,
    vPass:string): Boolean;
var
  lvAuth, lvValue:string;
  p:PChar;
begin
  Result := False;
  // Authorization: Basic aHVnb2JlbjpodWdvYmVuMTIz
  lvAuth := Trim(StringsValueOfName(FRequestHeader, 'Authorization', [':'], true));
  if lvAuth <> '' then
  begin  // 认证信息
    p := PChar(lvAuth);    //Basic aHVnb2JlbjpodWdvYmVuMTIz

    // 跳过Basic
    SkipUntil(P, [' ']);
    SkipChars(P, [' ']);


    // Base64
    lvValue := P;
    lvValue := Base64ToStr(lvValue);

    /// userid:pasword
    P := PChar(lvValue);

    // 取用户ID
    vUser := LeftUntil(P, [':']);
    SkipChars(P, [':']);
    // 取密码
    vPass := P;

    Result := true;
  end;

end;


function TDiocpNtripRequest.ExtractNMEAString: String;
var
  lvRawString:AnsiString;
begin
  SetLength(lvRawString, self.FRawPostData.Size);
  FRawPostData.Position := 0;
  FRawPostData.Read(lvRawString[1], FRawPostData.Size);
  Result := lvRawString;
end;

/// <summary>
///  解析POST和GET参数
/// </summary>
/// <pvParamText>
/// <param name="pvParamText">要解析的全部参数</param>
/// </pvParamText>
procedure TDiocpNtripRequest.ParseParams(pvParamText: string);
begin
  SplitStrings(pvParamText, FRequestParamsList, ['&']);
end;

procedure TDiocpNtripRequest.WriteRawBuffer(const buffer: Pointer; len: Integer);
begin
  FRawHeaderData.WriteBuffer(buffer^, len);
end;

procedure TDiocpNtripResponse.BadPassword;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'ERROR - Bad Password' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);

end;

procedure TDiocpNtripResponse.Clear;
begin
  FData.Clear;
  FResponseHeader := '';
end;

constructor TDiocpNtripResponse.Create;
begin
  inherited Create;
  FData := TMemoryStream.Create();
end;

destructor TDiocpNtripResponse.Destroy;
begin
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TDiocpNtripResponse.ICY200OK;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'ICY 200 OK' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.InvalidPasswordMsg(pvMountpoint: string);
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'Server: NtripCaster/1.0' + sLineBreak
          + 'WWW-Authenticate: Basic realm="/' +pvMountpoint + '"' + sLineBreak
          + 'Content-Type: text/html' + sLineBreak
          + 'Connection: close' + sLineBreak
          + '<html><head><title>401 Unauthorized</title></head><body bgcolor=black text=white link=blue alink=red>' + sLineBreak
          + '<h1><center>The server does not recognize your privileges to the requested entity stream</center></h1>' + sLineBreak
          + '</body></html>' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.SourceTableOKAndData(pvSourceTable:AnsiString);
var
  lvData:AnsiString;
  len: Integer;
begin
//SOURCETABLE 200 OK
//Content-Type: text/plain
//Content-Length: n
//CAS;129.217.182.51;80;EUREF;BKG;0;DEU;51.5;7.5;http://igs.ifag.de/index_ntrip_cast.htm
//CAS;62.159.109.248;8080;Trimble GPSNet;Trimble Terrasat;1;DEU;48.03;11.72;http://www.virtualrtk.com
//NET;EUREF;EUREF;B;N;http://www.epncb.oma.be/euref_IP;http://www.epncb.oma.be/euref_IP;http
//ENDSOURCETABLE

  lvData := 'SOURCETABLE 200 OK' + sLineBreak +
            'Content-Type: text/plain' + sLineBreak +
            'Content-Length: ' + IntToStr(length(pvSourceTable)) + sLineBreak + sLineBreak +
            pvSourceTable + sLineBreak +
           'ENDSOURCETABLE' + sLineBreak + sLineBreak;


  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.SourceTableOK;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'SOURCETABLE 200 OK' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.Unauthorized;
var
  lvData:AnsiString;
  len: Integer;
begin
  lvData := 'HTTP/1.0 401 Unauthorized' + sLineBreak;
  len := Length(lvData);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvData), len);
end;

procedure TDiocpNtripResponse.WriteBuf(pvBuf: Pointer; len: Cardinal);
begin
  FData.Write(pvBuf^, len);
end;

procedure TDiocpNtripResponse.WriteString(pvString: string; pvUtf8Convert:
    Boolean = true);
var
  lvRawString: AnsiString;
begin
  if pvUtf8Convert then
  begin     // 进行Utf8转换
    lvRawString := UTF8Encode(pvString);
  end else
  begin
    lvRawString := AnsiString(pvString);
  end;
  FData.WriteBuffer(PAnsiChar(lvRawString)^, Length(lvRawString));
end;

procedure TDiocpNtripClientContext.AddNtripClient(
  pvContext: TDiocpNtripClientContext);
begin
  // 当前是否NtripSource
  if FContextMode <> ncmNtripSource then Exit;

  self.Lock;
  try
    FNtripClients.Add(pvContext);
  finally
    self.UnLock;
  end;
end;

constructor TDiocpNtripClientContext.Create;
begin
  inherited Create;
  FNtripClients := TList.Create;
  FTempNtripClients := TList.Create;
end;

destructor TDiocpNtripClientContext.Destroy;
begin
  FNtripClients.Free;
  FTempNtripClients.Free;
  inherited Destroy;
end;

procedure TDiocpNtripClientContext.DispatchGNSSDATA(buf: Pointer;
  len: Cardinal);
var
  i:Integer;
  lvContext:TDiocpNtripClientContext;
begin
  FTempNtripClients.Clear;
  // copy到临时列表中
  Self.Lock;
  FTempNtripClients.Assign(FNtripClients);
  Self.UnLock;

  for i := 0 to FTempNtripClients.Count -1 do
  begin
    lvContext :=TDiocpNtripClientContext(FTempNtripClients[i]);
    if lvContext.LockContext('分发GNSS数据', Self) then
    begin
      try
        if lvContext.FMountPoint <> self.FMountPoint then  // 不是请求的挂节点
        begin
          RemoveNtripClient(lvContext);
        end else
        begin
          // 分发数据
          lvContext.PostWSASendRequest(buf, len);
        end;
      finally
        lvContext.UnLockContext('分发GNSS数据', Self);
      end;
    end else
    begin
      RemoveNtripClient(lvContext);
    end;
  end;
end;

procedure TDiocpNtripClientContext.DoCleanUp;
begin
  inherited;
  FTag := 0;
  FTagStr := '';
  FNtripState := hsCompleted;
  FContextMode := ncmNtripNone;
  FMountPoint := '';
  // 清空列表
  FNtripClients.Clear;
  if FCurrentRequest <> nil then
  begin
    FCurrentRequest.Close;
    FCurrentRequest := nil;
  end;
end;

procedure TDiocpNtripClientContext.DoNtripSourceAuthentication(
    pvRequest:TDiocpNtripRequest);
begin
  // 进行密码认证
  if pvRequest.SourceRequestPass <> TDiocpNtripServer(FOwner).FNtripSourcePassword then
  begin
    pvRequest.Response.BadPassword;
    pvRequest.CloseContext;
    Exit;
  end else
  begin
    Self.FContextMode := ncmNtripSource;

    // 改变装入进入接收数据模式
    FNtripState := hsRecvingSource;

    // 添加到NtripSource对应表中
    TDiocpNtripServer(FOwner).FNtripSources.Lock;
    TDiocpNtripServer(FOwner).FNtripSources.ValueMap[FMountPoint] := Self;
    TDiocpNtripServer(FOwner).FNtripSources.unLock;

    // 回应请求
    pvRequest.Response.ICY200OK;

  end;
end;

procedure TDiocpNtripClientContext.DoRequest(pvRequest: TDiocpNtripRequest);
begin
   {$IFDEF QDAC_QWorker}
   Workers.Post(OnExecuteJob, pvRequest);
   {$ELSE}
     {$IFDEF DIOCP_TASK}
     iocpTaskManager.PostATask(OnExecuteJob, pvRequest);
     {$ELSE}
     try
       // 直接触发事件
       OnRequest(pvRequest);
       TDiocpNtripServer(FOwner).DoRequest(pvRequest);
     finally
       pvRequest.close();
     end;
     {$ENDIF}
   {$ENDIF}
end;

{$IFDEF QDAC_QWorker}
procedure TDiocpNtripClientContext.OnExecuteJob(pvJob:PQJob);
var
  lvObj:TDiocpNtripRequest;
begin
  lvObj := TDiocpNtripRequest(pvJob.Data);
  try
    // 触发事件
    OnRequest(lvObj);
    TDiocpNtripServer(FOwner).DoRequest(lvObj);
  finally
    lvObj.close();
  end;
end;

{$ENDIF}

{$IFDEF DIOCP_Task}
procedure TDiocpNtripClientContext.OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
var
  lvObj:TDiocpNtripRequest;
begin
  lvObj := TDiocpNtripRequest(pvTaskRequest.TaskData);
  try
    // 触发事件
    OnRequest(lvObj);
    TDiocpNtripServer(FOwner).DoRequest(lvObj);
  finally
    lvObj.close();
  end;
end;
{$ENDIF}



procedure TDiocpNtripClientContext.OnDisconnected;
begin
  if ContextMode = ncmNtripSource then
  begin
    // 移除
    TDiocpNtripServer(FOwner).FNtripSources.Lock;
    TDiocpNtripServer(FOwner).FNtripSources.ValueMap[FMountPoint] := nil;
    TDiocpNtripServer(FOwner).FNtripSources.unLock;
  end;

  inherited;
end;

procedure TDiocpNtripClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: Word);
var
  lvTmpBuf: PAnsiChar;
  CR, LF: Integer;
  lvRemain: Cardinal;
  lvTempRequest: TDiocpNtripRequest;
  lvIsNMEA:Boolean;
begin
  if self.FNtripState = hsRecvingSource then
  begin   // 直接接收NtripSource数据
    if Assigned(TDiocpNtripServer(FOwner).FOnDiocpRecvNtripSourceBuffer) then
    begin
      TDiocpNtripServer(FOwner).FOnDiocpRecvNtripSourceBuffer(Self, buf, len);
    end;
  end else
  begin
    lvTmpBuf := buf;
    CR := 0;
    LF := 0;
    lvRemain := len;
    while (lvRemain > 0) do
    begin
      if FNtripState = hsCompleted then
      begin // 完成后重置，重新处理下一个包
        FCurrentRequest := TDiocpNtripServer(Owner).GetRequest;
        FCurrentRequest.FDiocpContext := self;
        FCurrentRequest.Response.FDiocpContext := self;
        FCurrentRequest.Clear;
        FNtripState := hsRequest;
      end;

      if (FNtripState = hsRequest) then
      begin
        case lvTmpBuf^ of
          #13:
            Inc(CR);
          #10:
            Inc(LF);
        else
          CR := 0;
          LF := 0;
        end;

        // 写入请求数据
        FCurrentRequest.WriteRawBuffer(lvTmpBuf, 1);

        if FCurrentRequest.DecodeRequestMethod = 2 then
        begin // 无效的Http请求
          // 还回对象池
          self.RequestDisconnect('无效的Http请求', self);
          Exit;
        end;

        // 请求数据已接收完毕(#13#10#13#10是HTTP请求结束的标志)
        if (CR = 2) and (LF = 2) then
        begin
          if FCurrentRequest.DecodeRequestHeader = 0 then
          begin
            self.RequestDisconnect('无效的Http协议数据', self);
            Exit;
          end;

          // 设置Context的挂机点
          Self.FMountPoint := FCurrentRequest.FMountPoint;

          if SameText(FCurrentRequest.FRequestMethod, 'SOURCE') then
          begin    // NtripSource进行认证

            lvTempRequest := FCurrentRequest;

            // 避免断开后还回对象池，造成重复还回
            FCurrentRequest := nil;

            DoNtripSourceAuthentication(lvTempRequest);

          end else
          begin
            // client请求模式
            FContextMode := ncmNtripClient;

            lvIsNMEA := false;
            if Assigned(TDiocpNtripServer(FOwner).OnRequestAcceptEvent) then
            begin
              TDiocpNtripServer(FOwner).OnRequestAcceptEvent(FCurrentRequest, lvIsNMEA);
            end;

            if lvIsNMEA then
            begin  // 接收NMEA数据
              FNtripState := hsRecevingNEMA;
              FCurrentRequest.RawPostData.Clear();
            end else
            begin
              FNtripState := hsCompleted;

              lvTempRequest := FCurrentRequest;

              // 避免断开后还回对象池，造成重复还回
              FCurrentRequest := nil;

              // 触发事件
              DoRequest(lvTempRequest);

              FCurrentRequest := nil;
              Break;
            end;
          end;
        end; //
      end else if FNtripState = hsRecevingNEMA then
      begin
        case lvTmpBuf^ of
          #13:
            Inc(CR);
          #10:
            Inc(LF);
        else
          CR := 0;
          LF := 0;
        end;

        // 写入请求数据
        FCurrentRequest.RawPostData.Write(lvTmpBuf^, 1);
        if (CR = 1) and (LF = 1) then
        begin
          FNtripState := hsCompleted;

          lvTempRequest := FCurrentRequest;

          // 避免断开后还回对象池，造成重复还回
          FCurrentRequest := nil;

          // 触发事件
          DoRequest(lvTempRequest);

          FCurrentRequest := nil;
          Break;
        end;
      end;
      Dec(lvRemain);
      Inc(lvTmpBuf);
    end;
  end;
end;

procedure TDiocpNtripClientContext.OnRequest(pvRequest:TDiocpNtripRequest);
begin

end;

procedure TDiocpNtripClientContext.RemoveNtripClient(
  pvContext: TDiocpNtripClientContext);
begin
  self.Lock;
  try
    FNtripClients.Remove(pvContext);
  finally
    self.UnLock;
  end;
end;

{ TDiocpNtripServer }

constructor TDiocpNtripServer.Create(AOwner: TComponent);
begin
  inherited;
  FRequestPool := TBaseQueue.Create;
  FNtripSources := TDHashTableSafe.Create();

  KeepAlive := false;
  RegisterContextClass(TDiocpNtripClientContext);
end;

destructor TDiocpNtripServer.Destroy;
begin
  FRequestPool.FreeDataObject;
  FNtripSources.Free;
  inherited;
end;

procedure TDiocpNtripServer.DoRequest(pvRequest: TDiocpNtripRequest);
begin
  if Assigned(FOnDiocpNtripRequest) then
  begin
    FOnDiocpNtripRequest(pvRequest);
  end;
end;

procedure TDiocpNtripServer.DoRequestPostDataDone(pvRequest: TDiocpNtripRequest);
var
  lvRawData:AnsiString;
begin 
  if Assigned(FOnDiocpNtripRequestPostDone) then
  begin
    FOnDiocpNtripRequestPostDone(pvRequest);
  end;
end;

function TDiocpNtripServer.FindNtripSource(
  pvMountPoint: string): TDiocpNtripClientContext;
begin
  FNtripSources.Lock;
  Result := TDiocpNtripClientContext(FNtripSources.ValueMap[pvMountPoint]);
  FNtripSources.unLock();
end;

function TDiocpNtripServer.GetRequest: TDiocpNtripRequest;
begin
  Result := TDiocpNtripRequest(FRequestPool.DeQueue);
  if Result = nil then
  begin
    Result := TDiocpNtripRequest.Create;
  end;
  Result.FDiocpNtripServer := Self;
end;

procedure TDiocpNtripServer.GiveBackRequest(pvRequest: TDiocpNtripRequest);
begin
  FRequestPool.EnQueue(pvRequest);
end;

end.
