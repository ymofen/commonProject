unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, utils_DValue, utils.strings;

type
  TForm1 = class(TForm)
    pnlTop: TPanel;
    mmoData: TMemo;
    btnParseJSON: TButton;
    btnEncodeJSON: TButton;
    btnClear: TButton;
    procedure btnClearClick(Sender: TObject);
    procedure btnEncodeJSONClick(Sender: TObject);
    procedure btnParseJSONClick(Sender: TObject);
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
//  lvDValue.ForceByName('__msgid').AsInteger := 1001;
//  lvDValue.ForceByPath('p1.name').AsString := 'ÑîÃ¯·á';
//  lvDValue.ForceByPath('p2.p2_1.name').AsString := 'ÑîÃ¯·á';
//  lvDValue.ForceByPath('p2.num').AsInteger := 1;
//
//
//  lvItem := lvDValue.ForceByName('array').AddArrayChild;
//  lvItem.ForceByName('key1').AsString := 'Êý×éÔªËØ1';
//  lvDValue.ForceByName('array').AddArrayChild.AsString := 'Êý×éÔªËØ2';

  ShowMessage(JSONEncode(lvDValue, False, true, [vdtObject]));
  lvDValue.Free;

  lvSB := TDStringBuilder.Create;
  try
    lvSB.Append('').AppendLine('ÑîÃ¯·á').Append(123).Append(true).Append(',').Append(3.1415926).AppendQuoteStr('ÑîÒ»ºã');
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

procedure TForm1.btnParseJSONClick(Sender: TObject);
var
  lvDValue, lvAccountGroup:TDValue;
begin
  lvDValue := TDValue.Create();
  JSONParser(mmoData.Lines.Text, lvDValue);
  ShowMessage(JSONEncode(lvDValue, False));
//  lvAccountGroup := lvDValue.ForceByPath('AccountList.AccountGroup');
//  ShowMessage(lvAccountGroup.Items[0].ForceByName('Name').Value.AsString);
end;

end.
