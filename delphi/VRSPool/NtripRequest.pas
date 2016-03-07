unit NtripRequest;

interface

uses
  utils_BufferPool, utils.strings, SysUtils;

const
  END_BYTES : array[0..3] of Byte = (13,10,13,10);
  MAX_RAW_BUFFER_SIZE = 4096;

type
  TNtripRequest = class(TObject)
  private
    FHeader:String;
    FContext:String;
    FBuffer:PByte;
    FPtrBuffer:PByte;
    FEndMatchIndex:Integer;
    FLength:Integer;

    /// <summary>
    ///   0: 需要初始化
    ///   1: 已经初始化
    /// </summary>
    FFlag:Byte;
    FMethod: String;
    FMountPoint: string;

    /// <summary>
    ///  0: Header;
    ///  1: Context;
    /// </summary>
    FSectionFlag:Byte;
    FSourcePass: String;

    function DecodeHeader: Integer;
  public
    /// <summary>TNtripRequest.InputBuffer
    /// </summary>
    /// <returns>
    ///  0: 需要更多的数据来完成解码
    ///  -2: 超过最大长度(MAX_RAW_BUFFER_SIZE)
    ///  1: Header
    ///  2: Content
    /// </returns>
    /// <param name="pvByte"> (Byte) </param>
    function InputBuffer(pvByte:Byte): Integer;
    property Context: String read FContext;
    property Header: String read FHeader;

    property Method: String read FMethod write FMethod;

    property MountPoint: string read FMountPoint write FMountPoint;

    property SourcePass: String read FSourcePass write FSourcePass;



    

    procedure DoCleanUp;

    destructor Destroy; override;
  end;

procedure __initalizeRequestBufferPool;
procedure __finalizeRequestBufferPool;

implementation





var
  __RequestBufferPool:PBufferPool;



procedure __initalizeRequestBufferPool;
begin
  __RequestBufferPool := NewBufferPool(MAX_RAW_BUFFER_SIZE);
end;

procedure __finalizeRequestBufferPool;
begin
  FreeBufferPool(__RequestBufferPool);
  __RequestBufferPool := nil;
end;

destructor TNtripRequest.Destroy;
begin
  DoCleanUp;
  inherited;
end;

function TNtripRequest.DecodeHeader: Integer;
var
  lvPtr:PChar;
begin
  // GET /test?v=abc HTTP/1.1
  // SOURCE letmein /Mountpoint
  lvPtr := PChar(FHeader);
  FMethod := UpperCase(LeftUntil(lvPtr, [' ']));
  if FMethod = '' then
  begin
    Result := -1;
    Exit;
  end;

  // 跳过空格
  SkipChars(lvPtr, [' ']);
  
  if (FMethod = 'GET') then
  begin
    if lvPtr^='/' then inc(lvPtr);
    FMountPoint := LeftUntil(lvPtr, [' ']);
  end else if (FMethod = 'SOURCE') then
  begin
    if lvPtr^=' ' then
    begin
      FSourcePass := '';
    end else
    begin
      FSourcePass := LeftUntil(lvPtr, [' ']);
    end;
    // 跳过空格
    SkipChars(lvPtr, [' ']);
    if lvPtr^='/' then inc(lvPtr);

    
    FMountPoint := LeftUntil(lvPtr, [' ', #13, #10]);
  end else
  begin
    Result := -1;
  end;
           


  

  Result := 0;
end;

procedure TNtripRequest.DoCleanUp;
begin
  if FBuffer <> nil then
  begin
    ReleaseRef(FBuffer);
    FBuffer := nil;
    FSectionFlag := 0;
    FFlag := 0;
  end;
end;

function TNtripRequest.InputBuffer(pvByte:Byte): Integer;
begin
  Result := 0;
  if FFlag = 0 then
  begin
    FBuffer := GetBuffer(__RequestBufferPool);
    AddRef(FBuffer);
    FFlag := 1;
    FEndMatchIndex := 0;
    FPtrBuffer := FBuffer;
    FLength := 0;
  end;

  Inc(FLength);
  FPtrBuffer^ := pvByte;
  Inc(FPtrBuffer);

  if (pvByte = END_BYTES[FEndMatchIndex]) then
  begin
    inc(FEndMatchIndex);
    if (FEndMatchIndex = 4) then
    begin
      if FSectionFlag = 0 then
      begin                                             
        FHeader := Utf8BufferToString(FBuffer, FLength);
        if DecodeHeader = -1 then
        begin
          FSectionFlag := 0;
          Result := -1;
        end else
        begin
          FSectionFlag := 1;
          Result := 1;
        end;
      end else
      begin
        FContext := Utf8BufferToString(FBuffer, FLength);
        Result := 2;
      end;
      ReleaseRef(FBuffer);
      FBuffer :=nil;
      FFlag := 0;

      Exit;
    end;
  end
  else if (FLength = MAX_RAW_BUFFER_SIZE) then
  begin
    ReleaseRef(FBuffer);
    FBuffer :=nil;
    FFlag := 0;
    Result := -2;
  end else
  begin
    FEndMatchIndex := 0;
  end;
  Result := 0;
end;

end.
