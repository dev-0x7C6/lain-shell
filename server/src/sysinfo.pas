{ Copyright (C) 2007-2008 Bartlomiej Burdukiewicz

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 3 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit SysInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils;

Const
 Fammily_Unknown :Byte = 0;
 Fammily_Unix :Byte = 1;
 Fammily_Windows :Byte = 2;
{$ifdef unix}
 MemInfoFile = '/proc/meminfo';
{$endif}

Const
 Lain_SysInfo_GetInfo = 20;
 
 function LainShellSystemInformation(var Connection :TTcpIpCustomConnection) :Longint;

implementation


uses {$ifdef unix} Unix, BaseUnix, {$endif} {$ifdef windows} Windows, {$endif} Engine;

function LainShellSystemInformation(var Connection :TTcpIpCustomConnection) :Longint;
var
 SysFammily :Byte;
 SysInfoStr :TStringList; // multiplatform LineEnding ?
 SysInfoDat :AnsiString;
{$ifdef unix}
 TFFile :TStringList;
 UNameInfo :UtsName;
{$endif}
begin
 SysInfoStr := TStringList.Create;
 SysFammily := Fammily_Unknown;
{$ifdef unix}
 SysFammily := Fammily_Unix;
 if fpuname(UNameInfo) <> -1 then
 begin
  SysInfoStr.Add('Information from uname');
  SysInfoStr.Add('');
  SysInfoStr.Add('System name: ' + UNameInfo.SysName);
  SysInfoStr.Add('Commputer name: ' + UNameInfo.Nodename);
  SysInfoStr.Add('Release: ' + UNameInfo.Release);
  SysInfoStr.Add('Version: ' + UNameInfo.Version);
  SysInfoStr.Add('Machine: ' + UNameInfo.Machine);
  SysInfoStr.Add('Domain: ' + UNameInfo.Domain);
  SysInfoStr.Add('');
 end else
 begin
  SysInfoStr.Add('Can''t get infomations from uname');
  SysInfoStr.Add('');
 end;

 if fpAccess (MemInfoFile, R_OK) = 0 then
 begin
  SysInfoStr.Add('Information from file "' + MemInfoFile + '"');
  SysInfoStr.Add('');
  TFFile := TStringList.Create;
  TFFile.LoadFromFile(MemInfoFile);
  SysInfoStr.AddStrings(TFFile);
  TFFile.Free;
 end else
 begin
  SysInfoStr.Add('Can''t get information from "' + MemInfoFile + '"');
  SysInfoStr.Add('');
 end;
 
 
{$endif}
{$ifdef windows}
 SysFammily := Fammily_Windows;
{$endif}
 SysInfoDat := SysInfoStr.Text;
 SysInfoStr.Free;
 
 if Connection.Send(SysFammily, SizeOf(SysFammily)) <> SizeOf(SysFammily) then Exit(Lain_Error);
 if Connection.SendString(SysInfoDat) = False then Exit(Lain_Error);

end;

end.

