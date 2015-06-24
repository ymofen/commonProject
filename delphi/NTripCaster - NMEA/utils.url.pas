unit utils.url;

interface

uses
  utils.strings;


type
  TURL = class(TObject)
  private
    FHost: string;
    FUser: String;
    FPassword: String;
    FParamStr: String;
    FPort: string;
    FProtocol: string;
    /// <summary>
    ///   分析路径部分
    ///   127.0.0.1:9983
    ///   user:password@127.0.0.1:9983/diocp/a.html
    /// </summary>
    procedure InnerParseUrlPath(const pvPath:String);
  public
    procedure SetURL(pvURL:String);

    /// <summary>
    ///   协议, http, https, ftp
    /// </summary>
    property Protocol: string read FProtocol write FProtocol;

    /// <summary>
    ///   主机地址
    /// </summary>
    property Host: string read FHost write FHost;

    /// <summary>
    ///   端口
    /// </summary>
    property Port: string read FPort write FPort;

    /// <summary>
    ///   参数
    /// </summary>
    property ParamStr: String read FParamStr write FParamStr;




  end;

implementation

{ TURL }

procedure TURL.InnerParseUrlPath(const pvPath: String);
var
  lvP, lvTempP:PChar;
  lvTempStr:String;
begin
  if length(pvPath) = 0 then Exit;

  lvP := PChar(pvPath);
  /// user:password
  lvTempStr := LeftUntil(lvP, ['@']);

  if lvTempStr <> '' then
  begin  // 存在用户名和密码
    lvTempP := PChar(lvTempStr);

    FUser := LeftUntil(lvTempP, [':']);
    if FUser <> '' then
    begin
      SkipChars(lvTempP, [':']);
      FPassword := lvTempP;
    end else
    begin
      // 无密码
      FUser := lvTempStr;
    end;
    SkipChars(lvP, ['@']);
  end;


end;

procedure TURL.SetURL(pvURL: String);
var
  lvPSave, lvPUrl:PChar;
  lvTempStr:String;
begin
  FProtocol := '';
  FHost := '';
  FPort := '';
  FPassword := '';
  FUser := '';

  lvPUrl := PChar(pvURL);

  if (lvPUrl = nil) or (lvPUrl^ = #0) then Exit;

  // http, ftp... or none
  FProtocol := LeftUntilStr(lvPUrl, '://');
  if FProtocol <> '' then lvPUrl := lvPUrl + 3; // 跳过 ://

  lvPSave := lvPUrl;  // 保存位置

  ///  路径和参数
  ///  www.diocp.org/image/xxx.asp
  lvTempStr := LeftUntil(lvPUrl, ['?']);

  // 如果没有参数
  if lvTempStr = '' then
  begin
    /// 路径和书签
    lvTempStr := LeftUntil(lvPUrl, ['#']);
  end;


  





  


end;

end.
