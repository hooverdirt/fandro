unit uSettings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Forms, IniFiles, Registry;


  function HomeDirectory : string;
  procedure LoadSettings;
  procedure SaveSettings;
  procedure AddItemToHistoryStrings(anitem : string; StL : TStrings; maxitems :
  integer; AddToTop : Boolean);
  function HookRegistered : boolean;

var
  iMainWindowState : Integer;
  iMainLeft, iMainTop, iMainWidth, iMainHeight : SmallInt;
  iMaxListItems : Byte;
  sMaskList, sWordList, sColumnSizes : string;


implementation

const FANDRO_GUID = '{EBDF1F20-C829-11D1-8233-00301F3E97B9}';
      FANDRO_DESCRIPTION = 'Fandro Search Shell extensions';

function HomeDirectory : string;
begin
  result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end;

procedure LoadSettings;
var iniFile : TIniFile;
begin
  iniFile := TIniFile.Create(HomeDirectory + 'fandro.ini');
  try
    iMainWindowState :=
      Byte(iniFile.ReadInteger('formMain', 'MainWindowState', Byte(wsNormal)));
    iMainLeft := iniFile.ReadInteger('formMain', 'MainLeft', 200);
    iMainTop := iniFile.ReadInteger('formMain', 'MainTop', 119);
    iMainWidth := iniFile.ReadInteger('formMain', 'MainWidth', 596);
    iMainheight := iniFile.ReadInteger('formMain', 'MainHeight', 529);
    iMaxListItems := iniFile.ReadInteger('formMain', 'MaxListItems', 20);
    sMaskList := iniFile.ReadString('formMain', 'MaskList', '');
    sWordList := iniFile.ReadString('formMain', 'WordList', '');
    sColumnSizes := iniFile.ReadString('formMain', 'ColumnSizes', '');
  finally
    iniFile.Free;
  end;
end;

procedure SaveSettings;
var iniFile : TIniFile;
begin
  iniFile := TIniFile.Create(HomeDirectory + 'fandro.ini');
  try
    iniFile.WriteInteger('formMain', 'MainWindowState', iMainWindowState);
    iniFile.WriteInteger('formMain', 'MainLeft', iMainLeft);
    iniFile.WriteInteger('formMain', 'MainTop', iMainTop);
    iniFile.WriteInteger('formMain', 'MainWidth',  iMainWidth);
    iniFile.WriteInteger('formMain', 'MainHeight', iMainheight);
    iniFile.WriteInteger('formMain', 'MaxListItems', iMaxListItems);
    iniFile.WriteString('formMain', 'MaskList', sMaskList);
    iniFile.WriteString('formMain', 'WordList', sWordList);
    iniFile.WriteString('formMain', 'ColumnSizes', sColumnSizes);
  finally
    iniFile.Free;
  end;
end;

procedure AddItemToHistoryStrings(anitem : string; StL : TStrings; maxitems :
  integer; AddToTop : Boolean);
var i : integer;
begin
  i := StL.IndexOf(AnItem);
  if i > - 1 then
  begin
    Stl.Move(i, Ord(not AddToTop) * (StL.Count -1));
  end
  else
  begin
    if AddToTop then
      StL.Insert(0, anitem)
    else
      StL.Add(anItem);


    while StL.Count > maxitems do
    begin
      StL.Delete(Ord(AddToTop) * (Stl.Count -1));
    end;
  end;
end;


function HookRegistered : boolean;
var
  Registry: TRegistry;
  registrykey : string;
begin
  // HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{EBDF1F20-C829-11D1-8233-00301F3E97B9}
  registrykey := Format('SOFTWARE\Classes\CLSID\%s', [FANDRO_GUID]);
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    // False because we do not want to create it if it doesn't exist
    Registry.OpenKey(registrykey, False);
    Result := (Registry.ReadString('') = FANDRO_DESCRIPTION);
  finally
    Registry.Free;
  end;
end;


end.
