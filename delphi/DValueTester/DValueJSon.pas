unit DValueJSon;

// #34  "
// #39  '
// #32  空格
// #58  :
// #9   TAB

interface

uses
  utils_DValue, utils.strings;

type
  TJsonParser = class(TObject)
  private
    FLastStrValue: String;
    FLastValue: String;
  end;

function JSONParser(s:string): TDValue;

function JSONEncode(v:TDValue): String;


    
implementation



function JSONParseEx(var ptrData: PChar; pvDValue: TDValue; pvParser:
    TJsonParser): Integer; forward;
    
function JSONSkipSpaceAndComment(var ptrData: PChar; pvParser: TJsonParser):
    Integer;forward;

function JSONParseName(var ptrData:PChar; pvParser:TJsonParser):Integer;
var
  lvEndChar:Char;
  lvStart:PChar;
begin
  if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
  begin
    Result := -1;
    exit;
  end;
  if ptrData^ in ['"', ''''] then
  begin
    lvEndChar := ptrData^;
    inc(ptrData);
    lvStart := ptrData;
    while ptrData^ <> #0 do
    begin
      if ptrData^ = lvEndChar then
      begin
        pvParser.FLastStrValue := Copy(lvStart, 0, ptrData - lvStart);
        Inc(ptrData);
        if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
        begin
          Result := -1;
          exit;
        end;
        if ptrData^ <> ':' then
        begin
          Result := -1;
          Exit;
        end;
        Inc(ptrData);
        Result := 0;
        Exit;
      end else
      begin
        Inc(ptrData);
      end;
    end;
    Result := -1;
    Exit;
  end else
  begin
    lvStart := ptrData;
    while ptrData^ <> #0 do
    begin
      if ptrData^ in [':'] then
      begin
        pvParser.FLastStrValue := Copy(lvStart, 0, ptrData - lvStart);
        Inc(ptrData);
        Result := 0;
        Exit;
      end else if ptrData^ in [#32, #9] then
      begin
        pvParser.FLastStrValue := Copy(lvStart, 0, ptrData - lvStart);
        if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
        begin
          Result := -1;
          exit;
        end;
        if ptrData^ <> ':' then
        begin
          Result := -1;
          Exit;
        end;
        Inc(ptrData);
        Result := 0;
        Exit;
      end else
      begin
        Inc(ptrData);
      end;
    end;
    Result := -1;
    Exit;
  end;
end;


function JSONParseValue(var ptrData: PChar; pvDValue: TDValue; pvParser:
    TJsonParser): Integer;
var
  lvEndChar:Char;
  lvStart:PChar;
begin
  pvParser.FLastStrValue := '';
  pvParser.FLastValue := '';
  if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
  begin
    Result := -1;
    exit;
  end;
  if ptrData^ in ['"', ''''] then
  begin
    lvEndChar := ptrData^;
    inc(ptrData);
    lvStart := ptrData;
    while ptrData^ <> #0 do
    begin
      if ptrData^ = lvEndChar then
      begin
        pvDValue.Value.AsString := Copy(lvStart, 0, ptrData - lvStart);
        Inc(ptrData);
        if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
        begin
          Result := -1;
          exit;
        end;
        if ptrData^ in [',',']','}'] then
        begin
          Result := 1;
          Exit;
        end;
        Result := -1;
        exit;
      end else
      begin
        Inc(ptrData);
      end;
    end;
    Result := -1;
    Exit;
  end else if ptrData^ in ['{', '['] then
  begin
    JSONParseEx(ptrData, pvDValue, pvParser);
    Result := 5;    
  end else
  begin
    lvStart := ptrData;
    while ptrData^ <> #0 do
    begin
      if ptrData^ in [',',']','}'] then
      begin
        pvDValue.Value.AsString := Copy(lvStart, 0, ptrData - lvStart);
        Result := 2;
        Exit;
      end else if ptrData^ in [#32, #9] then
      begin
        pvDValue.Value.AsString := Copy(lvStart, 0, ptrData - lvStart);
        if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
        begin
          Result := -1;
          exit;
        end;
        if ptrData^ in [',',']','}'] then
        begin
          Result := 2;
          Exit;
        end;
        Result := -1;
        Exit;
      end else
      begin
        Inc(ptrData);
      end;
    end;
    Result := -1;
    Exit;
  end;
end;

function JSONParseEx(var ptrData: PChar; pvDValue: TDValue; pvParser:
    TJsonParser): Integer;
var
  lvEndChar:Char;
  lvChild:TDValue;
  r:Integer;
begin  
  if ptrData^ in ['{', '['] then
  begin
    if ptrData^ = '{' then
    begin
      pvDValue.CheckSetNodeType(vntObject);
      lvEndChar := '}';
      Result := 1;
    end else if ptrData^ = '[' then
    begin
      pvDValue.CheckSetNodeType(vntArray);
      lvEndChar := ']';
      Result := 2;
    end;
    Inc(ptrData);
    if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
    begin
      Result := -1;
      exit;
    end;
    while (ptrData^ <> #0) and (ptrData^ <> lvEndChar) do
    begin
      if (ptrData^ <> lvEndChar) then
      begin
        if pvDValue.ObjectType = vntArray then
        begin
          lvChild := pvDValue.AddArrayChild;
        end else
        begin
          lvChild := pvDValue.Add;
        end;
        if JSONParseEx(ptrData, lvChild, pvParser) = -1 then
        begin
          Result := -1;
          exit;
        end;
        if ptrData^ = ',' then
        begin
          Inc(ptrData);
          if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
          begin
            Result := -1;
            exit;
          end;
        end;
      end else  // 解析完成
        Exit;
    end;  
    if JSONSkipSpaceAndComment(ptrData, pvParser) = -1 then
    begin
      Result := -1;
      exit;
    end;
    if ptrData^ <> lvEndChar then
    begin
      Result := -1;
      Exit;
    end;
    Inc(ptrData);
    JSONSkipSpaceAndComment(ptrData, pvParser);
  end else if (pvDValue.Parent <> nil) then
  begin
    if (pvDValue.Parent.ObjectType = vntObject) and (pvDValue.Name.DataType in [vdtNull, vdtUnset]) then
    begin
      if JSONParseName(ptrData, pvParser) = -1 then
      begin
        Result := -1;
        Exit;
      end else
      begin
        pvDValue.Name.AsString := pvParser.FLastStrValue;
        Result := JSONParseValue(ptrData, pvDValue, pvParser);
        Exit;
      end;
    end; 
  end else
  begin
    pvDValue.CheckSetNodeType(vntNull);
    Result := -1;
  end;     
end;

function JSONSkipSpaceAndComment(var ptrData: PChar; pvParser: TJsonParser):   Integer;
begin
  Result := 0;
  SkipChars(ptrData, [#10, #13, #9, #32]);
  while ptrData^ = '/' do
  begin
    if ptrData[1] = '/' then
    begin
      SkipUntil(ptrData, [#10]);
      SkipChars(ptrData, [#10, #13, #9, #32]);
    end else if ptrData[1] = '*' then
    begin
      Inc(ptrData, 2);
      while ptrData^ <> #0 do
      begin
        if (ptrData[0] = '*') and (ptrData[1] = '/') then
        begin
          Inc(ptrData, 2);
          SkipChars(ptrData, [#10, #13, #9, #32]);
          Break;
        end
        else
          Inc(ptrData);
      end;
    end else
    begin
      Result := -1;
      Exit;
    end;
  end;
end;

function JSONParser(s:string): TDValue;
var
  ptrData:PChar;
  j:Integer;
  lvParser:TJsonParser;
begin
  ptrData := PChar(s);
  lvParser := TJsonParser.Create;
  try
    j := JSONSkipSpaceAndComment(ptrData, lvParser);
    if j = -1 then
    begin
      Result := nil;
      Exit;
    end;

    if (ptrData ^ in ['{', '[']) then
    begin 
      Result := TDValue.Create();
      JSONParseEx(ptrData, Result, lvParser);
    end;
  finally
    lvParser.Free;
  end;
end;

function JSONEncode(v:TDValue): String;
begin
  Result := '';
end;

end.
