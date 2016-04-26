// Convert From Mongo-c-driver 1.3.5
// Hezihang @cnblogs.com
unit DriverMongo;

interface

uses DriverBson, Winapi.winsock2;

// mongoc_flags.h
type
  // *
  // * mongoc_delete_flags_t:
  // * @MONGOC_DELETE_NONE: Specify no delete flags.
  // * @MONGOC_DELETE_SINGLE_REMOVE: Only remove the first document matching the
  // * document selector.
  // *
  // * This type is only for use with deprecated functions and should not be
  // * used in new code. Use mongoc_remove_flags_t instead.
  // *
  // * #mongoc_delete_flags_t are used when performing a delete operation.
  // *
  mongoc_delete_flags_t = (MONGOC_DELETE_NONE = 0, MONGOC_DELETE_SINGLE_REMOVE = 1 shl 0);

  // *
  // * mongoc_remove_flags_t:
  // * @MONGOC_REMOVE_NONE: Specify no delete flags.
  // * @MONGOC_REMOVE_SINGLE_REMOVE: Only remove the first document matching the
  // * document selector.
  // *
  // * #mongoc_remove_flags_t are used when performing a remove operation.
  // *
  mongoc_remove_flags_t = (MONGOC_REMOVE_NONE = 0, MONGOC_REMOVE_SINGLE_REMOVE = 1 shl 0);

  // *
  // * mongoc_insert_flags_t:
  // * @MONGOC_INSERT_NONE: Specify no insert flags.
  // * @MONGOC_INSERT_CONTINUE_ON_ERROR: Continue inserting documents from
  // * the insertion set even if one fails.
  // *
  // * #mongoc_insert_flags_t are used when performing an insert operation.
  // *
  mongoc_insert_flags_t = (MONGOC_INSERT_NONE = 0, MONGOC_INSERT_CONTINUE_ON_ERROR = 1 shl 0);

const
  MONGOC_INSERT_NO_VALIDATE = (1 shl 31);

type
  // *
  // * mongoc_query_flags_t:
  // * @MONGOC_QUERY_NONE: No query flags supplied.
  // * @MONGOC_QUERY_TAILABLE_CURSOR: Cursor will not be closed when the last
  // * data is retrieved. You can resume this cursor later.
  // * @MONGOC_QUERY_SLAVE_OK: Allow query of replica slave.
  // * @MONGOC_QUERY_OPLOG_REPLAY: Used internally by Mongo.
  // * @MONGOC_QUERY_NO_CURSOR_TIMEOUT: The server normally times out idle
  // * cursors after an inactivity period (10 minutes). This prevents that.
  // * @MONGOC_QUERY_AWAIT_DATA: Use with %MONGOC_QUERY_TAILABLE_CURSOR. Block
  // * rather than returning no data. After a period, time out.
  // * @MONGOC_QUERY_EXHAUST: Stream the data down full blast in multiple
  // * "more" packages. Faster when you are pulling a lot of data and
  // * know you want to pull it all down.
  // * @MONGOC_QUERY_PARTIAL: Get partial results from mongos if some shards
  // * are down (instead of throwing an error).
  // *
  // * #mongoc_query_flags_t is used for querying a Mongo instance.
  // *
  mongoc_query_flags_t = (MONGOC_QUERY_NONE = 0, MONGOC_QUERY_TAILABLE_CURSOR = 1 shl 1, MONGOC_QUERY_SLAVE_OK = 1 shl 2, MONGOC_QUERY_OPLOG_REPLAY = 1 shl 3,
    MONGOC_QUERY_NO_CURSOR_TIMEOUT = 1 shl 4, MONGOC_QUERY_AWAIT_DATA = 1 shl 5, MONGOC_QUERY_EXHAUST = 1 shl 6, MONGOC_QUERY_PARTIAL = 1 shl 7);

  // *
  // * mongoc_reply_flags_t:
  // * @MONGOC_REPLY_NONE: No flags set.
  // * @MONGOC_REPLY_CURSOR_NOT_FOUND: Cursor was not found.
  // * @MONGOC_REPLY_QUERY_FAILURE: Query failed, error document provided.
  // * @MONGOC_REPLY_SHARD_CONFIG_STALE: Shard configuration is stale.
  // * @MONGOC_REPLY_AWAIT_CAPABLE: Wait for data to be returned until timeout
  // * has passed. Used with %MONGOC_QUERY_TAILABLE_CURSOR.
  // *
  // * #mongoc_reply_flags_t contains flags supplied by the Mongo server in reply
  // * to a request.
  // *
  mongoc_reply_flags_t = (MONGOC_REPLY_NONE = 0, MONGOC_REPLY_CURSOR_NOT_FOUND = 1 shl 0, MONGOC_REPLY_QUERY_FAILURE = 1 shl 1,
    MONGOC_REPLY_SHARD_CONFIG_STALE = 1 shl 2, MONGOC_REPLY_AWAIT_CAPABLE = 1 shl 3);

  // *
  // * mongoc_update_flags_t:
  // * @MONGOC_UPDATE_NONE: No update flags specified.
  // * @MONGOC_UPDATE_UPSERT: Perform an upsert.
  // * @MONGOC_UPDATE_MULTI_UPDATE: Continue updating after first match.
  // *
  // * #mongoc_update_flags_t is used when updating documents found in Mongo.
  // *
  mongoc_update_flags_t = (MONGOC_UPDATE_NONE = 0, MONGOC_UPDATE_UPSERT = 1 shl 0, MONGOC_UPDATE_MULTI_UPDATE = 1 shl 1);

const
  MONGOC_UPDATE_NO_VALIDATE = (1 shl 31);

  // mongoc_read_concern.h
type
  PMongocReadConcern = Pointer;

function mongoc_read_concern_new: PMongocReadConcern; cdecl;
function mongoc_read_concern_copy(const read_concern: PMongocReadConcern): PMongocReadConcern; cdecl;
procedure mongoc_read_concern_destroy(read_concern: PMongocReadConcern); cdecl;
function mongoc_read_concern_get_level(const read_concern: PMongocReadConcern): PAnsiChar; cdecl;
function mongoc_read_concern_set_level(read_concern: PMongocReadConcern; const level: PAnsiChar): Boolean; cdecl;



// mongoc_write_concern.h

const
  MONGOC_WRITE_CONCERN_W_UNACKNOWLEDGED = 0;
  MONGOC_WRITE_CONCERN_W_ERRORS_IGNORED = -1; // * deprecated *
  MONGOC_WRITE_CONCERN_W_DEFAULT = -2;
  MONGOC_WRITE_CONCERN_W_MAJORITY = -3;
  MONGOC_WRITE_CONCERN_W_TAG = -4;

type
  PMongocWriteConcern = Pointer;

function mongoc_write_concern_new(): PMongocWriteConcern; cdecl;
function mongoc_write_concern_copy(const write_concern: PMongocWriteConcern): PMongocWriteConcern; cdecl;
procedure mongoc_write_concern_destroy(write_concern: PMongocWriteConcern); cdecl;
function mongoc_write_concern_get_fsync(const write_concern: PMongocWriteConcern): Boolean; cdecl;
procedure mongoc_write_concern_set_fsync(write_concern: PMongocWriteConcern; fsync_: Boolean); cdecl;
function mongoc_write_concern_get_journal(const write_concern: PMongocWriteConcern): Boolean; cdecl;
procedure mongoc_write_concern_set_journal(write_concern: PMongocWriteConcern; journal: Boolean); cdecl;
function mongoc_write_concern_get_w(const write_concern: PMongocWriteConcern): Int32; cdecl;
procedure mongoc_write_concern_set_w(write_concern: PMongocWriteConcern; w: Int32); cdecl;

function mongoc_write_concern_get_wtag(const write_concern: PMongocWriteConcern): PAnsiChar; cdecl;
procedure mongoc_write_concern_set_wtag(write_concern: PMongocWriteConcern; const tag: Pointer); cdecl;
function mongoc_write_concern_get_wtimeout(const write_concern: PMongocWriteConcern): Int32; cdecl;
procedure mongoc_write_concern_set_wtimeout(write_concern: PMongocWriteConcern; wtimeout_msec: Int32); cdecl;
function mongoc_write_concern_get_wmajority(const write_concern: PMongocWriteConcern): Boolean; cdecl;
procedure mongoc_write_concern_set_wmajority(write_concern: PMongocWriteConcern; wtimeout_msec: Int32); cdecl;



// mongo-bulk-operation.h

type
  PMongocBulkOperation = Pointer;

procedure mongoc_bulk_operation_destroy(bulk: PMongocBulkOperation); cdecl;
function mongoc_bulk_operation_execute(bulk: PMongocBulkOperation; reply: PBson; var error: TBsonError): UInt32; cdecl;
procedure mongoc_bulk_operation_delete(bulk: PMongocBulkOperation; const selector: PBson); cdecl;
procedure mongoc_bulk_operation_delete_one(bulk: PMongocBulkOperation; const selector: PBson); cdecl;
procedure mongoc_bulk_operation_insert(bulk: PMongocBulkOperation; const document: PBson); cdecl;
procedure mongoc_bulk_operation_remove(bulk: PMongocBulkOperation; const selector: PBson); cdecl;
procedure mongoc_bulk_operation_remove_one(bulk: PMongocBulkOperation; const selector: PBson); cdecl;
procedure mongoc_bulk_operation_replace_one(bulk: PMongocBulkOperation; const selector: PBson; const document: PBson; upsert: Boolean); cdecl;
procedure mongoc_bulk_operation_update(bulk: PMongocBulkOperation; const selector: PBson; const document: PBson; upsert: Boolean); cdecl;
procedure mongoc_bulk_operation_update_one(bulk: PMongocBulkOperation; const selector: PBson; const document: PBson; upsert: Boolean); cdecl;
procedure mongoc_bulk_operation_set_bypass_document_validation(bulk: PMongocBulkOperation; bypass: Boolean); cdecl;


//
// The following functions are really only useful by language bindings and
// those wanting to replay a bulk operation to a number of clients or
// collections.
//

function mongoc_bulk_operation_new(ordered: Boolean): PMongocBulkOperation; cdecl;
procedure mongoc_bulk_operation_set_write_concern(bulk: PMongocBulkOperation; const write_concern: PMongocWriteConcern); cdecl;
procedure mongoc_bulk_operation_set_database(bulk: PMongocBulkOperation; const database: PAnsiChar); cdecl;
procedure mongoc_bulk_operation_set_collection(bulk: PMongocBulkOperation; const collection: PAnsiChar); cdecl;
procedure mongoc_bulk_operation_set_client(bulk: PMongocBulkOperation; client: Pointer); cdecl;
procedure mongoc_bulk_operation_set_hint(bulk: PMongocBulkOperation; hint: UInt32); cdecl;
function mongoc_bulk_operation_get_write_concern(const bulk: PMongocBulkOperation): PMongocWriteConcern; cdecl;



// mongoc_index.h

type
  TMongocIndexOptGeo = record
    twod_sphere_version: Byte;
    twod_bits_precision: Byte;
    twod_location_min: Double;
    twod_location_max: Double;
    haystack_bucket_size: Double;
    padding: array [0 .. 31] of Pointer;
  end;

  PMongocIndexOptGeo = ^TMongocIndexOptGeo;

  TMongocIndexOptStorage = record
    _type: Integer;
  end;

  PMongocIndexOptStorage = ^TMongocIndexOptStorage;

  TMongocIndexStorageOptType = (MONGOC_INDEX_STORAGE_OPT_MMAPV1, MONGOC_INDEX_STORAGE_OPT_WIREDTIGER);

  TMongocIndexOptWt = record
    base: TMongocIndexOptStorage;
    config_str: PAnsiChar;
    padding: array [0 .. 7] of Pointer;
  end;

  PMongocIndexOptWt = ^TMongocIndexOptWt;

  TMongocIndexOpt = record
    is_initialized: Boolean;
    background: Boolean;
    unique: Boolean;
    name: PAnsiChar;
    drop_dups: Boolean;
    sparse: Boolean;
    expire_after_seconds: Int32;
    v: Int32;
    weights: PBson;
    default_language: PAnsiChar;
    language_override: PAnsiChar;
    geo_options: PMongocIndexOptGeo;
    storage_options: PMongocIndexOptStorage;
    partial_filter_expression: PBson;
    padding: array [0 .. 4] of Pointer;
  end;

  PMongocIndexOpt = ^TMongocIndexOpt;

function mongoc_index_opt_get_default: PMongocIndexOpt; cdecl;
function mongoc_index_opt_geo_get_default: PMongocIndexOptGeo; cdecl;
function mongoc_index_opt_wt_get_default: PMongocIndexOptWt; cdecl;
procedure mongoc_index_opt_init(opt: PMongocIndexOpt); cdecl;
procedure mongoc_index_opt_geo_init(opt: PMongocIndexOptGeo); cdecl;
procedure mongoc_index_opt_wt_init(opt: PMongocIndexOptWt); cdecl;

// mongoc_read_prefs.h
type
  PMongocReadPrefs = Pointer;

type
  TMongocReadMode = (MONGOC_READ_PRIMARY = (1 shl 0), MONGOC_READ_SECONDARY = (1 shl 1), MONGOC_READ_PRIMARY_PREFERRED = (1 shl 2) or MONGOC_READ_PRIMARY,
    MONGOC_READ_SECONDARY_PREFERRED = (1 shl 2) or MONGOC_READ_SECONDARY, MONGOC_READ_NEAREST = (1 shl 3) or MONGOC_READ_SECONDARY);

function mongoc_read_prefs_new(read_mode: TMongocReadMode): PMongocReadPrefs; cdecl;
function mongoc_read_prefs_copy(const read_prefs): PMongocReadPrefs; cdecl;
procedure mongoc_read_prefs_destroy(read_prefs: PMongocReadPrefs); cdecl;
function mongoc_read_prefs_get_mode(const read_prefs: PMongocReadPrefs): TMongocReadMode; cdecl;
procedure mongoc_read_prefs_set_mode(read_prefs: PMongocReadPrefs; mode: TMongocReadMode); cdecl;
function mongoc_read_prefs_get_tags(const read_prefs: PMongocReadPrefs): PBson; cdecl;
procedure mongoc_read_prefs_set_tags(read_prefs: PMongocReadPrefs; const tags: PBson); cdecl;
procedure mongoc_read_prefs_add_tag(read_prefs: PMongocReadPrefs; const tag: PBson); cdecl;
function mongoc_read_prefs_is_valid(const read_prefs: PMongocReadPrefs): Boolean; cdecl;




// mongoc_uri.h

type
  PMongocUri = Pointer;
  PMongocHostList = Pointer;

function mongoc_uri_copy(const uri: PMongocUri): PMongocUri; cdecl;
procedure mongoc_uri_destroy(uri: PMongocUri); cdecl;
function mongoc_uri_new(const uri_string: PAnsiChar): PMongocUri; cdecl;
function mongoc_uri_new_for_host_port(const hostname: PAnsiChar; port: UInt16): PMongocUri; cdecl;
function mongoc_uri_get_hosts(const uri: PMongocUri): PMongocHostList; cdecl;
function mongoc_uri_get_database(const uri: PMongocUri): PAnsiChar; cdecl;
function mongoc_uri_get_options(const uri: PMongocUri): PBson; cdecl;
function mongoc_uri_get_password(const uri: PMongocUri): PAnsiChar; cdecl;
function mongoc_uri_get_read_prefs(const uri: PMongocUri): PBson; cdecl;
function mongoc_uri_get_read_prefs_t(const uri: PMongocUri): PBson; cdecl;

function mongoc_uri_get_replica_set(const uri: PMongocUri): PAnsiChar; cdecl;

function mongoc_uri_get_string(const uri: PMongocUri): PAnsiChar; cdecl;

function mongoc_uri_get_username(const uri: PMongocUri): PAnsiChar; cdecl;

function mongoc_uri_get_credentials(const uri: PMongocUri): PBson; cdecl;

function mongoc_uri_get_auth_source(const uri: PMongocUri): PAnsiChar; cdecl;

function mongoc_uri_get_auth_mechanism(const uri: PMongocUri): PAnsiChar; cdecl;
function mongoc_uri_get_mechanism_properties(const uri: PMongocUri; properties: PBson): Boolean; cdecl;
function mongoc_uri_get_ssl(const uri: PMongocUri): Boolean; cdecl;
function mongoc_uri_unescape(const escaped_string: PAnsiChar): PAnsiChar; cdecl;



// function mongoc_uri_get_read_prefs_t(const uri: PMongocUri): PMongocReadPrefs;

function mongoc_uri_get_write_concern(const uri: PMongocUri): PMongocWriteConcern; cdecl;
function mongoc_uri_get_read_concern(const uri: PMongocUri): PMongocReadConcern; cdecl;

// mongoc_cursor.h
type
  PMongocCursor = Pointer;

function mongoc_cursor_clone(const cursor: PMongocCursor): PMongocCursor; cdecl;

procedure mongoc_cursor_destroy(cursor: PMongocCursor); cdecl;
function mongoc_cursor_more(cursor: PMongocCursor): Boolean; cdecl;
function mongoc_cursor_next(cursor: PMongocCursor; const bson_t: PBsonArray): Boolean; cdecl;

function mongoc_cursor_error(cursor: PMongocCursor; var error: TBsonError): Boolean; cdecl;
procedure mongoc_cursor_get_host(cursor: PMongocCursor; host: PMongocHostList); cdecl;
function mongoc_cursor_is_alive(const cursor: PMongocCursor): Boolean; cdecl;

function mongoc_cursor_current(const cursor: PMongocCursor): PBson; cdecl;
procedure mongoc_cursor_set_batch_size(cursor: PMongocCursor; batch_size: UInt32); cdecl;
function mongoc_cursor_get_batch_size(const cursor: PMongocCursor): UInt32; cdecl;
function mongoc_cursor_get_hint(const cursor: PMongocCursor): UInt32; cdecl;
function mongoc_cursor_get_id(const cursor: PMongocCursor): Int64; cdecl;
procedure mongoc_cursor_set_max_await_time_ms(cursor: PMongocCursor; max_await_time_ms: UInt32); cdecl;
function mongoc_cursor_get_max_await_time_ms(const cursor: PMongocCursor): UInt32; cdecl;






// mongoc_gridfs_file.h

type
  PMongocGridfsFile = Pointer;

  TMongocGridfsFileOpt = record
    md5: PAnsiChar;
    filename: PAnsiChar;
    content_type: PAnsiChar;
    aliases: PBson;
    metadata: PBson;
    chunk_size: UInt32;
  end;

  PMongocIovec = Pointer;

function mongoc_gridfs_file_get_md5(_file: PMongocGridfsFile): PAnsiChar; cdecl;
procedure mongoc_gridfs_file_set_md5(_file: PMongocGridfsFile; const str: PAnsiChar); cdecl;
function mongoc_gridfs_file_get_filename(_file: PMongocGridfsFile): PAnsiChar; cdecl;
procedure mongoc_gridfs_file_set_filename(_file: PMongocGridfsFile; const str: PAnsiChar); cdecl;
function mongoc_gridfs_file_get_content_type(_file: PMongocGridfsFile): PAnsiChar; cdecl;
procedure mongoc_gridfs_file_set_content_type(_file: PMongocGridfsFile; const str: PAnsiChar); cdecl;
function mongoc_gridfs_file_get_aliases(_file: PMongocGridfsFile): PAnsiChar; cdecl;
procedure mongoc_gridfs_file_set_aliases(_file: PMongocGridfsFile; const str: PAnsiChar); cdecl;
function mongoc_gridfs_file_get_metadata(_file: PMongocGridfsFile): PAnsiChar; cdecl;
procedure mongoc_gridfs_file_set_metadata(_file: PMongocGridfsFile; const str: PAnsiChar); cdecl;
function mongoc_gridfs_file_get_id(_file: PMongocGridfsFile): PBsonValue; cdecl;
function mongoc_gridfs_file_get_length(_file: PMongocGridfsFile): Int64; cdecl;
function mongoc_gridfs_file_get_chunk_size(_file: PMongocGridfsFile): Int32; cdecl;
function mongoc_gridfs_file_get_upload_date(_file: PMongocGridfsFile): Int64; cdecl;
function mongoc_gridfs_file_writev(_file: PMongocGridfsFile; iov: PMongocIovec; iovcnt: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_gridfs_file_readv(_file: PMongocGridfsFile; iov: PMongocIovec; iovcnt: size_t; min_bytes: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_gridfs_file_seek(_file: PMongocGridfsFile; delta: Int64; whence: Integer): Integer; cdecl;
function mongoc_gridfs_file_tell(_file: PMongocGridfsFile): Int64; cdecl;
function mongoc_gridfs_file_save(_file: PMongocGridfsFile): Boolean; cdecl;
procedure mongoc_gridfs_file_destroy(_file: PMongocGridfsFile); cdecl;
function mongoc_gridfs_file_error(_file: PMongocGridfsFile; var error: TBsonError): Boolean; cdecl;
function mongoc_gridfs_file_remove(_file: PMongocGridfsFile; var error: TBsonError): Boolean; cdecl;





// mongoc_gridfs_file_list.h

type
  PMongocGridfsFileList = Pointer;

function mongoc_gridfs_file_list_next(list: PMongocGridfsFileList): PMongocGridfsFile; cdecl;
procedure mongoc_gridfs_file_list_destroy(list: PMongocGridfsFileList); cdecl;
function mongoc_gridfs_file_list_error(list: PMongocGridfsFileList; var error: TBsonError): Boolean; cdecl;




// mongoc_socket.h

type
  PMongocSocket = Pointer;

  TMongocSocketPoll = record
    socket: PMongocSocket;
    events: Integer;
    revents: Integer;
  end;

  socklen_t = NativeInt;

  PMongocSocketPoll = Pointer;

function mongoc_socket_accept(sock: PMongocSocket; expire_at: Int64): PMongocSocket; cdecl;
function mongoc_socket_bind(sock: PMongocSocket; const addr: psockaddr; addrlen: socklen_t): Integer; cdecl;
function mongoc_socket_close(sock: PMongocSocket): Integer; cdecl;
function mongoc_socket_connect(sock: PMongocSocket; const addr: psockaddr; addrlen: socklen_t; expire_at: Int64): Integer; cdecl;
function mongoc_socket_getnameinfo(sock: PMongocSocket): PAnsiChar; cdecl;
procedure mongoc_socket_destroy(sock: PMongocSocket); cdecl;
function mongoc_socket_errno(sock: PMongocSocket): Integer; cdecl;
function mongoc_socket_getsockname(sock: PMongocSocket; addr: psockaddr; var addrlen: socklen_t): Integer; cdecl;
function mongoc_socket_listen(sock: PMongocSocket; backlog: Cardinal): Integer; cdecl;
function mongoc_socket_new(domain: Integer; _type: Integer; protocol: Integer): PMongocSocket; cdecl;
function mongoc_socket_recv(sock: PMongocSocket; buf: Pointer; buflen: size_t; flags: Integer; expire_at: Int64): ssize_t; cdecl;
function mongoc_socket_setsockopt(sock: PMongocSocket; level: Integer; optname: Integer; const optval: Pointer; optlen: socklen_t): Integer; cdecl;
function mongoc_socket_send(sock: PMongocSocket; const buf: Pointer; buflen: size_t; expire_at: Int64): ssize_t; cdecl;
function mongoc_socket_sendv(sock: PMongocSocket; iov: PMongocIovec; iovcnt: size_t; expire_at: Int64): ssize_t; cdecl;
function mongoc_socket_check_closed(sock: PMongocSocket): Boolean; cdecl;
procedure mongoc_socket_inet_ntop(rp: PSocketAddress; buf: PAnsiChar; buflen: size_t); cdecl;
function mongoc_socket_poll(sds: PMongocSocketPoll; nsds: size_t; timeout: Int32): ssize_t; cdecl;








// mongoc_stream.h

type
  PMongocStream = Pointer;

  TMongocStreamPoll = record
    stream: PMongocStream;
    events: Integer;
    revents: Integer;
  end;

  PMongocStreamPoll = ^TMongocStreamPoll;

  // PMongocIovec = Pointer;

  TMongocStream = record
    _type: Integer;
    destroy: procedure(stream: PMongocStream); cdecl;
    close: function(stream: PMongocStream): Integer; cdecl;
    flush: function(stream: PMongocStream): Integer; cdecl;
    writev: function(stream: PMongocStream; iov: PMongocIovec; iovcnt: size_t; timeout_mses: Int32): ssize_t; cdecl;
    readv: function(stream: PMongocStream; iov: PMongocIovec; iovcnt: size_t; min_bytes: size_t; timeout_mses: Int32): ssize_t; cdecl;
    setsockopt: function(stream: PMongocStream; level: Integer; optname: Integer; optval: Pointer; optlen: socklen_t): Integer; cdecl;
    get_base_stream: function(stream: PMongocStream): PMongocStream; cdecl;
    check_closed: function(stream: PMongocStream): Boolean; cdecl;
    poll: function(streams: PMongocStreamPoll; nstreams: size_t; timeout: Int32): ssize_t; cdecl;
    failed: procedure(stream: PMongocStream); cdecl;
    padding: array [0 .. 4] of Pointer;
  end;

function mongoc_stream_get_base_stream(stream: PMongocStream): PMongocStream; cdecl;
function mongoc_stream_close(stream: PMongocStream): Integer; cdecl;
procedure mongoc_stream_destroy(stream: PMongocStream); cdecl;
procedure mongoc_stream_failed(stream: PMongocStream); cdecl;
function mongoc_stream_flush(stream: PMongocStream): Integer; cdecl;
function mongoc_stream_writev(stream: PMongocStream; iov: PMongocIovec; iovcnt: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_stream_write(stream: PMongocStream; buf: Pointer; count: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_stream_readv(stream: PMongocStream; iov: PMongocIovec; iovcnt: size_t; min_bytes: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_stream_read(stream: PMongocStream; buf: Pointer; count: size_t; min_bytes: size_t; timeout_msec: Int32): ssize_t; cdecl;
function mongoc_stream_setsockopt(stream: PMongocStream; level: Integer; optname: Integer; optval: Pointer; optlen: socklen_t): Integer; cdecl;
function mongoc_stream_check_closed(stream: PMongocStream): Boolean; cdecl;
function mongoc_stream_poll(streams: PMongocStreamPoll; nstreams: size_t; timeout: Int32): ssize_t; cdecl;

// mongoc_stream_socket.h
type
  PMongocStreamSocket = Pointer;

function mongoc_stream_socket_new(socket: PMongocSocket): PMongocStream; cdecl;
function mongoc_stream_socket_get_socket(stream: PMongocStreamSocket): PMongocSocket; cdecl;



// mongoc_stream_file.h

function mongoc_stream_buffered_new(base_stream: PMongocStream; buffer_size: size_t): PMongocStream; cdecl;





// mongoc_stream_file.h

type
  PMongocStreamFile = Pointer;

function mongoc_stream_file_new(fd: Integer): PMongocStream; cdecl;
function mongoc_stream_file_new_for_path(const path: PAnsiChar; flags, mode: Integer): PMongocStream; cdecl;
function mongoc_stream_file_get_fd(stream: PMongocStreamFile): Integer; cdecl;

// mongoc_gridfs.h
type
  PMongocCollection = Pointer;

type
  PMongocGridfs = Pointer;
  PMongocGridfsPrefs = Pointer;
  PMongocGridfsList = Pointer;
  PMongocGridfsFileOpt = Pointer;

function mongoc_gridfs_create_file_from_stream(gridfs: PMongocGridfs; stream: PMongocStream; opt: PMongocGridfsFileOpt): PMongocGridfs; cdecl;
function mongoc_gridfs_create_file(gridfs: PMongocGridfs; opt: PMongocGridfsFileOpt): PMongocGridfs; cdecl;
function mongoc_gridfs_find(gridfs: PMongocGridfs; const query: PBson): PMongocGridfsList; cdecl;
function mongoc_gridfs_find_one(gridfs: PMongocGridfs; const query: PBson; var error: TBsonError): PMongocGridfs; cdecl;
function mongoc_gridfs_find_one_by_filename(gridfs: PMongocGridfs; const filename: PAnsiChar; var error: TBsonError): PMongocGridfs; cdecl;
function mongoc_gridfs_drop(gridfs: PMongocGridfs; var error: TBsonError): Boolean; cdecl;
procedure mongoc_gridfs_destroy(gridfs: PMongocGridfs); cdecl;
function mongoc_gridfs_get_files(gridfs: PMongocGridfs): PMongocCollection; cdecl;
function mongoc_gridfs_get_chunks(gridfs: PMongocGridfs): PMongocCollection; cdecl;
function mongoc_gridfs_remove_by_filename(gridfs: PMongocGridfs; const filename: PAnsiChar; var error: TBsonError): Boolean; cdecl;

// #define MONGOC_GRIDFS_FILE_STR_HEADER(name) \
// const char * \
// mongoc_gridfs_file_get_##name (_file:PMongocGridfsFile); \
// void \
// mongoc_gridfs_file_set_##name (_file:PMongocGridfsFile, \
// const char           *str);
//
//
// #define MONGOC_GRIDFS_FILE_BSON_HEADER(name) \
// const bson_t * \
// mongoc_gridfs_file_get_##name (_file:PMongocGridfsFile); \
// void \
// mongoc_gridfs_file_set_##name (_file:PMongocGridfsFile, \
// const bson_t * bson);




// mongoc_stream_gridfs.h

function mongoc_stream_gridfs_new(_file: PMongocGridfsFile): PMongocStream; cdecl;



// mongoc_collection.h

type
  PMongocFindAndModifyOpts = Pointer;
  // PMongocCollection = Pointer;
  // PMongocIndexOpt = Pointer;

function mongoc_collection_aggregate(collection: PMongocCollection; flags: mongoc_query_flags_t; const pipeline: PBson; const options: PBson;
  const read_prefs: PMongocGridfsPrefs): PMongocCursor; cdecl;
procedure mongoc_collection_destroy(collection: PMongocCollection); cdecl;
function mongoc_collection_copy(collection: PMongocCollection): PMongocCollection; cdecl;
function mongoc_collection_command(collection: PMongocCollection; flags: mongoc_query_flags_t; skip: UInt32; limit: UInt32; batch_size: UInt32;
  const command: PBson; const fields: PBson; const read_prefs: PMongocGridfsPrefs): PMongocCursor; cdecl;
function mongoc_collection_command_simple(collection: PMongocCollection; const command: PBson; const read_prefs: PMongocGridfsPrefs; reply: PBson;
  var error: TBsonError): Boolean; cdecl;

function mongoc_collection_count(collection: PMongocCollection; flags: mongoc_query_flags_t; const query: PBson; skip: Int64; limit: Int64;
  const read_prefs: PMongocGridfsPrefs; var error: TBsonError): Int64; cdecl;
function mongoc_collection_count_with_opts(collection: PMongocCollection; flags: mongoc_query_flags_t; const query: PBson; skip: Int64; limit: Int64;
  const opts: PBson; const read_prefs: PMongocGridfsPrefs; var error: TBsonError): Int64; cdecl;
function mongoc_collection_drop(collection: PMongocCollection; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_drop_index(collection: PMongocCollection; const index_name: PAnsiChar; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_create_index(collection: PMongocCollection; const keys: PBson; const opt: PMongocIndexOpt; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_ensure_index(collection: PMongocCollection; const keys: PBson; const opt: PMongocIndexOpt; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_find_indexes(collection: PMongocCollection; var error: TBsonError): PMongocCursor; cdecl;
function mongoc_collection_find(collection: PMongocCollection; flags: mongoc_query_flags_t; skip: UInt32; limit: UInt32; batch_size: UInt32; const query: PBson;
  const fields: PBson; const read_prefs: PMongocGridfsPrefs): PMongocCursor; cdecl;
function mongoc_collection_insert(collection: PMongocCollection; flags: mongoc_insert_flags_t; const document: PBson; const write_concern: PMongocWriteConcern;
  var error: TBsonError): Boolean; cdecl;

function mongoc_collection_insert_bulk(collection: PMongocCollection; flags: mongoc_insert_flags_t; const documents: PBsonArray; n_documents: UInt32;
  const write_concern: PMongocWriteConcern; var error: TBsonError): Boolean; cdecl;
// function mongoc_collection_create_bulk_operation(collection: PMongocCollection; flags: mongoc_insert_flags_t; const documents: PBsonArray; n_documents: UInt32;
// const write_concern: PMongocWriteConcern; var error: TBsonError): Boolean;

function mongoc_collection_update(collection: PMongocCollection; flags: mongoc_update_flags_t; const selector: PBson; const update: PBson;
  const write_concern: PMongocWriteConcern; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_delete(collection: PMongocCollection; flags: mongoc_delete_flags_t; const selector: PBson; const write_concern: PMongocWriteConcern;
  var error: TBsonError): Boolean; cdecl;
// function mongoc_collection_remove(collection: PMongocCollection; flags: mongoc_delete_flags_t; const selector: PBson; const write_concern: PMongocWriteConcern;
// var error: TBsonError): Boolean;

function mongoc_collection_save(collection: PMongocCollection; const document: PBson; const write_concern: PMongocWriteConcern; var error: TBsonError)
  : Boolean; cdecl;
function mongoc_collection_remove(collection: PMongocCollection; flags: mongoc_remove_flags_t; const selector: PBson; const write_concern: PMongocWriteConcern;
  var error: TBsonError): Boolean; cdecl;
function mongoc_collection_rename(collection: PMongocCollection; const new_db: PAnsiChar; const new_name: PAnsiChar; drop_target_before_rename: Boolean;
  var error: TBsonError): Boolean; cdecl;
function mongoc_collection_find_and_modify_with_opts(collection: PMongocCollection; const query: PBson; const opts: PMongocFindAndModifyOpts; reply: PBson;
  var error: TBsonError): Boolean; cdecl;
function mongoc_collection_find_and_modify(collection: PMongocCollection; const query: PBson; const sort: PBson; const update: PBson; const fields: PBson;
  _remove: Boolean; upsert: Boolean; _new: Boolean; reply: PBson; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_stats(collection: PMongocCollection; const options: PBson; reply: PBson; var error: TBsonError): Boolean; cdecl;
function mongoc_collection_create_bulk_operation(collection: PMongocCollection; ordered: Boolean; const write_concern: PMongocWriteConcern)
  : PMongocBulkOperation; cdecl;
function mongoc_collection_get_read_prefs(const collection: PMongocCollection): PMongocGridfsPrefs; cdecl;
procedure mongoc_collection_set_read_prefs(collection: PMongocCollection; const read_prefs: PMongocGridfsPrefs); cdecl;
function mongoc_collection_get_read_concern(const collection: PMongocCollection): PMongocReadConcern; cdecl;
procedure mongoc_collection_set_read_concern(collection: PMongocCollection; const read_concern: PMongocReadConcern); cdecl;
function mongoc_collection_get_write_concern(const collection: PMongocCollection): PMongocWriteConcern; cdecl;
procedure mongoc_collection_set_write_concern(collection: PMongocCollection; const write_concern: PMongocWriteConcern); cdecl;
function mongoc_collection_get_name(collection: PMongocCollection): PAnsiChar; cdecl;
function mongoc_collection_get_last_error(const collection: PMongocCollection): PBson; cdecl;
function mongoc_collection_keys_to_index_string(const keys: PBson): PAnsiChar; cdecl;
function mongoc_collection_validate(collection: PMongocCollection; const options: PBson; reply: PBson; var error: TBsonError): Boolean; cdecl;

// mongoc_client.h
const
  MONGOC_NAMESPACE_MAX = 128;

const
  MONGOC_DEFAULT_CONNECTTIMEOUTMS = (10 * 1000);

  //
  // NOTE: The default socket timeout for connections is 5 minutes. This
  // means that if your MongoDB server dies or becomes unavailable
  // it will take 5 minutes to detect this.
  //
  // You can change this by providing sockettimeoutms= in your
  // connection URI.
  //
const
  MONGOC_DEFAULT_SOCKETTIMEOUTMS = (1000 * 60 * 5);

  //
  // mongoc_client_t:
  //
  // The mongoc_client_t structure maintains information about a connection to
  // a MongoDB server.
  //
type
  PMongocClient = Pointer;
  PMongocDatabase = Pointer;

  TAnsiCharArray = array [0 .. 0] of PAnsiChar;
  PAnsiCharArray = ^TAnsiCharArray;

  // PMongocCollection = Pointer;

  //
  // mongoc_stream_initiator_t:
  // @uri: The uri and options for the stream.
  // @host: The host and port (or UNIX domain socket path) to connect to.
  // @user_data: The pointer passed to mongoc_client_set_stream_initiator.
  // @error: A location for an error.
  //
  // Creates a new mongoc_stream_t for the host and port. Begin a
  // non-blocking connect and return immediately.
  //
  // This can be used by language bindings to create network transports other
  // than those built into libmongoc. An example of such would be the streams
  // API provided by PHP.
  //
  // Returns: A newly allocated mongoc_stream_t or NULL on failure.
  //
type
  mongoc_stream_initiator_t = function(uri: PMongocUri; host: PMongocHostList; user_data: Pointer; var error: TBsonError): PMongocStream; cdecl;

function mongoc_client_new(const uri_string: PAnsiChar): PMongocClient; cdecl;
function mongoc_client_new_from_uri(const uri: PMongocUri): PMongocClient; cdecl;
function mongoc_client_get_uri(const client: PMongocClient): PMongocUri; cdecl;
procedure mongoc_client_set_stream_initiator(client: PMongocClient; initiator: mongoc_stream_initiator_t; user_data: Pointer); cdecl;
function mongoc_client_command(client: PMongocClient; const db_name: PAnsiChar; flags: mongoc_query_flags_t; skip, limit, batch_size: UInt32;
  const query: PBson; const fields: PBson; const read_prefs: PMongocGridfsPrefs): PMongocCursor; cdecl;
cdecl
procedure mongoc_client_kill_cursor(client: PMongocClient; cursor_id: Int64);
cdecl;
function mongoc_client_command_simple(client: PMongocClient; const db_name: PAnsiChar; const command: PBson; const read_prefs: PMongocGridfsPrefs; reply: PBson;
  var error: TBsonError): Boolean; cdecl;
procedure mongoc_client_destroy(client: PMongocClient); cdecl;
function mongoc_client_get_database(client: PMongocClient; const name: PAnsiChar): PMongocDatabase; cdecl;
function mongoc_client_get_default_database(client: PMongocClient): PMongocDatabase; cdecl;
function mongoc_client_get_gridfs(client: PMongocClient; const db: PAnsiChar; const prefix: PAnsiChar; var error: TBsonError): PMongocGridfs; cdecl;
function mongoc_client_get_collection(client: PMongocClient; const db: PAnsiChar; const collection: PAnsiChar): PMongocCollection; cdecl;
function mongoc_client_get_database_names(client: PMongocClient; var error: TBsonError): PAnsiCharArray; cdecl;
function mongoc_client_find_databases(client: PMongocClient; var error: TBsonError): PMongocCursor; cdecl;
function mongoc_client_get_server_status(client: PMongocClient; read_prefs: PMongocGridfsPrefs; reply: PBson; var error: TBsonError): Boolean; cdecl;
function mongoc_client_get_max_message_size(client: PMongocClient): UInt32; cdecl;
function mongoc_client_get_max_bson_size(client: PMongocClient): UInt32; cdecl;
function mongoc_client_get_write_concern(const client: PMongocClient): PMongocWriteConcern; cdecl;
procedure mongoc_client_set_write_concern(client: PMongocClient; const write_concern: PMongocWriteConcern); cdecl;
function mongoc_client_get_read_concern(client: PMongocClient): PMongocReadConcern; cdecl;
procedure mongoc_client_set_read_concern(client: PMongocClient; const read_concern: PMongocReadConcern); cdecl;
function mongoc_client_get_read_prefs(const client: PMongocClient): PMongocGridfsPrefs; cdecl;
procedure mongoc_client_set_read_prefs(client: PMongocClient; const read_prefs: PMongocGridfsPrefs); cdecl;
{$IFDEF MONGOC_ENABLE_SSL}
procedure mongoc_client_set_ssl_opts(client: PMongocClient; const opts: pmongoc_ssl_opt_t); cdecl;
{$ENDIF}

// mongoc_client_pool.h
type
  PMongocClientPool = Pointer;
  _BsonArray = array [0 .. 0] of PBson;
  PBsonArray = ^_BsonArray;

function mongoc_client_pool_new(const uri: PMongocUri): PMongocClientPool; cdecl;
procedure mongoc_client_pool_destroy(pool: PMongocClientPool); cdecl;
function mongoc_client_pool_pop(pool: PMongocClientPool): PMongocClient; cdecl;
procedure mongoc_client_pool_push(pool: PMongocClientPool; client: PMongocClient); cdecl;
function mongoc_client_pool_try_pop(pool: PMongocClientPool): PMongocClient; cdecl;
procedure mongoc_client_pool_max_size(pool: PMongocClientPool; max_pool_size: UInt32); cdecl;
procedure mongoc_client_pool_min_size(pool: PMongocClientPool; min_pool_size: UInt32); cdecl;
{$IFDEF MONGOC_ENABLE_SSL}
procedure mongoc_client_pool_set_ssl_opts(pool: PMongocClientPool; const opts: pmongoc_ssl_opt_t); cdecl;
{$ENDIF}
// mongoc_database.h

// type
// PMongocDatabase=Pointer;

function mongoc_database_get_name(database: PMongocDatabase): PAnsiChar; cdecl;
function mongoc_database_remove_user(database: PMongocDatabase; const username: PAnsiChar; var error: TBsonError): Boolean; cdecl;
function mongoc_database_remove_all_users(database: PMongocDatabase; var error: TBsonError): Boolean; cdecl;
function mongoc_database_add_user(database: PMongocDatabase; const username: PAnsiChar; const password: PAnsiChar; const roles: PBson; const custom_data: PBson;
  var error: TBsonError): Boolean; cdecl;
procedure mongoc_database_destroy(database: PMongocDatabase); cdecl;
function mongoc_database_copy(database: PMongocDatabase): PMongocDatabase; cdecl;
function mongoc_database_command(database: PMongocDatabase; flags: mongoc_query_flags_t; skip: UInt32; limit: UInt32; batch_size: UInt32; const command: PBson;
  const fields: PBson; const read_prefs: PMongocGridfsPrefs): PMongocCursor; cdecl;
function mongoc_database_command_simple(database: PMongocDatabase; const command: PBson; const read_prefs: PMongocGridfsPrefs; replay: PBson;
  var error: TBsonError): Boolean; cdecl;
function mongoc_database_drop(database: PMongocDatabase; var error: TBsonError): Boolean; cdecl;
function mongoc_database_has_collection(database: PMongocDatabase; const name: PAnsiChar; var error: TBsonError): Boolean; cdecl;
function mongoc_database_create_collection(database: PMongocDatabase; const name: PAnsiChar; const options: PBson; var error: TBsonError)
  : PMongocCollection; cdecl;
function mongoc_database_get_read_prefs(const database: PMongocDatabase): PMongocGridfsPrefs; cdecl;
procedure mongoc_database_set_read_prefs(database: PMongocDatabase; const read_prefs: PMongocGridfsPrefs); cdecl;
function mongoc_database_get_write_concern(const database: PMongocDatabase): PMongocWriteConcern; cdecl;
procedure mongoc_database_set_write_concern(database: PMongocDatabase; const write_concern: PMongocWriteConcern); cdecl;
function mongoc_database_get_read_concern(const database: PMongocDatabase): PMongocReadConcern; cdecl;
procedure mongoc_database_set_read_concern(database: PMongocDatabase; const read_concern: PMongocReadConcern); cdecl;
function mongoc_database_find_collections(database: PMongocDatabase; const filter: PBson; var error: TBsonError): PMongocCursor; cdecl;
function mongoc_database_get_collection_names(database: PMongocDatabase; var error: TBsonError): PAnsiCharArray; cdecl;
function mongoc_database_get_collection(database: PMongocDatabase; const name: PAnsiChar): PMongocCollection; cdecl;

// mongoc_find_and_modify.h
type
  TMongocFindAndModifyFlag = (MONGOC_FIND_AND_MODIFY_NONE = 0, MONGOC_FIND_AND_MODIFY_REMOVE = 1 shl 0, MONGOC_FIND_AND_MODIFY_UPSERT = 1 shl 1,
    MONGOC_FIND_AND_MODIFY_RETURN_NEW = 1 shl 2);

  PMongocFindAndModifyFlag = ^TMongocFindAndModifyFlag;

function mongoc_find_and_modify_opts_new: PMongocFindAndModifyFlag; cdecl;
function mongoc_find_and_modify_opts_set_sort(opts: PMongocFindAndModifyFlag; const sort: PBson): Boolean; cdecl;
function mongoc_find_and_modify_opts_set_update(opts: PMongocFindAndModifyFlag; const update: PBson): Boolean; cdecl;
function mongoc_find_and_modify_opts_set_fields(opts: PMongocFindAndModifyFlag; const fields: PBson): Boolean; cdecl;
function mongoc_find_and_modify_opts_set_flags(opts: PMongocFindAndModifyFlag; const flags: TMongocFindAndModifyFlag): Boolean; cdecl;
function mongoc_find_and_modify_opts_set_bypass_document_validation(opts: PMongocFindAndModifyFlag; bypass: Boolean): Boolean; cdecl;
procedure mongoc_find_and_modify_opts_destroy(opts: PMongocFindAndModifyFlag); cdecl;




// mongoc_server_description.h

type
  PMongocServerDescription = Pointer;

procedure mongoc_server_description_destroy(description: PMongocServerDescription); cdecl;
function mongoc_server_description_new_copy(const description: PMongocServerDescription): PMongocServerDescription; cdecl;
function mongoc_server_description_id(description: PMongocServerDescription): Int32; cdecl;
function mongoc_server_description_host(description: PMongocServerDescription): PMongocHostList; cdecl;

// mongoc_log.h
type
  TMongocLogLevel = (MONGOC_LOG_LEVEL_ERROR, MONGOC_LOG_LEVEL_CRITICAL, MONGOC_LOG_LEVEL_WARNING, MONGOC_LOG_LEVEL_MESSAGE, MONGOC_LOG_LEVEL_INFO,
    MONGOC_LOG_LEVEL_DEBUG, MONGOC_LOG_LEVEL_TRACE);

  // *
  // *mongoc_log_func_t:
  // *@log_level: The level of the log message.
  // *@log_domain: The domain of the log message, such as "client".
  // *@message: The message generated.
  // *@user_data: User data provided to mongoc_log_set_handler().
  // *
  // *This function prototype can be used to set a custom log handler for the
  // *libmongoc library. This is useful if you would like to show them in a
  // *user interface or alternate storage.
  // *
  mongoc_log_func_t = procedure(log_level: TMongocLogLevel; const log_domain: PAnsiChar; const message: PAnsiChar; user_data: Pointer); cdecl;

  // *
  // *mongoc_log_set_handler:
  // *@log_func: A function to handle log messages.
  // *@user_data: User data for @log_func.
  // *
  // *Sets the function to be called to handle logging.
  // *
procedure mongoc_log_set_handler(log_func: mongoc_log_func_t; user_data: Pointer); cdecl;

// *
// *mongoc_log:
// *@log_level: The log level.
// *@log_domain: The log domain (such as "client").
// *@format: The format string for the log message.
// *
// *Logs a message using the currently configured logger.
// *
// *This method will hold a logging lock to prevent concurrent calls to the
// *logging infrastructure. It is important that your configured log function
// *does not re-enter the logging system or deadlock will occur.
// *
// *
procedure mongoc_log(log_level: TMongocLogLevel; const log_domain: PAnsiChar; const format: PAnsiChar); cdecl; varargs;
procedure mongoc_log_default_handler(log_level: TMongocLogLevel; const log_domain: PAnsiChar; const message: PAnsiChar; user_data: Pointer); cdecl;

// *
// *mongoc_log_level_str:
// *@log_level: The log level.
// *
// *Returns: The string representation of log_level
// *
function mongoc_log_level_str(log_level: TMongocLogLevel): PAnsiChar; cdecl;




// mongoc_matcher.h

type
  PMongocMacher = Pointer;

function mongoc_matcher_new(const query: PBson; var error: TBsonError): PMongocMacher; cdecl;
function mongoc_matcher_match(const matcher: PMongocMacher; const document: PBson): Boolean; cdecl;
procedure mongoc_matcher_destroy(matcher: PMongocMacher); cdecl;




// mongoc_init.h

procedure mongoc_init; cdecl;
procedure mongoc_cleanup; cdecl;


// mongoc_version_functions.h

function mongoc_get_major_version: Integer; cdecl;
function mongoc_get_minor_version: Integer; cdecl;
function mongoc_get_micro_version: Integer; cdecl;
function mongoc_get_version: PAnsiChar; cdecl;
function mongoc_check_version(required_major, required_minor, required_micro: Integer): Boolean; cdecl;

implementation

const
  DllName = 'libmongoc-1.0-0.dll';

function mongoc_read_concern_new: PMongocReadConcern; cdecl; external DllName;
function mongoc_read_concern_copy; cdecl; external DllName;
procedure mongoc_read_concern_destroy; cdecl; external DllName;
function mongoc_read_concern_get_level; cdecl; external DllName;
function mongoc_read_concern_set_level; cdecl; external DllName;

function mongoc_write_concern_new; cdecl; external DllName;
function mongoc_write_concern_copy; cdecl; external DllName;
procedure mongoc_write_concern_destroy; cdecl; external DllName;
function mongoc_write_concern_get_fsync; cdecl; external DllName;
procedure mongoc_write_concern_set_fsync; cdecl; external DllName;
function mongoc_write_concern_get_journal; cdecl; external DllName;
procedure mongoc_write_concern_set_journal; cdecl; external DllName;
function mongoc_write_concern_get_w; cdecl; external DllName;
procedure mongoc_write_concern_set_w; cdecl; external DllName;

function mongoc_write_concern_get_wtag; cdecl; external DllName;
procedure mongoc_write_concern_set_wtag; cdecl; external DllName;
function mongoc_write_concern_get_wtimeout; cdecl; external DllName;
procedure mongoc_write_concern_set_wtimeout; cdecl; external DllName;
function mongoc_write_concern_get_wmajority; cdecl; external DllName;
procedure mongoc_write_concern_set_wmajority; cdecl; external DllName;

procedure mongoc_bulk_operation_destroy; cdecl; external DllName;
function mongoc_bulk_operation_execute;cdecl; external DllName;
procedure mongoc_bulk_operation_delete; cdecl; external DllName;
procedure mongoc_bulk_operation_delete_one; cdecl; external DllName;
procedure mongoc_bulk_operation_insert; cdecl; external DllName;
procedure mongoc_bulk_operation_remove; cdecl; external DllName;
procedure mongoc_bulk_operation_remove_one; cdecl; external DllName;
procedure mongoc_bulk_operation_replace_one; cdecl; external DllName;
procedure mongoc_bulk_operation_update; cdecl; external DllName;
procedure mongoc_bulk_operation_update_one; cdecl; external DllName;
procedure mongoc_bulk_operation_set_bypass_document_validation; cdecl; external DllName;


//
// The following functions are really only useful by language bindings and
// those wanting to replay a bulk operation to a number of clients or
// collections.
//

function mongoc_bulk_operation_new; cdecl; external DllName;
procedure mongoc_bulk_operation_set_write_concern; cdecl; external DllName;
procedure mongoc_bulk_operation_set_database; cdecl; external DllName;
procedure mongoc_bulk_operation_set_collection; cdecl; external DllName;
procedure mongoc_bulk_operation_set_client; cdecl; external DllName;
procedure mongoc_bulk_operation_set_hint; cdecl; external DllName;
function mongoc_bulk_operation_get_write_concern; cdecl; external DllName;

function mongoc_index_opt_get_default; cdecl; external DllName;
function mongoc_index_opt_geo_get_default; cdecl; external DllName;
function mongoc_index_opt_wt_get_default; cdecl; external DllName;
procedure mongoc_index_opt_init; cdecl; external DllName;
procedure mongoc_index_opt_geo_init; cdecl; external DllName;
procedure mongoc_index_opt_wt_init; cdecl; external DllName;

function mongoc_read_prefs_new; cdecl; external DllName;
function mongoc_read_prefs_copy; cdecl; external DllName;
procedure mongoc_read_prefs_destroy; cdecl; external DllName;
function mongoc_read_prefs_get_mode; cdecl; external DllName;
procedure mongoc_read_prefs_set_mode; cdecl; external DllName;
function mongoc_read_prefs_get_tags; cdecl; external DllName;
procedure mongoc_read_prefs_set_tags; cdecl; external DllName;
procedure mongoc_read_prefs_add_tag; cdecl; external DllName;
function mongoc_read_prefs_is_valid; cdecl; external DllName;

function mongoc_uri_copy; cdecl; external DllName;
procedure mongoc_uri_destroy; cdecl; external DllName;
function mongoc_uri_new; cdecl; external DllName;
function mongoc_uri_new_for_host_port; cdecl; external DllName;
function mongoc_uri_get_hosts; cdecl; external DllName;
function mongoc_uri_get_database; cdecl; external DllName;
function mongoc_uri_get_options; cdecl; external DllName;
function mongoc_uri_get_password; cdecl; external DllName;
function mongoc_uri_get_read_prefs; cdecl; external DllName;
function mongoc_uri_get_read_prefs_t; cdecl; external DllName;

function mongoc_uri_get_replica_set; cdecl; external DllName;

function mongoc_uri_get_string; cdecl; external DllName;

function mongoc_uri_get_username; cdecl; external DllName;

function mongoc_uri_get_credentials; cdecl; external DllName;

function mongoc_uri_get_auth_source; cdecl; external DllName;

function mongoc_uri_get_auth_mechanism; cdecl; external DllName;
function mongoc_uri_get_mechanism_properties; cdecl; external DllName;
function mongoc_uri_get_ssl; cdecl; external DllName;
function mongoc_uri_unescape; cdecl; external DllName;



// function mongoc_uri_get_read_prefs_t; cdecl; external DllName;

function mongoc_uri_get_write_concern; cdecl; external DllName;
function mongoc_uri_get_read_concern; cdecl; external DllName;

function mongoc_cursor_clone; cdecl; external DllName;

procedure mongoc_cursor_destroy; cdecl; external DllName;
function mongoc_cursor_more; cdecl; external DllName;
function mongoc_cursor_next; cdecl; external DllName;
function mongoc_cursor_error; cdecl; external DllName;
procedure mongoc_cursor_get_host; cdecl; external DllName;
function mongoc_cursor_is_alive; cdecl; external DllName;

function mongoc_cursor_current; cdecl; external DllName;
procedure mongoc_cursor_set_batch_size; cdecl; external DllName;
function mongoc_cursor_get_batch_size; cdecl; external DllName;
function mongoc_cursor_get_hint; cdecl; external DllName;
function mongoc_cursor_get_id; cdecl; external DllName;
procedure mongoc_cursor_set_max_await_time_ms; cdecl; external DllName;
function mongoc_cursor_get_max_await_time_ms; cdecl; external DllName;

function mongoc_gridfs_file_get_md5; cdecl; external DllName;
procedure mongoc_gridfs_file_set_md5; cdecl; external DllName;
function mongoc_gridfs_file_get_filename; cdecl; external DllName;
procedure mongoc_gridfs_file_set_filename; cdecl; external DllName;
function mongoc_gridfs_file_get_content_type; cdecl; external DllName;
procedure mongoc_gridfs_file_set_content_type; cdecl; external DllName;
function mongoc_gridfs_file_get_aliases; cdecl; external DllName;
procedure mongoc_gridfs_file_set_aliases; cdecl; external DllName;
function mongoc_gridfs_file_get_metadata; cdecl; external DllName;
procedure mongoc_gridfs_file_set_metadata; cdecl; external DllName;
function mongoc_gridfs_file_get_id; cdecl; external DllName;
function mongoc_gridfs_file_get_length; cdecl; external DllName;
function mongoc_gridfs_file_get_chunk_size; cdecl; external DllName;
function mongoc_gridfs_file_get_upload_date; cdecl; external DllName;
function mongoc_gridfs_file_writev; cdecl; external DllName;
function mongoc_gridfs_file_readv; cdecl; external DllName;
function mongoc_gridfs_file_seek; cdecl; external DllName;
function mongoc_gridfs_file_tell; cdecl; external DllName;
function mongoc_gridfs_file_save; cdecl; external DllName;
procedure mongoc_gridfs_file_destroy; cdecl; external DllName;
function mongoc_gridfs_file_error; cdecl; external DllName;
function mongoc_gridfs_file_remove; cdecl; external DllName;

function mongoc_gridfs_file_list_next; cdecl; external DllName;
procedure mongoc_gridfs_file_list_destroy; cdecl; external DllName;
function mongoc_gridfs_file_list_error; cdecl; external DllName;

function mongoc_socket_accept; cdecl; external DllName;
function mongoc_socket_bind; cdecl; external DllName;
function mongoc_socket_close; cdecl; external DllName;
function mongoc_socket_connect; cdecl; external DllName;
function mongoc_socket_getnameinfo; cdecl; external DllName;
procedure mongoc_socket_destroy; cdecl; external DllName;
function mongoc_socket_errno; cdecl; external DllName;
function mongoc_socket_getsockname; cdecl; external DllName;
function mongoc_socket_listen; cdecl; external DllName;
function mongoc_socket_new; cdecl; external DllName;
function mongoc_socket_recv; cdecl; external DllName;
function mongoc_socket_setsockopt; cdecl; external DllName;
function mongoc_socket_send; cdecl; external DllName;
function mongoc_socket_sendv; cdecl; external DllName;
function mongoc_socket_check_closed; cdecl; external DllName;
procedure mongoc_socket_inet_ntop; cdecl; external DllName;
function mongoc_socket_poll; cdecl; external DllName;

function mongoc_stream_get_base_stream; cdecl; external DllName;
function mongoc_stream_close; cdecl; external DllName;
procedure mongoc_stream_destroy; cdecl; external DllName;
procedure mongoc_stream_failed; cdecl; external DllName;
function mongoc_stream_flush; cdecl; external DllName;
function mongoc_stream_writev; cdecl; external DllName;
function mongoc_stream_write; cdecl; external DllName;
function mongoc_stream_readv; cdecl; external DllName;
function mongoc_stream_read; cdecl; external DllName;
function mongoc_stream_setsockopt; cdecl; external DllName;
function mongoc_stream_check_closed; cdecl; external DllName;
function mongoc_stream_poll; cdecl; external DllName;

function mongoc_stream_socket_new; cdecl; external DllName;
function mongoc_stream_socket_get_socket; cdecl; external DllName;

function mongoc_stream_buffered_new; cdecl; external DllName;

function mongoc_stream_file_new; cdecl; external DllName;
function mongoc_stream_file_new_for_path; cdecl; external DllName;
function mongoc_stream_file_get_fd; cdecl; external DllName;

function mongoc_gridfs_create_file_from_stream; cdecl; external DllName;
function mongoc_gridfs_create_file; cdecl; external DllName;
function mongoc_gridfs_find; cdecl; external DllName;
function mongoc_gridfs_find_one; cdecl; external DllName;
function mongoc_gridfs_find_one_by_filename; cdecl; external DllName;
function mongoc_gridfs_drop; cdecl; external DllName;
procedure mongoc_gridfs_destroy; cdecl; external DllName;
function mongoc_gridfs_get_files; cdecl; external DllName;
function mongoc_gridfs_get_chunks; cdecl; external DllName;
function mongoc_gridfs_remove_by_filename; cdecl; external DllName;

function mongoc_stream_gridfs_new; cdecl; external DllName;

function mongoc_collection_aggregate; cdecl; external DllName;
procedure mongoc_collection_destroy; cdecl; external DllName;
function mongoc_collection_copy; cdecl; external DllName;
function mongoc_collection_command; cdecl; external DllName;
function mongoc_collection_command_simple; cdecl; external DllName;

function mongoc_collection_count; cdecl; external DllName;
function mongoc_collection_count_with_opts; cdecl; external DllName;
function mongoc_collection_drop; cdecl; external DllName;
function mongoc_collection_drop_index; cdecl; external DllName;
function mongoc_collection_create_index; cdecl; external DllName;
function mongoc_collection_ensure_index; cdecl; external DllName;
function mongoc_collection_find_indexes; cdecl; external DllName;
function mongoc_collection_find; cdecl; external DllName;
function mongoc_collection_insert; cdecl; external DllName;

function mongoc_collection_insert_bulk; cdecl; external DllName;
// function mongoc_collection_create_bulk_operation;

function mongoc_collection_update; cdecl; external DllName;
function mongoc_collection_delete; cdecl; external DllName;
// function mongoc_collection_remove;

function mongoc_collection_save; cdecl; external DllName;
function mongoc_collection_remove; cdecl; external DllName;
function mongoc_collection_rename; cdecl; external DllName;
function mongoc_collection_find_and_modify_with_opts; cdecl; external DllName;
function mongoc_collection_find_and_modify; cdecl; external DllName;
function mongoc_collection_stats; cdecl; external DllName;
function mongoc_collection_create_bulk_operation; cdecl; external DllName;
function mongoc_collection_get_read_prefs; cdecl; external DllName;
procedure mongoc_collection_set_read_prefs; cdecl; external DllName;
function mongoc_collection_get_read_concern; cdecl; external DllName;
procedure mongoc_collection_set_read_concern; cdecl; external DllName;
function mongoc_collection_get_write_concern; cdecl; external DllName;
procedure mongoc_collection_set_write_concern; cdecl; external DllName;
function mongoc_collection_get_name; cdecl; external DllName;
function mongoc_collection_get_last_error; cdecl; external DllName;
function mongoc_collection_keys_to_index_string; cdecl; external DllName;
function mongoc_collection_validate; cdecl; external DllName;

function mongoc_client_new; cdecl; external DllName;
function mongoc_client_new_from_uri; cdecl; external DllName;
function mongoc_client_get_uri; cdecl; external DllName;
procedure mongoc_client_set_stream_initiator; cdecl; external DllName;
function mongoc_client_command; cdecl; external DllName;
procedure mongoc_client_kill_cursor; cdecl; external DllName;
function mongoc_client_command_simple; cdecl; external DllName;
procedure mongoc_client_destroy; cdecl; external DllName;
function mongoc_client_get_database; cdecl; external DllName;
function mongoc_client_get_default_database; cdecl; external DllName;
function mongoc_client_get_gridfs; cdecl; external DllName;
function mongoc_client_get_collection; cdecl; external DllName;
function mongoc_client_get_database_names; cdecl; external DllName;
function mongoc_client_find_databases; cdecl; external DllName;
function mongoc_client_get_server_status; cdecl; external DllName;
function mongoc_client_get_max_message_size; cdecl; external DllName;
function mongoc_client_get_max_bson_size; cdecl; external DllName;
function mongoc_client_get_write_concern; cdecl; external DllName;
procedure mongoc_client_set_write_concern; cdecl; external DllName;
function mongoc_client_get_read_concern; cdecl; external DllName;
procedure mongoc_client_set_read_concern; cdecl; external DllName;
function mongoc_client_get_read_prefs; cdecl; external DllName;
procedure mongoc_client_set_read_prefs; cdecl; external DllName;
{$IFDEF MONGOC_ENABLE_SSL}
procedure mongoc_client_set_ssl_opts; cdecl; external DllName;
{$ENDIF}
function mongoc_client_pool_new; cdecl; external DllName;
procedure mongoc_client_pool_destroy; cdecl; external DllName;
function mongoc_client_pool_pop; cdecl; external DllName;
procedure mongoc_client_pool_push; cdecl; external DllName;
function mongoc_client_pool_try_pop; cdecl; external DllName;
procedure mongoc_client_pool_max_size; cdecl; external DllName;
procedure mongoc_client_pool_min_size; cdecl; external DllName;
{$IFDEF MONGOC_ENABLE_SSL}
procedure mongoc_client_pool_set_ssl_opts; cdecl; external DllName;
{$ENDIF}
function mongoc_database_get_name; cdecl; external DllName;
function mongoc_database_remove_user; cdecl; external DllName;
function mongoc_database_remove_all_users; cdecl; external DllName;
function mongoc_database_add_user; cdecl; external DllName;
procedure mongoc_database_destroy; cdecl; external DllName;
function mongoc_database_copy; cdecl; external DllName;
function mongoc_database_command; cdecl; external DllName;
function mongoc_database_command_simple; cdecl; external DllName;
function mongoc_database_drop; cdecl; external DllName;
function mongoc_database_has_collection; cdecl; external DllName;
function mongoc_database_create_collection ;cdecl; external DllName;
function mongoc_database_get_read_prefs; cdecl; external DllName;
procedure mongoc_database_set_read_prefs; cdecl; external DllName;
function mongoc_database_get_write_concern; cdecl; external DllName;
procedure mongoc_database_set_write_concern; cdecl; external DllName;
function mongoc_database_get_read_concern; cdecl; external DllName;
procedure mongoc_database_set_read_concern; cdecl; external DllName;
function mongoc_database_find_collections; cdecl; external DllName;
function mongoc_database_get_collection_names; cdecl; external DllName;
function mongoc_database_get_collection; cdecl; external DllName;

function mongoc_find_and_modify_opts_new: PMongocFindAndModifyFlag; cdecl; external DllName;
function mongoc_find_and_modify_opts_set_sort; cdecl; external DllName;
function mongoc_find_and_modify_opts_set_update; cdecl; external DllName;
function mongoc_find_and_modify_opts_set_fields; cdecl; external DllName;
function mongoc_find_and_modify_opts_set_flags; cdecl; external DllName;
function mongoc_find_and_modify_opts_set_bypass_document_validation; cdecl; external DllName;
procedure mongoc_find_and_modify_opts_destroy; cdecl; external DllName;

procedure mongoc_server_description_destroy; cdecl; external DllName;
function mongoc_server_description_new_copy; cdecl; external DllName;
function mongoc_server_description_id; cdecl; external DllName;
function mongoc_server_description_host; cdecl; external DllName;

procedure mongoc_log_set_handler; cdecl; external DllName;

procedure mongoc_log; cdecl; external DllName; varargs;
procedure mongoc_log_default_handler; cdecl; external DllName;

function mongoc_log_level_str; cdecl; external DllName;

function mongoc_matcher_new; cdecl; external DllName;
function mongoc_matcher_match; cdecl; external DllName;
procedure mongoc_matcher_destroy; cdecl; external DllName;

procedure mongoc_init; cdecl; external DllName;
procedure mongoc_cleanup; cdecl; external DllName;

function mongoc_get_major_version: Integer; cdecl; external DllName;
function mongoc_get_minor_version: Integer; cdecl; external DllName;
function mongoc_get_micro_version: Integer; cdecl; external DllName;
function mongoc_get_version: PAnsiChar; cdecl; external DllName;
function mongoc_check_version; cdecl; external DllName;

end.
