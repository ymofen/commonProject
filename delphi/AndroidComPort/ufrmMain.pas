unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.ScrollBox, FMX.Memo;

type
  TForm1 = class(TForm)
    btnOpen: TButton;
    btnRecvBuffer: TButton;
    edtPortName: TEdit;
    pnlTop: TPanel;
    pnlBottom: TPanel;
    edtSend: TEdit;
    btnSendBuffer: TButton;
    mmoRecv: TMemo;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnRecvBufferClick(Sender: TObject);
    procedure btnSendBufferClick(Sender: TObject);
  private
    FHandle:Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  posix_serialPort;


{$R *.fmx}

procedure TForm1.btnCloseClick(Sender: TObject);
begin
  CloseSerialPort(FHandle);
  FHandle := 0;
  btnOpen.Enabled := True;

  btnClose.Enabled := not btnOpen.Enabled;
end;

procedure TForm1.btnOpenClick(Sender: TObject);
var
  r:Integer;
  lvBytes:TBytes;
begin
  if FHandle <= 0 then
  begin
    FHandle := OpenSerialPort(edtPortName.Text);
    CheckSerialOperaResult(FHandle);
    r := ConfigSerialPort(FHandle, br9600, fcNone, db8Bits, sb1, spNone);
    if r <> 0 then
    begin
      CheckSerialOperaResult(r);
    end;
    showMessage('打开端口成功，可以读取数据');

    btnOpen.Enabled := False;
    btnClose.Enabled := not btnOpen.Enabled;
  end;
end;

procedure TForm1.btnRecvBufferClick(Sender: TObject);
var
  lvBytes:TBytes;
  r:Integer;
begin
  if FHandle <=0 then raise Exception.Create('请先打开串口');

  SetLength(lvBytes, 10240);
  r := ReadSerialPort(FHandle, @lvBytes[0], 10240);
  CheckSerialOperaResult(r);

  mmoRecv.Lines.Add(TEncoding.Default.GetString(lvBytes));
end;

procedure TForm1.btnSendBufferClick(Sender: TObject);
var
  lvBytes:TBytes;
  r:Integer;
begin
  if FHandle <=0 then raise Exception.Create('请先打开串口');

  lvBytes := TEncoding.Default.GetBytes(edtSend.Text);
  r := WriteSerialPort(FHandle, @lvBytes[0], Length(lvBytes));
  CheckSerialOperaResult(r);
end;

end.
