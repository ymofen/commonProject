unit MongoDBAPI;

interface

uses
  DriverMongo;

implementation

initialization
  mongoc_init();

finalization
  mongoc_cleanup();

end.
