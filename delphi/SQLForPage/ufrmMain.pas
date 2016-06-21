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
    tsNormalPage: TTabSheet;
    mmoNormalSQL: TMemo;
    btnGetNormalPageSQL: TButton;
    btnGetPageSQL_Mssql: TButton;
    btnRecordCountMssql: TButton;
    btnGetPageSQL_2005: TButton;
    procedure btnGetNormalPageSQLClick(Sender: TObject);
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

procedure TForm1.btnGetNormalPageSQLClick(Sender: TObject);
var
  SqlCommand, TopSqlComm, TmpSqlComm, FetchSQL, sqlStr, TableName:string;
  CompSQLComm:Boolean;
  StrI:Integer;


  PageSize, CurPage:Integer;
begin
  PageSize := 100;
  SqlCommand := mmoNormalSQL.Lines.Text;
  CurPage := StrToInt(edtPageIndex.Text);


  SqlCommand := AnsiLowerCase(AnsiReplaceStr(SqlCommand,'  ',' '));
  CompSQLComm := (Pos(' from ',SqlCommand)>0);      //判断是否为完整SQL语句
  //==================================
  if (PageSize>=20001) And CompSQLComm then
  Begin
      if (AnsiPos(' top ',SqlCommand)>0) then
      Begin
        StrI := AnsiPos(' top ', SqlCommand) + 1;
        TopSqlComm := Copy(SqlCommand, StrI, StrLen(PChar(SqlCommand)));
        StrI := AnsiPos(' ', TopSqlComm) + 1;
        TopSqlComm := Copy(TopSqlComm, StrI, StrLen(PChar(SqlCommand)));
        StrI := AnsiPos(' ', TopSqlComm) + 1;
        TopSqlComm := Copy(TopSqlComm, StrI, StrLen(PChar(SqlCommand)));
      End
      Else
        TopSqlComm := Copy(SqlCommand, 8, StrLen(PChar(SqlCommand)));
      // 获取表字段大小
      TmpSqlComm := 'select top 0 '+ TopSqlComm;
      // 获取一条记录大小
      TmpSqlComm := 'select Top 1 '+ TopSqlComm;
//      if SysQuery.Active then SysQuery.Close;
//      SysQuery.SQL.Text := TmpSqlComm;
//      dsp := TDataSetProvider.Create(nil);
//      cds := TClientDataSet.Create(nil);
//      Dsp.DataSet := SysQuery;
//      cds.Data := dsp.Data;
//      ok := (TableSize + (cds.DataSize - TableSize) * PageSize < 64 * 1024 * 1024);
//      if Not ok  then
//      begin
//        ok := (TableSize + (cds.DataSize - TableSize) * 2000 < 64 * 1024 * 1024);
//        if OK then
//           PageSize := 2000
//        Else
//        Begin
//          ErrorCode:='0206104B';
//          ErrorText:='数据库：['+SysConn.Database+'] '+' 单页查询的数据大小'
//              + FormatFloat('0.00',(TableSize + (cds.DataSize - TableSize) * PageSize) / 1024 / 1024)+'MB 不可大于 64MB 了，建议调整页面大小再做查询....';
//          NodeService.syslog.Log('Err'+ErrorCode+': '+ErrorText+'  '+Err);
//        End;

  end;
  //==============
  if (CurPage<=1) then
  Begin
    FetchSQL := ' OFFSET 0 ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
  End
  Else
  Begin
    FetchSQL := ' OFFSET '+Inttostr((CurPage -1 ) * PageSize + 1)+' ROW FETCH NEXT '+IntToStr(PageSize)+' ROWS ONLY'
  End;

  if CompSQLComm then
  Begin
    if (Pos('order by', SqlCommand)>0) And (AnsiPos(' top ', SqlCommand)<1) then       //判断是否有排序语法 及 Top 语法
    Begin
      sqlStr := SqlCommand + FetchSQL;
    End
    Else
    Begin
      strI := AnsiPos(' from ', SqlCommand) + 1;
      TmpSqlComm := Trim(Copy(SqlCommand, strI + 4, StrLen(PChar(SqlCommand))));
      strI := Pos(' ',TmpSqlComm);
      if (strI=0) then
        TableName := Copy(TmpSqlComm,1,StrLen(PChar(SqlCommand)))
      Else
        TableName := Copy(TmpSqlComm,1,strI);

      if (AnsiPos(' top ',SqlCommand)>0) then
        SQLStr := SqlCommand
      Else
      Begin
        TmpSqlComm := Copy(SqlCommand, 8, StrLen(PChar(SqlCommand)));
        SqlStr := 'select Top 0 '+ TmpSqlComm;
      End;
    End;
  End;


  if CompSQLComm then       //完整SQL语句，就进行总记录数及页数的统计
  Begin
    if (AnsiPos('group by',SqlCommand)>0) then             //判断是否为分组查询语句
    Begin
      StrI := AnsiPos('order by', SqlCommand);
      if (StrI>0) then
        SqlCommand := 'select Count(*) as RecordCount From ('+Copy(SqlCommand,0,StrI -1)+') as a'
      Else
        SqlCommand := 'select Count(*) as RecordCount From ('+SqlCommand+') as a';
    end
    else
    Begin                                                 //非分组查询语句
      strI := AnsiPos(' from', SqlCommand) + 1;
      TmpSqlComm := Trim(Copy(SqlCommand, strI, StrLen(PChar(SqlCommand))));
      if (AnsiPos('order by', SqlCommand)>0) then
      begin
        strI := AnsiPos('order by', TmpSqlComm);
        TmpSqlComm := Copy(TmpSqlComm,0,StrI - 1);
      End;
      SqlCommand := 'select count(*) AS RecordCount '+ TmpSqlComm;
    End;
  End;
  

  mmoSQL.Lines.Text := sqlStr;
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
  lvPageSQLMaker:TPageMSSQLMaker;
begin
  lvPageSQLMaker := TPageMSSQLMaker.Create;
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
  lvPageSQLMaker:TPageMSSQLMaker;
begin
  lvPageSQLMaker := TPageMSSQLMaker.Create;
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
