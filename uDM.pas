unit uDM;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  FireDAC.DApt,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client;

type
  TDatabase = class(TFDConnection)
  public
  end;

  TQuery = class(TFDQuery)
  public
    function ToJSON(const ACompact: Boolean = True): string;
  end;

  TDM = class(TDataModule)
  private
  public
    function  ExecuteQuery(const ASQL: string; out AResult: Integer): string;
    function  GetConnection: TDatabase;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  JsonDataObjects;

{ TQuery }

function TQuery.ToJSON(const ACompact: Boolean): string;
var
  LArray: TJSONArray;
  LRecord: TJSONObject;
  LFieldName: string;
  i: Integer;
begin
  LArray := TJSONArray.Create;
  try
    First;
    while not eof do
    begin
      LRecord := LArray.AddObject;

      for i := 0 to Fields.Count-1 do
      begin
        LFieldName := Fields[i].Name;

        case Fields[i].DataType of
        ftBoolean:
          LRecord.B[LFieldName] := Fields[i].AsBoolean;
        ftDate, ftDateTime:
          LRecord.D[LFieldName] := Fields[i].AsDateTime;
        ftAutoInc, ftInteger:
          LRecord.I[LFieldName] := Fields[i].AsInteger;
        ftLargeint:
          LRecord.L[LFieldName] := Fields[i].AsLargeInt;
        ftString, ftWideString, ftFixedChar, ftFixedWideChar:
          LRecord.S[LFieldName] := Fields[i].AsString;
        end;
      end;

      Next;
    end;

    Result := LArray.ToJSON(ACompact);
  finally
    LArray.Free;
  end;
end;

{ TDM }

function TDM.ExecuteQuery(const ASQL: string; out AResult: Integer): string;
var
  LConnection: TDatabase;
  LQuery: TQuery;
begin
  LConnection := DM.GetConnection;
  LQuery := TQuery.Create(nil);
  try
    try
      LQuery.Connection := LConnection;
      LQuery.SQL.Text := 'select * from address';
      LQuery.Open;
      Result := LQuery.ToJSON;
      LQuery.Close;
    except
      AResult := 404;
      Result := '{}';
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TDM.GetConnection: TDatabase;
begin
  Result := TDatabase.Create(nil);
  Result.LoginPrompt := False;
  Result.Params.Values['CharacterSet'] := 'utf8';

  // 아래에 사용할 데이터베이스 정보를 변경한다
  Result.Params.Values['DriverID'] := 'MySQL';
  Result.Params.Values['Server'] := '127.0.0.1';
  Result.Params.Values['Database'] := 'samples';
  Result.Params.Values['User_Name'] := 'root';
  Result.Params.Values['Password'] := '';
end;

end.
