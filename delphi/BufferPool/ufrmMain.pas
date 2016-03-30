unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, utils_BufferPool, StdCtrls, utils_async, utils.byteTools,
  utils.strings, utils.queues, utils.safeLogger;

type
  TForm1 = class(TForm)
    btnNewPool: TButton;
    btnFreePool: TButton;
    btnSimpleTester: TButton;
    btnThreadTester: TButton;
    btnThreadTester2: TButton;
    mmoLog: TMemo;
    btnPoolInfo: TButton;
    btnClear: TButton;
    btnCheckBounds: TButton;
    btnOutOfBounds: TButton;
    btnSpeedTester: TButton;
    edtThread: TEdit;
    btnSpinLocker: TButton;
    procedure btnCheckBoundsClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnFreePoolClick(Sender: TObject);
    procedure btnNewPoolClick(Sender: TObject);
    procedure btnOutOfBoundsClick(Sender: TObject);
    procedure btnPoolInfoClick(Sender: TObject);
    procedure btnSimpleTesterClick(Sender: TObject);
    procedure btnSpeedTesterClick(Sender: TObject);
    procedure btnSpinLockerClick(Sender: TObject);
    procedure btnThreadTester2Click(Sender: TObject);
    procedure btnThreadTesterClick(Sender: TObject);
  private
    { Private declarations }
    FPool:PBufferPool;

    procedure Tester(ASyncWorker:TASyncWorker);
    procedure TesterForSpeed(ASyncWorker:TASyncWorker);

    procedure Tester2(ASyncWorker:TASyncWorker);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation


{$R *.dfm}

procedure TForm1.btnCheckBoundsClick(Sender: TObject);
var
  r:Integer;
begin
  r := CheckBufferBounds(FPool);
  sfLogger.logMessage('池中共有:%d个内存块, 可能[%d]个内存块写入越界的情况', [FPool.FSize, r]);
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  mmoLog.Clear;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  sfLogger.AppendInMainThread := true;
  TStringsAppender(sfLogger.Appender).AddThreadINfo := true;
end;

procedure TForm1.btnFreePoolClick(Sender: TObject);
begin
  FreeBufferPool(FPool);
end;

procedure TForm1.btnNewPoolClick(Sender: TObject);
begin
  FPool := NewBufferPool(4096);
end;

procedure TForm1.btnOutOfBoundsClick(Sender: TObject);
var
  lvBuff:PByte;
begin
  lvBuff := GetBuffer(FPool);
  AddRef(lvBuff);


  FillChar(lvBuff^, FPool.FBlockSize, 1);

  // 越界写入
  PByte(Integer(lvBuff) + FPool.FBlockSize)^ := $FF;

  sfLogger.logMessage(TByteTools.varToHexString(lvBuff^, FPool.FBlockSize + 8));

  ReleaseRef(lvBuff);
end;

procedure TForm1.btnPoolInfoClick(Sender: TObject);
begin
  sfLogger.logMessage('get:%d, put:%d, addRef:%d, releaseRef:%d, size:%d', [FPool.FGet, FPool.FPut, FPool.FAddRef, FPool.FReleaseRef, FPool.FSize]);
end;

procedure TForm1.btnSimpleTesterClick(Sender: TObject);
var
  lvBuff:PByte;
begin
  lvBuff := GetBuffer(FPool);
  lvBuff^ := 1;
  PByte(Integer(lvBuff) + 8)^ := $FF;

  AttachData(lvBuff, TSafeQueue.Create, FREE_TYPE_OBJECTFREE);

  AddRef(lvBuff);
  AddRef(lvBuff);

  ReleaseRef(lvBuff);
  ReleaseRef(lvBuff);
end;

procedure TForm1.btnSpeedTesterClick(Sender: TObject);
var
  i, s:Integer;
begin
  if FPool = nil then raise Exception.Create('请先初始化FPool');
  for i := 1 to StrToInt(edtThread.Text) do
  begin
    ASyncInvoke(TesterForSpeed);
  end;
end;

procedure TForm1.btnSpinLockerClick(Sender: TObject);
var
  lvTarget:Integer;
begin
  lvTarget := 0;
  if AtomicCmpExchange(lvTarget, 1, 0) = 0 then
  begin
    ShowMessage('OK');
  end;

  if AtomicCmpExchange(lvTarget, 0, 1) = 1 then
  begin
    ShowMessage('OK');
  end;
  ;
end;

procedure TForm1.btnThreadTester2Click(Sender: TObject);
var
  lvBuf:PByte;
  i: Integer;
begin
  lvBuf := GetBuffer(FPool);
  lvBuf^ := 1;
  // 同一内存由多个线程去处理后归还

  for i := 1 to 100 do
  begin
    AddRef(lvBuf);
    ASyncInvoke(Tester2, lvBuf);
  end;
end;

procedure TForm1.btnThreadTesterClick(Sender: TObject);
var
  i:Integer;
begin
  // 多个线程同时获取内存块，并进行读写归还

  for i := 1 to 100 do
  begin
    ASyncInvoke(Tester);
  end;

end;

procedure TForm1.Tester(ASyncWorker:TASyncWorker);
var
  lvBuff:PByte;
  i:Integer;
  lvQueue:TSafeQueue;
begin
  Sleep(0);
  i := 1;
  while i < 100 do
  begin
    lvBuff := GetBuffer(FPool);
    lvBuff^ := 1;
    // 添加附加数据
    AttachData(lvBuff, TSafeQueue.Create, FREE_TYPE_OBJECTFREE);

    AddRef(lvBuff);

    // 获取附加数据
    Assert(GetAttachData(lvBuff, Pointer(lvQueue)) = 0);
    
    Sleep(0);
    ReleaseRef(lvBuff, False);
    inc(i);
  end;
end;

procedure TForm1.TesterForSpeed(ASyncWorker:TASyncWorker);
var
  lvBuff:PByte;
  i:Integer;
  l:Cardinal;
begin
  Sleep(0);
  i := 0;
  l := GetTickCount;
  while i < 10000000 do
  begin


    lvBuff := GetBuffer(FPool);
    lvBuff^ := 1;
    AddRef(lvBuff);
    //FillChar(lvBuff^, self.FPool.FBlockSize, 0);
    FillChar(lvBuff^, 16, 0);
    //FillChar(Result^, BLOCK_SIZE, 0);

    ReleaseRef(lvBuff);
    inc(i);
  end;
  l := GetTickCount - l;
  sfLogger.logMessage('id:%d, t:%d, c:%d, speed:%f / s', [GetCurrentThreadId, l, i, (i * 1000.0000) / l]);
end;

procedure TForm1.Tester2(ASyncWorker:TASyncWorker);
begin
  sfLogger.logMessage(TByteTools.varToHexString(ASyncWorker.Data, 5));
  sleep(0);
  ReleaseRef(ASyncWorker.Data);  
end;

end.
