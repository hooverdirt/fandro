program fandro;

uses
  Forms, System,
  formMain in 'formMain.pas' {frmMain},
  uFinder in 'uFinder.pas',
  uFindThread in 'uFindThread.pas',
  formAbout in 'formAbout.pas' {frmAbout},
  uSettings in 'uSettings.pas';

var
  p : string;

{$R *.res}
begin
  Application.Initialize;
  Application.Title := 'Fandro';
  p := ParamStr(1);
  if p <> '' then
  begin
    CommandoTigers.HasData := False;
    if uFinder.ParseCommandLine(uFinder.CommandoTigers) then
    begin
      CommandoTigers.HasData := True;
    end;
  end;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
