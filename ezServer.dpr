program ezServer;

uses
  Forms,
  uDM in 'uDM.pas' {DM: TDataModule},
  uMain in 'uMain.pas' {frmMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TDM, DM);
  Application.Run;
end.
