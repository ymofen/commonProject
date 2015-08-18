unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, diocp.udp, StdCtrls, ExtCtrls;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    Label1: TLabel;
    btnStart: TButton;
    edtPort: TEdit;
    btnAbout: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

end.
