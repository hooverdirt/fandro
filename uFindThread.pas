unit uFindThread;

interface

uses
  SysUtils, Classes, uFinder, StdCtrls, ComCtrls, ShellAPI, Windows;


type

  TAHSearchMode = (amsStopped, amsStarted, amsPaused);

  TAHSearchThread = class(TThread)
  private
    fSearchThing : TBMHWordsFinder;
    fFoundFileName : string;
    fPanelHint : string;
    fSearchRec : TSearchRec;
    fCountFiles, fFoundFiles, fCountSize : Int64;

    function FGetFiles(directory, mask : string; attr : integer;
       af : TFileSomething; recursive : Boolean) : integer;
    procedure FDoGetFile(dir : string; SearchRec : TSearchRec);
    procedure FDoUpdateListBox;
    procedure FDoUpdateStatus;
    procedure FDoAnimation;
    procedure FStopAnimation;
  protected
    procedure Execute; override;
  public
    FileCOnditions : TAHFileConditions;
    FileAttributes : integer;
    StartFolder : string;
    FileMask : string;
    LastFolder : string;
    KeyWords : string;
    Recursive : Boolean;
    UpdateListView: TListView;
    CaseSensitivity : Boolean;
    SearchMethod : TWordFind;
    WholeWords : Boolean;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses formMain;

{ TAHSearchThread }

constructor TAHSearchThread.Create;
begin
  inherited Create(False);
  fSearchThing := TBMHWordsFinder.Create;
  fCountFiles := 0;
  fFoundFiles := 0;
  fCountSize := 0;
end;

destructor TAHSearchThread.Destroy;
begin
  fSearchThing.Free;
  inherited;
end;

procedure TAHSearchThread.Execute;
begin
  inherited;
  fCountFiles := 0;
  fFoundFiles := 0;
  fCountSize := 0;
  fPanelHint := '';

  Synchronize(fDoUpdateStatus);
  if Assigned(UpdateListView) and (not Terminated) then
  begin
    // AH072905 --
    FSearchThing.SearchPattern := Self.KeyWords;
    FSearchThing.CaseInsensitive := not Self.CaseSensitivity;
    FSearchThing.WholeWord := Self.WholeWords;
    FSearchThing.TypeFind := Self.SearchMethod;
    Synchronize(FDoAnimation);
    FGetFiles(StartFolder, FileMask, faAnyFile,
      FDOGetFile, Recursive);
  end;
  Synchronize(FStopAnimation);

end;

procedure TAHSearchThread.FDoAnimation;
begin
  frmMain.aniAnimate.Active := True;
end;

procedure TAHSearchThread.FDoGetFile(dir: string; SearchRec: TSearchRec);
var FoundFile, MatchedConditions : Boolean;
begin
  fPanelHint := '(F) ' + IncludeTrailingPathDelimiter(dir) + SearchRec.Name;
  inc(fCountFiles);
  if (SearchRec.Attr and faDirectory) = 0 then
  begin
    if not
      IsFileInUse(IncludeTrailingPathDelimiter(dir) + SearchRec.Name) then
    begin
      //f.LoadFromFile(IncludeTrailingPathDelimiter(dir) + SearchRec.Name);
      MatchedConditions := True;

      if assigned(FileConditions) then
      begin
        if FileConditions.Count > 0 then
        begin
          //        FileConditions.Pass;
          FileConditions.SetSearchData(SearchRec);
          MatchedConditions := FIleConditions.DoMatch;
        end;
      end;

      if MatchedConditions then
      begin
        if FSearchThing.SearchPattern <> '' then
        begin
          FSearchThing.FileName := IncludeTrailingPathDelimiter(dir)
            + SearchRec.Name;
          FoundFile := FSearchThing.FindFirst > 0;
        end
        else
        begin
          // if empty but still pattern, go ahead!
          FoundFile := True;
        end;

        if FoundFile then
        begin
          fFoundFileName := IncludeTrailingPathDelimiter(dir) + SearchRec.Name;
          fSearchRec := SearchRec;
          Synchronize(FDoUpdateListBox);
          inc(fFoundFiles);
          inc(fCountSize, (SearchRec.Size div 1024));
        end;
      end;
    end;
  end;
  Synchronize(FDoUpdateStatus);
end;

procedure TAHSearchThread.FDoUpdateListBox;
var s : TListItem;
  SHFIleInfo : TSHFileInfo;
  m : TDateTime;
  fTime : Integer;
begin
  if Assigned(UpdateListView) then
  begin
    s := UpdateListVIew.Items.Add;
    s.Caption := fSearchRec.Name;
    SHGetFileInfo(PChar(fFoundFileName), 0, SHFileInfo, SizeOf(SHFileInfo),
      SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    s.ImageIndex := SHFileInfo.iIcon;
    s.SubItems.Add(ExtractFilePath(fFoundFileName));
    s.SubItems.Add(IntToStr(fSearchRec.Size));
    s.SubItems.Add(DateTimeToStr(FileDateToDateTime(fSearchRec.Time)));

    FileTimeToDosDateTime(fSearchRec.FindData.ftLastAccessTime,
      LongRec(fTime).Hi, LongRec(ftime).Lo);
    m := FileDateToDateTime(fTime);

    s.SubItems.Add(DateTimeToStr(m));

    FileTimeToDosDateTime(fSearchRec.FindData.ftCreationTime,
      LongRec(fTime).Hi, LongRec(ftime).Lo);
    m := FileDateToDateTime(fTime);

    s.SubItems.Add(DateTimeToStr(m));
  end;
end;

procedure TAHSearchThread.FDoUpdateStatus;
begin
  frmMain.sbInfoBar.Panels[0].Text := IntToStr(fCountFiles);
  frmMain.sbInfoBar.Panels[1].Text := IntToStr(fFoundFiles);
  frmMain.sbInfoBar.Panels[2].Text := Format('%8.3f MB', [KBToMB(fCountSize)]);
  frmMain.sbInfoBar.Panels[3].Text := FPanelhint;
end;

function TAHSearchThread.FGetFiles(directory, mask: string; attr: integer;
  af: TFileSomething; recursive: Boolean): integer;
var
  aSearchRec: TSearchRec;
  Found, i : Integer;
begin
  i := 0;
  fPanelHint := '(D) ' + IncludeTrailingPathDelimiter(directory);
  Synchronize(FDoUpdateStatus);
  Found := SysUtils.FindFirst(
    IncludeTrailingPathDelimiter(directory) + mask, faAnyFile, aSearchRec);
  try
    while (Found = 0) and (not Terminated) do
    begin
      if ((aSearchRec.Attr and attr) <> 0) {or
         ((aSearchRec.Attr and faHidden) <> 0) or
         ((aSearchRec.Attr and faReadOnly) <> 0)}
      then
      begin
        af(IncludeTrailingPathDelimiter(Directory), aSearchRec);
        inc(i);
      end;
      Found := SysUtils.FindNext(aSearchRec);
    end;

    if recursive then
    begin
      found:= SysUtils.FindFirst(IncludeTrailingPathDelimiter(Directory)
         + '*.*', faDirectory or faHidden, aSearchRec);
      while (Found = 0) and (not Terminated) do
      begin
        // was faDirectory > 1
        if (asearchRec.Attr and faDirectory) <> 0  then
        begin
          if( aSearchRec.NAME <> '.')
            and (aSearchRec.NAME <> '..') then
             i := i + FGetFiles(IncludeTrailingPathDelimiter(directory)
               + aSearchRec.NAME + '\',
               mask, attr, af, Recursive);
        end;
        Found := SysUtils.FindNext(aSearchRec);

      end;
    end;
  finally
    SysUtils.FindClose(aSearchRec);
    result := i;
  end;
end;

procedure TAHSearchThread.FStopAnimation;
begin
  frmMain.aniAnimate.Active := False;
  frmMain.SearchMode := amsStopped;
end;



end.
