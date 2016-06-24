unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, PageSQLMaker, StrUtils;

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
    tsTemplateSQL: TTabSheet;
    mmoNormalSQL: TMemo;
    btnGetPageSQL2012_Template: TButton;
    btnGetPageSQL_Mssql: TButton;
    btnRecordCountMssql: TButton;
    btnGetPageSQL_2005: TButton;
    procedure btnGetPageSQL2012_TemplateClick(Sender: TObject);
    procedure btnGetPageSQLClick(Sender: TObject);
    procedure btnGetPageSQL_2005Click(Sender: TObject);
    procedure btnGetPageSQL_MssqlClick(Sender: TObject);
    procedure btnRecordCountMssqlClick(Sender: TObject);
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

procedure TForm1.btnGetPageSQL2012_TemplateClick(Sender: TObject);
var
  lvPageSQLMaker:TPageMSSQLMaker2012;
begin
  lvPageSQLMaker := TPageMSSQLMaker2012.Create;
  lvPageSQLMaker.SelectFields := '*';
  lvPageSQLMaker.PageSize := 50;
  lvPageSQLMaker.PrimaryKey := 'FCode';
  lvPageSQLMaker.TableName := 'bas_Goods';
  lvPageSQLMaker.SortType := 2;
  mmoSQL.Lines.Add(lvPageSQLMaker.GetPageSQL(StrToInt(edtPageIndex.Text)));
  lvPageSQLMaker.Free;

end;

procedure TForm1.btnGetPageSQLClick(Sender: TObject);
begin
  FSQLMaker.TemplateSQL := mmoTemplate.Lines.Text;
  mmoSQL.Lines.Add(FSQLMaker.GetPageSQL(StrToInt(edtPageIndex.Text)));

end;

procedure TForm1.btnGetPageSQL_2005Click(Sender: TObject);
var
  lvPageSQLMaker:TPageMSSQLMaker2005;
begin
  lvPageSQLMaker := TPageMSSQLMaker2005.Create;
  lvPageSQLMaker.SelectFields := '*';
  lvPageSQLMaker.PageSize := 50;
  lvPageSQLMaker.PrimaryKey := 'FCode';
  lvPageSQLMaker.TableName := 'bas_Goods';
  lvPageSQLMaker.SortType := 2;
  mmoSQL.Lines.Add(lvPageSQLMaker.GetPageSQL(StrToInt(edtPageIndex.Text)));
  lvPageSQLMaker.Free;

end;

procedure TForm1.btnGetPageSQL_MssqlClick(Sender: TObject);
var
  lvPageSQLMaker:TPageMSSQLMaker2012;
begin
  lvPageSQLMaker := TPageMSSQLMaker2012.Create;
  lvPageSQLMaker.SelectFields := '*';
  lvPageSQLMaker.PageSize := 50;
  lvPageSQLMaker.PrimaryKey := 'FCode';
  lvPageSQLMaker.TableName := 'bas_Goods';
  lvPageSQLMaker.SortType := 2;
  mmoSQL.Lines.Add(lvPageSQLMaker.GetPageSQL(StrToInt(edtPageIndex.Text)));
  lvPageSQLMaker.Free;


end;

procedure TForm1.btnRecordCountMssqlClick(Sender: TObject);
var
  lvPageSQLMaker:TPageMSSQLMaker2012;
begin
  lvPageSQLMaker := TPageMSSQLMaker2012.Create;
  lvPageSQLMaker.SelectFields := '*';
  lvPageSQLMaker.PageSize := 50;
  lvPageSQLMaker.PrimaryKey := 'FCode';
  lvPageSQLMaker.TableName := 'bas_Goods';
  lvPageSQLMaker.SortType := 2;
  mmoSQL.Lines.Add(lvPageSQLMaker.GetRecordCounterSQL());
  lvPageSQLMaker.Free;


end;

procedure TForm1.btnRecordCountSQLClick(Sender: TObject);
begin
  FSQLMaker.TemplateSQL := mmoTemplate.Lines.Text;

  mmoSQL.Lines.Add(FSQLMaker.GetRecordCounterSQL);

end;

end.
