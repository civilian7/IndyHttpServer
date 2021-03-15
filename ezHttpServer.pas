//
//  ezHttpServer.pas
//  Indy를 사용한 심플 HTTP 서버
//
//  안영제 (civilian7@gmail.com), 010-3795-8897
//
unit ezHttpServer;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.classes,
  System.Generics.Collections,
  IdBaseComponent,
  IdComponent,
  IdCustomTCPServer,
  IdCustomHTTPServer,
  IdGlobal,
  IdContext,
  IdCoderMIME,
  IdHttp,
  IdHTTPServer;

type
  TURIHandler = reference to procedure(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

  TEZHttpServer = class(TIdHttpServer)
  strict private
    type
      TURIHandlers = class;

      THandler = class
      private
        FAuthorizedOnly: Boolean;
        FProc: TURIHandler;
        FURI: string;
      public
        constructor Create(AURI: string; AAuthorizedOnly: Boolean; AProc: TURIHandler);

        property AurhorizedOnly: Boolean read FAuthorizedOnly;
        property Proc: TURIHandler read FProc;
        property URI: string read FURI;
      end;

      TURIHandlers = class
      private
        FGetHandlers: TObjectDictionary<string, THandler>;
        FPostHandlers: TObjectDictionary<string, THandler>;
        FServer: TEZHttpServer;
      public
        constructor Create(AServer: TEZHttpServer);
        destructor Destroy; override;

        procedure Add(ACommandType: THTTPCommandType; const AURI: string; AHandler: TURIHandler; AAuthorizedOnly: Boolean = False );
        function  Execute(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): Boolean;
        procedure Remove(ACommandType: THTTPCommandType; const AURI: string);

        property Server: TEZHttpServer read FServer;
      end;
  private
    FPort: Integer;
    FRootPath: string;
    FURIHandlers: TURIHandlers;

    procedure SetPort(const Value: Integer);
  protected
    procedure DoCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo); override;
    procedure InitComponent; override;
  public
    destructor Destroy; override;

    property Handlers: TURIHandlers read FURIHandlers;
    property Port: Integer read FPort write SetPort;
    property RootPath: string read FRootPath;
  end;

implementation

uses
  System.NetEncoding,
  System.IOUtils;

procedure LogPrint(ErrorMsg: string);
var
  LDirectory: string;
  LFileName: string;
  LLogFile: TextFile;
begin
  try
    LDirectory := ExtractFilePath(ParamStr(0));
    LFileName := LDirectory + '\' + DateToStr(Now) + '.log';
    AssignFile(LLogFile, LFileName);
    if FileExists(LFileName) then
      Append(LLogFile)
    else
      Rewrite(LLogFile);

    Writeln(LLogFile, DateTimetoStr(Now) + ': ' + ErrorMsg);
  finally
    Closefile(LLogFile);
  end;
end;

{ TEZHttpServer.THandler }

constructor TEZHttpServer.THandler.Create(AURI: string; AAuthorizedOnly: Boolean; AProc: TURIHandler);
begin
  FAuthorizedOnly := AAuthorizedOnly;
  FProc := AProc;
  FURI := AURI;
end;

{ TEZHttpServer.TURIHandlers }

constructor TEZHttpServer.TURIHandlers.Create(AServer: TEZHttpServer);
begin
  FServer := AServer;
  FGetHandlers := TObjectDictionary<string, THandler>.Create([doOwnsValues]);
  FPostHandlers := TObjectDictionary<string, THandler>.Create([doOwnsValues]);
end;

destructor TEZHttpServer.TURIHandlers.Destroy;
begin
  FGetHandlers.Free;
  FPostHandlers.Free;
  FServer := nil;

  inherited;
end;

procedure TEZHttpServer.TURIHandlers.Add(ACommandType: THTTPCommandType; const AURI: string; AHandler: TURIHandler; AAuthorizedOnly: Boolean);
var
  LHandler: THandler;
begin
  LHandler := nil;

  case ACommandType of
    hcUnknown: ;
    hcHEAD: ;
    hcGET:
      begin
        LHandler := THandler.Create(AURI, AAuthorizedOnly, AHandler);
        FGetHandlers.AddOrSetValue(AURI.ToUpper, LHandler);
      end;
    hcPOST:
      FPostHandlers.AddOrSetValue(AURI.ToUpper, LHandler);
    hcDELETE: ;
    hcPUT:
      begin
        LHandler := THandler.Create(AURI, AAuthorizedOnly, AHandler);
        FPostHandlers.AddOrSetValue(AURI.ToUpper, LHandler);
      end;
    hcTRACE: ;
    hcOPTION: ;
  end;
end;

function TEZHttpServer.TURIHandlers.Execute(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): Boolean;
var
  LHandler: THandler;
begin
  Result := True;
  case ARequestInfo.CommandType of
    hcGet:
      begin
        TMonitor.Enter(FGetHandlers);
        try
          Result := FGetHandlers.TryGetValue(ARequestInfo.URI.ToUpper, LHandler);
        finally
          TMonitor.Exit(FGetHandlers);
        end;
      end;
    hcPost:
      begin
        TMonitor.Enter(FPostHandlers);
        try
          Result := FPostHandlers.TryGetValue(ARequestInfo.URI.ToUpper, Lhandler);
        finally
          TMonitor.Exit(FPostHandlers);
        end;
      end;
   end;

  if Result then
  begin
    LHandler.Proc(AContext, ARequestInfo, AResponseInfo)
  end
  else
    AResponseInfo.ResponseNo := 404;
end;

procedure TEZHttpServer.TURIHandlers.Remove(ACommandType: THTTPCommandType; const AURI: string);
begin
  case ACommandType of
    hcGet:
      begin
        TMonitor.Enter(FGetHandlers);
        try
          FGetHandlers.Remove(AURI.ToUpper);
        finally
          TMonitor.Exit(FGetHandlers);
        end;
      end;
    hcPost:
      begin
        TMonitor.Enter(FPostHandlers);
        try
          FPostHandlers.Remove(AURI.ToUpper);
        finally
          TMonitor.Exit(FPostHandlers);
        end;
      end;
  end;
end;

{ TEZHttpServer }

destructor TEZHttpServer.Destroy;
begin
  if Active then
    Active := False;

  FURIHandlers.Free;

  inherited;
end;

procedure TEZHttpServer.DoCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Origin'] := '*';
  AResponseInfo.ContentType := 'text/html; charset=utf-8';
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.RawHeaders.Add('Cache-Control: no-cache');
  AResponseInfo.Pragma := 'no-cache';

  if not FURIHandlers.Execute(AContext, ARequestInfo, AResponseInfo) then
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentText := '';
  end;
end;

procedure TEZHttpServer.InitComponent;
begin
  inherited;

  FPort := 8080;
  FRootPath := ExtractFilePath(ParamStr(0));

  with Bindings.Add do
  begin
    IP := '0.0.0.0';
    Port := FPort;
  end;

  AutoStartSession := False;
  KeepAlive := False;
  ListenQueue := 5;
  MaxConnections := 0;
  ParseParams := True;
  ReuseSocket := rsOSDependent;
  ServerSoftware := 'ezHttpServer';
  SessionIDCookieName := 'ezHttpSessionID';
  SessionState := False;
  SessionTimeOut := 0;
  TerminateWaitTime := 5000;
  UseNagle := True;

  FURIHandlers := TURIHandlers.Create(Self);
end;

procedure TEZHttpServer.SetPort(const Value: Integer);
begin
  FPort := Value;
  FBindings[0].Port := FPort;
end;

end.
