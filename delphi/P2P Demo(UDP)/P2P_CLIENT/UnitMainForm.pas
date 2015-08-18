unit UnitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Protocol, WinSock2, ExtCtrls, IniFiles, Gauges, XPMan,
  MMSystem;

const
  WM_SOCKET = WM_USER + 200;

type
  TSendFileInfo = packed record
    FileName: string;
    FileSize: Integer;
    ID: Integer;
    size: Integer;
    BlockCount: Integer;
    position: Integer;
    LastTickCount: Integer;
    IsWorking: Boolean;
    progress: Integer;
    startTick: Integer;
  end;
  TRecvFileInfo = packed record
    FileName: string;
    FileSize: Integer;
    ID: Integer;
    size: Integer;
    BlockCount: Integer;
    position: Integer;
    IsWorking: Boolean;
    progress: Integer;
    startTick: Integer;
  end;

type
  TMainForm = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    EdtIP: TEdit;
    EdtPort: TEdit;
    EdtName: TEdit;
    btnConnect: TButton;
    ListBox1: TListBox;
    TimerMakeHole: TTimer;
    EdtMessage: TEdit;
    btnSend: TButton;
    Memo1: TMemo;
    EdtFile: TEdit;
    btnBrowse: TButton;
    btnSendFile: TButton;
    Gauge1: TGauge;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Label4: TLabel;
    btnClear: TButton;
    btnRefresh: TButton;
    Label5: TLabel;
    TimerKeepOnline: TTimer;
    CheckBox1: TCheckBox;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure TimerMakeHoleTimer(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnSendFileClick(Sender: TObject);
    procedure EdtMessageKeyPress(Sender: TObject; var Key: Char);
    procedure btnClearClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure TimerKeepOnlineTimer(Sender: TObject);
  private
    { Private declarations }
    sock: TSocket;
    LoginTickCount: Integer;//用了验证登录包是否发送超时
    addrSrv :TSockAddrIn;//Server的地址
    addrP2P :TSockAddrIn;//对方的地址
    sendInfo :TSendFileInfo;//发送文件的状态信息
    recvInfo :TRecvFileInfo;//接收文件的状态信息
    readfs,writefs: TFileStream;//读写文件流
    procedure WMSOCKET(var msg: TMessage);message WM_SOCKET;
    procedure SendBlock(var s: TSendFileInfo);
    procedure AcceptRecvFile(b: Boolean);//发送是否接收对方文件消息
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses CRC32;

{$R 'res\res.res' 'res\res.rc'}
{$R *.dfm}
function GetBlockCount(Size:Integer):Integer;
begin
  Result:=(Size div BlockSize);
  if (Size mod BlockSize) > 0 then
    Inc(Result);
end;

procedure OnCheckBlockRespPack();//检查回复包是否超时
begin
  if GetTickCount-MainForm.sendInfo.LastTickCount>1000 then
  begin
    if MainForm.CheckBox1.State=cbUnchecked then
      MainForm.Memo1.Lines.Add('包 '+IntToStr(MainForm.sendInfo.ID)+' 丢失或超时，重发。。。'+#13);
    KillTimer(MainForm.Handle,1);
    MainForm.SendBlock(MainForm.sendInfo);
  end;
end;

procedure OnCheckLoginResp();//检查是否登录包发送超时
begin
  if GetTickCount-MainForm.LoginTickCount>2000 then
  begin
    KillTimer(MainForm.Handle,2);
    ShowMessage('服务器连接失败');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  pack: TP2PLogoutPack;
  pack2: TP2PCancelTransferPack;
  ini: TIniFile;
begin
  if sendInfo.IsWorking or recvInfo.IsWorking then
  begin
    pack2.head.Command:=cmdCancelTransfer;
    sendto(sock,pack2,sizeof(pack2),0,@addrP2P,sizeof(addrP2P));
  end;

  pack.head.Command:=cmdLogout;
  strpcopy(pack.body.name,EdtName.Text);
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));

  closesocket(sock);
  WSACleanup;
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\config.ini');
  ini.WriteString('Config','Server',EdtIP.Text);
  ini.WriteString('Config','Name',EdtName.Text);
  ini.WriteString('Config','Port',EdtPort.Text);
  ini.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  aWSAData: TWSAData;
  addr: TSockAddrIn;
  //i: integer;
  ini: TIniFile;
begin
  ini:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\config.ini');
  EdtIP.Text:=ini.ReadString('Config','Server','127.0.0.1');
  EdtPort.Text:=IntToStr(SERVER_PORT);
  EdtName.Text:=ini.ReadString('Config','Name','');
  EdtPort.Text:=ini.ReadString('Config','Port',IntToStr(SERVER_PORT));
  ini.Free;

  sendInfo.IsWorking:=False;
  recvInfo.IsWorking:=False;

  if WSAStartup($0101, aWSAData) <> 0 then
    ShowMessage('Winsock Version Error');

  sock:=Socket(AF_INET,SOCK_DGRAM,0);

  addr.sin_family:=AF_INET;
  addr.sin_addr.S_addr:=INADDR_ANY;
  {for i:=0 to 200 do//如果端口绑定失败，端口将递增，尝试200次
  begin
    addr.sin_port:=htons(CLIENT_PORT+i);
    if bind(sock,@addr,sizeof(addr))<>SOCKET_ERROR then
      break;
  end;}

  if SOCKET_ERROR=WSAAsyncSelect(sock,Handle,WM_SOCKET,FD_READ) then
    ShowMessage('WM_SOCKET Error');
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
var
  pack: TP2PLoginPack;
begin
  if EdtName.Text='' then
  begin
    ShowMessage('请输入名字');
    EdtName.SetFocus;
    Exit;
  end;

  addrSrv.sin_addr.S_addr:=inet_addr(pChar(EdtIP.Text));
  addrSrv.sin_family:=AF_INET;
  addrSrv.sin_port:=htons(StrToInt(EdtPort.Text));

  pack.head.Command:=cmdLogin;
  strpcopy(pack.body.name,EdtName.Text);

  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
  LoginTickCount:=GetTickCount;
  SetTimer(Handle,2,200,@OnCheckLoginResp);
end;

procedure TMainForm.WMSOCKET(var msg: TMessage);
var
  addr: TSockAddrIn;//接收到的主机信息
  addrlen: Integer;//地址结构长度
  i: Integer;//for循环专用
  buffer: array [0..1500] of byte;//数据包
  head: TP2PHead;//包头
  {i开头的是接收的消息结构，o开头的是发出的消息结构}
  iP2PLoginResp: TP2PLoginResp;//server登录回应
  oP2PUserListPack: TP2PUserListPack;//请求用户列表
  users: TStrings;//在线用户信息临时变量，用于分割字符
  iP2PUserListResp: TP2PUserListResp;//server返回的在线用户信息
  iP2PUserInfoResp: TP2PUserInfoResp;//server返回的指定用户信息
  iP2PMakeHole: TP2PMakeHole;//server要求你打洞，包含对方的主机信息
  iP2PMessage: TP2PMessage;//p2p之间的聊天信息
  iP2PInquireAcceptFile: TP2PInquireAcceptFile;//询问是否接收文件
  iP2PInquireAcceptFileResp: TP2PInquireAcceptFileResp;//同上，只是方向不同
  fileBuffer: PChar;//用来预先分配硬盘空间，来创建一个文件
  iP2PSendBlock: TP2PSendBlock;//接收到的文件数据块
  oP2PSendBlockRespPack: TP2PSendBlockRespPack;//返回 接收到的文件数据块 信息
  iP2PSendBlockResp: TP2PSendBlockResp;//接收用户文件块收到后的反馈
  crc32: DWORD;
  reshwnd: THandle;
  p: Pointer;
begin
  case WSAGetSelectEvent(msg.LParam) of
    FD_READ:
    begin
      addrlen:=sizeof(addr);
      recvfrom(sock,buffer,1500,0,@addr,addrlen);
      Move(buffer,head,sizeof(head));//从buffer中分离出数据包包头
      case head.Command of
        cmdLoginResp://登录回应
        begin
          //从buffer中分离数据包主体，下面都是如此
          KillTimer(MainForm.Handle,2);//接到登录回应包了，是时候把检查登录回应计时器关掉了
          move(buffer[sizeof(head)],iP2PLoginResp,sizeof(iP2PLoginResp));
          if iP2PLoginResp.res then
          begin
            //ShowMessage('登录成功');
            TimerKeepOnline.Enabled:=True;
            EdtName.Enabled:=False;
            EdtIP.Enabled:=False;
            EdtPort.Enabled:=False;
            btnConnect.Enabled:=False;
            oP2PUserListPack.head.Command:=cmdUserList;//登录后刷新在线用户信息
            sendto(sock,oP2PUserListPack,sizeof(oP2PUserListPack),0,@addr,sizeof(addr));
          end else
          begin
            ShowMessage('名字重复，请更名');
            EdtName.SetFocus;
          end;
        end;


        cmdUserListResp://返回所有在线用户名字
        begin
          ListBox1.Clear;
          move(buffer[sizeof(head)],iP2PUserListResp,sizeof(iP2PUserListResp));
          users:=TStringList.Create;//利用TStrings分割字符串
          users.Delimiter:='|';
          users.DelimitedText:=iP2PUserListResp.users;
          for i:=0 to users.Count-2 do//显示除自己外的所有在线人员
            if users[i]<>EdtName.Text then ListBox1.Items.Add(users[i]);
          users.Free;
        end;


        cmdUserInfoResp://返回我欲对话的用户信息，可以接着去和他打洞
        begin
          move(buffer[sizeof(head)],iP2PUserInfoResp,sizeof(iP2PUserInfoResp));
          addrP2P.sin_family:=AF_INET;//下面是对家的主机信息
          addrP2P.sin_port:=iP2PUserInfoResp.port;
          addrP2P.sin_addr.S_addr:=iP2PUserInfoResp.ip;

          {P2P之间的打洞，和服务器无关，主动打洞，维持心跳}
          TimerMakeHole.Enabled:=True;
        end;


        cmdMakeHole://服务器的打洞命令（被动打洞）
        begin
          move(buffer[sizeof(head)],iP2PMakeHole,sizeof(iP2PMakeHole));
          addrP2P.sin_family:=AF_INET;
          addrP2P.sin_port:=iP2PMakeHole.port;
          addrP2P.sin_addr.S_addr:=iP2PMakeHole.ip;
          //iP2PMakeHole.name字段保留

          TimerMakeHole.Enabled:=True;//维持打洞心跳
        end;


        cmdHole://打洞消息，无视它
        begin
        end;


        cmdMessage://P2P文字信息
        begin
          move(buffer[sizeof(head)],iP2PMessage,sizeof(iP2PMessage));
          Memo1.Lines.Add(iP2PMessage.name + ' : '+iP2PMessage.Text+#13);
          reshwnd:=FindResource(hInstance,'msg','WAV');
          reshwnd:=LoadResource(hInstance,reshwnd);
          p:=LockResource(reshwnd);
          sndPlaySound(p,SND_MEMORY or SND_ASYNC);
          UnlockResource(reshwnd);
          FreeResource(reshwnd);
        end;


        cmdInquireAcceptFile://询问是否接收文件
        begin
          move(buffer[sizeof(head)],iP2PInquireAcceptFile,sizeof(iP2PInquireAcceptFile));
          reshwnd:=FindResource(hInstance,'ring','WAV');
          reshwnd:=LoadResource(hInstance,reshwnd);
          p:=LockResource(reshwnd);
          sndPlaySound(p,SND_MEMORY or SND_ASYNC);
          UnlockResource(reshwnd);
          FreeResource(reshwnd);
          memo1.Lines.Add('【'+iP2PInquireAcceptFile.name+'】发送文件【'+iP2PInquireAcceptFile.FileName
            +'】，大小为'+IntToStr(iP2PInquireAcceptFile.FileSize) + ' B('+
            IntToStr(Round(iP2PInquireAcceptFile.FileSize/1024))+' KB)'+#13);
          if IDYES = MessageBox(handle,PChar('是否要接收该文件？'),
              PChar('P2P Transfer File'),MB_YESNO or MB_ICONQUESTION) then
          begin
            SaveDialog1.FileName:=iP2PInquireAcceptFile.FileName;
            if SaveDialog1.Execute then
            begin//同意接收文件
              recvInfo.FileName:=SaveDialog1.FileName;
              recvInfo.FileSize:=iP2PInquireAcceptFile.FileSize;
              recvInfo.BlockCount:=GetBlockCount(recvInfo.FileSize);
              recvInfo.IsWorking:=True;
              {在硬盘上创建一个空文件，大小与接收文件一致}
              Label5.Caption:='创建文件。。。';
              if FileExists(recvInfo.FileName) then
                  DeleteFile(recvInfo.FileName);
              writefs:=TFileStream.Create(recvInfo.FileName,fmCreate);
              GetMem(fileBuffer,recvInfo.FileSize);
              writefs.Write(fileBuffer^,recvInfo.FileSize);
              FreeMem(fileBuffer);//【注】writefs将在文件全部接收完后在Free

              {发送‘同意接收文件’的信息给对家，等待文件流的到来}
              AcceptRecvFile(True);
              recvInfo.startTick:=GetTickCount;
            end else//拒绝接收文件(yes no 时同意，但选保存文件是取消)
              AcceptRecvFile(False);
          end else//拒绝接收文件(yes no 时拒绝)
            AcceptRecvFile(True);
        end;


        cmdInquireAcceptFileResp://返回对方是否接收文件
        begin
          move(buffer[sizeof(head)],iP2PInquireAcceptFileResp,sizeof(iP2PInquireAcceptFileResp));
          if iP2PInquireAcceptFileResp.Resp then
          begin
            Memo1.Lines.Add('【'+iP2PInquireAcceptFileResp.name+
                '】同意接收文件'+#13);
            btnSendFile.Enabled:=False;

            sendInfo.startTick:=GetTickCount;
            sendInfo.IsWorking:=True;
            readfs:=TFileStream.Create(sendInfo.FileName,fmOpenRead);
            sendInfo.ID:=0;//数据块ID统一将从0开始计数
            sendInfo.position:=0;
            if sendInfo.FileSize <= BlockSize then
              sendInfo.size:=sendInfo.FileSize
            else
              sendInfo.size:=BlockSize;

            Gauge1.Progress:=Round(sendInfo.position/sendInfo.FileSize*100);

            SendBlock(sendInfo);

          end
          else
            Memo1.Lines.Add('【'+iP2PInquireAcceptFileResp.name+
                '】拒绝接收文件'+#13);
        end;


        cmdSendBlock://接收文件块
        begin
          move(buffer[sizeof(head)],iP2PSendBlock,sizeof(iP2PSendBlock));

          GetCrc32Byte(iP2PSendBlock.Data,iP2PSendBlock.size,crc32);

          if crc32=iP2PSendBlock.CRC32 then
          begin//crc检查无误，返回正确信息
            {if recvInfo.ID = recvInfo.BlockCount-1 then//最后一个包
            begin
              FreeAndNil(writefs);
              //Memo1.Lines.Add('【文件'+recvInfo.FileName+'接收完毕】'+#13);
              Memo1.Lines.Add('【文件 '+recvInfo.FileName +' 接收完毕】，用时'
              +IntToStr(Round((GetTickCount-recvInfo.startTick)/1000))+'秒，平均速度'
              +IntToStr(Round(recvInfo.BlockCount/(GetTickCount-recvInfo.startTick)*1000))
              +' KB/s'+#13);
              oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
              oP2PSendBlockRespPack.body.position:=recvInfo.position;
              oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
              oP2PSendBlockRespPack.body.checkCRC:=True;
              oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
              sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));
              recvInfo.IsWorking:=False;

              Label5.Caption:='';
              Exit;
            end;}

            recvInfo.position:=iP2PSendBlock.position;
            recvInfo.ID:=iP2PSendBlock.ID;
            if writefs<> nil then
            begin
              writefs.Seek(recvInfo.position,soBeginning);
              writefs.Write(iP2PSendBlock.Data,iP2PSendBlock.size);
            end;

            oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
            oP2PSendBlockRespPack.body.position:=recvInfo.position;
            oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
            oP2PSendBlockRespPack.body.checkCRC:=True;
            oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
            sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));

            if recvInfo.BlockCount=recvInfo.ID+1 then//最后一个包
            begin
              FreeAndNil(writefs);
              Memo1.Lines.Add('文件【'+recvInfo.FileName +'】接收完毕，用时'
              +IntToStr(Round((GetTickCount-recvInfo.startTick)/1000))+'秒，平均速度'
              +IntToStr(Round(recvInfo.BlockCount/(GetTickCount-recvInfo.startTick)*1000))
              +' KB/s'+#13);
              {oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
              oP2PSendBlockRespPack.body.position:=recvInfo.position;
              oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
              oP2PSendBlockRespPack.body.checkCRC:=True;
              oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
              sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));}
              recvInfo.IsWorking:=False;
              Label5.Caption:='';
            end;
          end else
          begin//crc检查有误，请求重发该包
            oP2PSendBlockRespPack.head.Command:=cmdSendBlockResp;
            oP2PSendBlockRespPack.body.position:=recvInfo.position;
            oP2PSendBlockRespPack.body.ID:=recvInfo.ID;
            oP2PSendBlockRespPack.body.checkCRC:=False;
            oP2PSendBlockRespPack.body.TimeTick:=iP2PSendBlock.TimeTick;
            sendto(sock,oP2PSendBlockRespPack,sizeof(oP2PSendBlockRespPack),
                  0,@addrP2P,sizeof(addrP2P));
            Memo1.Lines.Add('CRC32 error'+ IntToStr(iP2PSendBlock.ID));
          end;
          Gauge1.Progress:=Round(recvInfo.ID/recvInfo.BlockCount*100);
        end;


        cmdSendBlockResp://接收反馈，发下一个块
        begin
          move(buffer[sizeof(head)],iP2PSendBlockResp,sizeof(iP2PSendBlockResp));
          KillTimer(Handle,1);
          {if sendInfo.ID=sendInfo.BlockCount-1 then
          begin
            FreeAndNil(readfs);
            Memo1.Lines.Add('【文件 '+sendInfo.FileName +' 发送完毕】，用时'
              +IntToStr(Round((GetTickCount-sendInfo.startTick)/1000))+'秒，平均速度'
              +IntToStr(Round(sendInfo.BlockCount/(GetTickCount-sendInfo.startTick)*1000))
              +' KB/s'+#13);
            btnSendFile.Enabled:=True;
            sendInfo.IsWorking:=False;
            Label5.Caption:='';
            Exit;
          end;}

          if (iP2PSendBlockResp.checkCRC) and
            (GetTickCount-iP2PSendBlockResp.TimeTick<1000)  then//CRC检查无误 和时间戳无误
          begin
            sendInfo.ID:=iP2PSendBlockResp.ID+1;
            sendInfo.position:=iP2PSendBlockResp.position+BlockSize;
          end else
          begin//CRC检查有误或时间戳超时，重发
            sendInfo.ID:=iP2PSendBlockResp.ID;
            sendInfo.position:=iP2PSendBlockResp.position;
            if MainForm.CheckBox1.State=cbUnchecked then
              Memo1.Lines.Add('超时或错误包 '+IntToStr(sendInfo.ID));
          end;

          if sendInfo.ID=sendInfo.BlockCount-1 then//最后一个包
            sendInfo.size:=sendInfo.FileSize mod BlockSize
          else
            sendInfo.size:=BlockSize;

          if sendInfo.ID=sendInfo.BlockCount then
          begin
            FreeAndNil(readfs);
            Memo1.Lines.Add('文件【'+sendInfo.FileName +'】发送完毕，用时'
              +IntToStr(Round((GetTickCount-sendInfo.startTick)/1000))+'秒，平均速度'
              +IntToStr(Round(sendInfo.BlockCount/(GetTickCount-sendInfo.startTick)*1000))
              +' KB/s'+#13);
            btnSendFile.Enabled:=True;
            sendInfo.IsWorking:=False;
            Label5.Caption:='';
          end
          else
            SendBlock(sendInfo);

          Gauge1.Progress:=Round(sendInfo.position/sendInfo.FileSize*100);
        end;


        cmdCancelTransfer://取消传输文件
        begin
          if sendInfo.IsWorking then FreeAndNil(readfs);
          if recvInfo.IsWorking then FreeAndNil(writefs);
          Memo1.Lines.Add('【对方取消了传输】'+#13);
          sendInfo.IsWorking:=False;
          recvInfo.IsWorking:=False;
          Label5.Caption:='';
        end;

      end;

    end;
  end;
end;



procedure TMainForm.ListBox1Click(Sender: TObject);
var
  pack: TP2PUserInfoPack;
begin
  if ListBox1.ItemIndex<0 then Exit;
  pack.head.Command:=cmdUserInfo;
  StrPCopy(pack.body.name1,EdtName.Text);//自己
  StrPCopy(pack.body.name2,ListBox1.Items[ListBox1.ItemIndex]);//对方
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.TimerMakeHoleTimer(Sender: TObject);
var
  pack: TP2PHolePack;
begin
  pack.head.Command:=cmdHole;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
  if recvInfo.IsWorking then
    Label5.Caption:=IntToStr(recvInfo.ID-recvInfo.progress)+'KB/s';
  if sendInfo.IsWorking then
    Label5.Caption:=IntToStr(sendInfo.ID-sendInfo.progress)+'KB/s';
  recvInfo.progress:=recvInfo.ID;
  sendInfo.progress:=sendInfo.ID;
end;

procedure TMainForm.btnSendClick(Sender: TObject);
var
  pack: TP2PMessagePack;
begin
  if EdtMessage.Text = '' then Exit;

  pack.head.Command:=cmdMessage;
  StrPCopy(pack.body.name,EdtName.Text);
  StrPCopy(pack.body.Text,EdtMessage.Text);
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));

  Memo1.Lines.Add(EdtName.Text + ' : '+EdtMessage.Text+#13);
  EdtMessage.Clear;
end;
procedure TMainForm.EdtMessageKeyPress(Sender: TObject; var Key: Char);
begin
   if Integer(key)=13 then btnSendClick(self);
end;


procedure TMainForm.btnBrowseClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    EdtFile.Text:=OpenDialog1.FileName;
end;

procedure TMainForm.btnSendFileClick(Sender: TObject);
var
  stream: TFileStream;
  pack: TP2PInquireAcceptFilePack;
begin
  if FileExists(EdtFile.Text) then
  begin
    stream:=TFileStream.Create(EdtFile.Text,fmOpenRead);
    sendInfo.FileName:=EdtFile.Text;
    sendInfo.FileSize:=stream.Size;
    sendInfo.BlockCount:=GetBlockCount(sendInfo.FileSize);//文件分为多少块
    stream.Free;
    pack.head.Command:=cmdInquireAcceptFile;
    StrPCopy(pack.body.name,EdtName.Text);
    StrPCopy(pack.body.FileName,ExtractFileName(EdtFile.Text));
    pack.body.FileSize:=sendInfo.FileSize;
    sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));

  end else
    ShowMessage('请确认要发送的文件')
end;



procedure TMainForm.SendBlock(var s: TSendFileInfo);
var
  pack: TP2PSendBlockPack;
begin
  if sendInfo.IsWorking=False then
  begin
    KillTimer(Handle,1);
    Exit;
  end;
  pack.head.Command:=cmdSendBlock;
  pack.body.position:=s.position;
  pack.body.ID:=s.ID;
  pack.body.size:=s.size;
  readfs.Seek(s.position,soBeginning);
  readfs.Read(pack.body.Data,pack.body.size);
  GetCrc32Byte(pack.body.Data,pack.body.size,pack.body.CRC32);
  sendInfo.LastTickCount:=GetTickCount;
  pack.body.TimeTick:=sendInfo.LastTickCount;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
  SetTimer(Handle,1,100,@OnCheckBlockRespPack);
end;

procedure TMainForm.btnClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TMainForm.btnRefreshClick(Sender: TObject);
var
  pack: TP2PUserListPack;
begin
  pack.head.Command:=cmdUserList;
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.TimerKeepOnlineTimer(Sender: TObject);
var
  pack: TP2POnlinePack;
begin
  pack.head.Command:=cmdOnline;
  StrPCopy(pack.body.name,EdtName.Text);
  sendto(sock,pack,sizeof(pack),0,@addrSrv,sizeof(addrSrv));
end;

procedure TMainForm.AcceptRecvFile(b: Boolean);
var
  pack: TP2PInquireAcceptFileRespPack;
begin
  pack.head.Command:=cmdInquireAcceptFileResp;
  StrPCopy(pack.body.name,EdtName.Text);
  pack.body.Resp:=b;
  sendto(sock,pack,sizeof(pack),0,@addrP2P,sizeof(addrP2P));
end;

end.
