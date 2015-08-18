unit UnitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Winsock2, ComCtrls, ExtCtrls, IniFiles;

const
  WM_SOCKET = WM_USER+300;

type
  TMainForm = class(TForm)
    ListView1: TListView;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    sock: TSocket;
    clientList: TList;

    procedure WMSOCKET(var msg: TMessage);message WM_SOCKET;
    procedure UpdateOnlines;//服务端在线人员更新
    procedure UpdateOnlinesClient;//广播客户端在线情况
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses Protocol;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  aWSAData: TWSAData;
  addr: TSockAddrIn;
  ini: TIniFile;
  serverPort: Integer;
begin
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\server.ini');
  serverPort:=ini.ReadInteger('Config','Port',SERVER_PORT);
  clientList:=TList.Create;
  if WSAStartup($0101,aWSAData) <> 0 then
    showmessage('Winsock Version Error');

  sock:=Socket(AF_INET,SOCK_DGRAM,0);

  addr.sin_family:=AF_INET;
  addr.sin_port:=htons(serverPort);
  addr.sin_addr.S_addr:=INADDR_ANY;
  if bind(sock,@addr,sizeof(addr))=SOCKET_ERROR then
  begin
    ShowMessage('绑定'+inttostr(serverPort)+'端口失败，请修改server.ini，重启本程序');
    closesocket(sock);
    ini.Free;
    Exit;
  end;

  if SOCKET_ERROR=WSAAsyncSelect(sock,Handle,WM_SOCKET,FD_READ) then
    showmessage('WM_SOCKET Error');
  ini.Free;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
   i:Integer;
begin
  for i:=0 to clientList.Count-1 do
      FreeMem(PClientInfo(clientList.Items[i]));
  clientList.Free;

  closesocket(sock);
  WSACleanup;
end;

procedure TMainForm.UpdateOnlines;
var
  i: Integer;
  lsv:TListItem;
  tmp:TInAddr;
begin
  ListView1.Clear;
  for i:=0 to clientList.Count-1 do
  begin
    tmp.S_addr:=PClientInfo(clientList.Items[i]).ip;
    lsv:=ListView1.Items.Add;
    lsv.Caption:=PClientInfo(clientList.Items[i]).name;
    lsv.SubItems.Add(inet_ntoa(tmp));
    lsv.SubItems.Add(inttostr(ntohs(PClientInfo(clientList.Items[i]).port)));
   end;
end;

procedure TMainForm.WMSOCKET(var msg: TMessage);
var
  addr: TSockAddrIn;//接收到的主机信息
  addrTo: TSockAddrIn;//通知打洞方的主机地址信息
  addrlen,addrTolen: Integer;
  i: Integer;
  pCInfo: PClientInfo;
  buffer: array [0..1500] of byte;
  head: TP2PHead;//包头
  iP2PLogin: TP2PLogin;
  oP2PLoginRespPack: TP2PLoginRespPack;
  iP2PLogout: TP2PLogout;
  iP2PUserInfo: TP2PUserInfo;
  oP2PUserInfoRespPack: TP2PUserInfoRespPack;
  oP2PMakeHolePack: TP2PMakeHolePack;
  iP2POnline: TP2POnline;
begin
  case WSAGetSelectEvent(msg.LParam) of
    FD_READ:
    begin
      addrlen:=sizeof(addr);
      addrTolen:=sizeof(addrTo);
      recvfrom(sock,buffer,1500,0,@addr,addrlen);
      Move(buffer,head,sizeof(head));//从buffer中分离出包头
      case head.Command of
        cmdLogin:
        begin
          move(buffer[sizeof(head)],iP2PLogin,sizeof(iP2PLogin));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2PLogin.name)=0 then
            begin
              {发送登录失败的信息}
              oP2PLoginRespPack.head.Command:=cmdLoginResp;
              oP2PLoginRespPack.body.res:=False;//登录失败，名字有重复
              sendto(sock,oP2PLoginRespPack,sizeof(oP2PLoginRespPack),0,@addr,addrlen);
              Exit;
            end;
          end;
          {保存Client信息}
          GetMem(pCInfo,sizeof(TClientInfo));
          StrCopy(pCInfo^.name,iP2PLogin.name);
          pCInfo^.ip:=addr.sin_addr.S_addr;
          pCInfo^.port:=addr.sin_port;
          pCInfo^.ticktime:=GetTickCount;
          clientList.Add(pCInfo);

          UpdateOnlines;
          {发送登录成功的信息}
          oP2PLoginRespPack.head.Command:=cmdLoginResp;
          oP2PLoginRespPack.body.res:=True;//登录成功
          sendto(sock,oP2PLoginRespPack,sizeof(oP2PLoginRespPack),0,@addr,addrlen);
        end;

        cmdLogout:{退出}
        begin
          move(buffer[sizeof(head)],ip2plogout,sizeof(iP2PLogout));
          for i:=clientList.Count-1 downto 0 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,ip2plogout.name)=0 then
            begin
              FreeMem(PClientInfo(clientList.Items[i]));
              clientList.Delete(i);
            end
          end;

          UpdateOnlines;
          UpdateOnlinesClient;
        end;


        cmdOnline://客户端保持在线
        begin
          move(buffer[sizeof(head)],iP2POnline,sizeof(iP2POnline));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2POnline.name)=0 then
              PClientInfo(clientList.Items[i]).ticktime:=GetTickCount;
          end;
        end;


        cmdUserList://用户请求用户列表
        begin
          UpdateOnlinesClient;
        end;


        cmdUserInfo://用户穿透前提出获得对方主机IP port信息
        begin
          move(buffer[sizeof(head)],ip2puserinfo,sizeof(ip2puserinfo));
          for i:=0 to clientList.Count-1 do
          begin
            if StrComp(PClientInfo(clientList.Items[i]).name,iP2PUserInfo.name2)=0 then
            begin
              {返回clientA，另一端clientB的主机信息}
              oP2PUserInfoRespPack.head.Command:=cmdUserInfoResp;
              StrPCopy(oP2PUserInfoRespPack.body.name,PClientInfo(clientList.Items[i]).name);
              oP2PUserInfoRespPack.body.ip:=PClientInfo(clientList.Items[i]).ip;
              oP2PUserInfoRespPack.body.port:=PClientInfo(clientList.Items[i]).port;
              sendto(sock,oP2PUserInfoRespPack,sizeof(oP2PUserInfoRespPack),0,
                @addr,addrlen);

              {向另一端clientB发送向clientA的打洞命令}
              addrTo.sin_family:=AF_INET;
              addrTo.sin_addr.S_addr:=PClientInfo(clientList.Items[i]).ip;
              addrTo.sin_port:=PClientInfo(clientList.Items[i]).port;

              oP2PMakeHolePack.head.Command:=cmdMakeHole;
              StrPCopy(oP2PMakeHolePack.body.name,ip2puserinfo.name1);
              oP2PMakeHolePack.body.ip:=addr.sin_addr.S_addr;
              oP2PMakeHolePack.body.port:=addr.sin_port;

              sendto(sock,oP2PMakeHolePack,sizeof(oP2PMakeHolePack),0,
                @addrTo,addrTolen);

              break;
            end;

          end;
        end;
      end;
    end;
  end;

end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  NowTick: Integer;
  i: Integer;
begin
  NowTick:=GetTickCount;
  for i:=0 to clientList.Count-1 do
  begin
    if NowTick-PClientInfo(clientList[i]).ticktime>30000 then
    begin
      FreeMem(PClientInfo(clientList.Items[i]));
      clientList.Delete(i);
      UpdateOnlines;
      UpdateOnlinesClient;
    end;
  end;
end;

procedure TMainForm.UpdateOnlinesClient;
var
  addrTo: TSockAddrIn;
  addrTolen: Integer;
  i: Integer;
  s: string;
  pack: TP2PUserListRespPack;
begin
  addrTolen:=sizeof(addrTo);
  s:='';
  for i:=clientList.Count-1 downto 0 do
    s:=s+PClientInfo(clientList.Items[i]).name+'|';
  pack.head.Command:=cmdUserListResp;
  StrPCopy(pack.body.users,s);

  for i:=0 to clientList.Count-1 do{广播所有用户}
  begin
    addrTo.sin_family:=AF_INET;
    addrTo.sin_port:=PClientInfo(clientList.Items[i]).port;
    addrTo.sin_addr.S_addr:=PClientInfo(clientList.Items[i]).ip;
    sendto(sock,pack,sizeof(pack),0,@addrTo,addrTolen);
  end;
end;

end.
