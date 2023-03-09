unit uFinder;

interface

uses
  SysUtils, Classes, Contnrs, Windows, Forms, ShellAPI, DateUtils,
    JCLStrings;

const
  WordSeparators = ['''', '.', ',', '?', '/', '\', '+', '=', '*', '!', '#', '"', ';', ':',
    '<', '>', '%', '$', '@', '#', '|', '(', ')', ' ', #9, #13, #10];

type
  EPatternTooLarge = class(Exception);


  TCommandOption = (coSearchSubFolders, coSearchWholeWords,
    coSearchCaseSensitive);

  TCommandOptions = set of TCommandOption;

  TCommandMatchOption = (cmMatchAny, cmMatchAll, cmMatchExactly);

  TCommandObject = class
    FileMask : string;
    Folder : string;
    SearchWords : string;
    CommandOptions : TCommandOptions;
    CommandMatch : TCommandMatchOption;
    HasData : Boolean;
    LaunchDirectly : Boolean;
    constructor Create;
  end;

  TFileSomething = procedure(dir : string; SearchRec : TSearchRec) of object;

// Base finder abstract class
  TFinder = class
  private
    FWholeWord: Boolean;
    FCaseInsensitive: Boolean;
    FOriginalPattern: string;
    FSearchPattern: string;
    FOriginalText: string;
    FTextToSearch: string;
  protected
    FList: TList;
    procedure SetCaseInsensitive(const Value: Boolean); virtual;
    procedure SetWholeWord(const Value: Boolean); virtual;
    procedure SetTextToSearch(Value: string); virtual;
    procedure SetSearchPattern(const Value: string); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function FindFirst: Integer; virtual; abstract;
    function FindNext: Integer; virtual; abstract;
    function FindAll: TList; virtual; abstract;
    property TextToSearch: string read FTextToSearch write SetTextToSearch;
    property WholeWord: Boolean read FWholeWord write SetWholeWord;
    property CaseInsensitive: Boolean read FCaseInsensitive write SetCaseInsensitive;
    property SearchPattern: string read FSearchPattern write SetSearchPattern;
  end;



// Finder class that uses the Pos function to search text
  TPosFinder = class(TFinder)
  private
    FPos: Integer;
  public
    function FindFirst: Integer; override;
    function FindNext: Integer; override;
    function FindAll: TList; override;
  end;

// Finder class that uses the Boyer-Moore-Horspool algorithm
  TBMHFinder = class(TFinder)
  private
    FPos: Integer;
    FBMHTable: array[Char] of Byte;
    procedure CreateBMHTable;
  protected
    procedure SetCaseInsensitive(const Value: Boolean); override;
    procedure SetSearchPattern(const Value: string); override;
  public
    function FindFirst: Integer; override;
    function FindNext: Integer; override;
    function FindAll: TList; override;
  end;

  TWordFind = (wfAny, wfAll, wfExact);
  TFoundWord = class
    Position, Size : Integer;
  end;

// Finder class that uses the Boyer-Moore-Horspool algorithm
//   to find more than one word
  TBMHWordsFinder = class(TFinder)
  private
    FWords : TStringList;
    FPos: Integer;
    FBMHTable: Array of Array[Char] of Byte;
    FList : TObjectList;
    FTypeFind: TWordFind;
    FOriginalPattern : String;
    fFileName : string;
    fStart, fEnd : PChar;
    fDataLength : integer;


    procedure CreateBMHTables;
    procedure SetTypeFind(const Value: TWordFind);
    procedure SetFileName(const filename : string);

  protected
    procedure SetData(Data: pchar; DataLength: integer);
    procedure ClearData;
    procedure CloseFile;
    procedure SetCaseInsensitive(const Value: Boolean); override;
    procedure SetSearchPattern(const Value: string); override;
  public
    constructor Create;
    destructor Destroy; override;
    function FindFirst: Integer; override;
    function FindNext: Integer; override;
    function FindAll: TList; override;
    property FileName : string read FFileName write SetFileName;
    property TypeFind : TWordFind read FTypeFind write SetTypeFind;
  end;

  TMatcherType = (mtNone, mtFileSize, mtFileModTime, mtFileCreateTime,
    mtFileAccessTime);
  TMatcherAction = (maEquals, maNotEquals,
    maGreater, maSmaller, maDoesContain, maDoesNotContain);
  TMatcherValidation = (mvOr, mvAnd);

  TAHMatcher = class(TObject)
  public
    MatcherAction : TMatcherAction;
    MatcherType : TMatcherType;
    function DoMatch : Boolean; virtual; abstract;
  end;

  TAHIntegermatcher = class(TAHMatcher)
  public
    CurrentValue : Integer;
    CompareValue : Integer;
    function DoMatch : Boolean;
  end;

  TAHDateTimeMatcher = class(TAHMatcher)
  public
    CurrentValue : TDateTime;
    CompareValue : TDateTime;
    function DoMatch : Boolean;
  end;

  TAHFileConditions = class(TList)
  private
    function DoAndMatch : Boolean;
    function DoOrMatch : Boolean;
  public
    ValidateType : TMatcherValidation;
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Delete(index : integer);
    function SetSearchData(const asearchRec : TSearchRec) : integer;
    function DoMatch : Boolean;
  end;

function ParseIntoVerbs(SearchString: string; MustHaves, CanHaves,
  DontHaves: TStringList): Boolean;
procedure ParseString(Str: string; var List: TStringList; IgnoreDups : Boolean = False);
function IsFileInUse(fName : string) : boolean;
function KBToMB(aninteger : integer) : double;
function ahGetVersion(aVersionStringName : string) : string;
function ShowProperties(hWndOwner: HWND; const FileName: string) : boolean;
function SortStrings(s1, s2 : string; bAscending : Boolean) : integer;
function SortDates(s1, s2 : string; bAscending : Boolean) : integer;
function SortInteger(s1, s2 : string; bAscending : Boolean) : Integer;

function ParseCommandLine(ACommand : TCommandObject) : Boolean;
function ParseLoop(cstring : string; var returnstring : string) : Boolean;
function ParseQueryString(cstring : string) : string;

var CommandoTigers : TCommandObject;


implementation




function ParseLoop(cstring : string; var returnstring : string) : Boolean;
var ParserState : (mNone, mCommand, mStart, mQuoteStart, mWord, mQuoteEnd, mEnd);
  TheWord : String;
begin
  result := False;
  TheWord := '';
  if Length(cstring) > 0 then
  begin
    ParserState := mNone;
    while ParserState <> mEnd do
    begin
      case cString[1] of
        '-' :
        begin
          if ParserState <> mWord then
            ParserState := mCommand
          else
          begin
            theWord := TheWord + cString[1];
          end;
        end;
        '=' :
        begin
          if ParserState = mCommand then
            ParserState := mStart
          else
          begin
            if ParserState = mWord then
            begin
              theWord := TheWord + cstring[1];
            end
            else
            begin
              // Force a state
              ParserState := mStart;
            end;
          end;
        end;
        '"' :
        begin
          case ParserState of
            mStart :
            begin
              theWord := TheWord + cstring[1];
              ParserState := mQuoteStart;
            end;
            mWord :
            begin
              ParserState := mQuoteEnd;
              TheWord := TheWord + cstring[1];
            end;
            else
              ParserState := mQUoteStart;
          end;
        end;
        ' ' :
        begin
          case ParserState of
            mWord :
             TheWord := TheWord + cstring[1];
          end;
        end
        else
        begin
          if ParserState >= mStart then
          begin
            if ParserState = mStart then
              ParserState := mWord;
            TheWord := TheWord + cstring[1];
          end;
        end;
      end;

      delete(cstring, 1, 1);
      if length(cstring) = 0 then
      begin
        parserState := mEnd;
        Result := True;
      end;
    end;
  end;
  returnString := TheWord;
  Result := True;
end;

function ParseQueryString(cstring : string) : string;
var p : Integer;
  r : string;
begin
  result := '';
  if ParseLoop(cstring, r) then
   result := r;
end;

function ParseCommandLine(ACommand : TCommandObject)
  : Boolean;
var  p, x : Integer;
   tmp, cstring : string;
begin
  result := False;
  if Assigned(ACommand) then
  begin
    for x := 1 to ParamCount do
    begin
      cstring := ParamStr(x);

      p := Pos('--msk', cstring);
      if p > 0 then
      begin
        cstring := copy(cstring, p, Length(cstring));
        tmp := ParseQueryString(cstring);
        if tmp <> '' then
        begin
          ACommand.FileMask := tmp;
          result := True;
        end;
      end;

      p := Pos('--dir', cstring);
      if p > 0 then
      begin
        cstring := copy(cstring, p, Length(cstring));
        tmp := ParseQueryString(cstring);
        if tmp <> '' then
        begin
          ACommand.Folder := tmp;
          result := True;
        end;
      end;

      p := Pos('--cmd', cstring);
      if p > 0 then
      begin
        // SWC
        cstring := copy(cstring, p, Length(cstring));
        tmp := ParseQueryString(cstring);
        if tmp <> '' then
        begin
          ACommand.CommandOptions := [];

          if Pos('S', tmp) > 0 then
          begin
            ACommand.CommandOptions := ACommand.CommandOptions
             + [coSearchSubFolders];
          end;

          if Pos('W', tmp) > 0 then
          begin
            ACommand.CommandOptions := ACommand.CommandOptions
             + [coSearchWholeWords];
          end;

          if Pos('C', tmp) > 0 then
          begin
            ACommand.CommandOptions := ACommand.CommandOptions
             + [coSearchCaseSensitive];
          end;

        end;
      end;


      p := Pos('--qry', cstring);
      if p > 0 then
      begin
        cstring := copy(cstring, p, Length(cstring));
        tmp := ParseQueryString(cstring);
        if tmp <> '' then
        begin
          ACommand.SearchWords := tmp;
          result := True;
        end;
      end;

      p := Pos('--mtc', cstring);
      if p > 0 then
      begin
        cstring := copy(cstring, p, Length(cstring));
        tmp := ParseQueryString(cstring);
        if tmp <> '' then
        begin
          if tmp = 'ANY' then
            ACommand.CommandMatch := cmMatchAny;
          if tmp = 'ALL' then
            ACommand.CommandMatch := cmMatchAll;
          if tmp = 'EXACT' then
            ACommand.CommandMatch := cmMatchExactly;
        end;
      end;

      p := Pos('--run', cstring);
      if p > 0 then
      begin
        Acommand.LaunchDirectly := True;
      end;
    end;
  end;
end;

function SortStrings(s1, s2 : string; bAscending : Boolean) : integer;
begin
  result := 0;
  if bAscending then
  begin
    result := CompareStr(s1, s2);
  end
  else
  begin
    result := CompareStr(s2, s1);
  end;
end;

function SortDates(s1, s2 : string; bAscending : Boolean) : integer;
var d1, d2 : TDateTime;
begin
  d1 := StrToDateTimeDef(s1, 0);
  d2 := StrToDateTimeDef(s2, 0);
  result := 0;
  if bAscending then
    result := CompareDateTime(d1, d2)
  else
    result := CompareDateTime(d2, d1);
end;

function SortInteger(s1, s2 : string; bAscending : Boolean) : Integer;
var s, f : integer;
begin
  result := 0;
  if bAscending then
  begin
    f := StrToIntDef(s1, 0);
    s := StrToIntDef(s2, 0);
  end
  else
  begin
    s := StrToIntDef(s1, 0);
    f := StrToIntDef(s2, 0);
  end;
  if f < s then
    result := -1
  else
  begin
    if f = s then
      result := 0
    else
      result := 1
  end;
end;

function ShowProperties(hWndOwner: HWND; const FileName: string) : boolean;
var
   Info: TShellExecuteInfo;
   Handle : THandle;
begin
   with Info do
   begin
     cbSize := SizeOf(Info) ;
     fMask := SEE_MASK_NOCLOSEPROCESS or
              SEE_MASK_INVOKEIDLIST or
              SEE_MASK_FLAG_NO_UI;
     wnd := hWndOwner;
     lpVerb := 'properties';
     lpFile := pChar(FileName) ;
     lpParameters := nil;
     lpDirectory := nil;
     nShow := 0;
     hInstApp := 0;
     lpIDList := nil;
   end;

   { Call Windows to display the properties dialog.}
   Result := ShellExecuteEx(@Info) ;
end;

function ahGetVersion(aVersionStringName : string) : string;
var
  FileName: String;
  Size    : DWORD;
  Handle  : DWORD;
  Len     : UINT;
  Buffer  : PChar;
  Value   : PChar;
  TransNo : PLongInt;
  SFInfo  : String;
begin
  Result := '';
  FileName := Application.ExeName;
  Size := GetFileVersionInfoSize(PChar(FileName), Handle);
  if Size > 0 then begin
    Buffer := AllocMem(Size);
    try
      GetFileVersionInfo(PChar(FileName), 0, Size, Buffer);
      VerQueryValue(Buffer, PChar('VarFileInfo\Translation'),
                     Pointer(TransNo), Len);
      SFInfo := Format('%s%.4x%.4x%s%s%', ['StringFileInfo\',
        LoWord(TransNo^), HiWord(Transno^), '\', aVersionStringName]);
      if VerQueryValue(Buffer, PChar(SFInfo),
                      Pointer(Value), Len) then
        Result := Value;
    finally
      { always release memory }
      if Assigned(Buffer) then
        FreeMem(Buffer, Size);
    end;
  end;
end;


function KBToMB(aninteger : integer) : double;
begin
  result := (aninteger /1024);
end;

// AH061705 --

function ParseIntoVerbs(SearchString: string; MustHaves, CanHaves,
  DontHaves: TStringList): Boolean;
var ParserState : (mNone, mChar, mQuote, mEndKeyword, mEnd);
   WordState : (kCanHaves, kMustHaves, kDontHaves);
   thisstring : string;
   procedure AddToWordList;
   begin
     if length(thisstring)> 0 then
     begin
       case ParserState of
         mEndKeyWord :
         begin
           case WordState of
             kMustHaves :
             begin
               MustHaves.Add(Trim(ThisString));
             end;
             kDontHaves :
             begin
               DontHaves.Add(Trim(ThisString));
             end
             else
             begin
               CanHaves.Add(Trim(ThisString));
             end;
           end;

           ThisString := '';
           parserState := mNone;
           WordState := kCanHaves;
         end;
       end;
     end;
   end;
begin
  result := false;
  if length(SearchString) > 0 then
  begin
    ParserState := mNone;
    WordState := kCanhaves;
    while parserState <> mEnd do
    begin
      case searchString[1] of
        '+' :
        begin
          if parserState <> mQuote then
          begin
            if ParserState = mChar then
            begin
              ParserState := mEndKeyword;
              AddToWordList;
            end;
            WordState := kMustHaves;
          end;
        end;
        '-' :
        begin
          if ParserState <> mQuote then
          begin
            if ParserState = mChar then
            begin
              ParserState := mEndKeyword;
              AddToWordList;
            end;
            WordState := kDontHaves;
          end;
        end;
        ' ' :
        begin
          if ParserState <> mQuote then
            ParserState := mEndKeyword;
        end;
        '"' :
        begin
          if ParserState <> mQuote then
            ParserState := mQuote
          else
            ParserState := mEndKeyWord;
        end
        else
        begin
          if ParserState <> mQuote then
            ParserState := mChar;
        end;
      end;

      ThisString := ThisString + SearchString[1];
      AddToWordList;

      delete(searchString, 1, 1);
      if length(searchstring) = 0 then
      begin
        parserState := mEndKeyword;
        AddToWordList;
        parserState := mEnd;
        Result := True;
      end;
    end;
  end;
end;

// Breaks a string separated by semicolons into a StringList
//   IgnoreDups tells if duplicates are added or discarded from the list
// AH061405



procedure ParseString(Str: string; var List: TStringList; IgnoreDups : Boolean);
var
  PosDel: Integer;
  StrInsert : String;
begin
  Str := Trim(Str);
  while Str <> '' do begin
// find position of separator
    PosDel := Pos(';', Str);
    if PosDel <> 0 then begin
// separator found - StrInsert has the first part of the string and
//   Str has the part after the separator
      StrInsert := Trim(Copy(Str, 1, PosDel - 1));
      Str := Trim(Copy(Str, PosDel + 1, Length(Str)));
    end
    else begin
// separator not found - StrInsert has the whole string
      StrInsert := Str;
      Str := '';
    end;
// add the string to the list
    if not IgnoreDups or (List.IndexOf(StrInsert) < 0) then
      List.Add(StrInsert);
  end;
end;

procedure UpCase(Buffer: PChar; Size: Integer); assembler;
{ Converts all lower-case characters within Buffer to upper-case }
asm
  or  edx, edx         { edx contains size of Buffer }
  jz @3               { Exit if size = 0 }
  push edi
  mov  edi, eax    { Load Buffer }
@1:
  mov  al, [edi]      { Check current byte of Buffer }
  cmp  al, 'a'          { Skip if not 'a'..'z' }
  jb   @2
  cmp  al, 'z'
  ja   @2
  sub  al, 20h          { Convert to uppercase }
  mov  [edi], al      { Put converted byte back in Buffer }
@2:
  inc  edi               { Get next byte in Buffer }
  dec edx               { Continue to size of Buffer }
  jnz @1
  pop edi
@3:
end;

{ TFinder }
constructor TFinder.Create;
begin
  inherited;
// FList has the list of found words
  FList := TList.Create;
end;

destructor TFinder.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TFinder.SetCaseInsensitive(const Value: Boolean);
begin
// if case insensitive search, must convert search pattern and
//   text to search to upper case
  FCaseInsensitive := Value;
  if FCaseInsensitive then begin
    UpCase(PChar(FSearchPattern), Length(FSearchPattern));
    UpCase(PChar(FTextToSearch), Length(FTextToSearch));
  end
  else begin
    FSearchPattern := FOriginalPattern;
    FTextToSearch := FOriginalText;
  end;
end;

procedure TFinder.SetSearchPattern(const Value: string);
begin
  FSearchPattern := Value;
  FOriginalPattern := Value;
  if FCaseInsensitive then
    UpCase(PChar(FSearchPattern), Length(FSearchPattern));
end;

procedure TFinder.SetTextToSearch(Value: string);
begin
  FTextToSearch := Value;
  FOriginalText := Value;
  if FCaseInsensitive then
    UpCase(PChar(FTextToSearch), Length(FTextToSearch));
end;

procedure TFinder.SetWholeWord(const Value: Boolean);
begin
  FWholeWord := Value;
end;

{ TPosFinder }

function TPosFinder.FindAll: TList;
var
  Str: string;
  PosTxt: Integer;
begin
// finds all words and puts the found words in the list
  FList.Clear;
  if FSearchPattern <> '' then begin
    Str := FTextToSearch;
    while Str <> '' do begin
      PosTxt := Pos(FSearchPattern, FTextToSearch);
      if PosTxt > 0 then begin
// found word - cuts text to search
        Str := Copy(Str, PosTxt + Length(FSearchPattern) + 1, Length(Str));
// test if it's a whole word (has word separators before and after the text)
        if not WholeWord or ((FTextToSearch[FPos - 1] in WordSeparators)) and
          (FTextToSearch[FPos + Length(FSearchPattern)] in WordSeparators) then
          FList.Add(TObject(PosTxt));
      end
      else
        Str := '';
    end;
  end
  else
// blank search pattern - first character found
    FList.Add(TObject(1));
  Result := FList;
end;

function TPosFinder.FindFirst: Integer;
begin
// finds only first instance of text
  if FSearchPattern <> '' then begin
// use FindNext from the beginning of the text
    FPos := 0;
    Result := FindNext;
  end
  else begin
    Result := 1;
    FPos := Length(FTextToSearch);
  end;
end;

function TPosFinder.FindNext: Integer;
var
  TextLen: Integer;
  SearchLen: Integer;
begin
  Result := 0;
  TextLen := Length(FTextToSearch);
  SearchLen := Length(FSearchPattern);
  while (Result = 0) and (FPos < TextLen) do begin
// use Pos function to search text
    Result := Pos(FSearchPattern, Copy(FTextToSearch, FPos + 1, TextLen));
    if Result > 0 then begin
      FPos := FPos + Result;
// test if it is a Whole word
      if WholeWord then begin
        if not (((Result = 1) or (FTextToSearch[FPos - 1] in WordSeparators)) and
          (FTextToSearch[FPos + SearchLen] in WordSeparators)) then begin
          Result := 0;
          FPos := FPos + SearchLen;
        end
        else
          Result := FPos;
      end
      else
        Result := FPos;
    end
    else
      FPos := TextLen;
  end;
end;

{ TBMHFinder }

procedure TBMHFinder.CreateBMHTable;
var
  Size: Integer;
  i: Integer;
begin
// create skip table
  Size := Length(SearchPattern);
// all skip values are initialized with the length of the pattern
  FillChar(FBMHTable, Sizeof(FBMHTable), Size);
  for i := 1 to Pred(Length(SearchPattern)) do begin
    Dec(Size);
// the skip value of the character in the search pattern is the distance to
//   the last character
    FBMHTable[SearchPattern[i]] := Size;
  end;
end;

function TBMHFinder.FindAll: TList;
var
  NumSkip: Integer;
  LastChar : Char;
  TextLen, PatLen: Integer;
  i: Integer;
  Found: Boolean;
begin
// finds word in the text and put instances in the list
  TextLen := Length(FTextToSearch);
  PatLen := Length(FSearchPattern);
  FList.Clear;
  if PatLen = 0 then
    FList.Add(TObject(1))
  else begin
    FPos := Length(FSearchPattern);
    LastChar := FSearchPattern[PatLen];
    while FPos <= TextLen do begin
// if the actual character isn't last character in search pattern
//   skip characters
      if FTextToSearch[FPos] <> LastChar then
        NumSkip := FBMHTable[FTextToSearch[FPos]]
      else begin
// found last character in pattern - begin reverse search
        i := PatLen - 1;
        Found := True;
        NumSkip := PatLen;
        while i > 0 do begin
          Dec(FPos);
          if FTextToSearch[FPos] <> FSearchPattern[i] then begin
// match not found - begin search again
            Found := False;
            NumSkip := PatLen - i + FBMHTable[LastChar];
            break;
          end;
          Dec(i);
        end;
        if Found then
// match found - test if it is a whole word
          if not WholeWord or (((FPos = 1) or (FTextToSearch[FPos - 1] in WordSeparators))) and
            (FTextToSearch[FPos + Length(FSearchPattern)] in WordSeparators) then
            FList.Add(TObject(FPos));
      end;
      Inc(FPos, NumSkip);
    end;
  end;
  Result := FList;
end;

function TBMHFinder.FindFirst: Integer;
begin
// finds first occurence of the search pattern -
//   calls FindNext from the beginning of the text
  FPos := Length(FSearchPattern);
  if FPos = 0 then
    Result := 1
  else
    Result := FindNext;
end;

function TBMHFinder.FindNext: Integer;
var
  NumSkip: Integer;
  LastChar: Char;
  TextLen, PatLen: Integer;
  i: Integer;
  Found: Boolean;
begin
// finds next occurence of the search pattern
  TextLen := Length(FTextToSearch);
  PatLen := Length(FSearchPattern);
  LastChar := FSearchPattern[PatLen];
  Result := 0;
  while FPos <= TextLen do begin
// if the actual character isn't last character in search pattern
//   skip characters
    if FTextToSearch[FPos] <> LastChar then
      NumSkip := FBMHTable[FTextToSearch[FPos]]
    else begin
// found last character in pattern - begin reverse search
      i := PatLen - 1;
      Found := True;
      NumSkip := PatLen;
      while i > 0 do begin
        Dec(FPos);
        if FTextToSearch[FPos] <> FSearchPattern[i] then begin
// match not found - begin search again
          Found := False;
          NumSkip := PatLen - i + FBMHTable[LastChar];
          break;
        end;
        Dec(i);
      end;
// match found - test if it is a whole word
      if Found then
        if not WholeWord or (((FPos = 1) or (FTextToSearch[FPos - 1] in WordSeparators))) and
          (FTextToSearch[FPos + Length(FSearchPattern)] in WordSeparators) then begin
          Result := FPos;
          Exit;
        end;
    end;
    Inc(FPos, NumSkip);
  end;
end;

procedure TBMHFinder.SetCaseInsensitive(const Value: Boolean);
begin
  inherited;
  CreateBMHTable;
end;

procedure TBMHFinder.SetSearchPattern(const Value: string);
begin
// our skip table uses a byte - cannot skip more than 255 characters
//   to skip more, our table should be an integer table
//   FBMHTable: array[Char] of Integer;
  if Length(Value) > 255 then
    raise EPatternTooLarge.Create('Length of text to be found must be 255 characters or less');
  inherited;
  CreateBMHTable;
end;

{ TBMHWordsFinder }

procedure TBMHWordsFinder.ClearData;
begin
  fStart := nil;
  fEnd := nil;
  FTextToSearch := '';
  fDataLength := 0;
end;

procedure TBMHWordsFinder.CloseFile;
begin
   if (fStart <> nil) then UnmapViewOfFile(fStart);
   fFilename := '';
   ClearData;
end;

constructor TBMHWordsFinder.Create;
begin
  inherited;
// FWords
  FWords := TStringList.Create;
  FTypeFind := wfAny;
end;

procedure TBMHWordsFinder.CreateBMHTables;
var
  Size: Integer;
  i,j: Integer;
begin
  SetLength(FBMHTable,FWords.Count);
  for j := 0 to Pred(FWords.Count) do begin
    Size := Length(FWords[j]);
    FillChar(FBMHTable[j], Sizeof(FBMHTable[j]), Size);
    for i := 1 to Pred(Length(FWords[j])) do begin
      Dec(Size);
      FBMHTable[j,FWords[j][i]] := Size;
    end;
  end;
end;

destructor TBMHWordsFinder.Destroy;
begin
  FWords.Free;
  FList.Free;
  inherited;
end;

function ComparePos(Item1, Item2: Pointer): Integer;
begin
  Result := TFoundWord(Item1).Position - TFoundWord(Item2).Position;
end;

function TBMHWordsFinder.FindAll: TList;
var
  FoundWord : TFoundWord;
  NumSkip: Integer;
  LastChar, tmpChar : Char;
  TextLen, PatLen: Integer;
  i, j: Integer;
  Found: Boolean;
  fT, tmp : PChar;
begin
  if not Assigned(FList) then
    FList := TObjectList.Create
  else
    FList.Clear;
  fT := fStart;
  // TextLen := Length(FTextToSearch);
  TextLen := FDataLength;

  Result := FList;
  for j := 0 to Pred(FWords.Count) do begin
    PatLen := Length(FWords[j]);
    FPos := PatLen;
    if FPos <> 0  then begin
      LastChar := FWords[j][PatLen];
      while FPos < TextLen do begin // PChar <
        // if FTextToSearch[FPos] <> LastChar then
        // AH071606
        tmpChar := ft[fPos];

        if Self.FCaseInsensitive then
          tmpChar := JCLStrings.CharUpper(ft[fPos]);

        if tmpChar <> LastChar then
          NumSkip := FBMHTable[j][tmpChar] //[FTextToSearch[FPos]]
        else begin
          i := PatLen - 1;
          Found := True;
          NumSkip := PatLen;
          while i > 0 do
          begin
            Dec(FPos);
            //if FTextToSearch[FPos] <> FWords[j][i] then begin
            tmpChar := ft[fPos];

            if Self.FCaseInsensitive then
              tmpChar := JCLStrings.CharUpper(ft[fPos]);

            if tmpChar <> FWords[j][i] then begin
              Found := False;
              NumSkip := PatLen - i + FBMHTable[j][LastChar];
              break;
            end;
            Dec(i);
          end;
          if Found then
            if not WholeWord or (((FPos = 1) or
                // (FTextToSearch[FPos - 1] in WordSeparators))) and
                (ft[fpos - 1] in WordSeparators))) and
                ///(FTextToSearch[FPos + PatLen] in WordSeparators) then begin
                (ft[fpos + PatLen] in WordSeparators) then
            begin
              FoundWord := TFoundWord.Create;
              FoundWord.Position := FPos;
              FoundWord.Size := PatLen;
              FList.Add(FoundWord);
          end;
        end;
        Inc(FPos, NumSkip);
      end;
    end;
  end;
  FList.Sort(ComparePos);
end;

function TBMHWordsFinder.FindFirst: Integer;
var
  NumSkip: Integer;
  LastChar, tmpChar: Char;
  TextLen, PatLen: Integer;
  i, j: Integer;
  Found: Boolean;
  ft : PChar;
begin
  // TextLen := Length(FTextToSearch);
  TextLen := fDataLength;
  ft := fStart;
  Result := 0;
  for j := 0 to Pred(FWords.Count) do begin
    PatLen := Length(FWords[j]);
    FPos := PatLen;
    if FPos <> 0  then begin
      Result := 0;
      LastChar := FWords[j][PatLen];
      while FPos < TextLen do begin
        // if FTextToSearch[FPos] <> LastChar then
        // Start...
        tmpChar := ft[fPos];

        if Self.FCaseInsensitive then
          tmpChar := JCLStrings.CharUpper(ft[fPos]);

        if tmpChar <> LastChar then
          NumSkip := FBMHTable[j][tmpChar]  //[FTextToSearch[FPos]]
        else
        begin
          i := PatLen - 1;
          Found := True;
          NumSkip := PatLen;
          while i > 0 do
          begin
            Dec(FPos);
            tmpChar := ft[fPos];
            if Self.FCaseInsensitive then
              tmpChar := JCLStrings.CharUpper(ft[fPos]);

            if {FTextToSearch[FPos]} tmpChar <> FWords[j][i] then begin
              Found := False;
              NumSkip := PatLen - i + FBMHTable[j,LastChar];
              break;
            end;
            Dec(i);
          end;
          if Found then
            if not WholeWord or (((FPos = 1)
                or (ft[FPos - 1] in WordSeparators))) and
                (ft[FPos + PatLen] in WordSeparators) then begin
              Result := FPos;
              if FTypeFind = wfAll then
                Break
              else
                Exit;
          end;
        end;
        Inc(FPos, NumSkip);
      end;
    end;
    if (Result = 0) and (FTypeFind = wfAll) then
      Exit;
  end;
end;

function TBMHWordsFinder.FindNext: Integer;
var
  i : Integer;
begin
  if not Assigned(FList) then
    FindAll;
  Result := 0;
  for i := 0 to Pred(FList.Count) do
    if TFoundWord(FList[i]).Position > FPos then begin
      Result := TFoundWord(FList[i]).Position;
      FPos := Result + TFoundWord(FList[i]).Size;
    end;
  if Result = 0 then
    FPos := fDatalength; // Length(FTextToSearch);
end;

procedure TBMHWordsFinder.SetCaseInsensitive(const Value: Boolean);
begin
  inherited;
  CreateBMHTables;
end;

procedure TBMHWordsFinder.SetData(Data: pchar; DataLength: integer);
begin
  ClearData;
  if (Data = nil) or (DataLength < 1) then exit;
  fStart := Data;
  //SetLength(FTextToSearch, DataLength);
  //FTextToSearch := StrPas(fstart);
  fDataLength := DataLength;
  fEnd := fStart + fDataLength;
end;

procedure TBMHWordsFinder.SetFileName(const filename: string);
var
   filehandle: integer;
   filemappinghandle: thandle;
   size, highsize: integer;
begin
  CloseFile;
  if (Filename = '') or not FileExists(Filename) then exit;
  filehandle := sysutils.FileOpen(Filename, fmopenread or fmsharedenynone);
  if filehandle = 0 then exit; 		       //error
  size := GetFileSize(filehandle, @highsize);
  if (size <= 0) or (highsize <> 0) then      //nb: files >2 gig not supported
  begin
     CloseHandle(filehandle);
     exit;
  end;
  filemappinghandle := CreateFileMapping(filehandle, nil, page_readonly, 0, 0, nil);
  if GetLastError = error_already_exists then filemappinghandle := 0;
  if filemappinghandle <> 0 then
    SetData(MapViewOfFile(filemappinghandle,file_map_read,0,0,0),size);
  if fStart <> nil then fFilename := Filename;
  CloseHandle(filemappinghandle);
  CloseHandle(filehandle);
end;

procedure TBMHWordsFinder.SetSearchPattern(const Value: string);
var
  i : Integer;
  Len : Integer;
begin
  inherited;
  FWords.Clear;
  FreeAndNil(FList);
  FOriginalPattern := Value;
  if FTypeFind = wfExact then
    FWords.Add(FOriginalPattern)
  else begin
    FWords.Delimiter := ' ';
    FWords.DelimitedText := FOriginalPattern;
  end;
  for i := 0 to Pred(FWords.Count) do begin
    Len := Length(FWords[i]);
    if Len > 255 then
      raise EPatternTooLarge.Create('Length of text to be found must be 255 characters or less');
    FWords[i] := Format('#%.3d# ',[256-Len])+FWords[i];
  end;
  FWords.Sort;
  for i := 0 to Pred(FWords.Count) do
    FWords[i] := Copy(FWords[i],7,Length(FWords[i]));
  CreateBMHTables;
end;

procedure TBMHWordsFinder.SetTypeFind(const Value: TWordFind);
begin
  FTypeFind := Value;
  if FOriginalPattern <> '' then
    SetSearchPattern(FOriginalPattern);
end;

{ TAHIntegerMatcher }

function TAHIntegermatcher.DoMatch: Boolean;
begin
  {(maNone, maEquals, maNotEquals,
    maSmaller, maGreater, maDoesContain, maDoesNotContain);}
  case Self.MatcherAction of
    maEquals : Result := (Self.CurrentValue = Self.CompareValue);
    maNotEquals : Result := (Self.CurrentValue <> Self.CompareValue);
    maSmaller : Result := (Self.CurrentValue < Self.CompareValue);
    maGreater : Result := (Self.CurrentValue > Self.CompareValue);
  end;
end;

{ TAHDateTimeMatcher }

function TAHDateTimeMatcher.DoMatch: Boolean;
begin
  case Self.MatcherAction of
    maEquals : Result := (Self.CurrentValue = Self.CompareValue);
    maNotEquals : Result := (Self.CurrentValue <> Self.CompareValue);
    maSmaller : Result := (Self.CurrentValue < Self.CompareValue);
    maGreater : Result := (Self.CurrentValue > Self.CompareValue);
  end;

end;

{ TAHFileConditions }

procedure TAHFileConditions.Clear;
var x : integer;
begin
  for x := self.Count - 1 downto 0 do
  begin
    TAHMatcher(Self.Items[x]).Free;
  end;
  inherited;
end;

constructor TAHFileConditions.Create;
begin
  inherited;
  ValidateType := mvOr;
end;

procedure TAHFileConditions.Delete(index: integer);
begin
  inherited;
end;

destructor TAHFileConditions.Destroy;
var x : integer;
begin
  for x := 0 to Self.Count - 1 do
  begin
    TAHMatcher(Self.Items[x]).Free;
  end;
end;

function IsFileInUse(fName : string) : boolean;
var HFileRes : HFILE;
begin
  Result := false;
  if not FileExists(fName) then exit;
  // AH072905 -- Function fails when GENERIC_WRITE + Readonly.
  HFileRes := CreateFile(pchar(fName),
               GENERIC_READ,
               0, nil, OPEN_EXISTING,
               0	,
               0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);

  if not Result then CloseHandle(HFileRes);
end;


function TAHFileConditions.DoAndMatch: Boolean;
var x : integer;
begin
  result := True;
  for x := 0 to Self.Count - 1 do
  begin
    if (TObject(Self.Items[x]) is TAHIntegerMatcher) then
       result := result and TAHIntegerMatcher(Self.Items[x]).DoMatch
    else
      if (TObject(Self.Items[x]) is TAHDateTimeMatcher) then
        result := result and TAHDateTimeMatcher(Self.Items[x]).DoMatch;

    if result = False then exit;
  end;
end;

function TAHFileConditions.DoMatch: Boolean;
begin
  case ValidateType of
    mvOr : result := DoOrMatch;
    mvAnd : result := DoAndMatch;
    else
      result := True; // Always return true...
  end;
end;

function TAHFileConditions.DoOrMatch: Boolean;
var x : integer;
begin
  result := False;
  for x := 0 to Self.Count - 1 do
  begin
    if (TObject(Self.Items[x]) is TAHIntegerMatcher) then
       result := result or TAHIntegerMatcher(Self.Items[x]).DoMatch
    else
      if (TObject(Self.Items[x]) is TAHDateTimeMatcher) then
        result := result or TAHDateTimeMatcher(Self.Items[x]).DoMatch;
  end;
end;

function TAHFileConditions.SetSearchData(
  const asearchRec: TSearchRec): integer;
var x : integer;
  m : TDateTime;
  t : integer;
begin
  result := 0;
  for x := 0 to Self.Count - 1 do
  begin
    if (TObject(Self.Items[x]) is TAHIntegerMatcher) then
    begin
      inc(Result);
      case TAHIntegerMatcher(Self.Items[x]).MatcherType of
        mtFileSize :
          TAHIntegerMatcher(Self.Items[x]).CurrentValue :=
            (asearchRec.Size div 1024);
      end;
    end
    else
    begin
      if (TObject(Self.Items[x]) is TAHDateTimeMatcher) then
      begin
        inc(result);
        case TAHDateTimeMatcher(Self.Items[x]).MatcherType of
          mtFileModTime :
            TAHDateTimeMatcher(Self.Items[x]).CurrentValue :=
             Int(FileDateToDateTime(aSearchRec.Time));
          mtFileCreateTime :
          begin
            FileTimeToDosDateTime(aSearchRec.FindData.ftCreationTime,
              LongRec(t).Hi, LongRec(t).Lo);
            m := Int(FileDateToDateTime(t));
            TAHDateTimeMatcher(Self.Items[x]).CurrentValue := m;
          end;
          mtFileAccessTime :
          begin
            FileTimeToDosDateTime(aSearchRec.FindData.ftLastAccessTime,
              LongRec(t).Hi, LongRec(t).Lo);
            m := Int(FileDateToDateTime(t));
            TAHDateTimeMatcher(Self.Items[x]).CurrentValue := m;
          end;
        end;
      end;
    end;
  end;
end;

{ TCommandObject }

constructor TCommandObject.Create;
begin
  inherited;
  Self.FileMask := '*.*';
  Self.Folder := 'C:\';
  Self.SearchWords := '';
  Self.CommandOptions := [coSearchSubFolders];
  Self.CommandMatch := cmMatchAny;
  Self.LaunchDirectly := False;

end;

initialization
  CommandoTigers := TCommandObject.Create;

finalization
  CommandoTigers.Free;

end.


