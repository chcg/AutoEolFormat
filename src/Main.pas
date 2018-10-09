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

unit Main;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.DateUtils,
  System.IOUtils, System.Math, System.Types, System.Classes, System.Generics.Defaults,
  System.Generics.Collections,

  SciSupport, NppSupport, NppPlugin, NppPluginForms, NppPluginDockingForms,

  DataModule,

  dialog_TfrmSettings,
  dialog_TfrmAbout;


type
  // Plugin class
  TAutoEolFormatPlugin = class(TNppPlugin)
  private type
    TBufferCatalog = TDictionary<integer, string>;

  private
    FCurFileClassIdx: integer;
    FBuffers:         TBufferCatalog;
    FSettings:        TSettings;
    FBlockEvents:     boolean;

    // Functions to handle Notepad++ closing or renaming a document
    // or activating another document's tab
    procedure   CheckBufferChanges;
    procedure   CheckFileChanges;
    procedure   RemoveCurrentBufferFromCatalog;

    // Function to change the EOL format of the active Notepad++ document
    procedure   SwitchToEolFormat;

    // Functions to check if the filename extension or the language of the
    // active Notepad++ document fits the requirements of a certain file class
    function    MatchFileNameExt: boolean;

    // Retrieves the index of the file class the active document belongs to
    procedure   GetCurFileClassIdx();

  protected
    // Handler for certain Notepad++ events
    procedure   DoNppnReady; override;
    procedure   DoNppnFileBeforeLoad; override;
    procedure   DoNppnFileLoadFailed; override;
    procedure   DoNppnFileOpened; override;
    procedure   DoNppnFileBeforeSave; override;
    procedure   DoNppnBeforeShutDown; override;
    procedure   DoNppnCancelShutDown; override;

    procedure   DoNppnBufferActivated; override;
    procedure   DoNppnFileSaved; override;
    procedure   DoNppnFileRenamed; override;
    procedure   DoNppnFileBeforeClose; override;

  public
    constructor Create; override;
    destructor  Destroy; override;

    // Access to basic plugin functions
    procedure   LoadSettings();
    procedure   UnloadSettings();

    procedure   UpdateCurBuffer();

  end;


var
  // Class type to create in startup code
  PluginClass: TNppPluginClass = TAutoEolFormatPlugin;

  // Plugin instance variable, this is the reference to use in plugin's code
  Plugin: TAutoEolFormatPlugin;



implementation

const
  // Plugin name
  TXT_PLUGIN_NAME:       string = 'AutoEolFormat';

  TXT_MENUITEM_SETTINGS: string = 'Settings';
  TXT_MENUITEM_ABOUT:    string = 'About';


// Functions associated to the plugin's Notepad++ menu entries
procedure ShowSettings; cdecl; forward;
procedure ShowAbout; cdecl; forward;


// =============================================================================
// Class TAutoEolFormatPlugin
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TAutoEolFormatPlugin.Create;
begin
  inherited Create;

  // Store a reference to the instance in a global variable with an appropriate
  // type to get access to its properties and methods
  Plugin := Self;

  // This property is important to extract version infos from the DLL file,
  // so set it right now after creation of the object
  PluginName := TXT_PLUGIN_NAME;

  // Add plugins's menu entries to Notepad++
  AddFuncItem(TXT_MENUITEM_SETTINGS, ShowSettings);
  AddFuncItem(TXT_MENUITEM_ABOUT,    ShowAbout);

  FBuffers         := TBufferCatalog.Create;
  FCurFileClassIdx := -1;
  FBlockEvents     := false;
end;


destructor TAutoEolFormatPlugin.Destroy;
begin
  // Cleanup
  FBuffers.Free;

  UnloadSettings();

  // It's totally legal to call Free on already freed instances,
  // no checks needed
  frmAbout.Free;
  frmSettings.Free;

  inherited;
end;


// -----------------------------------------------------------------------------
// (De-)Initialization
// -----------------------------------------------------------------------------

// Read settings file
procedure TAutoEolFormatPlugin.LoadSettings;
begin
  FSettings := TSettings.Create(TSettings.FilePath);
end;


// Free settings data model
procedure TAutoEolFormatPlugin.UnloadSettings;
begin
  FreeAndNil(FSettings);
end;


// Emulate the activation of a document's tab in Notepad++
procedure TAutoEolFormatPlugin.UpdateCurBuffer;
begin
  DoNppnBufferActivated();
end;


// -----------------------------------------------------------------------------
// Event handler
// -----------------------------------------------------------------------------

// Called after Notepad++ has started and is ready for work
procedure TAutoEolFormatPlugin.DoNppnReady;
begin
  inherited;

  // Load settings and apply them to the active document
  LoadSettings();
  UpdateCurBuffer();
end;


// Called before a file is loaded
procedure TAutoEolFormatPlugin.DoNppnFileBeforeLoad;
begin
  FBlockEvents := true;
end;


// Called after a file load operation has failed
procedure TAutoEolFormatPlugin.DoNppnFileLoadFailed;
begin
  FBlockEvents := false;
end;


// Called after a file has been opened
procedure TAutoEolFormatPlugin.DoNppnFileOpened;
begin
  FBlockEvents := false;
end;


// Called just before a file is saved
procedure TAutoEolFormatPlugin.DoNppnFileBeforeSave;
begin
  FBlockEvents := true;
end;


// Called when Notepad++ shut down has been triggered
procedure TAutoEolFormatPlugin.DoNppnBeforeShutDown;
begin
  FBlockEvents := true;
end;


// Called when Notepad++ shut down has been cancelled
procedure TAutoEolFormatPlugin.DoNppnCancelShutDown;
begin
  FBlockEvents := false;
end;


// Called after activating the tab of a file
procedure TAutoEolFormatPlugin.DoNppnBufferActivated;
begin
  if FBlockEvents then exit;

  CheckBufferChanges();
end;


// Called after a file has been saved
procedure TAutoEolFormatPlugin.DoNppnFileSaved;
begin
  FBlockEvents := false;

  CheckBufferChanges();
end;


// Called after renaming a file in Notepad++
procedure TAutoEolFormatPlugin.DoNppnFileRenamed;
begin
  if FBlockEvents then exit;

  CheckFileChanges();
end;


// Called just before a file and its tab is closed
procedure TAutoEolFormatPlugin.DoNppnFileBeforeClose;
begin
  if FBlockEvents then exit;

  RemoveCurrentBufferFromCatalog();
end;


// -----------------------------------------------------------------------------
// Worker methods
// -----------------------------------------------------------------------------

// Change documents EOL format if its filename extension
// fits the requirements of a file class
procedure TAutoEolFormatPlugin.CheckBufferChanges;
var
  CurBufferId: integer;
  CurFileName: string;

begin
  if not MatchFileNameExt() then exit;

  CurBufferId := GetCurrentBufferId();
  CurFileName := GetFullCurrentPath();

  // Only change EOL format if it hasn't been done already
  if not FBuffers.ContainsKey(CurBufferId)   or
     not FBuffers.ContainsValue(CurFileName) then
  begin
    // Remember buffer ID
    FBuffers.AddOrSetValue(CurBufferId, CurFileName);

    // Change EOL format
    SwitchToEolFormat();
  end;
end;


// If a document has been renamed and its new filename extension is not
// a member of a file class remove its reference from the dictionary
// else check if its EOL format has to be changed
procedure TAutoEolFormatPlugin.CheckFileChanges;
begin
  if not MatchFileNameExt() then
    RemoveCurrentBufferFromCatalog()
  else
    CheckBufferChanges();
end;


// Delete reference to current text buffer
procedure TAutoEolFormatPlugin.RemoveCurrentBufferFromCatalog;
begin
  FBuffers.Remove(GetCurrentBufferId());
end;


// Request change of EOL format
procedure TAutoEolFormatPlugin.SwitchToEolFormat;
begin
  PerformMenuCommand(FSettings.FileClassEolFormat[FCurFileClassIdx]);
end;


// -----------------------------------------------------------------------------
// Test methods
// -----------------------------------------------------------------------------

// Check if the filename extension of the active Notepad++ document
// is a member of a file class
function TAutoEolFormatPlugin.MatchFileNameExt: boolean;
begin
  GetCurFileClassIdx();
  Result := (FCurFileClassIdx >= 0)
end;


// Searches in the array of file classes the filename extension of the active
// Notepad++ document and sets a global variable to the index of the matching
// file class
procedure TAutoEolFormatPlugin.GetCurFileClassIdx();
var
  Cnt:         integer;
  FileNameExt: string;

begin
  FCurFileClassIdx := -1;

  if not Assigned(FSettings) then exit;
  if not FSettings.Valid     then exit;

  // Retrieve filename extension
  FileNameExt := GetFileNameExt();

  // Check if there is a file class where the extension fits to
  for Cnt := 0 to Pred(FSettings.FileClassCount) do
  begin
    if IndexText(FileNameExt, SplitString(FSettings.FileClassExtensions[Cnt].DelimitedText,
                                          FSettings.FileClassExtensions[Cnt].Delimiter)) >= 0 then
    begin
      FCurFileClassIdx := Cnt;
      exit;
    end;
  end;
end;



// -----------------------------------------------------------------------------
// Plugin menu items
// -----------------------------------------------------------------------------

// Show "Settings" dialog in Notepad++
procedure ShowSettings; cdecl;
begin
  if not Assigned(frmSettings) then
  begin
    // Before opening the settings dialog discard own settings object
    Plugin.UnloadSettings();

    // Show settings dialog in a modal state and destroy it after close
    frmSettings := TfrmSettings.Create(Plugin);
    frmSettings.ShowModal;
    frmSettings.Free;

    // Load maybe updated settings and apply it to the active Notepad++ document
    Plugin.LoadSettings();
    Plugin.UpdateCurBuffer();
  end;
end;


// Show "About" dialog in Notepad++
procedure ShowAbout; cdecl;
begin
  if not Assigned(frmAbout) then
  begin
    // Show about dialog in a modal state and destroy it after close
    frmAbout := TfrmAbout.Create(Plugin);
    frmAbout.ShowModal;
    frmAbout.Free;
  end;
end;


end.
