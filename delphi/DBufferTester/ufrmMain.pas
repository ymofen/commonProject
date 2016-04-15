unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, utils.strings;

type
  TForm1 = class(TForm)
    btn1: TButton;
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btn1Click(Sender: TObject);
var
  lvDBuffer:TDBufferBuilder;
  lvStream, lvTempStream:TMemoryStream;
  lvByte, lvByte2:Byte;
begin
  lvStream := TMemoryStream.Create;
  lvTempStream := TMemoryStream.Create;
  lvDBuffer := TDBufferBuilder.Create;
  try
    lvTempStream.Write('ab', 2);
    lvDBuffer.LoadFromFile(ParamStr(0));
    lvDBuffer.SaveToFile('dbuffer.dat');

    lvStream.LoadFromFile(ParamStr(0));
    lvStream.SaveToFile('stream.dat');
    while True do
    begin
      if lvStream.Read(lvByte, 1) = 0 then Break;
      lvDBuffer.Read(lvByte2, 1);
      Assert(lvByte= lvByte2);
      Assert(lvStream.Position = lvDBuffer.Position);
      Assert(lvStream.Size = lvDBuffer.Size);
    end;


    Assert(lvDBuffer.CopyFrom(lvTempStream, 0) = lvStream.CopyFrom(lvTempStream, 0));
    Assert(lvStream.Position = lvDBuffer.Position);
    Assert(lvStream.Size = lvDBuffer.Size);

    ShowMessage(Format('%d, %d'#13#10'%d, %d',
      [lvStream.Position, lvStream.Size, lvDBuffer.Position, lvDBuffer.Size]));

    lvStream.Clear;
    lvDBuffer.Clear;
    Assert(lvStream.Position = lvDBuffer.Position);
    Assert(lvStream.Size = lvDBuffer.Size);
  finally
    lvStream.Free;
    lvDBuffer.Free;
    lvTempStream.Free;
  end;
  ;
end;

end.
