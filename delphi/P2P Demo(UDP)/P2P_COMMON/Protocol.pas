unit Protocol;

interface

uses
  Winsock2, Windows;

const
  SERVER_PORT = 5432;//Server端口
  
  BlockSize   = 1024;//文件块大小
type

  PClientInfo = ^TClientInfo;//用户信息
  TClientInfo = packed record
    name: array [0..20] of char;
    ip: u_long;
    port: Integer;
    ticktime: Integer;
  end;

  {用于数据包头的Command字段}
  TP2PCMD=(cmdLogin,cmdLoginResp,cmdLogout,cmdOnline,
      cmdUserList,cmdUserListResp,
      cmdUserInfo,cmdUserInfoResp,
      cmdMakeHole,cmdHole,
      cmdMessage,
      cmdInquireAcceptFile,cmdInquireAcceptFileResp,
      cmdSendBlock,cmdSendBlockResp,
      cmdCancelTransfer);

  TP2PHead = packed record//所有数据的包头
    Command: TP2PCMD;
    Len: Integer;//保留，仅用Command就可以区分数据包了。
  end;

  //==============================================================
  TP2PLogin = packed record//登录(c2s)
    name: array [0..20] of char;
  end;
  TP2PLoginPack = packed record
    head: TP2PHead;
    body: TP2PLogin;
  end;

  TP2PLoginResp = packed record//登录回复(s2c)
    res: Boolean;
  end;
  TP2PLoginRespPack = packed record
    head: TP2PHead;
    body: TP2PLoginResp;
  end;

  TP2PLogout = packed record//登出(c2s)
    name: array [0..20] of char;
  end;
  TP2PLogoutPack = packed record
    head: TP2PHead;
    body: TP2PLogout;
  end;


  TP2POnline = packed record//维持在线
    name: array [0..20] of char;
  end;
  TP2POnlinePack = packed record
    head: TP2PHead;
    body: TP2POnline;
  end;


  TP2PUserInfo = packed record//PeerA提出获得PeerB信息的请求(c2s)
    name1: array [0..20] of char;//对方
    name2: array [0..20] of char;//请求方
  end;
  TP2PUserInfoPack = packed record
    head: TP2PHead;
    body: TP2PUserInfo;
  end;


  TP2PUserInfoResp = packed record//server返回用户信息(s2c)
    name: array [0..20] of char;
    ip: u_long;
    port: Integer;
  end;
  TP2PUserInfoRespPack = packed record
    head: TP2PHead;
    body: TP2PUserInfoResp;
  end;


  TP2PUserList = packed record//获得在线用户列表(c2s)
  end;
  TP2PUserListPack = packed record
    head: TP2PHead;
    body: TP2PUserList;
  end;


  TP2PUserListResp = packed record//返回用户列表，用户名用'|'分割(s2c)
    users: array [0..1000] of char;
  end;
  TP2PUserListRespPack = packed record
    head: TP2PHead;
    body: TP2PUserListResp;
  end;


  TP2PMakeHole = packed record//Server指挥PeerB打洞(s2c)
    name: array [0..20] of char;//PeerA的信息
    ip: u_long;
    port: Integer;
  end;
  TP2PMakeHolePack = packed record
    head: TP2PHead;
    body: TP2PMakeHole;
  end;



  {下面的都是P2P之间的数据包结构，与服务器无关}
  TP2PHole = packed record//P2P之间的打洞信息
  end;
  TP2PHolePack = packed record
    head: TP2PHead;
    body: TP2PHole;
  end;


  TP2PMessage = packed record//P2P之间的文本聊天数据包
    name: array [0..20] of char;//发起人
    Text: array [0..1000] of char;
  end;
  TP2PMessagePack = packed record
    head: TP2PHead;
    body: TP2PMessage;
  end;


  TP2PInquireAcceptFile = packed record//P2P之间传文件的询问信息
    name: array [0..20] of char;//发起人
    FileName: array [0..255] of char;
    FileSize: Integer;
  end;
  TP2PInquireAcceptFilePack = packed record
    head: TP2PHead;
    body: TP2PInquireAcceptFile;
  end;


  TP2PInquireAcceptFileResp = packed record//P2P之间传文件，应答是否接收
    name: array [0..20] of char;
    Resp: Boolean;
  end;
  TP2PInquireAcceptFileRespPack = packed record
    head: TP2PHead;
    body: TP2PInquireAcceptFileResp;
  end;


  TP2PSendBlock = packed record//P2P发送文件块
    position: Integer;//当前位置
    ID: Integer;//数据包（块）标识
    size: Integer;//本包发送的字节数
    Data: array [0..BlockSize-1] of byte;//内容
    CRC32: DWORD;//CRC32冗余码
    TimeTick: Integer;//时间戳
  end;
  TP2PSendBlockPack = packed record
    head: TP2PHead;
    body: TP2PSendBlock;
  end;


  TP2PSendBlockResp = packed record//P2P发送文件，接收回复
    position: Integer;
    ID: integer;
    checkCRC: Boolean;
    TimeTick: Integer;//返回时间戳
  end;
  TP2PSendBlockRespPack = packed record
    head: TP2PHead;
    body: TP2PSendBlockResp
  end;


  TP2PCancelTransfer = packed record
  end;
  TP2PCancelTransferPack = packed record
    head: TP2PHead;
    body: TP2PCancelTransfer
  end;
implementation

end.
