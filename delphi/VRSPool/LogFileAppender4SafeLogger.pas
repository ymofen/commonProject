unit LogFileAppender4SafeLogger;

interface

uses
  utils.safeLogger, SysUtils;

type
  TLogFileAppender4SafeLogger = class(TBaseAppender)
  private
    FBasePath: string;
    FFilePreFix: String;
    FInitialized: Boolean;
    FLogFile: TextFile;
    FOutputToConsole: Boolean;
    procedure checkInitialized;
    function openLogFile(pvPre: String = ''): Boolean;
  protected
    procedure AppendLog(pvData:TLogDataObject); override;
  public
    constructor Create;
    property BasePath: string read FBasePath write FBasePath;
    property FilePreFix: String read FFilePreFix write FFilePreFix;
    property OutputToConsole: Boolean read FOutputToConsole write FOutputToConsole;



  end;

implementation

constructor TLogFileAppender4SafeLogger.Create;
begin
  inherited Create;
  FBasePath :=ExtractFilePath(ParamStr(0)) + 'log';
end;

procedure TLogFileAppender4SafeLogger.AppendLog(pvData: TLogDataObject);
var
  lvMsg:String;
  lvPreFix :String;
begin
  checkInitialized;
  lvPreFix := FFilePreFix;
  if pvData.FLogLevel = lgvError then
  begin
    lvPreFix := lvPreFix + '¥ÌŒÛ_';
  end else
  begin
    lvPreFix := lvPreFix + '‘À––_';
  end;


  if OpenLogFile(lvPreFix) then
  begin
    try
      lvMsg := Format('%s[%s]:%s',
          [FormatDateTime('hh:nn:ss:zzz', pvData.FTime)
            , TLogLevelCaption[pvData.FLogLevel]
            , pvData.FMsg
          ]
          );
      writeln(FLogFile, lvMsg);
      if FOutputToConsole then
      begin
        Writeln(lvMsg);
      end;
      flush(FLogFile);
    finally
      CloseFile(FLogFile);
    end;
  end else
  begin
    FOwner.incErrorCounter;
  end;
end;

procedure TLogFileAppender4SafeLogger.checkInitialized;
begin
  if FInitialized then exit;
  if not DirectoryExists(FBasePath) then ForceDirectories(FBasePath);
  FInitialized := true;
end;

function TLogFileAppender4SafeLogger.openLogFile(pvPre: String = ''): Boolean;
var
  lvFileName:String;
begin 
  lvFileName :=FBasePath + '\' + pvPre + FormatDateTime('YY.M.D', Now()) + '.log';
  try
    AssignFile(FLogFile, lvFileName);
    if (FileExists(lvFileName)) then
      append(FLogFile)
    else
      rewrite(FLogFile);

    Result := true;
  except
    Result := false;
  end;
end;

end.
