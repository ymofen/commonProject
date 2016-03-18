unit ntrip_tools;

interface

uses
  diocp.core.rawWinSocket, utils.strings, SysUtils, Classes;

const
  DOUBLE_LINEBREAK_BYTES : array[0..3] of Byte = (13,10,13,10);

function GetSourceTable(pvHost: string; pvPort: Integer): String;

procedure ReloadSourceTable;

var
  __sourceTable:AnsiString;
  __sourceTableHtml:AnsiString;

const
  ICY_200_OK:AnsiString = 'ICY 200 OK'#13#10#13#10;

implementation



procedure ReloadSourceTable;
var
  lvLoader:TStringList;
  lvData:AnsiString;
begin
  lvLoader := TStringList.Create();
  try
    lvLoader.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'sourceTable.txt');
    lvData := trim(lvLoader.Text);

    __sourceTable := 'SOURCETABLE 200 OK' + sLineBreak +
            'Content-Type: text/plain' + sLineBreak +
            'Content-Length: ' + IntToStr(length(lvData)) + sLineBreak + sLineBreak +
            lvData + sLineBreak +
           'ENDSOURCETABLE' + sLineBreak + sLineBreak;

    __sourceTableHtml := StringReplace(__sourceTable, sLineBreak, sLineBreak+'<br>', [rfReplaceAll]);

  finally
    lvLoader.Free;
  end;

end;

function GetSourceTable(pvHost: string; pvPort: Integer): String;
var
  lvRawSocket:TRawSocket;
  lvRequestStr, lvHost:String;
  lvBytes:TBytes;
  lvBB:TDBufferBuilder;
  lvBuffer:PByte;
  l, l2:Integer;
begin
  lvRequestStr := 'GET / HTTP 1.1'#13#10#13#10;
  lvRawSocket := TRawSocket.Create;
  lvBB := TDBufferBuilder.Create;
  try
    lvHost := lvRawSocket.GetIpAddrByName(pvHost);
    lvRawSocket.CreateTcpSocket;
    lvRawSocket.Connect(lvHost, pvPort);
    lvBytes := StringToUtf8Bytes(lvRequestStr);
    lvRawSocket.SendBuf(lvBytes[0], Length(lvBytes));
    SetLength(lvBytes, 4096);
    FillChar(lvBytes[0], 4096, 0);

    l := 0;

    if not lvRawSocket.Readable(5000) then
    begin
      raise Exception.Create('等待读取数据超时！');
    end;


    
    lvBuffer := lvBB.GetLockBuffer(4096);
    try
      l := lvRawSocket.RecvBufEnd(PAnsiChar(lvBuffer), 4096, PAnsiChar(@DOUBLE_LINEBREAK_BYTES[0]), 4, 10000);
      if l = -1 then
      begin
        RaiseLastOSError;
      end else if l = -2 then               
      begin
        raise Exception.Create('等待读取数据超时！');
      end;
    finally
      if l > 0 then
        lvBB.ReleaseLockBuffer(l);
    end;

    lvBuffer := lvBB.GetLockBuffer(4096);
    try
      l := lvRawSocket.RecvBufEnd(PAnsiChar(lvBuffer), 4096, PAnsiChar(@DOUBLE_LINEBREAK_BYTES[0]), 4, 10000);
      if l = -1 then
      begin
        RaiseLastOSError;
      end else if l = -2 then               
      begin
        raise Exception.Create('等待读取数据超时！');
      end;
    finally
      if l > 0 then
        lvBB.ReleaseLockBuffer(l);
    end;
    
    lvBytes := lvBB.ToBytes;
    Result := StrPas(@lvBytes[0]);
  finally
    lvRawSocket.Free;
    lvBB.Free;
  end;
end;

end.
