'==============================================================================
'
' Patch script for pluginsxXX.xml files to automate the deployment process of
' the plugin. The script sets the version information to the provided value.
'
' Author: Andreas Heim
' Date:   18.04.2017
'
' This file is part of the deployment system of the AutoEolFormat plugin for
' Notepad++.
'
' This program is free software; you can redistribute it and/or modify it
' under the terms of the GNU General Public License version 3 as published
' by the Free Software Foundation.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License along
' with this program; if not, write to the Free Software Foundation, Inc.,
' 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
'
'==============================================================================


'Variables have to be declared before first usage
Option Explicit


'Declare variables
Dim strEnvVar, strPluginName, strPlatform, strPlatformAlias, strRepositoryBaseUrl
Dim strXmlFile, strVersion, strVersionKey, strSourceUrlKey, strDownloadKey

Dim objFSO, objWshShell, objXmlDoc
Dim objPluginNode, objVersionNode, objSourceUrlNode, objDownloadNode


'Create some basic objects
Set objFSO      = CreateObject("Scripting.FileSystemObject")
Set objWshShell = CreateObject("WScript.Shell")
Set objXmlDoc   = CreateObject("Microsoft.XMLDOM")


'Retrieve plugin name from environment variable
strEnvVar     = "%PluginName%"
strPluginName = objWshShell.ExpandEnvironmentStrings(strEnvVar)

'Terminate with error code if environment variable is not set
If strPluginName = strEnvVar Then
  WScript.Echo WScript.ScriptName & ": Environment variable not set"
  WScript.Quit 1
End If


'Retrieve target platform from environment variable
strPlatform = objWshShell.ExpandEnvironmentStrings("%Platform%")

'Set target platform platform independent variables
strRepositoryBaseUrl = "https://github.com/dinkumoil/" & strPluginName
strSourceUrlKey      = "sourceUrl"
strDownloadKey       = "install/unicode/download"

'Set target platform specific variables
If StrComp(strPlatform, "Win32", vbTextCompare) = 0 Then
  strEnvVar        = "%Plugins86XmlFile%"
  strPlatformAlias = "UNI"
  strVersionKey    = "unicodeVersion"

ElseIf StrComp(strPlatform, "Win64", vbTextCompare) = 0 Then
  strEnvVar        = "%Plugins64XmlFile%"
  strPlatformAlias = "x64"
  strVersionKey    = "x64Version"
  
Else
  WScript.Echo WScript.ScriptName & ": Unknown target platform"
  WScript.Quit 2
End If


'Retrieve input file from environment variable
strXmlFile = objWshShell.ExpandEnvironmentStrings(strEnvVar)

'Terminate with error code if environment variable is not set
If strXmlFile = strEnvVar Then
  WScript.Echo WScript.ScriptName & ": Environment variable not set"
  WScript.Quit 3
End If


'Retrieve absolute path of input file
strXmlFile = objFSO.GetAbsolutePathName(strXmlFile)

'Terminate with error code if input file does not exist
If Not objFSO.FileExists(strXmlFile) Then
  WScript.Echo WScript.ScriptName & ": File not found"
  WScript.Quit 4
End If


'Terminate with error code if params count is wrong
If WScript.Arguments.Count < 1 Then
  WScript.Echo WScript.ScriptName & ": Missing arguments"
  WScript.Quit 5
Else
  'Retrieve plugin version from command line param
  strVersion = WScript.Arguments(0)
End If


'Load XML file
objXmlDoc.async = False
objXmlDoc.load(strXmlFile)

'Terminate with error code on parsing errors
If objXmlDoc.parseError.errorCode <> 0 Then
  WScript.Echo WScript.ScriptName & ": XML file corrupted"
  WScript.Quit 6
End If


'Retrieve plugin's root node
Set objPluginNode = objXmlDoc.documentElement.selectSingleNode("//plugin[@name='" & strPluginName & "']")

'Retrieve plugin's version node and set its value
Set objVersionNode = objPluginNode.selectSingleNode(strVersionKey)
objVersionNode.nodeTypedValue = strVersion

'Retrieve plugin's sourceURL node and set its value
Set objSourceUrlNode = objPluginNode.selectSingleNode(strSourceUrlKey)
objSourceUrlNode.nodeTypedValue = strRepositoryBaseUrl

'Retrieve plugin's download node and set its value
Set objDownloadNode = objPluginNode.selectSingleNode(strDownloadKey)
objDownloadNode.nodeTypedValue = strRepositoryBaseUrl & "/releases/download/v" & strVersion & "/" & strPluginName & "_v" & strVersion & "_" & strPlatformAlias & ".zip"


'Save XML file
objXmlDoc.save(strXmlFile)


'Output message indicating success
WScript.Echo "File """ & objFSO.GetFileName(strXmlFile) & """ successfully patched"

'Exit
WScript.Quit 0
