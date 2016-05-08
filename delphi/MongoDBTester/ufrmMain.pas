unit ufrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DriverMongo, DriverBson, ComObj;

type
  TfrmMain = class(TForm)
    pnlConnect: TPanel;
    edtHost: TEdit;
    btnConnect: TButton;
    btnInsert: TButton;
    btnFindOne: TButton;
    btnBatchInsert: TButton;
    edtCounter: TEdit;
    btnInsertBigBson: TButton;
    btnBson: TButton;
    edtCollection: TEdit;
    procedure btnBatchInsertClick(Sender: TObject);
    procedure btnBsonClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnFindOneClick(Sender: TObject);
    procedure btnInsertBigBsonClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
  private
    { Private declarations }
    FMongoClient:PMongocClient;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnBatchInsertClick(Sender: TObject);
var
  lvURI, lvValue:AnsiString;
  lvBson:PBson;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
  i, j: Integer;
  t: Cardinal;
  lvBsonArr:array of PBson;

begin
  if FMongoClient = nil then raise Exception.Create('请先建立连接');

  lvdatabase := mongoc_client_get_database(FMongoClient, 'qt_db');
  lvValue := edtCollection.Text;
  lvCollection := mongoc_client_get_collection(FMongoClient, 'qt_db', PAnsiChar(lvValue));

  t := GetTickCount;
  try
    j := StrToInt(edtCounter.Text);
    SetLength(lvBsonArr, j);
    for i := 0 to j -1 do
    begin
      lvValue := CreateClassID;
      lvBson := bson_new();
      bson_init(lvBson);
      bson_append_utf8(lvBson, 'key', 3, PAnsiChar(lvValue), Length(lvValue));
      lvBsonArr[i] := lvBson;
    end;

    if (not mongoc_collection_insert_bulk(lvCollection, MONGOC_INSERT_NONE, @lvBsonArr[0], j, nil, lvErr)) then
    begin
      ShowMessage(lvErr.message);
      Exit;
    end;
  finally
  end;
  ShowMessage(Format('count:%d, time:%d', [i, GetTickCount-t]));
end;

procedure TfrmMain.btnBsonClick(Sender: TObject);
const
  DATA_LENGTH = 1024 * 1024 * 15;
var
  lvURI, lvValue, lvChildValue:AnsiString;
  lvBson, lvBson1, lvBson2, lvList:PBson;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
  i: Integer;
  lvLength: size_t;
  lvBuff:PAnsiChar;
begin
  lvBson := bson_new();
  try
    bson_init(lvBson);
    SetLength(lvChildValue, 1024 * 1024 * 1);
    FillChar(lvChildValue[1], 1024 * 1024 * 1, ord('1'));

    lvValue := '{"appid":"1001汉字","v1":"' + lvChildValue + '", "clients":[{"id":1001},{"id":1002}]}';
    if not bson_init_from_json(lvBson, PAnsiChar(lvValue), Length(lvValue), lvErr) then
    begin
      ShowMessage(lvErr.message);
      exit;
    end;

    lvBuff := bson_as_json(lvBson, lvLength);

    bson_free(lvBuff);
    //ShowMessage(lvBuff);

  finally
    bson_destroy(lvBson);
  end;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var
  lvURI:AnsiString;
  lvBson:PBson;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
//  lvCommand:

begin
  lvURI := edtHost.Text;
  FMongoClient := mongoc_client_new(PAnsiChar(lvURI));
  if FMongoClient = nil then
  begin
    raise Exception.Create('connect fail');
  end;

//
//   insert = BCON_NEW ("hello", BCON_UTF8 ("world"));
//
//   if (!mongoc_collection_insert (collection, MONGOC_INSERT_NONE, insert, NULL, &error)) {
//      fprintf (stderr, "%s\n", error.message);
//   }
//
//   bson_destroy (insert);
//   bson_destroy (&reply);
//   bson_destroy (command);
//   bson_free (str);
//
//   /*
//    * Release our handles and clean up libmongoc
//    */
//   mongoc_collection_destroy (collection);
//   mongoc_database_destroy (database);
//   mongoc_client_destroy (client);
//   mongoc_cleanup ();


end;

procedure TfrmMain.btnFindOneClick(Sender: TObject);
var
  lvURI:AnsiString;
  lvBson:PBson;
  lvBsonArr:TBsonArray;
  lvCursor:PMongocCursor;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
  lvLength: size_t;
  lvBuff:PAnsiChar;
begin
  if FMongoClient = nil then raise Exception.Create('请先建立连接');

  lvCollection := mongoc_client_get_collection(FMongoClient, 'core', 'apps');

  lvBson := bson_new();
  bson_init(lvBson);

  lvCursor := mongoc_collection_find(lvCollection, MONGOC_QUERY_NONE, 0, 0, 0, lvBson, nil, nil);


  while (mongoc_cursor_next(lvCursor, @lvBsonArr)) do
  begin
    lvLength := 0;
    lvBuff := bson_as_json(lvBsonArr[0], lvLength);
    ShowMessage(lvBuff);
  end;


//
//
//  lvBson := bson_new();
//  bson_init(lvBson);
//  bson_append_utf8(lvBson, 'key', 3, 'hello world', 11);
//
//  if (not mongoc_collection_insert(lvCollection, MONGOC_INSERT_NONE, lvBson, nil, lvErr)) then
//  begin
//    ShowMessage(lvErr.message);
//  end;


end;

procedure TfrmMain.btnInsertBigBsonClick(Sender: TObject);
const
  DATA_LENGTH = 1024 * 1024 * 15;
var
  lvURI, lvValue:AnsiString;
  lvBson, lvBson1, lvBson2, lvList:PBson;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
  i: Integer;
  lvLength: size_t;
  lvBuff:PAnsiChar;
begin
  if FMongoClient = nil then raise Exception.Create('请先建立连接');

  lvdatabase := mongoc_client_get_database(FMongoClient, 'qt_db');
  lvCollection := mongoc_client_get_collection(FMongoClient, 'qt_db', 'apps2');
  lvValue := CreateClassID;
  lvBson := bson_new();
  lvList := bson_new();
  lvBson1 := bson_new();
  lvBson2 := bson_new();
  try
    bson_init(lvBson);
    bson_init(lvBson1);
    bson_init(lvBson2);
    bson_init(lvList);

    bson_append_utf8(lvBson, 'key', 3, PAnsiChar(lvValue), Length(lvValue));


    SetLength(lvValue, DATA_LENGTH);
    FillChar(lvValue[1], DATA_LENGTH, Ord('1'));
    bson_append_utf8(lvBson1, 'data1', 5, PAnsiChar(lvValue), Length(lvValue));

    SetLength(lvValue, DATA_LENGTH);
    FillChar(lvValue[1], DATA_LENGTH, Ord('2'));
    bson_append_utf8(lvBson2, 'data2', 5, PAnsiChar(lvValue), Length(lvValue));

    bson_append_array_begin(lvBson, 'clts', 4, lvList);

    bson_append_document(lvList, '0', -1, lvBson1);
    bson_append_document(lvList, '1', -1, lvBson2);

    bson_append_array_end(lvBson, lvList);
    //bson_append_document(lvList, )
//
//    bson_append_document(lvBson, 'clt1', 4, lvBson1);
//    bson_append_document(lvBson, 'clt2', 4, lvBson2);
//    lvLength := 10240;
//    lvBuff := bson_as_json(lvBson, lvLength);
//    ShowMessage(lvBuff);
    if (not mongoc_collection_insert(lvCollection, MONGOC_INSERT_NONE, lvBson, nil, lvErr)) then
    begin
      ShowMessage(lvErr.message);
      Exit;
    end;
  finally
    bson_destroy(lvBson);
  end;


end;

procedure TfrmMain.btnInsertClick(Sender: TObject);
var
  lvURI:AnsiString;
  lvBson:PBson;
  lvErr:TBsonError;
  lvdatabase:PMongocDatabase;
  lvCollection:PMongocCollection;
begin
  if FMongoClient = nil then raise Exception.Create('请先建立连接');

  //lvdatabase := mongoc_client_get_database(FMongoClient, 'qt_db');
  lvCollection := mongoc_client_get_collection(FMongoClient, 'qt_db', 'apps.clients');

  lvBson := bson_new();
  bson_init(lvBson);
  bson_append_utf8(lvBson, 'key', 3, 'hello world', 11);

  if (not mongoc_collection_insert(lvCollection, MONGOC_INSERT_NONE, lvBson, nil, lvErr)) then
  begin
    ShowMessage(lvErr.message);
  end;

end;

end.
