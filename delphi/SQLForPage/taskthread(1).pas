//
//---------------------------------------------------------------
//
//    WXD Butterfly Middleware Node Service
//
//    Version 1.45
//    Update Date: 2016.1.
//    Author: HuangZhiFEng
//
//    Copyright(C) WanXinDa Software Studio. All rights reserved
//
//---------------------------------------------------------------
//
unit taskthread;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  windows, Messages, SysUtils, Classes, Controls, forms, ActiveX,
  {$IFDEF UNICODE}
  AnsiStrings, Math,
  {$ENDIF}
  {$IFDEF VER130}
  DbClient,
  {$ELSE}
  Variants, DbClient,MidasLib,
  {$ENDIF}
  db, ButterflySocket, wxdPacket, wxdCommon, ButterflyUDP, QuickUDP, wxdMisc,
  wxdLzo, wxdZlibExGz, DllSpread, Provider, ShellAPI,
  ServerCommon, CallbackProcs, wxdMD5, wxdSHA1,
  wxdWinMessages, TriggerThread, Uni, CRAccess, DBAccess, MemData;

type
   TProcFunction=function(InPacketPtr: integer; var OutPacketPtr: integer): boolean; stdcall;
   TTaskRecord=record
      MessageId: AnsiString;
      TaskType: integer;            
      SqlCommand: AnsiString;
      FromUserId: AnsiString;
      ToUserId: AnsiString;
      MsgBody: TMemoryStream;
      MsgType: integer;
   end;
   TTaskThread=class(TThread)
   private
      Socket: TwxdCustomWinSocket;
      FromIpAddr: AnsiString;
      RequestLength: integer;   
      RequestBody: AnsiString; 
      RestBody: AnsiString;
      RequestPacket: TwxdPacket;
      BackPacket: TwxdPacket;
      ResponseBody: AnsiString;
      UDP: TButterflyUDP;
      UserSessionId: int64;
      RequestUserId: AnsiString;
      RequestNodeId: AnsiString;
      SelfUserId: AnsiString;
      ErrorCode: AnsiString;
      ErrorText: AnsiString;
      n_tablename: string;
      KeyFieldCount: integer;
      KeyFields: array of String;
      ThreadIndex: integer;
      tmpPlugin: TPluginRecord;
      tmpResult: boolean;
      OldPluginId: AnsiString;
      l_result: boolean;
      l_DllFileName: string;
      l_dllIndex: integer;
      x_ReloadUrl: ansistring;
      x_ReloadResult: boolean;

  protected
    function SetIsoLevel(const uniConn: TUniConnection; const Level: integer): boolean;
    function CompressStream(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
    function DecompressStream(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
    {$IF CompilerVersion>=25.0}
    function CompressStreamFD(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
    function DecompressStreamFD(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
    {$ENDIF}
    function CdsZipToStream(const aCds: TClientDataset; const aStream: TMemoryStream; var error: string): boolean;
    function DatasetSize(const uniQuery: TUniQuery; var err: string): integer; overload;
    function DatasetSize(const uniProc :TUniStoredProc; var err: string): Integer; overload;
    function DatasetZipToCdsStream(const uniQuery: TUniQuery; const Stream: TMemoryStream;
       const IsUnicode: boolean; var Error: string): boolean; overload;
    function DatasetZipToCdsStream(const uniProc:TUniStoredProc; const Stream: TMemoryStream;
       const IsUnicode: boolean; var Error: string): boolean; overload;
    function DatasetZipToCdsStream2(const uniProc:TUniStoredProc; const Stream: TMemoryStream;
       const IsUnicode: boolean; var Error: string): boolean; overload;
    function DatasetZipToStream(const uniQuery: TUniQuery; const Stream: TMemoryStream; var Error: string): boolean; overload;
    function DatasetZipToStream(const uniProc: TUniStoredProc; const Stream: TMemoryStream; var Error: string): boolean; overload;
    function GetCdsFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const aCds: TClientDataset): boolean;
//    function GetAdoDsFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const AdoDs: TUniQuery): boolean;
    function GetPacketFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const aSonPacket: TwxdPacket): boolean;
    function CdsWriteToUniQuery(const Cds: TClientDataset; const uniQuery: TuniQuery; var Error: string): boolean;
//    function AdoDsWriteToDataset(const AdoDs: TUniQuery; const AdoDataset: TUniQuery; var Error: string): boolean;
    function CdsRecordUpdateToUniQuery(const Cds: TClientDataset; const uniQuery: TUniQuery; var Error: string): boolean;
//    function AdoRecordUpdateToDataset(const AdoDs: TUniQuery; const AdoDataset: TUniQuery; var Error: string): boolean;
    function GetCdsFromUni(const uniQuery: TUniQuery; const aCds: TClientDataset; const IsUnicode: boolean; var Err:String): boolean; overload;
    function GetCdsFromUni(const uniProc: TUniStoredProc; const aCds: TClientDataset; const IsUnicode: boolean; var Err:String): boolean; overload;
    function ResolveKeyFields(const Cds: TClientDataset; const FieldList: String): boolean;
    function TwoQuotes(const SourceStr: string): string;
    function LocateRecord(const Cds: TClientDataset; const uniQuery: TUniQuery; const UpdateNull: boolean; const DataCds: TClientDataset; Var uniErr: ansistring): Boolean;
    function UpdateRecord(const Cds: TClientDataset; const uniQuery: TUniQuery; const UpdateNull: boolean; const MatchStrictly: boolean; var uniErr: AnsiString): Boolean;
    function InsertRecord(const Cds: TClientDataset; const uniQuery: TUniQuery; var uniErr: AnsiString): Boolean;
    function DeleteRecord(const Cds: TClientDataset; const uniSQL: TUniSQL; var uniErr: AnsiString): Boolean;
    procedure ReloadPreloadDll;
    procedure Execute; override;
    function ReceiveRequest: boolean;
    function ProcessTask: boolean;
    function FeedbackPacket(const aPacket: TwxdPacket): boolean;
    function SendToAllUser(const MsgPacket: TwxdPacket): boolean;
    function SaveUserMessage(const TargetUserId: AnsiString; const MsgPacket: TwxdPacket; var MsgId: AnsiString): boolean;
    function ExecuteExternalProgram(const aPrgFilename: String; const aParameters: String; const aReturnMode: integer; var ReturnValue: AnsiString): boolean;
    function TestDatabase(const aDatabaseId: AnsiString; var Error: string): boolean;
//    function TestExtDatabase(const aProvider: string; const aConnStr: string; var Error: string): boolean;
    function TestExtDatabase(const aProvider: string; const aServer: string;
                             const aUserName:String; const aPassword:String; const aDatabase:String; var Error: string): boolean;
    function CreateFileOnDisk(const FileName: String; const Size: Int64): Boolean;
    procedure PreloadPlugin;
    function RpcProcess(const aPluginId: AnsiString; const aPluginPassword: AnsiString; const aDatabaseId: ansistring; const InPacket: TwxdPacket; var OutPacket: TwxdPacket): boolean;
    function TransSessionIsValid(const TransSessionId: int64): boolean;
    procedure SaveErrorResponse(const ErrCode: AnsiString; const ErrText: AnsiString);
    function IsSybase(const uniConn: TUniConnection): boolean;
    procedure PacketToParameters(const Packet: TwxdPacket; const uniSQL: TUniSQL); overload;
//    procedure PacketToParameters(const Packet: TwxdPacket; const AdoDataset: TUniQuery); overload;
    procedure PacketToParameters(const Packet: TwxdPacket; const uniSP: TUniStoredProc); overload;
    procedure PacketToParameters(const Packet: TwxdPacket; const uniQuery: TUniQuery); overload;
    procedure Task_GetUserList;
    procedure Task_AddUser;
    procedure Task_UpdateUser;
    procedure Task_RemoveUser;
    procedure Task_U2UTransfer;
    procedure Task_BroadTransfer;
    procedure Task_GetBackupMsgList;
    procedure Task_GetMsgBody;
    procedure Task_DropMsg;
    procedure Task_FetchNodeList;
    procedure Task_AddNode;
    procedure Task_UpdateNode;
    procedure Task_RemoveNode;
    procedure Task_GetOnlineNodeList;
    procedure Task_FetchGroupList;
    procedure Task_AddGroup;
    procedure Task_UpdateGroup;
    procedure Task_RemoveGroup;
    procedure Task_FetchGroupMemberList;
    procedure Task_JoinToGroup;
    procedure Task_QuitFromGroup;
    procedure Task_PostGroupMsg;
    procedure Task_GetFileSize;
    procedure Task_CreateFile;
    procedure Task_ReadFileBlock;
    procedure Task_WriteFileBlock;
    procedure Task_FetchScheduleList;
    procedure Task_AddSchedule;
    procedure Task_UpdateSchedule;
    procedure Task_RemoveSchedule;
    procedure Task_RunSchedule;
    procedure Task_RunExternalProgram;
    procedure Task_FetchDatabaseList;
    procedure Task_AddDatabase;
    procedure Task_UpdateDatabase;
    procedure Task_RemoveDatabase;
    procedure Task_TestDatabase;
    procedure Task_TestExternalDatabase;
    procedure Task_FetchPluginList;
    procedure AddPlugin;
    procedure Task_AddPlugin;
    procedure UpdatePlugin;
    procedure Task_UpdatePlugin;
    procedure Task_RemovePlugin;
    procedure Task_BinaryRPC;
    procedure Task_BinaryRPCAnsyc;
//    procedure Task_CreatePageQuery;
//    procedure Task_QueryPageData;
//    procedure Task_TerminatePageQuery;
    procedure Task_SystemReport;
    // Modified by Administrator 2014-03-31 17:24:54
    // 添加存储过程分页查询函数，调用 PaginationQuery 存储过程
    Procedure Task_GetQueryPageData;
    // Modified by Administrator 2014-04-04 21:03:59
    // 添加存储过程分而查询函数，调用 PageQuery 存储过程
    Procedure Task_GetPageQuery;
    // Modified by Administrator 2014-04-09 11:31:10
    // 添加 GetUniqueID，获取指定表唯一字段值
    procedure Task_GetUniqueID;
    procedure uniDataAfterOpen(DataSet: TDataSet); overload;
    //=====================================================
    procedure Task_HelloNode;
    procedure Task_ChangeUserPassword;
    procedure Task_GetUserProperty;
    procedure Task_GetNodeProperty;
    procedure Task_GetPluginProperty;
    procedure Task_GetScheduleProperty;
    procedure Task_GetUserGroupProperty;
    procedure Task_GetDatabaseProperty;
    procedure Task_GetWebStatus;
    procedure Task_SetWebService;
    procedure Task_FetchWebSessions;
    procedure Task_RemoveWebSession;
    procedure Task_SetWebSocket;
    procedure Task_FetchWSSessions;
    procedure Task_RemoveWsSession;
    procedure Task_SendToWsUser;
    procedure Task_SendToBatchWsUsers;
    procedure Task_SendToWsChannel;
    procedure Task_ReadTmpFile;
    procedure Task_GroupHeartbeat;
    procedure Task_QueryHeartbeat;
    procedure Task_MountPlugin;
    procedure Task_DismountPlugin;
    procedure Task_GetTmpFileName;
    procedure Task_FetchBlackList;
    procedure Task_AddBlack;
    procedure Task_RemoveBlack;
    procedure Task_BindIntProp;
    procedure Task_BindStrProp;
    procedure Task_BindRoleId;
    procedure Task_SendToConnection;
    procedure Task_SendToIntPropConnections;
    procedure Task_SendToStrPropConnections;
    procedure Task_SendToRoleIdConnections;
    procedure Task_FetchIntPropConnections;
    procedure Task_FetchStrPropConnections;
    procedure Task_FetchRoleIdConnections;
    procedure Task_FetchAllConnections;
    procedure Task_ClearIntProp;
    procedure Task_ClearStrProp;
    procedure Task_ClearRoleId;
    procedure Task_GetIntPropCount;
    procedure Task_GetStrPropCount;
    procedure Task_GetRoleIdCount;
    procedure Task_ReadSysParameters;
    procedure Task_GenerateKeyId;
    procedure Task_FreeKeyId;
    procedure Task_ReadDataset;                             //读取一个数据集
    procedure Task_ReadSimpleResult;
    procedure Task_BlobToFile;
    procedure Task_TableToFile;
    procedure Task_GetTableHead;
    procedure Task_BlobToStream;
    procedure Task_ReadMultiDataset;                       //一次读取多个数据集
    procedure Task_ValueExists;
    procedure Task_ExecSQL;
    function Item_ExecSQL(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_ExecCommand;
    function Item_ExecCommand(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_ExecBatchSQL;
    function Item_ExecBatchSQL(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_ExecStoreProc;
    function Item_ExecStoreProc(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_FileToBlob;
    function Item_FileToBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_FileToTable;
    function Item_FileToTable(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_WriteDataset;
    function Item_WriteDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_AppendRecord;
    function Item_AppendRecord(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_UpdateRecord;
    function Item_UpdateRecord(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_SaveDelta;
    function Item_SaveDelta(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_ClearBlob;
    function Item_ClearBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_StreamToBlob;
    procedure Task_GetBlobMd5;
    procedure Task_GetBlobSha1;
    function Item_StreamToBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_WriteMultiDataset;
    function Item_WriteMultiDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_UpdateDataset;
    function Item_UpdateDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_CommitSqlDelta;
    function Item_CommitSqlDelta(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
    procedure Task_CommitBatchTasks;
    procedure Task_SendToWebSession;
    procedure Task_SendToAllWebSessions;
    procedure Task_SendToStrPropWebSessions;
    procedure Task_SendToIntPropWebSessions;
    procedure Task_SendToRoleIdWebSessions;
    procedure Task_GetServiceVersion;
    procedure Task_GetServerDateTime;
    procedure Task_FetchTriggerList;
    procedure Task_RegisterTrigger;
    procedure Task_UnregisterTrigger;
    procedure Task_FireTrigger;
    procedure Task_FetchDeviceList;
    procedure Task_RegisterDevice;
    procedure Task_UnregisterDevice;
    procedure Task_VerificationDevice;
    procedure Task_TableExists;
    Procedure Task_PrepostData;
    procedure Task_ReloadPlugin;
    procedure Task_RefreshPreloadPlugins;

  public
    Constructor Create(aIndex: integer; SuspendedOnCreate: boolean); Overload;

end;

implementation

uses main, ServiceTypes, AppDmUnt;

const
   TransferBlockSize=32768;

function TTaskThread.SetIsoLevel(const uniConn: TUniConnection; const Level: integer): boolean;
var
  IsoLevel: TCRIsolationLevel;
begin
  case Level of
    0:IsoLevel := ilReadCommitted;           //暂时不可用
    1:IsoLevel := ilIsolated;         //从其他事务中获取事务的独立级别 (还理解不了这个是什么意思)
    2:IsoLevel := ilReadCommitted;    //读取数据时采用只读操作数据锁，写数据时采用独占锁，在读取完成后立即释放事务锁
    3:IsoLevel := ilReadUnCommitted;  //读数据与写数据时，不锁定任何数据
    4:IsoLevel := ilRepeatableRead;   //读取数据时只读操作数据锁，而在写数据时采用独占锁，并且到事务完全结束时才释放
    5:IsoLevel := ilSnapshot;         //隔离事务，不阻塞由其他事务执行的更新操作
  else
    IsoLevel:=ilReadCommitted;
  end;
  try
    uniConn.DefaultTransaction.IsolationLevel := IsoLevel;
    result:=true;
  except
    result:=false;
  end;
end;

function TTaskThread.CompressStream(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
begin
   try
      if (NodeService.s_CompressMode='LZO') then
         result:=LzoCompressToStream(SourceStream,TargetStream)
      else
         begin
            GZCompressStream(SourceStream,TargetStream);
            result:=true;
         end;
   except
      result:=false;
   end;
end;

function TTaskThread.DecompressStream(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
begin
   try
      if NodeService.s_CompressMode='LZO' then
         result:=LzoDecompressFromStream(SourceStream,TargetStream)
      else
         begin
            GZDecompressStream(SourceStream,TargetStream);
            result:=true;
         end;
   except
      result:=false;
   end;
end;

{$IF CompilerVersion>=25.0}
function TTaskThread.CompressStreamFD(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
begin
  try
    GZCompressStream(SourceStream,TargetStream);
    result:=true;
  except
    result:=false;
  end;
end;

function TTaskThread.DecompressStreamFD(const SourceStream: TMemoryStream; const TargetStream: TMemoryStream): boolean;
begin
  try
    GZDecompressStream(SourceStream,TargetStream);
    result:=true;
  except
    result:=false;
  end;
end;
{$ENDIF}
Constructor TTaskThread.Create(aIndex: integer; SuspendedOnCreate: boolean);
begin
   Inherited Create(SuspendedOnCreate);
   ThreadIndex:=aIndex;
   freeOnTerminate:=true;
end;

function TTaskThread.CdsZipToStream(const aCds: TClientDataset; const aStream: TMemoryStream; var error: string): boolean;
var
   tmpStream: TMemoryStream;
begin
   tmpStream:=nil;
   try
      tmpStream:=TMemoryStream.Create;
      aCds.SaveToStream(tmpStream);
      tmpStream.Position:=0;
      aStream.Clear;
      CompressStream(tmpStream,aStream);
      Result:=true;
   except
      on e:exception do
         begin
            error:='['+e.ClassName+']-'+e.Message;
            Result:=false;
         end;
   end;
   if assigned(tmpStream) then
      FreeAndNil(tmpStream);
end;

function TTaskThread.DatasetSize(const uniQuery: TUniQuery; var err: string): integer;
var
  i: integer;
begin
  try
    result:= uniQuery.RecordSize *(uniQuery.RecordCount+1);
    err:='';
  except
    on e:exception do
    begin
      result:=0;
      err:='Error on get dataset size: ['+e.ClassName+']-'+e.Message;
    end;
  end;
end;

function TTaskThread.DataSetSize(const UniProc :TUniStoredProc; var err: string): Integer;
var
  i: integer;
begin
  try
    result:= UniProc.RecordSize *(UniProc.RecordCount+1);
    err:='';
  except
    on e:exception do
    begin
      result:=0;
      err:='Error on get dataset size: ['+e.ClassName+']-'+e.Message;
    end;
  end;
end;

function TTaskThread.DatasetZipToCdsStream(const UniQuery: TUniQuery; const Stream: TMemoryStream;
   const IsUnicode: boolean; var Error: string): boolean;
var
  dp: TDatasetProvider;
  Cds: TClientDataset;
  i: integer;
begin
  Result := True;
  dp := TDataSetProvider.Create(nil);
  if result then
  begin
    Cds:=nil;
    try
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      Stream.Clear;
      if uniQuery.Active then  uniQuery.Close;
      dp.DataSet := uniQuery;
      Cds.Data := dp.Data;
      result:=(Cds.DataSize < 64*1024*1024);
      if Not result then
        error := ' 单页查询的数据大小'
                + FormatFloat('0.00',(cds.DataSize / 1024 / 1024))+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
    except
      if uniQuery.Active then  uniQuery.Close;
      uniQuery.Open;
      Result := GetCdsFromUni(uniQuery,Cds,IsUnicode, Error);        // 强制转换到Cds
    end;
    if result then
      result:=CdsZipToStream(Cds,Stream,Error);
    if Assigned(Cds) then
      FreeAndNil(Cds);
    if Assigned(dp) then
      FreeAndNil(dp);
  end;
end;

function TTaskThread.DatasetZipToCdsStream(const uniProc: TUniStoredProc; const Stream: TMemoryStream;
   const IsUnicode: boolean; var Error: string): boolean;
var
  dp:TDataSetProvider;
  Cds: TClientDataset;
  i: integer;
begin
  Result := True;
  if result then
  begin
    Cds:=nil;
    try
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      Stream.Clear;
      if uniProc.Active then uniProc.Close;
      dp.DataSet := uniProc;
      Cds.Data := dp.Data;
      result:=(Cds.DataSize < 64*1024*1024);
      if Not result then
        error := ' 单页查询的数据大小'
                + FormatFloat('0.00',(cds.DataSize / 1024 / 1024))+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
    except
      if uniProc.Active then uniProc.Close;
      uniProc.Open;
      Result := GetCdsFromUni(uniProc,Cds,IsUnicode, Error);        // 强制转换到Cds
    end;
    if result then
      result:=CdsZipToStream(Cds,Stream,Error);
    if Assigned(Cds) then
      FreeAndNil(Cds);
  end;
end;

function TTaskThread.DatasetZipToCdsStream2(const uniProc: TUniStoredProc; const Stream: TMemoryStream;
   const IsUnicode: boolean; var Error: string): boolean;
var
  dp: TDatasetProvider;
  Cds: TClientDataset;
  i: integer;
begin
//  i:=DatasetSize(uniProc,error);
//  result:=(i<512*1024*1024) and (i>0);
//  if (not result) and (error='') then
//    error:='Dataset too large to fetch.';
  Result := True;
  if result then
  begin
    dp:=nil;
    Cds:=nil;
    try
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      Stream.Clear;
      result:=GetCdsFromUni(uniProc,Cds,IsUnicode, Error);
      if not result then
      Begin
        dp:=TDatasetProvider.Create(nil);
        dp.DataSet:=uniProc;
        Cds.Data:=dp.Data;
        result:=true;
      end
      Else
        NodeService.syslog.Log('数据格式替换失败...');
    except
      on e:exception do
      begin
        error:='['+e.ClassName+']-'+e.Message;
        Result:=false;
      end;
    end;
    if result then
      result:=CdsZipToStream(Cds,Stream,Error);
    if Assigned(Cds) then
      FreeAndNil(Cds);
    if Assigned(dp) then
      FreeAndNil(dp);
  end;
end;

function TTaskThread.DatasetZipToStream(const uniQuery: TUniQuery; const Stream: TMemoryStream;
   var Error: string): boolean;
var
  tmpStream: TMemoryStream;
  j: integer;
begin
  tmpStream:=nil;
  j:=DatasetSize(uniQuery,Error);
  result:=(j<512*1024*1024) and (j>0);
  if (not result) and (error='') then
    error:='数据集太大了，请使用 ReadLargeDataset() 方法获取数据... ';
  if result then
  begin
    Stream.Clear;
    try
      tmpStream:=TMemoryStream.Create;
      result:=wxdCommon.RecordsetToStream(uniQuery,tmpStream,error);
      if result then
      begin
        tmpStream.Position:=0;
        CompressStream(tmpStream,Stream);
        Stream.Position:=0;
        Result:=true;
      end;
    except
      on e:exception do
      begin
        error:='['+e.ClassName+']-'+e.Message;
        Result:=false;
      end;
    end;
    if assigned(tmpStream) then
      FreeAndNil(tmpStream);
  end;
end;

function TTaskThread.DatasetZipToStream(const uniProc: TuniStoredProc; const Stream: TMemoryStream;
   var Error: string): boolean;
var
  tmpStream: TMemoryStream;
  j: integer;
begin
  tmpStream:=nil;
  j:=DatasetSize(uniProc,Error);
  result:=(j<512*1024*1024) and (j>0);
  if (not result) and (error='') then
    error:='您要查询的数据太大了，将影响整个系统的运作哦...';
  if result then
  begin
    Stream.Clear;
    try
      tmpStream:=TMemoryStream.Create;
      result:=wxdCommon.RecordsetToStream(uniProc,tmpStream,error);
      if result then
      begin
        tmpStream.Position:=0;
        CompressStream(tmpStream,Stream);
        Stream.Position:=0;
        Result:=true;
      end;
    except
      on e:exception do
      begin
        error:='['+e.ClassName+']-'+e.Message;
        Result:=false;
      end;
    end;
    if assigned(tmpStream) then
      FreeAndNil(tmpStream);
  end;
end;

function TTaskThread.GetCdsFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const aCds: TClientDataset): boolean;
var
   tmpStream: TMemoryStream;
   Stream: TMemoryStream;
begin
   tmpStream:=nil;
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      tmpStream:=TMemoryStream.Create;
      if aPacket.GetStreamGoods(aGoodsName,tmpStream) then
         begin
            if tmpStream.Size>0 then
               begin
                  tmpStream.Position:=0;
                  DecompressStream(tmpStream,Stream);
                  Stream.Position:=0;
                  aCds.Close;
                  aCds.LoadFromStream(Stream);
                  result:=aCds.active;
               end
            else
               result:=false;
         end
      else
         result:=false;
   except
      result:=false;
   end;
   if assigned(tmpStream) then
      FreeAndNil(tmpStream);
   if assigned(Stream) then
      FreeAndNil(Stream);
end;

//function TTaskThread.GetAdoDsFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const AdoDs: TUniQuery): boolean;
//var
//   tmpStream: TMemoryStream;
//   Stream: TMemoryStream;
//   rs: adodb._Recordset;
//begin
//   tmpStream:=nil;
//   Stream:=nil;
//   try
//      Stream:=TMemoryStream.Create;
//      tmpStream:=TMemoryStream.Create;
//      if aPacket.GetStreamGoods(aGoodsName,tmpStream) then
//         begin
//            if tmpStream.Size>0 then
//               begin
//                  tmpStream.Position:=0;
//                  DecompressStream(tmpStream,Stream);
//                  Stream.Position:=0;
//                  AdoDs.Close;
//                  Result:=wxdCommon.StreamToRecordset(Stream,rs);
//                  Adods.Recordset:=rs;
//               end
//            else
//               result:=false;
//         end
//      else
//         result:=false;
//   except
//      result:=false;
//   end;
//   if assigned(tmpStream) then
//      FreeAndNil(tmpStream);
//   if assigned(Stream) then
//      FreeAndNil(Stream);
//end;

function TTaskThread.GetPacketFromPacket(const aPacket: TwxdPacket; const aGoodsName: AnsiString; const aSonPacket: TwxdPacket): boolean;
var
   tmpStream: TMemoryStream;
   Stream: TMemoryStream;
begin
   tmpStream:=nil;
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      tmpStream:=TMemoryStream.Create;
      if aPacket.GetStreamGoods(aGoodsName,tmpStream) then
         begin
            if tmpStream.Size>0 then
               begin
                  tmpStream.Position:=0;
                  DecompressStream(tmpStream,Stream);
                  Stream.Position:=0;
                  result:=aSonPacket.LoadFromStream(Stream);
               end
            else
               result:=false;
         end
      else
         result:=false;
   except
      result:=false;
   end;
   if assigned(tmpStream) then
      FreeAndNil(tmpStream);
   if assigned(Stream) then
      FreeAndNil(Stream);
end;

function TTaskThread.CdsWriteToUniQuery(const Cds: TClientDataset; const uniQuery: TuniQuery; var Error: string): boolean;
var
  FieldName: string;
  Fld: TField;
  i: integer;
  Stream: TMemoryStream;
begin
  Error:='';
  Stream:=nil;
  result:=true;
  Cds.First;
  try
    Stream:=TMemoryStream.Create;
    while not Cds.Eof do
    begin
      uniQuery.append;
      for i:=0 to Cds.FieldCount-1 do
      begin
        FieldName:=Cds.Fields[i].FieldName;
        Fld:=uniQuery.Fields.FindField(FieldName);
        if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
           continue;
        if Cds.fields[i].IsBlob and (Cds.fields[i].datatype<>ftMemo)
           and (Cds.fields[i].datatype<>ftFmtMemo) and (Cds.fields[i].datatype<>ftWideMemo) then
        begin
          try
            TBlobField(Cds.fields[i]).savetostream(stream);
            if Stream.Size>0 then
            begin
              stream.Position:=0;
              TBlobField(Fld).loadfromstream(stream);
            end;
          except
            on e:exception do
            begin
              result:=false;
              error:='['+e.ClassName+']-'+e.Message;
            end;
          end;
          stream.Clear;
        end
        else
           Fld.Value:=Cds.fields[i].Value;
        if not result then
           break;
      end;
    if not result then
       break;
    uniQuery.Post;
    Cds.next;
    end;
  except
    on e:exception do
    begin
      result:=false;
      error:='['+e.ClassName+']-'+e.Message;
    end;
  end;
  if assigned(Stream) then
  FreeAndNil(Stream);
end;

function TTaskThread.CdsRecordUpdateToUniQuery(const Cds: TClientDataset; const uniQuery: TUniQuery; var Error: string): boolean;
var
  FieldName: string;
  Fld: TField;
  i: integer;
  Stream: TMemoryStream;
begin
  Error:='';
  Stream:=nil;
  try
    result:=true;
    if uniQuery.RecordCount=0 then
      uniQuery.Append
    else
      uniQuery.edit;
    for i:=0 to Cds.FieldCount-1 do
    begin
      FieldName:=Cds.Fields[i].FieldName;
      Fld:=uniQuery.Fields.FindField(FieldName);
      if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
         continue;
      if Cds.fields[i].IsBlob and (Cds.fields[i].datatype<>ftMemo)
         and (Cds.fields[i].datatype<>ftFmtMemo) and (Cds.fields[i].datatype<>ftWideMemo) then
      begin
        Stream:=TMemoryStream.Create;
        try
          TBlobField(Cds.fields[i]).savetostream(stream);
          if Stream.Size>0 then
          begin
             stream.Position:=0;
             TBlobField(Fld).loadfromstream(stream);
          end;
        except
          on e:exception do
          begin
            result:=false;
            error:='['+e.ClassName+']-'+e.Message;
          end;
        end;
        FreeAndNil(Stream);
      end
      else
         Fld.Value:=Cds.fields[i].Value;
      if not result then
         break;
    end;
    if result then
      uniQuery.Post;
  except
    on e:exception do
    begin
      result:=false;
      error:='['+e.ClassName+']-'+e.Message;
    end;
  end;
end;

//function TTaskThread.AdoDsWriteToDataset(const AdoDs: TUniQuery; const AdoDataset: TUniQuery; var Error: string): boolean;
//var
//   FieldName: string;
//   Fld: TField;
//   i: integer;
//   Stream: TMemoryStream;
//begin
//   error:='';
//   Stream:=nil;
//   try
//      Stream:=TMemoryStream.Create;
//      result:=true;
//      AdoDs.First;
//      while not AdoDs.Eof do
//         begin
//            AdoDataset.append;
//            for i:=0 to AdoDs.FieldCount-1 do
//               begin
//                  FieldName:=AdoDs.Fields[i].FieldName;
//                  Fld:=AdoDataset.Fields.FindField(FieldName);
//                  if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
//                     continue;
//                  if AdoDs.fields[i].IsBlob and (AdoDs.fields[i].datatype<>ftMemo)
//                     and (AdoDs.fields[i].datatype<>ftFmtMemo) and (AdoDs.fields[i].datatype<>ftWideMemo) then
//                     begin
//                        try
//                           TBlobField(AdoDs.fields[i]).savetostream(stream);
//                           if Stream.Size>0 then
//                              begin
//                                 stream.Position:=0;
//                                 TBlobField(Fld).loadfromstream(stream);
//                              end;
//                        except
//                           on e:exception do
//                              begin
//                                 result:=false;
//                                 error:='['+e.ClassName+']-'+e.Message;
//                              end;
//                        end;
//                        stream.Clear;
//                     end
//                  else
//                     Fld.Value:=AdoDs.fields[i].Value;
//                  if not result then
//                     break;
//               end;
//            if not result then
//               break;
//            AdoDataset.Post;
//            AdoDs.next;
//         end;
//   except
//      on e:exception do
//         begin
//            result:=false;
//            error:='['+e.ClassName+']-'+e.Message;
//         end;
//   end;
//   if assigned(Stream) then
//      FreeAndNil(Stream);
//end;

//function TTaskThread.AdoRecordUpdateToDataset(const AdoDs: TUniQuery; const AdoDataset: TUniQuery; var Error: string): boolean;
//var
//   FieldName: string;
//   Fld: TField;
//   i: integer;
//   Stream: TMemoryStream;
//begin
//   Error:='';
//   Stream:=nil;
//   try
//      result:=true;
//      if AdoDataset.RecordCount=0 then
//         AdoDataset.Append
//      else
//         AdoDataset.edit;
//      for i:=0 to AdoDs.FieldCount-1 do
//         begin
//            FieldName:=AdoDs.Fields[i].FieldName;
//            Fld:=AdoDataset.Fields.FindField(FieldName);
//            if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
//               continue;
//            if AdoDs.fields[i].IsBlob and (AdoDs.fields[i].datatype<>ftMemo)
//               and (AdoDs.fields[i].datatype<>ftFmtMemo) and (AdoDs.fields[i].datatype<>ftWideMemo) then
//               begin
//                  Stream:=TMemoryStream.Create;
//                  try
//                     TBlobField(AdoDs.fields[i]).savetostream(stream);
//                     if Stream.Size>0 then
//                        begin
//                           stream.Position:=0;
//                           TBlobField(Fld).loadfromstream(stream);
//                        end;
//                  except
//                     on e:exception do
//                        begin
//                           result:=false;
//                           error:='['+e.ClassName+']-'+e.Message;
//                        end;
//                  end;
//                  FreeAndNil(Stream);
//               end
//            else
//               Fld.Value:=AdoDs.fields[i].Value;
//            if not result then
//               break;
//         end;
//      if result then
//         AdoDataset.Post;
//   except
//      on e:exception do
//         begin
//            result:=false;
//            error:='['+e.ClassName+']-'+e.Message;
//         end;
//   end;
//end;

//function TTaskThread.GetCdsFromUni(const uniQuery: TUniQuery; const aCds: TClientDataset; const IsUnicode: boolean; var Err:String): boolean;
//var
//  i: integer;
//  Stream: TMemoryStream;
//  dp: TDatasetProvider;
//begin
//  dp := nil;
//  Stream:=nil;
//  aCds.Close;
//  try
//    Stream:=TMemoryStream.Create;
//    for i := 0 to uniQuery.Fields.Count - 1 do
//    begin
//      with aCds.FieldDefs.AddFieldDef do
//      begin
//        Name:=uniQuery.Fields[i].FieldName;
//        if uniQuery.Fields[i].DataType=ftAutoInc then
//          DataType:=ftInteger
//        else
//        begin
//          {$IFDEF UNICODE}
//          if IsUnicode then
//          begin
//            if uniQuery.Fields[i].DataType=ftString then
//              DataType:=ftWideString
//            else if uniQuery.Fields[i].DataType=ftFixedChar then
//              DataType:=ftFixedWideChar
//            else if uniQuery.Fields[i].DataType=ftMemo then
//              DataType:=ftWideMemo
//            else if uniQuery.Fields[i].DataType=ftGuid then
//              DataType:=ftString
//            Else
//              DataType:=uniQuery.Fields[i].DataType;
//          end
//          else
//          {$ENDIF}
//          Begin
//            if uniQuery.Fields[i].DataType=ftDate then
//              DataType:=ftDateTime
//            Else
//              DataType:=uniQuery.Fields[i].DataType;
//          end;
//        end;
//        if (DataType=ftString) or (DataType=ftWideString)
//          or (DataType=ftFixedChar) {$IFDEF UNICODE} or (DataType=ftFixedWideChar){$ENDIF} then
//          Size:=uniQuery.Fields[i].DataSize;
//      end;
//    end;
//    aCds.CreateDataSet;
//    uniQuery.First;
//    while not uniQuery.Eof do
//    begin
//      aCds.Append;
//      for i := 0 to uniQuery.Fields.Count - 1 do
//      begin
//        if uniQuery.Fields[i].IsNull then
//          continue;
//        if uniQuery.Fields[i].IsBlob and (uniQuery.Fields[i].DataType<>ftMemo)
//           and (uniQuery.Fields[i].DataType<>ftFmtMemo) and (uniQuery.Fields[i].DataType<>ftWideMemo) then
//          begin
//             Stream.Clear;
//             try
//                TBlobField(uniQuery.Fields[i]).SaveToStream(Stream);
//             except
//                Stream.Clear;
//             end;
//             if Stream.Size>0 then
//                begin
//                   Stream.Position:=0;
//                   TBlobField(aCds.Fields[i]).LoadFromStream(Stream);
//                end;
//          end
//        else
//          aCds.Fields[i].Value:=uniQuery.Fields[i].Value;
//      end;
//      aCds.Post;
//      uniQuery.Next;
//    end;
//    aCDs.MergeChangeLog;
//    result:=true;
//  except
//    try
//      dp:=TDatasetProvider.Create(nil);
//      dp.DataSet:=UniQuery;
//      aCds.Data:=dp.Data;
//      result:=(aCds.DataSize < 64*1024*1024);
//      if Not result then
//        Err := ' 单页查询的数据大小'
//                + FormatFloat('0.00',(aCds.DataSize / 1024 / 1024))+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
//    except
//      Result:=false;
//    end;
//  end;
//  if assigned(Stream) then
//    FreeAndNil(Stream);
//  if Assigned(dp) then
//    FreeAndNil(dp);
//end;

function TTaskThread.GetCdsFromUni(const uniQuery: TUniQuery; const aCds: TClientDataset; const IsUnicode: boolean; var Err:String): boolean;
var
  i: integer;
  Stream: TMemoryStream;
begin
  Stream:=nil;
  aCds.Close;
  try
    Stream:=TMemoryStream.Create;
    for i := 0 to uniQuery.Fields.Count - 1 do
    begin
      with aCds.FieldDefs.AddFieldDef do
      begin
        Name:=uniQuery.Fields[i].FieldName;
        if uniQuery.Fields[i].DataType=ftAutoInc then
          DataType:=ftInteger
        else
        begin
          {$IFDEF UNICODE}
          if IsUnicode then
          begin
            if uniQuery.Fields[i].DataType=ftString then
              DataType:=ftWideString
            else if uniQuery.Fields[i].DataType=ftFixedChar then
              DataType:=ftFixedWideChar
            else if uniQuery.Fields[i].DataType=ftMemo then
              DataType:=ftWideMemo
            else if uniQuery.Fields[i].DataType=ftGuid then
              DataType:=ftString
            Else
              DataType:=uniQuery.Fields[i].DataType;
          end
          else
          {$ENDIF}
          Begin
            if uniQuery.Fields[i].DataType=ftDate then
              DataType:=ftDateTime
            Else
              DataType:=uniQuery.Fields[i].DataType;
          end;
        end;
        if (DataType=ftString) or (DataType=ftWideString)
          or (DataType=ftFixedChar) {$IFDEF UNICODE} or (DataType=ftFixedWideChar){$ENDIF} then
          Size:=uniQuery.Fields[i].DataSize;
      end;
    end;
    aCds.CreateDataSet;
    uniQuery.First;
    while not uniQuery.Eof do
    begin
      aCds.Append;
      for i := 0 to uniQuery.Fields.Count - 1 do
      begin
        if uniQuery.Fields[i].IsNull then
          continue;
        if uniQuery.Fields[i].IsBlob and (uniQuery.Fields[i].DataType<>ftMemo)
           and (uniQuery.Fields[i].DataType<>ftFmtMemo) and (uniQuery.Fields[i].DataType<>ftWideMemo) then
          begin
             Stream.Clear;
             try
                TBlobField(uniQuery.Fields[i]).SaveToStream(Stream);
             except
                Stream.Clear;
             end;
             if Stream.Size>0 then
                begin
                   Stream.Position:=0;
                   TBlobField(aCds.Fields[i]).LoadFromStream(Stream);
                end;
          end
        else
          aCds.Fields[i].Value:=uniQuery.Fields[i].Value;
      end;
      aCds.Post;
      uniQuery.Next;
    end;
    aCDs.MergeChangeLog;
    result:=true;
  except
    on e:exception do
    begin
      Err:='['+e.ClassName+']-'+e.Message;
      Result:=false;
    end;
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

function TTaskThread.GetCdsFromUni(const uniProc: TUniStoredProc; const aCds: TClientDataset; const IsUnicode: boolean; var Err:String): boolean;
var
  i: integer;
  Stream: TMemoryStream;
begin
  Stream:=nil;
  aCds.Close;
  try
    Stream:=TMemoryStream.Create;
    for i := 0 to uniProc.Fields.Count - 1 do
    begin
      with aCds.FieldDefs.AddFieldDef do
      begin
        Name:=uniProc.Fields[i].FieldName;
        if uniProc.Fields[i].DataType=ftAutoInc then
          DataType:=ftInteger
        else
        begin
          {$IFDEF UNICODE}
          if IsUnicode then
          begin
            if uniProc.Fields[i].DataType=ftString then
              DataType:=ftWideString
            else if uniProc.Fields[i].DataType=ftFixedChar then
              DataType:=ftFixedWideChar
            else if uniProc.Fields[i].DataType=ftMemo then
              DataType:=ftWideMemo
            else if uniProc.Fields[i].DataType=ftGuid then
              DataType:=ftString
            Else 
              DataType:=uniProc.Fields[i].DataType;
          end
          else
          {$ENDIF}
          Begin
            if uniProc.Fields[i].DataType=ftDate then
              DataType:=ftDateTime
            Else
              DataType:=uniProc.Fields[i].DataType;
          end;
        end;
        if (DataType=ftString) or (DataType=ftWideString)
          or (DataType=ftFixedChar) {$IFDEF UNICODE} or (DataType=ftFixedWideChar){$ENDIF} then
          Size:=uniProc.Fields[i].DataSize;
      end;
    end;
    aCds.CreateDataSet;
    uniProc.First;
    while not uniProc.Eof do
    begin
      aCds.Append;
      for i := 0 to uniProc.Fields.Count - 1 do
      begin
        if uniProc.Fields[i].IsNull then
          continue;
        if uniProc.Fields[i].IsBlob and (uniProc.Fields[i].DataType<>ftMemo)
           and (uniProc.Fields[i].DataType<>ftFmtMemo) and (uniProc.Fields[i].DataType<>ftWideMemo) then
          begin
             Stream.Clear;
             try
                TBlobField(uniProc.Fields[i]).SaveToStream(Stream);
             except
                Stream.Clear;
             end;
             if Stream.Size>0 then
                begin
                   Stream.Position:=0;
                   TBlobField(aCds.Fields[i]).LoadFromStream(Stream);
                end;
          end
        else
          aCds.Fields[i].Value:=uniProc.Fields[i].Value;
      end;
      aCds.Post;
      uniProc.Next;
    end;
    aCds.MergeChangeLog;
    result:=true;
  except
    on e:exception do
    begin
      Err:='['+e.ClassName+']-'+e.Message;
      Result:=false;
    end;
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

procedure TTaskThread.ReloadPreloadDll;
begin
   x_ReloadResult:=NodeService.ReloadPreloadPlugin(x_ReloadUrl)
end;

procedure TTaskThread.Execute;
var
   ok: boolean;
begin
   CoInitialize(nil);
   while not terminated do
      begin
         try
            Socket:=NodeService.PopTask;
            if socket<>nil then
               FromIpAddr:=Socket.RemoteAddress;
         except
            Socket:=nil;
            continue;
         end;
         if Socket=nil then
            begin
               NodeService.TaskThreads[ThreadIndex].LastActiveTime:=now;
               synchronize(self.Suspend);
               continue;
            end;
         RequestPacket:=TwxdPacket.Create;
         RequestPacket.EncryptKey:=NodeService.s_TransferKey;
         RestBody:='';
         while not terminated do
            begin
               if not ReceiveRequest then
                  begin
                     try
                        NodeService.TaskSocket.Socket.CloseAConnection(socket);
                     except
                     end;
                     break;
                  end;
               if RestBody='' then
                  try
                     socket.ReadStarted:=false;
                  except
                  end;
               try
                  RequestPacket.Clear;
                  RequestPacket.LoadFromString(RequestBody);
                  ok:=(RequestPacket.GoodsCount>0);
               except
                  ok:=false;
               end;
               if not ok then
                  begin
                     if RestBody='' then
                        break;
                     sleep(1);
                     continue;
                  end;
               BackPacket:=TwxdPacket.Create;
               ProcessTask;
               if BackPacket.GoodsCount>0 then
                  feedbackPacket(BackPacket);
               FreeAndNil(BackPacket);
               if RestBody='' then
                  break;
               sleep(1);
            end;
         FreeAndNil(RequestPacket);
      end;
   CoUninitialize;
end;

function TTaskThread.ReceiveRequest: boolean;
var
   tmpstr: AnsiString;
   t0: TDateTime;
   j,k,bytes: integer;
begin
   RequestLength:=-1;
   RequestBody:=RestBody;
   RestBody:='';
   t0:=now;
   result:=false;
   while (not terminated) and (round((now-t0)*24*60*60)<NodeService.s_RequestTimeout) do
      begin
         try
            if not socket.Connected then
               j:=-2
            else
               j:=socket.ReceiveLength;
         except
            j:=-2;
         end;
         if j=-2 then
            break;
         if j<=0 then
            begin
               sleep(1);
               continue;
            end;
         k:=length(RequestBody);
         SetLength(RequestBody,k+j);
         try
            bytes:=Socket.ReceiveBuf(RequestBody[k+1],j);
         except
            bytes:=0;
         end;
         if bytes<>j then
            break;
         if RequestLength=-1 then
            begin
               j:=pos(AnsiString(#13),RequestBody);
               if j>1 then
                  begin
                     tmpstr:=copy(RequestBody,1,j-1);
                     delete(RequestBody,1,j);
                     if trim(tmpstr)='' then
                        RequestLength:=-1
                     else
                        try
                           RequestLength:=StrToInt(string(tmpstr));
                        except
                           RequestLength:=-1;
                        end;
                     if (RequestLength<=0) or (RequestLength>=NodeService.s_MaxRequestLength) then
                        break;
                     j:=Length(RequestBody);
                     if j>=RequestLength then
                        begin
                           if j>RequestLength then
                              begin
                                 RestBody:=copy(RequestBody,RequestLength+1,j-RequestLength);
                                 delete(RequestBody,RequestLength+1,j-RequestLength);
                              end;
                           result:=true;
                           break;
                        end;
                  end
               else
                  begin
                     if length(RequestBody)>20 then
                        break;
                  end;
            end
         else
            begin
               j:=Length(RequestBody);
               if j>=RequestLength then
                  begin
                     if j>RequestLength then
                        begin
                           RestBody:=copy(RequestBody,RequestLength+1,j-RequestLength);
                           delete(RequestBody,RequestLength+1,j-RequestLength);
                        end;
                     result:=true;
                     break;
                  end;
            end;
         sleep(1);
      end;
end;

function TTaskThread.ProcessTask: boolean;
var
  TaskId,j,i: integer;
  Flag,AdminId,AdminPassword,cklb: ansistring;
  ok: boolean;
  SqlCommand:String;
begin
  try
    Flag:=RequestPacket.GetEncryptStringGoods('SystemFlag');
    if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(Flag),PAnsiChar('Task_Request'))<>0 then
    begin
      NodeService.syslog.Log('Err0200001: Invalid general task request flag.');
      Result:=false;
      exit;
    end;
    RequestNodeId:=RequestPacket.GetEncryptStringGoods('RequestUserId');
    j:=pos(AnsiString('@'),RequestNodeId);
    RequestUserId:=copy(RequestNodeId,1,j-1);
    delete(RequestNodeId,1,j);
    if RequestPacket.GoodsExists('CKLBString') then
    begin
      cklb:=RequestPacket.GetEncryptStringGoods('CKLBString');
      if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(cklb),PAnsiChar(NodeService.BalanceKey))<>0 then
      begin
        result:=false;
        exit;
      end;
    end
    else
    begin
      if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.s_ThisNodeId),PAnsiChar(RequestNodeId))=0 then
      begin
        UserSessionId:=RequestPacket.GetInt64Goods('SessionId');
        j:=NodeService.FindSessionInSessionId(UserSessionId);
        ok:=(j<>-1);
        if ok then
        begin
          SelfUserId:=NodeService.Sessions[j].UserId;
          ok:=({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(RequestUserId),PAnsiChar(SelfUserId))=0);
        end;
        if not ok then
        begin
          NodeService.syslog.Log('Err0200002: Invalid user SessionId. Access denied.');
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
          result:=false;
          exit;
        end;
      end
      else
      begin
        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar('Abs_Root_Node'),PAnsiChar(RequestNodeId))<>0 then
        begin
          UserSessionId:=RequestPacket.GetInt64Goods('SessionId');
          if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.s_RootNodeId),PAnsiChar(RequestNodeId))=0) then
             ok:=true
          else
          begin
            EnterCriticalSection(NodeService.NodeListCs);
            ok:=false;
            for i:= 0 to NodeService.NodeCount - 1 do
              if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.Nodes[i].NodeId),PAnsiChar(RequestNodeId))=0 then
              Begin
                ok:=true;
                break;
              end;
            LeaveCriticalSection(NodeService.NodeListCs);
          end;
          if (not ok) and (UserSessionId<>NodeService.PublicSessionId) then
          begin
            NodeService.syslog.Log('Err0200003: Invalid public SessionId. Access denied.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            result:=false;
            exit;
          end;
        end
        else
        begin
          adminid:=RequestPacket.GetEncryptStringGoods('_Admin_Id');
          adminpassword:=RequestPacket.GetEncryptStringGoods('_Admin_Password');
          ok:=(NodeService.s_Registered and NodeService.IsValidUser(AdminId,AdminPassword));
          if not ok then
          begin
            try
              BackPacket.EncryptKey:=NodeService.s_TransferKey;
              BackPacket.PutBooleanGoods('ProcessResult',false);
              if not NodeService.s_Registered then
              begin
                BackPacket.PutEncryptStringGoods('ErrorCode','0299901');
                BackPacket.PutEncryptStringGoods('ErrorText','System not authorized.');
              end
              else
              begin
                BackPacket.PutEncryptStringGoods('ErrorCode','0299902');
                BackPacket.PutEncryptStringGoods('ErrorText','Invalid userid or password.');
              end;
            except
              on e: exception do
                NodeService.syslog.Log('Err0200004: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
            end;
            result:=false;
            exit;
          end;
        end;
      end;
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err0200001: Error on get task parameters: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
  end;
  Result:=true;
  TaskId:=RequestPacket.GetIntegerGoods('TaskId');
  SqlCommand:=RequestPacket.GetStringGoods('SqlCommand');
  try
    case TaskId of
      1: Task_GetUserList;
      2: Task_AddUser;
      3: Task_UpdateUser;
      4: Task_RemoveUser;
      5: Task_U2UTransfer;
      6: Task_BroadTransfer;
      7: Task_GetBackupMsgList;
      8: Task_GetMsgBody;
      9: Task_DropMsg;
      10: Task_FetchNodeList;
      11: Task_AddNode;
      12: Task_UpdateNode;
      13: Task_RemoveNode;
      14: Task_GetOnlineNodeList;
      24: Task_FetchGroupList;
      25: Task_AddGroup;
      26: Task_UpdateGroup;
      27: Task_RemoveGroup;
      28: Task_FetchGroupMemberList;
      29: Task_JoinToGroup;
      30: Task_QuitFromGroup;
      32: Task_PostGroupMsg;
      33: begin
            NodeService.LogEventMsg(2,FromIpAddr+': Get file size to download file.');
            Task_GetFileSize;
         end;
      34: begin
            NodeService.LogEventMsg(2,FromIpAddr+': Create file to upload file.');
            Task_CreateFile;
         end;
      35: Task_ReadFileBlock;
      36: Task_WriteFileBlock;
      37: Task_FetchScheduleList;
      38: Task_AddSchedule;
      39: Task_UpdateSchedule;
      40: Task_RemoveSchedule;
      41: begin
            NodeService.LogEventMsg(4,FromIpAddr+': Execute schedule task immediately.');
            Task_RunSchedule;
          end;
      42: begin
            NodeService.LogEventMsg(5,FromIpAddr+': Execute external program.');
            Task_RunExternalProgram;
          end;
      43: Task_FetchDatabaseList;
      44: Task_AddDatabase;
      45: Task_UpdateDatabase;
      46: Task_RemoveDatabase;
      47: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Test registered database connection.');
            Task_TestDatabase;
         end;
      48: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Test external database connection.');
            Task_TestExternalDatabase;
         end;
      49: Task_FetchPluginList;
      50: Task_AddPlugin;
      51: Task_UpdatePlugin;
      52: Task_RemovePlugin;
      53: begin
            NodeService.LogEventMsg(3,FromIpAddr+': Remote procedure calling.');
            Task_BinaryRPC;
         end;
      54: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Execute SQL statement.');
            Task_ExecSQL;
         end;
      55: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Execute batch SQL statements.');
            Task_ExecBatchSQL;
         end;
      56: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Execute storaged procedure.');
            Task_ExecStoreProc;
         end;
      57: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Import file to blob field.');
            Task_FileToBlob;
         end;
      58: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Dump blob field to file.');
            Task_BlobToFile;
         end;
      59: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Dump dataset to file.');
            Task_TableToFile;
         end;
      60: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Import dataset from file.');
            Task_FileToTable;
         end;
      61: begin
            NodeService.LogEventMsg(1,FromIpAddr+': 读取单个数据集');
            Task_ReadDataset;
         end;
      62: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Write dataset to table.');
            Task_WriteDataset;
         end;
      63: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Append record to table.');
            Task_AppendRecord;
         end;
      64: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Update record to table.');
            Task_UpdateRecord;
         end;
      65: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Read table structure.');
            Task_GetTableHead;
         end;
      66: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Generate key field value.');
            Task_GenerateKeyId;
         end;
      67: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Free key field value.');
            Task_FreeKeyId;
         end;
      68: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Commit delta data to table.');
            Task_SaveDelta;
         end;
      70: begin
            NodeService.LogEventMsg(1,FromIpAddr+': 生成 UniqueID 值.');
            Task_GetUniqueID;
         end;
      72: begin
          NodeService.LogEventMsg(1, FromIpAddr+': 进行分页查询...');
          Task_GetQueryPageData;
         end;
      73: begin
          NodeService.LogEventMsg(1, FromIpAddr+': 调用 PageQuery 存储过程进行分页查询...');
          Task_GetPageQuery;
         end;
//      75: begin
//            NodeService.LogEventMsg(1,FromIpAddr+': Create page query session.');
//            Task_CreatePageQuery;
//         end;
//      76: Task_QueryPageData;
//      77: begin
//            NodeService.LogEventMsg(1,FromIpAddr+': Terminate page query session.');
//            Task_TerminatePageQuery;
//         end;

      79: Task_SystemReport;
      80: Task_HelloNode;
      81: begin
            NodeService.LogEventMsg(1,FromIpAddr+': Clear blob field.');
            Task_ClearBlob;
         end;
      82: Task_ChangeUserPassword;
      83: Task_GetUserProperty;
      84: Task_GetNodeProperty;
      85: Task_GetPluginProperty;
      86: Task_GetScheduleProperty;
      88: Task_GetUserGroupProperty;
      89: Task_GetDatabaseProperty;
      90: Task_GetWebStatus;
      91: Task_SetWebService;
      92: Task_FetchWebSessions;
      93: Task_RemoveWebSession;
      94: Task_SetWebSocket;
      95: Task_FetchWSSessions;
      96: Task_RemoveWsSession;
      97: Task_SendToWsUser;
      98: Task_SendToBatchWsUsers;
      99: Task_SendToWsChannel;
      100: Task_ReadTmpFile;
      102: Task_GroupHeartbeat;
      104: Task_QueryHeartbeat;
      105: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Read blob field to a stream.');
             Task_BlobToStream;
          end;
      106: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Import stream data to blob field.');
             Task_StreamToBlob;
          end;
      107: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Execute SQL command and return the affected record count.');
             Task_ExecCommand;
          end;
      108: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Execute SQL command and return simple result.');
             Task_ReadSimpleResult;
          end;
      109: begin
            NodeService.LogEventMsg(3,FromIpAddr+': Mount plugin module to frame.');
            Task_MountPlugin;
          end;
      110: begin
            NodeService.LogEventMsg(3,FromIpAddr+': Dismount plugin module from frame.');
            Task_DismountPlugin;
          end;
      111: Task_GetTmpFileName;
      112: Task_FetchBlackList;
      113: Task_AddBlack;
      114: Task_RemoveBlack;
      115: Task_BindIntProp;
      116: Task_BindStrProp;
      117: Task_SendToConnection;
      118: Task_SendToIntPropConnections;
      119: Task_SendToStrPropConnections;
      120: Task_FetchIntPropConnections;
      121: Task_FetchStrPropConnections;
      122: Task_ClearIntProp;
      123: Task_ClearStrProp;
      124: begin
             NodeService.LogEventMsg(1,FromIpAddr+': 批量读取多个数据集...');
             Task_ReadMultiDataset;
          end;
      125: begin
             NodeService.LogEventMsg(1,FromIpAddr+': 批量更新多个数据集...');
             Task_WriteMultiDataset;
          end;
      126: Task_ReadSysParameters;
      128: begin
             NodeService.LogEventMsg(1,FromIpAddr+': 批量提交多个任务...');
             Task_CommitBatchTasks;
          end;
      129: Task_GetIntPropCount;
      130: Task_GetStrPropCount;
      131: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Get MD5 of bolb field.');
             Task_GetBlobMd5;
          end;
      132: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Get SHA1 of bolb field.');
             Task_GetBlobSha1;
          end;
      133: Task_SendToWebSession;
      134: Task_SendToAllWebSessions;
      135: Task_SendToStrPropWebSessions;
      136: Task_SendToIntPropWebSessions;
      137: Task_GetServiceVersion;
      138: Task_GetServerDateTime;
      139: Task_FetchAllConnections;
      140: Task_FetchTriggerList;
      141: Task_RegisterTrigger;
      142: Task_UnregisterTrigger;
      143: Task_FireTrigger;
      144: begin
             NodeService.LogEventMsg(3,FromIpAddr+': Remote procedure calling.');
             Task_BinaryRPCAnsyc;
          end;
      145: begin
             NodeService.LogEventMsg(1,FromIpAddr+': Batch update records.');
             Task_UpdateDataset;
          end;
      146: task_FetchDeviceList;
      147: Task_RegisterDevice;
      148: Task_UnregisterDevice;
      149: Task_VerificationDevice;
      150: Task_BindRoleId;
      151: Task_FetchRoleIdConnections;
      152: Task_SendToRoleIdConnections;
      153: Task_ClearRoleId;
      154: Task_GetRoleIdCount;
      155: Task_SendToRoleIdWebSessions;
      156: Task_ValueExists;
      157: Task_CommitSqlDelta;
      158: Task_TableExists;
      159: Task_PrepostData;
      160: Task_ReloadPlugin;
      161: Task_RefreshPreloadPlugins;
    else
    begin
       NodeService.syslog.Log('Err0200005: 无效的请求任务ID ['+InttoStr(TaskId)+'] 。服务端拒绝访问...');
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
       NodeService.syslog.Log('Sql Command :'+SqlCommand);
       result:=false;
    end;
    end;
  except
    on e: exception do
    begin
      NodeService.syslog.Log('Err0200005: 执行请求的任务出错，任务 ID  ['+InttoStr(TaskId)+'] error: '+ansistring(e.classname)+'-'+ansistring(e.message));
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      NodeService.syslog.Log('Sql Command :'+SqlCommand);
      result:=false;
    end;
  end;
  if result then
    result:=(ResponseBody<>'');
end;

function TTaskThread.FeedbackPacket(const aPacket: TwxdPacket): boolean;
var
   BlockSize: integer;
   DataAddr: pointer;
   Ptr,bytes,LengthToSend: integer;
begin
   DataAddr:=aPacket.GetDataAddress2;
   LengthToSend:=aPacket.DataLength;
   ptr:=0;
   while (not terminated) and (ptr<LengthToSend) do
      begin
         if LengthToSend-Ptr>TransferBlockSize then
            BlockSize:=TransferBlockSize
         else
            BlockSize:=LengthToSend-Ptr;
         try
            bytes:=Socket.SendBuf(pointer(dword(dataaddr)+dword(ptr))^,BlockSize);
            if Bytes=-2 then
               break;
            if bytes>0 then
               ptr:=ptr+bytes;
         except
            break;
         end;
         sleep(1);
      end;
   result:=(ptr>=LengthToSend);
end;

function TTaskThread.SaveUserMessage(const TargetUserId: AnsiString; const MsgPacket: TwxdPacket; var MsgId: AnsiString): boolean;
var
   aTask: TTaskRecord;
   SysConn: TUniConnection;
   SysQuery: TUniQuery;
   PoolId,ConnectionId: integer;
begin
   aTask.MsgBody:=nil;
   SysConn:=nil;
   SysQuery:=nil;
   if not NodeService.GetConnection(NodeService.s_BackuperDB,PoolId,ConnectionId,SysConn) then
      begin
         result:=false;
         exit;
      end;
   try
      aTask.MsgBody:=TMemoryStream.Create;
      SysQuery:=TUniQuery.Create(nil);
      aTask.FromUserId:=MsgPacket.GetEncryptStringGoods('FromUserId');
      aTask.ToUserId:=TargetUserId;
      aTask.MsgType:=MsgPacket.GetIntegerGoods('MessageType');
      result:=MsgPacket.SaveToStream(aTask.MsgBody);
      if result then
         begin
            SysQuery.DisableControls;
            SysQuery.Connection:=SysConn;
            EnterCriticalSection(NodeService.LastMsgIdCs);
            try
               MsgId:=AnsiString(inttostr(strtoint(string(NodeService.LastMsgId))+1));
               while length(MsgId)<10 do
                  MsgId:='0'+MsgId;
               NodeService.LastMsgId:=MsgId;
            except
            end;
            LeaveCriticalSection(NodeService.LastMsgIdCs);
            try
               SysQuery.SQL.Text:='SELECT * FROM '+string(NodeService.s_BackuperTable)+' WHERE 1=2';
               SysQuery.Active:=true;
               SysQuery.append;
               SysQuery.fieldvalues['MessageId']:=MsgId;
               SysQuery.fieldvalues['TargetUserId']:=TargetUserId;
               SysQuery.fieldvalues['FromUserId']:=aTask.FromUserId;
               SysQuery.fieldvalues['MessageType']:=aTask.MsgType;
               SysQuery.fieldvalues['MessageSize']:=aTask.MsgBody.Size;
               SysQuery.fieldvalues['RecvDateTime']:=formatdatetime('yyyymmddhhnnss',now);
               aTask.MsgBody.position:=0;
               TBlobField(SysQuery.FieldByName('MessageBody')).LoadFromStream(aTask.MsgBody);
               SysQuery.Post;
            except
               on e: exception do
                  begin
                     NodeService.syslog.Log('Err0200009: Backup user message error: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     Result:=false;
                  end;
            end;
         end;
   except
      on e: exception do
         begin
            NodeService.syslog.Log('Err0200009: Backup user message error: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            Result:=false;
         end;
   end;
   if assigned(aTask.MsgBody) then
      FreeAndNil(aTask.MsgBody);
   if assigned(SysQuery) then
      FreeAndNil(SysQuery);
   NodeService.FreeConnection(PoolId,ConnectionId);
end;

function TTaskThread.ExecuteExternalProgram(const aPrgFilename: String; const aParameters: String; const aReturnMode: integer; var ReturnValue: AnsiString): boolean;
var
   commandline: string;
   StartInfo: TStartupInfo;                     
   ProcessInfo: TProcessInformation;            
   ExitCode: Cardinal;                          
begin
   if aReturnMode=1 then
      begin
         try
            Result:=(ShellExecute(0,'open',pchar(aPrgFilename),pchar(aParameters),'',SW_SHOW)>32);
         except
            on e: exception do
               begin
                  NodeService.syslog.Log('Err0200010: Run external program error: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  Result:=false;
               end;
         end;
      end
   else
      begin
          if copy(aPrgFilename,1,1)<>'"' then
             commandline:='"'+aPrgFilename+'"';
          commandline:=commandline+' '+aParameters;
          try
             Result:=CreateProcess(nil,pchar(CommandLine),nil,nil,true,CREATE_NO_WINDOW,nil,nil,StartInfo,ProcessInfo);
             if not result then
                begin
                   Result:=false;
                   ReturnValue:='';            
                end
             else
                begin
                   ExitCode:=STILL_ACTIVE;
                   while (ExitCode=STILL_ACTIVE) and (not NodeService.SystemNeedShutdown) and (not terminated) do
                      begin
                         if not GetExitCodeProcess(ProcessInfo.hProcess,ExitCode) then
                            begin
                               ExitCode:=0;
                               break;
                            end;
                         sleep(5);
                      end;
                   ReturnValue:=Ansistring(inttostr(ExitCode));
                   Result:=true;
                end;
          except
            on e: exception do
               begin
                  NodeService.syslog.Log('Err0200011: Run external program error: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  Result:=false;
               end;
          end;
      end;
end;

function TTaskThread.TestDatabase(const aDatabaseId: AnsiString; var Error: string): boolean;
var
  i,j: integer;
  Provider: string;
  Server:String;
  UserName:String;
  Password:String;
  Database:String;
  ConnStr: string;
  TestConn: TUniConnection;
begin
  EnterCriticalSection(NodeService.DatabaseListCs);
  provider:='';
  connstr:='';
  j:=-1;
  for i:=0 to NodeService.DatabaseCount-1 do
    if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aDatabaseId),PAnsiChar(NodeService.Databases[i].DatabaseId))=0) then
    begin
      j:=i;
      provider:=string(NodeService.Databases[j].DatabaseProvider);
      Server := string(NodeService.Databases[j].Server);
      UserName := String(NodeService.Databases[j].UserName);
      Password := String(NodeService.Databases[j].Password);
      Database := String(NodeService.Databases[j].Database);
      ConnStr := 'Provider=SQLOLEDB.1;Password='+Password
        +';Persist Security Info=True;User ID='+UserName
        +';Initial Catalog='+Database
        +';Data Source='+Server;
      break;
    end;
  LeaveCriticalSection(NodeService.DatabaseListCs);
  if j<>-1 then
  begin
  TestConn:=nil;
    try
      TestConn:=TUniConnection.Create(nil);
//      TestConn.Mode:=cmReadWrite;
      TestConn.LoginPrompt:=false;
//      TestConn.ConnectionTimeout:=10;
      TestConn.ProviderName:=provider;
      TestConn.Server := Server;
      TestConn.Username := UserName;
      TestConn.Password := Password;
      TestConn.Database := Database;
//      TestConn.ConnectionString:=connstr;
      TestConn.Connected:=true;
      sleep(1);
      result:=TestConn.Connected;
    except
      on e: exception do
      begin
        Error:='['+e.classname+']-'+e.message;
        Result:=false;
      end;
    end;
    if assigned(TestConn) then
      FreeAndNil(TestConn);
  end
  else
  begin
    Result:=false;
    Error:='测试连接的数据库 ['+ Database +'] 可能已经不存在...';
  end;
end;

function TTaskThread.TestExtDatabase(const aProvider: string;  const aServer: string;
            const aUserName:String; const aPassword:String; const aDatabase:String; var Error: string): boolean;
var
  TestConn: TUniConnection;
  i:integer;
begin
  try
    TestConn:=TUniConnection.Create(nil);
    TestConn.LoginPrompt := False;
//    TestConn.ConnectionString := 'Provider=SQLOLEDB.1;Password='+aPassword
//        +';Persist Security Info=True;User ID='+aUsername
//        +';Initial Catalog='+aDatabase
//        +';Data Source='+aServer;
    TestConn.ProviderName := aProvider;
    TestConn.Server := aServer;
    TestConn.Username := aUserName;
    TestConn.Password := aPassword;
    TestConn.Database := aDatabase;
    TestConn.Open;
    sleep(1);
    result:=TestConn.Connected;
  except
    on e: exception do
    begin
      Error:='['+e.classname+']-'+e.message;
      Result:=false;
    end;
  end;
  if assigned(TestConn) then
    FreeAndNil(TestConn);
end;

procedure TTaskThread.Task_GetUserList;
var
   ok: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=nil;
   Stream:=nil;
   try
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      with Cds do
         begin
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserId';
                  DataType:=ftWideString;
                  Size:=32;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserName';
                  DataType:=ftWideString;
                  Size:=48;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserPassword';
                  DataType:=ftWideString;
                  Size:=32;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserTypeId';
                  DataType:=ftInteger;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserAttr';
                  DataType:=ftWideString;
                  Size:=64;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='UserDesc';
                  DataType:=ftWideString;
                  Size:=64;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='Online';
                  DataType:=ftBoolean;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='IpAddress';
                  DataType:=ftWideString;
                  Size:=15;
               end;
            with FieldDefs.AddFieldDef do
               begin
                  Name:='Rejected';
                  DataType:=ftBoolean;
               end;
            CreateDataSet;
         end;
      Cds.Open;
      NodeService.UserListToCds(Cds);
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,Err);
      if not ok then
         begin
            ErrorCode:='0200101';
            ErrorText:='Zip user list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('UserCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('UserList',Stream);
            if not ok then
               begin
                  ErrorCode:='0200101';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02001: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   if assigned(Cds) then
      FreeAndNil(Cds);
end;

procedure TTaskThread.Task_AddUser;
var
   ok: boolean;
   tmpUserId,tmpUserName,tmpUserPassword,tmpUserAttr,tmpUserDesc: AnsiString;
   tmpUserType: integer;
begin
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   tmpUserName:=RequestPacket.GetEncryptStringGoods('UserName');
   tmpUserPassword:=RequestPacket.GetEncryptStringGoods('UserPassword');
   tmpUserType:=RequestPacket.GetIntegerGoods('UserType');
   tmpUserAttr:=RequestPacket.GetEncryptStringGoods('UserAttr');
   tmpUserDesc:=RequestPacket.GetEncryptStringGoods('UserDesc');
   ok:=(not ((trim(tmpUserId)='') or (trim(tmpUserName)='') or (tmpUserType<0)));
   if ok then
      begin
         try
            ok:=NodeService.AddUser(tmpUserId,tmpUserName,tmpUserPassword,tmpUserType,tmpUserAttr,tmpUserDesc);
         except
            ok:=false;
         end;
         if not ok then
            begin
               ErrorCode:='0200202';
               ErrorText:='UserId already exists.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0200201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02002: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_UpdateUser;
var
   ok: boolean;
   OldUserId: AnsiString;
   tmpUserId,tmpUserName,tmpUserPassword,tmpUserAttr,tmpUserDesc: AnsiString;
   tmpUserType: integer;
begin
   OldUserId:=RequestPacket.GetEncryptStringGoods('OldUserId');
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   tmpUserName:=RequestPacket.GetEncryptStringGoods('UserName');
   tmpUserPassword:=RequestPacket.GetEncryptStringGoods('UserPassword');
   tmpUserType:=RequestPacket.GetIntegerGoods('UserType');
   tmpUserAttr:=RequestPacket.GetEncryptStringGoods('UserAttr');
   tmpUserDesc:=RequestPacket.GetEncryptStringGoods('UserDesc');
   ok:=(not ((trim(OldUserId)='') or (trim(tmpUserId)='')
             or (trim(tmpUserName)='') or (tmpUserType<0) or ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(OldUserId),PAnsiChar(tmpUserId))<>0)));
   if ok then
      begin
         try
            ok:=NodeService.UpdateUser(OldUserId,tmpUserId,tmpUserName,tmpUserPassword,tmpUserType,tmpUserAttr,tmpUserDesc);
         except
            ok:=false;
         end;
         if not ok then
            begin
               ErrorCode:='0200302';
               ErrorText:='Old UserId not found or old password invalid.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0200301';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02003: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_ChangeUserPassword;
var
   ok: boolean;
   UserId,OldUserPassword,NewUserPassword: AnsiString;
begin
   UserId:=RequestPacket.GetEncryptStringGoods('UserId');
   OldUserPassword:=RequestPacket.GetEncryptStringGoods('OldUserPassword');
   NewUserPassword:=RequestPacket.GetEncryptStringGoods('NewUserPassword');
   ok:=(trim(UserId)<>'');
   if ok then
      begin
         try
            ok:=NodeService.UpdateUserPassword(UserId,OldUserPassword,NewUserPassword);
         except
            ok:=false;
         end;
         if not ok then
            begin
               ErrorCode:='0208202';
               ErrorText:='UserId not found or invalid.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0208201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02082: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_RemoveUser;
var
   ok: boolean;
   tmpUserId: AnsiString;
begin
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   ok:=(trim(tmpUserId)<>'') and (uppercase(trim(tmpUserId))<>'SYSTEM');
   if ok then
      begin
         try
            ok:=NodeService.RemoveUser(tmpUserId);
         except
            ok:=false;
         end;
         if not ok then
            begin
               ErrorCode:='0200402';
               ErrorText:='Old UserId not found or old password invalid.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0200401';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02004: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_U2UTransfer;
var
   ok: boolean;
   FromUserId,TargetUserId,MsgId,MsgBody: AnsiString;
   Packet: TwxdPacket;
begin
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   TargetUserId:=RequestPacket.GetEncryptStringGoods('TargetUserId');
   Packet:=TwxdPacket.Create;
   try
      Packet.EncryptKey:=NodeService.s_TransferKey;
      ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   except
      ok:=false;
   end;
   if ok then
      begin
         if NodeService.UserIsOnline(TargetUserId) then
            begin
               try
                  if Packet.PacketSize>64*1024 then
                     begin
                        Packet.PutIntegerGoods('ResponseId',4);
                        Packet.PutEncryptStringGoods('FromUserId',FromUserId);
                        Packet.PutIntegerGoods('MessageType',0);
                        ok:=SaveUserMessage(TargetUserId,Packet,MsgId);
                        if ok then
                           begin
                              Packet.Clear;
                              Packet.PutIntegerGoods('ResponseId',4);
                              Packet.PutEncryptStringGoods('FromUserId',FromUserId);
                              Packet.PutIntegerGoods('MessageType',0);
                              Packet.PutEncryptStringGoods('Sys_Msg_Id',MsgId);
                           end
                        else
                           begin
                              ErrorCode:='0200503';
                              ErrorText:='Backup message to database failed.';
                              NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                              NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                           end;
                     end
                  else
                     begin
                        Packet.PutIntegerGoods('ResponseId',4);
                        Packet.PutEncryptStringGoods('FromUserId',FromUserId);
                        Packet.PutIntegerGoods('MessageType',0);
                     end;
               except
                  on e: exception do
                    begin
                       ErrorCode:='0200505';
                       ErrorText:='Generate message Packet error: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                       ok:=false;
                    end;
               end;
               if ok then
                  begin
                     ok:=Packet.SaveToStringWithLength(MsgBody);
                     if ok then
                        ok:=NodeService.SendToUser(TargetUserId,MsgBody);
                     if not ok then
                        begin
                           ErrorCode:='0200502';
                           ErrorText:='Send to target user failed.';
                           NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                           NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                        end;
                  end;
            end
         else
            begin
               try
                  Packet.PutIntegerGoods('ResponseId',4);
                  Packet.PutEncryptStringGoods('FromUserId',FromUserId);
                  Packet.PutIntegerGoods('MessageType',0);
                  ok:=true;
               except
                  on e: exception do
                    begin
                       ErrorCode:='0200506';
                       ErrorText:='Generate message Packet error: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                       ok:=false;
                    end;
               end;
               if ok and NodeService.s_SaveU2UMessages then
                  begin
                     ok:=SaveUserMessage(TargetUserId,Packet,MsgId);
                     if not ok then
                        begin
                           ErrorCode:='0200503';
                           ErrorText:='Backup message to database failed.';
                           NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                           NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                        end;
                  end
               else
                  begin
                     ErrorCode:='0200504';
                     ErrorText:='Target user offline.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end;
      end
   else
      begin
         ErrorCode:='0200501';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02005: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_BroadTransfer;
var
   ok: boolean;
   FromUserId,MsgId,MsgBody: AnsiString;
   i,MsgType,tmpUserType: integer;
   OnlineUsers,OfflineUsers: TStringList;
   UDPAddress: AnsiString;
   UDPPort: integer;
   Packet: TwxdPacket;
begin
   OnlineUsers:=nil;
   OfflineUsers:=nil;
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   MsgType:=RequestPacket.GetIntegerGoods('MessageType');
   Packet:=TwxdPacket.Create;
   try
      Packet.EncryptKey:=NodeService.s_TransferKey;
      ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   except
      ok:=false;
   end;
   if ok then
      try
         Packet.PutEncryptStringGoods('FromUserId',FromUserId);
      except
         ok:=false;
      end;
   if ok then
      begin
         case MsgType of
            1: begin
                  if not RequestPacket.GoodsExists('TargetUserType') then
                     tmpUserType:=0
                  else
                     tmpUserType:=RequestPacket.GetIntegerGoods('TargetUserType');
                  OnlineUsers:=TStringList.Create;
                  OfflineUsers:=TStringList.Create;
                  try
                     Packet.PutIntegerGoods('ResponseId',5);
                     Packet.PutIntegerGoods('MessageType',MsgType);
                     NodeService.DispatchUserList(tmpUserType,OnlineUsers,OfflineUsers);
                     if Packet.SaveToStringWithLength(MsgBody) then
                        begin
                           for i:= 0 to OnlineUsers.Count - 1 do
                              NodeService.SendToUser(AnsiString(OnlineUsers[i]),MsgBody);
                        end;
                     if NodeService.s_SaveBroadcastMessages and (OfflineUsers.Count>0) then
                        begin
                           for i:=0 to OfflineUsers.Count - 1 do
                              SaveUserMessage(AnsiString(OfflineUsers[i]),Packet,MsgId);
                        end;
                  except
                     ok:=false;
                  end;
                  FreeAndNil(OnlineUsers);
                  FreeAndNil(OfflineUsers);
               end;
            2: begin
                  UDPPort:=RequestPacket.GetIntegerGoods('BroadcastPort');
                  UDPAddress:=AnsiString(wxdCommon.GetBroadcastIp);
                  UDP:=nil;
                  try
                     UDP:=TButterflyUDP.Create(nil);
                     UDP.RemoteHost:=UDPAddress;
                     UDP.RemotePort:=UDPPort;
                     if Packet.SaveToString(ResponseBody) then
                        UDP.SendBuffer(@ResponseBody[1],Length(ResponseBody));
                  except
                     ok:=false;
                     ErrorCode:='0200603';
                     ErrorText:='UDP sending failed.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
                  if assigned(udp) then
                     FreeAndNil(UDP);
               end;
            3: begin
                  UDPAddress:=RequestPacket.GetEncryptStringGoods('MulticastAddress');
                  UDPPort:=RequestPacket.GetIntegerGoods('MulticastPort');
                  UDP:=nil;
                  try
                     UDP:=TButterflyUDP.Create(nil);
                     UDP.RemoteHost:=UDPAddress;
                     UDP.RemotePort:=UDPPort;
                     if Packet.SaveToString(ResponseBody) then
                        UDP.SendBuffer(@ResponseBody[1],Length(ResponseBody));
                  except
                     ok:=false;
                     ErrorCode:='0200603';
                     ErrorText:='UDP sending failed.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
                  if assigned(udp) then
                     FreeAndNil(UDP);
               end;
            4: begin
                  UDPAddress:=RequestPacket.GetEncryptStringGoods('UnicastAddress');
                  UDPPort:=RequestPacket.GetIntegerGoods('UnicastPort');
                  UDP:=nil;
                  try
                     UDP:=TButterflyUDP.Create(nil);
                     UDP.RemoteHost:=UDPAddress;
                     UDP.RemotePort:=UDPPort;
                     if Packet.SaveToString(ResponseBody) then
                        UDP.SendBuffer(@ResponseBody[1],Length(ResponseBody));
                  except
                     ok:=false;
                     ErrorCode:='0200603';
                     ErrorText:='UDP sending failed.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
                  if assigned(udp) then
                     FreeAndNil(UDP);
               end;
            5: begin
                  try
                     Packet.PutIntegerGoods('ResponseId',22);
                     Packet.PutIntegerGoods('MessageType',MsgType);
                     ok:=NodeService.PostToAllConnections(Packet);
                     if not ok then
                        begin
                           ErrorCode:='0200603';
                           ErrorText:='SendToAllConnections failed.';
                        end;
                  except
                     ErrorCode:='0200603';
                     ErrorText:='Exception detected on SendToAllConnections.';
                     ok:=false;
                  end;
               end;
            else
               begin
                  ok:=false;
                  ErrorCode:='0200601';
                  ErrorText:='无效参数...';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      end
   else
      begin
         ErrorCode:='0200601';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02006: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_GetBackupMsgList;
var
   ok: boolean;
   tmpstr: AnsiString;
   MsgList: TStringList;
   SysConn: TUniConnection;
   SysQuery: TUniQuery;
   PoolId,ConnectionId: integer;
begin
   MsgList:=nil;
   SysConn:=nil;
   SysQuery:=nil;
   if NodeService.GetConnection(NodeService.s_BackuperDB,PoolId,ConnectionId,SysConn) then
      begin
         MsgList:=TStringList.Create;
         try
            SysQuery:=TUniQuery.Create(nil);
            SysQuery.DisableControls;
            SysQuery.Connection:=SysConn;
            SysQuery.SQL.Text:='SELECT MESSAGEID FROM '+string(NodeService.s_BackuperTable)+' WHERE TARGETUSERID='''+string(SelfUserId)+''' ORDER BY MESSAGEID';
            SysQuery.Active:=true;
            while not SysQuery.Eof do
               begin
                  MsgList.Add(trim(SysQuery.FieldByName('MessageId').AsString));
                  SysQuery.Next;
               end;
            ok:=true;
         except
            ok:=false;
         end;
         if Assigned(SysQuery) then
            FreeAndNil(SysQuery);
         if ok then
            begin
               tmpstr:=AnsiString(MsgList.Text);
               try
                  BackPacket.EncryptKey:=NodeService.s_TransferKey;
                  BackPacket.PutBooleanGoods('ProcessResult',true);
                  BackPacket.PutIntegerGoods('MessageCount',MsgList.Count);
                  BackPacket.PutEncryptStringGoods('MessageIdList',tmpstr);
               except
                  on e: exception do
                     NodeService.syslog.Log('Err02007: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
               end;
            end
         else
            begin
               ErrorCode:='0200701';
               ErrorText:='Open message cache table failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
         FreeAndNil(MsgList);
         NodeService.FreeConnection(PoolId,ConnectionId);
      end
   else
      begin
         ok:=false;
         ErrorCode:='0200702';
         ErrorText:='Allocate database connection failed.';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   if not ok then
      try
         BackPacket.PutBooleanGoods('ProcessResult',false);
         BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
         BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
      except
         on e: exception do
            NodeService.syslog.Log('Err02007: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
      end;
end;

procedure TTaskThread.Task_GetMsgBody;
var
   MsgId,tmpstr: AnsiString;
   ok: boolean;
   Stream: TMemoryStream;
   SysConn: TUniConnection;
   SysQuery: TUniQuery;
   PoolId,ConnectionId: integer;
begin
   Stream:=nil;
   SysConn:=nil;
   SysQuery:=nil;
   if NodeService.GetConnection(NodeService.s_BackuperDB,PoolId,ConnectionId,SysConn) then
      begin
         BackPacket.EncryptKey:=NodeService.s_TransferKey;
         MsgId:=RequestPacket.GetEncryptStringGoods('MessageId');
         try
            SysQuery:=TUniQuery.Create(nil);
            Stream:=TMemoryStream.Create;
            SysQuery.DisableControls;
            SysQuery.Connection:=SysConn;
            SysQuery.SQL.Text:='SELECT * FROM '+string(NodeService.s_BackuperTable)+' WHERE MESSAGEID='''+string(MsgId)+'''';
            SysQuery.Active:=true;
            if SysQuery.RecordCount=0 then
               ok:=false
            else
               begin
                  tmpstr:=AnsiString(trim(SysQuery.FieldByName('FromUserId').AsString));
                  BackPacket.PutEncryptStringGoods('FromUserId',tmpstr);
                  BackPacket.PutIntegerGoods('MessageSize',SysQuery.FieldByName('MessageSize').AsInteger);
                  TBlobField(SysQuery.FieldByName('MessageBody')).SaveToStream(Stream);
                  Stream.Position:=0;
                  ok:=BackPacket.PutStreamGoods('MessageBody',Stream);
                  if ok then
                     SysQuery.Delete;
                  if not ok then
                     begin
                        ErrorCode:='0200802';
                        ErrorText:='Put the message body to Packet failed.';
                     end;
               end;
         except
            on e: exception do
               begin
                  ok:=false;
                  ErrorText:='['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
         if Assigned(Stream) then
            FreeAndNil(Stream);
         if Assigned(SysQuery) then
            FreeAndNil(SysQuery);
         NodeService.FreeConnection(PoolId,COnnectionId);
      end
   else
      begin
         ErrorCode:='0200801';
         ErrorText:='Allocate message backup database connection failed.';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         ok:=false;
      end;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02008: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
end;

procedure TTaskThread.Task_DropMsg;
var
  tmpstr: ansistring;
  ok: boolean;
  SysConn: TUniConnection;
  SysCommand: TUniSQL;
  PoolId,ConnectionId: integer;
begin
  SysConn:=nil;
  SysCommand:=nil;
  if NodeService.GetConnection(NodeService.s_BackuperDB,PoolId,ConnectionId,SysConn) then
  begin
    try
      tmpstr:=RequestPacket.GetEncryptStringGoods('MessageId');
      SysCommand:=TUniSQL.Create(nil);
      SysCommand.Connection:=SysConn;
      SysCommand.SQL.Text:='DELETE FROM '+string(NodeService.s_BackuperTable)+' WHERE MESSAGEID='''+string(tmpstr)+'''';
      SysCommand.Execute;
      ok:=true;
    except
      on e:exception do
      begin
        ok:=false;
        ErrorCode:='0200902';
        ErrorText:='['+AnsiString(e.ClassName)+']-'+AnsiString(e.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
    end;
    if Assigned(SysCommand) then
      FreeAndNil(SysCommand);
    NodeService.FreeConnection(PoolId,COnnectionId);
  end
  else
  begin
    ErrorCode:='0200901';
    ErrorText:='Allocate message backup database connection failed.';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
    ok:=false;
  end;
  try
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02009: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
  end;
end;

procedure TTaskThread.Task_FetchNodeList;
var
   ok,IncludeRoot: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=nil;
   Stream:=nil;
   IncludeRoot:=RequestPacket.GoodsExists('IncludeRootNode');
   if IncludeRoot then
      IncludeRoot:=RequestPacket.GetBooleanGoods('IncludeRootNode');
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeId';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeName';
               DataType:=ftWideString;
               Size:=48;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodePassword';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeType';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeAddress';
               DataType:=ftWideString;
               Size:=48;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeMsgPort';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeTaskPort';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeWebPort';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='NodeWsPort';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='Online';
               DataType:=ftBoolean;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='IpAddress';
               DataType:=ftWideString;
               Size:=15;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.NodeListToCds(Cds,IncludeRoot);
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0201001';
            ErrorText:='Zip node list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('NodeCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('NodeList',Stream);
            if not ok then
               begin
                  ErrorCode:='0201001';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02010: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_AddNode;
var
   ok: boolean;
   tmpNodeId,tmpNodeName,tmpNodePassword,tmpNodeAddress: AnsiString;
   tmpNodeType,tmpNodeMsgPort,tmpNodeTaskPort,tmpWebPort,tmpWsPort: integer;
   Packet: TwxdPacket;
begin
   tmpNodeId:=RequestPacket.GetEncryptStringGoods('NodeId');
   tmpNodeName:=RequestPacket.GetEncryptStringGoods('NodeName');
   tmpNodePassword:=RequestPacket.GetEncryptStringGoods('NodePassword');
   tmpNodeType:=RequestPacket.GetIntegerGoods('NodeType');
   tmpNodeAddress:=RequestPacket.GetEncryptStringGoods('NodeAddress');
   tmpNodeMsgPort:=RequestPacket.GetIntegerGoods('NodeMsgPort');
   tmpNodeTaskPort:=RequestPacket.GetIntegerGoods('NodeTaskPort');
   if RequestPacket.GoodsExists('NodeTaskPort') then
      tmpWebPort:=RequestPacket.GetIntegerGoods('NodeWebPort')
   else
      tmpWebPort:=1880;
   if RequestPacket.GoodsExists('NodeWsPort') then
      tmpWsPort:=RequestPacket.GetIntegerGoods('NodeWsPort')
   else
      tmpWsPort:=1881;
   ok:=(not ((trim(tmpNodeId)='') or (trim(tmpNodeName)='') or (trim(tmpNodePassword)='')
        or (tmpNodeType<0) or (tmpNodeMsgPort<=0) or (tmpNodeMsgPort>65535) or (tmpNodeTaskPort<=0) or (tmpNodeTaskPort>65535)));
   if ok then
      begin
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.s_ThisNodeId),PAnsiChar(NodeService.s_RootNodeId))<>0 then
            begin
               ok:=false;
               ErrorCode:='0201103';
               ErrorText:='Refuse to manage nodes on son node.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end
         else
            begin
               ok:=NodeService.AddNode(tmpNodeId,tmpNodeName,tmpNodePassword,tmpNodeType,
                   tmpNodeAddress, tmpNodeMsgPort,tmpNodeTaskPort, tmpWebPort,tmpWsPort);
               if not ok then
                  begin
                     ErrorCode:='0201102';
                     ErrorText:='NodeId already exists.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end;
      end
   else
      begin
         ErrorCode:='0201101';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02010: 创建返回消息结构包失败: ['+AnsiString(e.classname)+']-'+AnsiString(e.message));
   end;
   if ok then
      begin
         Packet:=TwxdPacket.Create;
         try
            Packet.EncryptKey:=NodeService.s_TransferKey;
            Packet.PutIntegerGoods('ResponseId',3);
            Packet.PutEncryptStringGoods('FromUserId','system@'+NodeService.s_RootNodeId);
            Packet.PutEncryptStringGoods('NodeId',tmpNodeId);
            Packet.PutEncryptStringGoods('NodeName',tmpNodeName);
            Packet.PutIntegerGoods('NodeType',tmpNodeType);
            Packet.PutEncryptStringGoods('NodeAddress',tmpNodeAddress);
            Packet.PutIntegerGoods('NodeMsgPort',tmpNodeMsgPort);
            Packet.PutIntegerGoods('NodeTaskPort',tmpNodeTaskPort);
            Packet.PutIntegerGoods('NodeWebPort',tmpWebPort);
            Packet.PutIntegerGoods('NodeWsPort',tmpWsPort);
            NodeService.SendToAllNode(Packet);
            Packet.PutIntegerGoods('ResponseId',6);
            SendToAllUser(Packet);
         except
            on e: exception do
               NodeService.syslog.Log('Err02011: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
         FreeANdNil(Packet);
      end;
end;

function TTaskThread.SendToAllUser(const MsgPacket: TwxdPacket): boolean;
var
   OnlineUsers,OfflineUsers: TStringList;
   i: integer;
   ok: boolean;
   MsgBody: AnsiString;
begin
    OnlineUsers:=TStringList.Create;
    OfflineUsers:=TStringList.Create;
    try
       NodeService.DispatchUserList(0,OnlineUsers,OfflineUsers);
       ok:=MsgPacket.SaveToStringWithLength(MsgBody);
       if ok then
          begin
             for i:= 0 to OnlineUsers.Count - 1 do
                begin
                   ok:=(ok and NodeService.SendToUser(AnsiString(OnlineUsers[i]),MsgBody));
                   sleep(1);
                end;
          end;
    except
       ok:=false;
    end;
    FreeAndNil(OnlineUsers);
    FreeAndNil(OfflineUsers);
    result:=ok;
end;

procedure TTaskThread.Task_UpdateNode;
var
   ok: boolean;
   OldNodeId,tmpNodeId,tmpNodeName,tmpNodePassword,tmpNodeAddress: AnsiString;
   tmpNodeType,tmpNodeMsgPort,tmpNodeTaskPort, tmpWebPort,tmpWsPort: integer;
   Packet: TwxdPacket;
begin
   OldNodeId:=RequestPacket.GetEncryptStringGoods('OldNodeId');
   tmpNodeId:=RequestPacket.GetEncryptStringGoods('NodeId');
   tmpNodeName:=RequestPacket.GetEncryptStringGoods('NodeName');
   tmpNodePassword:=RequestPacket.GetEncryptStringGoods('NodePassword');
   tmpNodeType:=RequestPacket.GetIntegerGoods('NodeType');
   tmpNodeAddress:=RequestPacket.GetEncryptStringGoods('NodeAddress');
   tmpNodeMsgPort:=RequestPacket.GetIntegerGoods('NodeMsgPort');
   tmpNodeTaskPort:=RequestPacket.GetIntegerGoods('NodeTaskPort');
   if RequestPacket.GoodsExists('NodeTaskPort') then
      tmpWebPort:=RequestPacket.GetIntegerGoods('NodeWebPort')
   else
      tmpWebPort:=1880;
   if RequestPacket.GoodsExists('NodeWsPort') then
      tmpWsPort:=RequestPacket.GetIntegerGoods('NodeWsPort')
   else
      tmpWsPort:=1881;
   ok:=(not ((trim(OldNodeId)='') or (trim(tmpNodeId)='')
             or (trim(tmpNodeName)='') or (trim(tmpNodePassword)='') or (tmpNodeType<0)
             or (tmpNodeMsgPort<=0) or (tmpNodeMsgPort>65535) or (tmpNodeTaskPort<=0) or (tmpNodeTaskPort>65535)));
   if ok then
      begin
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.s_ThisNodeId),PAnsiChar(NodeService.s_RootNodeId))<>0 then
            begin
               ok:=false;
               ErrorCode:='0201203';
               ErrorText:='Refuse to manage nodes on son node.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end
         else
            begin
               try
                  ok:=NodeService.UpdateNode(OldNodeId,tmpNodeId,tmpNodeName,
                      tmpNodePassword,tmpNodeType,tmpNodeAddress,tmpNodeMsgPort,tmpNodeTaskPort, tmpWebPort,tmpWsPort);
               except
                  ok:=false;
               end;
               if not ok then
                  begin
                     ErrorCode:='0201202';
                     ErrorText:='Old NodeId not found or old password invalid.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end;
      end
   else
      begin
         ErrorCode:='0201201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02012: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if ok then
      begin
         Packet:=TwxdPacket.Create;
         try
            Packet.EncryptKey:=NodeService.s_TransferKey;
            Packet.PutIntegerGoods('ResponseId',4);
            Packet.PutEncryptStringGoods('FromUserId','system@'+NodeService.s_RootNodeId);
            Packet.PutEncryptStringGoods('OldNodeId',OldNodeId);
            Packet.PutEncryptStringGoods('NodeId',tmpNodeId);
            Packet.PutEncryptStringGoods('NodeName',tmpNodeName);
            Packet.PutIntegerGoods('NodeType',tmpNodeType);
            Packet.PutEncryptStringGoods('NodeAddress',tmpNodeAddress);
            Packet.PutIntegerGoods('NodeMsgPort',tmpNodeMsgPort);
            Packet.PutIntegerGoods('NodeTaskPort',tmpNodeTaskPort);
            Packet.PutIntegerGoods('NodeWebPort',tmpWebPort);
            Packet.PutIntegerGoods('NodeWsPort',tmpWsPort);
            NodeService.SendToAllNode(Packet);
            Packet.PutIntegerGoods('ResponseId',7);
            SendToAllUser(Packet);
         except
            on e: exception do
               NodeService.syslog.Log('Err02012: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
         FreeAndNil(Packet);
      end;
end;

procedure TTaskThread.Task_RemoveNode;
var
   ok: boolean;
   tmpNodeId: ansistring;
   Packet: TwxdPacket;
begin
   tmpNodeId:=RequestPacket.GetEncryptStringGoods('NodeId');
   ok:=(trim(tmpNodeId)<>'');
   if ok then
      begin
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(NodeService.s_ThisNodeId),PAnsiChar(NodeService.s_RootNodeId))<>0 then
            begin
               ok:=false;
               ErrorCode:='0201303';
               ErrorText:='Refuse to manage nodes on son node.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end
         else
            begin
               try
                  ok:=NodeService.RemoveNode(tmpNodeId);
               except
                  ok:=false;
               end;
               if not ok then
                  begin
                     ErrorCode:='0201302';
                     ErrorText:='Old NodeId not found or old password invalid.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end;
      end
   else
      begin
         ErrorCode:='0201301';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02013: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if ok then
      begin
         Packet:=TwxdPacket.Create;
         try
            Packet.EncryptKey:=NodeService.s_TransferKey;
            Packet.PutIntegerGoods('ResponseId',5);
            Packet.PutEncryptStringGoods('FromUserId','system@'+NodeService.s_RootNodeId);
            Packet.PutEncryptStringGoods('NodeId',tmpNodeId);
            NodeService.SendToAllNode(Packet);
            Packet.PutIntegerGoods('ResponseId',8);
            SendToAllUser(Packet);
         except
            on e: exception do
               NodeService.syslog.Log('Err02013: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
         FreeAndNil(Packet);
      end;
end;

procedure TTaskThread.Task_GetOnlineNodeList;
var
   OnlineNodes: TStringList;
begin
   OnlineNodes:=TStringList.Create;
   NodeService.GetOnlineNodeIdList(OnlineNodes);
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutIntegerGoods('OnlineNodeCount',OnlineNodes.Count);
      BackPacket.PutEncryptStringGoods('OnlineNodeIdList',AnsiString(OnlineNodes.text));
   except
   end;
   FreeAndNil(OnlineNodes);
end;

procedure TTaskThread.Task_FetchGroupList;
var
   ok: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='GroupId';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='GroupName';
               DataType:=ftWideString;
               Size:=48;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='GroupDesc';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='GroupType';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='GroupOwnerId';
               DataType:=ftWideString;
               Size:=72;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='AllowedMembers';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='CurrentMembers';
               DataType:=ftInteger;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.GroupListToCds(Cds);
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0202401';
            ErrorText:='Zip group list failed: '+AnsiString(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('GroupCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('GroupList',Stream);
            if not ok then
               begin
                  ErrorCode:='0202401';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02024: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_AddGroup;
var
   ok: boolean;
   tmpGroupId,tmpGroupName,tmpGroupDesc,tmpGroupOwnerId: AnsiString;
   tmpGroupType,tmpAllowedMembers: integer;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   tmpGroupName:=RequestPacket.GetEncryptStringGoods('GroupName');
   tmpGroupDesc:=RequestPacket.GetEncryptStringGoods('GroupDesc');
   tmpGroupType:=RequestPacket.GetIntegerGoods('GroupType');
   tmpAllowedMembers:=RequestPacket.GetIntegerGoods('AllowedMembers');
   tmpGroupOwnerId:=RequestPacket.GetEncryptStringGoods('GroupOwnerId');
   ok:=(not ((trim(tmpGroupId)='') or (trim(tmpGroupName)='') or (tmpGroupType<0)
        or (tmpAllowedMembers<1) or (tmpGroupOwnerId='')));
   if ok then
      begin
         ok:=NodeService.AddGroup(tmpGroupId,tmpGroupName,tmpGroupDesc,
             tmpGroupType,tmpAllowedMembers, tmpGroupOwnerId);
         if not ok then
            begin
               ErrorCode:='0202502';
               ErrorText:='Group Id already exists.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0202501';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02025: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_UpdateGroup;
var
   ok: boolean;
   OldGroupId,tmpGroupId,tmpGroupName,tmpGroupDesc,tmpGroupOwnerId: AnsiString;
   tmpGroupType,tmpAllowedMembers: integer;
begin
   OldGroupId:=RequestPacket.GetEncryptStringGoods('OldGroupId');
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   tmpGroupName:=RequestPacket.GetEncryptStringGoods('GroupName');
   tmpGroupDesc:=RequestPacket.GetEncryptStringGoods('GroupDesc');
   tmpGroupType:=RequestPacket.GetIntegerGoods('GroupType');
   tmpAllowedMembers:=RequestPacket.GetIntegerGoods('AllowedMembers');
   tmpGroupOwnerId:=RequestPacket.GetEncryptStringGoods('GroupOwnerId');
   ok:=(not ((trim(OldGroupId)='') or (trim(tmpGroupId)='') or (trim(tmpGroupName)='') or (tmpGroupType<0)
        or (tmpAllowedMembers<1) or (tmpGroupOwnerId='')));
   if ok then
      begin
         ok:=NodeService.UpdateGroup(OldGroupId,tmpGroupId,tmpGroupName,tmpGroupDesc,
             tmpGroupType,tmpAllowedMembers, tmpGroupOwnerId);
         if not ok then
            begin
               ErrorCode:='0202602';
               ErrorText:='Old group Id not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0202601';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02026: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RemoveGroup;
var
   ok: boolean;
   tmpGroupId: AnsiString;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   ok:=(not (trim(tmpGroupId)=''));
   if ok then
      begin
         ok:=NodeService.RemoveGroup(tmpGroupId);
         if not ok then
            begin
               ErrorCode:='0202702';
               ErrorText:='Group Id not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0202701';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02027: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchGroupMemberList;
var
   ok: boolean;
   j: integer;
   tmpGroupId: ansistring;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   j:=pos(AnsiString('*'),tmpGroupId);
   if j>0 then
      tmpGroupId:=copy(tmpGroupId,1,j-1);
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='UserId';
               DataType:=ftWideString;
               Size:=72;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='UserName';
               DataType:=ftWideString;
               Size:=48;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.GroupMembersToCds(tmpGroupId,Cds);
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0202801';
            ErrorText:='Zip node list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('UserCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('UserList',Stream);
            if not ok then
               begin
                  ErrorCode:='0202801';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02028: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_JoinToGroup;
var
   ok: boolean;
   tmpGroupId,tmpUserId,tmpUserName: AnsiString;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   tmpUserName:=RequestPacket.GetEncryptStringGoods('UserName');
   ok:=(not ((trim(tmpGroupId)='') or (pos(ansistring('@'),tmpUserId)<=0)));
   if ok then
      begin
         ok:=NodeService.JoinToGroup(tmpGroupId,tmpUserId,tmpUserName);
         if not ok then
            begin
               ErrorCode:='0202902';
               ErrorText:='User group not found or not allowed to join.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0202901';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02029: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_QuitFromGroup;
var
   ok: boolean;
   tmpGroupId,tmpUserId: AnsiString;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   ok:=(not ((trim(tmpGroupId)='') or (pos(ansistring('@'),tmpUserId)<=0)));
   if ok then
      begin
         ok:=NodeService.QuitFromGroup(tmpGroupId,tmpUserId);
         if not ok then
            begin
               ErrorCode:='0203002';
               ErrorText:='User group not found or not allowed to join.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203001';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02030: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_PostGroupMsg;
var
   ok: boolean;
   tmpGroupId,MsgId,FromUserId: AnsiString;
   MsgPacket: TwxdPacket;
   MsgType: integer;
begin
   MsgPacket:=nil;
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   ok:=(trim(tmpGroupId)<>'');
   if ok then
      begin
         if (RequestPacket.PacketSize+RequestPacket.GoodsCount*40)>64*1024 then
            begin
               MsgPacket:=TwxdPacket.Create;
               try
                  ok:=RequestPacket.GetPacketGoods('MessageBody',MsgPacket);
                  if ok then
                     begin
                        FromUserId:=RequestPacket.GetEncryptStringGoods('RequestUserId');
                        MsgType:=9;                                     
                        MsgPacket.putEncryptStringGoods('FromUserId',FromUserId);
                        MsgPacket.PutIntegerGoods('MessageType',MsgType);
                        ok:=SaveUserMessage(tmpGroupId,MsgPacket,MsgId);
                        if ok then
                           begin
                              RequestPacket.RemoveGoods('MessageBody');
                              RequestPacket.PutEncryptStringGoods('LargeMessageId',MsgId);
                           end;
                     end;
                  if not ok then
                     begin
                        ErrorCode:='0203204';
                        ErrorText:='Save large group message failed.';
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     end;
               except
                  on e: exception do
                     begin
                        ErrorCode:='0203203';
                        ErrorText:='Save large group message failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                        ok:=false;
                     end;
               end;
            end
         else
            MsgPacket:=nil;
         if ok then
            begin
               try
                  RequestPacket.PutIntegerGoods('ResponseId',20);
               except
                  ok:=false;
               end;
               if ok then
                  begin
                     EnterCriticalSection(NodeService.GroupListCs);
                     try
                        NodeService.GroupMembersToBatches(tmpGroupId);
                        NodeService.SendToAllBatches(RequestPacket);
                     except
                        ok:=false;
                     end;
                     LeaveCriticalSection(NodeService.GroupListCs);
                  end;
               if not ok then
                  begin
                     ErrorCode:='0203202';
                     ErrorText:='Send message failed.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end;
         if Assigned(MsgPacket) then
            FreeAndNil(MsgPacket);
      end
   else
      begin
         ErrorCode:='0203201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02032: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetFileSize;
var
   ok: boolean;
   tmpFileName: String;
   fh: integer;
   filesize: Int64;
begin
   tmpFileName:=RequestPacket.GetStringGoods('FileName');
   tmpFileName:=GetAbsolutePath(NodeService.s_DefaultDir,tmpFileName);
   try
      ok:=fileexists(tmpFileName);
   except
      ok:=false;
   end;
   FileSize:=0;
   if ok then
      begin
         fh:=FileOpen(tmpFileName,fmShareDenyNone);
         ok:=(fh<>-1);
         if ok then
            begin
               FileSize:=fileseek(fh,int64(0),2);
               fileclose(fh);
            end;
         if not ok then
            begin
               ErrorCode:='0203302';
               ErrorText:='Open file to get size failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203301';
         ErrorText:='File not found: '+ansistring(tmpFileName);
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutInt64Goods('FileSize',FileSize)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02033: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_CreateFile;
var
   ok: boolean;
   tmpFileName,tmpstr: String;
   filesize: int64;
begin
   tmpFileName:=RequestPacket.GetStringGoods('FileName');
   tmpFileName:=GetAbsolutePath(NodeService.s_DefaultDir,tmpFileName);
   if RequestPacket.GetGoodsType('FileSize')=gtInt64 then
      fileSize:=RequestPacket.GetInt64Goods('FileSize')
   else
      fileSize:=RequestPacket.GetIntegerGoods('FileSize');
   ok:=(FileSize>=0);
   if ok then
      begin
         tmpstr:=extractfiledir(tmpFileName);
         ok:=directoryexists(tmpstr);
         if not ok then
            begin
               try
                  SysUtils.ForceDirectories(tmpstr);
                  ok:=true;
               except
                  ok:=false;
               end;
            end;
         if ok then
            try
               ok:=CreateFileOnDisk(tmpFileName,FileSize);
            except
               ok:=false;
            end;
         if not ok then
            begin
               ErrorCode:='0203402';
               ErrorText:='Create file failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203401';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02034: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

function TTaskThread.CreateFileOnDisk(const FileName: String; const Size: Int64): Boolean;
var
   F: integer;
   h: integer;
begin
   F := FileCreate(FileName);
   if f<>-1 then
      begin
         if Size>0 then
            begin
               h:=Int64Rec(Size).Hi;
               result:=(SetFilePointer(F, Int64Rec(Size).Lo, @h, FILE_BEGIN)<>$FFFFFFFF);
               if result then
                  Result:=SetEndOfFile(F);
            end
         else
            result:=true;
         FileClose(F);
      end
   else
      begin
         FileSetAttr(FileName,faArchive);
         if fileexists(FileName) then
            begin
               if DeleteFile(FileName) then
                  begin
                     result:=(Integer(FileCreate(FileName))<>-1);
                     if result then
                        begin
                           if Size>0 then
                              begin
                                 h:=Int64Rec(Size).Hi;
                                 result:=(SetFilePointer(F, Int64Rec(Size).Lo, @h, FILE_BEGIN)<>$FFFFFFFF);
                                 if result then
                                    Result:=SetEndOfFile(F);
                              end;
                           FileClose(F);
                        end;
                  end
               else
                  result:=false;
            end
         else
            result:=false;
      end;
end;

procedure TTaskThread.Task_ReadFileBlock;
var
   ok,IsCompressed: boolean;
   tmpFileName: String;
   fh,BlockSize: integer;
   BlockOffset: int64;
   Stream1,Stream2: TMemoryStream;
begin
   try
      tmpFileName:=RequestPacket.GetStringGoods('FileName');
      tmpFileName:=GetAbsolutePath(NodeService.s_DefaultDir,tmpFileName);
      if RequestPacket.GetGoodsType('BlockOffset')=gtInt64 then
         BlockOffset:=RequestPacket.GetInt64Goods('BlockOffset')
      else
         BlockOffset:=RequestPacket.GetIntegerGoods('BlockOffset');
      BlockSize:=RequestPacket.GetIntegerGoods('BlockSize');
      if RequestPacket.GoodsExists('IsCompressed') then
         IsCompressed:=RequestPacket.GetBooleanGoods('IsCompressed')
      else
         IsCompressed:=false;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      ok:=((BlockSize>0) and (BlockOffset>=0) and FileExists(tmpFileName));
   except
      ok:=false;
   end;
   if ok then
      begin
         fh:=fileopen(tmpfilename,fmOpenRead or fmShareDenyWrite);
         ok:=(fh<>-1);
         if ok then
            begin
               if IsCompressed then
                  begin
                     Stream1:=nil;
                     Stream2:=nil;
                     try
                        Stream1:=TMemoryStream.Create;
                        Stream2:=TMemoryStream.Create;
                        Stream1.SetSize(BlockSize);
                        Stream1.Position:=0;
                        FileSeek(fh,BlockOffset,0);
                        ok:=(FileRead(fh,Stream1.Memory^,BlockSize)=BlockSize);
                        if ok then
                           begin
                              Stream1.Position:=0;
                              ok:=CompressStream(Stream1,Stream2);
                              if ok then
                                 ok:=BackPacket.PutStreamGoods('BlockData',Stream2);
                           end;
                     except
                        ok:=false;
                     end;
                     if assigned(Stream1) then
                        FreeAndNil(Stream1);
                     if assigned(Stream2) then
                        FreeAndNil(Stream2);
                  end
               else
                  begin
                     try
                        FileSeek(fh,BlockOffset,0);
                        ok:=BackPacket.PutFileBlockGoods('BlockData',fh,BlockSize);
                     except
                        ok:=false;
                     end;
                  end;
               FileClose(fh);
            end;
         if not ok then
            begin
               ErrorCode:='0203502';
               ErrorText:='Read file block failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203501';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02035: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_WriteFileBlock;
var
   ok,IsCompressed: boolean;
   tmpFileName: String;
   fh,BlockSize: integer;
   BlockOffset: int64;
   Stream1,Stream2: TMemoryStream;
begin
   try
      tmpFileName:=RequestPacket.GetStringGoods('FileName');
      tmpFileName:=GetAbsolutePath(NodeService.s_DefaultDir,tmpFileName);
      if RequestPacket.GetGoodsType('BlockOffset')=gtInt64 then
         BlockOffset:=RequestPacket.GetInt64Goods('BlockOffset')
      else
         BlockOffset:=RequestPacket.GetIntegerGoods('BlockOffset');
      BlockSize:=RequestPacket.GetIntegerGoods('BlockSize');
      if RequestPacket.GoodsExists('IsCompressed') then
         IsCompressed:=RequestPacket.GetBooleanGoods('IsCompressed')
      else
         IsCompressed:=false;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      ok:=((BlockSize>0) and (BlockOffset>=0) and FileExists(tmpFileName));
   except
      ok:=false;
   end;
   if ok then
      begin
         fh:=fileopen(tmpfilename,fmOpenWrite or fmShareDenyNone);
         ok:=(fh<>-1);
         if ok then
            begin
               FileSeek(fh,BlockOffset,0);
               if IsCompressed then
                  begin
                     Stream1:=nil;
                     Stream2:=nil;
                     try
                        Stream1:=TMemoryStream.Create;
                        Stream2:=TMemoryStream.Create;
                        ok:=RequestPacket.GetStreamGoods('BlockData',Stream1);
                        if ok then
                           begin
                              Stream1.Position:=0;
                              ok:=DecompressStream(Stream1,Stream2);
                              if ok then
                                 begin
                                    Stream2.Position:=0;
                                    ok:=(FileWrite(fh,Stream2.Memory^,Stream2.Size)=Stream2.Size);
                                 end;
                           end;
                     except
                        ok:=false;
                     end;
                     if assigned(Stream1) then
                        FreeAndNil(Stream1);
                     if assigned(Stream2) then
                        FreeAndNil(Stream2);
                  end
               else
                  begin
                     try
                        ok:=RequestPacket.GetFileBlockGoods('BlockData',fh);
                     except
                        ok:=false;
                     end;
                  end;
               fileclose(fh);
            end;
         if not ok then
            begin
               ErrorCode:='0203602';
               ErrorText:='Write file block failed';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203601';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02036: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchScheduleList;
var
   ok: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleId';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleName';
               DataType:=ftWideString;
               Size:=36;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleFilename';
               DataType:=ftWideString;
               Size:=96;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleParameters';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='SchedulePassword';
               DataType:=ftWideString;
               Size:=16;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleExecMode';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleReturnMode';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleStartupTime';
               DataType:=ftWideString;
               Size:=8;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ScheduleExecInterval';
               DataType:=ftInteger;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.ScheduleListToCds(Cds);
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0203701';
            ErrorText:='Zip schedule list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('ScheduleCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('ScheduleList',Stream);
            if not ok then
               begin
                  ErrorCode:='0203701';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02037: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_AddSchedule;             
var
   ok: boolean;
   tmpSchedule: TScheduleTaskRecord;
begin
   tmpSchedule.ScheduleId:=RequestPacket.GetEncryptStringGoods('ScheduleId');
   tmpSchedule.ScheduleName:=RequestPacket.GetEncryptStringGoods('ScheduleName');
   tmpSchedule.ScheduleFilename:=RequestPacket.GetStringGoods('ScheduleFilename');
   tmpSchedule.SchedulePassword:=RequestPacket.GetEncryptStringGoods('SchedulePassword');
   tmpSchedule.ScheduleParameters:=RequestPacket.GetEncryptStringGoods('ScheduleParameters');
   tmpSchedule.ScheduleExecMode:=RequestPacket.GetIntegerGoods('ScheduleExecMode');
   tmpSchedule.ScheduleReturnMode:=RequestPacket.GetIntegerGoods('ScheduleReturnMode');
   tmpSchedule.ScheduleStartupTime:=RequestPacket.GetEncryptStringGoods('ScheduleStartupTime');
   tmpSchedule.ScheduleExecInterval:=RequestPacket.GetIntegerGoods('ScheduleExecInterval');
   ok:=(not ((trim(tmpSchedule.ScheduleId)='') or (trim(tmpSchedule.ScheduleName)='') or (trim(tmpSchedule.ScheduleFileName)='')
        or (tmpSchedule.ScheduleExecMode<=0) or (length(tmpSchedule.ScheduleStartupTime)>8) or (tmpSchedule.ScheduleReturnMode<1)
        or (tmpSchedule.ScheduleReturnMode>2)));
   if ok then
      begin
         ok:=NodeService.AddSchedule(tmpSchedule);
         if not ok then
            begin
               ErrorCode:='0203802';
               ErrorText:='Schedule Id already exists.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203801';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02038: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_UpdateSchedule;          
var
   ok: boolean;
   tmpSchedule: TScheduleTaskRecord;
   OldScheduleId: AnsiString;
begin
   oldScheduleId:=RequestPacket.GetEncryptStringGoods('OldScheduleId');
   tmpSchedule.ScheduleId:=RequestPacket.GetEncryptStringGoods('ScheduleId');
   tmpSchedule.ScheduleName:=RequestPacket.GetEncryptStringGoods('ScheduleName');
   tmpSchedule.ScheduleFilename:=RequestPacket.GetStringGoods('ScheduleFilename');
   tmpSchedule.SchedulePassword:=RequestPacket.GetEncryptStringGoods('SchedulePassword');
   tmpSchedule.ScheduleParameters:=RequestPacket.GetEncryptStringGoods('ScheduleParameters');
   tmpSchedule.ScheduleExecMode:=RequestPacket.GetIntegerGoods('ScheduleExecMode');
   tmpSchedule.ScheduleReturnMode:=RequestPacket.GetIntegerGoods('ScheduleReturnMode');
   tmpSchedule.ScheduleStartupTime:=RequestPacket.GetEncryptStringGoods('ScheduleStartupTime');
   tmpSchedule.ScheduleExecInterval:=RequestPacket.GetIntegerGoods('ScheduleExecInterval');
   ok:=(not ((trim(OldScheduleId)='') or (trim(tmpSchedule.ScheduleId)='') or (trim(tmpSchedule.ScheduleName)='') or (trim(tmpSchedule.ScheduleFileName)='')
        or (tmpSchedule.ScheduleExecMode<=0) or (length(tmpSchedule.ScheduleStartupTime)>8) or (tmpSchedule.ScheduleReturnMode<1)
        or (tmpSchedule.ScheduleReturnMode>2)));
   if ok then
      begin
         ok:=NodeService.UpdateSchedule(OldScheduleId,tmpSchedule);
         if not ok then
            begin
               ErrorCode:='0203902';
               ErrorText:='Old schedule task not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0203901';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02039: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RemoveSchedule;          
var
   ok: boolean;
   OldScheduleId: AnsiString;
begin
   oldScheduleId:=RequestPacket.GetEncryptStringGoods('ScheduleId');
   ok:=(trim(OldScheduleId)<>'');
   if ok then
      begin
         ok:=NodeService.RemoveSchedule(OldScheduleId);
         if not ok then
            begin
               ErrorCode:='0204002';
               ErrorText:='Old schedule task not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0204001';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02040: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RunSchedule;
var
   ok: boolean;
   OldScheduleId,OldSchedulePassword,ReturnValue: AnsiString;
begin
   oldScheduleId:=RequestPacket.GetEncryptStringGoods('ScheduleId');
   oldSchedulePassword:=RequestPacket.GetEncryptStringGoods('SchedulePassword');
   ok:=(trim(OldScheduleId)<>'');
   if ok then
      begin
         ok:=NodeService.ExecuteSchedule(OldScheduleId,OldSchedulePassword,ReturnValue);
         if not ok then
            begin
               ErrorCode:='0204102';
               ErrorText:='Old schedule task not found or password incorrect.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0204101';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutEncryptStringGoods('ReturnValue',ReturnValue)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02041: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RunExternalProgram;
var
   ok: boolean;
   PrgFilename: string;
   Parameters: string;
   ReturnType: integer;
   ReturnValue: AnsiString;
begin
   PrgFileName:=RequestPacket.GetStringGoods('ProgramFilename');
   Parameters:=RequestPacket.GetStringGoods('Parameters');
   ReturnType:=RequestPacket.GetIntegerGoods('ReturnMode');
   ok:=((ReturnType=1) or (ReturnType=2));
   if ok then
      begin
         ok:=ExecuteExternalProgram(PrgFileName,Parameters,ReturnType,ReturnValue);
         if not ok then
            begin
               ErrorCode:='0204202';
               ErrorText:='Error detected on execute external program.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0204201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutEncryptStringGoods('ReturnValue',ReturnValue)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02042: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchDatabaseList;
var
  ok: boolean;
  Cds: TClientDataset;
  Stream: TMemoryStream;
  err: string;
begin
  Cds:=TClientDataset.Create(nil);
  Cds.DisableControls;
  with Cds do
  begin
    with FieldDefs.AddFieldDef do      //添加客户名称
    Begin
      Name := 'ClientName';
      DataType := ftWideString;
      Size := 40;
    End;
    with FieldDefs.AddFieldDef do      //帐套名称
    begin
       Name:='DatabaseId';
       DataType:=ftWideString;
       Size:=32;
    end;
    with FieldDefs.AddFieldDef do
    begin
       Name:='DatabaseDesc';
       DataType:=ftWideString;
       Size:=48;
    end;
    with FieldDefs.AddFieldDef do
    begin
       Name:='DatabaseType';
       DataType:=ftInteger;
    end;
    with FieldDefs.AddFieldDef do
    begin
       Name:='DatabaseProvider';
       DataType:=ftWideString;
       Size:=36;
    end;
    with FieldDefs.AddFieldDef do       //数据库服务器地址
    begin
       Name:='Server';
       DataType:=ftWideString;
       Size:=50;
    end;
    with FieldDefs.AddFieldDef do
    Begin
      Name := 'UserName';
      DataType := ftWideString;
      Size := 50;
    End;
    with FieldDefs.AddFieldDef do
    Begin
      Name := 'PassWord';
      DataType := ftWideString;
      Size := 30;
    End;
    with FieldDefs.AddFieldDef Do
    Begin
      Name := 'Database';
      DataType := ftWideString;
      Size := 50;
    End;
    CreateDataSet;
  end;
  Cds.Open;
  NodeService.DatabaseListToCds(Cds);
  try
    Stream:=TMemoryStream.Create;
    ok:=CdsZipToStream(Cds,Stream,err);
    if not ok then
    begin
      ErrorCode:='0204301';
      ErrorText:='压缩数据库列表失败: '+ansistring(err);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
    end;
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      BackPacket.PutIntegerGoods('DatabaseCount',Cds.RecordCount);
      ok:=BackPacket.PutStreamGoods('DatabaseList',Stream);
      if not ok then
      begin
        ErrorCode:='0204301';
        ErrorText:='返回列表失败。';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
    end;
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
      NodeService.syslog.Log('Err02043: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
  FreeAndNil(Cds)
end;

procedure TTaskThread.Task_AddDatabase;
var
  ok: boolean;
  tmpClientName:AnsiString;
  tmpDatabaseId,tmpDatabaseDesc,tmpDatabaseProvider,tmpServer,tmpUsername,tmpPassword,tmpDatabase: ansistring;
  tmpDatabaseType: integer;
begin
  tmpClientName:=RequestPacket.GetStringGoods('ClientName');
  tmpDatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  tmpDatabaseDesc:=RequestPacket.GetEncryptStringGoods('DatabaseDescription');
  tmpDatabaseType:=RequestPacket.GetIntegerGoods('DatabaseType');
  tmpDatabaseProvider:=RequestPacket.GetEncryptStringGoods('DatabaseProvider');
  tmpServer := requestPacket.GetEncryptStringGoods('Server');
  tmpUsername := RequestPacket.GetEncryptStringGoods('UserName');
  tmpPassword := RequestPacket.GetEncryptStringGoods('Password');
  tmpDatabase := RequestPacket.GetEncryptStringGoods('Database');
  ok:=(not ((trim(tmpDatabaseId)='') or (trim(tmpDatabaseProvider)='') or (trim(tmpServer)='')
       or (trim(tmpServer)='') or (Trim(tmpUsername)='') or (trim(tmpPassword)='') or (trim(tmpDatabase)='')));
  if ok then
  begin
    ok:=NodeService.AddDatabase(tmpClientName,tmpDatabaseId,tmpDatabaseDesc,tmpDatabaseType,
                    tmpDatabaseProvider,tmpServer,tmpUsername,tmpPassword,tmpDatabase);
    if not ok then
    begin
       ErrorCode:='0204402';
       ErrorText:='数据库标识已存在。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
    end;
  end
  else
  begin
    ErrorCode:='0204401';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02044: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_UpdateDatabase;
var
  ok: boolean;
  tmpClientName:AnsiString;
  oldDatabaseId,tmpDatabaseId,tmpDatabaseDesc,tmpDatabaseProvider,tmpServer,tmpUserName,tmppassword,tmpDatabase: ansistring;
  tmpDatabaseType: integer;
begin
  tmpClientName := RequestPacket.GetStringGoods('ClientName');
  OldDatabaseId:=RequestPacket.GetEncryptStringGoods('OldDatabaseId');
  tmpDatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  tmpDatabaseDesc:=RequestPacket.GetEncryptStringGoods('DatabaseDescription');
  tmpDatabaseType:=RequestPacket.GetIntegerGoods('DatabaseType');
  tmpDatabaseProvider:=RequestPacket.GetEncryptStringGoods('DatabaseProvider');
  tmpServer := RequestPacket.GetEncryptStringGoods('Server');
  tmpUserName := RequestPacket.GetEncryptStringGoods('UserName');
  tmppassword := RequestPacket.GetEncryptStringGoods('Password');
  tmpDatabase := RequestPacket.GetEncryptStringGoods('Database');
  ok:=(not ((trim(OldDatabaseId)='') or (trim(tmpDatabaseId)='') or (trim(tmpDatabaseProvider)='') or
        (trim(tmpServer)='') or (trim(tmpUserName)='') or (trim(tmppassword)='') or (trim(tmpDatabase)='')));
  if ok then
  begin
    ok:=NodeService.UpdateDatabase(tmpClientName, OldDatabaseId, tmpDatabaseId,tmpDatabaseDesc,tmpDatabaseType,tmpDatabaseProvider,
                tmpServer, tmpUserName, tmpPassWord, tmpDatabase);
    if not ok then
    begin
       ErrorCode:='0204502';
       ErrorText:='要修改的数据库标识(帐套名称)不存在！';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    end;
  end
  else
  begin
    ErrorCode:='0204501';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02045: 创建信息反馈结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_RemoveDatabase;
var
   ok: boolean;
   tmpDatabaseId: ansistring;
begin
   tmpDatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
   ok:=(trim(tmpDatabaseId)<>'');
   if ok then
      begin
         ok:=NodeService.RemoveDatabase(tmpDatabaseId);
         if not ok then
            begin
               ErrorCode:='0204602';
               ErrorText:='Database not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0204601';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02046: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_TestDatabase;
var
   ok: boolean;
   tmpDatabaseId: ansistring;
   Err: string;
begin
   tmpDatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
   ok:=(trim(tmpDatabaseId)<>'');
   if ok then
      begin
         ok:=TestDatabase(tmpDatabaseId,Err);
         if not ok then
            begin
               ErrorCode:='0204702';
               ErrorText:='Test database failed. Fail reason='+ansistring(err);
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0204701';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02047: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_TestExternalDatabase;
var
  ok: boolean;
  tmpProvider,tmpServer,tmpUsername,tmpPassword,tmpDatabase,Err: string;
begin
  tmpProvider:=RequestPacket.GetStringGoods('Provider');
  if (tmpProvider ='MSSQL') then tmpProvider:='SQL Server';

  tmpServer := RequestPacket.GetStringGoods('Server');
  tmpUsername := RequestPacket.GetStringGoods('Username');
  tmpPassword := RequestPacket.GetStringGoods('PassWord');
  tmpDatabase := RequestPacket.GetStringGoods('Database');
  ok:=(trim(tmpProvider)<>'') and (trim(tmpServer)<>'') and (trim(tmpUsername)<>'') Or
          (trim(tmpPassword)<>'') or (trim(tmpDatabase)<>'') ;
  if ok then
  begin
    ok:=TestExtDatabase(tmpProvider,tmpServer,tmpUsername, tmpPassword, tmpDatabase,Err);
    if not ok then
    begin
      ErrorCode:='0204802';
      ErrorText:='测试外部数据库失败，失败原因：='+ansistring(err);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
    end;
  end
  else
  begin
    ErrorCode:='0204801';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02048: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_FetchPluginList;
var
   ok: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginId';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginDesc';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginFilename';
               DataType:=ftWideString;
               Size:=96;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginPassword';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginThreadMode';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginExecMode';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='LoadCount';
               DataType:=ftInteger;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.PluginListToCds(Cds);
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0204901';
            ErrorText:='Zip plugin list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('PluginCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('PluginList',Stream);
            if not ok then
               begin
                  ErrorCode:='0204901';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02049: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.AddPlugin;
begin
   tmpResult:=NodeService.AddPlugin(tmpPlugin);
end;

procedure TTaskThread.Task_AddPlugin;
var
   ok: boolean;
begin
   tmpPlugin.PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   tmpPlugin.PluginDesc:=RequestPacket.GetEncryptStringGoods('PluginDescription');
   tmpPlugin.PluginFilename:=RequestPacket.GetStringGoods('PluginFilename');
   tmpPlugin.PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
   tmpPlugin.PluginThreadMode:=RequestPacket.GetIntegerGoods('PluginThreadMode');
   tmpPlugin.PluginExecMode:=RequestPacket.GetIntegerGoods('PluginExecMode');
   ok:=(not ((trim(tmpPlugin.PluginId)='') or (trim(tmpPlugin.PluginFilename)='')));
   ok:=ok and FileExists(NodeService.s_DefaultDir+'plugins\'+tmpPlugin.PluginFilename);
   if ok then
      begin
         Synchronize(AddPlugin);
         ok:=tmpResult;
         if not ok then
            begin
               ErrorCode:='0205002';
               ErrorText:='Plugin Id already exists.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0205001';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02050: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.UpdatePlugin;
begin
   tmpResult:=NodeService.UpdatePlugin(OldPluginId,tmpPlugin);
end;

procedure TTaskThread.Task_UpdatePlugin;
var
   ok: boolean;
begin
   OldPluginId:=RequestPacket.GetEncryptStringGoods('OldPluginId');
   tmpPlugin.PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   tmpPlugin.PluginDesc:=RequestPacket.GetEncryptStringGoods('PluginDescription');
   tmpPlugin.PluginFilename:=RequestPacket.GetStringGoods('PluginFilename');
   tmpPlugin.PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
   tmpPlugin.PluginThreadMode:=RequestPacket.GetIntegerGoods('PluginThreadMode');
   tmpPlugin.PluginExecMode:=RequestPacket.GetIntegerGoods('PluginExecMode');
   ok:=(not ((trim(OldPluginId)='') or (trim(tmpPlugin.PluginId)='') or (trim(tmpPlugin.PluginFilename)='')));
   ok:=ok and FileExists(NodeService.s_DefaultDir+'plugins\'+tmpPlugin.PluginFilename);
   if ok then
      begin
         Synchronize(UpdatePlugin);
         ok:=tmpResult;
         if not ok then
            begin
               ErrorCode:='0205102';
               ErrorText:='Old plugin nou found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0205101';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02051: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RemovePlugin;
var
   ok: boolean;
   OldPluginId: AnsiString;
begin
   OldPluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   ok:=(trim(OldPluginId)<>'');
   if ok then
      begin
         ok:=NodeService.RemovePlugin(OldPluginId);
         if not ok then
            begin
               ErrorCode:='0205202';
               ErrorText:='Old plugin not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0205201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02052: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_BinaryRPC;               
var
   ok: boolean;
   PluginId,PluginPassword,DatabaseId: AnsiString;
   Stream,Stream1: TMemoryStream;
   InPacket,OutPacket: TwxdPacket;
begin
   InPacket:=TwxdPacket.Create;
   OutPacket:=nil;
   Stream:=nil;
   stream1:=nil;
   try
      Stream:=TMemoryStream.Create;
      stream1:=TMemoryStream.Create;
      PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
      PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
      DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
      ok:=RequestPacket.GetStreamGoods('InPacketStream',Stream);
      ok:=ok and (stream.Size>0) and (trim(PluginId)<>'');
   except
      ok:=false;
   end;
   if ok then
      begin
         try
            Stream.Position:=0;
            DecompressStream(Stream,Stream1);
            ok:=(stream1.size>0);
            if ok then
               begin
                  Stream1.Position:=0;
                  ok:=InPacket.LoadFromStream(Stream1);
               end;
            if not ok then
               begin
                  ErrorCode:='0205305';
                  ErrorText:='Unzip InPacket failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         except
            on e: exception do
               begin
                  ok:=false;
                  ErrorCode:='0205304';
                  ErrorText:='Unzip InPacket failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
         if ok then
            begin
               try
                  InPacket.PutAnsiStringGoods('Client_Ip_Address',Socket.RemoteAddress);
                  ok:=RPCProcess(PluginId,PluginPassword,DatabaseId,InPacket,OutPacket);
                  if not ok then
                     begin
                        ErrorCode:='0205302';
                        ErrorText:='Call plugin function failed.';
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     end;
               except
                  on e: exception do
                     begin
                        ok:=false;
                        ErrorCode:='0205303';
                        ErrorText:='Call plugin function failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     end;
               end;
            end;
      end
   else
      begin
         ErrorCode:='0205301';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   if ok then
      begin
         if OutPacket<>nil then
            begin
               try
                  Stream.Clear;
                  Stream1.Clear;
                  ok:=OutPacket.SaveToStream(Stream);
                  if ok then
                     begin
                        Stream.Position:=0;
                        CompressStream(Stream,Stream1);
                        Stream1.Position:=0;
                        ok:=BackPacket.PutStreamGoods('OutPacketStream',Stream1);
                        if not ok then
                           begin
                              ErrorCode:='0205307';
                              ErrorText:='Compress output Packet failed.';
                              NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                              NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                           end;
                     end;
               except
                  on e: exception do
                     begin
                        ok:=false;
                        ErrorCode:='0205306';
                        ErrorText:='Compress output Packet failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     end;
               end;
            end
         else
            ok:=true;
         try
            if ok then
               BackPacket.PutBooleanGoods('ProcessResult',true)
            else
               begin
                  BackPacket.PutBooleanGoods('ProcessResult',false);
                  BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
                  BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
               end;
         except
            on e: exception do
               NodeService.syslog.Log('Err02053: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end
   else
      begin
         try
            BackPacket.PutBooleanGoods('ProcessResult',false);
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         except
            on e: exception do
               NodeService.syslog.Log('Err02053: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   try
      if assigned(Stream) then
         FreeAndNil(Stream);
      if assigned(Stream1) then
         FreeAndNil(Stream1);
      FreeAndNil(InPacket);
      if OutPacket<>nil then
         FreeAndNil(OutPacket);
   except
   end;
end;

procedure TTaskThread.Task_BinaryRPCAnsyc;               
var
   ok: boolean;
   PluginId,PluginPassword,DatabaseId,DllFileName: AnsiString;
   Stream,Stream1: TMemoryStream;
   InPacket: TwxdPacket;
   i,j: integer;
begin
   Stream:=nil;
   Stream1:=nil;
   InPacket:=nil;
   try
      Stream:=TMemoryStream.Create;
      PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
      PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
      DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
      ok:=RequestPacket.GetStreamGoods('InPacketStream',Stream);
      ok:=ok and (stream.Size>0) and (trim(PluginId)<>'');
   except
      ok:=false;
   end;
   if not ok then
      begin
         try
            BackPacket.EncryptKey:=NodeService.s_TransferKey;
            BackPacket.PutBooleanGoods('ProcessResult',false);
            BackPacket.PutEncryptStringGoods('ErrorCode','0214406');
            BackPacket.PutEncryptStringGoods('ErrorText','Invalid request parameters.');
         except
         end;
         if assigned(Stream) then
            FreeAndNil(Stream);
         exit;
      end;
   InPacket:=TwxdPacket.Create;
   try
      stream1:=TMemoryStream.Create;
      Stream.Position:=0;
      DecompressStream(Stream,Stream1);
      ok:=(stream1.size>0);
      if ok then
         begin
            Stream1.Position:=0;
            ok:=InPacket.LoadFromStream(Stream1);
         end;
      if not ok then
         begin
            ErrorCode:='0214405';
            ErrorText:='Unzip InPacket failed.';
            FreeAndNil(InPacket);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         begin
            ok:=false;
            ErrorCode:='0214404';
            ErrorText:='Unzip InPacket failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
            FreeAndNil(InPacket);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   end;
   if assigned(Stream1) then
      FreeAndNil(Stream1);
   if assigned(Stream) then
      FreeAndNil(Stream);
   if ok then
      begin
         EnterCriticalSection(NodeService.PluginListCs);
         j:=-1;
         for i:=0 to NodeService.PluginCount-1 do
            if NodeService.Plugins[i].used and ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginId),PAnsiChar(NodeService.Plugins[i].PluginId))=0)
               and ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginPassword),PAnsiChar(NodeService.Plugins[i].PluginPassword))=0) then
               begin
                  j:=i;
                  break;
               end;
         ok:=(j<>-1);
         if not ok then
            begin
               LeaveCriticalSection(NodeService.PluginListCs);
               ErrorCode:='0214403';
               ErrorText:='Plugin ['+PluginId+'] not found!';
               FreeAndNil(InPacket);
               NodeService.syslog.Log('Err0200012: Plugin ['+PluginId+'] not found!');
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end
         else
            begin
               DllFileName:=AnsiString(NodeService.s_defaultdir+'plugins\'+NodeService.Plugins[j].PluginFilename);
               LeaveCriticalSection(NodeService.PluginListCs);
               try
                  InPacket.PutAnsiStringGoods('Request_UserId',RequestUserId+'@'+RequestNodeId);
                  InPacket.PutAnsiStringGoods('ClientIpAddress',FromIpAddr);
                  TTriggerThread.Create(dllfilename,InPacket,false);
               except
                  on e: exception do
                     begin
                        ok:=false;
                        ErrorCode:='0214402';
                        ErrorText:='Startup plugin failed: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                        FreeAndNil(InPacket);
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                     end;
               end;
            end;
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02144: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.PreloadPlugin;
begin
   try
      l_result:=NodeService.PreloadLibrary(l_DllFileName,l_dllIndex);
   except
   end;
end;

function TTaskThread.RpcProcess(const aPluginId: AnsiString; const aPluginPassword: AnsiString; const aDatabaseId: ansistring; const InPacket: TwxdPacket; var OutPacket: TwxdPacket): boolean;
var
   i,j,k: integer;
   dllIndex: integer;
   ok: boolean;
   TmpPacket: TwxdPacket;
   InitProc: pointer;
   ApiInitProc: TApiInitProc;
   DllFilename: String;
   ThreadMode: integer;                  
   ExecMode: integer;                    
   ProcAddress: Pointer;                 
   RemoteFunction: TProcFunction;        
   h: integer;
begin
   TmpPacket:=nil;
   EnterCriticalSection(NodeService.PluginListCs);
   try
      j:=-1;
      for i:=0 to NodeService.PluginCount-1 do
         if NodeService.Plugins[i].Used and ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aPluginId),PAnsiChar(NodeService.Plugins[i].PluginId))=0)
            and ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aPluginPassword),PAnsiChar(NodeService.Plugins[i].PluginPassword))=0) then
            begin
               j:=i;
               break;
            end;
      if j=-1 then
         begin
            LeaveCriticalSection(NodeService.PluginListCs);
            NodeService.syslog.Log('Err0200012: Plugin ['+aPluginId+'] not found!');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            result:=false;
            exit;
         end;
      if (NodeService.Plugins[j].PluginExecMode=1) and (NodeService.Plugins[j].PluginHandle=0) then
         begin
            try
               NodeService.Plugins[j].PluginHandle:=Loadlibrary(pchar(NodeService.s_defaultdir+'plugins\'+NodeService.Plugins[j].PluginFilename));
            except
               NodeService.Plugins[j].PluginHandle:=0;
            end;
            if NodeService.Plugins[j].PluginHandle<>0 then
               begin
                  InitProc:=GetProcAddress(NodeService.Plugins[j].PluginHandle,'ApiInitialize');
                  if InitProc<>nil then
                     begin
                        TmpPacket:=TwxdPacket.Create;
                        try
                           TmpPacket.PutIntegerGoods('Callback_Proc_List',integer(@NodeService.ExportAddrList[0]));
                           TmpPacket.PutAnsiStringGoods('Transfer_Key',NodeService.s_TransferKey);
                           TmpPacket.PutAnsiStringGoods('ThisNodeId',NodeService.s_ThisNodeId);
                           ApiInitProc:=TApiInitProc(InitProc);
                           ApiInitProc(integer(Pointer(TmpPacket)));
                        except
                           on e: exception do
                              NodeService.syslog.Log('Err0200016: Call initialize function of ['+aPluginId+'] failed: ['+ansistring(e.classname)+']-'+ansistring(e.message));
                        end;
                        FreeAndNil(TmpPacket);
                     end;
                  NodeService.Plugins[j].PluginProcAddress:=GetProcAddress(NodeService.Plugins[j].PluginHandle,'RemoteProcess');
                  if NodeService.Plugins[j].PluginProcAddress=nil then
                     begin
                        FreeLibrary(NodeService.Plugins[j].PluginHandle);
                        NodeService.Plugins[j].PluginHandle:=0;
                        NodeService.Plugins[j].LoadCount:=0;
                     end
                  else
                     NodeService.Plugins[j].LoadCount:=1;
               end
            else
               begin
                  NodeService.Plugins[j].PluginProcAddress:=nil;
                  NodeService.Plugins[j].LoadCount:=0;
               end;
            if NodeService.Plugins[j].PluginHandle=0 then
               begin
                  LeaveCriticalSection(NodeService.PluginListCs);
                  NodeService.syslog.Log('Err0200014: Call plugin ['+aPluginId+'] failed because it loaded failed.');
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  result:=false;
                  exit;
               end;
         end;
      if (NodeService.Plugins[j].PluginExecMode=2) and (NodeService.Plugins[j].LoadCount<=0) then
         begin
            LeaveCriticalSection(NodeService.PluginListCs);
            NodeService.syslog.Log('Err0200015: Plugin ['+aPluginId+'] not loaded!');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            result:=false;
            exit;
         end;
      NodeService.Plugins[j].LastActiveTime:=now;
      DllFilename:=NodeService.s_defaultdir+'plugins\'+NodeService.Plugins[j].PluginFilename;
      ThreadMode:=NodeService.Plugins[j].PluginThreadMode;
      ExecMode:=NodeService.Plugins[j].PluginExecMode;
      ProcAddress:=NodeService.Plugins[j].PluginProcAddress;
      h:=NodeService.Plugins[j].PluginHandle;
      ok:=true;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.PluginListCs);
   if not ok then
      begin
         NodeService.syslog.Log('Err0200016: Get plugin ['+aPluginId+'] parameters failed!');
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         result:=false;
         exit;
      end;
   if ExecMode=0 then
      begin
         l_DllFileName:=DllFileName;
         EnterCriticalSection(NodeService.MyPluginCs);
         Synchronize(PreloadPlugin);
         LeaveCriticalSection(NodeService.MyPluginCs);
         dllindex:=l_dllIndex;
         try
            h:=Loadlibrary(pchar(DllFilename));
         except
            on e: exception do
               begin
                  NodeService.syslog.Log('Err0200016: Load ['+aPluginId+'] failed: ['+ansistring(e.classname)+']-'+ansistring(e.message));
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  h:=0;
               end;
         end;
         if h<>0 then
            begin
               ProcAddress:=GetProcAddress(h,'RemoteProcess');
               if ProcAddress=nil then
                  begin
                     FreeLibrary(h);
                     ok:=false;
                  end
               else
                  ok:=true;
            end
         else
            ok:=false;
         if not ok then
            begin
               if DllIndex<>-1 then
                  NodeService.SetMyPluginActiveTime(DllIndex);
               NodeService.syslog.Log('Err0200016: Load plugin ['+aPluginId+'] failed!');
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               result:=false;
               exit;
            end;
      end;
   if ThreadMode=1 then
      EnterCriticalSection(NodeService.Plugins[j].PluginModuleCs);
   try
      InPacket.PutAnsiStringGoods('Dll_Filename',Ansistring(DllFilename));
      InPacket.PutIntegerGoods('Callback_Proc_List',integer(@nodeservice.ExportAddrList[0]));
      InPacket.PutAnsiStringGoods('Transfer_Key',NodeService.s_TransferKey);
      InPacket.PutAnsiStringGoods('Request_UserId',RequestUserId+'@'+RequestNodeId);
      InPacket.PutAnsiStringGoods('ClientIpAddress',FromIpAddr);
      InPacket.PutAnsiStringGoods('ThisNodeId',NodeService.s_ThisNodeId);
      k:=0;
      RemoteFunction:=TProcFunction(ProcAddress);
      ok:=RemoteFunction(integer(Pointer(InPacket)),k);
      if ok and (k<>0) then
         begin
            OutPacket:=Mem2Packet(k);
            DllSpread.FreeMemory(k);
            ok:=(OutPacket<>nil);
         end;
      if not ok then
         begin
            NodeService.syslog.Log('Err0200016: Calling ['+aPluginId+'] plugin failed!');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         begin
            NodeService.syslog.Log('Err0200017: Calling ['+aPluginId+'] error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            ok:=false;
         end;
   end;
   if ThreadMode=1 then
      LeaveCriticalSection(NodeService.Plugins[j].PluginModuleCs);
   if ExecMode=0 then
      begin
         if dllIndex<>-1 then
            NodeService.SetMyPluginActiveTime(dllIndex);
         FreeLibrary(h);
      end;
   result:=ok;
end;

function TTaskThread.TransSessionIsValid(const TransSessionId: int64): boolean;
var
   j,k: integer;
   p: pointer;
begin
   p:=@TransSessionId;
   move(p^,j,4);
   p:=pointer(integer(@TransSessionId)+4);
   move(p^,k,4);
   result:=(j=k);
end;

procedure TTaskThread.SaveErrorResponse(const ErrCode: AnsiString; const ErrText: AnsiString);
begin
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',false);
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrText);
   except
      on e: exception do
         NodeService.syslog.Log('Err0200016: Save error response error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

function TTaskThread.IsSybase(const uniConn: TUniConnection): boolean;
var
   tmpstr: ansistring;
begin
   try
      tmpstr:=AnsiString(uppercase(UniConn.ProviderName));
      result:=(pos(AnsiString('SQL Server'),tmpstr)>0);
   except
      result:=true;
   end;
end;

procedure TTaskThread.PacketToParameters(const Packet: TwxdPacket; const uniSQL: TUniSQL);
var
  ParamName,ParamName1: AnsiString;
  i,j: integer;
  Stream: TMemoryStream;
begin
  for i := 0 to uniSQL.Params.Count - 1 do
  begin
    ParamName1:=AnsiString(uniSQL.Params[i].Name);
    ParamName:=':'+ParamName1;
    if not Packet.GoodsExists(ParamName) then
      continue;
    case Packet.GetGoodsType(ParamName) of
      gtNull: uniSQL.Params[i].Value:=null;
      gtByte: uniSQL.Params[i].Value:=Packet.GetByteGoods(ParamName);
      gtShortInt: uniSQL.Params[i].Value:=Packet.GetShortIntGoods(ParamName);
      gtWord: uniSQL.Params[i].Value:=Packet.GetWordGoods(ParamName);
      gtSmallInt: uniSQL.Params[i].Value:=Packet.GetSmallIntGoods(ParamName);
      gtLongWord: uniSQL.Params[i].Value:=Packet.GetLongWordGoods(ParamName);
      gtInteger: uniSQL.Params[i].Value:=Packet.GetIntegerGoods(ParamName);
      gtInt64: uniSQL.Params[i].Value:=Packet.GetInt64Goods(ParamName);
      gtBoolean: uniSQL.Params[i].Value:=Packet.GetBooleanGoods(ParamName);
      gtByteBool: uniSQL.Params[i].Value:=Packet.GetByteBoolGoods(ParamName);
      gtWordBool: uniSQL.Params[i].Value:=Packet.GetWordBoolGoods(ParamName);
      gtLongBool: uniSQL.Params[i].Value:=Packet.GetLongBoolGoods(ParamName);
      gtSingle: uniSQL.Params[i].Value:=Packet.GetSingleGoods(ParamName);
      gtReal: uniSQL.Params[i].Value:=Packet.GetRealGoods(ParamName);
      gtDouble: uniSQL.Params[i].Value:=Packet.GetDoubleGoods(ParamName);
      gtComp: uniSQL.Params[i].Value:=Packet.GetCompGoods(ParamName);
      gtCurrency: uniSQL.Params[i].Value:=Packet.GetCurrencyGoods(ParamName);
      gtExtended: uniSQL.Params[i].Value:=Packet.GetExtendedGoods(ParamName);
      gtDateTime: uniSQL.Params[i].Value:=Packet.GetDateTimeGoods(ParamName);
      gtDate: uniSQL.Params[i].Value:=Packet.GetDateGoods(ParamName);
      gtTime: uniSQL.Params[i].Value:=Packet.GetTimeGoods(ParamName);
      gtShortString:
      begin
        j:=length(Packet.GetShortStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniSQL.Params[i].Size:=255
           else
              uniSQL.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniSQL.Params[i].Size:=255;
        {$ENDIF}
        uniSQL.Params[i].Value:=Packet.GetShortStringGoods(ParamName);
      end;
      gtAnsiString:
      begin
        j:=length(Packet.GetAnsiStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniSQL.Params[i].Size:=255
           else
              uniSQL.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniSQL.Params[i].Size:=255;
        {$ENDIF}
        uniSQL.Params[i].Value:=Packet.GetAnsiStringGoods(ParamName);
      end;
      gtWideString:
      begin
        j:=length(Packet.GetWideStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniSQL.Params[i].Size:=255
           else
              uniSQL.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniSQL.Params[i].Size:=255;
        {$ENDIF}
        uniSQL.Params[i].Value:=Packet.GetWideStringGoods(ParamName);
      end;
      gtString:
      begin
        j:=length(Packet.GetStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniSQL.Params[i].Size:=255
           else
              uniSQL.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniSQL.Params[i].Size:=255;
        {$ENDIF}
        uniSQL.Params[i].Value:=Packet.GetStringGoods(ParamName);
      end;
      gtBinary:
      begin
        try
           Stream:=TMemoryStream.Create;
           Packet.GetStreamGoods(ParamName,Stream);
           Stream.Position:=0;
           uniSQL.Params[i].LoadFromStream(Stream,ftBlob);
           FreeAndNil(Stream);
        except
        end;
        if assigned(Stream) then
           FreeAndNil(Stream);
      end;
    end;
  end;
end;

//procedure TTaskThread.PacketToParameters(const Packet: TwxdPacket; const AdoDataset: TUniQuery);
//var
//   ParamName,ParamName1: AnsiString;
//   i,j: integer;
//   Stream: TMemoryStream;
//   Sybase: boolean;
//begin
//   Sybase:=IsSybase(AdoDataset.Connection);
//   for i := 0 to AdoDataset.Parameters.Count - 1 do
//      begin
//         ParamName1:=AnsiString(AdoDataset.Parameters[i].Name);
//         ParamName:=':'+ParamName1;
//         if not Packet.GoodsExists(ParamName) then
//            continue;
//         case Packet.GetGoodsType(ParamName) of
//            gtNull: AdoDataset.Parameters[i].Value:=null;
//            gtByte: AdoDataset.Parameters[i].Value:=Packet.GetByteGoods(ParamName);
//            gtShortInt: AdoDataset.Parameters[i].Value:=Packet.GetShortIntGoods(ParamName);
//            gtWord: AdoDataset.Parameters[i].Value:=Packet.GetWordGoods(ParamName);
//            gtSmallInt: AdoDataset.Parameters[i].Value:=Packet.GetSmallIntGoods(ParamName);
//            gtLongWord: AdoDataset.Parameters[i].Value:=Packet.GetLongWordGoods(ParamName);
//            gtInteger: AdoDataset.Parameters[i].Value:=Packet.GetIntegerGoods(ParamName);
//            gtInt64: AdoDataset.Parameters[i].Value:=Packet.GetInt64Goods(ParamName);
//            gtBoolean: AdoDataset.Parameters[i].Value:=Packet.GetBooleanGoods(ParamName);
//            gtByteBool: AdoDataset.Parameters[i].Value:=Packet.GetByteBoolGoods(ParamName);
//            gtWordBool: AdoDataset.Parameters[i].Value:=Packet.GetWordBoolGoods(ParamName);
//            gtLongBool: AdoDataset.Parameters[i].Value:=Packet.GetLongBoolGoods(ParamName);
//            gtSingle: AdoDataset.Parameters[i].Value:=Packet.GetSingleGoods(ParamName);
//            gtReal: AdoDataset.Parameters[i].Value:=Packet.GetRealGoods(ParamName);
//            gtDouble: AdoDataset.Parameters[i].Value:=Packet.GetDoubleGoods(ParamName);
//            gtComp: AdoDataset.Parameters[i].Value:=Packet.GetCompGoods(ParamName);
//            gtCurrency: AdoDataset.Parameters[i].Value:=Packet.GetCurrencyGoods(ParamName);
//            gtExtended: AdoDataset.Parameters[i].Value:=Packet.GetExtendedGoods(ParamName);
//            gtDateTime: AdoDataset.Parameters[i].Value:=Packet.GetDateTimeGoods(ParamName);
//            gtDate: AdoDataset.Parameters[i].Value:=Packet.GetDateGoods(ParamName);
//            gtTime: AdoDataset.Parameters[i].Value:=Packet.GetTimeGoods(ParamName);
//            gtShortString:
//               begin
//                  j:=length(Packet.GetShortStringGoods(ParamName))*sizeof(char);
//                  if j=0 then
//                     j:=2;
//                  if Sybase then
//                     AdoDataset.Parameters[i].DataType:=ftString;
//                  AdoDataset.Parameters[i].Size:=j;
//                  AdoDataset.Parameters[i].Value:=Packet.GetShortStringGoods(ParamName);
//               end;
//            gtAnsiString:
//               begin
//                  j:=length(Packet.GetAnsiStringGoods(ParamName));
//                  if j=0 then
//                     j:=2;
//                  if sybase then
//                     AdoDataset.Parameters[i].DataType:=ftString;
//                  AdoDataset.Parameters[i].Size:=j;
//                  AdoDataset.Parameters[i].Value:=Packet.GetAnsiStringGoods(ParamName);
//               end;
//            gtWideString:
//               begin
//                  j:=length(Packet.GetWideStringGoods(ParamName))*sizeof(char);
//                  if j=0 then
//                     j:=2;
//                  if sybase then
//                     AdoDataset.Parameters[i].DataType:=ftString;
//                  AdoDataset.Parameters[i].Size:=j;
//                  AdoDataset.Parameters[i].Value:=Packet.GetWideStringGoods(ParamName);
//               end;
//            gtString:
//               begin
//                  j:=length(Packet.GetStringGoods(ParamName))*sizeof(char);
//                  if j=0 then
//                     j:=2;
//                  if sybase then
//                     AdoDataset.Parameters[i].DataType:=ftString;
//                  AdoDataset.Parameters[i].Size:=j;
//                  AdoDataset.Parameters[i].Value:=Packet.GetStringGoods(ParamName);
//               end;
//            gtBinary:
//               begin
//                  Stream:=nil;
//                  try
//                     Stream:=TMemoryStream.Create;
//                     Packet.GetStreamGoods(ParamName,Stream);
//                     Stream.Position:=0;
//                     AdoDataset.Parameters[i].LoadFromStream(Stream,ftBlob);
//                     FreeAndNil(Stream);
//                  except
//                  end;
//                  if assigned(Stream) then
//                     FreeAndNil(Stream);
//               end;
//         end;
//      end;
//end;

procedure TTaskThread.PacketToParameters(const Packet: TwxdPacket; const uniSP: TuniStoredProc);
var
  ParamName,Provider: AnsiString;
//  ParamDir: TParameterDirection;
  ParamType:TParamType;       //TParamType = (ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult);
//  isOracle: boolean;
  i: integer;
  Stream: TMemoryStream;
begin
  provider:=AnsiString(uniSP.Connection.ProviderName);
//  isOracle:=({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(Provider),PAnsiChar('OraOLEDB.Oracle.1'))=0);
//  if not isOracle then
//  begin
//    try
//      uniSP.Parameters.Refresh;
//    except
//      isOracle:=true;
//    end;
//  end;

  for i := 0 to Packet.GoodsCount - 1 do
  begin
    ParamName:=Packet.GetGoodsName(i);
    case Packet.GetGoodsDirection(ParamName) of
      1: ParamType:=ptInput;
      2: ParamType:=ptOutput;
      4: ParamType:= ptResult;
    else
      ParamType:=ptInputOutput;
    end;

    case Packet.GetGoodsType(ParamName) of
      gtByte:
      begin
        uniSP.Params.CreateParam({$IFDEF UNICODE}ftByte{$ELSE}ftWord{$ENDIF},string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetByteGoods(ParamName);
      end;
      gtShortInt:
      begin
        uniSP.Params.CreateParam({$IFDEF UNICODE}ftShortInt{$ELSE}ftInteger{$ENDIF},string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetShortIntGoods(ParamName);
      end;
      gtWord:
      begin
        uniSP.Params.CreateParam(ftWord,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetWordGoods(ParamName);
      end;
      gtSmallInt:
      begin
        uniSP.Params.CreateParam(ftSmallint,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetSmallIntGoods(ParamName);
      end;
      gtLongWord:
      begin
        uniSP.Params.CreateParam({$IFDEF UNICODE}ftLongWord{$ELSE}ftInteger{$ENDIF},string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetLongWordGoods(ParamName);
      end;
      gtInteger:
      begin
        uniSP.Params.CreateParam(ftInteger,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetIntegerGoods(ParamName);
      end;
      gtInt64:
      begin
        uniSP.Params.CreateParam(ftLargeint,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetInt64Goods(ParamName);
      end;
      gtBoolean:
      begin
        uniSP.Params.CreateParam(ftBoolean,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetBooleanGoods(ParamName);
      end;
      gtByteBool:
      begin
        uniSP.Params.CreateParam(ftBoolean,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetByteBoolGoods(ParamName);
      end;
      gtWordBool:
      begin
        uniSP.Params.CreateParam(ftBoolean,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetWordBoolGoods(ParamName);
      end;
      gtLongBool:
      begin
        uniSP.Params.CreateParam(ftBoolean,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetLongBoolGoods(ParamName);
      end;
      gtSingle:
      begin
        uniSP.Params.CreateParam({$IFDEF UNICODE}ftSingle{$ELSE}ftFloat{$ENDIF},string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetSingleGoods(ParamName);
      end;
      gtReal:
      begin
        uniSP.Params.CreateParam(ftFloat,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetRealGoods(ParamName);
      end;
      gtDouble:
      begin
        uniSP.Params.CreateParam(ftFloat,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetDoubleGoods(ParamName);
      end;
      gtComp:
      begin
        uniSP.Params.CreateParam(ftUnknown,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetCompGoods(ParamName);
      end;
      gtCurrency:
      begin
        uniSP.Params.CreateParam(ftCurrency,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetCurrencyGoods(ParamName);
      end;
      gtExtended:
      begin
        uniSP.Params.CreateParam({$IFDEF UNICODE}ftExtended{$ELSE}ftFloat{$ENDIF},string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetExtendedGoods(ParamName);
      end;
      gtDateTime:
      begin
        uniSP.Params.CreateParam(ftDateTime,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetDateTimeGoods(ParamName);
      end;
      gtDate:
      begin
        uniSP.Params.CreateParam(ftDate,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetDateGoods(ParamName);
      end;
      gtTime:
      begin
        uniSP.Params.CreateParam(ftTime,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetTimeGoods(ParamName);
      end;
      gtShortString:
      begin
        uniSP.Params.CreateParam(ftString,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetShortStringGoods(ParamName);
      end;
      gtAnsiString:
      begin
        uniSP.Params.CreateParam(ftString,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetAnsiStringGoods(ParamName);
      end;
      gtWideString:
      begin
        uniSP.Params.CreateParam(ftWideString,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetWideStringGoods(ParamName);
      end;
      gtString:
      begin
        uniSP.Params.CreateParam(ftString,string(ParamName), ParamType);
        uniSP.Params.ParamByName(string(ParamName)).Value:=Packet.GetStringGoods(ParamName);
      end;
      gtBinary:
      begin
        try
          Stream:=TMemoryStream.Create;
          uniSP.Params.CreateParam(ftBlob,string(ParamName), ParamType);
          if Packet.GetStreamGoods(ParamName,Stream) then
          begin
            Stream.Position:=0;
            uniSP.Params.ParamByName(string(ParamName)).LoadFromStream(Stream,ftBlob);
          end;
        except
        end;
        if assigned(Stream) then
          FreeAndNil(Stream);
      end;
    end;
  end;
end;

procedure TTaskThread.PacketToParameters(const Packet: TwxdPacket; const uniQuery: TuniQuery);
var
  ParamName,ParamName1: AnsiString;
  i,j: integer;
  Stream: TMemoryStream;
begin
  for i := 0 to uniQuery.Params.Count - 1 do
  begin
    ParamName1:=AnsiString(uniQuery.Params[i].Name);
    ParamName:=':'+ParamName1;
    if not Packet.GoodsExists(ParamName) then
      continue;
    case Packet.GetGoodsType(ParamName) of
      gtNull: uniQuery.Params[i].Value:=null;
      gtByte: uniQuery.Params[i].Value:=Packet.GetByteGoods(ParamName);
      gtShortInt: uniQuery.Params[i].Value:=Packet.GetShortIntGoods(ParamName);
      gtWord: uniQuery.Params[i].Value:=Packet.GetWordGoods(ParamName);
      gtSmallInt: uniQuery.Params[i].Value:=Packet.GetSmallIntGoods(ParamName);
      gtLongWord: uniQuery.Params[i].Value:=Packet.GetLongWordGoods(ParamName);
      gtInteger: uniQuery.Params[i].Value:=Packet.GetIntegerGoods(ParamName);
      gtInt64: uniQuery.Params[i].Value:=Packet.GetInt64Goods(ParamName);
      gtBoolean: uniQuery.Params[i].Value:=Packet.GetBooleanGoods(ParamName);
      gtByteBool: uniQuery.Params[i].Value:=Packet.GetByteBoolGoods(ParamName);
      gtWordBool: uniQuery.Params[i].Value:=Packet.GetWordBoolGoods(ParamName);
      gtLongBool: uniQuery.Params[i].Value:=Packet.GetLongBoolGoods(ParamName);
      gtSingle: uniQuery.Params[i].Value:=Packet.GetSingleGoods(ParamName);
      gtReal: uniQuery.Params[i].Value:=Packet.GetRealGoods(ParamName);
      gtDouble: uniQuery.Params[i].Value:=Packet.GetDoubleGoods(ParamName);
      gtComp: uniQuery.Params[i].Value:=Packet.GetCompGoods(ParamName);
      gtCurrency: uniQuery.Params[i].Value:=Packet.GetCurrencyGoods(ParamName);
      gtExtended: uniQuery.Params[i].Value:=Packet.GetExtendedGoods(ParamName);
      gtDateTime: uniQuery.Params[i].Value:=Packet.GetDateTimeGoods(ParamName);
      gtDate: uniQuery.Params[i].Value:=Packet.GetDateGoods(ParamName);
      gtTime: uniQuery.Params[i].Value:=Packet.GetTimeGoods(ParamName);
      gtShortString:
      begin
        j:=length(Packet.GetShortStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniQuery.Params[i].Size:=255
           else
              uniQuery.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniQuery.Params[i].Size:=255;
        {$ENDIF}
        uniQuery.Params[i].Value:=Packet.GetShortStringGoods(ParamName);
      end;
      gtAnsiString:
      begin
        j:=length(Packet.GetAnsiStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniQuery.Params[i].Size:=255
           else
              uniQuery.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniQuery.Params[i].Size:=255;
        {$ENDIF}
        uniQuery.Params[i].Value:=Packet.GetAnsiStringGoods(ParamName);
      end;
      gtWideString:
      begin
        j:=length(Packet.GetWideStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniQuery.Params[i].Size:=255
           else
              uniQuery.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniQuery.Params[i].Size:=255;
        {$ENDIF}
        uniQuery.Params[i].Value:=Packet.GetWideStringGoods(ParamName);
      end;
      gtString:
      begin
        j:=length(Packet.GetStringGoods(ParamName));
        {$IFNDEF UNICODE}
           if j=0 then
              uniQuery.Params[i].Size:=255
           else
              uniQuery.Params[i].Size:=j;
        {$ELSE}
           if j=0 then
              uniQuery.Params[i].Size:=255;
        {$ENDIF}
        uniQuery.Params[i].Value:=Packet.GetStringGoods(ParamName);
      end;
      gtBinary:
      begin
        try
           Stream:=TMemoryStream.Create;
           Packet.GetStreamGoods(ParamName,Stream);
           Stream.Position:=0;
           uniQuery.Params[i].LoadFromStream(Stream,ftBlob);
           FreeAndNil(Stream);
        except
        end;
        if assigned(Stream) then
           FreeAndNil(Stream);
      end;
    end;
  end;
end;

procedure TTaskThread.Task_ExecSQL;
var
  ok,HasResult: boolean;
  DatabaseId,ExceptText: AnsiString;
  SqlCommand,ReturnValue: string;
  SysConn: TuniConnection;
  SysCommand: TUniSQL;
  SysQuery: TUniQuery;
  CommandTimeout,PoolId,ConnectionId,j: integer;
  EnableBCD: boolean;
  ParamPacket: TwxdPacket;
begin
  SysConn:=nil;
  SysCommand:=nil;
  SysQuery:=nil;
  ParamPacket:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SQLCommand');
  HasResult:=RequestPacket.GetBooleanGoods('HasResult');
  CommandTimeout:=RequestPacket.GetIntegerGoods('CommandTimeout');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  ok:=ok and (trim(SQLCommand)<>'') and (CommandTimeout>=5);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      if HasResult then
      begin
        try
          SysQuery:=TUniQuery.Create(nil);
          SysQuery.DisableControls;
          SysQuery.Options.EnableBCD:=EnableBCD;
          SysQuery.Connection:=SysConn;
          SysQuery.SQL.Text:=SQLCommand;
          if assigned(ParamPacket) then
            PacketToParameters(ParamPacket,SysCommand);
          SysQuery.Open;
          if SysQuery.RecordCount=0 then
            ReturnValue:=''
          else
            ReturnValue:=trim(SysQuery.Fields[0].asstring);
          ok:=true;
        except
          on E: Exception do
          begin
           ok:=false;
           ExceptText:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
           ReturnValue:='';
          end;
        end;
        SafeFreeUniData(SysQuery);
      end
      else
      begin
        ReturnValue:='';
        try
          SysCommand:=TUniSQL.Create(nil);
          SysCommand.Connection:=SysConn;
          SysCommand.SQL.Text:=SQLCommand;
          if assigned(ParamPacket) then
             PacketToParameters(ParamPacket,SysCommand);
          SysCommand.execute;
          ok:=true;
        except
          on E: Exception do
          begin
            ok:=false;
            ExceptText:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          end;
        end;
      end;
      if not ok then
      begin
        ErrorCode:='0205403';
        ErrorText:='执行 SQL 命令失败['+SQLCommand+']: '+ExceptText;
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
      end;
      if assigned(SysCommand) then
        FreeAndNil(SysCommand);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0205402';
      ErrorText:='数据库连接分配失败...';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
    end;
  end
  else
  begin
    ErrorCode:='0205401';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
  end;
  if Assigned(ParamPacket) then
    FreeAndNil(ParamPacket);
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if ok then
    BackPacket.PutStringGoods('ReturnValue',ReturnValue)
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02054: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_ExecSQL(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  HasResult: boolean;
  SqlCommand: string;
  SysCommand: TUniSQL;
  SysQuery: TUniQuery;
  CommandTimeout: integer;
  EnableBCD: boolean;
  ParamPacket: TwxdPacket;
begin
  SysCommand:=nil;
  SysQuery:=nil;
  ParamPacket:=nil;
  SqlCommand:=TaskPacket.GetStringGoods('SQLCommand');
  HasResult:=TaskPacket.GetBooleanGoods('HasResult');
  CommandTimeout:=TaskPacket.GetIntegerGoods('CommandTimeout');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    Result:=GetPacketFromPacket(TaskPacket,'Parameters',ParamPacket);
    if not Result then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    Result:=true;
  end;
  Result:=Result and (trim(SQLCommand)<>'') and (CommandTimeout>=5);
  if Result then
  begin
    if HasResult then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        SysQuery.Options.EnableBCD:=EnableBCD;
        SysQuery.SQL.Text:=SQLCommand;
        SysQuery.Connection:=SysConn;
        if assigned(ParamPacket) then
          PacketToParameters(ParamPacket,SysCommand);
        SysQuery.Open;
        if SysQuery.RecordCount=0 then
          RetValue:=''
        else
          RetValue:=AnsiString(trim(SysQuery.Fields[0].asstring));
        Result:=true;
      except
        on E: Exception do
        begin
          Result:=false;
          RetValue:='';
          ErrorCode:='0205403';
          ErrorText:='执行SQL命令失: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        end;
      end;
      SafeFreeUniData(SysQuery);
    end
    else
    begin
      RetValue:='';
      try
        SysCommand:=TUniSQL.Create(nil);
        SysCommand.Connection:=SysConn;
        SysCommand.SQL.Text:=SQLCommand;
        if assigned(ParamPacket) then
           PacketToParameters(ParamPacket,SysCommand);
        SysCommand.execute;
        Result:=true;
      except
        on E: Exception do
        begin
          Result:=false;
          RetValue:='';
          ErrorCode:='0205403';
          ErrorText:='执行SQL命令失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        end;
      end;
    end;
    if assigned(SysCommand) then
      FreeAndNil(SysCommand);
  end
  else
  begin
    ErrorCode:='0205401';
    ErrorText:='无效参数...';
  end;
  if Assigned(ParamPacket) then
    FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_ExecCommand;
var
  ok: boolean;
  DatabaseId: AnsiString;
  SqlCommand: string;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;
  CommandTimeout,PoolId,ConnectionId,Affected,j: integer;
  EnableBCD: boolean;
  ParamPacket: TwxdPacket;
begin
  SysConn:=nil;
  SysQuery:=nil;
  ParamPacket:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SQLCommand');
  CommandTimeout:=RequestPacket.GetIntegerGoods('CommandTimeout');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
    begin
      FreeAndNil(ParamPacket);
      ParamPacket:=nil;
    end;
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  ok:=ok and (trim(SQLCommand)<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        SysQuery.Options.EnableBCD:=EnableBCD;
        SysQuery.Connection:=SysConn;
        SysQuery.SQL.Clear;
        SysQuery.SQL.Add(SQLCommand);
        if assigned(ParamPacket) then
           PacketToParameters(ParamPacket,SysQuery);
        SysQuery.ExecSQL;
        Affected := SysQuery.RowsAffected;
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0210703';
          ErrorText:='执行SQL命令失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
        end;
      end;
      if assigned(SysQuery) then
        FreeAndNil(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0210702';
      ErrorText:='分配数据库连接失败...';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
    end;
  end
  else
  begin
    ErrorCode:='0210701';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
  end;
  if Assigned(ParamPacket) then
    FreeAndNil(ParamPacket);
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if ok then
    BackPacket.PutIntegerGoods('RecordsAffected',Affected)
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02107: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_ExecCommand(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  SqlCommand: string;
  SysQuery: TUniQuery;
  CommandTimeout,Affected: integer;
  EnableBCD: boolean;
  ParamPacket: TwxdPacket;
begin
  SysQuery:=nil;
  ParamPacket:=nil;
  SqlCommand:=TaskPacket.GetStringGoods('SQLCommand');
  CommandTimeout:=TaskPacket.GetIntegerGoods('CommandTimeout');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    Result:=GetPacketFromPacket(TaskPacket,'Parameters',ParamPacket);
    if not Result then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    Result:=true;
  end;
  Result:=Result and (trim(SQLCommand)<>'') and (CommandTimeout>=5);
  if Result then
  begin
    try
      SysQuery:=TUniQuery.Create(nil);
      SysQuery.DisableControls;
      SysQuery.Options.EnableBCD:=EnableBCD;
      SysQuery.Connection:=SysConn;
      SysQuery.SQL.Clear;
      SysQuery.SQL.Add(SQLCommand);
      if assigned(ParamPacket) then
         PacketToParameters(ParamPacket,SysQuery);
      SysQuery.ExecSQL;
      Affected:=SysQuery.RowsAffected;
      Result:=true;
    except
      on E: Exception do
      begin
        Affected:=0;
        Result:=false;
        ErrorCode:='0210703';
        ErrorText:='执行SQL命令失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
      end;
    end;
    if assigned(SysQuery) then
      FreeAndNil(SysQuery);
  end
  else
  begin
    Affected:=0;
    ErrorCode:='0210701';
    ErrorText:='无效参数...';
  end;
  RetValue:=AnsiString(inttostr(Affected));
  if Assigned(ParamPacket) then
  FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_ExecBatchSQL;
var
  ok: boolean;
  DatabaseId: AnsiString;
  BatchCommand: TStringList;
  SysConn: TUniConnection;
  SysCommand: TUniSQL;
  i,PoolId,Connectionid,j: integer;
begin
  SysConn:=nil;
  SysCommand:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  BatchCommand:=TStringList.Create;
  BatchCommand.Text:=RequestPacket.GetStringGoods('BatchSQLCommand');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=(BatchCommand.Count>0);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysCommand:=TUniSQL.Create(nil);
        SysConn.StartTransaction;
        SysCommand.Connection:=SysConn;
        for i := 0 to BatchCommand.Count - 1 do
        begin
          if trim(BatchCommand[i])='' then
             continue;
          SysCommand.SQL.Text:=BatchCommand[i];
          SysCommand.Execute;
        end;
        SysConn.Commit;
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0205503';
          ErrorText:='批量执行SQL: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          try
            if SysConn.InTransaction then
              SysConn.Rollback;
          except
          end;
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(BatchCommand.Text));
        end;
      end;
      if assigned(SysCommand) then
        FreeAndNil(SysCommand);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0205502';
       ErrorText:='分配数据库连接失败...';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(BatchCommand.Text));
    end;
  end
  else
  begin
    ErrorCode:='0205501';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(BatchCommand.Text));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02055: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  FreeAndNil(BatchCommand);
end;

function TTaskThread.Item_ExecBatchSQL(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  BatchCommand: TStringList;
  SysCommand: TUniSQL;
  i: integer;
begin
  SysCommand:=nil;
  BatchCommand:=TStringList.Create;
  BatchCommand.Text:=TaskPacket.GetStringGoods('BatchSQLCommand');
  Result:=(BatchCommand.Count>0);
  if Result then
  begin
    try
      SysCommand:=TUniSQL.Create(nil);
      SysCommand.Connection:=SysConn;
      for i := 0 to BatchCommand.Count - 1 do
      begin
        if trim(BatchCommand[i])='' then
           continue;
        SysCommand.SQL.Text:=BatchCommand[i];
        SysCommand.Execute;
      end;
      Result:=true;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0205503';
        ErrorText:='批量执行SQL语句失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(BatchCommand.Text));
      end;
    end;
    if assigned(SysCommand) then
      FreeAndNil(SysCommand);
  end
  else
  begin
    ErrorCode:='0205501';
    ErrorText:='无效参数...';
  end;
  RetValue:='';
  FreeAndNil(BatchCommand);
end;

procedure TTaskThread.Task_ExecStoreProc;
var
  ok,HasResultDataset: boolean;
  DatabaseId,ParamName: AnsiString;
  StoredProcName,err: string;
  ParamPacket: TwxdPacket;
  tmpStream,Stream: TMemoryStream;
  SysConn: TuniConnection;
  dp: TDatasetProvider;
  SysDataset: TUniQuery;
  RecordsAffected: OleVariant;
  StreamCount: integer;
  Streams: array of TMemoryStream;
  SysSP: TUniStoredProc;
  i,j,PoolId,Connectionid,k: integer;
  EnableBCD,IsUnicode: Boolean;
  bytevalue: byte;
  ShortIntValue: ShortInt;
  WordValue: Word;
  SmallIntValue: SmallInt;
  LongWordValue: LongWord;
  IntegerValue: integer;
  Int64Value: int64;
  BooleanValue: boolean;
  ByteBoolValue: ByteBool;
  WordBoolValue: WordBool;
  LongBoolValue: LongBool;
  SingleValue: Single;
  RealValue: Real;
  DoubleValue: double;
  CompValue: Comp;
  CurrencyValue: Currency;
  ExtendedValue: Extended;
  DateTimeValue: TDateTime;
  DateValue: TDate;
  TimeValue: TTime;
  ShortStringValue: ShortString;
  AnsiStringValue: AnsiString;
  WideStringValue: WideString;
  StringValue: String;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  StoredProcName:=RequestPacket.GetStringGoods('StoredProcName');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
  if RequestPacket.GoodsExists('_HasResultDataset') then
    HasResultDataset:=RequestPacket.GetBooleanGoods('_HasResultDataset')
  else
    HasResultDataset:=false;
  if RequestPacket.GoodsExists('IsolationLevel') then
    k:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    k:=-1;
  if RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  StreamCount:=0;
  SetLength(Streams,StreamCount);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (k<>-1) then
      ok:=SetIsoLevel(SysConn,k);
    if ok then
    begin
      try
        Stream:=TMemoryStream.Create;
        SysSP:=TUniStoredProc.Create(nil);
        SysSp.Options.EnableBCD:=EnableBCD;
        SysSP.Connection:=SysConn;
        SysSP.DisableControls;
        SysSp.StoredProcName:=StoredProcName;
        if ParamPacket<>nil then
           PacketToParameters(ParamPacket,SysSp);
        if HasResultDataset then                        //有返回数据集的存储过程
        begin
          try
            DP:=TDatasetProvider.Create(nil);
            DP.DataSet:=SysSp;
            SysSp.Active:=true;
            SysSP.AfterOpen := uniDataAfterOpen;
            SysSp.Open;
            while ok do
            begin
              j:=StreamCount;
              inc(StreamCount);
              SetLength(Streams,StreamCount);
              Streams[j]:=TMemoryStream.Create;
              ok:=DatasetZipToCdsStream(SysSP,Streams[j],IsUnicode,err);
              if not ok then
                break;
              If Not SysSP.OpenNext Then
                break;
             end;
          except
            on E: Exception do
            begin
              ok:=false;
              ErrorCode:='0205605';
              ErrorText:='打开存储过程失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
              NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
              NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
            end;
          end;
          if assigned(dp) then
             FreeAndNil(DP);
          SafeFreeUniData(SysSp);
        end
        else
           SysSp.ExecProc;               //无返回数据集的存储过程
        if ParamPacket<>nil then
        begin
          i:=0;
          while cardinal(i)<ParamPacket.GoodsCount do
          begin
            ParamName:=ParamPacket.GetGoodsName(i);
            j:=ParamPacket.GetGoodsDirection(ParamName);
            if (j<>2) and (j<>3) then
               ParamPacket.RemoveGoods(ParamName)
            else
               inc(i);
          end;
          for i := 0 to ParamPacket.GoodsCount - 1 do
          begin
            ParamName:=ParamPacket.GetGoodsName(i);
            try
              case ParamPacket.GetGoodsType(ParamName) of
                gtByte:
                begin
                  ByteValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutByteGoods(ParamName,ByteValue);
                end;
                gtShortInt:
                begin
                  ShortIntValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutShortIntGoods(ParamName,ShortIntValue);
                end;
                gtWord:
                begin
                  WordValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutWordGoods(ParamName,WordValue);
                end;
                gtSmallInt:
                begin
                  SmallIntValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutSmallIntGoods(ParamName,SmallIntValue);
                end;
                gtLongWord:
                begin
                  LongWordValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutLongWordGoods(ParamName,LongWordValue);
                end;
                gtInteger:
                begin
                  IntegerValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutIntegerGoods(ParamName,IntegerValue);
                end;
                gtInt64:
                begin
                  Int64Value:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutInt64Goods(ParamName,Int64Value);
                end;
                gtBoolean:
                begin
                  BooleanValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutBooleanGoods(ParamName,BooleanValue);
                end;
                gtByteBool:
                begin
                  ByteBoolValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutByteBoolGoods(ParamName,ByteBoolValue);
                end;
                gtWordBool:
                Begin
                  WordBoolValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutWordBoolGoods(ParamName,WordBoolValue);
                End;
                gtLongBool:
                begin
                  LongBoolValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutLongBoolGoods(ParamName,LongBoolValue);
                end;
                gtSingle:
                begin
                  SingleValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutSingleGoods(ParamName,SingleValue);
                end;
                gtReal:
                begin
                  realvalue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutRealGoods(ParamName,RealValue);
                end;
                gtDouble:
                begin
                  DoubleValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutDoubleGoods(ParamName,DoubleValue);
                end;
                gtComp:
                begin
                  CompValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutCompGoods(ParamName,CompValue);
                end;
                gtCurrency:
                begin
                  CurrencyValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutCurrencyGoods(ParamName,CurrencyValue);
                end;
                gtExtended:
                begin
                  ExtendedValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutExtendedGoods(ParamName,ExtendedValue);
                end;
                gtDateTime:
                begin
                  DateTimeValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutDateTimeGoods(ParamName,DateTimeValue);
                end;
                gtDate:
                begin
                  DateValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutDateGoods(ParamName,DateValue);
                end;
                gtTime:
                begin
                  TimeValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutTimeGoods(ParamName,TimeValue);
                end;
                gtShortString:
                begin
                  ShortStringValue:=ShortString(SysSP.Params.ParamByName(string(ParamName)).Value);
                  ParamPacket.PutShortStringGoods(ParamName,ShortStringValue);
                end;
                gtAnsiString:
                begin
                  AnsiStringValue:=AnsiString(SysSP.Params.ParamByName(string(ParamName)).Value);
                  ParamPacket.PutAnsiStringGoods(ParamName,AnsiStringValue);
                end;
                gtWideString:
                begin
                  WideStringValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutStringGoods(ParamName,WideStringValue);
                end;
                gtString:
                begin
                  StringValue:=SysSP.Params.ParamByName(string(ParamName)).Value;
                  ParamPacket.PutStringGoods(ParamName,StringValue);
                end;
                gtBinary:
                begin
                  Stream.Clear;
                  ParamPacket.PutStreamGoods(ParamName,Stream);
                end;
              end;
            except
            end;
          end;
          if SysSP.Params.Count>0 then
          begin
            try
               j:=SysSP.Params[0].Value;
               ParamPacket.PutIntegerGoods('_Return_Value',j);
            except
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0205603';
          ErrorText:='执行存储过程失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+SysConn.Database+']  Err'+ErrorCode+': '+ErrorText);
          try
             for i := 0 to StreamCount - 1 do
                if assigned(Streams[i]) then
                   FreeAndNil(Streams[i]);
             StreamCount:=0;
             SetLength(Streams,StreamCount);
             if assigned(SysDataset) then
                FreeAndNil(SysDataset);
          except
          end;
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
        end;
      end;
      if assigned(SysSp) then
        FreeAndNil(SysSp);
      if assigned(Stream) then
        FreeAndNil(Stream);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0205602';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
    end;
  end
  else
  begin
    ErrorCode:='0205601';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
  end;
  BackPacket.EncryptKey:=NodeService.s_TransferKey;
  if ok then
  begin
    if (ParamPacket<>nil) and (ParamPacket.GoodsCount>0) then
    begin
      try
        tmpStream:=TMemoryStream.Create;
        Stream:=TMemoryStream.Create;
        ok:=ParamPacket.SaveToStream(tmpStream);
        if ok then
        begin
          tmpStream.Position:=0;
          CompressStream(tmpStream,Stream);
          if Stream.Size>0 then
          begin
            Stream.Position:=0;
            ok:=BackPacket.PutStreamGoods('Parameters',Stream);
          end;
        end;
      except
        on e: exception do
        begin
           NodeService.syslog.Log('Err02056: 压缩反馈参数结构错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
           NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
           ok:=false;
        end;
      end;
      if assigned(Stream) then
        FreeAndNil(Stream);
      if assigned(tmpStream) then
        FreeAndNil(tmpStream);
    end;
    if ok and HasResultDataset then
    begin
      try
        BackPacket.PutIntegerGoods('DatasetCount',StreamCount);
        for i := 0 to StreamCount - 1 do
        begin
          ok:=BackPacket.PutStreamGoods('ResultDataset_'+AnsiString(inttostr(i)),Streams[i]);
          if not ok then
             break;
        end;
      except
        on e: exception do
        begin
          NodeService.syslog.Log('Err02056: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
          ok:=false;
        end;
      end;
    end;
    for i := 0 to StreamCount - 1 do
      if Streams[i]<>nil then
         FreeAndNil(Streams[i]);
    StreamCount:=0;
    SetLength(Streams,StreamCount);
    try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
      begin
        ErrorCode:='0205610';
        ErrorText:='ZIP方式压缩参数结构并转换为内存流失败...';
        NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
        BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
        BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
      end;
    except
      on e: exception do
         NodeService.syslog.Log('Err02056: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
    end;
  end
  else
  begin
    try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    except
      on e: exception do
         NodeService.syslog.Log('Err02056: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
    end;
  end;
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

function TTaskThread.Item_ExecStoreProc(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  StoredProcName: string;
  ParamPacket: TwxdPacket;
  SysSP: TUniStoredProc;
  EnableBCD: Boolean;
begin
  StoredProcName:=TaskPacket.GetStringGoods('StoredProcName');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    Result:=GetPacketFromPacket(TaskPacket,'Parameters',ParamPacket);
    if not Result then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    Result:=true;
  end;
  if Result then
  begin
    try
      SysSP:=TUniStoredProc.Create(nil);
      SysSP.DisableControls;
      SysSp.Options.EnableBCD:=EnableBCD;
      SysSP.Connection:=SysConn;
      SysSp.StoredProcName:=StoredProcName;
      if ParamPacket<>nil then
         PacketToParameters(ParamPacket,SysSp);
      SysSp.ExecProc;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0205603';
        ErrorText:='执行存储过程失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(StoredProcName));
      end;
    end;
    if assigned(SysSp) then
      FreeAndNil(SysSp);
  end
  else
  begin
    ErrorCode:='0205601';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_FileToBlob;
var
  ok: boolean;
  DatabaseId: AnsiString;
  LocateCondition,DataFileName,TableName, BlobFieldName: string;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;
  PoolId,ConnectionId,j: integer;
begin
  SysConn:=nil;
  SysQuery:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  DataFileName:=RequestPacket.GetStringGoods('DataFilename');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=fileexists(DataFileName) and (BlobFieldName<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        SysQuery.Connection:=SysConn;
        if LocateCondition='' then
           SysQuery.SQL.Text:='SELECT * FROM '+TableName
        else
           SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysQuery.Active:=true;
        if SysQuery.recordCount>0 then
        begin
          SysQuery.edit;
          TBlobField(SysQuery.FieldByName(BlobFieldName)).LoadFromFile(DataFilename);
          SysQuery.post;
          ok:=true;
        end
        else
        begin
          ok:=false;
          ErrorCode:='0205704';
          ErrorText:='数据表内无记录可进行转存...';
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0205703';
          ErrorText:='加载文件至 Blob 类型字段失败:  ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
        end;
      end;
      SafeFreeUniData(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0205702';
       ErrorText:='分配数据库连接失败...';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
    end;
  end
  else
  begin
    ErrorCode:='0205701';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02057: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_FileToBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  LocateCondition,DataFileName,TableName, BlobFieldName: string;
  SysQuery: TUniQuery;
begin
  SysQuery:=nil;
  TableName:=TaskPacket.GetStringGoods('TableName');
  BlobFieldName:=TaskPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=TaskPacket.GetStringGoods('LocateCondition');
  DataFileName:=TaskPacket.GetStringGoods('DataFilename');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  Result:=fileexists(DataFileName) and (BlobFieldName<>'') and (TableName<>'');
  if Result then
  begin
    try
      SysQuery:=TUniQuery.Create(nil);
      SysQuery.DisableControls;
      SysQuery.Connection:=SysConn;
      if LocateCondition='' then
         SysQuery.SQL.Text:='SELECT * FROM '+TableName
      else
         SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
      SysQuery.Active:=true;
      if SysQuery.recordCount>0 then
      begin
        SysQuery.edit;
        TBlobField(SysQuery.FieldByName(BlobFieldName)).LoadFromFile(DataFilename);
        SysQuery.post;
        Result:=true;
      end
      else
         Result:=false;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0205703';
        ErrorText:='Load file to Blob field failed: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
      end;
    end;
    SafeFreeUniData(SysQuery);
  end
  else
  begin
    ErrorCode:='0205701';
    ErrorText:='无效参数...';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_ClearBlob;
var
  ok: boolean;
  DatabaseId: AnsiString;
  LocateCondition, TableName, BlobFieldName: string;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;
  PoolId,ConnectionId,j: integer;
begin
  SysConn:=nil;
  SysQuery:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=(BlobFieldName<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        SysQuery.Connection:=SysConn;
        if LocateCondition='' then
           SysQuery.SQL.Text:='SELECT * FROM '+TableName
        else
           SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysQuery.Active:=true;
        if SysQuery.recordCount>0 then
        begin
          SysQuery.edit;
          TBlobField(SysQuery.FieldByName(BlobFieldName)).Clear;
          SysQuery.post;
          ok:=true;
        end
        else
        begin
          ok:=false;
          ErrorCode:='0208104';
          ErrorText:='无数据可清除...';
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0208103';
          ErrorText:='清除 Blob 类型字段内部失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      end;
      SafeFreeUniData(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0208102';
       ErrorText:='分配数据库连接失败...';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
    end;
  end
  else
  begin
    ErrorCode:='0208101';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02058: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_ClearBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  LocateCondition, TableName, BlobFieldName: string;
  SysQuery: TUniQuery;
begin
  SysQuery:=nil;
  TableName:=TaskPacket.GetStringGoods('TableName');
  BlobFieldName:=TaskPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=TaskPacket.GetStringGoods('LocateCondition');
  Result:=(BlobFieldName<>'') and (TableName<>'');
  if Result then
  begin
    try
      SysQuery:=TUniQuery.Create(nil);
      SysQuery.DisableControls;
      SysQuery.Connection:=SysConn;
      if LocateCondition='' then
         SysQuery.SQL.Text:='SELECT * FROM '+TableName
      else
         SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
      SysQuery.Active:=true;
      if SysQuery.recordCount>0 then
      begin
        SysQuery.edit;
        TBlobField(SysQuery.FieldByName(BlobFieldName)).Clear;
        SysQuery.post;
        Result:=true;
      end
      else
      begin
        Result:=false;
        ErrorCode:='0208104';
        ErrorText:='无数据内容可清除...';
      end;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0208103';
        ErrorText:='清除 Blob 类型字段内容失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
      end;
    end;
    SafeFreeUniData(SysQuery);
  end
  else
  begin
    ErrorCode:='0208101';
    ErrorText:='无效参数...';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_BlobToFile;
var
  ok: boolean;
  DatabaseId: AnsiString;
  LocateCondition,DataFileName,TableName, BlobFieldName: string;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;
  PoolId,ConnectionId,j: integer;
begin
  SysConn:=nil;
  SysQuery:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  DataFileName:=RequestPacket.GetStringGoods('DataFilename');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=(DatabaseId<>'') and (BlobFieldName<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        SysQuery.Connection:=SysConn;
        if LocateCondition='' then
          SysQuery.SQL.Text:='SELECT * FROM '+TableName
        else
          SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysQuery.Active:=true;
        if SysQuery.recordcount>0 then
        begin
          TBlobField(SysQuery.FieldByName(BlobFieldName)).SaveToFile(DataFilename);
          ok:=true;
        end
        else
        begin
          ok:=false;
          ErrorCode:='0205804';
          ErrorText:='无记录可导出...';
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0205803';
          ErrorText:='导出 blob 类型字段内容至文件失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
        end;
      end;
      SafeFreeUniData(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0205802';
       ErrorText:='分配数据库连接失败...';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
    end;
  end
  else
  begin
    ErrorCode:='0205801';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02058: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_TableToFile;
var
  ok: boolean;
  DatabaseId: AnsiString;
  SqlCommand,DataFileName: string;
  DataFormat: integer;
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  cds:TClientDataSet;
  dp:TDataSetProvider;
  PoolId,ConnectionId,j: integer;
  ParamPacket: TwxdPacket;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SqlCommand');
  DataFileName:=RequestPacket.GetStringGoods('DataFilename');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  DataFormat:=RequestPacket.GetIntegerGoods('DataFormat');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  ok:=ok and (DatabaseId<>'') and (SqlCommand<>'') and (DataFilename<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.UniDirectional := True;
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        SysDataset.SQL.Text:=SqlCommand;
        if assigned(ParamPacket) then
           PacketToParameters(ParamPacket,SysDataset);
        SysDataset.Active:=true;
        dp := TDataSetProvider.Create(nil);
        cds := TClientDataSet.Create(nil);
        dp.DataSet := SysDataset;
        cds.Data := dp.Data;
        if DataFormat=1 then
          cds.SaveToFile(DataFileName,dfBinary)
        else
          cds.SaveToFile(DataFileName,dfXML);
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0205903';
          ErrorText:='数据库:['+SysConn.Database+']  数据导出到文件失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand)+#13#10+AnsiString(DataFileName));
        end;
      end;
      SafeFreeUniData(SysDataset);
      FreeAndNil(cds);
      FreeAndNil(dp);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0205902';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand)+#13#10+AnsiString(DataFileName));
    end;
  end
  else
  begin
    ErrorCode:='0205901';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand)+#13#10+AnsiString(DataFileName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02059: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(ParamPacket) then
    FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_FileToTable;
var
  ok: boolean;
  DatabaseId: AnsiString;
  TableName,DataFileName,FieldName: string;
  i,j: integer;
  SysConn: TuniConnection;
  tempDataset: TuniQuery;
  cds:TClientDataSet;
  PoolId,ConnectionId: integer;
  Fld: TField;
  Stream: TMemoryStream;
  EnableBCD: boolean;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  DataFileName:=RequestPacket.GetStringGoods('DataFilename');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=(DatabaseId<>'') and (TableName<>'') and FileExists(DataFilename);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        cds:=TClientDataSet.Create(nil);
        cds.DisableControls;
        tempDataset:=TUniQuery.Create(nil);
        tempDataset.DisableControls;
        Stream:=TMemoryStream.Create;
        SysConn.StartTransaction;
        tempDataset.Options.EnableBCD:=EnableBCD;
        tempDataset.Connection:=SysConn;
        tempDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
        tempDataset.Active:=true;
        cds.LoadFromFile(DataFileName);
        cds.First;
        while not cds.Eof do
        begin
          tempdataset.append;
          for i:=0 to cds.FieldCount-1 do
          begin
            FieldName:=cds.Fields[i].FieldName;
            Fld:=TempDataset.FindField(FieldName);
            if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
              continue;
            if cds.fields[i].IsBlob then
            begin
               TBlobField(cds.fields[i]).savetostream(Stream);
               Stream.Position:=0;
               TBlobField(fld).loadfromstream(Stream);
               Stream.Clear;
            end
            else
              fld.Value:=cds.fields[i].Value;
          end;
          TempDataset.Post;
          cds.next;
        end;
        SysConn.Commit;
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206003';
          ErrorText:='从文件导入数据失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          try
            if SysConn.InTransaction then
               SysConn.Rollback;
          except
          end;
          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
        end;
      end;
      if assigned(Stream) then
        FreeAndNil(Stream);
      SafeFreeUniData(tempDataset);
      if Assigned(cds) then
        FreeAndNil(cds);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0206002';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
    end;
  end
  else
  begin
    ErrorCode:='0206001';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02060: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_FileToTable(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  TableName,DataFileName,FieldName: string;
  i: integer;
  tempDataset: TUniQuery;
  cds:TClientDataSet;
  Fld: TField;
  Stream: TMemoryStream;
  EnableBCD: boolean;
begin
  TableName:=TaskPacket.GetStringGoods('TableName');
  DataFileName:=TaskPacket.GetStringGoods('DataFilename');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  DataFileName:=wxdCommon.GetAbsolutePath(NodeService.s_DefaultDir,DataFileName);
  Result:=(TableName<>'') and FileExists(DataFilename);
  if Result then
  begin
    try
      cds:=TClientDataSet.Create(nil);
      cds.DisableControls;
      tempDataset:=TUniQuery.Create(nil);
      tempDataset.DisableControls;
      Stream:=TMemoryStream.Create;
      tempDataset.Options.EnableBCD:=EnableBCD;
      tempDataset.Connection:=SysConn;
      tempDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
      tempDataset.Active:=true;
      cds.LoadFromFile(DataFileName);
      cds.First;
      while not cds.Eof do
      begin
        tempdataset.append;
        for i:=0 to cds.FieldCount-1 do
        begin
          FieldName:=cds.Fields[i].FieldName;
          Fld:=TempDataset.FindField(FieldName);
          if (fld=nil) or (fld.DataType=ftAutoInc) or (fld.DataType=ftBytes) then
            continue;
          if cds.fields[i].IsBlob then
          begin
            TBlobField(cds.fields[i]).savetostream(Stream);
            Stream.Position:=0;
            TBlobField(fld).loadfromstream(Stream);
            Stream.Clear;
          end
          else
            fld.Value:=cds.fields[i].Value;
        end;
        TempDataset.Post;
        cds.next;
      end;
      Result:=true;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0206003';
        ErrorText:='从文件导入数据失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(DataFileName));
      end;
    end;
    if assigned(Stream) then
      FreeAndNil(Stream);
    SafeFreeUniData(tempDataset);
    if Assigned(cds) then
      FreeAndNil(cds);
  end
  else
  begin
    ErrorCode:='0206001';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_ReadDataset;
var
  ok: boolean;
  DatabaseId: AnsiString;
  SqlCommand,err: string;
  PoolId,ConnectionId,j: integer;
  SysConn: TUniConnection;
  SysDataset: TUniQuery;
  Stream: TMemoryStream;
  ParamPacket: TwxdPacket;
  EnableBCD,IsUnicode: boolean;           //IsAdoFormat
begin
  SysConn:=nil;
  ParamPacket:=nil;
  Stream:=nil;
  SysDataset:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SqlCommand');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
//  IsAdoFormat:=RequestPacket.GoodsExists('IsAdoFormat');
//  if IsAdoFormat then
//    IsAdoFormat:=RequestPacket.GetBooleanGoods('IsAdoFormat');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if (pos(':',SqlCommand)>0) and RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  ok:=ok and (DatabaseId<>'') and (SqlCommand<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok then
    begin
      if j<>-1 then
        ok:=SetIsoLevel(SysConn,j);
    end
    else
    begin
      ErrorCode:='0206102';
      ErrorText:='分配数据库连接失败....';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
    end;
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.DisableControls;
        Stream:=TMemoryStream.Create;
        SysDataset.Options.EnableBCD:=EnableBCD;
//        SysDataSet.UniDirectional := True;
        SysDataset.AfterOpen := uniDataAfterOpen;
        SysDataset.Connection:=SysConn;
        SysDataset.SQL.Text:=sqlcommand;
        if ParamPacket<>nil then
           PacketToParameters(ParamPacket,SysDataset);
//        SysDataset.active:=true;
        if ok then
        begin
          ok:=DatasetZipToCdsStream(SysDataset,Stream,IsUnicode,err);
          if not ok then
          begin
            ErrorCode:='0206104A';
            ErrorText:='执行 ReadDataSet 出错: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
          end;
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206103A';
          ErrorText:='打开数据集失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
        end;
      end;
      if (not ok) and assigned(Stream) then
          FreeAndNil(Stream);
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end;
  end
  else
  begin
    ErrorCode:='0206101A';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      ok:=BackPacket.PutStreamGoods('OleVariant',Stream);
      FreeAndNil(Stream);
      if not ok then
      begin
        ErrorCode:='0206101A';
        ErrorText:='返回数据集参数...';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
      end;
    end;
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
      NodeService.syslog.Log('Err02061: 创建返回数据结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if ParamPacket<>nil then
  FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_ReadSimpleResult;
var
  ok: boolean;
  DatabaseId: AnsiString;
  SqlCommand: string;
  PoolId,ConnectionId,j: integer;
  SysQuery:TUniQuery;
  SysConn: TuniConnection;
  ParamPacket: TwxdPacket;
  EnableBCD: boolean;
  RetValue: String;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SqlCommand');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if (pos(':',SqlCommand)>0) and RequestPacket.GoodsExists('Parameters') then
  begin
    ParamPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
    if not ok then
      FreeAndNil(ParamPacket);
  end
  else
  begin
    ParamPacket:=nil;
    ok:=true;
  end;
  ok:=ok and (DatabaseId<>'') and (SqlCommand<>'');
  RetValue:='';
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TuniQuery.Create(nil);
        SysQuery.UniDirectional := True;
        SysQuery.DisableControls;
        SysQuery.Options.EnableBCD:=EnableBCD;
        SysQuery.AfterOpen := uniDataAfterOpen;
        SysQuery.Connection:=SysConn;
        SysQuery.SQL.Text:=sqlcommand;
        if ParamPacket<>nil then
           PacketToParameters(ParamPacket,SysQuery);
        SysQuery.active:=true;
        if SysQuery.RecordCount>0 then
           RetValue:=trim(SysQuery.Fields[0].AsString);
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0210803';
          ErrorText:='读取结果的SQL命令失败: : ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
        end;
      end;
      SafeFreeUniData(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0210802';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
    end;
  end
  else
  begin
    ErrorCode:='0210801';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    BackPacket.PutStringGoods('ReturnValue',RetValue)
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
      NodeService.syslog.Log('Err02108: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

procedure TTaskThread.Task_WriteDataset;
var
  ok: boolean;
  DatabaseId: AnsiString;
  TableName,Condition,Err: string;
  SysConn: TuniConnection;
  SysQuery: TuniQuery;
  SysCommand: TUniSQL;
  PoolId,ConnectionId,j: integer;
  Cds: TClientDataset;
  EnableBCD: boolean;
  Stream: TMemoryStream;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  if RequestPacket.GoodsExists('Condition') then
    Condition:=RequestPacket.GetStringGoods('Condition')
  else
    condition:='';
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
  j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
  j:=-1;
  if RequestPacket.GoodsExists('Dataset') then
  begin
    begin
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      ok:=GetCdsFromPacket(RequestPacket,'Dataset',Cds);
      if not ok then
        FreeAndNil(Cds);
    end;
  end
  else
    ok:=false;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysQuery:=TUniQuery.Create(nil);
        SysQuery.DisableControls;
        Stream:=TMemoryStream.Create;
        SysConn.StartTransaction;
        SysQuery.Options.EnableBCD:=EnableBCD;
        SysQuery.Connection:=SysConn;
        if Condition<>'' then
        begin
          try
            SysCommand:=TUniSQL.Create(nil);
            SysCommand.Connection:=SysConn;
            SysCommand.SQL.Text:='DELETE FROM '+tablename+' WHERE '+condition;
            SysCommand.Execute;
            ok:=true;
          except
            on E: Exception do
            begin
              ok:=false;
              ErrorCode:='0206209';
              ErrorText:='删除记录失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
              NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
              NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
            end;
          end;
          if assigned(SysCommand) then
             FreeAndNil(SysCommand);
          if not ok then
          begin
            try
               SysConn.Rollback;
            except
            end;
            NodeService.FreeConnection(PoolId,ConnectionId);
            FreeAndNil(SysQuery);
            FreeAndNil(Stream);
            FreeAndNil(Cds);
            exit;
          end;
        end;
        SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
        SysQuery.Active:=true;
        ok:=CdsWriteToUniQuery(Cds,SysQuery,Err);
        Cds.Active:=false;
        if ok then
           sysconn.Commit
        else
        begin
          SysConn.Rollback;
          ErrorCode:='0206204';
          ErrorText:=AnsiString(err);
          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206203';
          ErrorText:='将数据集追加到表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
          try
             if SysConn.InTransaction then
                SysConn.Rollback;
          except
          end;
        end;
      end;
      SafeFreeUniData(SysQuery);
      if assigned(Stream) then
        FreeAndNil(Stream);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0206202';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
    end;
    FreeAndNil(Cds);
  end
  else
  begin
    ErrorCode:='0206201';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02062: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_WriteDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  TableName,Condition,Err: string;
  SysQuery: TuniQuery;
  SysCommand: TuniSQL;
  Cds: TClientDataset;
  EnableBCD,IsAdoFormat: boolean;
  Stream: TMemoryStream;
begin
  TableName:=TaskPacket.GetStringGoods('TableName');
  if TaskPacket.GoodsExists('Condition') then
    Condition:=TaskPacket.GetStringGoods('Condition')
  else
    condition:='';
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('Dataset') then
  begin
    Cds:=TClientDataset.Create(nil);
    Cds.DisableControls;
    Result:=GetCdsFromPacket(TaskPacket,'Dataset',Cds);
    if not Result then
      FreeAndNil(Cds);
  end
  else
    Result:=false;
  if Result then
  begin
    try
      SysQuery:=TuniQuery.Create(nil);
      SysQuery.DisableControls;
      Stream:=TMemoryStream.Create;
      SysQuery.Options.EnableBCD:=EnableBCD;
      SysQuery.Connection:=SysConn;
      if Condition<>'' then
      begin
        try
           SysCommand:=TuniSQL.Create(nil);
           SysCommand.Connection:=SysConn;
           SysCommand.SQL.Text:='DELETE FROM '+tablename+' WHERE '+condition;
           SysCommand.Execute;
           Result:=true;
        except
           on E: Exception do
           begin
             result:=false;
             ErrorCode:='0206204';
             ErrorText:='执行 DELETE SQL 语句失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
             NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
             NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
           end;
        end;
        if Assigned(SysCommand) then
           FreeAndNil(SysCommand);
        if not Result then
        begin
          FreeAndNil(SysQuery);
          FreeAndNil(Stream);
          FreeAndNil(Cds);
        end;
      end;
      SysQuery.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
      SysQuery.Active:=true;
      Result := CdsWriteToUniQuery(Cds,SysQuery,Err);
      Cds.Active:=false;

      if not result then
      begin
        ErrorCode:='0206202';
        ErrorText:=AnsiString(Err);
      end;
    except
      on E: Exception do
      begin
        result:=false;
        ErrorCode:='0206203';
        ErrorText:='将数据集追加到表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#19+AnsiString(Condition));
      end;
    end;
    SafeFreeUniData(SysQuery);
    if assigned(Stream) then
      FreeAndNil(Stream);
    FreeAndNil(Cds);
  end
  else
  begin
  ErrorCode:='0206201';
  ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_AppendRecord;
var
  ok: boolean;
  DatabaseId: AnsiString;
  TableName,FieldName, AutoIncFieldName: string;
  GoodsName: AnsiString;
  i, AutoIncFieldValue, j, k: integer;
  SysConn: TuniConnection;
  SysDataset: TUniQuery;
  PoolId,ConnectionId: integer;
  Fld: TField;
  RecordPacket: TwxdPacket;
  Stream: TMemoryStream;
  ByteValue: byte;
  ShortIntValue: shortint;
  WordValue: Word;
  SmallIntValue: SmallInt;
  LongWordValue: LongWord;
  IntegerValue: Integer;
  Int64Value: Int64;
  BooleanValue: Boolean;
  ByteBoolValue: ByteBool;
  WordBoolValue: WordBool;
  LongBoolValue: LongBool;
  SingleValue: Single;
  RealValue: Real;
  DoubleValue: Double;
  CompValue: Comp;
  CurrencyValue: Currency;
  ExtendedValue: Extended;
  DateTimeValue: TDateTime;
  DateValue: TDate;
  TimeValue: TTime;
  ShortStringValue: ShortString;
  AnsiStringValue: AnsiString;
  WideStringValue: WideString;
  StringValue: String;
  IsOldFormat: boolean;
  Cds: TClientdataset;
  EnableBCD: boolean;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  IsOldFormat:=RequestPacket.GoodsExists('OldMethodFlag');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    k:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    k:=-1;
  if RequestPacket.GoodsExists('RecordData') then
  begin
    if IsOldFormat then
    begin
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      ok:=GetCdsFromPacket(RequestPacket,'RecordData',Cds);
      if not ok then
         FreeAndNil(Cds);
    end
    else
    begin
      RecordPacket:=TwxdPacket.Create;
      ok:=GetPacketFromPacket(RequestPacket,'RecordData',RecordPacket);
      if not ok then
         FreeAndNil(RecordPacket);
    end;
  end
  else
  ok:=false;
  AutoIncFieldValue:=0;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (k<>-1) then
      ok:=SetIsoLevel(SysConn,k);
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.DisableControls;
        Stream:=TMemoryStream.Create;
        SysDataset.Options.EnableBCD:=EnableBCD;
        SysDataset.Connection:=SysConn;
        SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
        SysDataset.Active:=true;
        sysdataset.append;
        AutoIncFieldName:='';
        if IsOldFormat then
        begin
          for i:=0 to Cds.Fields.Count-1 do
          begin
            FieldName:=Cds.Fields[i].FieldName;
            Fld:=SysDataset.Fields.FindField(FieldName);
            if fld=nil then
               continue;
            if fld.DataType=ftAutoInc then
            begin
              AutoIncFieldName:=Cds.fields[i].FieldName;
              continue;
            end;
            if Cds.fields[i].IsBlob then
            begin
              try
                TBlobField(Cds.fields[i]).savetostream(stream);
                if Stream.Size>0 then
                  begin
                     stream.Position:=0;
                     TBlobField(Fld).loadfromstream(stream);
                  end
                else
                  TBlobField(Fld).Clear;
                ok:=true;
              except
                ok:=false;
              end;
              stream.Clear;
            end
            else
            begin
              if not Cds.Fields[i].IsNull then
                 Fld.Value:=Cds.Fields[i].Value;
            end;
          end;
        end
        else
        begin
          for i:=0 to RecordPacket.GoodsCount-1 do
          begin
            GoodsName:=RecordPacket.GetGoodsName(i);
            FieldName:=string(GoodsName);
            Fld:=SysDataset.FindField(FieldName);
            if fld=nil then
               continue;
            if fld.DataType=ftAutoInc then
            begin
              AutoIncFieldName:=Fld.FieldName;
              continue;
            end;
            j:=RecordPacket.GetGoodsType(GoodsName);
            if j=gtNull then
            begin
              Fld.Clear;
              Continue;
            end;
            case j of
               gtByte:
                   begin
                     ByteValue:=RecordPacket.GetByteGoods(GoodsName);
                     Fld.Value:=ByteValue;
                   end;
               gtShortInt:
                  begin
                     ShortIntValue:=RecordPacket.GetShortIntGoods(GoodsName);
                     Fld.Value:=ShortIntValue;
                  end;
               gtWord:
                  begin
                     WordValue:=RecordPacket.GetWordGoods(GoodsName);
                     Fld.Value:=WordValue;
                  end;
               gtSmallInt:
                  begin
                     SmallIntValue:=RecordPacket.GetSmallIntGoods(GoodsName);
                     Fld.Value:=SmallIntValue;
                  end;
               gtLongWord:
                  begin
                     LongWordValue:=RecordPacket.GetLongWordGoods(GoodsName);
                     Fld.Value:=LongWordValue;
                  end;
               gtInteger:
                  begin
                     IntegerValue:=RecordPacket.GetIntegerGoods(GoodsName);
                     Fld.Value:=IntegerValue;
                  end;
               gtInt64:
                  begin
                     Int64Value:=RecordPacket.GetInt64Goods(GoodsName);
                     Fld.Value:=Int64Value;
                  end;
               gtBoolean:
                  begin
                     BooleanValue:=RecordPacket.GetBooleanGoods(GoodsName);
                     Fld.Value:=BooleanValue;
                  end;
               gtByteBool:
                  begin
                     ByteBoolValue:=RecordPacket.GetByteBoolGoods(GoodsName);
                     Fld.Value:=ByteBoolValue;
                  end;
               gtWordBool:
                  begin
                     WordBoolValue:=RecordPacket.GetWordBoolGoods(GoodsName);
                     Fld.Value:=WordBoolValue;
                  end;
               gtLongBool:
                  begin
                     LongBoolValue:=RecordPacket.GetLongBoolGoods(GoodsName);
                     Fld.Value:=LongBoolValue;
                  end;
               gtSingle:
                  begin
                     SingleValue:=RecordPacket.GetSingleGoods(GoodsName);
                     Fld.Value:=SingleValue;
                  end;
               gtReal:
                  begin
                     RealValue:=RecordPacket.GetRealGoods(GoodsName);
                     Fld.Value:=RealValue;
                  end;
               gtDouble:
                  begin
                     DoubleValue:=RecordPacket.GetDoubleGoods(GoodsName);
                     Fld.Value:=DoubleValue;
                  end;
               gtComp:
                  begin
                     CompValue:=RecordPacket.GetCompGoods(GoodsName);
                     Fld.Value:=CompValue;
                  end;
               gtCurrency:
                  begin
                     CurrencyValue:=RecordPacket.GetCurrencyGoods(GoodsName);
                     Fld.Value:=CurrencyValue;
                  end;
               gtExtended:
                  begin
                     ExtendedValue:=RecordPacket.GetExtendedGoods(GoodsName);
                     Fld.Value:=ExtendedValue;
                  end;
               gtDateTime:
                  begin
                     DateTimeValue:=RecordPacket.GetDateTimeGoods(GoodsName);
                     if DateTimeValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=DateTimeValue;
                  end;
               gtDate:
                  begin
                     DateValue:=RecordPacket.GetDateGoods(GoodsName);
                     if DateValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=DateValue;
                  end;
               gtTime:
                  begin
                     TimeValue:=RecordPacket.GetTimeGoods(GoodsName);
                     if TimeValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=TimeValue;
                  end;
               gtShortString:
                  begin
                     ShortStringValue:=RecordPacket.GetShortStringGoods(GoodsName);
                     Fld.Value:=ShortStringValue;
                  end;
               gtAnsiString:
                  begin
                     AnsiStringValue:=RecordPacket.GetAnsiStringGoods(GoodsName);
                     Fld.Value:=AnsiStringValue;
                  end;
               gtWideString:
                  begin
                     WideStringValue:=RecordPacket.GetWideStringGoods(GoodsName);
                     Fld.Value:=WideStringValue;
                  end;
               gtString:
                  begin
                     StringValue:=RecordPacket.GetStringGoods(GoodsName);
                     Fld.Value:=StringValue;
                  end;
               gtBinary:
                  begin
                     try
                        ok:=RecordPacket.GetStreamGoods(GoodsName,Stream);
                        if ok and (Stream.Size>0) then
                           begin
                              stream.Position:=0;
                              TBlobField(Fld).loadfromstream(stream);
                           end
                        else
                           begin
                              if ok then
                                 TBlobField(Fld).Clear;
                           end;
                     except
                        ok:=false;
                     end;
                     stream.Clear;
                  end;
            end;
          end;
        end;
        if ok then
           sysdataset.Post
        else
        begin
          ErrorCode:='0206304';
          ErrorText:='追加记录到表失败。';
          NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206303';
          ErrorText:='追加记录到表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
        end;
      end;
      if ok and (AutoIncFieldName<>'') then
        AutoIncFieldValue:=SysDataset.fieldbyname(AutoIncFieldName).asinteger;
      SafeFreeUniData(SysDataset);
      if assigned(Stream) then
        FreeAndNil(Stream);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0206302';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
    end;
    if IsOldFormat then
      FreeAndNil(Cds)
    else
      FreeAndNil(RecordPacket);
  end
  else
  begin
    ErrorCode:='0206301';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if ok then
    begin
      if AutoIncFieldValue<>0 then
         BackPacket.PutIntegerGoods('AutoIncFieldValue',AutoIncFieldValue);
    end
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02063: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_AppendRecord(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  TableName,FieldName, AutoIncFieldName: string;
  GoodsName: AnsiString;
  i, j: integer;
  SysDataset: TuniQuery;
  Fld: TField;
  RecordPacket: TwxdPacket;
  Stream: TMemoryStream;
  ByteValue: byte;
  ShortIntValue: shortint;
  WordValue: Word;
  SmallIntValue: SmallInt;
  LongWordValue: LongWord;
  IntegerValue: Integer;
  Int64Value: Int64;
  BooleanValue: Boolean;
  ByteBoolValue: ByteBool;
  WordBoolValue: WordBool;
  LongBoolValue: LongBool;
  SingleValue: Single;
  RealValue: Real;
  DoubleValue: Double;
  CompValue: Comp;
  CurrencyValue: Currency;
  ExtendedValue: Extended;
  DateTimeValue: TDateTime;
  DateValue: TDate;
  TimeValue: TTime;
  ShortStringValue: ShortString;
  AnsiStringValue: AnsiString;
  WideStringValue: WideString;
  StringValue: String;
  IsOldFormat: boolean;
  Cds: TClientdataset;
  EnableBCD: boolean;
begin
  TableName:=TaskPacket.GetStringGoods('TableName');
  IsOldFormat:=TaskPacket.GoodsExists('OldMethodFlag');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('RecordData') then
  begin
    if IsOldFormat then
    begin
       Cds:=TClientDataset.Create(nil);
       Cds.DisableControls;
       Result:=GetCdsFromPacket(TaskPacket,'RecordData',Cds);
       if not Result then
          FreeAndNil(Cds);
    end
    else
    begin
       RecordPacket:=TwxdPacket.Create;
       Result:=GetPacketFromPacket(TaskPacket,'RecordData',RecordPacket);
       if not Result then
          FreeAndNil(RecordPacket);
    end;
  end
  else
  Result:=false;
  if Result then
  begin
    try
      SysDataset:=TuniQuery.Create(nil);
      SysDataset.DisableControls;
      Stream:=TMemoryStream.Create;
      SysDataset.Options.EnableBCD:=EnableBCD;
      SysDataset.Connection:=SysConn;
      SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
      SysDataset.Active:=true;
      sysdataset.append;
      AutoIncFieldName:='';
      if IsOldFormat then
      begin
        for i:=0 to Cds.Fields.Count-1 do
        begin
          FieldName:=Cds.Fields[i].FieldName;
          Fld:=SysDataset.Fields.FindField(FieldName);
          if fld=nil then
             continue;
          if fld.DataType=ftAutoInc then
          begin
            AutoIncFieldName:=Cds.fields[i].FieldName;
            continue;
          end;
          if Cds.fields[i].IsBlob then
          begin
            try
               TBlobField(Cds.fields[i]).savetostream(stream);
               if Stream.Size>0 then
               begin
                 stream.Position:=0;
                 TBlobField(Fld).loadfromstream(stream);
               end
               else
                  TBlobField(Fld).Clear;
               Result:=true;
            except
               Result:=false;
            end;
            stream.Clear;
          end
          else
          begin
            if not Cds.Fields[i].IsNull then
               Fld.Value:=Cds.Fields[i].Value;
          end;
        end;
      end
      else
      begin
        for i:=0 to RecordPacket.GoodsCount-1 do
        begin
          GoodsName:=RecordPacket.GetGoodsName(i);
          FieldName:=string(GoodsName);
          Fld:=SysDataset.FindField(FieldName);
          if fld=nil then
             continue;
          if fld.DataType=ftAutoInc then
          begin
            AutoIncFieldName:=Fld.FieldName;
            continue;
          end;
          j:=RecordPacket.GetGoodsType(GoodsName);
          if j=gtNull then
          begin
            Fld.Clear;
            Continue;
          end;
          case j of
             gtByte:
                begin
                   ByteValue:=RecordPacket.GetByteGoods(GoodsName);
                   Fld.Value:=ByteValue;
                end;
             gtShortInt:
                begin
                   ShortIntValue:=RecordPacket.GetShortIntGoods(GoodsName);
                   Fld.Value:=ShortIntValue;
                end;
             gtWord:
                begin
                   WordValue:=RecordPacket.GetWordGoods(GoodsName);
                   Fld.Value:=WordValue;
                end;
             gtSmallInt:
                begin
                   SmallIntValue:=RecordPacket.GetSmallIntGoods(GoodsName);
                   Fld.Value:=SmallIntValue;
                end;
             gtLongWord:
                begin
                   LongWordValue:=RecordPacket.GetLongWordGoods(GoodsName);
                   Fld.Value:=LongWordValue;
                end;
             gtInteger:
                begin
                   IntegerValue:=RecordPacket.GetIntegerGoods(GoodsName);
                   Fld.Value:=IntegerValue;
                end;
             gtInt64:
                begin
                   Int64Value:=RecordPacket.GetInt64Goods(GoodsName);
                   Fld.Value:=Int64Value;
                end;
             gtBoolean:
                begin
                   BooleanValue:=RecordPacket.GetBooleanGoods(GoodsName);
                   Fld.Value:=BooleanValue;
                end;
             gtByteBool:
                begin
                   ByteBoolValue:=RecordPacket.GetByteBoolGoods(GoodsName);
                   Fld.Value:=ByteBoolValue;
                end;
             gtWordBool:
                begin
                   WordBoolValue:=RecordPacket.GetWordBoolGoods(GoodsName);
                   Fld.Value:=WordBoolValue;
                end;
             gtLongBool:
                begin
                   LongBoolValue:=RecordPacket.GetLongBoolGoods(GoodsName);
                   Fld.Value:=LongBoolValue;
                end;
             gtSingle:
                begin
                   SingleValue:=RecordPacket.GetSingleGoods(GoodsName);
                   Fld.Value:=SingleValue;
                end;
             gtReal:
                begin
                   RealValue:=RecordPacket.GetRealGoods(GoodsName);
                   Fld.Value:=RealValue;
                end;
             gtDouble:
                begin
                   DoubleValue:=RecordPacket.GetDoubleGoods(GoodsName);
                   Fld.Value:=DoubleValue;
                end;
             gtComp:
                begin
                   CompValue:=RecordPacket.GetCompGoods(GoodsName);
                   Fld.Value:=CompValue;
                end;
             gtCurrency:
                begin
                   CurrencyValue:=RecordPacket.GetCurrencyGoods(GoodsName);
                   Fld.Value:=CurrencyValue;
                end;
             gtExtended:
                begin
                   ExtendedValue:=RecordPacket.GetExtendedGoods(GoodsName);
                   Fld.Value:=ExtendedValue;
                end;
             gtDateTime:
                begin
                   DateTimeValue:=RecordPacket.GetDateTimeGoods(GoodsName);
                   if DateTimeValue=0 then
                      Fld.Clear
                   else
                      Fld.Value:=DateTimeValue;
                end;
             gtDate:
                begin
                   DateValue:=RecordPacket.GetDateGoods(GoodsName);
                   if DateValue=0 then
                      Fld.Clear
                   else
                      Fld.Value:=DateValue;
                end;
             gtTime:
                begin
                   TimeValue:=RecordPacket.GetTimeGoods(GoodsName);
                   if TimeValue=0 then
                      Fld.Clear
                   else
                      Fld.Value:=TimeValue;
                end;
             gtShortString:
                begin
                   ShortStringValue:=RecordPacket.GetShortStringGoods(GoodsName);
                   Fld.Value:=ShortStringValue;
                end;
             gtAnsiString:
                begin
                   AnsiStringValue:=RecordPacket.GetAnsiStringGoods(GoodsName);
                   Fld.Value:=AnsiStringValue;
                end;
             gtWideString:
                begin
                   WideStringValue:=RecordPacket.GetWideStringGoods(GoodsName);
                   Fld.Value:=WideStringValue;
                end;
             gtString:
                begin
                   StringValue:=RecordPacket.GetStringGoods(GoodsName);
                   Fld.Value:=StringValue;
                end;
             gtBinary:
                begin
                  try
                    Result:=RecordPacket.GetStreamGoods(GoodsName,Stream);
                    if Result and (Stream.Size>0) then
                    begin
                      stream.Position:=0;
                      TBlobField(Fld).loadfromstream(stream);
                    end
                    else
                    begin
                      if Result then
                         TBlobField(Fld).Clear;
                    end;
                  except
                    Result:=false;
                  end;
                  stream.Clear;
                end;
          end;
        end;
      end;
      if Result then
         sysdataset.Post
      else
      begin
        ErrorCode:='0206304';
        ErrorText:='追加记录至数据表失败。';
        NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
      end;
    except
      on E: Exception do
         begin
            Result:=false;
            ErrorCode:='0206303';
            ErrorText:='追加记录至数据表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
            NodeService.syslog.Log('数据库：['+sysConn.Database+']Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
         end;
    end;
    if Result and (AutoIncFieldName<>'') then
      RetValue:=AnsiString(SysDataset.fieldbyname(AutoIncFieldName).asstring)
    else
      RetValue:='';
    SafeFreeUniData(SysDataset);
    if assigned(Stream) then
      FreeAndNil(Stream);
    if IsOldFormat then
      FreeAndNil(Cds)
    else
      FreeAndNil(RecordPacket);
  end
  else
  begin
    RetValue:='';
    ErrorCode:='0206301';
    ErrorText:='无效参数。';
  end;
end;

procedure TTaskThread.Task_UpdateRecord;
var
  ok: boolean;
  DatabaseId: AnsiString;
  FilterCondition,TableName,FieldName: string;
  GoodsName: AnsiString;
  i,j,k: integer;
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  PoolId,ConnectionId: integer;
  Fld: TField;
  RecordPacket: TwxdPacket;
  Stream: TMemoryStream;
  ByteValue: byte;
  ShortIntValue: shortint;
  WordValue: Word;
  SmallIntValue: SmallInt;
  LongWordValue: LongWord;
  IntegerValue: Integer;
  Int64Value: Int64;
  BooleanValue: Boolean;
  ByteBoolValue: ByteBool;
  WordBoolValue: WordBool;
  LongBoolValue: LongBool;
  SingleValue: Single;
  RealValue: Real;
  DoubleValue: Double;
  CompValue: Comp;
  CurrencyValue: Currency;
  ExtendedValue: Extended;
  DateTimeValue: TDateTime;
  DateValue: TDate;
  TimeValue: TTime;
  ShortStringValue: ShortString;
  AnsiStringValue: AnsiString;
  WideStringValue: WideString;
  StringValue: String;
  IsOldFormat: boolean;
  Cds: TClientdataset;
  EnableBCD: boolean;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  FilterCondition:=RequestPacket.GetStringGoods('FilterCondition');
  TableName:=RequestPacket.GetStringGoods('TableName');
  IsOldFormat:=RequestPacket.GoodsExists('OldMethodFlag');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    k:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    k:=-1;
  if RequestPacket.GoodsExists('RecordData') then
  begin
    if IsOldFormat then
    begin
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      Ok:=GetCdsFromPacket(RequestPacket,'RecordData',Cds);
      if not ok then
        FreeAndNil(Cds);
    end
    else
    begin
      RecordPacket:=TwxdPacket.Create;
      ok:=GetPacketFromPacket(RequestPacket,'RecordData',RecordPacket);
      if not ok then
        FreeAndNil(RecordPacket);
    end;
  end
  else
  ok:=false;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (k<>-1) then
      ok:=SetIsoLevel(SysConn,k);
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.DisableControls;
        Stream:=TMemoryStream.Create;
        SysDataset.Options.EnableBCD:=EnableBCD;
        SysDataset.Connection:=SysConn;
        if FilterCondition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+TableName
        else
           SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+FilterCondition;
        SysDataset.Active:=true;
        ok:=(SysDataset.RecordCount<>0);
        if ok then
        begin
          sysdataset.edit;
          if IsOldFormat then
          begin
            for i:=0 to Cds.Fields.Count-1 do
            begin
              FieldName:=Cds.Fields[i].FieldName;
              Fld:=SysDataset.Fields.FindField(FieldName);
              if (fld=nil) or (fld.DataType=ftAutoInc) then
                 continue;
              if Cds.fields[i].IsBlob then
              begin
                try
                   TBlobField(Cds.fields[i]).savetostream(stream);
                   stream.Position:=0;
                   if Stream.Size=0 then
                      TBlobField(Fld).Clear
                   else
                      TBlobField(Fld).loadfromstream(stream);
                   ok:=true;
                except
                   ok:=false;
                end;
                stream.Clear;
              end
              else
              begin
                if Cds.Fields[i].IsNull then
                   Fld.Clear
                else
                   Fld.Value:=Cds.Fields[i].Value;
              end;
            end;
          end
          else
          begin
            for i:=0 to RecordPacket.GoodsCount-1 do
            begin
              GoodsName:=RecordPacket.GetGoodsName(i);
              FieldName:=string(GoodsName);
              Fld:=SysDataset.Fields.FindField(FieldName);
              if (fld=nil) or (fld.DataType=ftAutoInc) then
                 continue;
              j:=RecordPacket.GetGoodsType(GoodsName);
              if j=gtNull then
              begin
                Fld.Clear;
                Continue;
              end;
              case j of
                 gtByte:
                    begin
                       ByteValue:=RecordPacket.GetByteGoods(GoodsName);
                       Fld.Value:=ByteValue;
                    end;
                 gtShortInt:
                    begin
                       ShortIntValue:=RecordPacket.GetShortIntGoods(GoodsName);
                       Fld.Value:=ShortIntValue;
                    end;
                 gtWord:
                    begin
                       WordValue:=RecordPacket.GetWordGoods(GoodsName);
                       Fld.Value:=WordValue;
                    end;
                 gtSmallInt:
                    begin
                       SmallIntValue:=RecordPacket.GetSmallIntGoods(GoodsName);
                       Fld.Value:=SmallIntValue;
                    end;
                 gtLongWord:
                    begin
                       LongWordValue:=RecordPacket.GetLongWordGoods(GoodsName);
                       Fld.Value:=LongWordValue;
                    end;
                 gtInteger:
                    begin
                       IntegerValue:=RecordPacket.GetIntegerGoods(GoodsName);
                       Fld.Value:=IntegerValue;
                    end;
                 gtInt64:
                    begin
                       Int64Value:=RecordPacket.GetInt64Goods(GoodsName);
                       Fld.Value:=Int64Value;
                    end;
                 gtBoolean:
                    begin
                       BooleanValue:=RecordPacket.GetBooleanGoods(GoodsName);
                       Fld.Value:=BooleanValue;
                    end;
                 gtByteBool:
                    begin
                       ByteBoolValue:=RecordPacket.GetByteBoolGoods(GoodsName);
                       Fld.Value:=ByteBoolValue;
                    end;
                 gtWordBool:
                    begin
                       WordBoolValue:=RecordPacket.GetWordBoolGoods(GoodsName);
                       Fld.Value:=WordBoolValue;
                    end;
                 gtLongBool:
                    begin
                       LongBoolValue:=RecordPacket.GetLongBoolGoods(GoodsName);
                       Fld.Value:=LongBoolValue;
                    end;
                 gtSingle:
                    begin
                       SingleValue:=RecordPacket.GetSingleGoods(GoodsName);
                       Fld.Value:=SingleValue;
                    end;
                 gtReal:
                    begin
                       RealValue:=RecordPacket.GetRealGoods(GoodsName);
                       Fld.Value:=RealValue;
                    end;
                 gtDouble:
                    begin
                       DoubleValue:=RecordPacket.GetDoubleGoods(GoodsName);
                       Fld.Value:=DoubleValue;
                    end;
                 gtComp:
                    begin
                       CompValue:=RecordPacket.GetCompGoods(GoodsName);
                       Fld.Value:=CompValue;
                    end;
                 gtCurrency:
                    begin
                       CurrencyValue:=RecordPacket.GetCurrencyGoods(GoodsName);
                       Fld.Value:=CurrencyValue;
                    end;
                 gtExtended:
                    begin
                       ExtendedValue:=RecordPacket.GetExtendedGoods(GoodsName);
                       Fld.Value:=ExtendedValue;
                    end;
                 gtDateTime:
                    begin
                       DateTimeValue:=RecordPacket.GetDateTimeGoods(GoodsName);
                       if DateTimeValue=0 then
                          Fld.Clear
                       else
                          Fld.Value:=DateTimeValue;
                    end;
                 gtDate:
                    begin
                       DateValue:=RecordPacket.GetDateGoods(GoodsName);
                       if DateValue=0 then
                          Fld.Clear
                       else
                          Fld.Value:=DateValue;
                    end;
                 gtTime:
                    begin
                       TimeValue:=RecordPacket.GetTimeGoods(GoodsName);
                       if TimeValue=0 then
                          Fld.Clear
                       else
                          Fld.Value:=TimeValue;
                    end;
                 gtShortString:
                    begin
                       ShortStringValue:=RecordPacket.GetShortStringGoods(GoodsName);
                       Fld.Value:=ShortStringValue;
                    end;
                 gtAnsiString:
                    begin
                       AnsiStringValue:=RecordPacket.GetAnsiStringGoods(GoodsName);
                       Fld.Value:=AnsiStringValue;
                    end;
                 gtWideString:
                    begin
                       WideStringValue:=RecordPacket.GetWideStringGoods(GoodsName);
                       Fld.Value:=WideStringValue;
                    end;
                 gtString:
                    begin
                       StringValue:=RecordPacket.GetStringGoods(GoodsName);
                       Fld.Value:=StringValue;
                    end;
                 gtBinary:
                    begin
                      try
                        ok:=RecordPacket.GetStreamGoods(GoodsName,Stream);
                        if ok then
                        begin
                          stream.Position:=0;
                          if Stream.Size=0 then
                             TBlobField(Fld).Clear
                          else
                             TBlobField(Fld).loadfromstream(stream);
                        end;
                      except
                        ok:=false;
                      end;
                      stream.Clear;
                    end;
              end;
            end;
          end;
          if ok then
             sysdataset.Post
          else
          begin
            ErrorCode:='0206403';
            ErrorText:='更新记录至表失败.';
            NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
          end;
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206403';
          ErrorText:='更新记录至表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(FilterCondition));
        end;
      end;
      SafeFreeUniData(SysDataset);
      if assigned(Stream) then
        FreeAndNil(Stream);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0206402';
      ErrorText:='分配数据库连接失败。';
      NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(FilterCondition));
    end;
    if IsOldFormat then
      FreeAndNil(Cds)
    else
      FreeAndNil(RecordPacket);
  end
  else
  begin
    ErrorCode:='0206401';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('数据库：['+sysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(FilterCondition));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02064: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_UpdateRecord(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  FilterCondition,TableName,FieldName: string;
  GoodsName: AnsiString;
  i,j: integer;
  SysDataset: TuniQuery;
  Fld: TField;
  RecordPacket: TwxdPacket;
  Stream: TMemoryStream;
  ByteValue: byte;
  ShortIntValue: shortint;
  WordValue: Word;
  SmallIntValue: SmallInt;
  LongWordValue: LongWord;
  IntegerValue: Integer;
  Int64Value: Int64;
  BooleanValue: Boolean;
  ByteBoolValue: ByteBool;
  WordBoolValue: WordBool;
  LongBoolValue: LongBool;
  SingleValue: Single;
  RealValue: Real;
  DoubleValue: Double;
  CompValue: Comp;
  CurrencyValue: Currency;
  ExtendedValue: Extended;
  DateTimeValue: TDateTime;
  DateValue: TDate;
  TimeValue: TTime;
  ShortStringValue: ShortString;
  AnsiStringValue: AnsiString;
  WideStringValue: WideString;
  StringValue: String;
  IsOldFormat: boolean;
  Cds: TClientdataset;
  EnableBCD: boolean;
begin
  FilterCondition:=TaskPacket.GetStringGoods('FilterCondition');
  TableName:=TaskPacket.GetStringGoods('TableName');
  IsOldFormat:=TaskPacket.GoodsExists('OldMethodFlag');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('RecordData') then
  begin
    if IsOldFormat then
    begin
      Cds:=TClientDataset.Create(nil);
      Cds.DisableControls;
      Result:=GetCdsFromPacket(TaskPacket,'RecordData',Cds);
      if not Result then
         FreeAndNil(Cds);
    end
    else
    begin
      RecordPacket:=TwxdPacket.Create;
      Result:=GetPacketFromPacket(TaskPacket,'RecordData',RecordPacket);
      if not Result then
         FreeAndNil(RecordPacket);
    end;
  end
  else
    Result:=false;
  if Result then
  begin
    try
      SysDataset:=TUniQuery.Create(nil);
      SysDataset.DisableControls;
      Stream:=TMemoryStream.Create;
      SysDataset.Options.EnableBCD:=EnableBCD;
      SysDataset.Connection:=SysConn;
      if FilterCondition='' then
         SysDataset.SQL.Text:='SELECT * FROM '+TableName
      else
         SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+FilterCondition;
      SysDataset.Active:=true;
      Result:=(SysDataset.RecordCount<>0);
      if Result then
      begin
        sysdataset.edit;
        if IsOldFormat then
        begin
          for i:=0 to Cds.Fields.Count-1 do
          begin
            FieldName:=Cds.Fields[i].FieldName;
            Fld:=SysDataset.Fields.FindField(FieldName);
            if (fld=nil) or (fld.DataType=ftAutoInc) then
               continue;
            if Cds.fields[i].IsBlob then
            begin
              try
                 TBlobField(Cds.fields[i]).savetostream(stream);
                 stream.Position:=0;
                 if Stream.Size=0 then
                    TBlobField(Fld).Clear
                 else
                    TBlobField(Fld).loadfromstream(stream);
                 Result:=true;
              except
                 Result:=false;
              end;
              stream.Clear;
            end
            else
            begin
              if Cds.Fields[i].IsNull then
                 Fld.Clear
              else
                 Fld.Value:=Cds.Fields[i].Value;
            end;
          end;
        end
        else
        begin
          for i:=0 to RecordPacket.GoodsCount-1 do
          begin
            GoodsName:=RecordPacket.GetGoodsName(i);
            FieldName:=string(GoodsName);
            Fld:=SysDataset.Fields.FindField(FieldName);
            if (fld=nil) or (fld.DataType=ftAutoInc) then
               continue;
            j:=RecordPacket.GetGoodsType(GoodsName);
            if j=gtNull then
            begin
              Fld.Clear;
              Continue;
            end;
            case j of
               gtByte:
                  begin
                     ByteValue:=RecordPacket.GetByteGoods(GoodsName);
                     Fld.Value:=ByteValue;
                  end;
               gtShortInt:
                  begin
                     ShortIntValue:=RecordPacket.GetShortIntGoods(GoodsName);
                     Fld.Value:=ShortIntValue;
                  end;
               gtWord:
                  begin
                     WordValue:=RecordPacket.GetWordGoods(GoodsName);
                     Fld.Value:=WordValue;
                  end;
               gtSmallInt:
                  begin
                     SmallIntValue:=RecordPacket.GetSmallIntGoods(GoodsName);
                     Fld.Value:=SmallIntValue;
                  end;
               gtLongWord:
                  begin
                     LongWordValue:=RecordPacket.GetLongWordGoods(GoodsName);
                     Fld.Value:=LongWordValue;
                  end;
               gtInteger:
                  begin
                     IntegerValue:=RecordPacket.GetIntegerGoods(GoodsName);
                     Fld.Value:=IntegerValue;
                  end;
               gtInt64:
                  begin
                     Int64Value:=RecordPacket.GetInt64Goods(GoodsName);
                     Fld.Value:=Int64Value;
                  end;
               gtBoolean:
                  begin
                     BooleanValue:=RecordPacket.GetBooleanGoods(GoodsName);
                     Fld.Value:=BooleanValue;
                  end;
               gtByteBool:
                  begin
                     ByteBoolValue:=RecordPacket.GetByteBoolGoods(GoodsName);
                     Fld.Value:=ByteBoolValue;
                  end;
               gtWordBool:
                  begin
                     WordBoolValue:=RecordPacket.GetWordBoolGoods(GoodsName);
                     Fld.Value:=WordBoolValue;
                  end;
               gtLongBool:
                  begin
                     LongBoolValue:=RecordPacket.GetLongBoolGoods(GoodsName);
                     Fld.Value:=LongBoolValue;
                  end;
               gtSingle:
                  begin
                     SingleValue:=RecordPacket.GetSingleGoods(GoodsName);
                     Fld.Value:=SingleValue;
                  end;
               gtReal:
                  begin
                     RealValue:=RecordPacket.GetRealGoods(GoodsName);
                     Fld.Value:=RealValue;
                  end;
               gtDouble:
                  begin
                     DoubleValue:=RecordPacket.GetDoubleGoods(GoodsName);
                     Fld.Value:=DoubleValue;
                  end;
               gtComp:
                  begin
                     CompValue:=RecordPacket.GetCompGoods(GoodsName);
                     Fld.Value:=CompValue;
                  end;
               gtCurrency:
                  begin
                     CurrencyValue:=RecordPacket.GetCurrencyGoods(GoodsName);
                     Fld.Value:=CurrencyValue;
                  end;
               gtExtended:
                  begin
                     ExtendedValue:=RecordPacket.GetExtendedGoods(GoodsName);
                     Fld.Value:=ExtendedValue;
                  end;
               gtDateTime:
                  begin
                     DateTimeValue:=RecordPacket.GetDateTimeGoods(GoodsName);
                     if DateTimeValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=DateTimeValue;
                  end;
               gtDate:
                  begin
                     DateValue:=RecordPacket.GetDateGoods(GoodsName);
                     if DateValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=DateValue;
                  end;
               gtTime:
                  begin
                     TimeValue:=RecordPacket.GetTimeGoods(GoodsName);
                     if TimeValue=0 then
                        Fld.Clear
                     else
                        Fld.Value:=TimeValue;
                  end;
               gtShortString:
                  begin
                     ShortStringValue:=RecordPacket.GetShortStringGoods(GoodsName);
                     Fld.Value:=ShortStringValue;
                  end;
               gtAnsiString:
                  begin
                     AnsiStringValue:=RecordPacket.GetAnsiStringGoods(GoodsName);
                     Fld.Value:=AnsiStringValue;
                  end;
               gtWideString:
                  begin
                     WideStringValue:=RecordPacket.GetWideStringGoods(GoodsName);
                     Fld.Value:=WideStringValue;
                  end;
               gtString:
                  begin
                     StringValue:=RecordPacket.GetStringGoods(GoodsName);
                     Fld.Value:=StringValue;
                  end;
               gtBinary:
                  begin
                     try
                       Result:=RecordPacket.GetStreamGoods(GoodsName,Stream);
                       if Result then
                       begin
                          stream.Position:=0;
                          if Stream.Size=0 then
                             TBlobField(Fld).Clear
                          else
                             TBlobField(Fld).loadfromstream(stream);
                       end;
                     except
                        Result:=false;
                     end;
                     stream.Clear;
                  end;
            end;
          end;
        end;
        if Result then
           sysdataset.Post
        else
        begin
          ErrorCode:='0206404';
          ErrorText:='数据表更新失败。';
          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(FilterCondition));
        end;
      end;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0206403';
        ErrorText:='数据表更新失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(FilterCondition));
      end;
    end;
    SafeFreeUniData(SysDataset);
    if assigned(Stream) then
      FreeAndNil(Stream);
    if IsOldFormat then
      FreeAndNil(Cds)
    else
      FreeAndNil(RecordPacket);
  end
  else
  begin
    ErrorCode:='0206401';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_GetTableHead;
var
  ok: boolean;
  DatabaseId: AnsiString;
  TableName,err: string;
  PoolId,ConnectionId,j: integer;
  SysConn: TuniConnection;
  SysDataset: TUniQuery;
  Stream: TMemoryStream;
  EnableBCD,IsUnicode: boolean;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=(DatabaseId<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
       try
          Stream:=TMemoryStream.Create;
          SysDataset:=TUniQuery.Create(nil);
          SysDataset.DisableControls;
          SysDataset.Options.EnableBCD:=EnableBCD;
          SysDataset.Connection:=SysConn;
          SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
          SysDataset.active:=true;
          ok := DatasetZipToCdsStream(SysDataset,Stream,IsUnicode,err);
          if not ok then
          begin
            FreeAndNil(Stream);
            ErrorCode:='0206504';
            ErrorText:='读表头信息失败: '+ansistring(err);
            NodeService.syslog.Log('数据库['+sysConn.Database+'[ Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
          end;
       except
          on E: Exception do
          begin
            ok:=false;
            ErrorCode:='0206503';
            ErrorText:='读表头信息失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
            NodeService.syslog.Log('数据库['+sysConn.Database+'[ Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
            if assigned(Stream) then
               FreeAndNil(Stream);
          end;
      end;
       SafeFreeUniData(SysDataset);
       NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0206502';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('数据库['+sysConn.Database+'[ Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
    end;
  end
  else
  begin
    ErrorCode:='0206501';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('数据库['+sysConn.Database+'[ Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      ok:=BackPacket.PutStreamGoods('TableHead',Stream);
      FreeAndNil(Stream);
      if not ok then
      begin
        ErrorCode:='0206501';
        ErrorText:='返回表头信息数据失败。';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName));
      end;
    end;
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
      NodeService.syslog.Log('Err02065: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_GenerateKeyId;
var
  ok: boolean;
  i,j,k: integer;
  DatabaseId: AnsiString;
  TableName,KeyFieldName,FilterCondition: string;
  FieldMask,ConstList, NormalStr: ansistring;
  SysConn: TuniConnection;
  SysDataset: TUniQuery;
  PoolId,ConnectionId: integer;
  EnableBCD: boolean;
begin
  DatabaseId:=Uppercase(RequestPacket.GetEncryptStringGoods('DatabaseId'));
  TableName:=Uppercase(RequestPacket.GetStringGoods('TableName'));
  KeyFieldName:=Uppercase(RequestPacket.GetStringGoods('KeyFieldName'));
  FilterCondition:=RequestPacket.GetStringGoods('FilterCondition');
  FieldMask:=RequestPacket.GetEncryptStringGoods('FieldMask');
  ConstList:=RequestPacket.GetEncryptStringGoods('ConstList');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  ok:=(TableName<>'') and (KeyFieldName<>'') and (FieldMask<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok then
    begin
      EnterCriticalSection(NodeService.IdGenCs);
      try
        j:=-1;
        for i:=0 to NodeService.IdCount-1 do
          if (StrComp(PChar(NodeService.Ids[i].dbname),PChar(string(DatabaseId)))=0)
             and (StrComp(PChar(NodeService.Ids[i].tablename),PChar(TableName))=0)
             and (StrComp(PChar(NodeService.Ids[i].fieldname),PChar(KeyFieldName))=0)
             and (StrComp(PChar(NodeService.Ids[i].Condition),PChar(FilterCondition))=0)
             and (round((now-NodeService.Ids[i].LastActiveTime)*24*60)<30) then
             begin
                j:=i;
                break;
             end;
        if j=-1 then
        begin
          try
            SysDataset:=TUniQuery.Create(nil);
            SysDataset.DisableControls;
            SysDataset.Options.EnableBCD:=EnableBCD;
            SysDataset.Connection:=SysConn;
            if FilterCondition<>'' then
               SysDataset.SQL.Text:='SELECT MAX('+keyfieldName+') FROM '+tablename+' WHERE '+FilterCondition
            else
               SysDataset.SQL.Text:='SELECT MAX('+keyfieldName+') FROM '+tablename;
            SysDataset.Active:=true;
            if SysDataset.RecordCount<=0 then
               NormalStr:=GetFirstValue(FieldMask,ConstList)
            else
            begin
              NormalStr:=AnsiString(trim(SysDataset.Fields[0].AsString));
              if trim(NormalStr)='' then
                 NormalStr:=GetFirstValue(FieldMask,ConstList);
            end;
            ok:=true;
          except
            on E: Exception do
            begin
              ok:=false;
              ErrorCode:='0206603';
              ErrorText:='首个ID值初始化失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
              NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
              NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldName)+#13#10+AnsiString(FilterCondition));
              NormalStr:='';
            end;
          end;
          SafeFreeUniData(SysDataset);
          ok:=ok and (trim(NormalStr)<>'');
          if not ok then
          begin
             SaveErrorResponse(ErrorCode,ErrorText);
             LeaveCriticalSection(NodeService.IdGenCs);
             NodeService.FreeConnection(PoolId,ConnectionId);
             exit;
          end;
          j:=NodeService.IdCount;
          inc(NodeService.IdCount);
          setlength(NodeService.Ids,NodeService.IdCount);
          if (FieldMask='A') or (FieldMask='I') then
            k:=1
          else
            k:=2;
          NodeService.Ids[j].dbname:=String(DatabaseId);
          NodeService.Ids[j].tablename:=TableName;
          NodeService.Ids[j].fieldname:=KeyFieldName;
          NodeService.Ids[j].fieldtype:=k;
          NodeService.Ids[j].Condition:=FilterCondition;
          NodeService.Ids[j].LastValue:=NormalStr;
          NodeService.Ids[j].FreeIdCount:=0;
          setlength(NodeService.Ids[j].FreeIds,0);
          inc(NodeService.ActiveIds);
        end;
         NodeService.Ids[j].LastActiveTime:=now;
         if NodeService.Ids[j].FreeIdCount>0 then
         begin
           NormalStr:=NodeService.ids[j].freeids[NodeService.Ids[j].FreeIdCount-1];
           dec(NodeService.Ids[j].FreeIdCount);
           setlength(NodeService.Ids[j].FreeIds,NodeService.Ids[j].FreeIdCount);
         end
         else
         begin
           NormalStr:=NextKeyValue(FieldMask, NodeService.Ids[j].LastValue,ConstList);
           NodeService.Ids[j].LastValue:=NormalStr;
         end;
         ok:=true;
      except
         ok:=false;
      end;
      LeaveCriticalSection(NodeService.IdGenCs);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0206602';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldName)+#13#10+AnsiString(FilterCondition));
    end;
  end
  else
  begin
    ErrorCode:='0206601';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldName)+#13#10+AnsiString(FilterCondition));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if ok then
    BackPacket.PutEncryptStringGoods('NewKeyFieldId',NormalStr)
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02054: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_FreeKeyId;
var
  ok: boolean;
  i,j,k: integer;
  DatabaseId: AnsiString;
  TableName,KeyFieldName,FilterCondition: string;
  IdToFree: ansistring;
begin
  DatabaseId:=Uppercase(RequestPacket.GetEncryptStringGoods('DatabaseId'));
  TableName:=Uppercase(RequestPacket.GetStringGoods('TableName'));
  KeyFieldName:=Uppercase(RequestPacket.GetStringGoods('KeyFieldName'));
  FilterCondition:=RequestPacket.GetStringGoods('FilterCondition');
  IdToFree:=RequestPacket.GetEncryptStringGoods('IdToFree');
  ok:=(TableName<>'') and (KeyFieldName<>'') and (IdToFree<>'');
  if ok then
  begin
    EnterCriticalSection(NodeService.IdGenCs);
    try
      j:=-1;
      for i:=0 to NodeService.IdCount-1 do
        if (StrComp(PChar(NodeService.Ids[i].dbname),PChar(string(DatabaseId)))=0)
           and (StrComp(PChar(NodeService.Ids[i].tablename),PChar(TableName))=0)
           and (StrComp(PChar(NodeService.Ids[i].fieldname),PChar(KeyFieldName))=0)
           and (StrComp(PChar(NodeService.Ids[i].Condition),PChar(FilterCondition))=0)
           and (round((now-NodeService.Ids[i].LastActiveTime)*24*60)<30) then
           begin
              j:=i;
              break;
           end;
      if j<>-1 then
      begin
        k:=-1;
        for i:=0 to NodeService.Ids[j].FreeIdCount-1 do
          if NodeService.Ids[j].FreeIds[i]=IdToFree then
          begin
            k:=i;
            break;
          end;
        if k=-1 then
        begin
          k:=NodeService.Ids[j].FreeIdCount;
          inc(NodeService.Ids[j].FreeIdCount);
          setlength(NodeService.Ids[j].FreeIds,NodeService.Ids[j].FreeIdCount);
          NodeService.Ids[j].FreeIds[k]:=IdToFree;
          NodeService.Ids[j].LastActiveTime:=now;
        end;
      end;
     Ok:=(j<>-1);
    except
     ok:=false;
    end;
    LeaveCriticalSection(NodeService.IdGenCs);
    if not ok then
    begin
      ErrorCode:='0206702';
      ErrorText:='释放使用的字段关键值失败。';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldName)+#13#10+AnsiString(FilterCondition));
    end;
  end
  else
  begin
    ErrorCode:='0206701';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldName)+#13#10+AnsiString(FilterCondition));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02054: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.ResolveKeyFields(const Cds: TClientDataset; const FieldList: String): boolean;
var
   j,i: integer;
   tmpstr,kname: String;
begin
   keyFieldCount:=0;
   SetLength(KeyFields,0);
   if trim(fieldlist)='' then
      begin
         for i := 0 to Cds.Fields.Count-1 do
            begin
               if Cds.Fields[i].DataType in [ftUnknown, ftBytes, ftVarBytes,
                  ftBlob, ftGraphic, ftParadoxOle, ftDBaseOle,
                  ftTypedBinary, ftCursor, ftADT, ftArray, ftReference, ftDataSet,
                  ftOraBlob, ftOraClob, ftVariant, ftInterface, ftIDispatch,
                  ftConnection, ftParams, ftStream, ftTimeStampOffset, ftObject] then
                  continue;
               j:=keyFieldCount;
               inc(keyFieldCount);
               SetLength(KeyFields,keyFieldCount);
               KeyFields[j]:=Cds.Fields[i].FieldName;
            end;
         result:=(keyFieldCount>0);
         exit;
      end;
   result:=true;
   tmpstr:=trim(FieldList);
   if copy(tmpstr,length(tmpstr),1)<>',' then
      tmpstr:=tmpstr+',';
   j:=pos(',',tmpstr);
   while j>1 do
      begin
         kname:=copy(tmpstr,1,j-1);
         delete(tmpstr,1,j);
         if Cds.FindField(kname)=nil then
            begin
               result:=false;
               break;
            end;
         j:=KeyFieldCount;
         inc(KeyFieldCount);
         SetLength(KeyFields,KeyFieldCount);
         KeyFields[j]:=kName;
         j:=pos(',',tmpstr);
      end;
end;

function TTaskThread.TwoQuotes(const SourceStr: string): string;
var
   i,j: integer;
begin
   result:='';
   j:=length(SourceStr);
   i:=1;
   while i<=j do
      begin
         if SourceStr[i]='''' then
            Result:=Result+''''''
         else
            result:=result+SourceStr[i];
         inc(i);
      end;
end;

function TTaskThread.LocateRecord(const Cds: TClientDataset; const uniQuery: TUniQuery; const UpdateNull: boolean; const DataCds: TClientDataset; Var uniErr: ansistring): Boolean;
var
  sql: String;
  i: integer;
  ok: boolean;
begin
  uniQuery.Active:=false;
  uniQuery.LockMode:=lmOptimistic;
  sql:='SELECT * FROM '+n_TableName+' WHERE ';
  for i:=0 to KeyFieldCount-1 do
  begin
    if i>0 then
      sql:=sql+' AND ';
    if cds.fieldbyname(keyfields[i]).isnull then
      sql:=sql+'('+KeyFields[i]+' IS NULL)'
    else
    begin
      if cds.FindField(KeyFields[i]).DataType
      in [ftString,ftWideString,ftFixedChar,ftFixedWideChar,ftMemo,ftFmtMemo,ftGUID] then
      begin
        if pos('''',trim(cds.fieldbyname(KeyFields[i]).AsString))>0 then
          sql:=sql+'('+KeyFields[i]+'='''+TwoQuotes(trim(cds.fieldbyname(KeyFields[i]).AsString))+''')'
        else
          sql:=sql+'('+KeyFields[i]+'='''+trim(cds.fieldbyname(KeyFields[i]).AsString)+''')';
      end
      else
      begin
        if (cds.FindField(KeyFields[i]).DataType=ftDateTime) or (cds.FindField(KeyFields[i]).DataType=ftDate) or (cds.FindField(KeyFields[i]).DataType=ftTime) then
          sql:=sql+'('+KeyFields[i]+'='''+formatdatetime('yyyymmdd hh:nn:ss',cds.fieldbyname(KeyFields[i]).AsDateTime)+''')'
        else
          sql:=sql+'('+KeyFields[i]+'='+trim(cds.fieldbyname(KeyFields[i]).AsString)+')';
      end;
    end;
  end;
  uniQuery.SQL.Text:=sql;
  try
    uniQuery.Active:=true;
    result:=(uniQuery.RecordCount=1);
    uniErr:='';
  except
    on E: Exception do
    begin
      result:=false;
      uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
    end;
  end;
  if not result then
    uniQuery.Active:=false
  else
  begin
    if UpdateNull then
    begin
      result:=false;
      try
        DataCds.First;
        while not DataCds.Eof do
        begin
          ok:=true;
          for i:=0 to KeyFieldCount-1 do
          begin
            if Cds.FieldValues[KeyFields[i]]<>DataCds.FieldValues[KeyFields[i]] then
            begin
              ok:=false;
              break;
            end;
          end;
          if ok then
          begin
            result:=true;
            break;
          end;
          DataCds.Next;
        end;
      except
      on E: Exception do
        begin
          result:=false;
          uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        end;
      end;
    end;
  end;
end;

function TTaskThread.UpdateRecord(const Cds: TClientDataset; const uniQuery: TuniQuery; const UpdateNull: boolean; const MatchStrictly: boolean; var uniErr: AnsiString): Boolean;
var
  i: integer;
  stream: TMemoryStream;
  Fld: TField;
begin
  if not uniQuery.Active then
  begin
    result:=false;
    exit;
  end;
  try
    result:=true;
    uniQuery.Edit;
    for i:=0 to Cds.Fields.Count-1 do
    begin
      Fld:=uniQuery.FindField(Cds.Fields[i].FieldName);
      if fld=nil then
      begin
        if MatchStrictly then
        begin
          result:=false;
          break;
        end;
        continue;
      end;
      if (Fld.DataType=ftAutoInc) or (Fld.DataType=ftBytes) then
         continue;
      if not UpdateNull then
      begin
        if Cds.Fields[i].IsNull then
          continue;
      end;
      if Fld.IsBlob and (Fld.DataType<>ftMemo) and (Fld.DataType<>ftFmtMemo)
          and (Fld.DataType<>ftWideMemo) then
      begin
        Stream:=nil;
        try
          Stream:=TMemoryStream.create;
          TBlobField(Cds.fields[i]).savetostream(Stream);
          Stream.Position:=0;
          if Stream.Size>0 then
             TBlobField(Fld).loadfromstream(Stream)
          else
             TBlobField(Fld).Clear;
        except
          on E: Exception do
          begin
            result:=false;
            uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          end;
        end;
        if assigned(Stream) then
           FreeAndNil(Stream);
        if not result then
           break;
      end
      else
      begin
        if Cds.Fields[i].Value=Fld.value then
           continue;
        if Cds.Fields[i].IsNull then
           Fld.Clear
        else
           Fld.Value:=Cds.Fields[i].Value;
      end;
    end;
    if result then
      uniQuery.Post;
  except
    on E: Exception do
    begin
      result:=false;
      uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
    end;
  end;
  uniQuery.Active:=false;
end;

function TTaskThread.InsertRecord(const Cds: TClientDataset; const uniQuery: TUniQuery; var uniErr: AnsiString): Boolean;
var
  i: integer;
  stream: TMemoryStream;
  fld: TField;
begin
  try
    uniQuery.SQL.Text:='SELECT * FROM '+n_tablename+' WHERE 1=2';
    uniQuery.Active:=true;
    result:=true;
    uniQuery.append;
    for i:=0 to Cds.Fields.Count-1 do
    begin
      Fld:=uniQuery.FindField(Cds.Fields[i].FieldName);
      if Fld=nil then
         continue;
      if Cds.Fields[i].IsNull or (Fld.DataType=ftAutoInc) or (Fld.DataType=ftBytes) then
         continue;
      if Fld.IsBlob and (Fld.DataType<>ftMemo) and (Fld.DataType<>ftFmtMemo)
         and (Fld.DataType<>ftWideMemo) then
      begin
        Stream:=nil;
        try
          Stream:=TMemoryStream.create;
          TBlobField(Cds.fields[i]).savetostream(Stream);
          Stream.Position:=0;
          if Stream.Size>0 then
            TBlobField(Fld).loadfromstream(Stream)
          else
            TBlobField(Fld).Clear;
        except
          on E: Exception do
          begin
            result:=false;
            uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          end;
        end;
        if assigned(Stream) then
           FreeAndNil(Stream);
        if not result then
           break;
      end
      else
         Fld.Value:=Cds.Fields[i].Value;
    end;
    if result then
      uniQuery.Post;
    uniQuery.Active:=false;
  except
    on E: Exception do
    begin
      result:=false;
      uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
      uniQuery.Active:=false;
    end;
  end;
end;

function TTaskThread.DeleteRecord(const Cds: TClientDataset; const uniSQL: TUniSQL; var uniErr: AnsiString): Boolean;
var
  sql, tmpstr: String;
  i,j: integer;
begin
  sql:='DELETE FROM '+n_TableName+' WHERE ';
  for i:=0 to KeyFieldCount-1 do
  begin
    if i>0 then
      sql:=sql+' AND ';
    if cds.fieldbyname(keyfields[i]).isnull then
      sql:=sql+'('+KeyFields[i]+' IS NULL)'
    else
    begin
      if (cds.FindField(KeyFields[i]).DataType=ftString) or (cds.FindField(KeyFields[i]).DataType=ftWideString) or (cds.FindField(KeyFields[i]).DataType=ftFixedChar) or (cds.FindField(KeyFields[i]).DataType=ftGUID) then
      begin
         tmpstr:=trim(cds.fieldbyname(KeyFields[i]).AsString);
         j:=pos('''',tmpstr);
         if j>0 then
            tmpstr:='('+KeyFields[i]+'='''+TwoQuotes(trim(cds.fieldbyname(KeyFields[i]).AsString))+''')'
         else
            tmpstr:='('+KeyFields[i]+'='''+trim(cds.fieldbyname(KeyFields[i]).AsString)+''')';
         sql:=sql+tmpstr;
      end
      else
      begin
         if (cds.FindField(KeyFields[i]).DataType=ftDateTime) or (cds.FindField(KeyFields[i]).DataType=ftDate) or (cds.FindField(KeyFields[i]).DataType=ftTime) then
            sql:=sql+'('+KeyFields[i]+'='''+formatdatetime('yyyymmdd hh:nn:ss',cds.fieldbyname(KeyFields[i]).AsDateTime)+''')'
         else
            sql:=sql+'('+KeyFields[i]+'='+trim(cds.fieldbyname(KeyFields[i]).AsString)+')';
      end;
    end;
  end;
  uniSQL.SQL.Text:=sql;
  try
    uniSQL.Execute;
    result:=true;
  except
    on E: Exception do
    begin
      result:=false;
      uniErr:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
    end;
  end;
end;

//procedure TTaskThread.Task_SaveDelta;
//var
//   ok: boolean;
//   DatabaseId,uniErr: AnsiString;
//   TableName,KeyFieldList: string;
//   SysConn: TUniConnection;
//   SysQuery: TUniQuery;
//   SysCommand: TAdoCommand;
//   PoolId,ConnectionId,j: integer;
//   Cds,DataCds: TClientDataset;
//   EnableBCD: boolean;
//   MatchStrictly: boolean;
//begin
//   SysConn:=nil;
//   SysCommand:=nil;
//   DataCds:=nil;
//   Cds:=nil;
//   SysQuery:=nil;
//   DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
//   TableName:=RequestPacket.GetStringGoods('TableName');
//   n_TableName:=TableName;
//   KeyFieldList:=RequestPacket.GetStringGoods('KeyFieldList');
//   EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
//   MatchStrictly:=RequestPacket.GetBooleanGoods('MatchStrictly');
//   if RequestPacket.GoodsExists('IsolationLevel') then
//      j:=RequestPacket.GetIntegerGoods('IsolationLevel')
//   else
//      j:=-1;
//   DataCds:=nil;
//   if RequestPacket.GoodsExists('DeltaData') then
//      begin
//         Cds:=TClientDataset.Create(nil);
//         Cds.DisableControls;
//         ok:=GetCdsFromPacket(RequestPacket,'DeltaData',Cds);
//         if not ok then
//            FreeAndNil(Cds)
//         else
//            begin
//               if RequestPacket.GoodsExists('ModifiedData') then
//                  begin
//                     DataCds:=TClientDataset.Create(nil);
//                     DataCds.DisableControls;
//                     ok:=GetCdsFromPacket(RequestPacket,'ModifiedData',DataCds);
//                     if not ok then
//                        begin
//                           FreeAndNil(Cds);
//                           FreeAndNil(DataCds);
//                           DataCds:=nil;
//                        end;
//                  end;
//            end;
//      end
//   else
//      ok:=false;
//   if ok then
//      begin
//         ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
//         if ok and (j<>-1) then
//            ok:=SetIsoLevel(SysConn,j);
//         if ok then
//            begin
//               try
//                  ok:=ResolveKeyFields(Cds,KeyFieldList);
//               except
//                  ok:=false;
//               end;
//               if not ok then
//                  begin
//                     FreeAndNil(Cds);
//                     if DataCds<>nil then
//                        FreeAndNil(DataCds);
//                     NodeService.FreeConnection(PoolId,ConnectionId);
//                     ErrorCode:='0206805';
//                     ErrorText:='Invalid keyfield list.';
//                     SaveErrorResponse(ErrorCode,ErrorText);
//                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldList));
//                     exit;
//                  end;
//               try
//                 SysQuery:=TUniQuery.Create(nil);
//                 SysQuery.DisableControls;
//                 SysQuery.CommandTimeout:=300;
//                 SysCommand:=TAdoCommand.Create(nil);
//                 SysCommand.CommandTimeout:=300;
//                 SysConn.BeginTrans;
//                 SysQuery.EnableBCD:=EnableBCD;
//                 SysQuery.Connection:=SysConn;
//                 SysCommand.Connection:=SysConn;
//                 ok:=true;
//                 Cds.First;
//                 while not Cds.Eof do
//                    begin
//                       case Cds.UpdateStatus of
//                          usUnModified:
//                             begin
//                                try
//                                   ok:=LocateRecord(Cds,SysQuery,DataCds<>nil,DataCds,uniErr);
//                                except
//                                   ok:=false;
//                                end;
//                                if not ok then
//                                   begin
//                                      ErrorCode:='0206803';
//                                      ErrorText:='Locate origin record failed: '+uniErr;
//                                   end;
//                             end;
//                          usModified:
//                             begin
//                                if DataCds<>nil then
//                                   begin
//                                      try
//                                         ok:=UpdateRecord(DataCds,SysQuery,true,MatchStrictly,uniErr);
//                                      except
//                                         ok:=false;
//                                      end;
//                                      DataCds.Next;
//                                   end
//                                else
//                                   try
//                                      ok:=UpdateRecord(Cds,SysQuery,false,MatchStrictly,uniErr);
//                                   except
//                                      ok:=false;
//                                   end;
//                                if not ok then
//                                   begin
//                                      ErrorCode:='0206803';
//                                      ErrorText:='Update record failed: '+uniErr;
//                                   end;
//                             end;
//                          usInserted:
//                             begin
//                                try
//                                   ok:=InsertRecord(Cds,SysQuery,uniErr);
//                                except
//                                   ok:=false;
//                                end;
//                                if not ok then
//                                   begin
//                                      ErrorCode:='0206803';
//                                      ErrorText:='Insert record failed: '+uniErr;
//                                   end;
//                             end;
//                          usDeleted:
//                             begin
//                                try
//                                   ok:=DeleteRecord(Cds,SysCommand,uniErr);
//                                except
//                                   ok:=false;
//                                end;
//                                if not ok then
//                                   begin
//                                      ErrorCode:='0206803';
//                                      ErrorText:='Delete record failed: '+uniErr;
//                                   end;
//                             end;
//                       end;
//                       if not ok then
//                          break;
//                       Cds.Next;
//                    end;
//                 if ok then
//                    SysConn.CommitTrans
//                 else
//                    begin
//                       SysConn.RollbackTrans;
//                       ErrorCode:='0206804';
//                       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//                       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldList));
//                    end;
//               except
//                  on E: Exception do
//                     begin
//                        ok:=false;
//                        ErrorCode:='0206803';
//                        ErrorText:='Exception on commit delta: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldList));
//                        try
//                           if SysConn.InTransaction then
//                              SysConn.RollbackTrans;
//                        except
//                        end;
//                     end;
//               end;
//               SafeFreeUniData(SysQuery);
//               if Assigned(SysCommand) then
//                  FreeAndNil(SysCommand);
//               NodeService.FreeConnection(PoolId,ConnectionId);
//            end
//         else
//            begin
//               ErrorCode:='0206802';
//               ErrorText:='分配数据库连接失败...';
//            end;
//         FreeAndNil(Cds);
//         if DataCds<>nil then
//            FreeAndNil(DataCds);
//      end
//   else
//      begin
//         ErrorCode:='0206801';
//         ErrorText:='无效参数...';
//      end;
//   try
//      BackPacket.EncryptKey:=NodeService.s_TransferKey;
//      BackPacket.PutBooleanGoods('ProcessResult',ok);
//      if not ok then
//         begin
//            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//         end;
//   except
//      on e: exception do
//         NodeService.syslog.Log('Err02068: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//   end;
//end;

procedure TTaskThread.Task_SaveDelta;
var
  ok: boolean;
  DatabaseId: AnsiString;
  TableName,KeyFieldList: string;   //添加不更新字段  NoUpdateFields
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  SysCommand: TUniSQL;
  PoolId,ConnectionId,j: integer;
  Cds,DataCds: TClientDataset;
  EnableBCD: boolean;
  MatchStrictly: boolean;
  loDM:TAppDM;
  upData: oleVariant;
  psCommandtext:String;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  n_TableName:=TableName;
  KeyFieldList:=RequestPacket.GetStringGoods('KeyFieldList');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  MatchStrictly:=RequestPacket.GetBooleanGoods('MatchStrictly');        //严格匹配
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  DataCds:=nil;
  if RequestPacket.GoodsExists('DeltaData') then
  begin
    Cds:=TClientDataset.Create(nil);
    Cds.DisableControls;
    ok:=GetCdsFromPacket(RequestPacket,'DeltaData',Cds);
    if not ok then
        FreeAndNil(Cds)
    else
    begin
      if RequestPacket.GoodsExists('ModifiedData') then
      begin
        DataCds:=TClientDataset.Create(nil);
        DataCds.DisableControls;
        ok:=GetCdsFromPacket(RequestPacket,'ModifiedData',DataCds);
        if not ok then
        begin
          FreeAndNil(Cds);
          FreeAndNil(DataCds);
          DataCds:=nil;
        end;
      end;
    end;
  end
  else
    ok:=false;

  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
       ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysConn.StartTransaction;
        // Modified by Administrator 2014-03-10 16:50:36
        loDM := TAppDM.Create(nil);
        Try
          Try
            upData := Cds.Data;
            cds.First;
            psCommandtext := 'SELECT * FROM '+TableName+' where 1<>1';
            loDM.DSPUpdateTable.UpdateTableName := TableName;
            ok := loDM.UpdateTable(upData, psCommandtext, KeyFieldList, SysConn, ErrorText);
          Finally
            FreeAndNIl(loDM);
          End;
        Except
          ok := False;
        End;
        if ok then
          SysConn.Commit
        else
        begin
          SysConn.Rollback;
          ErrorCode:='0206804';
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206803';
          ErrorText:='Exception on commit delta: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          try
             if SysConn.InTransaction then
                SysConn.Rollback;
          except
          end;
        end;
      end;

      SafeFreeUniData(SysDataset);
      if Assigned(SysCommand) then
          FreeAndNil(SysCommand);
       NodeService.FreeConnection(PoolId,ConnectionId)
    end
    else
    begin
      ErrorCode:='0206802';
      ErrorText:='分配数据库['+DatabaseId+']连接失败...';
    end;
    FreeAndNil(Cds);
    if DataCds<>nil then
      FreeAndNil(DataCds);
  end
  else
  begin
     ErrorCode:='0206801';
     ErrorText:='参数无效...';
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02068: 创建反馈信息结构失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_SaveDelta(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  TableName,KeyFieldList: string;
  SysDataset: TuniQuery;
  SysCommand: TUniSQL;
  Cds,DataCds: TClientDataset;
  EnableBCD: boolean;
  MatchStrictly: boolean;
  AdoErr: AnsiString;
begin
  TableName:=TaskPacket.GetStringGoods('TableName');
  n_TableName:=TableName;
  KeyFieldList:=TaskPacket.GetStringGoods('KeyFieldList');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  MatchStrictly:=TaskPacket.GetBooleanGoods('MatchStrictly');
  DataCds:=nil;
  if TaskPacket.GoodsExists('DeltaData') then
  begin
    Cds:=TClientDataset.Create(nil);
    Cds.DisableControls;
    Result:=GetCdsFromPacket(TaskPacket,'DeltaData',Cds);
    if not Result then
      FreeAndNil(Cds)
    else
    begin
      if TaskPacket.GoodsExists('ModifiedData') then
      begin
        DataCds:=TClientDataset.Create(nil);
        DataCds.DisableControls;
        Result:=GetCdsFromPacket(TaskPacket,'ModifiedData',DataCds);
        if not Result then
        begin
           FreeAndNil(Cds);
           FreeAndNil(DataCds);
        end;
      end;
    end;
  end
  else
  Result:=false;
  if Result then
  begin
    try
      Result:=ResolveKeyFields(Cds,KeyFieldList);
    except
      Result:=false;
    end;
    if not Result then
    begin
      FreeAndNil(Cds);
      if DataCds<>nil then
        FreeAndNil(DataCds);
      ErrorCode:='0206805';
      ErrorText:='无效的关键字段列表。';
      SaveErrorResponse(ErrorCode,ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldList));
      exit;
    end;
    try
      SysDataset:=TuniQuery.Create(nil);
      SysDataset.DisableControls;
      SysCommand:=TuniSQL.Create(nil);
      SysDataset.Options.EnableBCD:=EnableBCD;
      SysDataset.Connection:=SysConn;
   　 SysCommand.Connection:=SysConn;
    　Result:=true;
    　Cds.First;
      while not Cds.Eof do
      begin
        case Cds.UpdateStatus of
          usUnModified:
          begin
            try
               Result:=LocateRecord(Cds,SysDataset,DataCds<>nil,DataCds,AdoErr);
            except
               Result:=false;
            end;
            if not result then
            begin
              ErrorCode:='0206803';
              ErrorText:='Locate origin record failed: '+AdoErr;
            end;
          end;
          usModified:
          begin
            if DataCds<>nil then
            begin
              try
                 Result:=UpdateRecord(DataCds,SysDataset,true,MatchStrictly,AdoErr);
              except
                 Result:=false;
              end;
              DataCds.Next;
            end
            else
              try
                Result:=UpdateRecord(Cds,SysDataset,false,MatchStrictly,AdoErr);
              except
                Result:=false;
              end;
            if not Result then
            begin
              ErrorCode:='0206803';
              ErrorText:='Update record failed: '+AdoErr;
            end;
          end;
          usInserted:
          begin
            try
               Result:=InsertRecord(Cds,SysDataset,AdoErr);
            except
               Result:=false;
            end;
            if not Result then
            begin
              ErrorCode:='0206803';
              ErrorText:='Insert record failed: '+AdoErr;
            end;
          end;
          usDeleted:
          begin
            try
               Result:=DeleteRecord(Cds,SysCommand,AdoErr);
            except
               Result:=false;
            end;
            if not result then
            begin
              ErrorCode:='0206803';
              ErrorText:='Delete record failed: '+AdoErr;
            end;
          end;
        end;
        if not Result then
          break;
        Cds.Next;
      end;
    except
      on E: Exception do
      begin
        Result:=false;
        ErrorCode:='0206803';
        ErrorText:='Exception on commit delta: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
      end;
    end;
    SafeFreeUniData(SysDataset);
    if Assigned(SysCommand) then
      FreeAndNil(SysCommand);
    FreeAndNil(Cds);
    if DataCds<>nil then
      FreeAndNil(DataCds);
  end
  else
  begin
    ErrorCode:='0206801';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

//procedure TTaskThread.Task_CreatePageQuery;
//var
//   ok: boolean;
//   DatabaseId: AnsiString;
//   SqlCommand: string;
//   QueryId,SessionId: integer;
//   ParamPacket: TwxdPacket;
//   EnableBCD: boolean;
//begin
//   DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
//   SqlCommand:=RequestPacket.GetStringGoods('SQLCommand');
//   EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
//   if RequestPacket.GoodsExists('Parameters') then
//      begin
//         ParamPacket:=TwxdPacket.Create;
//         ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
//         if not ok then
//            FreeAndNil(ParamPacket);
//      end
//   else
//      begin
//         ParamPacket:=nil;
//         ok:=true;
//      end;
//   ok:=ok and (trim(DatabaseId)<>'') and (trim(SQLCommand)<>'');
//   SessionId:=0;
//   if ok then
//      begin
//         ok:=NodeService.CreateQuerySession(DatabaseId,NodeService.s_QueryFreeTime,QueryId);
//         if ok then
//            begin
//               SessionId:=NodeService.Querys[QueryId].SessionId;
//               NodeService.Querys[QueryId].LastActiveTime:=now;
//               try
//                  NodeService.Querys[QueryId].AdoDataset:=TUniQuery.Create(nil);
//                  NodeService.Querys[QueryId].AdoDataset.DisableControls;
//                  NodeService.Querys[QueryId].AdoDataset.CommandTimeout:=300;
//                  NodeService.Querys[QueryId].AdoDataset.EnableBCD:=EnableBCD;
//                  NodeService.Querys[QueryId].AdoDataset.CacheSize:=100;
//                  NodeService.Querys[QueryId].AdoDataset.Connection:=NodeService.Querys[QueryId].AdoConn;
//                  NodeService.Querys[QueryId].AdoDataset.CommandText:=SqlCommand;
//                  if Assigned(ParamPacket) then
//                     PacketToParameters(ParamPacket,NodeService.Querys[QueryId].AdoDataset);
//                  NodeService.Querys[QueryId].AdoDataset.Active:=true;
//               except
//                  on E: Exception do
//                     begin
//                        ok:=false;
//                        ErrorCode:='0207003';
//                        ErrorText:='Open table failed: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//                        NodeService.FreeQuerySession(QueryId,NodeService.Querys[QueryId].SessionId);
//                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
//                     end;
//               end;
//            end
//         else
//            begin
//               ErrorCode:='0207002';
//               ErrorText:='Create query session failed. ';
//               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
//            end;
//      end
//   else
//      begin
//         ErrorCode:='0207001';
//         ErrorText:='无效参数...';
//         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
//      end;
//   try
//      BackPacket.EncryptKey:=NodeService.s_TransferKey;
//      if ok then
//         begin
//            BackPacket.PutIntegerGoods('QueryId',QueryId);
//            BackPacket.PutIntegerGoods('QuerySessionId',SessionId);
//            try
//               BackPacket.PutIntegerGoods('AllRecords',NodeService.Querys[QueryId].AdoDataset.RecordCount);
//            except
//               ok:=false;
//            end;
//         end
//      else
//         begin
//            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//         end;
//      BackPacket.PutBooleanGoods('ProcessResult',ok);
//   except
//      on e: exception do
//         NodeService.syslog.Log('Err02070: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//   end;
//   if Assigned(ParamPacket) then
//      FreeAndNil(ParamPacket);
//end;

//procedure TTaskThread.Task_QueryPageData;
//var
//   ok: boolean;
//   QueryId,QuerySessionId,PageSize,PageNumber: integer;
//   Stream,tmpStream: TMemoryStream;
//begin
//   Stream:=nil;
//   tmpStream:=nil;
//   QueryId:=RequestPacket.GetIntegerGoods('QueryId');
//   QuerySessionId:=RequestPacket.GetIntegerGoods('QuerySessionId');
//   PageSize:=RequestPacket.GetIntegerGoods('PageSize');
//   PageNumber:=RequestPacket.GetIntegerGoods('PageNumber');
//   ok:=(PageSize>0) and (PageNumber>=0) and NodeService.QuerySessionOk(queryid,querysessionid);
//   if ok then
//      begin
//         try
//            tmpStream:=TMemoryStream.Create;
//            ok:=GetPageData(NodeService.querys[QueryId].AdoDataset,PageSize,PageNumber,tmpStream,ErrorText);
//         except
//            on e:exception do
//               begin
//                  ErrorText:='['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//                  ok:=false;
//               end;
//         end;
//         if ok then
//            begin
//              try
//                 Stream:=TMemoryStream.Create;
//                 tmpStream.Position:=0;
//                 CompressStream(tmpStream,Stream);
//              except
//                 on E: Exception do
//                    begin
//                       ok:=false;
//                       if assigned(Stream) then
//                          FreeAndNil(Stream);
//                       ErrorCode:='0207103';
//                       ErrorText:='Zip page data failed: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//                       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//                       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//                    end;
//              end;
//              if assigned(tmpStream) then
//                 FreeAndNil(tmpStream);
//            end
//         else
//            begin
//               if assigned(tmpStream) then
//                  FreeAndNil(tmpStream);
//               ErrorCode:='0207102';
//               ErrorText:='Read page data failed: '+ErrorText;
//               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//            end;
//      end
//   else
//      begin
//         ErrorCode:='0207101';
//         ErrorText:='无效参数...';
//         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//      end;
//   try
//      BackPacket.EncryptKey:=NodeService.s_TransferKey;
//      if ok then
//         begin
//            ok:=BackPacket.PutStreamGoods('PageData',Stream);
//            FreeAndNil(Stream);
//            if not ok then
//               begin
//                  ErrorCode:='0207101';
//                  ErrorText:='Return page data failed.';
//                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//               end;
//         end;
//      if not ok then
//         begin
//            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//         end;
//      BackPacket.PutBooleanGoods('ProcessResult',ok);
//   except
//      on e: exception do
//         NodeService.syslog.Log('Err02063: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//   end;
//end;

//procedure TTaskThread.Task_TerminatePageQuery;
//var
//   ok: boolean;
//   QueryId,QuerySessionId: integer;
//begin
//   QueryId:=RequestPacket.GetIntegerGoods('QueryId');
//   QuerySessionId:=RequestPacket.GetIntegerGoods('QuerySessionId');
//   ok:=NodeService.FreeQuerySession(queryid,QuerySessionId);
//   if not ok then
//      begin
//         ErrorCode:='0207302';
//         ErrorText:='Free query session failed.';
//         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//      end;
//   try
//      BackPacket.EncryptKey:=NodeService.s_TransferKey;
//      BackPacket.PutBooleanGoods('ProcessResult',ok);
//      if not ok then
//         begin
//            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//         end;
//   except
//      on e: exception do
//         NodeService.syslog.Log('Err02073: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//   end;
//end;

procedure TTaskThread.Task_SystemReport;
var
   StatusPacket: TwxdPacket;
begin
   StatusPacket:=TwxdPacket.Create;
   NodeService.GetSystemStatus(StatusPacket);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutPacketGoods('SystemStatus',StatusPacket);
   except
      on e: exception do
         NodeService.syslog.Log('Error: Generate status Packet failed: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   FreeAndNil(StatusPacket);
end;


// Modified by ZhiFeng 2015-10-05 17:30:09
// 添加存储过程分页查询函数，调用 PaginationQuery 存储过程
procedure TTaskThread.Task_GetQueryPageData;
var
  ok: boolean;
  DatabaseId, SQLStr, FetchSQL: AnsiString;
  TmpSqlComm, TopSqlComm, TableName, TopFieldName:String;
  SqlCommand, OlsSQL: string;
  PoolId,ConnectionId,j, StrI, TableSize: integer;
  CurPage,PageSize, totalRecords, TotalPages:Integer;
  SysConn: TUniConnection;
  spProc: TUniStoredProc;
  dsp:TDataSetProvider;
  cds:TClientDataSet;
  SysQuery:TUniQuery;
  Stream: TMemoryStream;
  ParamPacket: TWXDPacket;
  EnableBCD, CompSQLComm: boolean;
  IsUnicode:Boolean;
  Err:String;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SqlCommand');
  OlsSQL := SqlCommand;
  CurPage := Integer(RequestPacket.GetIntegerGoods('CurPage'));
  PageSize := RequestPacket.GetIntegerGoods('PageSize');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');

  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;

  if (pos(':',SqlCommand)>0) and RequestPacket.GoodsExists('Parameters') then
  begin
     ParamPacket:=TWXDPacket.Create;
     ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
     if not ok then
        FreeAndNil(ParamPacket);
  end
  else
  begin
     ParamPacket:=nil;
     ok:=true;
  end;
  ok:=ok and (DatabaseId<>'') and (SqlCommand<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        Stream:=TMemoryStream.Create;
        SysQuery := TUniQuery.Create(nil);
//        SysQuery.UniDirectional := True;
        SysQuery.Connection := SysConn;
        SysQuery.AfterOpen := uniDataAfterOpen;
        sysQuery.Options.EnableBCD := EnableBCD;

        SqlCommand := AnsiLowerCase(AnsiReplaceStr(SqlCommand,'  ',' '));
        CompSQLComm := (Pos(' from ',SqlCommand)>0);      //判断是否为完整SQL语句
        //==================================
        if (PageSize>=20001) And CompSQLComm then
        Begin
          Try
            if (AnsiPos(' top ',SqlCommand)>0) then
            Begin
              StrI := AnsiPos(' top ', SqlCommand) + 1;
              TopSqlComm := Copy(SqlCommand, StrI, StrLen(PWideChar(SqlCommand)));
              StrI := AnsiPos(' ', TopSqlComm) + 1;
              TopSqlComm := Copy(TopSqlComm, StrI, StrLen(PWideChar(SqlCommand)));
              StrI := AnsiPos(' ', TopSqlComm) + 1;
              TopSqlComm := Copy(TopSqlComm, StrI, StrLen(PWideChar(SqlCommand)));
            End
            Else
              TopSqlComm := Copy(SqlCommand, 8, StrLen(PWideChar(SqlCommand)));
            TmpSqlComm := 'select top 0 '+ TopSqlComm;
            if SysQuery.Active then SysQuery.Close;
            SysQuery.SQL.Text := TmpSqlComm;
            dsp := TDataSetProvider.Create(nil);
            cds := TClientDataSet.Create(nil);
            Dsp.DataSet := SysQuery;
            cds.Data := dsp.Data;
            TableSize := cds.DataSize;
            TmpSqlComm := 'select Top 1 '+ TopSqlComm;
            if SysQuery.Active then SysQuery.Close;
            SysQuery.SQL.Text := TmpSqlComm;
            dsp := TDataSetProvider.Create(nil);
            cds := TClientDataSet.Create(nil);
            Dsp.DataSet := SysQuery;
            cds.Data := dsp.Data;
            ok := (TableSize + (cds.DataSize - TableSize) * PageSize < 64 * 1024 * 1024);
            if Not ok  then
            begin
              ok := (TableSize + (cds.DataSize - TableSize) * 2000 < 64 * 1024 * 1024);
              if OK then
                 PageSize := 2000
              Else
              Begin
                ErrorCode:='0206104B';
                ErrorText:='数据库：['+SysConn.Database+'] '+' 单页查询的数据大小'
                    + FormatFloat('0.00',(TableSize + (cds.DataSize - TableSize) * PageSize) / 1024 / 1024)+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
                NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
              End;
            End;
          finally
            FreeAndNil(cds);
            FreeAndNil(dsp);
          End;
        end;
        //==============
        if (CurPage<=1) then
        Begin
          FetchSQL := ' OFFSET 0 ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
        End
        Else
        Begin
          FetchSQL := ' OFFSET '+Inttostr((CurPage -1 ) * PageSize + 1)+' ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
        End;

//        NodeService.syslog.Log(SqlCommand);
        if CompSQLComm then
        Begin
          if (Pos('order by', SqlCommand)>0) And (AnsiPos(' top ', SqlCommand)<1) then       //判断是否有排序语法 及 Top 语法
          Begin
            sqlStr := SqlCommand + FetchSQL;
          End
          Else
          Begin
            strI := AnsiPos(' from ', SqlCommand) + 1;
            TmpSqlComm := Trim(Copy(SqlCommand, strI + 4, StrLen(PWideChar(SqlCommand))));
            strI := Pos(' ',TmpSqlComm);
            if (strI=0) then
              TableName := Copy(TmpSqlComm,1,StrLen(PWideChar(SqlCommand)))
            Else
              TableName := Copy(TmpSqlComm,1,strI);

            if (AnsiPos(' top ',SqlCommand)>0) then
              SQLStr := SqlCommand
            Else
            Begin
              TmpSqlComm := Copy(SqlCommand, 8, StrLen(PWideChar(SqlCommand)));
              SqlStr := 'select Top 0 '+ TmpSqlComm;
            End;
            if sysQuery.Active then sysQuery.Close;
            sysQuery.SQL.Text := sqlStr;
            sysQuery.Open;
            TopFieldName := SysQuery.Fields.Fields[0].FieldName;
            if (AnsiPos(' top ',SqlCommand)=0) then
              sqlStr := SqlCommand +' Order By '+TopFieldName + FetchSQL;
          End;
        end;
        if ok then
        begin
          if CompSQLComm then       //完整SQL语句，就进行总记录数及页数的统计
          Begin
            if (AnsiPos('group by',SqlCommand)>0) then             //判断是否为分组查询语句
            Begin
              StrI := AnsiPos('order by', SqlCommand);
              if (StrI>0) then
                SqlCommand := 'select Count(*) as RecordCount From ('+Copy(SqlCommand,0,StrI -1)+') as a'
              Else
                SqlCommand := 'select Count(*) as RecordCount From ('+SqlCommand+') as a';
            end
            else
            Begin                                                 //非分组查询语句
              strI := AnsiPos(' from', SqlCommand) + 1;
              TmpSqlComm := Trim(Copy(SqlCommand, strI, StrLen(PWideChar(SqlCommand))));
              if (AnsiPos('order by', SqlCommand)>0) then
              begin
                strI := AnsiPos('order by', TmpSqlComm);
                TmpSqlComm := Copy(TmpSqlComm,0,StrI - 1);
              End;
              SqlCommand := 'select count(*) AS RecordCount '+ TmpSqlComm;
            End;
            if sysQuery.Active then sysQuery.Close;
            sysQuery.SQL.Text := SqlCommand;
            SysQuery.Open;
            if (SysQuery.FieldByName('RecordCount').AsInteger>0) then
            Begin
              totalRecords := SysQuery.FieldByName('RecordCount').AsInteger;
              totalPages := ceil(totalRecords / PageSize);
            End;
            if sysQuery.Active then sysQuery.Close;
            sysQuery.SQL.Text := SqlStr;
          End
          Else
            SysQuery.SQL.Text := SqlCommand;
//          NodeService.syslog.Log(SqlStr);
          ok:=DataSetZipToCdsStream(SysQuery,Stream,IsUnicode, Err);
          if not ok then
          begin
            ErrorCode:='0206104C';
            ErrorText:='数据库：['+SysConn.Database+'] '+ Err;
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
          end;
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206101B';
          ErrorText:='数据库：['+SysConn.Database+'] 分页查询出错: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('分页查询SQL语句(原始):'+OlsSQL);
          NodeService.syslog.Log('分页查询SQL语句(实际):'+sysQuery.SQL.Text);
        end;
      end;
      if (not ok) and assigned(Stream) then
        FreeAndNil(Stream);
      SafeFreeUniData(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    End;
  end
  else
  begin
    ErrorCode:='0206101B';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      BackPacket.PutIntegerGoods('totalRecords',totalRecords);
      BackPacket.PutIntegerGoods('totalPages',totalPages);
      ok:=BackPacket.PutStreamGoods('OleVariant',Stream);
      FreeAndNil(Stream);
      if not ok then
      begin
        ErrorCode:='0206101B';
        ErrorText:='封装返回数据集出错...';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      end;
    end;
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
       NodeService.syslog.Log('Err02061: Task_GetQueryPageData，创建反馈信息结构失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

// 添加存储过程分而查询函数，调用 PageQuery 存储过程
//procedure TTaskThread.Task_GetPageQuery;
//var
//  ok: boolean;
//  DatabaseId: AnsiString;
////  SqlCommand: string;
//  PoolId,ConnectionId,j, TableSize: integer;
//  TableName, FieldsList, PrimaryKey, Where, Order, TmpSqlComm:string;
//  SortType, RecorderCount, PageSize, PageIndex, TotalCount, TotalPageCount:Integer;
//  SysConn: TUniConnection;
//  spProc: TUniStoredProc;
//  SysQuery:TUniQuery;
//  dsp:TDataSetProvider;
//  cds:TClientDataSet;
//  Stream: TMemoryStream;
//  ParamPacket: TWXDPacket;
//  EnableBCD: boolean;
//  IsUnicode:Boolean;
//  Err:String;
//begin
//  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
//  TableName := RequestPacket.GetStringGoods('TableName');
//  FieldsList := RequestPacket.GetStringGoods('FieldsList');
//  PrimaryKey := RequestPacket.GetStringGoods('PrimaryKey');
//  Where := RequestPacket.GetStringGoods('Where');
//  Order := RequestPacket.GetStringGoods('Order');
//  SortType := RequestPacket.GetIntegerGoods('SortType');
//  RecorderCount := RequestPacket.GetIntegerGoods('RecorderCount');
//  PageSize := RequestPacket.GetIntegerGoods('PageSize');
//  PageIndex := RequestPacket.GetIntegerGoods('PageIndex');
//  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
//  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
//
//  if RequestPacket.GoodsExists('IsolationLevel') then
//    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
//  else
//    j:=-1;
//  if (pos(':',TableName)>0) and RequestPacket.GoodsExists('Parameters') then
//    begin
//       ParamPacket:=TWXDPacket.Create;
//       ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
//       if not ok then
//          FreeAndNil(ParamPacket);
//    end
//  else
//    begin
//       ParamPacket:=nil;
//       ok:=true;
//    end;
//  ok:=ok and (DatabaseId<>'') and (TableName<>'');
//
//  if ok then
//  begin
//    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
//    if ok and (j<>-1) then
//      ok:=SetIsoLevel(SysConn,j);
//    if ok then
//    begin
//      try
//        if (PageSize>=20001) then
//        Begin
//          Try
//            TmpSqlComm :='SELECT TOP 0 * FROM '+TableName+' Where '+Where;
//            SysQuery := TUniQuery.Create(nil);
//            SysQuery.Connection := SysConn;
//            if SysQuery.Active then SysQuery.Close;
//            SysQuery.SQL.Text := TmpSqlComm;
//            dsp := TDataSetProvider.Create(nil);
//            cds := TClientDataSet.Create(nil);
//            Dsp.DataSet := SysQuery;
//            cds.Data := dsp.Data;
//            TableSize := cds.DataSize;
//            TmpSqlComm :='SELECT TOP 1 * FROM '+TableName+' Where '+Where;
//            if SysQuery.Active then SysQuery.Close;
//            SysQuery.SQL.Text := TmpSqlComm;
//            dsp := TDataSetProvider.Create(nil);
//            cds := TClientDataSet.Create(nil);
//            Dsp.DataSet := SysQuery;
//            cds.Data := dsp.Data;
//            ok := (TableSize + (cds.DataSize - TableSize) * PageSize < 64 * 1024 * 1024);
//            if Not ok  then
//            begin
//              ok := (TableSize + (cds.DataSize - TableSize) * 2000 < 64 * 1024 * 1024);
//              if OK then
//                PageSize := 2000
//              Else
//              Begin
//                ErrorCode:='0206104D';
//                ErrorText:='数据库：['+SysConn.Database+'] '+' 单页查询的数据大小'
//                    + FormatFloat('0.00',(TableSize + (cds.DataSize - TableSize) * PageSize) / 1024 / 1024)+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
//                NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
//              End;
//            End;
//          finally
//            FreeAndNil(cds);
//            FreeAndNil(dsp);
//            FreeAndNil(SysQuery);
//          End;
//        end;
//
//        if ok then
//        begin
//          spProc:=TUniStoredProc.Create(nil);
//          spProc.AfterOpen := uniDataAfterOpen;
//          spProc.DisableControls;
//          spProc.UniDirectional := True;
//          Stream:=TMemoryStream.Create;
//          spProc.Options.EnableBCD:=EnableBCD;
//          spProc.Connection:=SysConn;
//          spProc.SpecificOptions.Values['FetchAll'] := 'False';
//          spProc.Params.Clear;
//          spProc.ParamCheck := False;
//          spProc.StoredProcName :='PageQuery';
//          spProc.Params.CreateParam(ftInteger,'RETURN_VALUE', ptResult);
//          spProc.Params.ParamByName('RETURN_VALUE').AsInteger := 0;
//          spProc.Params.CreateParam(ftString,'TableName',ptInput);
//          spProc.Params.ParamByName('TableName').AsString := TableName;
//          spProc.Params.CreateParam(ftString,'FieldsList',ptInput);
//          spProc.Params.ParamByName('FieldsList').AsString := FieldsList;
//          spProc.Params.CreateParam(ftString,'PrimaryKey',ptInput);
//          spProc.Params.ParamByName('PrimaryKey').AsString := PrimaryKey;
//          spProc.Params.CreateParam(ftString,'Where',ptInput);
//          spProc.Params.ParamByName('Where').AsString := Where;
//          spProc.Params.CreateParam(ftString,'Order',ptInput);
//          spProc.Params.ParamByName('Order').AsString := Order;
//          spProc.Params.CreateParam(ftInteger,'SortType',ptInput);
//          spProc.Params.ParamByName('SortType').AsInteger := SortType;
//          spProc.Params.CreateParam(ftInteger,'RecorderCount',ptInput);
//          spProc.Params.ParamByName('RecorderCount').AsInteger := RecorderCount;
//          spProc.Params.CreateParam(ftInteger,'PageSize',ptInput);
//          spProc.Params.ParamByName('PageSize').AsInteger := PageSize;
//          spProc.Params.CreateParam(ftInteger,'PageIndex',ptInput);
//          spProc.Params.ParamByName('PageIndex').AsInteger := PageIndex;
//          spProc.Params.CreateParam(ftInteger,'TotalCount',ptInputOutput);
//          spProc.Params.ParamByName('TotalCount').AsInteger := TotalCount;
//          spProc.Params.CreateParam(ftInteger,'TotalPageCount',ptInputOutput);
//          spProc.Params.ParamByName('TotalPageCount').AsInteger := TotalPageCount;
//          if ParamPacket<>nil then
//             PacketToParameters(ParamPacket,spProc);
//
//          ok:=DataSetZipToCdsStream(spProc,Stream,IsUnicode, Err);
//          if not ok then
//          begin
//            ErrorCode:='0206104E';
//            ErrorText:='将存储过程数据集转换为内存流失败，可能是因为数据太大造成...';
//            NodeService.syslog.Log('数据库：['+SysConn.Database+']  Err'+ErrorCode+': '+ErrorText+'   '+ Err);
//          end;
//          TotalCount := spProc.ParamByName('TotalCount').AsInteger;
//          TotalPageCount := spProc.ParamByName('TotalPageCount').AsInteger;
//        end;
//      except
//        on E: Exception do
//        begin
//          ok:=false;
//          ErrorCode:='0206103C';
//          ErrorText:='打开存储过程数据集失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//          NodeService.syslog.Log('数据库：['+SysConn.Database+'] Err'+ErrorCode+': '+ErrorText);
//        end;
//      end;
//       if (not ok) and assigned(Stream) then
//          FreeAndNil(Stream);
//       SafeFreeUniData(spProc);
//       NodeService.FreeConnection(PoolId,ConnectionId)
//    end;
//  end
//  else
//  begin
//    ErrorCode:='0206101';
//    ErrorText:='无效参数...';
//    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//  end;
//
//  try
//    BackPacket.EncryptKey:=NodeService.s_TransferKey;
//    if ok then
//    begin
//      BackPacket.PutIntegerGoods('TotalCount',TotalCount);
//      BackPacket.PutIntegerGoods('TotalPageCount',TotalPageCount);
//      ok:=BackPacket.PutStreamGoods('OleVariant',Stream);
//      FreeAndNil(Stream);
//      if not ok then
//      begin
//        ErrorCode:='0206101';
//        ErrorText:='封装返回数据集出错...';
//        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//      end;
//    end;
//
//    if not ok then
//    begin
//      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//    end;
//    BackPacket.PutBooleanGoods('ProcessResult',ok);
//  except
//    on e: exception do
//       NodeService.syslog.Log('Err02061: Task_GetPageQuery，创建反馈信息结构失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//  end;
//  if ParamPacket<>nil then
//    FreeAndNil(ParamPacket);
//end;

procedure TTaskThread.Task_GetPageQuery;
var
  ok: boolean;
  DatabaseId: AnsiString;
  PoolId,ConnectionId,j, TableSize: integer;
  TableName, FieldsList, PrimaryKey, Where, Order, TmpSqlComm:string;
  SortType, RecorderCount, PageSize, PageIndex, TotalCount, TotalPageCount:Integer;
  SysConn: TUniConnection;
  SysQuery:TUniQuery;
  dsp:TDataSetProvider;
  cds:TClientDataSet;
  Stream: TMemoryStream;
  ParamPacket: TWXDPacket;
  EnableBCD: boolean;
  IsUnicode:Boolean;
  Err:String;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName := RequestPacket.GetStringGoods('TableName');
  FieldsList := RequestPacket.GetStringGoods('FieldsList');
  PrimaryKey := RequestPacket.GetStringGoods('PrimaryKey');
  Where := RequestPacket.GetStringGoods('Where');
  Order := RequestPacket.GetStringGoods('Order');
  SortType := RequestPacket.GetIntegerGoods('SortType');
  RecorderCount := RequestPacket.GetIntegerGoods('RecorderCount');
  PageSize := RequestPacket.GetIntegerGoods('PageSize');
  PageIndex := RequestPacket.GetIntegerGoods('PageIndex');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');

  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if (pos(':',TableName)>0) and RequestPacket.GoodsExists('Parameters') then
    begin
       ParamPacket:=TWXDPacket.Create;
       ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
       if not ok then
          FreeAndNil(ParamPacket);
    end
  else
    begin
       ParamPacket:=nil;
       ok:=true;
    end;
  ok:=ok and (DatabaseId<>'') and (TableName<>'');

  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        Stream:=TMemoryStream.Create;
        SysQuery := TUniQuery.Create(nil);
        SysQuery.Connection := SysConn;
//        SysQuery.UniDirectional := True;
        SysQuery.AfterOpen := uniDataAfterOpen;
        sysQuery.Options.EnableBCD := EnableBCD;
        if (PageSize>=20001) then
        Begin
          Try
            TmpSqlComm :='SELECT TOP 0 * FROM '+TableName+' Where '+Where;
            SysQuery.SQL.Text := TmpSqlComm;
            dsp := TDataSetProvider.Create(nil);
            cds := TClientDataSet.Create(nil);
            Dsp.DataSet := SysQuery;
            cds.Data := dsp.Data;
            TableSize := cds.DataSize;
            TmpSqlComm :='SELECT TOP 1 * FROM '+TableName+' Where '+Where;
            if SysQuery.Active then SysQuery.Close;
            SysQuery.SQL.Text := TmpSqlComm;
            dsp := TDataSetProvider.Create(nil);
            cds := TClientDataSet.Create(nil);
            Dsp.DataSet := SysQuery;
            cds.Data := dsp.Data;
            ok := (TableSize + (cds.DataSize - TableSize) * PageSize < 64 * 1024 * 1024);
            if Not ok  then
            begin
              ok := (TableSize + (cds.DataSize - TableSize) * 2000 < 64 * 1024 * 1024);
              if OK then
                PageSize := 2000
              Else
              Begin
                ErrorCode:='0206104D';
                ErrorText:='数据库：['+SysConn.Database+'] '+' 单页查询的数据大小'
                    + FormatFloat('0.00',(TableSize + (cds.DataSize - TableSize) * PageSize) / 1024 / 1024)+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
                NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
              End;
            End;
          finally
            FreeAndNil(cds);
            FreeAndNil(dsp);
          End;
        end;

        if ok then
        begin
          TmpSqlComm := 'select Count(*) As TotalCount From '+ TableName +' Where '+Where;
          if Not SysQuery.Active then SysQuery.Close;
          SysQuery.SQL.Text := TmpSqlComm;
          SysQuery.Open;
          if (SysQuery.FieldByName('TotalCount').AsInteger > 0) then
          Begin
            TotalCount := SysQuery.FieldByName('TotalCount').AsInteger;
            TotalPageCount := ceil(TotalCount / PageSize);
          End;
          SysQuery.Close;

          TmpSqlComm := 'SELECT '+FieldsList+' From '+TableName+' Where '+ Where +' Order By ';
          if (Order='') then
            TmpSqlComm := TmpSqlComm + PrimaryKey
          Else
            TmpSqlComm := TmpSqlComm + Order;

          if (SortType =2) then  TmpSqlComm := TmpSqlComm +' desc ';

          if (PageIndex<=1) then
            TmpSqlComm := TmpSqlComm + ' OFFSET 0 ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
          Else
            TmpSqlComm := TmpSqlComm + ' OFFSET '+Inttostr((PageIndex - 1) * PageSize + 1)+' ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY';
          SysQuery.SQL.Text := TmpSqlComm;
          ok:=DataSetZipToCdsStream(SysQuery,Stream,IsUnicode, Err);
          if not ok then
          begin
            ErrorCode:='0206104C';
            ErrorText:='数据库：['+SysConn.Database+'] '+ Err;
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
          end;
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206103B';
          ErrorText:='数据库：['+SysConn.Database+'] 分页查询出错: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('分页查询SQL语句:'+sysQuery.SQL.Text);
        end;
      end;
       if (not ok) and assigned(Stream) then
          FreeAndNil(Stream);
       SafeFreeUniData(SysQuery);
       NodeService.FreeConnection(PoolId,ConnectionId)
    end;
  end
  else
  begin
    ErrorCode:='0206101C';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
  end;

  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      BackPacket.PutIntegerGoods('TotalCount',TotalCount);
      BackPacket.PutIntegerGoods('TotalPageCount',TotalPageCount);
      ok:=BackPacket.PutStreamGoods('OleVariant',Stream);
      FreeAndNil(Stream);
      if not ok then
      begin
        ErrorCode:='0206101C';
        ErrorText:='封装返回数据集参数错误...';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      end;
    end;

    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
       NodeService.syslog.Log('Err02061: Task_GetPageQuery，创建反馈信息结构失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

// Modified by ZhiFeng 2015-10-05 17:31:09
// 添加 GetUniqueID，获取指定表唯一字段值
procedure TTaskThread.Task_GetUniqueID;
  function GeneralUniqueID(NumberTit, psPror, psNext: String; piCurrID,
    piLength, piCount: Integer): String;
  var
    lsValue,lsTmp:String;
    liCurrLength,i,j:integer;
  begin
    Result:='';
    if piCount<1 then
      exit;
    for i:=piCurrID to piCurrID+piCount-1 do
    begin
      lsValue:=IntToStr(i);
      if piLength=0 then
      begin
        Result:=Result+','+psPror+lsValue+psNext;
      end else
      begin
        liCurrLength:=Length(psPror+lsValue+psNext);
        if liCurrLength<piLength then
        begin
          lsTmp:='';
          for j:=liCurrLength to piLength-1 do
            lsTmp:=lsTmp+'0';
          Result:=Result+','+psPror+lsTmp+lsValue+psNext;
        end;
      end;
    end;
    Result:=Copy(Result,2,Length(Result));
    For I:=Length(Result)+1 To 7 do Result := '0' + Result;
    Result := NumberTit + Result;
  end;
var
  ok: boolean;
  DatabaseId: AnsiString;
  NumberTit, TableName, FieldName, IDList: string;
  liCurrID, liLength:integer;
  lsPror,lsNext:String;
  PoolId,ConnectionId,j: integer;
  Count:Integer;
  SysConn: TUniConnection;
  uniQuery: TUniQuery;
  ParamPacket: TWXDPacket;
  EnableBCD: boolean;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  NumberTit:=RequestPacket.GetStringGoods('NumberTit');
  TableName := RequestPacket.GetStringGoods('TableName');
  FieldName := RequestPacket.GetStringGoods('FieldName');
  Count := 1;
  Count := RequestPacket.GetIntegerGoods('Count');

// GetUniqueID(const DBName: AnsiString; const NumberTit: AnsiString; const TableName: AnsiString;
//        const FieldName: AnsiString; const Count: Integer; var IDList: AnsiString; out ErrMsg: AnsiString): Integer;
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if (pos(':',TableName)>0) and RequestPacket.GoodsExists('Parameters') then
  begin
     ParamPacket:=TWXDPacket.Create;
     ok:=GetPacketFromPacket(RequestPacket,'Parameters',ParamPacket);
     if not ok then
        FreeAndNil(ParamPacket);
  end
  else
  begin
     ParamPacket:=nil;
     ok:=true;
  end;
  ok:=ok and (DatabaseId<>'') and (TableName<>'');

  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        uniQuery:=TUniQuery.Create(nil);
        uniQuery.DisableControls;
        uniQuery.Options.EnableBCD:=EnableBCD;
        uniQuery.Connection:=SysConn;
        try
          EnterCriticalSection(NodeService.DatabaseListCs);
          uniQuery.SQL.Text := 'select * from TAB_AutoNumber where NumberTit='+ QuotedStr(NumberTit)+' And FLDIDNOS='+QuotedStr(TableName);
          if Trim(FieldName)<>'' then
            uniQuery.SQL.Text:=uniQuery.SQL.Text+' and FieldName='+QuotedStr(FieldName);

          if ParamPacket<>nil then
             PacketToParameters(ParamPacket,uniQuery);

          uniQuery.Open;
          if uniQuery.IsEmpty then
          begin
            uniQuery.Append;
            uniQuery.FieldByName('NumberTit').AsString := NumberTit;
            uniQuery.FieldByName('FLDIDNOS').AsString:=TableName;
            uniQuery.FieldByName('FieldName').AsString:=FieldName;
            uniQuery.FieldByName('FLDCOUNTD').AsInteger:=1;
            uniQuery.FieldByName('FLDLENGTHD').AsInteger:=0;
            uniQuery.Post;
          end;
          liCurrID:=uniQuery.FieldByName('FLDCOUNTD').AsInteger;
          liLength:=uniQuery.FieldByName('FLDLENGTHD').AsInteger;
          lsPror:=uniQuery.FieldByName('FLDPREFIXS').AsString;
          lsNext:=uniQuery.FieldByName('FLDSUFFIXS').AsString;
          IDList:=GeneralUniqueID(NumberTit, lsPror,lsNext,liCurrID,liLength,Count);
          uniQuery.Edit;
          uniQuery.FieldByName('FLDCOUNTD').AsInteger:=liCurrID+Count;
          uniQuery.Post;
        finally
          LeaveCriticalSection(NodeService.DatabaseListCs);
        end;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0206103D';
          ErrorText:='创建 UniqueID 失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('数据库：['+SysConn.Database+']  Err'+ErrorCode+': '+ErrorText);
        end;
      end;

      SafeFreeUniData(uniQuery);
      NodeService.FreeConnection(PoolId,ConnectionId)
    end;
  end
  else
  begin
    ErrorCode:='0206101D';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
  end;

  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    if ok then
    begin
      BackPacket.PutStringGoods('IDList',IDList);
      if not ok then
      begin
        ErrorCode:='0206101D';
        ErrorText:='封装返回数据集出错...';
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      end;
    end;
    if not ok then
       begin
          BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
          BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
       end;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
  except
    on e: exception do
       NodeService.syslog.Log('Err02061: Task_GetUniqueID，创建反馈信息结构失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if ParamPacket<>nil then
    FreeAndNil(ParamPacket);
end;

// Modified by ZhiFeng 2015-10-05 18:19:18
procedure TTaskThread.uniDataAfterOpen(DataSet: TDataSet);
var
  I:Smallint;
begin
  For I:=0 to DataSet.FieldCount - 1 do
  Begin
    DataSet.Fields[i].ReadOnly := False;
    DataSet.Fields[i].Required := False;
  End;
end;

procedure TTaskThread.Task_HelloNode;
begin
   try
      BackPacket.PutBooleanGoods('ProcessResult',true);
   except
      on e: exception do
         NodeService.syslog.Log('Error: Generate status Packet failed: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetUserProperty;
var
   ok: boolean;
   UserId: AnsiString;
begin
   UserId:=RequestPacket.GetEncryptStringGoods('UserId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetUserProperty(UserId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208301');
            BackPacket.PutEncryptStringGoods('ErrorText','User not found!');
            NodeService.syslog.Log('Error: 0208301-User not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02083: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetNodeProperty;
var
   ok: boolean;
   NodeId: AnsiString;
begin
   NodeId:=RequestPacket.GetEncryptStringGoods('NodeId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetNodeProperty(NodeId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208401');
            BackPacket.PutEncryptStringGoods('ErrorText','Node not found!');
            NodeService.syslog.Log('Error: 0208401-Node not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02084: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetPluginProperty;       
var
   ok: boolean;
   PluginId: AnsiString;
begin
   PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetPluginProperty(PluginId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208501');
            BackPacket.PutEncryptStringGoods('ErrorText','Plugin module not found!');
            NodeService.syslog.Log('Error: 0208501-Plugin module not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02085: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetScheduleProperty;     
var
   ok: boolean;
   ScheduleId: AnsiString;
begin
   ScheduleId:=RequestPacket.GetEncryptStringGoods('ScheduleId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetScheduleProperty(ScheduleId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208601');
            BackPacket.PutEncryptStringGoods('ErrorText','Schedule task not found!');
            NodeService.syslog.Log('Error: 0208601-Schedule task not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02086: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetUserGroupProperty;    
var
   ok: boolean;
   GroupId: AnsiString;
begin
   GroupId:=RequestPacket.GetEncryptStringGoods('UserGroupId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetGroupProperty(GroupId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208801');
            BackPacket.PutEncryptStringGoods('ErrorText','User group not found!');
            NodeService.syslog.Log('Error: 0208801-User group not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02088: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetDatabaseProperty;
var
   ok: boolean;
   DatabaseId: AnsiString;
begin
   DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   ok:=NodeService.GetDatabaseProperty(DatabaseId,BackPacket);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0208901');
            BackPacket.PutEncryptStringGoods('ErrorText','Database not found!');
            NodeService.syslog.Log('Error: 0208901-Database not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02089: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetWebStatus;
begin
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('WebServiceEnabled',NodeService.s_WebServiceEnabled);
      BackPacket.PutBooleanGoods('WebSocketEnabled',NodeService.s_WebSocketEnabled);
      BackPacket.PutBooleanGoods('ProcessResult',true);
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SetWebService;
var
   EnabledFlag: boolean;
begin
   EnabledFlag:=RequestPacket.GetBooleanGoods('WebServiceEnabled');
   NodeService.s_WebServiceEnabled:=EnabledFlag;
   synchronize(NodeService.ControlWebService);         
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchWebSessions;
var
   Cds: TClientDataset;
   i: integer;
   ok: boolean;
   TargetStream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='WebSessionId';
               DataType:=ftWideString;
               Size:=128;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='AppName';
               DataType:=ftWideString;
               Size:=24;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientName';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientAddress';
               DataType:=ftWideString;
               size:=15;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingIntProp';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingStrProp';
               DataType:=ftWideString;
               size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingRoleId';
               DataType:=ftWideString;
               size:=16;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.WebSessionListCs);
   for i := 0 to NodeService.WebSessionCount - 1 do
      begin
         if not NodeService.WebSessions[i].Used then
            continue;
         try
            Cds.AppendRecord([NodeService.WebSessions[i].SessionId,
                              NodeService.WebSessions[i].AppName,
                              NodeService.WebSessions[i].ClientName,
                              NodeService.WebSessions[i].ClientAddress,
                              NodeService.WebSessions[i].BindingIntProp,
                              NodeService.WebSessions[i].BindingStrProp,
                              NodeService.WebSessions[i].BindingRoleId
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate web session list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.WebSessionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('WebSessionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0209201');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0209201-Compress list data failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02092: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_RemoveWebSession;
procedure RemoveWebSession2(aSessionId: PAnsiChar); stdcall;
var
   i,l,h,m,Index,MainIndex: integer;
begin
   Index:=-1;
   l:=0;
   h:=NodeService.WebSessionIndexCount-1;
   while l<=h do
      begin
         m:=(l+h) div 2;
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(aSessionId,NodeService.WebSessionIndexes[m].PSessionId)=0 then
            begin
               Index:=m;
               break;
            end;
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.WebSessionIndexes[m].PSessionId,aSessionId)>0 then
            h:=m-1
         else
            l:=m+1;
      end;
   if Index<>-1 then
      begin
         MainIndex:=NodeService.WebSessionIndexes[Index].MainIndex;
         for i := Index to NodeService.WebSessionIndexCount - 2 do
             NodeService.WebSessionIndexes[i]:=NodeService.WebSessionIndexes[i+1];
         dec(NodeService.WebSessionIndexCount);
         setlength(NodeService.WebSessionIndexes,NodeService.WebSessionIndexCount);
      end
   else
      MainIndex:=-1;
   if MainIndex<>-1 then
      begin
         NodeService.WebSessions[MainIndex].Used:=false;
         if NodeService.WebSessions[MainIndex].StoragedStatus<>nil then
            FreeAndNil(NodeService.WebSessions[MainIndex].StoragedStatus);
         inc(NodeService.WebSessionUnusedCount);
         setlength(NodeService.WebSessionUnuseds,NodeService.WebSessionUnusedCount);
         NodeService.WebSessionUnuseds[NodeService.WebSessionUnusedCount-1]:=MainIndex;
      end;
end;
var
   aSessionId: AnsiString;
   l,h,m,SessionIndex: integer;
   ok: boolean;
begin
   aSessionId:=RequestPacket.GetEncryptStringGoods('WebSessionId');
   EnterCriticalSection(NodeService.WebSessionListCs);
   try
      if NodeService.WebSessionIndexCount<=0 then
         ok:=false
      else
         ok:=true;
      if ok then
         begin
            if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aSessionId),NodeService.WebSessionIndexes[0].PSessionId)<0)
               or ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aSessionId),NodeService.WebSessionIndexes[NodeService.WebSessionIndexCount-1].PSessionId)>0) then
               ok:=false;
         end;
      if ok then
         begin
            SessionIndex:=-1;
            l:=0;
            h:=NodeService.WebSessionIndexCount-1;
            while l<=h do
               begin
                  m:=(l+h) div 2;
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aSessionId),NodeService.WebSessionIndexes[m].PSessionId)=0 then
                     begin
                        SessionIndex:=NodeService.WebSessionIndexes[m].MainIndex;
                        break;
                     end;
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.WebSessionIndexes[m].PSessionId,PAnsiChar(aSessionId))>0 then
                     h:=m-1
                  else
                     l:=m+1;
               end;
            if SessionIndex<>-1 then
               begin
                  RemoveWebSession2(PAnsiChar(aSessionId));
                  ok:=true;
               end
            else
               ok:=false;
         end;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.WebSessionListCs);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0209301');
            BackPacket.PutEncryptStringGoods('ErrorText','Invalid web session id.');
            NodeService.syslog.Log('Error: 0209301-Invalid web session id.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02093: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SetWebSocket;
var
   EnabledFlag: boolean;
begin
   EnabledFlag:=RequestPacket.GetBooleanGoods('WebSocketEnabled');
   NodeService.s_WebSocketEnabled:=EnabledFlag;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchWSSessions;
var
   Cds: TClientDataset;
   i: integer;
   ok: boolean;
   TargetStream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsSessionId';
               DataType:=ftWideString;
               Size:=24;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsUserId';
               DataType:=ftWideString;
               Size:=16;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsUserName';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsChannelId';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsOrigin';
               DataType:=ftWideString;
               size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='wsIPAddress';
               DataType:=ftWideString;
               size:=15;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.WsSessionListCs);
   for i := 0 to NodeService.wsSessionCount - 1 do
      begin
         if not NodeService.wsSessions[i].Used then
            continue;
         try
            Cds.AppendRecord([SysUtils.IntToStr(NodeService.wsSessions[i].wsSessionId),
                              NodeService.wsSessions[i].wsUserId,
                              NodeService.wsSessions[i].wsUserName,
                              NodeService.wsSessions[i].wsChannel,
                              copy(NodeService.wsSessions[i].wsOrigin,1,64),
                              NodeService.wsSessions[i].wsSocket.RemoteAddress
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate websocket session list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.WsSessionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('WsSessionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0209501');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0209501-Compress list data failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02095: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_RemoveWsSession;
var
   l,h,m,j: integer;
   wsSessionId: Int64;
   ok: boolean;
begin
   wsSessionId:=RequestPacket.GetInt64Goods('wsSessionId');
   EnterCriticalSection(NodeService.wsSessionListCs);
   try
      ok:=(NodeService.wsSessionIndexCount>0);
      if ok then
         begin
            if (wsSessionId<NodeService.wsSessionIndexes[0].wsSessionId) or (wsSessionId>NodeService.wsSessionIndexes[NodeService.wsSessionIndexCount-1].wsSessionId) then
               ok:=false;
         end;
      if ok then
         begin
            j:=-1;
            l:=0;
            h:=NodeService.wsSessionIndexCount-1;
            while l<=h do
               begin
                  m:=(l+h) div 2;
                  if wsSessionId=NodeService.wsSessionIndexes[m].wsSessionId then
                     begin
                        j:=NodeService.wsSessionIndexes[m].MainIndex;
                        break;
                     end;
                  if NodeService.wsSessionIndexes[m].wsSessionId>wsSessionId then
                     h:=m-1
                  else
                     l:=m+1;
               end;
            if j<>-1 then
               begin
                  try
                     NodeService.WSSocket.Socket.CloseAConnection(NodeService.wsSessions[j].wsSocket);
                  except
                  end;
                  ok:=true;
               end
            else
               ok:=false;
         end;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.wsSessionListCs);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0209601');
            BackPacket.PutEncryptStringGoods('ErrorText','Invalid websocket session id.');
            NodeService.syslog.Log('Error: 0209601-Invalid websocket session id.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02096: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToWsUser;
var
   l,h,m,j,DataFormat: integer;
   MsgBody: AnsiString;
   aUserId,aMsg: AnsiString;
   ok: boolean;
begin
   aUserId:=RequestPacket.GetEncryptStringGoods('wsUserId');
   aMsg:=RequestPacket.GetEncryptStringGoods('MessageBody');
   DataFormat:=RequestPacket.GetIntegerGoods('DataFormat');
   EnterCriticalSection(NodeService.wsSessionListCs);
   try
      if NodeService.wsUserIndexCount<=0 then
         ok:=false
      else
         ok:=true;
      if ok then
         begin
            if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[0].PUserId)<0)
               or ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[NodeService.wsUserIndexCount-1].PUserId)>0) then
               ok:=false;
         end;
      if ok then
         begin
            j:=-1;
            l:=0;
            h:=NodeService.wsUserIndexCount-1;
            while l<=h do
               begin
                  m:=(l+h) div 2;
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[m].PUserId)=0 then
                     begin
                        j:=NodeService.wsUserIndexes[m].MainIndex;
                        break;
                     end;
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.wsUserIndexes[m].PUserId,PAnsiChar(aUserId))>0 then
                     h:=m-1
                  else
                     l:=m+1;
               end;
            if j<>-1 then
               begin
                  msgBody:=EncodeWsPackage(DataFormat,aMsg);                    // WebSocket格式的数据
                  ok:=NodeService.PushMsgResponse(NodeService.wsSessions[j].wsSocket,MsgBody);
               end
            else
               ok:=false;
         end;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.wsSessionListCs);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0209701');
            BackPacket.PutEncryptStringGoods('ErrorText','Target websocket user not found!');
            NodeService.syslog.Log('Error: 0209701-Target websocket user not found!');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02097: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToBatchWsUsers;
var
   l,h,m,j,i,DataFormat: integer;
   MsgBody: AnsiString;
   aUserId,aMsg: AnsiString;
   ok: boolean;
   UserList: TStringList;
begin
   UserList:=TStringList.Create;
   UserList.Text:=string(RequestPacket.GetEncryptStringGoods('wsUserList'));
   aMsg:=RequestPacket.GetEncryptStringGoods('MessageBody');
   DataFormat:=RequestPacket.GetIntegerGoods('DataFormat');
   msgBody:=EncodeWsPackage(DataFormat,aMsg);
   EnterCriticalSection(NodeService.wsSessionListCs);
   try
      for i := 0 to UserList.Count - 1 do
         begin
            aUserId:=AnsiString(UserList[i]);
            if NodeService.wsUserIndexCount<=0 then
               ok:=false
            else
               ok:=true;
            if ok then
               begin
                  if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[0].PUserId)<0) or ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[NodeService.wsUserIndexCount-1].PUserId)>0) then
                     ok:=false;
               end;
            if ok then
               begin
                  j:=-1;
                  l:=0;
                  h:=NodeService.wsUserIndexCount-1;
                  while l<=h do
                     begin
                        m:=(l+h) div 2;
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[m].PUserId)=0 then
                           begin
                              j:=NodeService.wsUserIndexes[m].MainIndex;
                              break;
                           end;
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.wsUserIndexes[m].PUserId,PAnsiChar(aUserId))>0 then
                           h:=m-1
                        else
                           l:=m+1;
                     end;
                  if j<>-1 then
                     NodeService.PushMsgResponse(NodeService.wsSessions[j].wsSocket,MsgBody);
               end;
         end;
      ok:=true;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.wsSessionListCs);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   FreeAndNil(UserList);
end;

procedure TTaskThread.Task_SendToWsChannel;
var
   l,h,m,j,i,Channel,DataFormat: integer;
   MsgBody: AnsiString;
   aUserId,aMsg: AnsiString;
   ok: boolean;
begin
   channel:=RequestPacket.GetIntegerGoods('wsChannel');
   aMsg:=RequestPacket.GetEncryptStringGoods('MessageBody');
   DataFormat:=RequestPacket.GetIntegerGoods('DataFormat');
   msgBody:=EncodeWsPackage(DataFormat,aMsg);
   EnterCriticalSection(NodeService.wsSessionListCs);
   try
      for i := 0 to NodeService.wsSessionCount - 1 do
         begin
            if not NodeService.wsSessions[i].Used then
               continue;
            if NodeService.wsSessions[i].wsChannel<>Channel then
               continue;
            aUserId:=NodeService.wsSessions[i].wsUserId;
            if NodeService.wsUserIndexCount<=0 then
               ok:=false
            else
               ok:=true;
            if ok then
               begin
                  if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[0].PUserId)<0) or ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[NodeService.wsUserIndexCount-1].PUserId)>0) then
                     ok:=false;
               end;
            if ok then
               begin
                  j:=-1;
                  l:=0;
                  h:=NodeService.wsUserIndexCount-1;
                  while l<=h do
                     begin
                        m:=(l+h) div 2;
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(aUserId),NodeService.wsUserIndexes[m].PUserId)=0 then
                           begin
                              j:=NodeService.wsUserIndexes[m].MainIndex;
                              break;
                           end;
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.wsUserIndexes[m].PUserId,PAnsiChar(aUserId))>0 then
                           h:=m-1
                        else
                           l:=m+1;
                     end;
                  if j<>-1 then
                     NodeService.PushMsgResponse(NodeService.wsSessions[j].wsSocket,MsgBody);
               end;
         end;
      ok:=true;
   except
      ok:=false;
   end;
   LeaveCriticalSection(NodeService.wsSessionListCs);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ReadTmpFile;
var
   TmpFileName: AnsiString;
   Stream: TMemoryStream;
   ok: boolean;
   ErrText: AnsiString;
begin
   Stream:=nil;
   TmpFileName:=RequestPacket.GetEncryptStringGoods('TmpDataFilename');
   if fileexists(NodeService.s_DefaultDir+'tmp\'+string(TmpFileName)) then
      begin
         try
            Stream:=TMemoryStream.Create;
            Stream.LoadFromFile(NodeService.s_DefaultDir+'tmp\'+string(TmpFileName));
            Stream.Position:=0;
            ok:=true;
         except
            on e: exception do
               begin
                  ok:=false;
                  ErrText:='Read file failed: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
                  if assigned(Stream) then
                     FreeAndNil(Stream);
               end;
         end;
         deletefile(NodeService.s_DefaultDir+'tmp\'+string(TmpFileName));
      end
   else
      begin
         ok:=false;
         ErrText:='File not found.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         begin
            BackPacket.PutStreamGoods('TmpFileBody',Stream);
            FreeAndNil(Stream);
         end
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0210001');
            BackPacket.PutEncryptStringGoods('ErrorText',errtext);
            NodeService.syslog.Log('Error: 0210001-Read tmpdatafile failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Error: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GroupHeartbeat;
var
   tmpGroupId,tmpUserId: AnsiString;
   ok: boolean;
begin
   tmpGroupId:=RequestPacket.GetEncryptStringGoods('GroupId');
   tmpUserId:=RequestPacket.GetEncryptStringGoods('UserId');
   ok:=not ((trim(tmpGroupId)='') or (pos(ansistring('@'),tmpUserId)<=0));
   if ok then
      begin
         ok:=NodeService.GroupMemberHeartbeat(tmpGroupId,tmpUserId);
         if not ok then
            begin
               ErrorCode:='0210202';
               ErrorText:='User group not found or not allowed to join.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            end;
      end
   else
      begin
         ErrorCode:='0210201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02102: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_QueryHeartbeat;
var
   QueryId,QuerySessionId: integer;
   ok: boolean;
begin
   QueryId:=RequestPacket.GetIntegerGoods('QueryId');
   QuerySessionId:=RequestPacket.GetIntegerGoods('QuerySessionId');
   ok:=NodeService.QuerySessionHeartbeat(QueryId,QuerySessionId);
   if not ok then
      begin
         ErrorCode:='0210401';
         ErrorText:='Invalid query session parameters.';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02104: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_BlobToStream;
var
  ok: boolean;
  DatabaseId: AnsiString;
  Stream: TMemoryStream;
  LocateCondition,TableName, BlobFieldName: string;
  SysConn: TuniConnection;
  SysDataset: TUniQuery;
  PoolId,ConnectionId,j: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  try
    ok:=(DatabaseId<>'') and (TableName<>'');
    Stream:=TMemoryStream.Create;
  except
    ok:=false;
  end;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysDataset:=TuniQuery.Create(nil);
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        if LocateCondition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+TableName
        else
           SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysDataset.Active:=true;
        if SysDataset.recordcount>0 then
        begin
          TBlobField(SysDataset.FieldByName(BlobFieldName)).SaveToStream(Stream);
          Stream.Position:=0;
          ok:=true;
        end
        else
        begin
          ok:=false;
          ErrorCode:='0210504';
          ErrorText:='记录不存在。';
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0210503';
          ErrorText:='读 Blob 类型字段至数据流失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      end;
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0210502';
      ErrorText:='分配数据库连接失败。';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
    end;
  end
  else
  begin
    ErrorCode:='0210501';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end
    else
    BackPacket.PutStreamGoods('StreamData',Stream);
  except
    on e: exception do
      NodeService.syslog.Log('Err02105: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

procedure TTaskThread.Task_StreamToBlob;
var
  ok: boolean;
  DatabaseId: AnsiString;
  Stream: TMemoryStream;
  LocateCondition,TableName, BlobFieldName: string;
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  PoolId,ConnectionId,j: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  try
    Stream:=TMemoryStream.Create;
    ok:=RequestPacket.GetStreamGoods('StreamData',Stream);
    Stream.Position:=0;
  except
  ok:=false;
  end;
  ok:=ok and (BlobFieldName<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysDataset:=TuniQuery.Create(nil);
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        if LocateCondition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+TableName
        else
           SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysDataset.Active:=true;
        if SysDataset.recordCount>0 then
        begin
          SysDataset.edit;
          TBlobField(SysDataset.FieldByName(BlobFieldName)).LoadFromStream(Stream);
          SysDataset.post;
          ok:=true;
        end
        else
        begin
          ok:=false;
          ErrorCode:='0210604';
          ErrorText:='保存数据流至　Blob 类型字段失败。';
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0210603';
          ErrorText:='保存数据流至　Blob 类型字段失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      end;
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0210602';
      ErrorText:='分配数据库连接失败。';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
    end;
  end
  else
  begin
    ErrorCode:='0210601';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02106: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

function TTaskThread.Item_StreamToBlob(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  Stream: TMemoryStream;
  LocateCondition,TableName, BlobFieldName: string;
  SysDataset: TuniQuery;
begin
  TableName:=TaskPacket.GetStringGoods('TableName');
  BlobFieldName:=TaskPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=TaskPacket.GetStringGoods('LocateCondition');
  try
    Stream:=TMemoryStream.Create;
    Result:=TaskPacket.GetStreamGoods('StreamData',Stream);
    Stream.Position:=0;
  except
    Result:=false;
  end;
  Result:=Result and (BlobFieldName<>'') and (TableName<>'');
  if Result then
  begin
    try
      SysDataset:=TUniQuery.Create(nil);
      SysDataset.DisableControls;
      SysDataset.Connection:=SysConn;
      if LocateCondition='' then
         SysDataset.SQL.Text:='SELECT * FROM '+TableName
      else
         SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
      SysDataset.Active:=true;
      if SysDataset.recordCount>0 then
      begin
        SysDataset.edit;
        TBlobField(SysDataset.FieldByName(BlobFieldName)).LoadFromStream(Stream);
        SysDataset.post;
        Result:=true;
      end
      else
      begin
        Result:=false;
        ErrorCode:='0210603';
        ErrorText:='保存数据流至　Blob 类型字段失败。';
      end;
    except
      on e: exception do
      begin
        Result:=false;
        ErrorCode:='0210603';
        ErrorText:='保存数据流至　Blob 类型字段失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
      end;
    end;
    SafeFreeUniData(SysDataset);
  end
  else
  begin
    ErrorCode:='0210601';
    ErrorText:='无效参数。';
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
  RetValue:='';
end;

procedure TTaskThread.Task_GetBlobMd5;
var
  ok: boolean;
  DatabaseId,Md5: AnsiString;
  Stream: TMemoryStream;
  LocateCondition,TableName, BlobFieldName: string;
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  PoolId,ConnectionId,j: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  try
    ok:=(DatabaseId<>'') and (TableName<>'');
    Stream:=TMemoryStream.Create;
  except
    ok:=false;
  end;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        if LocateCondition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+TableName
        else
           SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysDataset.Active:=true;
        if SysDataset.recordcount>0 then
        begin
          TBlobField(SysDataset.FieldByName(BlobFieldName)).SaveToStream(Stream);
          Stream.Position:=0;
          ok:=GetStreamMd5(Stream,md5);
        end
        else
        begin
          ok:=false;
          ErrorCode:='0213104';
          ErrorText:='记录不存在。';
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0213103';
          ErrorText:='读 Blob 类型字段至数据流失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      end;
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0213102';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
    end;
  end
  else
  begin
    ErrorCode:='0213101';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end
    else
    BackPacket.PutAnsiStringGoods('BlobMd5',md5);
  except
    on e: exception do
      NodeService.syslog.Log('Err02131: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

procedure TTaskThread.Task_GetBlobSha1;
var
  ok: boolean;
  DatabaseId,Sha1: AnsiString;
  Stream: TMemoryStream;
  LocateCondition,TableName, BlobFieldName: string;
  SysConn: TuniConnection;
  SysDataset: TuniQuery;
  PoolId,ConnectionId,j: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  BlobFieldName:=RequestPacket.GetStringGoods('BlobFieldName');
  LocateCondition:=RequestPacket.GetStringGoods('LocateCondition');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  try
    ok:=(DatabaseId<>'') and (TableName<>'');
    Stream:=TMemoryStream.Create;
  except
    ok:=false;
  end;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        if LocateCondition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+TableName
        else
           SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE '+LocateCondition;
        SysDataset.Active:=true;
        if SysDataset.recordcount>0 then
        begin
          TBlobField(SysDataset.FieldByName(BlobFieldName)).SaveToStream(Stream);
          Stream.Position:=0;
          ok:=GetStreamSha1(Stream,Sha1);
        end
        else
        begin
          ok:=false;
          ErrorCode:='0213204';
          ErrorText:='记录不存在。';
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0213203';
          ErrorText:='读 Blob 类型字段失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
        end;
      end;
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0213202';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
    end;
  end
  else
  begin
    ErrorCode:='0213201';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(BlobFieldName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end
    else
    BackPacket.PutAnsiStringGoods('BlobSha1',Sha1);
  except
    on e: exception do
      NodeService.syslog.Log('Err02132: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  if assigned(Stream) then
    FreeAndNil(Stream);
end;

procedure TTaskThread.Task_MountPlugin;
var
   ok: boolean;
   PluginId,PluginPassword: AnsiString;
   i,j: integer;
   InitProc: pointer;
   ApiInitProc: TApiInitProc;
   tmpPacket: TwxdPacket;
begin
   PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
   ok:=(trim(PluginId)<>'');
   if ok then
      begin
         EnterCriticalSection(NodeService.PluginListCs);
         try
            j:=-1;
            for i:=0 to NodeService.PluginCount-1 do
               if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginId),PAnsiChar(NodeService.Plugins[i].PluginId))=0) then
                  begin
                     j:=i;
                     break;
                  end;
            if j<>-1 then
               begin
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginPassword),PAnsiChar(NodeService.Plugins[j].PluginPassword))=0 then
                     begin
                        if NodeService.Plugins[j].LoadCount>0 then
                           inc(NodeService.Plugins[j].LoadCount)
                        else
                           begin
                              try
                                 NodeService.Plugins[j].PluginHandle:=Loadlibrary(pchar(NodeService.s_defaultdir+'plugins\'+NodeService.Plugins[j].PluginFilename));
                              except
                                 NodeService.Plugins[j].PluginHandle:=0;
                              end;
                              if NodeService.Plugins[j].PluginHandle<>0 then
                                 begin
                                    InitProc:=GetProcAddress(NodeService.Plugins[j].PluginHandle,'ApiInitialize');
                                    if InitProc<>nil then
                                       begin
                                          TmpPacket:=TwxdPacket.Create;
                                          try
                                             TmpPacket.PutIntegerGoods('Callback_Proc_List',integer(@NodeService.ExportAddrList[0]));
                                             TmpPacket.PutAnsiStringGoods('Transfer_Key',NodeService.s_TransferKey);
                                             TmpPacket.PutAnsiStringGoods('ThisNodeId',NodeService.s_ThisNodeId);
                                             ApiInitProc:=TApiInitProc(InitProc);
                                             ApiInitProc(integer(Pointer(TmpPacket)));
                                          except
                                          end;
                                          FreeAndNil(TmpPacket);
                                       end;
                                    NodeService.Plugins[j].PluginProcAddress:=GetProcAddress(NodeService.Plugins[j].PluginHandle,'RemoteProcess');
                                    if NodeService.Plugins[j].PluginProcAddress=nil then
                                       begin
                                          FreeLibrary(NodeService.Plugins[j].PluginHandle);
                                          CloseHandle(NodeService.Plugins[j].PluginHandle);
                                          NodeService.Plugins[j].PluginHandle:=0;
                                          ok:=false;
                                       end;
                                 end
                              else
                                 ok:=false;
                              if ok then
                                 NodeService.Plugins[j].LoadCount:=1
                              else
                                 begin
                                    NodeService.Plugins[j].LoadCount:=0;
                                    ErrorCode:='0210904';
                                    ErrorText:='Load plugin module failed!';
                                    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                                    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
                                 end;
                           end;
                        NodeService.Plugins[j].LastActiveTime:=now;
                     end
                  else
                     begin
                        ErrorCode:='0210903';
                        ErrorText:='Plugin password invalid!';
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
                        ok:=false;
                     end;
               end
            else
               begin
                  ErrorCode:='0210902';
                  ErrorText:='Plugin not found!';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
                  ok:=false;
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.PluginListCs);
      end
   else
      begin
         ErrorCode:='0210901';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02044: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_DismountPlugin;
var
   ok: boolean;
   PluginId,PluginPassword: AnsiString;
   i,j: integer;
begin
   PluginId:=RequestPacket.GetEncryptStringGoods('PluginId');
   PluginPassword:=RequestPacket.GetEncryptStringGoods('PluginPassword');
   ok:=(trim(PluginId)<>'');
   if ok then
      begin
         EnterCriticalSection(NodeService.PluginListCs);
         try
            j:=-1;
            for i:=0 to NodeService.PluginCount-1 do
               if ({$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginId),PAnsiChar(NodeService.Plugins[i].PluginId))=0) then
                  begin
                     j:=i;
                     break;
                  end;
            if j<>-1 then
               begin
                  if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(PAnsiChar(PluginPassword),PAnsiChar(NodeService.Plugins[j].PluginPassword))=0 then
                     begin
                        if NodeService.Plugins[j].LoadCount>1 then
                           dec(NodeService.Plugins[j].LoadCount)
                        else
                           begin
                              if NodeService.Plugins[j].LoadCount=1 then
                                 begin
                                    NodeService.DoUninitialize(NodeService.Plugins[j].PluginHandle);
                                    FreeLibrary(NodeService.Plugins[j].PluginHandle);
                                    CloseHandle(NodeService.Plugins[j].PluginHandle);
                                    NodeService.Plugins[j].PluginHandle:=0;
                                 end;
                              NodeService.Plugins[j].LoadCount:=0;
                           end;
                        NodeService.Plugins[j].LastActiveTime:=now;
                     end
                  else
                     begin
                        ErrorCode:='0211003';
                        ErrorText:='Plugin password invalid!';
                        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
                        ok:=false;
                     end;
               end
            else
               begin
                  ErrorCode:='0211002';
                  ErrorText:='Plugin not found!';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
                  ok:=false;
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.PluginListCs);
      end
   else
      begin
         ErrorCode:='0211001';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+PluginId);
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02044: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetTmpFileName;
var
   tmpPath: string;
   SerialNumber: string;
begin
   tmpPath:=NodeService.s_DefaultDir+'tmp\';
   SerialNumber:=inttostr(AllocTmpDataId);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutStringGoods('TmpPath',tmpPath);
      BackPacket.PutStringGoods('SerialNumber',SerialNumber);
   except
      on e: exception do
         NodeService.syslog.Log('Err02044: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchBlackList;
var
   ok: boolean;
   Cds: TClientDataset;
   Stream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='BlackId';
               DataType:=ftWideString;
               Size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BlackName';
               DataType:=ftWideString;
               Size:=48;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='RejectReason';
               DataType:=ftWideString;
               Size:=64;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.BlackListToCds(Cds);
   Stream:=nil;
   try
      Stream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,Stream,err);
      if not ok then
         begin
            ErrorCode:='0211201';
            ErrorText:='Zip Black list failed: '+ansistring(err);
            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      if ok then
         begin
            BackPacket.PutIntegerGoods('BlackCount',Cds.RecordCount);
            ok:=BackPacket.PutStreamGoods('BlackList',Stream);
            if not ok then
               begin
                  ErrorCode:='0211202';
                  ErrorText:='Return list failed.';
                  NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                  NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
               end;
         end;
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02112: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_AddBlack;
var
   ok: boolean;
   tmpBlackId,tmpBlackName,tmpRejectReason: ansistring;
begin
   tmpBlackId:=RequestPacket.GetEncryptStringGoods('BlackId');
   tmpBlackName:=RequestPacket.GetEncryptStringGoods('BlackName');
   tmpRejectReason:=RequestPacket.GetEncryptStringGoods('RejectReason');
   ok:=(trim(tmpBlackId)<>'') and (uppercase(trim(tmpBlackId))<>'SYSTEM');
   if ok then
      begin
         ok:=NodeService.AddBlack(tmpBlackId,tmpBlackName,tmpRejectReason);
         if not ok then
            begin
               ErrorCode:='0211302';
               ErrorText:='Black Id already exists.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0211301';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02113: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RemoveBlack;
var
   ok: boolean;
   tmpBlackId: ansistring;
begin
   tmpBlackId:=RequestPacket.GetEncryptStringGoods('BlackId');
   ok:=(trim(tmpBlackId)<>'');
   if ok then
      begin
         ok:=NodeService.RemoveBlack(tmpBlackId);
         if not ok then
            begin
               ErrorCode:='0211402';
               ErrorText:='Black not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0211401';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02114: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_BindIntProp;
var
   ConnectionId: int64;
   IntProp,MainIndex: integer;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   IntProp:=RequestPacket.GetIntegerGoods('IntProp');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingIntProp=-1);
         if ok then
            begin
               try
                  NodeService.AddIntPropIndex(IntProp,MainIndex);
               except
                  ok:=false;
                  ErrorCode:='0211503';
                  ErrorText:='Add to property array failed.';
               end;
            end
         else
            begin
               ErrorCode:='0211502';
               ErrorText:='IntProp has binded.';
            end;
      end
   else
      begin
         ErrorCode:='0211501';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02115: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_BindStrProp;
var
   ConnectionId: int64;
   MainIndex: integer;
   StrProp: AnsiString;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   StrProp:=RequestPacket.GetAnsiStringGoods('StrProp');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingStrProp='');
         if ok then
            begin
               try
                  NodeService.AddStrPropIndex(StrProp,MainIndex);
               except
                  ok:=false;
                  ErrorCode:='0211603';
                  ErrorText:='Add to property array failed.';
               end;
            end
         else
            begin
               ErrorCode:='0211602';
               ErrorText:='StrProp has binded.';
            end;
      end
   else
      begin
         ErrorCode:='0211601';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02116: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToConnection;
var
   ok: boolean;
   ConnectionId: int64;
   FromUserId: AnsiString;
   Packet: TwxdPacket;
   MainIndex: integer;
begin
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   ConnectionId:=RequestPacket.GetInt64Goods('TargetConnectionId');
   Packet:=TwxdPacket.Create;
   Packet.EncryptKey:=NodeService.s_TransferKey;
   ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   if ok then
      begin
         MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
         if MainIndex<>-1 then
            begin
               try
                  Packet.PutIntegerGoods('ResponseId',23);
                  Packet.PutEncryptStringGoods('FromUserId',FromUserId);
                  ok:=Packet.SaveToStringWithLength(ResponseBody);
               except
                  ok:=false;
               end;
               if ok then
                  ok:=NodeService.PushMsgResponse(NodeService.Connections[MainIndex].Socket,ResponseBody);
               if not ok then
                  begin
                     ErrorCode:='0211703';
                     ErrorText:='Push message to queue failed.';
                     NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                     NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
                  end;
            end
         else
            begin
               ErrorCode:='0211702';
               ErrorText:='Target connection not found.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0211701';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02117: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToIntPropConnections;
var
   ok: boolean;
   FromUserId: AnsiString;
   Packet: TwxdPacket;
   MainIndex,IntProp,i,StartIndex: integer;
begin
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   IntProp:=RequestPacket.GetIntegerGoods('TargetIntProp');
   Packet:=TwxdPacket.Create;
   Packet.EncryptKey:=NodeService.s_TransferKey;
   ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   if ok then
      begin
         try
            Packet.PutIntegerGoods('ResponseId',24);
            Packet.PutEncryptStringGoods('FromUserId',FromUserId);
            ok:=Packet.SaveToStringWithLength(ResponseBody);
         except
            ok:=false;
         end;
      end;
   if ok then
      begin
         EnterCriticalSection(NodeService.ConnectionListCs);
         try
            StartIndex:=NodeService.FindConnectionInIntProp2(IntProp);
            if StartIndex<>-1 then
               begin
                  for i := StartIndex to NodeService.IntPropIndexCount - 1 do
                     begin
                        if NodeService.IntPropIndexes[i].IntProp=IntProp then
                           begin
                              MainIndex:=NodeService.IntPropIndexes[i].MainIndex;
                              try
                                 NodeService.PushMsgResponse(NodeService.Connections[MainIndex].Socket,ResponseBody);
                              except
                              end;
                           end
                        else
                           break;
                     end;
               end;
         except
         end;
         LeaveCriticalSection(NodeService.ConnectionListCs);
         if not ok then
            begin
               ErrorCode:='0211802';
               ErrorText:='Push message to queue failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0211801';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02118: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToStrPropConnections;
var
   ok: boolean;
   StrProp,FromUserId: AnsiString;
   Packet: TwxdPacket;
   MainIndex,i,StartIndex: integer;
begin
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   StrProp:=RequestPacket.GetAnsiStringGoods('TargetStrProp');
   Packet:=TwxdPacket.Create;
   Packet.EncryptKey:=NodeService.s_TransferKey;
   ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   if ok then
      begin
         try
            Packet.PutIntegerGoods('ResponseId',25);
            Packet.PutEncryptStringGoods('FromUserId',FromUserId);
            ok:=Packet.SaveToStringWithLength(ResponseBody);
         except
            ok:=false;
         end;
      end;
   if ok then
      begin
         EnterCriticalSection(NodeService.ConnectionListCs);
         try
            StartIndex:=NodeService.FindConnectionInStrProp2(StrProp);
            if StartIndex<>-1 then
               begin
                  for i := StartIndex to NodeService.StrPropIndexCount - 1 do
                     begin
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.StrPropIndexes[i].StrProp,PAnsiChar(StrProp))=0 then
                           begin
                              MainIndex:=NodeService.StrPropIndexes[i].MainIndex;
                              try
                                 NodeService.PushMsgResponse(NodeService.Connections[MainIndex].Socket,ResponseBody);
                              except
                              end;
                           end
                        else
                           break;
                     end;
               end;
         except
         end;
         LeaveCriticalSection(NodeService.ConnectionListCs);
         if not ok then
            begin
               ErrorCode:='0211902';
               ErrorText:='Push message to queue failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0211901';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02119: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchIntPropConnections;
var
   ok: boolean;
   MainIndex,IntProp,i: integer;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   err: string;
begin
   IntProp:=RequestPacket.GetIntegerGoods('TargetIntProp');
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='ConnectionId';
               DataType:=ftLargeInt;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientIpAddress';
               DataType:=ftWideString;
               Size:=15;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingIntProp';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingStrProp';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingRoleId';
               DataType:=ftWideString;
               Size:=8;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.ConnectionListCs);
   for i := 0 to NodeService.IntPropIndexCount - 1 do
      begin
         if NodeService.IntPropIndexes[i].IntProp<>IntProp then
            continue;
         MainIndex:=NodeService.IntPropIndexes[i].MainIndex;
         try
            Cds.AppendRecord([NodeService.Connections[mainindex].ConnectionId,
                              NodeService.Connections[mainindex].socket.remoteaddress,
                              NodeService.Connections[mainindex].BindingIntProp,
                              string(copy(NodeService.Connections[mainindex].BindingStrProp,1,64)),
                              string(copy(NodeService.Connections[mainindex].BindingRoleId,1,8))
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate integer property connection list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.ConnectionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('ConnectionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0212001');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0212001-Compress list data failed.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02120: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_FetchStrPropConnections;
var
   ok: boolean;
   MainIndex,i: integer;
   StrProp: AnsiString;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   err: string;
begin
   StrProp:=RequestPacket.GetAnsiStringGoods('TargetStrProp');
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='ConnectionId';
               DataType:=ftLargeInt;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientIpAddress';
               DataType:=ftWideString;
               Size:=15;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingIntProp';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingStrProp';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingRoleId';
               DataType:=ftWideString;
               Size:=8;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.ConnectionListCs);
   for i := 0 to NodeService.StrPropIndexCount - 1 do
      begin
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.StrPropIndexes[i].StrProp,PAnsiChar(StrProp))<>0 then
            continue;
         MainIndex:=NodeService.StrPropIndexes[i].MainIndex;
         try
            Cds.AppendRecord([NodeService.Connections[mainindex].ConnectionId,
                              NodeService.Connections[mainindex].socket.remoteaddress,
                              NodeService.Connections[mainindex].BindingIntProp,
                              string(copy(NodeService.Connections[mainindex].BindingStrProp,1,64)),
                              string(copy(NodeService.Connections[mainindex].BindingRoleId,1,8))
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate string property connection list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.ConnectionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('ConnectionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0212101');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0212101-Compress list data failed.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02121: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_ClearIntProp;
var
   ConnectionId: int64;
   MainIndex: integer;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingIntProp<>-1);
         if ok then
            NodeService.RemoveIntPropIndex(MainIndex)
         else
            begin
               ErrorCode:='0212202';
               ErrorText:='IntProp not binded.';
            end;
      end
   else
      begin
         ErrorCode:='0212201';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02122: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ClearStrProp;
var
   ConnectionId: int64;
   MainIndex: integer;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingStrProp<>'');
         if ok then
            NodeService.RemoveStrPropIndex(MainIndex)
         else
            begin
               ErrorCode:='0212302';
               ErrorText:='StrProp not binded.';
            end;
      end
   else
      begin
         ErrorCode:='0212301';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02123: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetIntPropCount;
var
   IntProp,j: integer;
begin
   IntProp:=RequestPacket.GetIntegerGoods('IntProp');
   j:=NodeService.GetIntPropConnectionCount(IntProp);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutIntegerGoods('IntPropConnections',j);
   except
      on e: exception do
         NodeService.syslog.Log('Err02129: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetStrPropCount;
var
   StrProp: AnsiString;
   j: integer;
begin
   StrProp:=RequestPacket.GetAnsiStringGoods('StrProp');
   j:=NodeService.GetStrPropConnectionCount(StrProp);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutIntegerGoods('StrPropConnections',j);
   except
      on e: exception do
         NodeService.syslog.Log('Err02130: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ReadMultiDataset;
var
  DatabaseId: ansistring;
  SqlList: TStringList;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;
  PoolId,ConnectionId: integer;
  DatasetCount,i,j: integer;
  ok,EnableBCD,IsUnicode: boolean;     //IsAdoFormat
  Stream: TMemoryStream;
  Err: string;
begin
  SysConn:=nil;
  SysQuery:=nil;
  Stream:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlList:=TStringList.Create;
  SqlList.Text:=RequestPacket.GetStringGoods('SqlCommandList');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  IsUnicode:=RequestPacket.GoodsExists('IsUnicode');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
  if ok and (j<>-1) then
    ok:=SetIsoLevel(SysConn,j);
  BackPacket.EncryptKey:=NodeService.s_TransferKey;
  if ok then
  begin
    try
      SysQuery:=TuniQuery.Create(nil);
      SysQuery.DisableControls;
      SysQuery.connection:=SysConn;
      SysQuery.Options.EnableBCD:=EnableBCD;
//      SysQuery.UniDirectional := True;
      SysQuery.AfterOpen := uniDataAfterOpen;
      DatasetCount:=0;
      Stream:=TMemoryStream.Create;
      for i := 0 to SqlList.Count - 1 do
      begin
        if trim(SqlList.Strings[i])='' then
           continue;
        SysQuery.SQL.Text:=trim(SqlList.Strings[i]);
//        try
//          SysQuery.Active:=true;
//          ok:=true;
//        except
//          on e: exception do
//          begin
//            ok:=false;
//            ErrorCode:='0212401';
//            ErrorText:='执行SQL失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//            NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
//          end;
//        end;
//        if ok then
//        begin
//          if IsAdoFormat then
//             ok:=DatasetZipToStream(SysQuery,Stream,Err)
//          else
          ok:=DatasetZipToCdsStream(SysQuery,Stream,IsUnicode,Err);
          if ok then
          begin
            inc(DatasetCount);
            try
              BackPacket.PutStreamGoods('Dataset_'+AnsiString(inttostr(DatasetCount)),Stream);
              ok:=true;
            except
              on e: exception do
              begin
                ok:=false;
                ErrorCode:='0212402';
                ErrorText:='数据集转换为数据结构包时出错: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
                NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
                NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
              end;
            end;
          end
          else
         begin
            ErrorCode:='0212403';
            ErrorText:='Convert dataset to stream failed: '+ansistring(err);
         end;
//        end;
        If SysQuery.Active Then SysQuery.Close;
        if not ok then
           break;
      end;
    except
      on e: exception do
      begin
        ok:=false;
        ErrorCode:='0212405';
        ErrorText:='批量读取多个数据集失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
      end;
    end;
    if assigned(Stream) then
      FreeAndNil(Stream);
    SafeFreeUniData(SysQuery);
    NodeService.FreeConnection(PoolId,ConnectionId);
  end
  else
  begin
    ErrorCode:='0212404';
    ErrorText:='数据库连接分配失败...';
  end;
  FreeAndNil(SqlList);
  try
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end
    else
    BackPacket.PutIntegerGoods('DatasetCount',DatasetCount);
  except
    on e: exception do
      NodeService.syslog.Log('Err02124: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

//procedure TTaskThread.Task_WriteMultiDataset;
//var
//  DatabaseId: ansistring;
//  SysConn: TUniConnection;
//  SysQuery,AdoDs: TUniQuery;
//  SysCommand: TAdoCommand;
//  PoolId,ConnectionId: integer;
//  PacketCount: integer;
//  Packets: array of TwxdPacket;
//  i,j: integer;
//  ok,EnableBCD,IsAdoFormat: boolean;
//  TableName,ClearSql,err: string;
//  Cds: TClientDataset;
//begin
//  SysConn:=nil;
//  SysQuery:=nil;
//  SysCommand:=nil;
//  Cds:=nil;
//  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
//  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
//  PacketCount:=RequestPacket.GetIntegerGoods('DatasetCount');
//  if RequestPacket.GoodsExists('IsolationLevel') then
//    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
//  else
//    j:=-1;
//  if (trim(databaseid)='') or (PacketCount<=0) then
//  begin
//    NodeService.syslog.Log('Err02125: 批量进行数据更新参数无效...');
//    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//    exit;
//  end;
//  setlength(Packets,PacketCount);
//  ok:=true;
//  for i := 0 to PacketCount - 1 do
//  begin
//    Packets[i]:=TwxdPacket.Create;
//    ok:=ok and RequestPacket.GetPacketGoods('DatasetPacket_'+AnsiString(inttostr(i)),Packets[i]);
//  end;
//  if not ok then
//  begin
//    NodeService.syslog.Log('Err02125: Invalid dataset Packet list of writing multiple datasets.');
//    for i := 0 to PacketCount - 1 do
//    begin
//      if assigned(Packets[i]) then
//        FreeAndNil(Packets[i]);
//    end;
//    setlength(Packets,0);
//    exit;
//  end;
//  ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
//  if ok and (j<>-1) then
//  ok:=SetIsoLevel(SysConn,j);
//  if not ok then
//  begin
//    NodeService.syslog.Log('Err02125: 数据库连接分配失败...');
//    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
//    for i := 0 to PacketCount - 1 do
//    begin
//       if assigned(Packets[i]) then
//          FreeAndNil(Packets[i]);
//    end;
//    setlength(Packets,0);
//    exit;
//  end;
//  try
//    SysQuery:=TUniQuery.Create(nil);
//    SysQuery.DisableControls;
//    SysQuery.CommandTimeout:=300;
//    SysQuery.Connection:=SysConn;
//    SysQuery.EnableBCD:=EnableBCD;
//    SysCommand:=TAdoCommand.Create(nil);
//    SysCommand.Connection:=SysConn;
//    SysCommand.CommandTimeout:=300;
//    Cds:=TClientDataset.Create(nil);
//    Cds.DisableControls;
//    AdoDs:=TUniQuery.Create(nil);
//    AdoDs.DisableControls;
//    AdoDs.CommandTimeout:=300;
//    SysConn.BeginTrans;
//    ok:=true;
//    for i:=0 to PacketCount - 1 do
//    begin
//      TableName:=Packets[i].GetStringGoods('TableName');
//      ClearSql:=Packets[i].GetStringGoods('ClearSQL');
//      IsAdoFormat:=Packets[i].GoodsExists('IsAdoFormat');
//      if IsAdoFormat then
//         IsAdoFormat:=Packets[i].GetBooleanGoods('IsAdoFormat');
//      if IsAdoFormat then
//         begin
//            AdoDs.Close;
//            ok:=(trim(TableName)<>'') and GetAdoDsFromPacket(Packets[i],'DatasetBody',AdoDs);
//         end
//      else
//         begin
//            Cds.Close;
//            ok:=(trim(TableName)<>'') and GetCdsFromPacket(Packets[i],'DatasetBody',Cds);
//         end;
//      if not ok then
//         begin
//            ErrorCode:='0212501';
//            ErrorText:='Invalid committed datasets.';
//            break;
//         end;
//      if trim(ClearSQL)<>'' then
//         begin
//            SysCommand.CommandText:=ClearSQL;
//            SysCommand.Execute;
//         end;
//      SysQuery.CommandText:='SELECT * FROM '+TableName+' WHERE 1=2';
//      SysQuery.Active:=true;
//      if IsAdoFormat then
//         ok:=AdoDsWriteToDataset(AdoDs,SysQuery,Err)
//      else
//         ok:=CdsWriteToDataset(Cds,SysQuery,Err);
//      SysQuery.Active:=false;
//      if not ok then
//         begin
//            ErrorCode:='0212502';
//            ErrorText:=AnsiString(err);
//            break;
//         end;
//    end;
//    if ok then
//    SysConn.CommitTrans
//    else
//    SysConn.RollbackTrans;
//    if not ok then
//    begin
//      ErrorCode:='0212504';
//      if ErrorText='' then
//         ErrorText:='Write datasets failed.';
//      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
//    end;
//  except
//    on e: exception do
//    begin
//      ok:=false;
//      ErrorCode:='0212503';
//      ErrorText:='Commit transaction failed: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
//      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
//      try
//         if SysConn.InTransaction then
//            SysConn.RollbackTrans;
//      except
//      end;
//      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
//    end;
//  end;
//  SafeFreeUniData(SysQuery);
//  if assigned(SysCommand) then
//    FreeAndNil(SysCommand);
//  if assigned(Cds) then
//    FreeAndNil(Cds);
//  SafeFreeUniData(Adods);
//  NodeService.FreeConnection(PoolId,ConnectionId);
//  for i := 0 to PacketCount - 1 do
//  begin
//    if assigned(Packets[i]) then
//      FreeAndNil(Packets[i]);
//  end;
//  setlength(Packets,0);
//  BackPacket.EncryptKey:=NodeService.s_TransferKey;
//  try
//    BackPacket.PutBooleanGoods('ProcessResult',ok);
//    if not ok then
//    begin
//      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
//      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
//    end;
//  except
//    on e: exception do
//    Node  Service.syslog.Log('Err02125: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
//  end;
//end;

procedure TTaskThread.Task_WriteMultiDataset;
var
  DatabaseId: ansistring;
  SysConn: TUniConnection;
  SysQuery: TUniQuery;    //AdoDs
  SysSQL: TUniSQL;
  PoolId,ConnectionId: integer;
  PacketCount: integer;
  Packets: array of TwxdPacket;
  i,j: integer;
  ok,EnableBCD, cdsOK: boolean;    //IsAdoFormat
  TableName,ClearSql,err: string;
  Cds: TClientDataset;
  loDM:TAppDM;
  upData:OleVariant;
  psCommandtext, KeyFieldList:String;
  uniErr:AnsiString;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  PacketCount:=RequestPacket.GetIntegerGoods('DatasetCount');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if (trim(databaseid)='') or (PacketCount<=0) then
  begin
    NodeService.syslog.Log('Err02125: 一次写多个数据集的参数无效！');
    exit;
  end;
  setlength(Packets,PacketCount);
  ok:=true;
  for i := 0 to PacketCount - 1 do
  begin
    Packets[i]:=TwxdPacket.Create;
    ok:=ok and RequestPacket.GetPacketGoods('DatasetPacket_'+AnsiString(inttostr(i)),Packets[i]);
  end;
  if not ok then
  begin
    NodeService.syslog.Log('Err02125: 无效数据集分组列表！');
    for i := 0 to PacketCount - 1 do
    begin
     if assigned(Packets[i]) then
        FreeAndNil(Packets[i]);
    end;
    setlength(Packets,0);
    exit;
  end;
  ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
  if ok and (j<>-1) then
       ok:=SetIsoLevel(SysConn,j);
  if not ok then
  begin
    NodeService.syslog.Log('Err02125: 分配数据库连接失败！');
    for i := 0 to PacketCount - 1 do
    begin
       if assigned(Packets[i]) then
          FreeAndNil(Packets[i]);
    end;
    setlength(Packets,0);
    exit;
  end;
  try
    SysQuery:=TUniQuery.Create(nil);
    SysQuery.DisableControls;
    SysQuery.Connection:=SysConn;
    SysQuery.Options.EnableBCD:=EnableBCD;
    SysSQL:=TUniSQL.Create(nil);
    SysSQL.Connection:=SysConn;
    Cds:=TClientDataset.Create(nil);
    Cds.DisableControls;
    SysConn.StartTransaction;

    ok:=true;
    loDM := TAppDM.Create(nil);
//    EnterCriticalSection(NodeService.DatabaseListCs);
//    Try
      for i:=0 to PacketCount - 1 do
      begin
        TableName:=Packets[i].GetStringGoods('TableName');
        ClearSql:=Packets[i].GetStringGoods('ClearSQL');
        KeyFieldList := Packets[i].GetStringGoods('KeyFieldList');         //关键字段
        Cds.Close;
        cdsOk := GetCdsFromPacket(Packets[i],'DatasetBody',Cds);
        ok:=(trim(TableName)<>'') and cdsOK or (trim(ClearSQL)<>'');
        if not ok then
        begin
          ErrorCode:='0212501';
          ErrorText:='提交的数据集无效！';
          break;
        end;
        if cdsOK then
        Begin
          Try
            upData := Cds.Data;
            cds.First;
            psCommandtext := 'SELECT * FROM '+TableName+' where 1<>1';
            loDM.DSPUpdateTable.UpdateTableName := TableName;
            ok := loDM.UpdateTable(upData, psCommandtext, KeyFieldList, SysConn, uniErr);
            if not Ok then
            Begin
               ErrorText := '提交数据表：'+TableName+' 失败: '+ uniErr;
               Break;
            End;
          Except
            ErrorCode:='0212502';
            ErrorText:='提交数据表：'+TableName+' 失败!!!';//uniErr;
            break;
          End;
        End;
        if trim(ClearSQL)<>'' then
        begin
          Try
            SysSQL.SQL.Text:=ClearSQL;
            SysSQL.Execute;
          Except
            on E: Exception do
            begin
              ok:=false;
              ErrorCode:='0212506';
              ErrorText:='执行 SQL 命令失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
              NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
              NodeService.syslog.Log('执行失败的 SQL 语句: '+ClearSQL);
              break
            end;
          end;
        End;
      end;
      if ok then
        SysConn.Commit
      else
      Begin
        SysConn.Rollback;
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      End;
//    finally
//      LeaveCriticalSection(NodeService.DatabaseListCs);
//    end;
    FreeAndNIl(loDM);
  except
    on e: exception do
    begin
      ok:=false;
      ErrorCode:='0212503';
      ErrorText:='事务提交失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      try
        if SysConn.InTransaction then
          SysConn.Rollback;
      except
      end;
    end;
  end;
  SafeFreeUniData(SysQuery);
  if assigned(SysSQL) then
    FreeAndNil(SysSQL);
  if assigned(Cds) then
    FreeAndNil(Cds);

  NodeService.FreeConnection(PoolId,ConnectionId);
  for i := 0 to PacketCount - 1 do
  begin
  if assigned(Packets[i]) then
    FreeAndNil(Packets[i]);
  end;
  setlength(Packets,0);
  BackPacket.EncryptKey:=NodeService.s_TransferKey;
  try
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02125: 创建信息反馈结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_WriteMultiDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  SysDataset: TuniQuery;
  SysCommand: TuniSQL;
  PacketCount: integer;
  Packets: array of TwxdPacket;
  i: integer;
  EnableBCD: boolean;
  TableName,ClearSql,Err: string;
  Cds: TClientDataset;
begin
  RetValue:='';
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  PacketCount:=TaskPacket.GetIntegerGoods('DatasetCount');
  if PacketCount<=0 then
  begin
    ErrorCode:='0212501';
    ErrorText:='无效的数据集数量。';
    result:=false;
    exit;
  end;
  setlength(Packets,PacketCount);
  Result:=true;
  for i := 0 to PacketCount - 1 do
  begin
    Packets[i]:=TwxdPacket.Create;
    try
      Result:=Result and TaskPacket.GetPacketGoods('DatasetPacket_'+AnsiString(inttostr(i)),Packets[i]);
    except
      on e: exception do
      begin
        Result:=false;
        ErrorCode:='0212505';
        ErrorText:='提交的数据集无效: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
        NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
        NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
    end;
  end;
  if not Result then
  begin
    for i := 0 to PacketCount - 1 do
    begin
     if assigned(Packets[i]) then
        FreeAndNil(Packets[i]);
    end;
    setlength(Packets,0);
    exit;
  end;
  try
    SysDataset:=TUniQuery.Create(nil);
    SysDataset.DisableControls;
    SysDataset.Connection:=SysConn;
    SysDataset.Options.EnableBCD:=EnableBCD;
    SysCommand:=TUniSQL.Create(nil);
    SysCommand.Connection:=SysConn;
    Cds:=TClientDataset.Create(nil);
    Cds.DisableControls;
    Result:=true;
    for i:=0 to PacketCount - 1 do
    begin
      TableName:=Packets[i].GetStringGoods('TableName');
      ClearSql:=Packets[i].GetStringGoods('ClearSQL');
      Cds.Close;
      Result:=(trim(TableName)<>'') and GetCdsFromPacket(Packets[i],'DatasetBody',Cds);

      if not Result then
      begin
        ErrorCode:='0212504';
        ErrorText:='提交的数据集无效....';
        break;
      end;
      if trim(ClearSQL)<>'' then
      begin
        SysCommand.SQL.Text:=ClearSQL;
        SysCommand.Execute;
      end;
      SysDataset.SQL.Text:='SELECT * FROM '+TableName+' WHERE 1=2';
      SysDataset.Active:=true;
      Result:=CdsWriteToUniQuery(Cds,SysDataset,Err);
      SysDataset.Active:=false;
      if not Result then
      begin
        ErrorCode:='0212503';
        ErrorText:=AnsiString(Err);
        break;
      end;
    end;
  except
    on e: exception do
    begin
      Result:=false;
      ErrorCode:='0212502';
      ErrorText:='将数据集(dataset)转换至表失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
    end;
  end;
  SafeFreeUniData(SysDataset);
  if assigned(SysCommand) then
    FreeAndNil(SysCommand);
  if assigned(Cds) then
    FreeAndNil(Cds);

  for i := 0 to PacketCount - 1 do
    if assigned(Packets[i]) then
      FreeAndNil(Packets[i]);
  setlength(Packets,0);
end;

procedure TTaskThread.Task_UpdateDataset;
var
  DatabaseId: ansistring;
  divchar,TableName,KeyFieldList,Condition,err: string;
  EnableBCD,ok: boolean;
  SysDataset: TUniQuery;
  Cds: TClientDataset;
  SysConn: TuniConnection;
  PoolId,ConnectionId,i,j: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  TableName:=RequestPacket.GetStringGoods('TableName');
  Condition:=RequestPacket.GetStringGoods('Condition');
  KeyFieldList:=RequestPacket.GetStringGoods('KeyFieldList');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  Cds:=TClientDataset.Create(nil);
  Cds.DisableControls;
  ok:=GetCdsFromPacket(RequestPacket,'Dataset',Cds);
  if not ok then
    FreeAndNil(Cds);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      if pos(AnsiString(';'),KeyFieldList)>0 then
        divchar:=';'
      else
        divchar:=',';
      if copy(keyfieldlist,length(keyfieldlist),1)<>divchar then
        keyfieldlist:=keyfieldlist+divchar;
      KeyFieldCount:=0;
      SetLength(KeyFields,0);
      j:=pos(divchar,KeyFieldList);
      while j>0 do
      begin
         i:=keyfieldcount;
         inc(keyfieldcount);
         setlength(keyfields,keyfieldcount);
         keyfields[i]:=copy(KeyFieldList,1,j-1);
         delete(KeyFieldList,1,j);
         j:=pos(divchar,KeyFieldList);
      end;
      try
        SysDataset:=TUniQuery.Create(nil);
        SysDataset.Options.EnableBCD:=EnableBCD;
        SysDataset.DisableControls;
        SysDataset.Connection:=SysConn;
        if condition='' then
           SysDataset.SQL.Text:='SELECT * FROM '+string(tablename)
        else
           SysDataset.SQL.Text:='SELECT * FROM '+string(tablename)+' WHERE '+condition;
        SysDataset.Active:=true;
        ok:=true;
        SysConn.StartTransaction;

        sysdataset.First;
        while not sysdataset.Eof do
        begin
          Condition:='';
          for i := 0 to KeyFieldCount-1 do
          begin
            if condition<>'' then
               condition:=condition+' AND ';
            condition:=condition+keyfields[i]+'=';
            if (sysdataset.FindField(keyfields[i]).DataType=ftString)
            or (sysdataset.FindField(keyfields[i]).DataType=ftWideString)
            or (sysdataset.FindField(keyfields[i]).DataType=ftFixedChar)
            {$IFDEF UNICODE}
            or (sysdataset.FindField(keyfields[i]).DataType=ftFixedWideChar)
            or (sysdataset.FindField(keyfields[i]).DataType=ftWideMemo)
            {$ENDIF}
            or (sysdataset.FindField(keyfields[i]).DataType=ftMemo)
            or (sysdataset.FindField(keyfields[i]).DataType=ftDateTime)
            or (sysdataset.FindField(keyfields[i]).DataType=ftTime)
            or (sysdataset.FindField(keyfields[i]).DataType=ftDate)
            or (sysdataset.FindField(keyfields[i]).DataType=ftGuid) then
               condition:=condition+quotedstr(trim(sysdataset.FieldByName(keyfields[i]).AsString))
            else
               condition:=condition+trim(sysdataset.FieldByName(keyfields[i]).AsString);
          end;
          Cds.Filter:=condition;
          try
            Cds.Filtered:=true;
          except
            on e:exception do
            begin
              ok:=false;
              err:='['+e.ClassName+']-'+e.Message;
            end;
          end;
          if not ok then
          begin
            ErrorCode:='0214505';
            ErrorText:=AnsiString(err);
            break;
          end;
          if Cds.RecordCount=0 then
             SysDataset.Delete
          else
             SysDataset.Next;
        end;
        if ok then
        begin
          Cds.Filtered:=false;
          Cds.First;
          while not Cds.Eof do
          begin
            Condition:='';
            for i := 0 to KeyFieldCount-1 do
            begin
              if condition<>'' then
                 condition:=condition+' AND ';
              condition:=condition+keyfields[i]+'=';
              if (Cds.FindField(keyfields[i]).DataType=ftString)
              or (Cds.FindField(keyfields[i]).DataType=ftWideString)
              or (Cds.FindField(keyfields[i]).DataType=ftFixedChar)
              {$IFDEF UNICODE}
              or (Cds.FindField(keyfields[i]).DataType=ftFixedWideChar)
              or (Cds.FindField(keyfields[i]).DataType=ftWideMemo)
              {$ENDIF}
              or (Cds.FindField(keyfields[i]).DataType=ftMemo)
              or (Cds.FindField(keyfields[i]).DataType=ftDateTime)
              or (Cds.FindField(keyfields[i]).DataType=ftTime)
              or (Cds.FindField(keyfields[i]).DataType=ftDate)
              or (Cds.FindField(keyfields[i]).DataType=ftGuid) then
                 condition:=condition+quotedstr(trim(Cds.FieldByName(keyfields[i]).AsString))
              else
                 condition:=condition+trim(Cds.FieldByName(keyfields[i]).AsString);
            end;
            sysdataset.Filter:=condition;
            try
              sysdataset.Filtered:=true;
            except
              on e:exception do
              begin
                ok:=false;
                err:='['+e.ClassName+']-'+e.Message;
              end;
            end;
            if ok then
              ok := CdsRecordUpdateToUniQuery(Cds,SysDataset,err);
            if not ok then
            begin
              ErrorCode:='0214505';
              ErrorText:=AnsiString(err);
              break;
            end;
            Cds.Next;
          end;
        end;

        if ok then
           SysConn.Commit
        else
           SysConn.Rollback;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0214503';
          ErrorText:='打开数据集失败: ['+AnsiString(e.ClassName)+']-'+AnsiString(e.Message);
          try
            if SysConn.InTransaction then
              SysConn.Rollback;
          except
          end;
        end;
      end;
      SafeFreeUniData(SysDataset);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0214502';
       ErrorText:='Allocate ADO connection failed.';
    end;
    FreeAndNil(Cds);
  end
  else
  begin
    ErrorCode:='0214501';
    ErrorText:='无效参数。';
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(TableName)+#13#10+AnsiString(KeyFieldList)+#13#10+AnsiString(Condition));
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02145: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_UpdateDataset(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  divchar,TableName,KeyFieldList,Condition,Err: string;
  SysDataset,AdoDs: TUniQuery;
  Cds: TClientDataset;
  EnableBCD: boolean;
  i,j: integer;
begin
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  TableName:=TaskPacket.GetStringGoods('TableName');
  Condition:=TaskPacket.GetStringGoods('Condition');
  KeyFieldList:=TaskPacket.GetStringGoods('KeyFieldList');
  Cds:=TClientDataset.Create(nil);
  Cds.DisableControls;
  Result:=GetCdsFromPacket(TaskPacket,'Dataset',Cds);
  if not Result then
    FreeAndNil(Cds);

  if Result then
  begin
    if pos(AnsiString(';'),KeyFieldList)>0 then
      divchar:=';'
    else
      divchar:=',';
    if copy(keyfieldlist,length(keyfieldlist),1)<>divchar then
      keyfieldlist:=keyfieldlist+divchar;
    KeyFieldCount:=0;
    SetLength(KeyFields,0);
    j:=pos(divchar,KeyFieldList);
    while j>0 do
    begin
      i:=keyfieldcount;
      inc(keyfieldcount);
      setlength(keyfields,keyfieldcount);
      keyfields[i]:=copy(KeyFieldList,1,j-1);
      delete(KeyFieldList,1,j);
      j:=pos(divchar,KeyFieldList);
    end;
    try
      SysDataset:=TUniQuery.Create(nil);
      SysDataset.Options.EnableBCD:=EnableBCD;
      SysDataset.DisableControls;
      SysDataset.Connection:=SysConn;
      if condition='' then
         SysDataset.SQL.Text:='SELECT * FROM '+string(tablename)
      else
         SysDataset.SQL.Text:='SELECT * FROM '+string(tablename)+' WHERE '+condition;
      SysDataset.Active:=true;
      result:=true;

      SysDataset.First;
      while not SysDataset.Eof do
      begin
        Condition:='';
        for i := 0 to KeyFieldCount-1 do
        begin
          if condition<>'' then
             condition:=condition+' AND ';
          condition:=condition+keyfields[i]+'=';
          if (SysDataset.FindField(keyfields[i]).DataType=ftString)
          or (SysDataset.FindField(keyfields[i]).DataType=ftWideString)
          or (SysDataset.FindField(keyfields[i]).DataType=ftFixedChar)
          {$IFDEF UNICODE}
          or (SysDataset.FindField(keyfields[i]).DataType=ftFixedWideChar)
          or (SysDataset.FindField(keyfields[i]).DataType=ftWideMemo)
          {$ENDIF}
          or (SysDataset.FindField(keyfields[i]).DataType=ftMemo)
          or (SysDataset.FindField(keyfields[i]).DataType=ftDateTime)
          or (SysDataset.FindField(keyfields[i]).DataType=ftTime)
          or (SysDataset.FindField(keyfields[i]).DataType=ftDate)
          or (SysDataset.FindField(keyfields[i]).DataType=ftGuid) then
             condition:=condition+quotedstr(trim(SysDataset.FieldByName(keyfields[i]).AsString))
          else
             condition:=condition+trim(SysDataset.FieldByName(keyfields[i]).AsString);
        end;
        Cds.Filter:=condition;
        try
           Cds.Filtered:=true;
        except
          on e:exception do
          begin
             result:=false;
             err:='['+e.classname+']-'+e.message;
          end;
        end;
        if not result then
        begin
          ErrorCode:='0214505';
          ErrorText:=AnsiString(err);
          break;
        end;
        if Cds.RecordCount=0 then
           SysDataset.Delete
        else
           SysDataset.Next;
      end;

      if result then
      begin
        Cds.Filtered:=false;
        Cds.First;
        while not Cds.Eof do
        begin
          Condition:='';
          for i := 0 to KeyFieldCount-1 do
          begin
            if condition<>'' then
               condition:=condition+' AND ';
            condition:=condition+keyfields[i]+'=';
            if (Cds.FindField(keyfields[i]).DataType=ftString)
            or (Cds.FindField(keyfields[i]).DataType=ftWideString)
            or (Cds.FindField(keyfields[i]).DataType=ftFixedChar)
            {$IFDEF UNICODE}
            or (Cds.FindField(keyfields[i]).DataType=ftFixedWideChar)
            or (Cds.FindField(keyfields[i]).DataType=ftWideMemo)
            {$ENDIF}
            or (Cds.FindField(keyfields[i]).DataType=ftMemo)
            or (Cds.FindField(keyfields[i]).DataType=ftDateTime)
            or (Cds.FindField(keyfields[i]).DataType=ftTime)
            or (Cds.FindField(keyfields[i]).DataType=ftDate)
            or (Cds.FindField(keyfields[i]).DataType=ftGuid) then
               condition:=condition+quotedstr(trim(Cds.FieldByName(keyfields[i]).AsString))
            else
               condition:=condition+trim(Cds.FieldByName(keyfields[i]).AsString);
          end;
          sysdataset.Filter:=condition;
          try
             sysdataset.Filtered:=true;
          except
            on e:exception do
            begin
               result:=false;
               err:='['+e.classname+']-'+e.message;
            end;
          end;
          if result then
             result:=CdsRecordUpdateToUniQuery(Cds,SysDataset,Err);
          if not result then
          begin
            ErrorCode:='0214505';
            ErrorText:=AnsiString(err);
            break;
          end;
          Cds.Next;
        end;
      end;
    except
      on e: exception do
      begin
        result:=false;
        ErrorCode:='0214503';
        ErrorText:='打开源数据集失败: ['+AnsiString(e.ClassName)+']-'+AnsiString(e.Message);
      end;
    end;
    SafeFreeUniData(SysDataset);
    FreeAndNil(Cds);
  end
  else
  begin
    ErrorCode:='0214501';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_CommitSqlDelta;
var
  ok: boolean;
  j: integer;
  DatabaseId: AnsiString;
  SqlCommand: string;
  EnableBCD: boolean;
  SysConn: TuniConnection;
  PoolId,ConnectionId: integer;
  SysQuery: TUniQuery;
  Dsp: TDatasetProvider;
  Stream: TMemoryStream;
  DeltaData: OleVariant;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=RequestPacket.GetStringGoods('SQLCommand');
  EnableBCD:=RequestPacket.GetBooleanGoods('EnableBCD');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if RequestPacket.GoodsExists('DeltaData') then
  begin
    Stream:=TMemoryStream.Create;
    ok:=RequestPacket.GetStreamGoods('DeltaData',Stream);
    if ok then
    begin
      Stream.Position:=0;
      ok:=StreamToVariant(Stream,DeltaData);
      if ok then
        ok:=not (VarIsNull(DeltaData) or VarIsEmpty(DeltaData));

    end;
    FreeAndNil(Stream);
  end
  else
  ok:=false;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok and (j<>-1) then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
      try
        SysConn.StartTransaction;
        SysQuery:=TUniQuery.Create(nil);
        Dsp:=TDatasetProvider.Create(nil);
        SysQuery.Connection:=SysConn;
        SysQuery.Options.enableBCD:=EnableBCD;
        SysQuery.DisableControls;
        Dsp.DataSet:=SysQuery;
        SysQuery.SQL.Text:=SqlCommand;
        dsp.ApplyUpdates(DeltaData,0,j);
        ok:=(j=0);
        if not ok then
        begin
          ErrorCode:='0215705';
          ErrorText:='提交数据到数据库失败 ('+AnsiString(inttostr(j))+' errors).';
        end
        else
           SysConn.Commit;
      except
        on e: exception do
        begin
          ok:=false;
          ErrorCode:='0215703';
          ErrorText:='['+ansistring(e.classname)+']-'+ansistring(e.message);
        end;
      end;
      if not ok then
      begin
        try
           if SysConn.InTransaction then
              SysConn.Rollback;
        except
        end;
      end;
      if Assigned(Dsp) then
        FreeAndNil(Dsp);
      if assigned(SysQuery) then
        FreeAndNil(SysQuery);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0215702';
       ErrorText:='分配数据库连接失败。';
    end;
    DeltaData:=null;
  end
  else
  begin
    ErrorCode:='0215701';
    ErrorText:='无效参数。';
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+AnsiString(SqlCommand));
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02157: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

function TTaskThread.Item_CommitSqlDelta(const TaskPacket: TwxdPacket; const SysConn: TUniConnection; var RetValue: AnsiString): boolean;
var
  j: integer;
  DatabaseId: AnsiString;
  SqlCommand: string;
  EnableBCD: boolean;
  SysQuery: TuniQuery;
  Dsp: TDatasetProvider;
  Stream: TMemoryStream;
  DeltaData: OleVariant;
begin
  DatabaseId:=TaskPacket.GetEncryptStringGoods('DatabaseId');
  SqlCommand:=TaskPacket.GetStringGoods('SQLCommand');
  EnableBCD:=TaskPacket.GetBooleanGoods('EnableBCD');
  if TaskPacket.GoodsExists('IsolationLevel') then
    j:=TaskPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if TaskPacket.GoodsExists('DeltaData') then
  begin
    Stream:=TMemoryStream.Create;
    result:=TaskPacket.GetStreamGoods('DeltaData',Stream);
    if result then
    begin
       Stream.Position:=0;
       result:=StreamToVariant(Stream,DeltaData);
       if result then
          result:=not (VarIsNull(DeltaData) or VarIsEmpty(DeltaData));
    end;
    FreeAndNil(Stream);
  end
  else
  result:=false;
  if result then
  begin
    try
      SysQuery:=TUniQuery.Create(nil);
      SysQuery.Connection:=SysConn;
      SysQuery.Options.enableBCD:=EnableBCD;
      SysQuery.DisableControls;
      Dsp:=TDatasetProvider.Create(nil);
      Dsp.DataSet:=SysQuery;
      try
        SysQuery.SQL.Text:=SqlCommand;
        dsp.ApplyUpdates(DeltaData,0,j);
        result:=(j=0);
        if not result then
        begin
           ErrorCode:='0215705';
           ErrorText:='数据提交至数据库失败。';
        end;
      except
         on e: exception do
            begin
               result:=false;
               ErrorCode:='0215704';
               ErrorText:='['+ansistring(e.classname)+']-'+ansistring(e.message);
            end;
      end;
    except
      on e: exception do
      begin
        result:=false;
        ErrorCode:='0215703';
        ErrorText:='['+ansistring(e.classname)+']-'+ansistring(e.message);
      end;
    end;
    if assigned(SysQuery) then
      FreeAndNil(SysQuery);
    if Assigned(Dsp) then
      FreeAndNil(Dsp);
    DeltaData:=null;
  end
  else
  begin
    ErrorCode:='0215701';
    ErrorText:='无效参数。';
  end;
  RetValue:='';
end;

procedure TTaskThread.Task_ReadSysParameters;
var
   Packet: TwxdPacket;
begin
   Packet:=TwxdPacket.Create;
   BackPacket.EncryptKey:=NodeService.s_TransferKey;
   try
      BackPacket.PutBooleanGoods('ProcessResult',true);
      Packet.putStringGoods('DefaultDir',NodeService.s_DefaultDir);
      Packet.putStringGoods('SelfFileName',NodeService.s_SelfFileName);
      Packet.putStringGoods('ServiceName',string(NodeService.s_ServiceName));
      Packet.putStringGoods('DisplayName',string(NodeService.s_DisplayName));
      Packet.putStringGoods('ServiceDesc',string(NodeService.s_ServiceDesc));
      Packet.putIntegerGoods('RequestTimeout',NodeService.s_RequestTimeout);
      Packet.putIntegerGoods('HeartbeatSeconds',NodeService.s_HeartbeatSeconds);
      Packet.putIntegerGoods('MaxRequestLength',NodeService.s_MaxRequestLength);
      Packet.putIntegerGoods('MaxUsersAllowed',NodeService.s_MaxUsersAllowed);
      Packet.putIntegerGoods('BackupDays',NodeService.s_BackupDays);
      Packet.PutBooleanGoods('SaveU2UMessages',NodeService.s_SaveU2UMessages);
      Packet.PutBooleanGoods('SaveBroadcastMessages',NodeService.s_SaveBroadcastMessages);
      Packet.putIntegerGoods('WebPort',NodeService.s_WebPort);
      Packet.PutBooleanGoods('WebServiceEnabled',NodeService.s_WebServiceEnabled);
      Packet.putStringGoods('WebHomeDir',NodeService.s_WebHomeDir);
      Packet.putStringGoods('WebDefaultFilename',NodeService.s_WebDefaultFilename);
      Packet.putStringGoods('WebDynamicPageExt',string(NodeService.s_WebDynamicPageExt));
      Packet.PutBooleanGoods('WebGZipEnabled',NodeService.s_WebGZipEnabled);
      Packet.PutBooleanGoods('WebStaticGZipEnabled',NodeService.s_WebStaticGZipEnabled);
      Packet.putIntegerGoods('WebMaxRequestHeader',NodeService.s_WebMaxRequestHeader);
      Packet.putIntegerGoods('WebMaxRequestData',NodeService.s_WebMaxRequestData);
      Packet.putIntegerGoods('WebRequestTimeout',NodeService.s_WebRequestTimeout);
      Packet.PutBooleanGoods('FileCacheEnabled',NodeService.s_FileCacheEnabled);
      Packet.putIntegerGoods('FileCacheSize',NodeService.s_FileCacheSize);
      Packet.putIntegerGoods('FileSizeThreshold',NodeService.s_FileSizeThreshold);
      Packet.putIntegerGoods('FileAliveMinutes',NodeService.s_FileAliveMinutes);
      Packet.PutBooleanGoods('WebSocketEnabled',NodeService.s_WebSocketEnabled);
      Packet.putIntegerGoods('WebSocketHeartbeat',NodeService.s_WebSocketHeartbeat);
      Packet.PutBooleanGoods('LoadBalanceEnabled',NodeService.s_LoadBalanceEnabled);
      Packet.PutBooleanGoods('WebDispatchEnabled',NodeService.s_WebDispatchEnabled);
      Packet.putStringGoods('BalanceAddress',string(NodeService.s_BalanceAddress));
      Packet.putIntegerGoods('BalancePort',NodeService.s_BalancePort);
      Packet.PutRealGoods('ThisNodeFactor',NodeService.s_ThisNodeFactor);
      BackPacket.PutPacketGoods('Parameters',Packet);
   except
      on e: exception do
         NodeService.syslog.Log('Err02126: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   FreeAndNil(Packet);
end;

procedure TTaskThread.Task_CommitBatchTasks;
var
  ok: boolean;
  DatabaseId,RetValue: AnsiString;
  SysConn: TuniConnection;
  PoolId,ConnectionId,TaskCount,i,TaskId,j: integer;
  TaskPacket,ItemPacket: TwxdPacket;
  RetValueList: TStringList;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TaskCount:=RequestPacket.GetIntegerGoods('TaskCount');
  if RequestPacket.GoodsExists('IsolationLevel') then
    j:=RequestPacket.GetIntegerGoods('IsolationLevel')
  else
    j:=-1;
  if RequestPacket.GoodsExists('BatchTasks') then
  begin
    TaskPacket:=TwxdPacket.Create;
    ok:=GetPacketFromPacket(RequestPacket,'BatchTasks',TaskPacket);
    if ok then
      ok:=(integer(TaskPacket.GoodsCount)=TaskCount);
    if not ok then
    begin
       FreeAndNil(TaskPacket);
       ErrorCode:='0212801';
       ErrorText:='Load merged tasks from Packet failed.';
    end;
  end
  else
  begin
    TaskPacket:=nil;
    ok:=false;
    ErrorCode:='0212801';
    ErrorText:='Merged tasks not found.';
  end;
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok then
      ok:=SetIsoLevel(SysConn,j);
    if ok then
    begin
  　　ItemPacket:=TwxdPacket.Create;
  　　RetValueList:=TStringList.Create;
  　　try
        SysConn.StartTransaction;
        ok:=true;
  　　except
     　 on e: exception do
        begin
          ErrorCode:='0212804';
          ErrorText:='数据库事务启动失败: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
          ok:=false;
        end;
   　 end;
      if ok then
    　begin
        for i:=0 to TaskCount-1 do
        begin
          ok:=TaskPacket.GetPacketGoods('Task'+AnsiString(inttostr(i+1)),ItemPacket);
          if not ok then
          begin
             ErrorCode:='0212803';
             ErrorText:='Get task'+AnsiString(inttostr(i+1))+' failed.';
             break;
          end;
          TaskId:=ItemPacket.GetIntegerGoods('TaskId');
          try
            case TaskId of
               54: ok:=Item_ExecSql(ItemPacket,SysConn,RetValue);
               107: ok:=Item_ExecCommand(ItemPacket,SysConn,RetValue);
               55: ok:=Item_ExecBatchSQL(ItemPacket,SysConn,RetValue);
               56: ok:=Item_ExecStoreProc(ItemPacket,SysConn,RetValue);
               57: ok:=Item_FileToBlob(ItemPacket,SysConn,RetValue);
               60: ok:=Item_FileToTable(ItemPacket,SysConn,RetValue);
               62: ok:=Item_WriteDataset(ItemPacket,SysConn,RetValue);
               63: ok:=Item_AppendRecord(ItemPacket,SysConn,RetValue);
               64: ok:=Item_UpdateRecord(ItemPacket,SysConn,RetValue);
               68: ok:=Item_SaveDelta(ItemPacket,SysConn,RetValue);
               81: ok:=Item_ClearBlob(ItemPacket,SysConn,RetValue);
               106: ok:=Item_StreamToBlob(ItemPacket,SysConn,RetValue);
               125: ok:=Item_WriteMultiDataset(ItemPacket,SysConn,RetValue);
               145: ok:=Item_UpdateDataset(ItemPacket,SysConn,RetValue);
               157: ok:=Item_CommitSqlDelta(ItemPacket,SysConn,RetValue);
            end;
          except
            on e: exception do
               begin
                  ErrorCode:='0212805';
                  ErrorText:='exception detected on commit merged tasks: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
                  ok:=false;
               end;
          end;
          if not ok then
          begin
             NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
             break;
          end;
          RetValueList.Add(string(RetValue));
        end;
        if ok then
        begin
          try
            sysconn.Commit;
          except
            on e: exception do
            begin
              try
                 if sysconn.InTransaction then
                    sysconn.Rollback;
              except
              end;
              ErrorCode:='0212807';
              ErrorText:='exception on commit mergetask: ['+ansistring(e.ClassName)+']-'+ansistring(e.Message);
              ok:=false;
            end;
          end;
        end
        else
        begin
          try
            if sysconn.InTransaction then
               sysconn.Rollback;
          except
          end;
        end;
    　end;
       if ok and (RetValueList.Count>0) then
         try
           BackPacket.PutStringGoods('RetValueList',RetValueList.Text);
         except
           ok:=false;
         end;
       FreeAndNil(ItemPacket);
       FreeAndNil(RetValueList);
       NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0212802';
       ErrorText:='分配数据库连接失败。';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId);
    end;
    FreeAndNil(TaskPacket);
  end
  else
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02128: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

procedure TTaskThread.Task_SendToWebSession;
var
   TargetSessionId: ansistring;
   MsgPacket: TwxdPacket;
   ok: boolean;
   MainIndex,j: integer;
begin
   TargetSessionId:=RequestPacket.GetAnsiStringGoods('TargetSessionId');
   MsgPacket:=TwxdPacket.create;
   ok:=RequestPacket.GetPacketGoods('MessageBody',MsgPacket);
   if ok then
      begin
         EnterCriticalSection(NodeService.WebSessionListCs);
         try
            MainIndex:=FindWebSessionInSessionId(PAnsiChar(TargetSessionId));
            ok:=(MainIndex<>-1);
            if ok then
               begin
                  j:=NodeService.WebSessions[MainIndex].MsgCount;
                  inc(NodeService.WebSessions[MainIndex].MsgCount);
                  SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                  NodeService.WebSessions[MainIndex].Msgs[j]:=MsgPacket;
               end
            else
               begin
                  ErrorCode:='0213302';
                  ErrorText:='Web session not found.';
                  FreeAndNil(MsgPacket);
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.WebSessionListCs);
      end
   else
      begin
         ErrorCode:='0213301';
         ErrorText:='无效参数...';
         FreeAndNil(MsgPacket);
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02133: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToAllWebSessions;
var
   Stream: TMemoryStream;
   ok: boolean;
   i,j: integer;
begin
   Stream:=nil;
   try
      Stream:=TMemoryStream.create;
      ok:=RequestPacket.GetStreamGoods('MessageBody',Stream);
   except
      ok:=false;
   end;
   if ok then
      begin
         EnterCriticalSection(NodeService.WebSessionListCs);
         try
            ok:=true;
            for i := 0 to NodeService.WebSessionCount-1 do
               begin
                  if not NodeService.WebSessions[i].used then
                     continue;
                  j:=NodeService.WebSessions[i].MsgCount;
                  inc(NodeService.WebSessions[i].MsgCount);
                  SetLength(NodeService.WebSessions[i].Msgs,NodeService.WebSessions[i].MsgCount);
                  NodeService.WebSessions[i].Msgs[j]:=TwxdPacket.create;
                  Stream.position:=0;
                  try
                     ok:=NodeService.WebSessions[i].Msgs[j].loadfromstream(stream);
                  except
                     ok:=false;
                  end;
                  if not ok then
                     begin
                        FreeAndNil(NodeService.WebSessions[i].Msgs[j]);
                        dec(NodeService.WebSessions[i].MsgCount);
                        SetLength(NodeService.WebSessions[i].Msgs,NodeService.WebSessions[i].MsgCount);
                        ErrorCode:='0213402';
                        ErrorText:='Load message package failed.';
                        break;
                     end;
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.WebSessionListCs);
      end
   else
      begin
         ErrorCode:='0213401';
         ErrorText:='无效参数...';
      end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02133: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToStrPropWebSessions;
var
   Stream: TMemoryStream;
   ok: boolean;
   PropIndex,MainIndex,i,j: integer;
   TargetStrProp: ansistring;
begin
   Stream:=nil;
   try
      Stream:=TMemoryStream.create;
      ok:=RequestPacket.GetStreamGoods('MessageBody',Stream);
      TargetStrProp:=RequestPacket.GetAnsiStringGoods('StrProp');
   except
      ok:=false;
   end;
   if ok then
      begin
         EnterCriticalSection(NodeService.WebSessionListCs);
         try
            PropIndex:=CallbackProcs.FindWebSessionInStrProp(PAnsiChar(TargetStrProp));
            ok:=(PropIndex<>-1);
            if ok then
               begin
                  for i := PropIndex to NodeService.WebStrPropIndexCount-1 do
                     begin
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.WebStrPropIndexes[i].StrProp,PAnsiChar(TargetStrProp))<>0 then
                           break;
                        MainIndex:=NodeService.WebStrPropIndexes[i].mainindex;
                        j:=NodeService.WebSessions[MainIndex].MsgCount;
                        inc(NodeService.WebSessions[MainIndex].MsgCount);
                        SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                        NodeService.WebSessions[MainIndex].Msgs[j]:=TwxdPacket.create;
                        Stream.position:=0;
                        try
                           ok:=NodeService.WebSessions[MainIndex].Msgs[j].loadfromstream(stream);
                        except
                           ok:=false;
                        end;
                        if not ok then
                           begin
                              FreeAndNil(NodeService.WebSessions[MainIndex].Msgs[j]);
                              dec(NodeService.WebSessions[MainIndex].MsgCount);
                              SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                              ErrorCode:='0213503';
                              ErrorText:='Load message package failed.';
                              break;
                           end;
                     end;
               end
            else
               begin
                  ErrorCode:='0213502';
                  ErrorText:='No sessions matched.';
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.WebSessionListCs);
      end
   else
      begin
         ErrorCode:='0213501';
         ErrorText:='无效参数...';
      end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02133: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToIntPropWebSessions;
var
   Stream: TMemoryStream;
   ok: boolean;
   PropIndex,MainIndex,i,j,TargetIntProp: integer;
begin
   Stream:=nil;
   try
      Stream:=TMemoryStream.create;
      ok:=RequestPacket.GetStreamGoods('MessageBody',Stream);
      TargetIntProp:=RequestPacket.GetIntegerGoods('IntProp');
   except
      ok:=false;
   end;
   if ok then
      begin
         EnterCriticalSection(NodeService.WebSessionListCs);
         try
            PropIndex:=FindWebSessionInIntProp(TargetIntProp);
            ok:=(PropIndex<>-1);
            if ok then
               begin
                  for i := PropIndex to NodeService.WebIntPropIndexCount-1 do
                     begin
                        if NodeService.WebIntPropIndexes[i].IntProp<>TargetIntProp then
                           break;
                        MainIndex:=NodeService.WebIntPropIndexes[i].mainindex;
                        j:=NodeService.WebSessions[MainIndex].MsgCount;
                        inc(NodeService.WebSessions[MainIndex].MsgCount);
                        SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                        NodeService.WebSessions[MainIndex].Msgs[j]:=TwxdPacket.create;
                        Stream.position:=0;
                        try
                           ok:=NodeService.WebSessions[MainIndex].Msgs[j].loadfromstream(stream);
                        except
                           ok:=false;
                        end;
                        if not ok then
                           begin
                              FreeAndNil(NodeService.WebSessions[MainIndex].Msgs[j]);
                              dec(NodeService.WebSessions[MainIndex].MsgCount);
                              SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                              ErrorCode:='0213603';
                              ErrorText:='Load message package failed.';
                              break;
                           end;
                     end;
               end
            else
               begin
                  ErrorCode:='0213602';
                  ErrorText:='No sessions matched.';
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.WebSessionListCs);
      end
   else
      begin
         ErrorCode:='0213601';
         ErrorText:='无效参数...';
      end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02133: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_SendToRoleIdWebSessions;
var
   Stream: TMemoryStream;
   ok: boolean;
   PropIndex,MainIndex,i,j: integer;
   TargetRoleId: ansistring;
begin
   Stream:=nil;
   try
      Stream:=TMemoryStream.create;
      ok:=RequestPacket.GetStreamGoods('MessageBody',Stream);
      TargetRoleId:=RequestPacket.GetAnsiStringGoods('RoleId');
   except
      ok:=false;
   end;
   if ok then
      begin
         EnterCriticalSection(NodeService.WebSessionListCs);
         try
            PropIndex:=CallbackProcs.FindWebSessionInRoleId(PAnsiChar(TargetRoleId));
            ok:=(PropIndex<>-1);
            if ok then
               begin
                  for i := PropIndex to NodeService.WebRoleIdIndexCount-1 do
                     begin
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.WebRoleIdIndexes[i].RoleId,PAnsiChar(TargetRoleId))<>0 then
                           break;
                        MainIndex:=NodeService.WebRoleIdIndexes[i].mainindex;
                        j:=NodeService.WebSessions[MainIndex].MsgCount;
                        inc(NodeService.WebSessions[MainIndex].MsgCount);
                        SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                        NodeService.WebSessions[MainIndex].Msgs[j]:=TwxdPacket.create;
                        Stream.position:=0;
                        try
                           ok:=NodeService.WebSessions[MainIndex].Msgs[j].loadfromstream(stream);
                        except
                           ok:=false;
                        end;
                        if not ok then
                           begin
                              FreeAndNil(NodeService.WebSessions[MainIndex].Msgs[j]);
                              dec(NodeService.WebSessions[MainIndex].MsgCount);
                              SetLength(NodeService.WebSessions[MainIndex].Msgs,NodeService.WebSessions[MainIndex].MsgCount);
                              ErrorCode:='0215503';
                              ErrorText:='Load message package failed.';
                              break;
                           end;
                     end;
               end
            else
               begin
                  ErrorCode:='0215502';
                  ErrorText:='No sessions matched.';
               end;
         except
            ok:=false;
         end;
         LeaveCriticalSection(NodeService.WebSessionListCs);
      end
   else
      begin
         ErrorCode:='0215501';
         ErrorText:='无效参数...';
      end;
   if assigned(Stream) then
      FreeAndNil(Stream);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02155: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetServiceVersion;
var
   ver: ansistring;
begin
   try
      ver:=ansistring(GetFileVersion(application.exename));
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutAnsiStringGoods('Version',ver);
   except
      on e: exception do
         NodeService.syslog.Log('Err02137: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetServerDateTime;
begin
   try
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutDateTimeGoods('DateTime',now);
   except
      on e: exception do
         NodeService.syslog.Log('Err02138: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchAllConnections;
var
   ok: boolean;
   i: integer;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   ctype,err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='ConnectionType';
               DataType:=ftWideString;
               Size:=4;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='SocketHandle';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ConnectionId';
               DataType:=ftLargeInt;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientIpAddress';
               DataType:=ftWideString;
               Size:=15;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingIntProp';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingStrProp';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingRoleId';
               DataType:=ftWideString;
               Size:=8;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.ConnectionListCs);
   for i := 0 to NodeService.ConnectionCount - 1 do
      begin
         if not NodeService.Connections[i].used then
            continue;
         if NodeService.Connections[i].ConnectionType=2 then
            ctype:='Node'
         else
            ctype:='User';
         try
            Cds.AppendRecord([ctype,
                              NodeService.Connections[i].SocketHandle,
                              NodeService.Connections[i].ConnectionId,
                              NodeService.Connections[i].socket.remoteaddress,
                              NodeService.Connections[i].BindingIntProp,
                              string(copy(NodeService.Connections[i].BindingStrProp,1,64)),
                              string(copy(NodeService.Connections[i].BindingRoleId,1,8))
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate all connection list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.ConnectionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('ConnectionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0212101');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0212101-Compress list data failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02121: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_FetchTriggerList;
var
   ok: boolean;
   i: integer;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='TriggerMessage';
               DataType:=ftWideString;
               size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='TriggerDesc';
               DataType:=ftWideString;
               Size:=36;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='PluginFilename';
               DataType:=ftWideString;
               Size:=48;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.TriggerCs);
   for i := 0 to NodeService.TriggerCount - 1 do
      begin
         try
            Cds.AppendRecord([string(copy(NodeService.Triggers[i].TriggerMessage,1,32)),
                              string(copy(NodeService.Triggers[i].TriggerDesc,1,36)),
                              string(copy(NodeService.Triggers[i].TriggerPlugin,1,48))
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate trigger list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.TriggerCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('TriggerList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0214001');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0214001-Compress list data failed.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02140: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_RegisterTrigger;
var
   TriggerMessage,TriggerDesc,PluginFileName: ansistring;
   ok: boolean;
begin
   TriggerMessage:=RequestPacket.GetAnsiStringGoods('TriggerMessage');
   TriggerDesc:=RequestPacket.GetAnsiStringGoods('TriggerDesc');
   PluginFileName:=RequestPacket.GetAnsiStringGoods('PluginFileName');
   ok:=(TriggerMessage<>'') and (TriggerDesc<>'') and (PluginFileName<>'');
   if ok then
      ok:=NodeService.AddTrigger(TriggerMessage,TriggerDesc,PluginFileName);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02141: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_UnregisterTrigger;
var
   TriggerMessage: ansistring;
   ok: boolean;
begin
   TriggerMessage:=RequestPacket.GetAnsiStringGoods('TriggerMessage');
   ok:=(TriggerMessage<>'');
   if ok then
      ok:=NodeService.RemoveTrigger(TriggerMessage);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02142: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FireTrigger;
var
   Msgs: TwxdWinMessages;
   TriggerMessage: ansistring;
   ok: boolean;
begin
   TriggerMessage:=RequestPacket.GetAnsiStringGoods('TriggerMessage');
   ok:=(TriggerMessage<>'');
   if ok then
      begin
         Msgs:=TwxdWinMessages.Create(nil);
         try
            Msgs.RegisterUserMessage(string(TriggerMessage));
            Msgs.PostUserMessage(string(TriggerMessage),integer(@nodeservice.ExportAddrList[0]),0);
         except
            ok:=false;
         end;
         Msgs.RemoveUserMessage(string(TriggerMessage));
         FreeAndNil(Msgs);
      end;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02143: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchDeviceList;
var
   ok: boolean;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   err: string;
begin
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='DeviceId';
               DataType:=ftWideString;
               size:=32;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='DeviceType';
               DataType:=ftWideString;
               Size:=10;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='DeviceDesc';
               DataType:=ftWideString;
               Size:=48;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   NodeService.DeviceListToCds(Cds);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      BackPacket.PutBooleanGoods('VerificationEnabled',NodeService.s_EnableDeviceVerification);
      if ok then
         BackPacket.PutStreamGoods('DeviceList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0214601');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0214601-Compress list data failed.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02146: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_RegisterDevice;
var
   DeviceId,DeviceDesc,DeviceType: ansistring;
   ok: boolean;
begin
   DeviceId:=RequestPacket.GetAnsiStringGoods('DeviceId');
   DeviceDesc:=RequestPacket.GetAnsiStringGoods('DeviceDesc');
   DeviceType:=RequestPacket.GetAnsiStringGoods('DeviceType');
   ok:=(DeviceId<>'') and (DeviceType<>'');
   if ok then
      ok:=NodeService.AddDevice(DeviceId,DeviceType,DeviceDesc);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02147: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_UnregisterDevice;
var
   DeviceId: ansistring;
   ok: boolean;
begin
   DeviceId:=RequestPacket.GetAnsiStringGoods('DeviceId');
   ok:=(DeviceId<>'');
   if ok then
      ok:=NodeService.RemoveDevice(DeviceId);
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
   except
      on e: exception do
         NodeService.syslog.Log('Err02148: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_VerificationDevice;
var
   DeviceId: ansistring;
   ok,valid: boolean;
begin
   DeviceId:=RequestPacket.GetAnsiStringGoods('DeviceId');
   ok:=(DeviceId<>'');
   if ok then
      valid:=NodeService.IsValidDevice(DeviceId)
   else
      valid:=false;
   try
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      BackPacket.PutBooleanGoods('IsValidDevice',valid);
   except
      on e: exception do
         NodeService.syslog.Log('Err02149: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_BindRoleId;
var
   ConnectionId: int64;
   MainIndex: integer;
   RoleId: AnsiString;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   RoleId:=RequestPacket.GetAnsiStringGoods('RoleId');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingRoleId='');
         if ok then
            begin
               try
                  NodeService.AddRoleIdIndex(RoleId,MainIndex);
               except
                  ok:=false;
                  ErrorCode:='0215003';
                  ErrorText:='Add to property array failed.';
               end;
            end
         else
            begin
               ErrorCode:='0215002';
               ErrorText:='RoleId has binded.';
            end;
      end
   else
      begin
         ErrorCode:='0215001';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02150: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_FetchRoleIdConnections;
var
   ok: boolean;
   MainIndex,i: integer;
   RoleId: AnsiString;
   Cds: TClientDataset;
   TargetStream: TMemoryStream;
   err: string;
begin
   RoleId:=RequestPacket.GetAnsiStringGoods('TargetRoleId');
   Cds:=TClientDataset.Create(nil);
   Cds.DisableControls;
   with Cds do
      begin
         with FieldDefs.AddFieldDef do
            begin
               Name:='ConnectionId';
               DataType:=ftLargeInt;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='ClientIpAddress';
               DataType:=ftWideString;
               Size:=15;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingIntProp';
               DataType:=ftInteger;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingStrProp';
               DataType:=ftWideString;
               Size:=64;
            end;
         with FieldDefs.AddFieldDef do
            begin
               Name:='BindingRoleId';
               DataType:=ftWideString;
               Size:=8;
            end;
         CreateDataSet;
      end;
   Cds.Open;
   EnterCriticalSection(NodeService.ConnectionListCs);
   for i := 0 to NodeService.RoleIdIndexCount - 1 do
      begin
         if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.RoleIdIndexes[i].RoleId,PAnsiChar(RoleId))<>0 then
            continue;
         MainIndex:=NodeService.RoleIdIndexes[i].MainIndex;
         try
            Cds.AppendRecord([NodeService.Connections[mainindex].ConnectionId,
                              NodeService.Connections[mainindex].socket.remoteaddress,
                              NodeService.Connections[mainindex].BindingIntProp,
                              string(copy(NodeService.Connections[mainindex].BindingStrProp,1,64)),
                              string(copy(NodeService.Connections[mainindex].BindingRoleId,1,8))
                             ]);
         except
            on e: exception do
               NodeService.syslog.Log('Error: Generate string property connection list error: ['+ansistring(e.classname)+']-'+ansistring(e.message));
         end;
      end;
   LeaveCriticalSection(NodeService.ConnectionListCs);
   TargetStream:=nil;
   try
      TargetStream:=TMemoryStream.Create;
      ok:=CdsZipToStream(Cds,TargetStream,err);
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if ok then
         BackPacket.PutStreamGoods('ConnectionList',TargetStream)
      else
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0215101');
            BackPacket.PutEncryptStringGoods('ErrorText','Compress list data failed: '+ansistring(err));
            NodeService.syslog.Log('Error: 0215101-Compress list data failed.');
            NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02151: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
   if assigned(TargetStream) then
      FreeAndNil(TargetStream);
   FreeAndNil(Cds);
end;

procedure TTaskThread.Task_SendToRoleIdConnections;
var
   ok: boolean;
   RoleId,FromUserId: AnsiString;
   Packet: TwxdPacket;
   MainIndex,i,StartIndex: integer;
begin
   FromUserId:=RequestPacket.GetEncryptStringGoods('FromUserId');
   RoleId:=RequestPacket.GetAnsiStringGoods('TargetRoleId');
   Packet:=TwxdPacket.Create;
   Packet.EncryptKey:=NodeService.s_TransferKey;
   ok:=RequestPacket.GetPacketGoods('MessageBody',Packet);
   if ok then
      begin
         try
            Packet.PutIntegerGoods('ResponseId',26);
            Packet.PutEncryptStringGoods('FromUserId',FromUserId);
            ok:=Packet.SaveToStringWithLength(ResponseBody);
         except
            ok:=false;
         end;
      end;
   if ok then
      begin
         EnterCriticalSection(NodeService.ConnectionListCs);
         try
            StartIndex:=NodeService.FindConnectionInRoleId2(RoleId);
            if StartIndex<>-1 then
               begin
                  for i := StartIndex to NodeService.RoleIdIndexCount - 1 do
                     begin
                        if {$IF CompilerVersion>=25.0}AnsiStrings.{$ENDIF}StrIComp(NodeService.RoleIdIndexes[i].RoleId,PAnsiChar(RoleId))=0 then
                           begin
                              MainIndex:=NodeService.RoleIdIndexes[i].MainIndex;
                              try
                                 NodeService.PushMsgResponse(NodeService.Connections[MainIndex].Socket,ResponseBody);
                              except
                              end;
                           end
                        else
                           break;
                     end;
               end;
         except
         end;
         LeaveCriticalSection(NodeService.ConnectionListCs);
         if not ok then
            begin
               ErrorCode:='0215202';
               ErrorText:='Push message to queue failed.';
               NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
               NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
            end;
      end
   else
      begin
         ErrorCode:='0215201';
         ErrorText:='无效参数...';
         NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
         NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr));
      end;
   FreeAndNil(Packet);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02152: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ClearRoleId;
var
   ConnectionId: int64;
   MainIndex: integer;
   ok: boolean;
begin
   ConnectionId:=RequestPacket.GetInt64Goods('ConnectionId');
   MainIndex:=NodeService.FindConnectionInConnectionId(ConnectionId);
   ok:=(MainIndex<>-1);
   if ok then
      begin
         ok:=(NodeService.Connections[MainIndex].BindingRoleId<>'');
         if ok then
            NodeService.RemoveRoleIdIndex(MainIndex)
         else
            begin
               ErrorCode:='0215302';
               ErrorText:='RoleId not binded.';
            end;
      end
   else
      begin
         ErrorCode:='0215301';
         ErrorText:='Invalid connection ID.';
      end;
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',ok);
      if not ok then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
            BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02153: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_GetRoleIdCount;
var
   RoleId: AnsiString;
   j: integer;
begin
   RoleId:=RequestPacket.GetAnsiStringGoods('RoleId');
   j:=NodeService.GetRoleIdConnectionCount(RoleId);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutIntegerGoods('RoleIdConnections',j);
   except
      on e: exception do
         NodeService.syslog.Log('Err02154: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ValueExists;
var
  ok,Exists: boolean;
  DatabaseId: AnsiString;
  BatchCommand: TStringList;
  SysConn: TuniConnection;
  SysCommand: TUniQuery;
  CommandTimeout,i,PoolId,Connectionid: integer;
begin
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  BatchCommand:=TStringList.Create;
  BatchCommand.Text:=RequestPacket.GetStringGoods('SQLCommandList');
  CommandTimeout:=RequestPacket.GetIntegerGoods('CommandTimeout');
  ok:=(BatchCommand.Count>0) and (CommandTimeout>=5);
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok then
    begin
      Exists:=false;
      try
        SysCommand:=TUniQuery.Create(nil);
        SysCommand.Connection:=SysConn;
        for i := 0 to BatchCommand.Count - 1 do
        begin
          if trim(BatchCommand[i])='' then
             continue;
          SysCommand.SQL.Text:=BatchCommand[i];
          SysCommand.Execute;
          if SysCommand.Fields[0].Value>0 then
          begin
            Exists:=true;
            break;
          end;
        end;
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0215603';
          ErrorText:='值检测不存在: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+Ansistring(BatchCommand.Text));
        end;
      end;
      if assigned(SysCommand) then
        FreeAndNil(SysCommand);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
      ErrorCode:='0215602';
      ErrorText:='分配数据库连接失败。';
      NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
      NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+Ansistring(BatchCommand.Text));
    end;
  end
  else
  begin
    ErrorCode:='0215601';
    ErrorText:='无效参数。';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+Ansistring(BatchCommand.Text));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    BackPacket.PutBooleanGoods('ValueExists',Exists);
    if not ok then
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02156: 创建反馈数据结构包错误: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
  FreeAndNil(BatchCommand);
end;

procedure TTaskThread.Task_TableExists;
var
  ok,Exists: boolean;
  DatabaseId: AnsiString;
  TableName: string;
  PoolId,ConnectionId: integer;
  SysConn: TUniConnection;
  tmpFldList: TStrings;
  nLoop: integer;
begin
  SysConn:=nil;
  tmpFldList:=nil;
  DatabaseId:=RequestPacket.GetEncryptStringGoods('DatabaseId');
  TableName:=RequestPacket.GetStringGoods('TableName');
  ok:=(DatabaseId<>'') and (TableName<>'');
  if ok then
  begin
    ok:=NodeService.GetConnection(DatabaseId,PoolId,ConnectionId,SysConn);
    if ok then
    begin
      tmpFldList := TStringList.Create ;
      Exists:=False ;
      try
        SysConn.GetTableNames(tmpFldList,false);
        for nLoop:=0 to tmpFldList.Count-1 do
        begin
          if uppercase(tmpFldList[nLoop])=uppercase(TableName) then
          begin
            Exists:=True;
            break;
          end;
        end;
        ok:=true;
      except
        on E: Exception do
        begin
          ok:=false;
          ErrorCode:='0215803';
          ErrorText:='检查表是否存在失败: ['+AnsiString(E.ClassName)+']-'+AnsiString(E.Message);
          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
          NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId+':'+AnsiString(TableName));
        end;
      end;
      FreeAndNil(tmpFldList);
      NodeService.FreeConnection(PoolId,ConnectionId);
    end
    else
    begin
       ErrorCode:='0215802';
       ErrorText:='分配数据库连接失败...';
       NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
       NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId+':'+AnsiString(TableName));
    end;
  end
  else
  begin
    ErrorCode:='0215801';
    ErrorText:='无效参数...';
    NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText);
    NodeService.syslog.Log('Call from: '+AnsiString(FromIpAddr)+#13#10+DatabaseId+':'+AnsiString(TableName));
  end;
  try
    BackPacket.EncryptKey:=NodeService.s_TransferKey;
    BackPacket.PutBooleanGoods('ProcessResult',ok);
    if ok then
    BackPacket.PutBooleanGoods('TableExists',Exists)
    else
    begin
      BackPacket.PutEncryptStringGoods('ErrorCode',ErrorCode);
      BackPacket.PutEncryptStringGoods('ErrorText',ErrorText);
    end;
  except
    on e: exception do
      NodeService.syslog.Log('Err02158: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
  end;
end;

Procedure TTaskThread.Task_PrepostData;
var
   DataName: AnsiString;
   tmpstr: AnsiString;
begin
   tmpstr:=RequestPacket.GetAnsiStringGoods('PrepostData');
   DataName:=ansistring(Inttostr(NodeService.GetSessionId(FromIpAddr)));
   PutCommonParameter(PAnsiChar(DataName),Str2Mem(tmpstr));
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
      BackPacket.PutAnsiStringGoods('DataName',DataName);
   except
      on e: exception do
         NodeService.syslog.Log('Err02159: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_ReloadPlugin;
begin
   x_ReloadUrl:=RequestPacket.GetEncryptStringGoods('ReloadPreloadUrl');
   synchronize(reloadpreloaddll);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',x_ReloadResult);
      if not x_ReloadResult then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0216003');
            BackPacket.PutEncryptStringGoods('ErrorText','Reload preload web plugin failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02160: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

procedure TTaskThread.Task_RefreshPreloadPlugins;
begin
   synchronize(NodeService.RefreshPreloads);
   try
      BackPacket.EncryptKey:=NodeService.s_TransferKey;
      BackPacket.PutBooleanGoods('ProcessResult',true);
      if not x_ReloadResult then
         begin
            BackPacket.PutEncryptStringGoods('ErrorCode','0216103');
            BackPacket.PutEncryptStringGoods('ErrorText','Load new preload web plugin failed.');
         end;
   except
      on e: exception do
         NodeService.syslog.Log('Err02161: 创建返回消息结构包失败: ['+ansistring(e.classname)+']-'+ansistring(e.message));
   end;
end;

end.

