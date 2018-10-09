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

unit dialog_TfrmSettings;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.IOUtils,
  System.Math, System.Types, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Forms, Vcl.Dialogs,

  NppSupport, NppMenuCmdID, NppPlugin, NppPluginForms,

  DataModule;


type
  TfrmSettings = class(TNppPluginForm)
    lbxGroups: TListBox;
    btnAddGroup: TButton;
    btnUpdateGroup: TButton;
    btnDeleteGroup: TButton;
    edtNewGroupName: TLabeledEdit;
    lblEolFormatHeader: TStaticText;
    cbxEolFormat: TComboBox;

    lbxExtensions: TListBox;
    btnAddExtension: TButton;
    btnDeleteExtension: TButton;
    edtNewExtension: TLabeledEdit;

    btnClose: TButton;

    procedure FormCreate(Sender: TObject);

    procedure lbxGroupsClick(Sender: TObject);
    procedure btnAddGroupClick(Sender: TObject);
    procedure btnDeleteGroupClick(Sender: TObject);
    procedure btnUpdateGroupClick(Sender: TObject);

    procedure edtNewGroupNameChange(Sender: TObject);
    procedure cbxEolFormatChange(Sender: TObject);

    procedure lbxExtensionsClick(Sender: TObject);
    procedure btnAddExtensionClick(Sender: TObject);
    procedure btnDeleteExtensionClick(Sender: TObject);

    procedure edtNewExtensionChange(Sender: TObject);

    procedure btnCloseClick(Sender: TObject);

  private
    FInUpdateGUI: boolean;
    FSettings:    TSettings;

    procedure   InitLists;
    procedure   LoadSettings(const AFilePath: string);

    procedure   UpdateExtensions;

    procedure   PrepareGUI;
    procedure   UpdateGUI(const SkipControls: array of TControl);

    function    ArrayContains(const AArray: array of TControl; AItem: TControl): boolean;

  public
    constructor Create(NppParent: TNppPlugin); override;
    destructor  Destroy; override;

    procedure   InitLanguage; override;

  end;


var
  frmSettings: TfrmSettings;



implementation

{$R *.dfm}


const
  TXT_HINT_BTN_ADD_GROUP:       string = 'Add group';
  TXT_CAPTION_BTN_UPDATE_GROUP: string = 'Update';
  TXT_HINT_BTN_UPDATE_GROUP:    string = 'Update group';
  TXT_HINT_BTN_DEL_GROUP:       string = 'Delete group';

  TXT_CAPTION_EDT_NEW_GROUP:    string = 'Group name';
  TXT_CAPTION_CBX_EOLFORMAT:     string = 'EOL format to set';

  TXT_HINT_BTN_ADD_EXT:         string = 'Add extension';
  TXT_HINT_BTN_DEL_EXT:         string = 'Delete extension';

  TXT_CAPTION_EDT_NEW_EXT:      string = 'New filename extension(s)';
  TXT_HINT_EDT_NEW_EXT:         string = 'Separate multiple extensions by semicolon';

  TXT_CAPTION_BTN_CLOSE:        string = 'Close';


type
  TEolFormatMapping = record
    Name:        string;
    MenuCommand: integer;
  end;


var
  // ---------------------------------------------------------------------------
  // Mapping of EOL format names to the menu command id which has to be send to
  // Notepad++ to switch to this format
  // This array is used to fill the entries in the "EOL format to set" combobox
  // ---------------------------------------------------------------------------
  EolFormatMappings: array[0..2] of TEolFormatMapping = (
    (Name: 'Windows (CR LF)' ;  MenuCommand: IDM_FORMAT_TODOS ),
    (Name: 'Unix (LF)'       ;  MenuCommand: IDM_FORMAT_TOUNIX),
    (Name: 'Macintosh (CR)'  ;  MenuCommand: IDM_FORMAT_TOMAC )
  );


// =============================================================================
// Class TfrmSettings
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TfrmSettings.Create(NppParent: TNppPlugin);
begin
  inherited;

  DefaultCloseAction := caHide;
  FInUpdateGUI       := false;
end;


destructor TfrmSettings.Destroy;
begin
  FSettings.Free;

  inherited;
  frmSettings := nil;
end;


// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

// Perform basic initialization tasks
procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  Caption := Plugin.GetName;

  InitLanguage;
  InitLists;
  LoadSettings(TSettings.FilePath);

  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Set caption of GUI controls
procedure TfrmSettings.InitLanguage;
begin
  inherited;

  btnAddGroup.Hint                  := TXT_HINT_BTN_ADD_GROUP;
  btnUpdateGroup.Caption            := TXT_CAPTION_BTN_UPDATE_GROUP;
  btnUpdateGroup.Hint               := TXT_HINT_BTN_UPDATE_GROUP;
  btnDeleteGroup.Hint               := TXT_HINT_BTN_DEL_GROUP;

  edtNewGroupName.EditLabel.Caption := TXT_CAPTION_EDT_NEW_GROUP;
  lblEolFormatHeader.Caption        := TXT_CAPTION_CBX_EOLFORMAT;

  btnAddExtension.Hint              := TXT_HINT_BTN_ADD_EXT;
  btnDeleteExtension.Hint           := TXT_HINT_BTN_DEL_EXT;

  edtNewExtension.EditLabel.Caption := TXT_CAPTION_EDT_NEW_EXT;
  edtNewExtension.Hint              := TXT_HINT_EDT_NEW_EXT;

  btnClose.Caption                  := TXT_CAPTION_BTN_CLOSE;
end;


// Init comboboxes
procedure TfrmSettings.InitLists;
var
  Cnt: integer;

begin
  // Fill "EOL format to set" combobox
  for Cnt := Low(EolFormatMappings) to High(EolFormatMappings) do
    cbxEolFormat.Items.AddObject(EolFormatMappings[Cnt].Name, TObject(EolFormatMappings[Cnt].MenuCommand));
end;


// Load settings from disk file and show settings of first file class available
procedure TfrmSettings.LoadSettings(const AFilePath: string);
var
  Cnt: integer;

begin
  FSettings := TSettings.Create(AFilePath);

  // Set file group entries
  for Cnt := 0 to Pred(FSettings.FileClassCount) do
    lbxGroups.Items.Add(FSettings.FileClassName[Cnt]);

  // Set EOL format combobox to the settings of first file group
  if FSettings.FileClassCount > 0 then
  begin
    lbxGroups.ItemIndex    := 0;
    cbxEolFormat.ItemIndex := cbxEolFormat.Items.IndexOfObject(TObject(FSettings.FileClassEolFormat[0]));
  end;
end;


// -----------------------------------------------------------------------------
// Event handlers
// -----------------------------------------------------------------------------

// Add a file class
procedure TfrmSettings.btnAddGroupClick(Sender: TObject);
var
  GroupList: TStringList;

begin
  if not FSettings.Valid then exit;

  GroupList := TStringList.Create;

  try
    GroupList.Sorted        := true;
    GroupList.CaseSensitive := false;
    GroupList.Duplicates    := dupIgnore;
    GroupList.Delimiter     := ';';

    GroupList.AddStrings(lbxGroups.Items);
    GroupList.Add(edtNewGroupName.Text);

    // Only add a new file group entry if there is no other file group
    // with the same name
    if GroupList.Count > lbxGroups.Count then
    begin
      FSettings.AddFileClass(edtNewGroupName.Text,
                             integer(cbxEolFormat.Items.Objects[cbxEolFormat.ItemIndex]));

      lbxGroups.Clear;
      lbxGroups.Items.AddStrings(GroupList);
      lbxGroups.ItemIndex := GroupList.IndexOf(edtNewGroupName.Text);
    end;

    UpdateExtensions;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    GroupList.Free;
  end;
end;


// Update a file class' parameters
procedure TfrmSettings.btnUpdateGroupClick(Sender: TObject);
var
  Cnt:       integer;
  GroupList: TStringList;

begin
  if not FSettings.Valid then exit;

  GroupList := TStringList.Create;

  try
    GroupList.Sorted        := true;
    GroupList.CaseSensitive := false;
    GroupList.Duplicates    := dupIgnore;
    GroupList.Delimiter     := ';';

    GroupList.AddStrings(lbxGroups.Items);

    // Only update file group data if its name has not changed or if there
    // is no other file group with the same name
    if SameText(GroupList[lbxGroups.ItemIndex], edtNewGroupName.Text) or
       (GroupList.IndexOf(edtNewGroupName.Text) = -1)                 then
    begin
      FSettings.UpdateFileClass(lbxGroups.Items[lbxGroups.ItemIndex],
                                edtNewGroupName.Text,
                                integer(cbxEolFormat.Items.Objects[cbxEolFormat.ItemIndex]));

      GroupList.Clear;

      for Cnt := 0 to Pred(FSettings.FileClassCount) do
        GroupList.Add(FSettings.FileClassName[Cnt]);

      lbxGroups.Clear;
      lbxGroups.Items.AddStrings(GroupList);
      lbxGroups.ItemIndex := GroupList.IndexOf(edtNewGroupName.Text);
    end;

    UpdateExtensions;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    GroupList.Free;
  end;
end;


// Delete a file class
procedure TfrmSettings.btnDeleteGroupClick(Sender: TObject);
begin
  if not FSettings.Valid then exit;

  lbxExtensions.SelectAll;
  btnDeleteExtensionClick(Self);

  FSettings.DeleteFileClass(edtNewGroupName.Text);

  // Reset GUI
  lbxGroups.DeleteSelected;
  edtNewGroupName.Clear;
  cbxEolFormat.ItemIndex := -1;

  if lbxGroups.Count > 0 then
    lbxGroups.ItemIndex := 0;

  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Add filename extension(s) to a file class
procedure TfrmSettings.btnAddExtensionClick(Sender: TObject);
var
  I:             integer;
  Cnt:           integer;
  IsValidExt:    boolean;
  Extensions:    TStringDynArray;
  ExtensionList: TStringList;

begin
  if not FSettings.Valid then exit;

  Extensions    := SplitString(edtNewExtension.Text, ';');
  ExtensionList := TStringList.Create;

  try
    ExtensionList.Sorted        := true;
    ExtensionList.CaseSensitive := false;
    ExtensionList.Duplicates    := dupIgnore;
    ExtensionList.Delimiter     := ';';

    ExtensionList.AddStrings(lbxExtensions.Items);

    for Cnt := Low(Extensions) to High(Extensions) do
    begin
      IsValidExt := true;

      // Only accept valid filename extensions
      for I := 1 to Length(Extensions[Cnt]) do
      begin
        if not TPath.IsValidFileNameChar(Extensions[Cnt][I]) then
        begin
          IsValidExt := false;
          break;
        end;
      end;

      if IsValidExt then
      begin
        Extensions[Cnt] := '.' + ReplaceStr(Extensions[Cnt], '.', '');
        if Length(Extensions[Cnt]) > 1 then ExtensionList.Add(Extensions[Cnt]);
      end;
    end;

    // Only update data model if we have a selected file group entry
    if InRange(lbxGroups.ItemIndex, 0, Pred(FSettings.FileClassCount)) then
    begin
      FSettings.SetExtensions(FSettings.FileClassName[lbxGroups.ItemIndex], ExtensionList);

      lbxExtensions.Clear;
      lbxExtensions.Items.AddStrings(ExtensionList);
      lbxExtensions.ItemIndex := ExtensionList.IndexOf(Extensions[0]);
      lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
    end;

    edtNewExtension.Clear;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    ExtensionList.Free;
  end;
end;


// Delete filename extension from a file class
procedure TfrmSettings.btnDeleteExtensionClick(Sender: TObject);
begin
  if not FSettings.Valid then exit;

  lbxExtensions.DeleteSelected;
  edtNewExtension.Clear;

  // Only update data model if we have a selected file group entry
  if InRange(lbxGroups.ItemIndex, 0, Pred(FSettings.FileClassCount)) then
    FSettings.SetExtensions(FSettings.FileClassName[lbxGroups.ItemIndex], lbxExtensions.Items);

  if lbxExtensions.Count > 0 then
  begin
    lbxExtensions.ItemIndex := 0;
    lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
  end;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Show parameters of selected file class
procedure TfrmSettings.lbxGroupsClick(Sender: TObject);
begin
  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Change state of GUI controls according to file class name data
procedure TfrmSettings.edtNewGroupNameChange(Sender: TObject);
begin
  UpdateGUI([edtNewGroupName, cbxEolFormat]);
end;


// Change state of GUI controls according to EOL format data
procedure TfrmSettings.cbxEolFormatChange(Sender: TObject);
begin
  UpdateGUI([edtNewGroupName, cbxEolFormat]);
end;


// Show filename extension parameters
procedure TfrmSettings.lbxExtensionsClick(Sender: TObject);
begin
  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Change state of GUI controls according to filename extension data
procedure TfrmSettings.edtNewExtensionChange(Sender: TObject);
begin
  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Close dialog
procedure TfrmSettings.btnCloseClick(Sender: TObject);
begin
  Close;
end;


// -----------------------------------------------------------------------------
// Internal worker methods
// -----------------------------------------------------------------------------

// Store filename extension data in settings data model
procedure TfrmSettings.UpdateExtensions;
begin
  if not FSettings.Valid     then exit;
  if lbxGroups.ItemIndex < 0 then exit;

  lbxExtensions.Clear;
  lbxExtensions.Items.AddStrings(FSettings.FileClassExtensions[lbxGroups.ItemIndex]);

  if FSettings.FileClassExtensions[lbxGroups.ItemIndex].Count > 0 then
  begin
    lbxExtensions.ItemIndex := 0;
    lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
  end;
end;


// Set state of GUI controls I
procedure TfrmSettings.PrepareGUI;
begin
  btnAddGroup.Enabled    := false;
  btnUpdateGroup.Enabled := false;
end;


// Set state of GUI controls II
procedure TfrmSettings.UpdateGUI(const SkipControls: array of TControl);
begin
  if FInUpdateGUI then exit;

  // Semaphore to lock the following code section
  FInUpdateGUI := true;

  try
    // The array SkipControls can contain controls which should be excluded
    // from GUI update because the caller has already set the state of these
    // controls and doesn't want to get it changed
    if not ArrayContains(SkipControls, edtNewGroupName) then
      if lbxGroups.ItemIndex >= 0 then
        edtNewGroupName.Text     := FSettings.FileClassName[lbxGroups.ItemIndex];

    if not ArrayContains(SkipControls, cbxEolFormat) then
      if lbxGroups.ItemIndex >= 0 then
        cbxEolFormat.ItemIndex    := cbxEolFormat.Items.IndexOfObject(TObject(FSettings.FileClassEolFormat[lbxGroups.ItemIndex]));

    if not ArrayContains(SkipControls, btnAddGroup) then
      btnAddGroup.Enabled        := (edtNewGroupName.Text  <> '')                                              and
                                    ((lbxGroups.ItemIndex = -1) or
                                     not SameText(edtNewGroupName.Text, lbxGroups.Items[lbxGroups.ItemIndex])) and
                                    (cbxEolFormat.ItemIndex <> -1);

    if not ArrayContains(SkipControls, btnDeleteGroup) then
      btnDeleteGroup.Enabled     := (lbxGroups.ItemIndex  <> -1);

    if not ArrayContains(SkipControls, btnUpdateGroup) then
      btnUpdateGroup.Enabled     := (lbxGroups.ItemIndex   <> -1) and
                                    (edtNewGroupName.Text  <> '') and
                                    (cbxEolFormat.ItemIndex <> -1);

    if not ArrayContains(SkipControls, btnAddExtension) then
      btnAddExtension.Enabled    := (edtNewExtension.Text <> '') and
                                    (lbxGroups.ItemIndex  <> -1);

    if not ArrayContains(SkipControls, btnDeleteExtension) then
      btnDeleteExtension.Enabled := (lbxExtensions.ItemIndex <> -1);

  finally
    // Unlock section
    FInUpdateGUI := false;
  end;
end;


// Check if an array contains a specified GUI control
function TfrmSettings.ArrayContains(const AArray: array of TControl; AItem: TControl): boolean;
var
  Cnt: integer;

begin
  Result := false;

  for Cnt := 0 to Pred(Length(AArray)) do
    if AArray[Cnt] = AItem then exit(true);
end;


end.

