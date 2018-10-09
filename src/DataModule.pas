{
    This file is part of the AutoEolFormat plugin for Notepad++
    Author: Andreas Heim

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3 as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit DataModule;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.DateUtils,
  System.IOUtils, System.Math, System.Types, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.IniFiles,

  NppSupport, NppMenuCmdID, NppPlugin;


type
  // Forward declarations
  TSettings  = class;
  TFileClass = class;

  // List classes
  TFileClasses       = TObjectList<TFileClass>;
  TFileClassComparer = TComparer<TFileClass>;
  IFileClassComparer = IComparer<TFileClass>;


  // Data container to hold the settings for a file class
  TFileClass = class(TObject)
  strict private
    FName:       string;
    FEolFormat:  integer;
    FExtensions: TStringList;

  public
    constructor Create;
    destructor  Destroy; override;

    property    Name:       string      read FName     write FName;
    property    EolFormat:  integer     read FEolFormat write FEolFormat;
    property    Extensions: TStringList read FExtensions;
  end;


  // Abstraction of the settings file
  TSettings = class(TObject)
  strict private
    FValid:        boolean;
    FIniFile:      TIniFile;
    FFileClasses:  TFileClasses;
    FNoExtensions: TStringList;

    class function GetFilePath: string; static;

    procedure   LoadSettings;
    procedure   SaveSettings;

    function    GetFileClassCount: integer;

    function    GetFileClassName(Idx: integer): string;
    procedure   SetFileClassName(Idx: integer; Value: string);

    function    GetFileClassEolFormat(Idx: integer): integer;
    procedure   SetFileClassEolFormat(Idx: integer; Value: integer);

    function    GetFileClassExtensions(Idx: integer): TStringList;

  public
    constructor Create(const AFilePath: string);
    destructor  Destroy; override;

    // Operations with file classes
    procedure   AddFileClass(const AClassName: string; AEolFormat: integer);
    procedure   UpdateFileClass(const AClassName, ANewClassName: string; AEolFormat: integer);
    procedure   DeleteFileClass(const AClassName: string);

    // Operations with the file extensions of a file class
    procedure   AddExtension(const AClassName, AExtension: string);
    procedure   SetExtensions(const AClassName: string; AExtensions: TStrings);
    procedure   DeleteExtension(const AClassName, AExtension: string);
    procedure   DeleteAllExtensions(const AClassName: string);

    // Class properties
    class property FilePath:                       string      read GetFilePath;

    // Common properties
    property    Valid:                             boolean     read FValid;

    // Access properties to encapsulated list of file classes
    property    FileClassCount:                    integer     read GetFileClassCount;
    property    FileClassName      [Idx: integer]: string      read GetFileClassName        write SetFileClassName;
    property    FileClassEolFormat  [Idx: integer]: integer    read GetFileClassEolFormat    write SetFileClassEolFormat;
    property    FileClassExtensions[Idx: integer]: TStringList read GetFileClassExtensions;

  end;



implementation

uses
  Main;


const
  // Data for INI file section "Header"
  SECTION_HEADER:       string = 'Header';
  KEY_VERSION:          string = 'Version';
  VALUE_VERSION:        string = '1.0';

  // Data for INI file section "Groups" and related sections
  SECTION_GROUPS:       string = 'Groups';
  KEY_GRP_VAL_ACTIVE:   string = 'active';
  KEY_GRP_VAL_INACTIVE: string = 'inactive';
  KEY_EOLFORMAT_NAME:   string = 'EolFormat';
  KEY_EXT_PREFIX:       string = 'Ext';


// =============================================================================
// Class TSettings
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TSettings.Create(const AFilePath: string);
var
  AComparer: IFileClassComparer;

begin
  inherited Create;

  // Compare function for sorting the list of file classes
  AComparer := TFileClassComparer.Construct(
    function(const Left, Right: TFileClass): integer
    begin
      Result := CompareText(Left.Name, Right.Name);
    end
  );

  FValid        := false;
  FIniFile      := TIniFile.Create(AFilePath);
  FFileClasses  := TFileClasses.Create(AComparer, true);
  FNoExtensions := TStringList.Create;

  LoadSettings;
end;


destructor TSettings.Destroy;
begin
  // Settings are saved to disk at instance destruction
  SaveSettings;

  FNoExtensions.Free;
  FFileClasses.Free;
  FIniFile.Free;

  inherited;
end;


// -----------------------------------------------------------------------------
// Getter / Setter
// -----------------------------------------------------------------------------

// Get path of settings file
class function TSettings.GetFilePath: string;
begin
  Result := TPath.Combine(Plugin.GetPluginsConfigDir, ReplaceStr(Plugin.GetName, ' ', '') + '.ini');
end;


// Get number of file classes managed by the settings' data model
function TSettings.GetFileClassCount: integer;
begin
  if not FValid then exit(0);

  Result := FFileClasses.Count;
end;


// Get name of the file class at a specified array index
function TSettings.GetFileClassName(Idx: integer): string;
begin
  if not FValid                then exit('');
  if Idx >= FFileClasses.Count then exit('');

  Result := FFileClasses[Idx].Name;
end;


// Set name of the file class at a specified array index
procedure TSettings.SetFileClassName(Idx: integer; Value: string);
begin
  if not FValid                then exit;
  if Idx >= FFileClasses.Count then exit;

  FFileClasses[Idx].Name := Value;
  FFileClasses.Sort;
end;


// Get EolFormat of the file class at a specified array index
function TSettings.GetFileClassEolFormat(Idx: integer): integer;
begin
  if not FValid                then exit(0);
  if Idx >= FFileClasses.Count then exit(0);

  Result := FFileClasses[Idx].EolFormat;
end;


// Set EolFormat of the file class at a specified array index
procedure TSettings.SetFileClassEolFormat(Idx: integer; Value: integer);
begin
  if not FValid                then exit;
  if Idx >= FFileClasses.Count then exit;

  FFileClasses[Idx].EolFormat := Value;
end;


// Get list of filename extensions of the file class at a specified array index
function TSettings.GetFileClassExtensions(Idx: integer): TStringList;
begin
  if not FValid                then exit(FNoExtensions);
  if Idx >= FFileClasses.Count then exit(FNoExtensions);

  Result := FFileClasses[Idx].Extensions;
end;


// -----------------------------------------------------------------------------
// I/O methods
// -----------------------------------------------------------------------------

// Parse settings file and store its content in a data model
procedure TSettings.LoadSettings;
var
  GrpCnt:          integer;
  ExtCnt:          integer;
  KeyIdx:          integer;
  Header:          TStringList;
  Groups:          TStringList;
  GroupExtensions: TStringList;

begin
  Header               := TStringList.Create;
  Header.Sorted        := false;
  Header.CaseSensitive := false;
  Header.Duplicates    := dupIgnore;
  Header.Delimiter     := ';';

  try
    // Skip header checking if the settings file doesn't exist
    if FileExists(FIniFile.FileName) then
    begin
      // In future versions of the plugin here we could call an update function
      // for the settings file of older plugin versions
      FIniFile.ReadSectionValues(SECTION_HEADER, Header);
      if not SameText(Header.Values[KEY_VERSION], VALUE_VERSION) then exit;
    end;

    // Init lists for file classes and related filename extensions
    Groups                        := TStringList.Create;
    Groups.Sorted                 := true;
    Groups.CaseSensitive          := false;
    Groups.Duplicates             := dupIgnore;
    Groups.Delimiter              := ';';

    GroupExtensions               := TStringList.Create;
    GroupExtensions.Sorted        := true;
    GroupExtensions.CaseSensitive := false;
    GroupExtensions.Duplicates    := dupIgnore;
    GroupExtensions.Delimiter     := ';';

    try
      // Retrieve data about existing file classes from settings file...
      FIniFile.ReadSectionValues(SECTION_GROUPS, Groups);

      // ...and transfer it to the datamodel
      for GrpCnt := 0 to Pred(Groups.Count) do
      begin
        FFileClasses.Add(TFileClass.Create);

        FFileClasses.Last.Name      := Groups.Names[GrpCnt];
        FFileClasses.Last.EolFormat := FIniFile.ReadInteger(Groups.Names[GrpCnt], KEY_EOLFORMAT_NAME, IDM_FORMAT_ANSI);
      end;

      // For every file class...
      for GrpCnt := 0 to Pred(FFileClasses.Count) do
      begin
        // ...read the keys of the related section
        GroupExtensions.Clear;
        FIniFile.ReadSectionValues(FFileClasses[GrpCnt].Name, GroupExtensions);

        // EolFormat data, if there is any, was already retrieved in the first
        // loop above. So we can delete this key/value pair from the list.
        KeyIdx := GroupExtensions.IndexOfName(KEY_EOLFORMAT_NAME);
        if KeyIdx > -1 then GroupExtensions.Delete(KeyIdx);

        // Store filename extensions per file class
        for ExtCnt := 0 to Pred(GroupExtensions.Count) do
          FFileClasses[GrpCnt].Extensions.Add(GroupExtensions.ValueFromIndex[ExtCnt]);
      end;

      // Sort the file class list by name
      FFileClasses.Sort;

      // If we reached this point we can mark settings as valid
      FValid := true;

    finally
      Groups.Free;
      GroupExtensions.Free;
    end;

  finally
    Header.Free;
  end;
end;


// Save settings data model to a disk file
procedure TSettings.SaveSettings;
var
  GrpCnt: integer;
  ExtCnt: integer;
  Groups: TStringList;

begin
  if not FValid then exit;

  // Clear whole settings file
  Groups := TStringList.Create;

  try
    FIniFile.ReadSections(Groups);

    for GrpCnt := 0 to Pred(Groups.Count) do
      FIniFile.EraseSection(Groups[GrpCnt]);

  finally
    Groups.Free;
  end;

  // Write Header
  FIniFile.WriteString(SECTION_HEADER, KEY_VERSION, VALUE_VERSION);

  // Write file classes data
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    // Write file class name
    FIniFile.WriteString(SECTION_GROUPS, FFileClasses[GrpCnt].Name, KEY_GRP_VAL_ACTIVE);

    // Write EolFormat and language data
    FIniFile.WriteInteger(FFileClasses[GrpCnt].Name, KEY_EOLFORMAT_NAME, FFileClasses[GrpCnt].EolFormat);

    // Write filename extensions
    for ExtCnt := 0 to Pred(FFileClasses[GrpCnt].Extensions.Count) do
      FIniFile.WriteString(FFileClasses[GrpCnt].Name, KEY_EXT_PREFIX + IntToStr(Succ(ExtCnt)), FFileClasses[GrpCnt].Extensions[ExtCnt]);
  end;
end;


// -----------------------------------------------------------------------------
// Worker methods
// -----------------------------------------------------------------------------

// Add a file class to the settings data model
procedure TSettings.AddFileClass(const AClassName: string; AEolFormat: integer);
var
  GrpCnt: integer;
  Idx:    integer;

begin
  if not FValid then exit;

  // Only add a file class if it not already exists
  Idx := -1;

  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    Idx := GrpCnt;
    break;
  end;

  if Idx <> -1 then exit;

  Idx := FFileClasses.Add(TFileClass.Create);

  FFileClasses[Idx].Name      := AClassName;
  FFileClasses[Idx].EolFormat := AEolFormat;

  FFileClasses.Sort;
end;


// Update parameters of a file class in the settings data model
procedure TSettings.UpdateFileClass(const AClassName, ANewClassName: string; AEolFormat: integer);
var
  GrpCnt: integer;
  Idx:    integer;

begin
  if not FValid then exit;

  // Only update a file class if it already exists
  Idx := -1;

  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    Idx := GrpCnt;
    break;
  end;

  if Idx = -1 then exit;

  FFileClasses[Idx].Name      := ANewClassName;
  FFileClasses[Idx].EolFormat := AEolFormat;

  FFileClasses.Sort;
end;


// Delete a file class from the settings data model
procedure TSettings.DeleteFileClass(const AClassName: string);
var
  GrpCnt: integer;

begin
  if not FValid then exit;

  // Delete a whole file class from data model
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    FFileClasses.Delete(GrpCnt);
    exit;
  end;
end;


// Add a filename extension to a file class in the settings data model
procedure TSettings.AddExtension(const AClassName, AExtension: string);
var
  GrpCnt: integer;
  ExtCnt: integer;

begin
  if not FValid then exit;

  // Add a single file extensions to a file class
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    for ExtCnt := 0 to Pred(FFileClasses[GrpCnt].Extensions.Count) do
      if SameText(FFileClasses[GrpCnt].Extensions[ExtCnt], AExtension) then exit;

    FFileClasses[GrpCnt].Extensions.Add(AExtension);
    exit;
  end;
end;


// Add a list of filename extensions to a file class in the settings data model
procedure TSettings.SetExtensions(const AClassName: string; AExtensions: TStrings);
var
  GrpCnt: integer;

begin
  if not FValid then exit;

  // Replace the current list of file extensions with a new one
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    FFileClasses[GrpCnt].Extensions.Clear;
    FFileClasses[GrpCnt].Extensions.AddStrings(AExtensions);
    exit;
  end;
end;


// Delete a filename extension from a file class in the settings data model
procedure TSettings.DeleteExtension(const AClassName, AExtension: string);
var
  GrpCnt: integer;
  ExtCnt: integer;

begin
  if not FValid then exit;

  // Delete a single filename extension off a file class
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    for ExtCnt := 0 to Pred(FFileClasses[GrpCnt].Extensions.Count) do
    begin
      if not SameText(FFileClasses[GrpCnt].Extensions[ExtCnt], AExtension) then continue;

      FFileClasses[GrpCnt].Extensions.Delete(ExtCnt);
      exit;
    end;
  end;
end;


// Delete all filename extensions from a file class in the settings data model
procedure TSettings.DeleteAllExtensions(const AClassName: string);
var
  GrpCnt: integer;

begin
  if not FValid then exit;

  // Delete all filename extensions of a file class
  for GrpCnt := 0 to Pred(FFileClasses.Count) do
  begin
    if not SameText(FFileClasses[GrpCnt].Name, AClassName) then continue;

    FFileClasses[GrpCnt].Extensions.Clear;
    break;
  end;
end;



// =============================================================================
// Class TFileClass
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TFileClass.Create;
begin
  inherited;

  FName      := '';
  FEolFormat := 0;

  FExtensions := TStringList.Create(false);

  FExtensions.Sorted        := true;
  FExtensions.CaseSensitive := false;
  FExtensions.Duplicates    := dupIgnore;
  FExtensions.Delimiter     := ';';
end;


destructor TFileClass.Destroy;
begin
  FExtensions.Free;

  inherited;
end;


end.
