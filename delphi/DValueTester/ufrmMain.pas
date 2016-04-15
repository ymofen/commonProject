unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, utils_DValue, utils.strings, ComCtrls,
  IdMultipartFormData, utils_dvalue_multiparts, utils_dvalue_msgpack,
  SimpleMsgPack;

type
  TForm1 = class(TForm)
    pnlTop: TPanel;
    mmoData: TMemo;
    btnParseJSON: TButton;
    btnEncodeJSON: TButton;
    btnClear: TButton;
    btnObjectTester: TButton;
    pgcMain: TPageControl;
    tsJSON: TTabSheet;
    tsMultiParts: TTabSheet;
    btnSave: TButton;
    btnParse: TButton;
    tsMsgPack: TTabSheet;
    btnMsgPackSave: TButton;
    btnMsgPackParse: TButton;
    procedure btnClearClick(Sender: TObject);
    procedure btnEncodeJSONClick(Sender: TObject);
    procedure btnMsgPackSaveClick(Sender: TObject);
    procedure btnObjectTesterClick(Sender: TObject);
    procedure btnParseClick(Sender: TObject);
    procedure btnParseJSONClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  utils_DValue_JSON;

{$R *.dfm}

procedure TForm1.btnClearClick(Sender: TObject);
begin
  mmoData.Clear;
end;

procedure TForm1.btnEncodeJSONClick(Sender: TObject);
const
  MemoryDelta = $2000; { Must be a power of 2 }

var
  lvDValue, lvItem:TDValue;
  lvValue:Integer;
  lvSB:TDStringBuilder;
begin
  lvDValue := TDValue.Create();
  lvDValue.ForceByPath('p2.obj').BindObject(Self, faNone);
  lvDValue.ForceByPath('p2.n').AsInteger := 3;
  lvDValue.ForceByName('name').AsString := '张三abc';
//  lvDValue.ForceByName('__msgid').AsInteger := 1001;
//  lvDValue.ForceByPath('p1.name').AsString := '杨茂丰';
//  lvDValue.ForceByPath('p2.p2_1.name').AsString := '杨茂丰';
//  lvDValue.ForceByPath('p2.num').AsInteger := 1;
//
//
//  lvItem := lvDValue.ForceByName('array').AddArrayChild;
//  lvItem.ForceByName('key1').AsString := '数组元素1';
//  lvDValue.ForceByName('array').AddArrayChild.AsString := '数组元素2';

  ShowMessage(JSONEncode(lvDValue, true, true, [vdtObject]));
  lvDValue.Free;

  lvSB := TDStringBuilder.Create;
  try
    lvSB.Append('').AppendLine('杨茂丰').Append(123).Append(true).Append(',').Append(3.1415926).AppendQuoteStr('杨一恒');
    ShowMessage(lvSB.ToString);
  finally
    lvSB.Free;
  end;
//
//  lvValue := 8192;
//
//  lvValue := (lvValue + (MemoryDelta - 1)) and not (MemoryDelta - 1);
//
//  ShowMessage(Format('%x, %d', [lvValue, lvValue]));


end;

procedure TForm1.btnMsgPackSaveClick(Sender: TObject);
var
  lvFileStream:TFileStream;
  lvDValue:TDValue;
  lvFileName:String;
  lvMsgPack:TSimpleMsgPack;
begin
  lvFileName := ExtractFilePath(ParamStr(0)) + 'dvalue_msgpack.dat';
  DeleteFile(lvFileName);

  lvFileStream := TFileStream.Create(lvFileName, fmCreate);
  try
    lvDValue := TDValue.Create();
    lvDValue.ForceByName('备注').AsString:= 'HELLO中国' + sLineBreak + 'World 你好';
    lvDValue.ForceByName('fileID').AsString:= ExtractFileName(ParamStr(0));
    lvDValue.ForceByName('data').AsStream.LoadFromFile(ParamStr(0));
    MsgPackEncode(lvDValue, lvFileStream);
    lvDValue.Free;
  finally
    lvFileStream.Free;
  end;

  lvMsgPack := TSimpleMsgPack.Create;
  lvMsgPack.DecodeFromFile(lvFileName);
  ShowMessage(lvMsgPack.ForcePathObject('备注').AsString);
  lvMsgPack.Free;
end;

procedure TForm1.btnObjectTesterClick(Sender: TObject);
var
  lvDValue:TDValue;
begin
  lvDValue := TDValue.Create();

  // 设置为数组为3
  lvDValue.Value.SetArraySize(3);

  lvDValue.Value.Items[0].BindObject(TButton.Create(nil), faFree);
  lvDValue.Value.Items[1].BindObject(TButton.Create(nil), faFree);
  lvDValue.Value.Items[2].BindObject(TButton.Create(nil), faFree);

  // 设置为数组为2(会释放一个)
  lvDValue.Value.SetArraySize(2);
  
  lvDValue.Free;

end;

procedure TForm1.btnParseClick(Sender: TObject);
var
  lvDVAlue:TDValue;
  lvTickCount:Cardinal;
begin
  lvDVAlue := TDValue.Create();
  lvTickCount := GetTickCount;
  MultiPartsParseFromFile(lvDVAlue, 'multparts.dat');
  Self.Caption := Format('MultiPartsParseFromFile, time:%d ns', [GetTickCount - lvTickCount]);
  SavePartValueToFile(lvDVAlue, 'data', 'abc.dat');
  ShowMessage(ExtractValueAsUtf8String(lvDVAlue, 'fileID', ''));
  lvDVAlue.Free;
end;

procedure TForm1.btnParseJSONClick(Sender: TObject);
var
  lvDValue, lvDValue2, lvAccountGroup:TDValue;
begin
  lvDValue := TDValue.Create();
  JSONParser(mmoData.Lines.Text, lvDValue);
  ShowMessage(JSONEncode(lvDValue, False));

//  lvDValue2 := TDValue.Create();
//  JSONParser(lvDValue.ForceByName('main').AsString, lvDValue2);
//  ShowMessage(JSONEncode(lvDValue2, False));


//  lvAccountGroup := lvDValue.ForceByPath('AccountList.AccountGroup');
//  ShowMessage(lvAccountGroup.Items[0].ForceByName('Name').Value.AsString);
end;

procedure TForm1.btnSaveClick(Sender: TObject);
var
  lvMultiParts:TIdMultiPartFormDataStream;
  lvFileStream:TFileStream;

  lvDValue:TDValue;

  lvBuilder:TDBufferBuilder;
begin
  lvMultiParts := TIdMultiPartFormDataStream.Create;
  lvMultiParts.AddFormField('fileID', ExtractFileName(ParamStr(0)));
  lvMultiParts.AddFile('data', ExtractFileName(ParamStr(0)), 'application/x-msdownload');
  lvFileStream := TFileStream.Create(ExtractFilePath(ParamStr(0)) + 'multparts.dat', fmCreate);
  lvMultiParts.Position := 0;
  lvFileStream.CopyFrom(lvMultiParts, lvMultiParts.Size);
  lvFileStream.Free;
  lvMultiParts.Free;


  lvBuilder := TDBufferBuilder.Create;
  lvDValue := TDValue.Create();
  lvDValue.ForceByName('备注').AsString:= 'HELLO中国' + sLineBreak + 'World 你好';
  lvDValue.ForceByName('fileID').AsString:= ExtractFileName(ParamStr(0));
  AddFieldValue(lvDValue, 'e主键e', '很多字符abc');
  AddFilePart(lvDValue, 'data', ParamStr(0));

  MultiPartsEncode(lvDValue, lvBuilder, '');
  lvDValue.Free;

  lvBuilder.SaveToFile(ExtractFilePath(ParamStr(0)) + 'dvalue_multparts.dat');
  lvBuilder.Free;


end;

end.
