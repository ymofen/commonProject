unit PageSQLMaker;

interface

uses
  utils.strings, SysUtils, Classes;



type
  TPageSQLMaker = class(TObject)
  private
    FPageSize: Integer;
    FTemplateSQL: String;
  public
    function GetRecordCounterSQL: string; virtual;
    function GetPageSQL(pvPageIndex:Integer): String; virtual;
    property PageSize: Integer read FPageSize write FPageSize;
    property TemplateSQL: String read FTemplateSQL write FTemplateSQL;
  end;

  TPageMySQLMaker = class(TPageSQLMaker)
  public
    function GetRecordCounterSQL: string; override;

    /// <summary>
    ///   生成获取第几页的数据的SQL语句
    ///   pageIndex从0开始
    /// </summary>
    function GetPageSQL(pvPageIndex:Integer): String; override;
  end;



implementation

function StringReplaceArea(s, pvStart, pvEnd, pvNewStr: string; pvIgnoreCase:
    Boolean): string;
var
  lvStr, lvStr2:String;
  lvSearchPtr, lvStartPtr:PChar;
  lvSB:TDStringBuilder;
  iStart, iEnd:Integer;
begin
  iStart := Length(pvStart);
  iEnd := Length(pvEnd);
  
  lvSB:= TDStringBuilder.Create;
  try
    lvSearchPtr := PChar(s);
    while True do
    begin
      lvStartPtr := lvSearchPtr;
      lvStr := LeftUntilStr(lvSearchPtr,PChar(pvStart), pvIgnoreCase);      
      if lvStr = ''  then
      begin     // 没了
        lvSB.Append(lvStartPtr);
        Break;
      end;
      // skip start
      Inc(lvSearchPtr, iStart);
      lvStr2 := LeftUntilStr(lvSearchPtr,PChar(pvEnd), pvIgnoreCase);
      if lvStr2 = '' then
      begin  
        // 没结束的区域
        lvSB.Append(lvStartPtr);
        Break;
      end;          
      Inc(lvSearchPtr, iEnd);

      lvSB.Append(lvStr);
      lvSB.Append(pvNewStr);   

    end;
    Result := lvSB.ToString;
  finally
    lvSB.Free;
  end;
  
end;

function TPageSQLMaker.GetPageSQL(pvPageIndex:Integer): String;
begin
  Result := '';
end;

function TPageSQLMaker.GetRecordCounterSQL: string;
begin
  Result := '';
end;

function TPageMySQLMaker.GetPageSQL(pvPageIndex:Integer): String;
var
  lvSQL, lvPageStr:String;
begin
  lvSQL := FTemplateSQL;
//  [selectlist][/selectlist] 区域在进行count统计记录时会进行替换 成count(1) as RecordCount
//  [countIgnore][/countIgnore] 区域在进行count统计记录时会被替换成空字符串
//  [page][/page]   分页语句 limit 0, 10
  lvSQL := StringReplace(lvSQL, '[selectlist]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[/selectlist]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[countIgnore]', '', [rfReplaceAll]);
  lvSQL := StringReplace(lvSQL, '[/countIgnore]', '', [rfReplaceAll]);
  lvPageStr := Format(' limit %d, %d ', [pvPageIndex * FPageSize, FPageSize]);
  lvSQL := StringReplace(lvSQL, '[page]', lvPageStr,  [rfReplaceAll]);
  Result := lvSQL;

end;

function TPageMySQLMaker.GetRecordCounterSQL: string;
var
  lvSQL:String;
begin
  lvSQL := FTemplateSQL;
//  [selectlist][/selectlist] 区域在进行count统计记录时会进行替换 成count(1) as RecordCount
//  [countIgnore][/countIgnore] 区域在进行count统计记录时会被替换成空字符串
//  [page][/page]   分页语句 limit 0, 10
  lvSQL := StringReplaceArea(lvSQL, '[selectlist]', '[/selectlist]', 'COUNT(1) AS RecordCount', True);
  lvSQL := StringReplaceArea(lvSQL, '[countIgnore]', '[/countIgnore]', '', True);
  lvSQL := StringReplace(lvSQL, '[page]', '',  [rfReplaceAll]);
  Result := lvSQL;

end;

end.
