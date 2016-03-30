unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, PageSQLMaker;

type
  TForm1 = class(TForm)
    pnlTop: TPanel;
    pgcMain: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    mmoSQL: TMemo;
    mmoTemplate: TMemo;
    btnGetPageSQL: TButton;
    btnRecordCountSQL: TButton;
    edtPageIndex: TEdit;
    procedure btnGetPageSQLClick(Sender: TObject);
    procedure btnRecordCountSQLClick(Sender: TObject);
  private
    { Private declarations }
    FSQLMaker: TPageSQLMaker;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQLMaker := TPageMySQLMaker.Create();
  FSQLMaker.PageSize := 5;
end;

destructor TForm1.Destroy;
begin
  FreeAndNil(FSQLMaker);
  inherited Destroy;
end;

procedure TForm1.btnGetPageSQLClick(Sender: TObject);
begin
  FSQLMaker.TemplateSQL := mmoTemplate.Lines.Text;
  mmoSQL.Lines.Add(FSQLMaker.GetPageSQL(StrToInt(edtPageIndex.Text)));

end;

procedure TForm1.btnRecordCountSQLClick(Sender: TObject);
begin
  FSQLMaker.TemplateSQL := mmoTemplate.Lines.Text;

  mmoSQL.Lines.Add(FSQLMaker.GetRecordCounterSQL);

end;

end.
