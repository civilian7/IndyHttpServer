unit uMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  IdBaseComponent,
  IdComponent,
  IdCustomTCPServer,
  IdCustomHTTPServer,
  IdGlobal,
  IdContext,
  IdCoderMIME,
  IdHttp,
  ezHttpServer;

type
  TfrmMain = class(TForm)
    ePort: TEdit;
    Label1: TLabel;
    btnStart: TButton;
    btnStop: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FServer: TEZHttpServer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  uDM;

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;

  FServer := TEZHttpServer.Create(Self);
  FServer.Port := 8080;

  // 서비스로 처리할 것들을 추가한다
  FServer.Handlers.Add(
    hcGet,
    '/hello',
    procedure(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo)
    var
      LResult: Integer;
    begin
      AResponseInfo.ContentText := DM.ExecuteQuery('select * from address', LResult);
      AResponseInfo.ResponseNo := LResult;
    end
  );
end;

destructor TfrmMain.Destroy;
begin
  FServer.Free;

  inherited;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  FServer.Port := StrtoIntDef(ePort.Text, 9000);
  FServer.Active := True;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FServer.Active := False;
end;

end.
