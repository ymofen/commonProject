//Convert From mongo-c-driver v1.3.5
//Hezihang@ cnblogs.com

unit DriverBson;

interface

type

  { A value of TBsonType indicates the type of the data associated
    with a field within a BSON document. }
  TBsonType = (bsonEOO = 0, bsonDOUBLE = 1, bsonSTRING = 2, bsonOBJECT = 3, bsonARRAY = 4, bsonBINDATA = 5, bsonUNDEFINED = 6, bsonOID = 7, bsonBOOL = 8,
    bsonDATE = 9, bsonNULL = 10, bsonREGEX = 11, bsonDBREF = 12,
    (* Deprecated. *)
    bsonCODE = 13, bsonSYMBOL = 14, bsonCODEWSCOPE = 15, bsonINT = 16, bsonTIMESTAMP = 17, bsonLONG = 18, bsonMAXKEY = $7F, bsonMINKEY = $FF);

  TBsonSubType = (BSON_SUBTYPE_BINARY = $00, BSON_SUBTYPE_FUNCTION = $01, BSON_SUBTYPE_BINARY_DEPRECATED = $02, BSON_SUBTYPE_UUID_DEPRECATED = $03,
    BSON_SUBTYPE_UUID = $04, BSON_SUBTYPE_MD5 = $05, BSON_SUBTYPE_USER = $80);

  TBsonValidateFlags = ( // bson_validate_flags_t
    BSON_VALIDATE_NONE = 0, BSON_VALIDATE_UTF8 = (1 shl 0), BSON_VALIDATE_DOLLAR_KEYS = (1 shl 1), BSON_VALIDATE_DOT_KEYS = (1 shl 2),
    BSON_VALIDATE_UTF8_ALLOW_NULL = (1 shl 3));

  TBsonContextFlags = ( // bson_context_flags_t
    BSON_CONTEXT_NONE = 0, BSON_CONTEXT_THREAD_SAFE = (1 shl 0), BSON_CONTEXT_DISABLE_HOST_CACHE = (1 shl 1), BSON_CONTEXT_DISABLE_PID_CACHE = (1 shl 2)
{$IFDEF LINUX}
    , BSON_CONTEXT_USE_TASK_ID = (1 shl 3)
{$ENDIF}
    );

  TBsonOid = array [0 .. 11] of Byte;
  PBsonOid = ^TBsonOid;

  PBson = Pointer;
  TBsonArray = array [0 .. 0] of PBson;
  PBsonArray = ^TBsonArray;

  ssize_t = NativeInt;
  size_t = NativeInt;

  TBsonError = record
    domain: UInt32;
    code: UInt32;
    message: array [0 .. 503] of AnsiChar;
  end;

  PBsonError = ^TBsonError;

  TBsonReallocFunc = procedure(mem: Pointer; num_bytes: size_t; ctx: Pointer); cdecl;

  time_t = UInt32;

  timeval = record
    tv_sec: UInt32;
    tv_usec: UInt32;
  end;

  ptimeval = ^timeval;

  t_timestamp = record
    timestamp, increment: UInt32;
  end;

  t_utf8 = record
    len: UInt32;
    str: PAnsiChar;
  end;

  t_doc = record
    data_len: UInt32;
    data: Pointer;
  end;

  t_binary = record
    data_len: UInt32;
    data: Pointer;
    subtype: TBsonSubType;
  end;

  t_regex = record
    regex: PAnsiChar;
    options: PAnsiChar;
  end;

  t_dbPointer = record
    collection: PAnsiChar;
    collection_len: UInt32;
    oid: TBsonOid;
  end;

  t_code = record
    code_len: UInt32;
    code: PAnsiChar;
  end;

  t_codewscope = record
    code_len: UInt32;
    code: PAnsiChar;
    scope_len: UInt32;
    scope_data: Pointer;
  end;

  t_symbol = record
    len: UInt32;
    symbol: PAnsiChar;
  end;

{$ALIGN 8}

  TBsonValue = record
    case value_type: TBsonType of
      bsonEOO:
        ();
      bsonDOUBLE:
        (v_double: Double);
      bsonOBJECT:
        (v_int64: Int64);
      bsonARRAY:
        (v_int32: Int32);
      bsonUNDEFINED:
        (v_int8: Byte);
      bsonDATE:
        (v_datetime: Int64);

      bsonOID:
        (v_oid: TBsonOid);
      bsonBOOL:
        (v_bool: Boolean);
      bsonTIMESTAMP:
        (v_timestamp: t_timestamp);
      bsonSTRING:
        (v_utf8: t_utf8);
      bsonNULL:
        (v_doc: t_doc);
      bsonBINDATA:
        (v_binary: t_binary);
      bsonREGEX:
        (v_regex: t_regex);
      bsonLONG:
        (v_dbPointer: t_dbPointer);
      bsonCODE:
        (v_code: t_code);
      bsonCODEWSCOPE:
        (v_codewscope: t_codewscope);
      bsonSYMBOL:
        (v_symbol: t_symbol);
  end;
{$A-}
{$A+}

  PBsonIterator = ^TBsonIterator;

{$IFDEF CPU32BITS}
{$ALIGN 4}
{$ENDIF}
{$IFDEF CPU64BITS}
{$ALIGN 8}
{$ENDIF}

  TBsonIterator = record
    raw: Pointer; // The raw buffer being iterated.
    len: UInt32; // The length of raw.
    off: UInt32; // The offset within the buffer.
    _type: UInt32; // The offset of the type byte.
    key: UInt32; // The offset of the key byte.
    d1: UInt32; // The offset of the first data byte.
    d2: UInt32; // The offset of the second data byte.
    d3: UInt32; // The offset of the third data byte.
    d4: UInt32; // The offset of the fourth data byte.
    next_off: UInt32; // The offset of the next field.
    err_off: UInt32; // The offset of the error.
    value: TBsonValue; // Internal value for various state.
  end;
{$A-}
{$A+}

  PBsonValue = ^TBsonValue;

  PBsonContext = Pointer;

//function bson_iter_create: PBsonIterator;
//procedure bson_iter_dispose(iter: PBsonIterator);

function bson_get_major_version: Integer; cdecl;
function bson_get_minor_version: Integer; cdecl;
function bson_get_micro_version: Integer; cdecl;
function bson_get_version: PInteger; cdecl;
function bson_check_version(required_major, required_minor, required_micro: Integer): Boolean; cdecl;

function bson_get_monotonic_time: Int64; cdecl;
function bson_gettimeofday(tv: ptimeval): Integer; cdecl;

function bson_context_new(flags: TBsonValidateFlags): PBsonContext; cdecl;
procedure bson_context_destroy(context: PBsonContext); cdecl;
function bson_context_get_default(): PBsonContext; cdecl;

function bson_new: PBson; cdecl;

function bson_new_from_json(data: Pointer; len: size_t; var error: TBsonError): PBson; cdecl;

function bson_init_from_json(Bson: PBson; data: Pointer; len: size_t; var error: TBsonError): Boolean; cdecl;

function bson_init_static(b: PBson; data: Pointer; len: size_t): Boolean; cdecl;

procedure bson_init(b: PBson); cdecl;

function bson_new_from_data(data: Pointer; len: size_t): PBson; cdecl;

function bson_new_from_buffer(var buf: Pointer; var buf_len: size_t; realloc_func: TBsonReallocFunc; realloc_func_ctx: Pointer): PBson; cdecl;

function bson_sized_new(size: size_t): PBson; cdecl;

function bson_copy(const Bson: PBson): PBson; cdecl;

procedure bson_copy_to(const src: PBson; dst: PBson); cdecl;

procedure bson_copy_to_excluding(const src: PBson; dst: PBson; const first_exclude: PAnsiChar); cdecl; varargs;

procedure bson_copy_to_excluding_noinit(const src: PBson; dst: PBson; const first_exclude: PAnsiChar); cdecl; varargs;

procedure bson_destroy(Bson: PBson); cdecl;

function bson_destroy_with_steal(Bson: PBson; steal: Boolean; var length: UInt32): Pointer; cdecl;

function bson_get_data(Bson: PBson): Pointer; cdecl;

function bson_count_keys(Bson: PBson): UInt32; cdecl;

function bson_has_field(const Bson: PBson; const key: PAnsiChar): Boolean; cdecl;

function bson_compare(const Bson: PBson; const other: PBson): Integer; cdecl;

function bson_equal(const Bson: PBson; const other: PBson): Integer; cdecl;

function bson_validate(const Bson: PBson; flags: TBsonValidateFlags; var offset: size_t): Boolean; cdecl;

function bson_as_json(const Bson: PBson; var length: size_t): PAnsiChar; cdecl;

function bson_array_as_json(const Bson: PBson; var length: size_t): PAnsiChar; cdecl;

function bson_append_value(Bson: PBson; const key: PAnsiChar; key_length: Integer; const value: PBsonValue): Boolean; cdecl;

function bson_append_array(Bson: PBson; const key: PAnsiChar; key_length: Integer; const array_: PBson): Boolean; cdecl;

function bson_append_binary(Bson: PBson; const key: PAnsiChar; key_length: Integer; subtype: TBsonSubType; const binary: Pointer; length: UInt32)
  : Boolean; cdecl;

function bson_append_bool(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: Boolean): Boolean; cdecl;

function bson_append_code(Bson: PBson; const key: PAnsiChar; key_length: Integer; const javascript: PAnsiChar): Boolean; cdecl;

function bson_append_code_with_scope(Bson: PBson; const key: PAnsiChar; key_length: Integer; const javascript: PAnsiChar; const scope: PBson): Boolean; cdecl;

function bson_append_dbPointer(Bson: PBson; const key: PAnsiChar; key_length: Integer; const collection: PAnsiChar; const oid: PBsonOid): Boolean; cdecl;

function bson_append_double(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: Double): Boolean; cdecl;

function bson_append_document(Bson: PBson; const key: PAnsiChar; key_length: Integer; const value: PBson): Boolean; cdecl;

function bson_append_document_begin(Bson: PBson; const key: PAnsiChar; key_length: Integer; child: PBson): Boolean; cdecl;

function bson_append_document_end(Bson, child: PBson): Boolean; cdecl;

function bson_append_array_begin(Bson: PBson; const key: PAnsiChar; key_length: Integer; child: PBson): Boolean; cdecl;
function bson_append_array_end(Bson, child: PBson): Boolean; cdecl;

function bson_append_int32(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: Int32): Boolean; cdecl;

function bson_append_int64(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: Int64): Boolean; cdecl;

function bson_append_iter(Bson: PBson; const key: PAnsiChar; key_length: Integer; const iter: PBsonIterator): Boolean; cdecl;

function bson_append_minkey(Bson: PBson; const key: PAnsiChar; key_length: Integer): Boolean; cdecl;

function bson_append_maxkey(Bson: PBson; const key: PAnsiChar; key_length: Integer): Boolean; cdecl;
function bson_append_null(Bson: PBson; const key: PAnsiChar; key_length: Integer): Boolean; cdecl;

function bson_append_oid(Bson: PBson; const key: PAnsiChar; key_length: Integer; const oid: PBsonOid): Boolean; cdecl;

function bson_append_regex(Bson: PBson; const key: PAnsiChar; key_length: Integer; const regex, options: PAnsiChar): Boolean; cdecl;
function bson_append_utf8(Bson: PBson; const key: PAnsiChar; key_length: Integer; const value: PAnsiChar; length: Integer): Boolean; cdecl;
function bson_append_symbol(Bson: PBson; const key: PAnsiChar; key_length: Integer; const value: PAnsiChar; length: Integer): Boolean; cdecl;

function bson_append_time_t(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: time_t; length: Integer): Boolean; cdecl;

function bson_append_timeval(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: timeval; length: Integer): Boolean; cdecl;

function bson_append_date_time(Bson: PBson; const key: PAnsiChar; key_length: Integer; value: Int64): Boolean; cdecl;

function bson_append_now_utc(Bson: PBson; const key: PAnsiChar; key_length: Integer): Boolean; cdecl;

function bson_append_timestamp(Bson: PBson; const key: PAnsiChar; key_length: Integer; timestamp, increment: UInt32): Boolean; cdecl;

function bson_append_undefined(Bson: PBson; const key: PAnsiChar; key_length: Integer): Boolean; cdecl;

function bson_concat(dst: PBson; const src: PBson): Boolean; cdecl;

procedure bson_iter_array(iter: PBsonIterator; var arraylen: UInt32; var arr: Pointer); cdecl;
function bson_iter_as_bool(iter: PBsonIterator): Boolean; cdecl;
function bson_iter_as_int64(iter: PBsonIterator): Int64; cdecl;
procedure bson_iter_binary(iter: PBsonIterator; var subtype: TBsonSubType; var binary_len: UInt32; var binary: PByte); cdecl;
function bson_iter_bool(iter: PBsonIterator): Boolean; cdecl;
function bson_iter_code(iter: PBsonIterator; var len: UInt32): PAnsiChar; cdecl;
function bson_iter_codewscope(iter: PBsonIterator; var length, scope_len: UInt32; var scope: Pointer): PAnsiChar; cdecl;
function bson_iter_date_time(iter: PBsonIterator): Int64; cdecl;
procedure bson_iter_dbPointer(iter: PBsonIterator; var collection_len: UInt32; var collection: PAnsiChar; var oid: PBsonOid); cdecl;
procedure bson_iter_document(iter: PBsonIterator; var document_len: UInt32; var document: Pointer); cdecl;
function bson_iter_double(iter: PBsonIterator): Double; cdecl;
function bson_iter_dup_utf8(iter: PBsonIterator; var length: UInt32): PAnsiChar; cdecl;
function bson_iter_find(iter: PBsonIterator; key: PAnsiChar): Boolean; cdecl;
function bson_iter_find_case(iter: PBsonIterator; key: PAnsiChar): Boolean; cdecl;
function bson_iter_find_descendant(iter: PBsonIterator; dotkey: PAnsiChar; descendant: PBsonIterator): Boolean; cdecl;
procedure bson_iter_init(var iter: PBsonIterator; Bson: PBson); cdecl;
function bson_iter_init_find(var iter: PBsonIterator; Bson: PBson; key: PAnsiChar): Boolean; cdecl;
function bson_iter_init_find_case(var iter: PBsonIterator; Bson: PBson; key: PAnsiChar): Boolean; cdecl;
function bson_iter_int32(iter: PBsonIterator): Int32; cdecl;
function bson_iter_int64(iter: PBsonIterator): Int64; cdecl;
function bson_iter_key(iter: PBsonIterator): PAnsiChar; cdecl;
function bson_iter_next(iter: PBsonIterator): Boolean; cdecl;
function bson_iter_oid(iter: PBsonIterator): PBsonOid; cdecl;
procedure bson_iter_overwrite_bool(iter: PBsonIterator; value: Boolean); cdecl;
procedure bson_iter_overwrite_double(iter: PBsonIterator; value: Double); cdecl;
procedure bson_iter_overwrite_int32(iter: PBsonIterator; value: Int32); cdecl;
procedure bson_iter_overwrite_int64(iter: PBsonIterator; value: Int64); cdecl;
function bson_iter_recurse(iter: PBsonIterator; child: Pointer): Boolean; cdecl;
function bson_iter_regex(iter: PBsonIterator; options: PPAnsiChar): PAnsiChar; cdecl;
function bson_iter_symbol(iter: PBsonIterator; var length: UInt32): PAnsiChar; cdecl;
function bson_iter_time_t(iter: PBsonIterator): Int64; cdecl;
procedure bson_iter_timestamp(iter: PBsonIterator; var timestamp, increment: UInt32); cdecl;
procedure bson_iter_timeval(iter: PBsonIterator; var tv: timeval); cdecl;
function bson_iter_type(iter: PBsonIterator): TBsonType; cdecl;
function bson_iter_utf8(iter: PBsonIterator; var length: UInt32): PAnsiChar; cdecl;
function bson_iter_value(iter: PBsonIterator): PBsonValue; cdecl;
function bson_iter_visit_all(iter: PBsonIterator; visitor: Pointer; data: Pointer): Boolean; cdecl;

type
  pbson_json_reader_t = Pointer;

  TBsonJsonErrorCode = // bson_json_error_code_t
    (BSON_JSON_ERROR_READ_CORRUPT_JS = 1, BSON_JSON_ERROR_READ_INVALID_PARAM, BSON_JSON_ERROR_READ_CB_FAILURE);

  bson_json_reader_cb = function(handle: Pointer; buf: Pointer; count: size_t): ssize_t; cdecl;
  bson_json_destroy_cb = procedure(handle: Pointer); cdecl;

function bson_json_reader_new(data: Pointer; cb: bson_json_reader_cb; dcb: bson_json_destroy_cb; allow_multiple: Boolean; buf_size: size_t)
  : pbson_json_reader_t; cdecl;
function bson_json_reader_new_from_fd(fd: Integer; close_on_destroy: Boolean): pbson_json_reader_t; cdecl;
function bson_json_reader_new_from_file(const filename: PAnsiChar; var error: TBsonError): pbson_json_reader_t; cdecl;
procedure bson_json_reader_destroy(reader: pbson_json_reader_t); cdecl;
function bson_json_reader_read(reader: pbson_json_reader_t; Bson: PBson; var error: TBsonError): Integer; cdecl;
function bson_json_data_reader_new(allow_multiple: Boolean; size: size_t): pbson_json_reader_t; cdecl;
procedure bson_json_data_reader_ingest(reader: pbson_json_reader_t; const data: Pointer; len: size_t); cdecl;

function bson_oid_compare(const oid1: PBsonOid; const oid2: PBsonOid): Integer; cdecl;
procedure bson_oid_copy(const src: PBsonOid; dst: PBsonOid); cdecl;
function bson_oid_equal(const oid1: PBsonOid; const oid2: PBsonOid): Boolean; cdecl;
function bson_oid_is_valid(const str: PAnsiChar; length: size_t): Boolean; cdecl;
function bson_oid_get_time_t(const oid: PBsonOid): time_t; cdecl;
function bson_oid_hash(const oid: PBsonOid): UInt32; cdecl;
procedure bson_oid_init(oid: PBsonOid; context: PBsonContext); cdecl;
procedure bson_oid_init_from_data(oid: PBsonOid; const data: Pointer); cdecl;
procedure bson_oid_init_from_string(oid: PBsonOid; const str: PAnsiChar); cdecl;
procedure bson_oid_init_sequence(oid: PBsonOid; context: PBsonContext); cdecl;

type
  TOidString = packed array [0 .. 24] of AnsiChar;
procedure bson_oid_to_string(const oid: PBsonOid; var str: TOidString); cdecl;

type
  bson_reader_read_func_t = function(handle: Pointer; buf: Pointer; count: size_t): ssize_t; cdecl;
  bson_reader_destroy_func_t = procedure(handle: Pointer); cdecl;
  pbson_reader_t = Pointer;
  off_t = NativeInt;
function bson_reader_new_from_handle(handle: Pointer; rf: bson_reader_read_func_t; df: bson_reader_destroy_func_t): pbson_reader_t; cdecl;
function bson_reader_new_from_fd(fd: Integer; close_on_destroy: Boolean): pbson_reader_t; cdecl;
function bson_reader_new_from_file(const path: PAnsiChar; var error: TBsonError): pbson_reader_t; cdecl;
function bson_reader_new_from_data(const data: Pointer; length: size_t): pbson_reader_t; cdecl;
procedure bson_reader_destroy(reader: pbson_reader_t); cdecl;
procedure bson_reader_set_read_func(reader: pbson_reader_t; func: bson_reader_read_func_t); cdecl;
procedure bson_reader_set_destroy_func(reader: pbson_reader_t; func: bson_reader_destroy_func_t); cdecl;
function bson_reader_read(reader: pbson_reader_t; var reached_eof: Boolean): PBson; cdecl;
function bson_reader_tell(reader: pbson_reader_t): off_t; cdecl;

type
  TBsonString = record
    str: PAnsiChar;
    len, alloc: UInt32;
  end;

  PBsonString = ^TBsonString;
  bson_unichar_t = WideChar;

function bson_string_new(const str: PAnsiChar): PBsonString; cdecl;
function bson_string_free(str: PBsonString; free_segment: Boolean): PAnsiChar; cdecl;
procedure bson_string_append(str: PBsonString; const str2: PAnsiChar); cdecl;
procedure bson_string_append_c(str: PBsonString; str2: AnsiChar); cdecl;
procedure bson_string_append_unichar(str: PBsonString; unichar: bson_unichar_t); cdecl;
procedure bson_string_append_printf(str: PBsonString; const format: PAnsiChar); cdecl; varargs;
procedure bson_string_truncate(str: PBsonString; len: UInt32); cdecl;
function bson_strdup(const str: PAnsiChar): PAnsiChar; cdecl;
function bson_strdup_printf(const format: PAnsiChar): PAnsiChar; cdecl; varargs;
function bson_strdupv_printf(const format: PAnsiChar): PAnsiChar; cdecl; varargs;
function bson_strndup(const str: PAnsiChar; n_bytes: size_t): PAnsiChar; cdecl;
procedure bson_strncpy(dst: PAnsiChar; const src: PAnsiChar; size: size_t); cdecl;
function bson_vsnprintf(str: PAnsiChar; size: size_t; const format: PAnsiChar): Integer; cdecl;
function bson_snprintf(str: PAnsiChar; size: size_t; const format: PAnsiChar): Integer; cdecl;
procedure bson_strfreev(var strv: PAnsiChar); cdecl;
function bson_strnlen(const s: PAnsiChar; maxlen: size_t): size_t; cdecl;
function bson_ascii_strtoll(const str: PAnsiChar; var endptr: PAnsiChar; base: Integer): Int64; cdecl;

type
  pbson_writer_t = Pointer;
  bson_realloc_func = function(mem: Pointer; num_bytes: size_t; ctx: Pointer): Pointer; cdecl;

function bson_writer_new(var buf: Pointer; var buflen: size_t; offset: size_t; realloc_func: bson_realloc_func; realloc_func_ctx: Pointer)
  : pbson_writer_t; cdecl;
procedure bson_writer_destroy(writer: pbson_writer_t); cdecl;
function bson_writer_get_length(writer: pbson_writer_t): size_t; cdecl;
function bson_writer_begin(writer: pbson_writer_t; var Bson: PBson): Boolean; cdecl;
procedure bson_writer_end(writer: pbson_writer_t); cdecl;
procedure bson_writer_rollback(writer: pbson_writer_t); cdecl;

function bson_utf8_validate(const utf8: PAnsiChar; utf8_len: size_t; allow_null: Boolean): Boolean; cdecl;
function bson_utf8_escape_for_json(const utf8: PAnsiChar; utf8_len: ssize_t): PAnsiChar; cdecl;
function bson_utf8_get_char(const utf8: PAnsiChar): PWideChar; cdecl;
function bson_utf8_next_char(const utf8: PAnsiChar): PAnsiChar; cdecl;

type
  unichar_out = packed array [0 .. 5] of AnsiChar;
procedure bson_utf8_from_unichar(unichar: WideChar; var utf8: unichar_out; var len: UInt32); cdecl;

procedure bson_value_copy(const src: PBsonValue; dst: PBsonValue); cdecl;
procedure bson_value_destroy(value: PBsonValue); cdecl;

function bson_uint32_to_string(value: UInt32; const strptr: PPAnsiChar; str: PAnsiChar; size: size_t): size_t; cdecl;

const
  BSON_ERROR_JSON = 1;
  BSON_ERROR_READER = 2;
  BSON_ERROR_BUFFER_SIZE = 64;
procedure bson_set_error(var error: TBsonError; domain, code: UInt32; const format: PAnsiChar); cdecl; varargs;
function bson_strerror_r(err_code: Integer; buf: PAnsiChar; buflen: size_t): PAnsiChar; cdecl;

procedure bson_reinit(b: PBson); cdecl;

type
  bson_mem_vtable_t = record
    malloc: function(num_bytes: size_t): Pointer; cdecl;
    calloc: function(n_members: size_t; num_bytes: size_t): Pointer; cdecl;
    realloc: function(mem: Pointer; num_bytes: size_t): Pointer; cdecl;
    free: procedure(mem: Pointer); cdecl;
    padding: array [0 .. 3] of Pointer;
  end;

  pbson_mem_vtable_t = ^bson_mem_vtable_t;

procedure bson_mem_set_vtable(const vtable: pbson_mem_vtable_t); cdecl;
procedure bson_mem_restore_vtable(); cdecl;
function bson_malloc(num_bytes: size_t): Pointer; cdecl;
function bson_malloc0(num_bytes: size_t): Pointer; cdecl;
function bson_realloc(mem: Pointer; num_bytes: size_t): Pointer; cdecl;
function bson_realloc_ctx(mem: Pointer; num_bytes: size_t; ctx: Pointer): Pointer; cdecl;
procedure bson_free(mem: Pointer); cdecl;
procedure bson_zero_free(mem: Pointer; size: size_t); cdecl;

type
  bson_md5_t = record
    count: array [0 .. 1] of UInt32; // message length in bits, lsw first
    abcd: array [0 .. 3] of UInt32; // digest buffer
    buf: array [0 .. 63] of Byte; // accumulate block
  end;

  PBsonMD5 = ^bson_md5_t;
  md5_digest_t = array [0 .. 15] of Byte;
procedure bson_md5_init(pms: PBsonMD5); cdecl;
procedure bson_md5_append(pms: PBsonMD5; const data: Pointer; nbytes: UInt32); cdecl;
procedure bson_md5_finish(pms: PBsonMD5; digest: md5_digest_t); cdecl;

type
  pbcon_append_ctx_t = Pointer;
  pbcon_extract_ctx_t = Pointer;
procedure bcon_append(Bson: PBson); cdecl;
procedure bcon_append_ctx(Bson: PBson; ctx: pbcon_append_ctx_t); cdecl; varargs;
procedure bcon_append_ctx_va(Bson: PBson; ctx: pbcon_append_ctx_t; va: Pointer); cdecl;
procedure bcon_append_ctx_init(ctx: pbcon_append_ctx_t); cdecl;
procedure bcon_extract_ctx_init(ctx: pbcon_extract_ctx_t); cdecl;
procedure bcon_extract_ctx(Bson: PBson; ctx: pbcon_extract_ctx_t); cdecl; varargs;
function bcon_extract_ctx_va(Bson: PBson; ctx: pbcon_extract_ctx_t; ap: Pointer): Boolean; cdecl;
function bcon_extract(Bson: PBson): Boolean; cdecl; varargs;
function bcon_extract_va(Bson: PBson; ctx: pbcon_extract_ctx_t): Boolean; cdecl; varargs;
function bcon_new(unused: Pointer): PBson; cdecl; varargs;
function bson_bcon_magic: PAnsiChar; cdecl;
function bson_bcone_magic: PAnsiChar cdecl;

implementation

const
  bsondll = 'libbson-1.0-0.dll';

//function bson_iter_create: PBsonIterator;
//begin
//  GetMem(Result, SizeOf(TBsonIterator));
//end;
//
//procedure bson_iter_dispose(iter: PBsonIterator);
//begin
//  FreeMem(iter);
//end;

function bson_get_major_version: Integer; cdecl; external bsondll;
function bson_get_minor_version: Integer; cdecl; external bsondll;
function bson_get_micro_version: Integer; cdecl; external bsondll;
function bson_get_version: PInteger; cdecl; external bsondll;
function bson_check_version; cdecl; external bsondll;
function bson_get_monotonic_time: Int64; cdecl; external bsondll;
function bson_gettimeofday; cdecl; external bsondll;

function bson_context_new; cdecl; external bsondll;
procedure bson_context_destroy; cdecl; external bsondll;
function bson_context_get_default; cdecl; external bsondll;

function bson_new: PBson; cdecl; external bsondll;

function bson_new_from_json; cdecl; external bsondll;

function bson_init_from_json; cdecl; external bsondll;

function bson_init_static; cdecl; external bsondll;

procedure bson_init; cdecl; external bsondll;

function bson_new_from_data; cdecl; external bsondll;

function bson_new_from_buffer; cdecl; external bsondll;

function bson_sized_new; cdecl; external bsondll;

function bson_copy; cdecl; external bsondll;

procedure bson_copy_to; cdecl; external bsondll;

procedure bson_copy_to_excluding; cdecl; varargs; external bsondll;

procedure bson_copy_to_excluding_noinit; cdecl; varargs; external bsondll;

procedure bson_destroy; cdecl; external bsondll;

function bson_destroy_with_steal; cdecl; external bsondll;

function bson_get_data; cdecl; external bsondll;

function bson_count_keys; cdecl; external bsondll;

function bson_has_field; cdecl; external bsondll;

function bson_compare; cdecl; external bsondll;

function bson_equal; cdecl; external bsondll;

function bson_validate; cdecl; external bsondll;

function bson_as_json; cdecl; external bsondll;

function bson_array_as_json; cdecl; external bsondll;

function bson_append_value; cdecl; external bsondll;

function bson_append_array; cdecl; external bsondll;

function bson_append_binary; cdecl; external bsondll;

function bson_append_bool; cdecl; external bsondll;

function bson_append_code; cdecl; external bsondll;

function bson_append_code_with_scope; cdecl; external bsondll;

function bson_append_dbPointer; cdecl; external bsondll;

function bson_append_double; cdecl; external bsondll;

function bson_append_document; cdecl; external bsondll;

function bson_append_document_begin; cdecl; external bsondll;

function bson_append_document_end; cdecl; external bsondll;

function bson_append_array_begin; cdecl; external bsondll;
function bson_append_array_end; cdecl; external bsondll;

function bson_append_int32; cdecl; external bsondll;

function bson_append_int64; cdecl; external bsondll;

function bson_append_iter; cdecl; external bsondll;

function bson_append_minkey; cdecl; external bsondll;

function bson_append_maxkey; cdecl; external bsondll;
function bson_append_null; cdecl; external bsondll;

function bson_append_oid; cdecl; external bsondll;

function bson_append_regex; cdecl; external bsondll;
function bson_append_utf8; cdecl; external bsondll;
function bson_append_symbol; cdecl; external bsondll;
function bson_append_time_t; cdecl; external bsondll;

function bson_append_timeval; cdecl; external bsondll;

function bson_append_date_time; cdecl; external bsondll;

function bson_append_now_utc; cdecl; external bsondll;

function bson_append_timestamp; cdecl; external bsondll;

function bson_append_undefined; cdecl; external bsondll;

function bson_concat; cdecl; external bsondll;

procedure bson_iter_array; cdecl; external bsondll;

function bson_iter_as_bool; cdecl; external bsondll;
function bson_iter_as_int64; cdecl; external bsondll;
procedure bson_iter_binary; cdecl; external bsondll;
function bson_iter_bool; cdecl; external bsondll;
function bson_iter_code; cdecl; external bsondll;
function bson_iter_codewscope; cdecl; external bsondll;
function bson_iter_date_time; cdecl; external bsondll;
procedure bson_iter_dbPointer; cdecl; external bsondll;
procedure bson_iter_document; cdecl; external bsondll;
function bson_iter_double; cdecl; external bsondll;
function bson_iter_dup_utf8; cdecl; external bsondll;
function bson_iter_find; cdecl; external bsondll;
function bson_iter_find_case; cdecl; external bsondll;
function bson_iter_find_descendant; cdecl; external bsondll;
procedure bson_iter_init; cdecl; external bsondll;
function bson_iter_init_find; cdecl; external bsondll;
function bson_iter_init_find_case; cdecl; external bsondll;
function bson_iter_int32; cdecl; external bsondll;
function bson_iter_int64; cdecl; external bsondll;
function bson_iter_key; cdecl; external bsondll;
function bson_iter_next; cdecl; external bsondll;
function bson_iter_oid; cdecl; external bsondll;
procedure bson_iter_overwrite_bool; cdecl; external bsondll;
procedure bson_iter_overwrite_double; cdecl; external bsondll;
procedure bson_iter_overwrite_int32; cdecl; external bsondll;
procedure bson_iter_overwrite_int64; cdecl; external bsondll;
function bson_iter_recurse; cdecl; external bsondll;
function bson_iter_regex; cdecl; external bsondll;
function bson_iter_symbol; cdecl; external bsondll;
function bson_iter_time_t; cdecl; external bsondll;
procedure bson_iter_timestamp; cdecl; external bsondll;
procedure bson_iter_timeval; cdecl; external bsondll;

function bson_iter_type; cdecl; external bsondll;
function bson_iter_utf8; cdecl; external bsondll;
function bson_iter_value; cdecl; external bsondll;

function bson_iter_visit_all; cdecl; external bsondll;

function bson_json_reader_new; cdecl; external bsondll;
function bson_json_reader_new_from_fd; cdecl; external bsondll;
function bson_json_reader_new_from_file; cdecl; external bsondll;
procedure bson_json_reader_destroy; cdecl; external bsondll;
function bson_json_reader_read; cdecl; external bsondll;
function bson_json_data_reader_new; cdecl; external bsondll;
procedure bson_json_data_reader_ingest; cdecl; external bsondll;

function bson_oid_compare; cdecl; external bsondll;
procedure bson_oid_copy; cdecl; external bsondll;
function bson_oid_equal; cdecl; external bsondll;
function bson_oid_is_valid; cdecl; external bsondll;
function bson_oid_get_time_t; cdecl; external bsondll;
function bson_oid_hash; cdecl; external bsondll;
procedure bson_oid_init; cdecl; external bsondll;
procedure bson_oid_init_from_data; cdecl; external bsondll;
procedure bson_oid_init_from_string; cdecl; external bsondll;
procedure bson_oid_init_sequence; cdecl; external bsondll;
procedure bson_oid_to_string; cdecl; external bsondll;

function bson_reader_new_from_handle; cdecl; external bsondll;
function bson_reader_new_from_fd; cdecl; external bsondll;
function bson_reader_new_from_file; cdecl; external bsondll;
function bson_reader_new_from_data; cdecl; external bsondll;
procedure bson_reader_destroy; cdecl; external bsondll;
procedure bson_reader_set_read_func; cdecl; external bsondll;
procedure bson_reader_set_destroy_func; cdecl; external bsondll;
function bson_reader_read; cdecl; external bsondll;
function bson_reader_tell; cdecl; external bsondll;

function bson_string_new; cdecl; external bsondll;
function bson_string_free; cdecl; external bsondll;
procedure bson_string_append; cdecl; external bsondll;
procedure bson_string_append_c; cdecl; external bsondll;
procedure bson_string_append_unichar; cdecl; external bsondll;
procedure bson_string_append_printf; cdecl; varargs; external bsondll;
procedure bson_string_truncate; cdecl; external bsondll;
function bson_strdup; cdecl; external bsondll;
function bson_strdup_printf; cdecl; varargs; external bsondll;
function bson_strdupv_printf; cdecl; varargs; external bsondll;
function bson_strndup; cdecl; external bsondll;
procedure bson_strncpy; cdecl; external bsondll;
function bson_vsnprintf; cdecl; external bsondll;
function bson_snprintf; cdecl; external bsondll;
procedure bson_strfreev; cdecl; external bsondll;
function bson_strnlen; cdecl; external bsondll;
function bson_ascii_strtoll; cdecl; external bsondll;

function bson_writer_new; cdecl; external bsondll;
procedure bson_writer_destroy; cdecl; external bsondll;
function bson_writer_get_length; cdecl; external bsondll;
function bson_writer_begin; cdecl; external bsondll;
procedure bson_writer_end; cdecl; external bsondll;
procedure bson_writer_rollback; cdecl; external bsondll;

function bson_utf8_validate; cdecl; external bsondll;
function bson_utf8_escape_for_json; cdecl; external bsondll;
function bson_utf8_get_char; cdecl; external bsondll;
function bson_utf8_next_char; cdecl; external bsondll;
procedure bson_utf8_from_unichar; cdecl; external bsondll;

procedure bson_value_copy; cdecl; external bsondll;
procedure bson_value_destroy; cdecl; external bsondll;

function bson_uint32_to_string; cdecl; external bsondll;

procedure bson_set_error; cdecl; varargs; external bsondll;
function bson_strerror_r; cdecl; external bsondll;

procedure bson_mem_set_vtable; cdecl; external bsondll;
procedure bson_mem_restore_vtable; cdecl; external bsondll;
function bson_malloc; cdecl; external bsondll;
function bson_malloc0; cdecl; external bsondll;
function bson_realloc; cdecl; external bsondll;
function bson_realloc_ctx; cdecl; external bsondll;
procedure bson_free; cdecl; external bsondll;
procedure bson_zero_free; cdecl; external bsondll;

procedure bson_md5_init; cdecl; external bsondll;
procedure bson_md5_append; cdecl; external bsondll;
procedure bson_md5_finish; cdecl; external bsondll;

procedure bson_reinit; cdecl; external bsondll;

procedure bcon_append; cdecl; external bsondll;
procedure bcon_append_ctx; cdecl; varargs; external bsondll;
procedure bcon_append_ctx_va; cdecl; external bsondll;
procedure bcon_append_ctx_init; cdecl; external bsondll;
procedure bcon_extract_ctx_init; cdecl; external bsondll;
procedure bcon_extract_ctx; cdecl; varargs; external bsondll;
function bcon_extract_ctx_va; cdecl; external bsondll;
function bcon_extract; cdecl; varargs; external bsondll;
function bcon_extract_va; cdecl; varargs; external bsondll;
function bcon_new; cdecl; varargs; external bsondll;
function bson_bcon_magic: PAnsiChar; cdecl; external bsondll;
function bson_bcone_magic: PAnsiChar cdecl; external bsondll;

end.
