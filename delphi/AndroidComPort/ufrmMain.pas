unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    btnOpen: TButton;
    procedure btnOpenClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  posix_serialPort;


{$R *.fmx}

procedure TForm1.btnOpenClick(Sender: TObject);
var
  fd, l:Integer;
  lvBytes:TBytes;
begin
  fd := OpenPort('/dev/ttyHSL1');
  if fd = -1 then
  begin
    raise Exception.Create('open fail');
  end else
  begin
    showMessage('打开端口成功，准备读取数据');
  end;

  SetLength(lvBytes, 10240);

  l := ReadBuffer(fd, @lvBytes[0], 10240);

  ShowMessage(Format('接收到数据,长度:%d', [l]));



end;

end.
