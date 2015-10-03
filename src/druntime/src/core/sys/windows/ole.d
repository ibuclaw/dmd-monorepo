/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: Placed into public domain
 * Source: $(DRUNTIMESRC src/core/sys/windows/_ole.d)
 */
module core.sys.windows.ole;

private import core.sys.windows.windef, core.sys.windows.wingdi, core.sys.windows.uuid;

alias LPCSTR OLE_LPCSTR;

/+#define LRESULT LONG
#define HGLOBAL HANDLE+/

enum {
	OT_LINK = 1,
	OT_EMBEDDED,
	OT_STATIC
}

const OLEVERB_PRIMARY = 0;
const OF_SET          = 1;
const OF_GET          = 2;
const OF_HANDLER      = 4;

struct OLETARGETDEVICE {
	USHORT otdDeviceNameOffset;
	USHORT otdDriverNameOffset;
	USHORT otdPortNameOffset;
	USHORT otdExtDevmodeOffset;
	USHORT otdExtDevmodeSize;
	USHORT otdEnvironmentOffset;
	USHORT otdEnvironmentSize;
	BYTE   _otdData;
	BYTE*  otdData() { return &_otdData; }
}
alias OLETARGETDEVICE* LPOLETARGETDEVICE;

enum OLESTATUS {
	OLE_OK,
	OLE_WAIT_FOR_RELEASE,
	OLE_BUSY,
	OLE_ERROR_PROTECT_ONLY,
	OLE_ERROR_MEMORY,
	OLE_ERROR_STREAM,
	OLE_ERROR_STATIC,
	OLE_ERROR_BLANK,
	OLE_ERROR_DRAW,
	OLE_ERROR_METAFILE,
	OLE_ERROR_ABORT,
	OLE_ERROR_CLIPBOARD,
	OLE_ERROR_FORMAT,
	OLE_ERROR_OBJECT,
	OLE_ERROR_OPTION,
	OLE_ERROR_PROTOCOL,
	OLE_ERROR_ADDRESS,
	OLE_ERROR_NOT_EQUAL,
	OLE_ERROR_HANDLE,
	OLE_ERROR_GENERIC,
	OLE_ERROR_CLASS,
	OLE_ERROR_SYNTAX,
	OLE_ERROR_DATATYPE,
	OLE_ERROR_PALETTE,
	OLE_ERROR_NOT_LINK,
	OLE_ERROR_NOT_EMPTY,
	OLE_ERROR_SIZE,
	OLE_ERROR_DRIVE,
	OLE_ERROR_NETWORK,
	OLE_ERROR_NAME,
	OLE_ERROR_TEMPLATE,
	OLE_ERROR_NEW,
	OLE_ERROR_EDIT,
	OLE_ERROR_OPEN,
	OLE_ERROR_NOT_OPEN,
	OLE_ERROR_LAUNCH,
	OLE_ERROR_COMM,
	OLE_ERROR_TERMINATE,
	OLE_ERROR_COMMAND,
	OLE_ERROR_SHOW,
	OLE_ERROR_DOVERB,
	OLE_ERROR_ADVISE_NATIVE,
	OLE_ERROR_ADVISE_PICT,
	OLE_ERROR_ADVISE_RENAME,
	OLE_ERROR_POKE_NATIVE,
	OLE_ERROR_REQUEST_NATIVE,
	OLE_ERROR_REQUEST_PICT,
	OLE_ERROR_SERVER_BLOCKED,
	OLE_ERROR_REGISTRATION,
	OLE_ERROR_ALREADY_REGISTERED,
	OLE_ERROR_TASK,
	OLE_ERROR_OUTOFDATE,
	OLE_ERROR_CANT_UPDATE_CLIENT,
	OLE_ERROR_UPDATE,
	OLE_ERROR_SETDATA_FORMAT,
	OLE_ERROR_STATIC_FROM_OTHER_OS,
	OLE_ERROR_FILE_VER,
	OLE_WARN_DELETE_DATA = 1000
}

enum OLE_NOTIFICATION {
	OLE_CHANGED,
	OLE_SAVED,
	OLE_CLOSED,
	OLE_RENAMED,
	OLE_QUERY_PAINT,
	OLE_RELEASE,
	OLE_QUERY_RETRY
}

enum OLE_RELEASE_METHOD {
	OLE_NONE,
	OLE_DELETE,
	OLE_LNKPASTE,
	OLE_EMBPASTE,
	OLE_SHOW,
	OLE_RUN,
	OLE_ACTIVATE,
	OLE_UPDATE,
	OLE_CLOSE,
	OLE_RECONNECT,
	OLE_SETUPDATEOPTIONS,
	OLE_SERVERUNLAUNCH,
	OLE_LOADFROMSTREAM,
	OLE_SETDATA,
	OLE_REQUESTDATA,
	OLE_OTHER,
	OLE_CREATE,
	OLE_CREATEFROMTEMPLATE,
	OLE_CREATELINKFROMFILE,
	OLE_COPYFROMLNK,
	OLE_CREATEFROMFILE,
	OLE_CREATEINVISIBLE
}

enum OLEOPT_RENDER {
	olerender_none,
	olerender_draw,
	olerender_format
}

alias WORD OLECLIPFORMAT;

enum OLEOPT_UPDATE {
	oleupdate_always,
	oleupdate_onsave,
	oleupdate_oncall,
// #ifdef OLE_INTERNAL
	oleupdate_onclose
// #endif
}

mixin DECLARE_HANDLE!("HOBJECT");
alias LONG LHSERVER, LHCLIENTDOC, LHSERVERDOC;

struct OLEOBJECTVTBL {
	extern (Windows) {
		void* function(LPOLEOBJECT, OLE_LPCSTR) QueryProtocol;
		OLESTATUS function(LPOLEOBJECT) Release;
		OLESTATUS function(LPOLEOBJECT, BOOL) Show;
		OLESTATUS function(LPOLEOBJECT, UINT, BOOL, BOOL) DoVerb;
		OLESTATUS function(LPOLEOBJECT, OLECLIPFORMAT, HANDLE*) GetData;
		OLESTATUS function(LPOLEOBJECT, OLECLIPFORMAT, HANDLE) SetData;
		OLESTATUS function(LPOLEOBJECT, HGLOBAL) SetTargetDevice;
		OLESTATUS function(LPOLEOBJECT, RECT*) SetBounds;
		OLECLIPFORMAT function(LPOLEOBJECT, OLECLIPFORMAT) EnumFormats;
		OLESTATUS function(LPOLEOBJECT, LOGPALETTE*) SetColorScheme;
//#ifndef SERVERONLY
		OLESTATUS function(LPOLEOBJECT) Delete;
		OLESTATUS function(LPOLEOBJECT, OLE_LPCSTR, OLE_LPCSTR) SetHostNames;
		OLESTATUS function(LPOLEOBJECT, LPOLESTREAM) SaveToStream;
		OLESTATUS function(LPOLEOBJECT, LPOLECLIENT, LHCLIENTDOC, OLE_LPCSTR,
		  LPOLEOBJECT*) Clone;
		OLESTATUS function(LPOLEOBJECT, LPOLECLIENT, LHCLIENTDOC, OLE_LPCSTR,
		  LPOLEOBJECT*) CopyFromLink;
		OLESTATUS function(LPOLEOBJECT, LPOLEOBJECT) Equal;
		OLESTATUS function(LPOLEOBJECT) CopyToClipboard;
		OLESTATUS function(LPOLEOBJECT, HDC, RECT*, RECT*, HDC) Draw;
		OLESTATUS function(LPOLEOBJECT, UINT, BOOL, BOOL, HWND, RECT*)
		  Activate;
		OLESTATUS function(LPOLEOBJECT, HGLOBAL, UINT) Execute;
		OLESTATUS function(LPOLEOBJECT) Close;
		OLESTATUS function(LPOLEOBJECT) Update;
		OLESTATUS function(LPOLEOBJECT) Reconnect;
		OLESTATUS function(LPOLEOBJECT, OLE_LPCSTR, LPOLECLIENT, LHCLIENTDOC,
		  OLE_LPCSTR, LPOLEOBJECT*) ObjectConvert;
		OLESTATUS function(LPOLEOBJECT, OLEOPT_UPDATE*) GetLinkUpdateOptions;
		OLESTATUS function(LPOLEOBJECT, OLEOPT_UPDATE) SetLinkUpdateOptions;
		OLESTATUS function(LPOLEOBJECT, OLE_LPCSTR) Rename;
		OLESTATUS function(LPOLEOBJECT, LPSTR, UINT*) QueryName;
		OLESTATUS function(LPOLEOBJECT, LONG*) QueryType;
		OLESTATUS function(LPOLEOBJECT, RECT*) QueryBounds;
		OLESTATUS function(LPOLEOBJECT, DWORD*) QuerySize;
		OLESTATUS function(LPOLEOBJECT) QueryOpen;
		OLESTATUS function(LPOLEOBJECT) QueryOutOfDate;
		OLESTATUS function(LPOLEOBJECT) QueryReleaseStatus;
		OLESTATUS function(LPOLEOBJECT) QueryReleaseError;
		OLE_RELEASE_METHOD function(LPOLEOBJECT) QueryReleaseMethod;
		OLESTATUS function(LPOLEOBJECT, OLECLIPFORMAT) RequestData;
		OLESTATUS function(LPOLEOBJECT, UINT, LONG*) ObjectLong;
		OLESTATUS function(LPOLEOBJECT, HANDLE, LPOLECLIENT, BOOL) ChangeData;
//#endif
	}
}
alias OLEOBJECTVTBL* LPOLEOBJECTVTBL;

//#ifndef OLE_INTERNAL
struct OLEOBJECT {
	LPOLEOBJECTVTBL lpvtbl;
}
alias OLEOBJECT* LPOLEOBJECT;
//#endif

struct OLECLIENTVTBL {
	int function(LPOLECLIENT, OLE_NOTIFICATION, LPOLEOBJECT) CallBack;
}
alias OLECLIENTVTBL* LPOLECLIENTVTBL;

struct OLECLIENT {
	LPOLECLIENTVTBL lpvtbl;
}
alias OLECLIENT* LPOLECLIENT;

struct OLESTREAMVTBL {
	DWORD function(LPOLESTREAM, void*, DWORD) Get;
	DWORD function(LPOLESTREAM, void*, DWORD) Put;
}
alias OLESTREAMVTBL* LPOLESTREAMVTBL;

struct OLESTREAM {
	LPOLESTREAMVTBL lpstbl;
}
alias OLESTREAM* LPOLESTREAM;

enum OLE_SERVER_USE {
	OLE_SERVER_MULTI,
	OLE_SERVER_SINGLE
}

struct OLESERVERVTBL {
	OLESTATUS function(LPOLESERVER, LHSERVERDOC, OLE_LPCSTR, LPOLESERVERDOC*)
	  Open;
	OLESTATUS function(LPOLESERVER, LHSERVERDOC, OLE_LPCSTR, OLE_LPCSTR,
	  LPOLESERVERDOC*) Create;
	OLESTATUS function(LPOLESERVER, LHSERVERDOC, OLE_LPCSTR, OLE_LPCSTR,
	  OLE_LPCSTR, LPOLESERVERDOC*) CreateFromTemplate;
	OLESTATUS function(LPOLESERVER, LHSERVERDOC, OLE_LPCSTR, OLE_LPCSTR,
	  LPOLESERVERDOC*) Edit;
	OLESTATUS function(LPOLESERVER) Exit;
	OLESTATUS function(LPOLESERVER) Release;
	OLESTATUS function(LPOLESERVER, HGLOBAL) Execute;
}
alias TypeDef!(OLESERVERVTBL*) LPOLESERVERVTBL;

struct OLESERVER {
	LPOLESERVERVTBL lpvtbl;
}
alias OLESERVER* LPOLESERVER;

struct OLESERVERDOCVTBL {
	OLESTATUS function(LPOLESERVERDOC) Save;
	OLESTATUS function(LPOLESERVERDOC) Close;
	OLESTATUS function(LPOLESERVERDOC, OLE_LPCSTR, OLE_LPCSTR) SetHostNames;
	OLESTATUS function(LPOLESERVERDOC, RECT*) SetDocDimensions;
	OLESTATUS function(LPOLESERVERDOC, OLE_LPCSTR, LPOLEOBJECT*, LPOLECLIENT)
	  GetObject;
	OLESTATUS function(LPOLESERVERDOC) Release;
	OLESTATUS function(LPOLESERVERDOC, LOGPALETTE*) SetColorScheme;
	OLESTATUS function(LPOLESERVERDOC, HGLOBAL) Execute;
}
alias OLESERVERDOCVTBL* LPOLESERVERDOCVTBL;

struct OLESERVERDOC {
	LPOLESERVERDOCVTBL lpvtbl;
}
alias OLESERVERDOC* LPOLESERVERDOC;

extern (Windows) {
	OLESTATUS OleDelete(LPOLEOBJECT);
	OLESTATUS OleRelease(LPOLEOBJECT);
	OLESTATUS OleSaveToStream(LPOLEOBJECT, LPOLESTREAM);
	OLESTATUS OleEqual(LPOLEOBJECT, LPOLEOBJECT);
	OLESTATUS OleCopyToClipboard(LPOLEOBJECT);
	OLESTATUS OleSetHostNames(LPOLEOBJECT, LPCSTR, LPCSTR);
	OLESTATUS OleSetTargetDevice(LPOLEOBJECT, HGLOBAL);
	OLESTATUS OleSetBounds(LPOLEOBJECT, LPCRECT);
	OLESTATUS OleSetColorScheme(LPOLEOBJECT, const(LOGPALETTE)*);
	OLESTATUS OleQueryBounds(LPOLEOBJECT, RECT*);
	OLESTATUS OleQuerySize(LPOLEOBJECT, DWORD*);
	OLESTATUS OleDraw(LPOLEOBJECT, HDC, LPCRECT, LPCRECT, HDC);
	OLESTATUS OleQueryOpen(LPOLEOBJECT);
	OLESTATUS OleActivate(LPOLEOBJECT, UINT, BOOL, BOOL, HWND, LPCRECT);
	OLESTATUS OleExecute(LPOLEOBJECT, HGLOBAL, UINT);
	OLESTATUS OleClose(LPOLEOBJECT);
	OLESTATUS OleUpdate(LPOLEOBJECT);
	OLESTATUS OleReconnect(LPOLEOBJECT);
	OLESTATUS OleGetLinkUpdateOptions(LPOLEOBJECT, OLEOPT_UPDATE*);
	OLESTATUS OleSetLinkUpdateOptions(LPOLEOBJECT, OLEOPT_UPDATE);
	void* OleQueryProtocol(LPOLEOBJECT, LPCSTR);
	OLESTATUS OleQueryReleaseStatus(LPOLEOBJECT);
	OLESTATUS OleQueryReleaseError(LPOLEOBJECT);
	OLE_RELEASE_METHOD OleQueryReleaseMethod(LPOLEOBJECT);
	OLESTATUS OleQueryType(LPOLEOBJECT, LONG*);
	DWORD OleQueryClientVersion();
	DWORD OleQueryServerVersion();
	OLECLIPFORMAT OleEnumFormats(LPOLEOBJECT, OLECLIPFORMAT);
	OLESTATUS OleGetData(LPOLEOBJECT, OLECLIPFORMAT, HANDLE*);
	OLESTATUS OleSetData(LPOLEOBJECT, OLECLIPFORMAT, HANDLE);
	OLESTATUS OleQueryOutOfDate(LPOLEOBJECT);
	OLESTATUS OleRequestData(LPOLEOBJECT, OLECLIPFORMAT);
	OLESTATUS OleQueryLinkFromClip(LPCSTR, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleQueryCreateFromClip(LPCSTR, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleCreateFromClip(LPCSTR, LPOLECLIENT, LHCLIENTDOC, LPCSTR,
	  LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleCreateLinkFromClip(LPCSTR, LPOLECLIENT, LHCLIENTDOC, LPCSTR,
	  LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleCreateFromFile(LPCSTR, LPOLECLIENT, LPCSTR, LPCSTR,
	  LHCLIENTDOC, LPCSTR, LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleCreateLinkFromFile(LPCSTR, LPOLECLIENT, LPCSTR, LPCSTR,
	  LPCSTR, LHCLIENTDOC, LPCSTR, LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleLoadFromStream(LPOLESTREAM, LPCSTR, LPOLECLIENT, LHCLIENTDOC,
	  LPCSTR, LPOLEOBJECT*);
	OLESTATUS OleCreate(LPCSTR, LPOLECLIENT, LPCSTR, LHCLIENTDOC, LPCSTR,
	  LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleCreateInvisible(LPCSTR, LPOLECLIENT, LPCSTR, LHCLIENTDOC,
	  LPCSTR, LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT, BOOL);
	OLESTATUS OleCreateFromTemplate(LPCSTR, LPOLECLIENT, LPCSTR, LHCLIENTDOC,
	  LPCSTR, LPOLEOBJECT*, OLEOPT_RENDER, OLECLIPFORMAT);
	OLESTATUS OleClone(LPOLEOBJECT, LPOLECLIENT, LHCLIENTDOC, LPCSTR,
	  LPOLEOBJECT*);
	OLESTATUS OleCopyFromLink(LPOLEOBJECT, LPCSTR, LPOLECLIENT, LHCLIENTDOC,
	  LPCSTR, LPOLEOBJECT*);
	OLESTATUS OleObjectConvert(LPOLEOBJECT, LPCSTR, LPOLECLIENT, LHCLIENTDOC,
	  LPCSTR, LPOLEOBJECT*);
	OLESTATUS OleRename(LPOLEOBJECT, LPCSTR);
	OLESTATUS OleQueryName(LPOLEOBJECT, LPSTR, UINT*);
	OLESTATUS OleRevokeObject(LPOLECLIENT);
	BOOL OleIsDcMeta(HDC);
	OLESTATUS OleRegisterClientDoc(LPCSTR, LPCSTR, LONG, LHCLIENTDOC*);
	OLESTATUS OleRevokeClientDoc(LHCLIENTDOC);
	OLESTATUS OleRenameClientDoc(LHCLIENTDOC, LPCSTR);
	OLESTATUS OleRevertClientDoc(LHCLIENTDOC);
	OLESTATUS OleSavedClientDoc(LHCLIENTDOC);
	OLESTATUS OleEnumObjects(LHCLIENTDOC, LPOLEOBJECT*);
	OLESTATUS OleRegisterServer(LPCSTR, LPOLESERVER, LHSERVER*, HINSTANCE,
	  OLE_SERVER_USE);
	OLESTATUS OleRevokeServer(LHSERVER);
	OLESTATUS OleBlockServer(LHSERVER);
	OLESTATUS OleUnblockServer(LHSERVER, BOOL*);
	OLESTATUS OleLockServer(LPOLEOBJECT, LHSERVER*);
	OLESTATUS OleUnlockServer(LHSERVER);
	OLESTATUS OleRegisterServerDoc(LHSERVER, LPCSTR, LPOLESERVERDOC,
	  LHSERVERDOC*);
	OLESTATUS OleRevokeServerDoc(LHSERVERDOC);
	OLESTATUS OleRenameServerDoc(LHSERVERDOC, LPCSTR);
	OLESTATUS OleRevertServerDoc(LHSERVERDOC);
	OLESTATUS OleSavedServerDoc(LHSERVERDOC);
}
