{
    The content of this file was originally created by Damjan Zobo Cvetko
    Modified by Andreas Heim for using in the AutoEolFormat plugin for Notepad++

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit NppMenuCmdID;


interface

const
  // This is only a short outtake of menuCmdID.h and provides only the command
  // ids of the menu entries needed for this plugin

  // ---------------------------------------------------------------------------
  // Base id for menu entries
  // ---------------------------------------------------------------------------
  IDM                       = 40000;


  // ---------------------------------------------------------------------------
  // Menu Edit
  // ---------------------------------------------------------------------------
  IDM_EDIT                  = (IDM + 2000);

  IDM_EDIT_SETREADONLY      = (IDM_EDIT + 28);
  IDM_EDIT_CLEARREADONLY    = (IDM_EDIT + 33);


  // ---------------------------------------------------------------------------
  // Menu Encoding -> Character Set -> <Language group> -> xxxx
  // ---------------------------------------------------------------------------
  IDM_FORMAT                = (IDM + 5000);

  // EOL formats
  IDM_FORMAT_TODOS          = (IDM_FORMAT + 1);
  IDM_FORMAT_TOUNIX         = (IDM_FORMAT + 2);
  IDM_FORMAT_TOMAC          = (IDM_FORMAT + 3);

  // Character encodings
  IDM_FORMAT_ANSI           = (IDM_FORMAT + 4);
  IDM_FORMAT_UTF_8          = (IDM_FORMAT + 5);  // UTF-8 w/ BOM
  IDM_FORMAT_UCS_2BE        = (IDM_FORMAT + 6);
  IDM_FORMAT_UCS_2LE        = (IDM_FORMAT + 7);
  IDM_FORMAT_AS_UTF_8       = (IDM_FORMAT + 8);  // UTF-8 w/o BOM

  IDM_FORMAT_ENCODE         = (IDM_FORMAT + 20);

  IDM_FORMAT_WIN_1250       = (IDM_FORMAT_ENCODE + 0);
  IDM_FORMAT_WIN_1251       = (IDM_FORMAT_ENCODE + 1);
  IDM_FORMAT_WIN_1252       = (IDM_FORMAT_ENCODE + 2);
  IDM_FORMAT_WIN_1253       = (IDM_FORMAT_ENCODE + 3);
  IDM_FORMAT_WIN_1254       = (IDM_FORMAT_ENCODE + 4);
  IDM_FORMAT_WIN_1255       = (IDM_FORMAT_ENCODE + 5);
  IDM_FORMAT_WIN_1256       = (IDM_FORMAT_ENCODE + 6);
  IDM_FORMAT_WIN_1257       = (IDM_FORMAT_ENCODE + 7);
  IDM_FORMAT_WIN_1258       = (IDM_FORMAT_ENCODE + 8);

  IDM_FORMAT_ISO_8859_1     = (IDM_FORMAT_ENCODE + 9);
  IDM_FORMAT_ISO_8859_2     = (IDM_FORMAT_ENCODE + 10);
  IDM_FORMAT_ISO_8859_3     = (IDM_FORMAT_ENCODE + 11);
  IDM_FORMAT_ISO_8859_4     = (IDM_FORMAT_ENCODE + 12);
  IDM_FORMAT_ISO_8859_5     = (IDM_FORMAT_ENCODE + 13);
  IDM_FORMAT_ISO_8859_6     = (IDM_FORMAT_ENCODE + 14);
  IDM_FORMAT_ISO_8859_7     = (IDM_FORMAT_ENCODE + 15);
  IDM_FORMAT_ISO_8859_8     = (IDM_FORMAT_ENCODE + 16);
  IDM_FORMAT_ISO_8859_9     = (IDM_FORMAT_ENCODE + 17);
//  IDM_FORMAT_ISO_8859_10    = (IDM_FORMAT_ENCODE + 18);  // not used
//  IDM_FORMAT_ISO_8859_11    = (IDM_FORMAT_ENCODE + 19);  // not used
  IDM_FORMAT_ISO_8859_13    = (IDM_FORMAT_ENCODE + 20);
  IDM_FORMAT_ISO_8859_14    = (IDM_FORMAT_ENCODE + 21);
  IDM_FORMAT_ISO_8859_15    = (IDM_FORMAT_ENCODE + 22);
//  IDM_FORMAT_ISO_8859_16    = (IDM_FORMAT_ENCODE + 23);  // not used

  IDM_FORMAT_DOS_437        = (IDM_FORMAT_ENCODE + 24);
  IDM_FORMAT_DOS_720        = (IDM_FORMAT_ENCODE + 25);
  IDM_FORMAT_DOS_737        = (IDM_FORMAT_ENCODE + 26);
  IDM_FORMAT_DOS_775        = (IDM_FORMAT_ENCODE + 27);
  IDM_FORMAT_DOS_850        = (IDM_FORMAT_ENCODE + 28);
  IDM_FORMAT_DOS_852        = (IDM_FORMAT_ENCODE + 29);
  IDM_FORMAT_DOS_855        = (IDM_FORMAT_ENCODE + 30);
  IDM_FORMAT_DOS_857        = (IDM_FORMAT_ENCODE + 31);
  IDM_FORMAT_DOS_858        = (IDM_FORMAT_ENCODE + 32);
  IDM_FORMAT_DOS_860        = (IDM_FORMAT_ENCODE + 33);
  IDM_FORMAT_DOS_861        = (IDM_FORMAT_ENCODE + 34);
  IDM_FORMAT_DOS_862        = (IDM_FORMAT_ENCODE + 35);
  IDM_FORMAT_DOS_863        = (IDM_FORMAT_ENCODE + 36);
  IDM_FORMAT_DOS_865        = (IDM_FORMAT_ENCODE + 37);
  IDM_FORMAT_DOS_866        = (IDM_FORMAT_ENCODE + 38);
  IDM_FORMAT_DOS_869        = (IDM_FORMAT_ENCODE + 39);

  IDM_FORMAT_BIG5           = (IDM_FORMAT_ENCODE + 40);
  IDM_FORMAT_GB2312         = (IDM_FORMAT_ENCODE + 41);
  IDM_FORMAT_SHIFT_JIS      = (IDM_FORMAT_ENCODE + 42);
  IDM_FORMAT_KOREAN_WIN     = (IDM_FORMAT_ENCODE + 43);
  IDM_FORMAT_EUC_KR         = (IDM_FORMAT_ENCODE + 44);
  IDM_FORMAT_TIS_620        = (IDM_FORMAT_ENCODE + 45);

  IDM_FORMAT_MAC_CYRILLIC   = (IDM_FORMAT_ENCODE + 46);
  IDM_FORMAT_KOI8U_CYRILLIC = (IDM_FORMAT_ENCODE + 47);
  IDM_FORMAT_KOI8R_CYRILLIC = (IDM_FORMAT_ENCODE + 48);



implementation


end.
