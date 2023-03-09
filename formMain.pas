unit formMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,ToolWin, ComCtrls,   CommCtrl,
  JvExComCtrls, JvListView, StdCtrls, Mask, JvExMask, JvToolEdit, ImgList,
  ShellAPI, uFindThread, ActnList, Menus, Grids, JvSpin, JvDateTimePicker,
  Buttons, uFinder, ItemProp;

type
  TfrmMain = class(TForm)
    sbInfoBar: TStatusBar;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    cboFilemask: TComboBox;
    Label2: TLabel;
    cboKeyWords: TComboBox;
    edDirectories: TJvDirectoryEdit;
    Label3: TLabel;
    chkRecursive: TCheckBox;
    chkCaseSensitive: TCheckBox;
    rdWordsAny: TRadioButton;
    rdWordsAll: TRadioButton;
    rdExact: TRadioButton;
    Panel3: TPanel;
    Panel4: TPanel;
    tbToolbar: TToolBar;
    aniAnimate: TAnimate;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    imlSysIcons: TImageList;
    chkWholeWords: TCheckBox;
    aclActions: TActionList;
    actSearchStart: TAction;
    actSearchStop: TAction;
    imlToolbar: TImageList;
    Bevel1: TBevel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Clear1: TMenuItem;
    SaveSearch1: TMenuItem;
    Edit1: TMenuItem;
    Copy1: TMenuItem;
    Copy2: TMenuItem;
    Paste1: TMenuItem;
    Search1: TMenuItem;
    Start1: TMenuItem;
    Stop1: TMenuItem;
    Help1: TMenuItem;
    actHelpAbout: TAction;
    About1: TMenuItem;
    actSearchOpenFileSelected: TAction;
    actSearchOpenFileWith: TAction;
    N1: TMenuItem;
    Openselected1: TMenuItem;
    Openselectedwith1: TMenuItem;
    popMenu: TPopupMenu;
    Openselected2: TMenuItem;
    Openselectedwith2: TMenuItem;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    actFileClearScreen: TAction;
    lvwResults: TListView;
    ToolButton5: TToolButton;
    actSearchFileproperties: TAction;
    ToolButton6: TToolButton;
    N2: TMenuItem;
    FileProperties1: TMenuItem;
    N3: TMenuItem;
    Properties1: TMenuItem;
    ToolButton7: TToolButton;
    actSearchPause: TAction;
    Pause1: TMenuItem;
    TabSheet2: TTabSheet;
    GroupBox2: TGroupBox;
    grdConditions: TStringGrid;
    cboSearchTerms: TComboBox;
    cboConditions: TComboBox;
    edIntegerValues: TJvSpinEdit;
    edDateValues: TDateTimePicker;
    Panel5: TPanel;
    rdgMatch: TRadioGroup;
    Panel6: TPanel;
    btnAddRow: TBitBtn;
    btnRemoveRow: TBitBtn;
    btnClearAll: TBitBtn;
    actSearchOpenSelectedFolder: TAction;
    Openfolder1: TMenuItem;
    actSearchRegisterHook: TAction;
    N4: TMenuItem;
    RegisterShellHook1: TMenuItem;
    actSearchUnregisterHook: TAction;
    UnregisterShellHook1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actSearchStartExecute(Sender: TObject);
    procedure actSearchStopExecute(Sender: TObject);
    procedure actSearchStartUpdate(Sender: TObject);
    procedure actSearchStopUpdate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure actHelpAboutExecute(Sender: TObject);
    procedure actSearchOpenFileWithExecute(Sender: TObject);
    procedure actSearchOpenFileWithUpdate(Sender: TObject);
    procedure actSearchOpenFileSelectedExecute(Sender: TObject);
    procedure actFileClearScreenExecute(Sender: TObject);
    procedure actFileClearScreenUpdate(Sender: TObject);
    procedure actSearchFilepropertiesExecute(Sender: TObject);
    procedure actSearchFilepropertiesUpdate(Sender: TObject);
    procedure actSearchPauseExecute(Sender: TObject);
    procedure actSearchPauseUpdate(Sender: TObject);
    procedure lvwResultsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvwResultsCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure lvwResultsDblClick(Sender: TObject);
    procedure cboFilemaskExit(Sender: TObject);
    procedure cboKeyWordsExit(Sender: TObject);
    procedure grdConditionsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure cboConditionsClick(Sender: TObject);
    procedure cboSearchTermsClick(Sender: TObject);
    procedure edDateValuesClick(Sender: TObject);
    procedure edIntegerValuesExit(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnRemoveRowClick(Sender: TObject);
    procedure edDateValuesExit(Sender: TObject);
    procedure edIntegerValuesBottomClick(Sender: TObject);
    procedure edIntegerValuesTopClick(Sender: TObject);
    procedure btnClearAllClick(Sender: TObject);
    procedure lvwResultsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure actSearchOpenSelectedFolderExecute(Sender: TObject);
    procedure actSearchRegisterHookUpdate(Sender: TObject);
    procedure actSearchRegisterHookExecute(Sender: TObject);
    procedure actSearchUnregisterHookUpdate(Sender: TObject);
    procedure actSearchUnregisterHookExecute(Sender: TObject);
  private
    { Private declarations }
    SearchThread : TAHSearchThread;
    fOldFormSizeX, fOldFormSizeY : integer;
    fLastColumnClicked : Integer;
    fAscending : Boolean;
    SearchConditions : TAHFileConditions;
    hookRegistered : Boolean;
    function CreateShellHook(doregister : Boolean) : boolean;
  public
    { Public declarations }
    SearchMode : TAHSearchMode;
    procedure GetSettings;
    procedure SetSettings;
    procedure HideComboBoxes;
    function MapFileConditions : integer;
    function IsRowEmtpy(rownumber : Integer) : Boolean;
  end;

var
  frmMain: TfrmMain;

implementation

uses  formAbout, uSettings;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var SHFileInfo: TSHFileInfo;
  sRect : TGridRect;
begin
  SearchMode := amsStopped;
  imlSysIcons.Handle := SHGetFileInfo('', 0, SHFileInfo,
    SizeOf(SHFileInfo),  SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  fOldFormSizeX := Self.Width;
  fOldFormSizeY := Self.Height;
  fLastColumnClicked := 1; // Always on directories *first* (default).
  fAscending := True;
  GetSettings;
  SRect.Top := -1;
  SRect.Left := -1;
  SRect.Bottom := -1;
  SRect.Right := -1;
  grdConditions.Selection := SRect;
  SearchConditions := TAHFileConditions.Create;
  if CommandoTigers.HasData then
  begin
    cboFileMask.Text := CommandoTigers.FileMask;
    edDirectories.Text := CommandoTigers.Folder;
    if coSearchSubFolders in CommandoTigers.CommandOptions then
    begin
      chkRecursive.Checked := True;
    end;

    if coSearchWholeWords in CommandoTigers.CommandOptions then
    begin
      chkWholeWords.Checked := True;
    end;

    if coSearchCaseSensitive in CommandoTigers.CommandOptions then
    begin
      chkCaseSensitive.Checked := True;
    end;

    case CommandoTigers.CommandMatch of
      cmMatchAny : rdWordsAny.Checked := True;
      cmMatchAll : rdWordsAll.Checked := True;
      cmMatchExactly : rdExact.Checked := True;
    end;
    cboKeyWords.Text := CommandoTigers.SearchWords;

    if CommandoTigers.LaunchDirectly then
      Self.actSearchStartExecute(Sender);
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  SearchThread.Free;
  SearchConditions.Free;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if SearchThread <> nil then
  begin
    SearchThread.Terminate;
    SearchThread.WaitFor;
  end;
  SetSettings;
end;

procedure TfrmMain.actSearchStartExecute(Sender: TObject);
begin
  Screen.Cursor := crHourglass;
  try
    lvwResults.Items.Clear;
  finally
    Screen.Cursor := crDefault;
  end;


  // Clear all the items (see code!)
  SearchConditions.Clear;


  SearchThread := TAHSearchThread.Create;
  try
    if MapFileConditions > 0 then
    begin
      SearchConditions.ValidateType := TMatcherValidation(Byte(rdgMatch.ItemIndex));
      SearchThread.FileConditions := SearchConditions;
    end;
    TAHSearchThread(SearchThread).StartFolder := edDirectories.Text;
    TAHSearchThread(SearchThread).FileMask := cboFileMask.Text;
    TAHSearchThread(SearchThread).FileAttributes := faAnyFile;
    TAHSearchThread(SearchThread).KeyWords := cboKeywords.Text;
    TAHSearchThread(SearchThread).UpdateListView := lvwResults;
    TAHSearchThread(SearchThread).Recursive := chkRecursive.Checked;
    // AH071707 --
    TAHSearchThread(SearchThread).CaseSensitivity :=
      ChkCaseSensitive.Checked;
    if rdWordsAny.Checked then
      TAHSearchThread(SearchThread).SearchMethod :=  wfAny
    else
      if rdWordsAll.Checked then
        TAHSearchThread(SearchThread).SearchMethod := wfAll
      else
        TAHSearchThread(SearchThread).SearchMethod := wfExact;
    TAHSearchThread(SearchThread).WholeWords := chkWholeWords.Checked;
    SearchMode := amsStarted;

    SearchThread.Resume;
  except
    SearchMode := amsStopped;
    SearchThread.Free;
  end;
end;

procedure TfrmMain.actSearchStopExecute(Sender: TObject);
begin
  if SearchThread <> nil then
  begin
    SearchThread.Terminate;
    SearchThread.WaitFor;
  end;
  SearchMode := amsStopped;
end;

procedure TfrmMain.actSearchStartUpdate(Sender: TObject);
var b : Boolean;
begin
  b := (SearchMode = amsStopped);
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.actSearchStopUpdate(Sender: TObject);
var b : Boolean;
begin
  b := (SearchMode = amsStarted);
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  // Hey! I'm a lazy programmer!
  edDirectories.Width := edDirectories.Width + (Self.Width - fOldFormSizeX);
  cboKeywords.Width := cboKeywords.Width + (Self.Width - fOldFormSizeX);
  Bevel1.Width := bevel1.Width + (Self.Width - fOldFormSizeX);
  fOldFormSizeX := Self.Width;
  fOldFormSizeY := Self.Height;
end;

procedure TfrmMain.actHelpAboutExecute(Sender: TObject);
begin
  frmAbout := TfrmAbout.Create(nil);
  try
    frmAbout.ShowModal;
  finally
    frmAbout.Free;
  end;
end;

procedure TfrmMain.actSearchOpenFileWithExecute(Sender: TObject);
var s : string;
begin
  s := '';
  if lvwResults.Selected <> nil then
  begin
    s := 'shell32.dll,OpenAs_RunDLL '
      + lvwResults.Selected.SubItems[0] + lvwResults.Selected.Caption;
    ShellExecute(Handle, Pchar('Open'), PChar('rundll32.exe'),
      PChar(s), #0, SW_SHOWNORMAL);
  end;
end;

procedure TfrmMain.actSearchOpenFileWithUpdate(Sender: TObject);
var b : Boolean;
begin
  b := lvwResults.SelCount > 0;
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.actSearchOpenFileSelectedExecute(Sender: TObject);
var s : string;
begin
  s := '';
  if lvwResults.Selected <> nil then
  begin
    s := lvwResults.Selected.SubItems[0] + lvwResults.Selected.Caption;
    ShellExecute(Handle, 'open', PChar(s), '',
       PChar(lvwResults.Selected.SubItems[0]), SW_SHOWNORMAL)
  end;
end;

// Opens the current selected folder
procedure TfrmMain.actSearchOpenSelectedFolderExecute(Sender: TObject);
var s : string;
begin
  s := '';
  if lvwResults.Selected <> nil then
  begin
    s := lvwResults.Selected.SubItems[0];
    ShellExecute(Handle, 'open', PChar(s), '',
       PChar(lvwResults.Selected.SubItems[0]), SW_SHOWNORMAL)
  end;
end;

procedure TfrmMain.actFileClearScreenExecute(Sender: TObject);
var x : integer;
begin
  cboFileMask.Text := '';
  edDirectories.Text := '';
  chkRecursive.Checked := False;
  cboKeyWords.Text := '';
  chkWholeWords.Checked := False;
  chkCaseSensitive.Checked := False;
  rdWordsAny.Checked := True;
  lvwResults.Items.Clear;

  for x := 0 to sbInfoBar.Panels.Count -1 do
  begin
    sbInfoBar.Panels[x].Text := '';
  end;
  cboFileMask.SetFocus;
end;

procedure TfrmMain.actFileClearScreenUpdate(Sender: TObject);
var b : boolean;
begin
  b := (SearchMode = amsStopped);
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.actSearchFilepropertiesExecute(Sender: TObject);
begin
  if lvwResults.Selected <> nil then
  begin
    ShowProperties(Self.Handle, lvwResults.Selected.SubItems[0]
      + lvwResults.Selected.Caption);
  end;
end;

procedure TfrmMain.actSearchUnregisterHookUpdate(Sender: TObject);
begin
  (Sender as TCustomAction).Enabled := self.hookRegistered;
end;


procedure TfrmMain.actSearchRegisterHookUpdate(Sender: TObject);
begin
  (Sender as TCustomAction).Enabled := not self.hookRegistered;
end;


procedure TfrmMain.actSearchFilepropertiesUpdate(Sender: TObject);
var b : boolean;
begin
  b := lvwResults.SelCount = 1;
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.actSearchPauseExecute(Sender: TObject);
begin
 case SearchMode of
   amsStarted :
   begin
     SearchThread.Suspend;

     sbInfoBar.Panels[3].Text := '-- PAUSED --';
     SearchMode := amsPaused;
   end;
   amsPaused :
   begin
     if SearchThread.Suspended then
     begin
       SearchThread.Resume;
       SearchMode := amsStarted;
     end;
   end;
 end;
end;

procedure TfrmMain.actSearchPauseUpdate(Sender: TObject);
var b : Boolean;
begin
  b := (SearchMode = amsStarted) or (SearchMode = amsPaused);
  (Sender as TCustomAction).Enabled := b;
end;

procedure TfrmMain.lvwResultsColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  fLastColumnClicked := Column.Index;
  fAscending := not fAscending;
  (lvwResults as TCustomListView).AlphaSort;
end;

procedure TfrmMain.lvwResultsCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  case fLastColumnClicked of
    0 : // Filename
      Compare := SortStrings(Item1.Caption, Item2.Caption, fAscending);
    1 : // FOlder
      Compare := SortStrings(Item1.SubItems[0], Item2.SubItems[0], fAscending);
    2 : // Size
       Compare := SortInteger(Item1.SubItems[1], Item2.SubItems[1], fAscending);
    3 : // Date mod.
      Compare := SortDates(Item1.SubItems[2], Item2.SubItems[2], fAscending);
    4 : //Date access.
      Compare := SortDates(Item1.SubItems[3], Item2.SubItems[3], fAscending);
    5 : //Date Created.
      Compare := SortDates(Item1.SubItems[4], Item2.SubItems[4], fAscending);
  end;
end;

procedure TfrmMain.lvwResultsDblClick(Sender: TObject);
begin
  actSearchOpenFileSelectedExecute(Self);
end;

procedure TfrmMain.GetSettings;
var t : TStringList;
  x : integer;
begin
  // Settings -> Screen
  LoadSettings;

  self.hookRegistered := uSettings.HookRegistered;

  t := TStringList.Create;
  try
    Self.WindowState := TWindowState(iMainWindowState);
    if Self.WindowState = wsNormal then
    begin
      Self.Left := iMainLeft;
      Self.Top := iMainTop;
      Self.Width := iMainWidth;
      Self.Height := iMainHeight;
    end;

    cboFileMask.Items.CommaText := sMaskList;
    cboKeyWords.Items.CommaText := sWordList;

    if sColumnSizes <> '' then
    begin
      t.Clear;
      t.CommaText := sColumnSizes;
      if t.Count = lvwResults.Columns.Count then
      begin
        for x := 0 to t.Count - 1 do
        begin
          lvwResults.Columns[x].Width := StrToIntDef(t.Strings[x], 50);
        end;
      end;
    end;
  finally
    t.Free;
  end;
end;

procedure TfrmMain.SetSettings;
var x : integer;
  t : TStringList;
begin
  // Screen --> Settings

  t := TStringList.Create;
  try
    iMainLeft := Self.Left;
    iMainTop := Self.Top;
    iMainWidth := Self.Width;
    iMainHeight :=  Self.Height;
    iMainWindowState := Byte(Self.WindowState);

    sMaskList :=  cboFileMask.Items.CommaText;
    sWordList := cboKeyWords.Items.CommaText;

    t.Clear;

    for x := 0 to lvwResults.Columns.Count - 1 do
    begin
      t.Add(IntToStr(lvwResults.Columns[x].Width));
    end;
    sColumnSizes := t.CommaText;

    SaveSettings;
  finally
    t.Free;
  end;
end;

procedure TfrmMain.cboFilemaskExit(Sender: TObject);
begin
  if cboFileMask.Text <> '' then
  begin
    if cboFileMask.Items.IndexOf(cboFileMask.Text) = - 1 then
      AddItemToHistoryStrings(cboFileMask.Text, cboFileMask.Items, iMaxListItems,
        True);
  end;
end;

procedure TfrmMain.cboKeyWordsExit(Sender: TObject);
begin
  if cboKeyWords.Text <> '' then
  begin
    if cboKeyWords.Items.IndexOf(cboKeywords.Text) = -1 then
      AddItemToHistoryStrings(cboKeyWords.Text, cbokeyWords.Items, iMaxListItems,
        True);
  end;
end;

procedure TfrmMain.HideComboBoxes;
begin
  cboConditions.Visible := False;
  cboSearchTerms.Visible := False;
  edIntegerValues.Visible := False;
  edDateValues.Visible := False;
end;

procedure TfrmMain.grdConditionsSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
var Sel : TRect;
    prevstr : string;
begin
  Sel := grdConditions.CellRect(Acol, Arow);
  prevstr := grdConditions.Cells[ACol, Arow];
  HideComboBoxes;
  case acol of
    0 :
    begin
      SetWindowPos(cboConditions.Handle,
         0,
        Sel.Left+ grdConditions.left + 1,
        Sel.Top + grdConditions.top + 1,
        Sel.Right - Sel.Left + 2,
        Sel.Bottom - Sel.top + 2,
        SWP_NOZORDER or SWP_SHOWWINDOW);
      cboConditions.ItemIndex := cboConditions.Items.IndexOf(prevstr);
      cboConditions.Show;
      exit;
    end;
    1 :
    begin
      SetWindowPos(cboSearchTerms.Handle,
         0,
        Sel.Left+ grdConditions.left + 1,
        Sel.Top + grdConditions.top + 1,
        Sel.Right - Sel.Left + 2,
        Sel.Bottom - Sel.top +2,
        SWP_NOZORDER or SWP_SHOWWINDOW);
      cboSearchTerms.ItemIndex := cboSearchTerms.Items.IndexOf(prevstr);
      cboSearchTerms.Show;
      exit;
    end;
    2 :
    begin
      case cboConditions.Items.IndexOf(grdConditions.Cells[0, Arow]) of
        0..2 :
        begin
          SetWindowPos(edDateValues.Handle,
             0,
            Sel.Left+ grdConditions.left + 1,
            Sel.Top + grdConditions.top + 1,
            Sel.Right - Sel.Left + 2,
            Sel.Bottom - Sel.top ,
            SWP_NOZORDER or SWP_SHOWWINDOW);

          edDatevalues.Date := StrToDateTimeDef(prevstr, Now);
          edDateValues.Show;
          exit;
        end;
        3 :
        begin
          SetWindowPos(edIntegerValues.Handle,
             0,
            Sel.Left+ grdConditions.left + 1,
            Sel.Top + grdConditions.top + 1,
            Sel.Right - Sel.Left + 2,
            Sel.Bottom - Sel.top,
            SWP_NOZORDER or SWP_SHOWWINDOW);
          edIntegervalues.Value := StrToIntDef(PrevStr, 0);
          edIntegerValues.Show;
          exit;
        end;
      end;
    end;
  end;
end;

procedure TfrmMain.cboConditionsClick(Sender: TObject);
begin
  grdConditions.Rows[grdConditions.Row].Clear;  // Clear this line...
  grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
    cboConditions.Items[cboConditions.ItemIndex];
end;

procedure TfrmMain.cboSearchTermsClick(Sender: TObject);
begin
  grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
    cboSearchTerms.Items[cboSearchTerms.Itemindex];
end;

procedure TfrmMain.edDateValuesClick(Sender: TObject);
begin
 grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
   DateToStr(edDateValues.Date);
end;

procedure TfrmMain.edIntegerValuesExit(Sender: TObject);
begin
  grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
    IntToStr(edIntegerValues.AsInteger);
end;

procedure TfrmMain.btnAddRowClick(Sender: TObject);
begin
  grdConditions.RowCount := grdConditions.RowCount + 1;
end;

procedure TfrmMain.btnRemoveRowClick(Sender: TObject);
begin
  grdConditions.Rows[grdConditions.Row].Clear;
  grdConditions.RowCount := grdConditions.RowCount - 1;
end;

procedure TfrmMain.edDateValuesExit(Sender: TObject);
begin
 grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
   DateToStr(edDateValues.Date);
end;

function TfrmMain.MapFileConditions : integer;
var y, r, p, ma : Integer;
begin
  result := 0;
  for y := 0 to grdConditions.RowCount -1  do
  begin
    if IsRowEmtpy(y) then
    begin
      p := cboConditions.Items.IndexOf(grdConditions.Cells[0, y]);
      case p of
        0..2 :
        begin
          r := SearchConditions.Add(TAHDateTimeMatcher.Create);
          if r > -1 then
          begin
            inc(Result);
            TAHDateTimeMatcher(SearchConditions.Items[r]).CompareValue :=
              StrToDateDef(grdConditions.Cells[2, y], Now);
            // If Condtion's FUN!
            if p = 0 then
            begin
              TAHDateTimeMatcher(SearchConditions.Items[r]).MatcherType :=
                 mtFileCreateTime;
            end
            else
            begin
              if p = 1 then
              begin
                TAHDateTimeMatcher(SearchConditions.Items[r]).MatcherType :=
                  mtFileAccessTime;
              end
              else
              begin
                TAHDateTimeMatcher(SearchConditions.Items[r]).MatcherType :=
                  mtFileModTime;
              end;
            end;
            // Add the action type
            ma := cboSearchTerms.Items.IndexOf(grdConditions.Cells[1, y]);
            TAHDateTimeMatcher(SearchConditions.Items[r]).MatcherAction :=
              TMatcherAction(Byte(ma));

          end;
        end;
        3 :
        begin
          r := SearchConditions.Add(TAHIntegerMatcher.Create);
          if r > -1 then
          begin
            inc(result);
            TAHIntegerMatcher(SearchConditions.Items[r]).CompareValue :=
              StrToIntDef(grdConditions.Cells[2, y], 0);
            TAHIntegerMatcher(SearchConditions.Items[r]).MatcherType :=
                  mtFileSize;
            ma := cboSearchTerms.Items.IndexOf(grdConditions.Cells[1, y]);
            TAHIntegerMatcher(SearchConditions.Items[r]).MatcherAction :=
             TMatcherAction(Byte(ma));
          end;
        end;
      end;
    end;
  end;
end;

function TfrmMain.IsRowEmtpy(rownumber: Integer): Boolean;
begin
  result := (Trim(grdConditions.Cells[0, rownumber]) <> '') and
     (Trim(grdConditions.Cells[1, rownumber]) <> '') and
     (Trim(grdConditions.Cells[2, rownumber]) <> '');
end;

procedure TfrmMain.edIntegerValuesBottomClick(Sender: TObject);
begin
  grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
    IntToStr(edIntegerValues.AsInteger);
end;

procedure TfrmMain.edIntegerValuesTopClick(Sender: TObject);
begin
  grdConditions.Cells[grdConditions.Col, grdConditions.Row] :=
    IntToStr(edIntegerValues.AsInteger);
end;

procedure TfrmMain.btnClearAllClick(Sender: TObject);
var x : integer;
begin
  for x := grdConditions.RowCount - 1 downto 0 do
  begin
    grdConditions.Rows[x].Clear;
  end;
  grdConditions.RowCount := 1;
end;

procedure TfrmMain.lvwResultsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var t : Boolean;
begin
  t := False;
  if (Button = mbRight) then
  begin
    if lvwResults.SelCount = 1 then
    begin
      ItemProp.DisplayContextMenu(lvwResults.Selected.SubItems[0] +
        lvwResults.Selected.Caption, Self.Handle,
        lvwResults.ClientToScreen(Point(X, Y)), False,
          T);
    end;
  end;
end;

procedure TfrmMain.actSearchRegisterHookExecute(Sender: TObject);
begin
  self.hookRegistered := CreateShellHook(True);
end;

procedure TfrmMain.actSearchUnregisterHookExecute(Sender: TObject);
begin
  self.hookRegistered := CreateShellHook(False);
end;


function TfrmMain.CreateShellHook(doregister : Boolean) : boolean;
const
  ProcNames: array [0..1] of PChar =
    ('DllRegisterServer', 'DllUnregisterServer');
var
  Handle:  THandle;
  RegProc: function: HResult; stdcall;
  hr:      HResult;
begin
  result := false;

  Handle := LoadLibrary(PChar(uSettings.HomeDirectory + 'fandroobj.dll'));

  if Handle = 0 then
    raise Exception.CreateFmt('%s: %s',
      [SysErrorMessage(GetLastError), uSettings.HomeDirectory + 'fandroobj.dll']);
  try
    if doregister then
       RegProc := GetProcAddress(Handle, ProcNames[0])
    else
       RegProc := GetProcAddress(Handle, ProcNames[1]);

    if Assigned(RegProc) then begin
      hr := RegProc;
      result := true;

      if Failed(hr) then
      begin
        result := false;
        raise Exception.Create(
          'Procnames ' + BoolToStr(doregister) + ' failed.')
      end;
    end
    else
      RaiseLastWin32Error
  finally
    FreeLibrary(Handle)
  end
end;

end.
