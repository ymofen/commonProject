unit diocp.p2p;

interface

uses
  diocp.udp, SysUtils, utils.strings;

type
  TSessionInfo = class(TObject)
  private
    FIP: string;
    FPort: Integer;
  public
    property IP: string read FIP write FIP;
    property Port: Integer read FPort write FPort;

  end;
  TDiocpP2PManager = class(TObject)
  private
    FDiocpUdp: TDiocpUdp;
    procedure OnRecv(pvReqeust:TDiocpUdpRecvRequest);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TDiocpP2PManager.Create;
begin
  inherited Create;
  FDiocpUdp := TDiocpUdp.Create(nil);
  FDiocpUdp.OnRecv := OnRecv;
end;

destructor TDiocpP2PManager.Destroy;
begin
  FDiocpUdp.Stop();
  FreeAndNil(FDiocpUdp);
  inherited Destroy;
end;

procedure TDiocpP2PManager.OnRecv(pvReqeust:TDiocpUdpRecvRequest);
var
  lvCMD:AnsiString;
begin
   // 0                      : 请求激活，返回0, id
   // 1,id                   : 心跳包
   // 2,request_id, dest_id  : 请求打洞
   SetLength(lvCMD, pvReqeust.RecvBufferLen);
   Move(pvReqeust.RecvBuffer^, PAnsiChar(lvCMD)^, pvReqeust.RecvBufferLen);

end;

end.
