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

unit Shell;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils;

Const
 Lain_Shell_List = 10;
 Lain_Shell_ChShell = 11;
 Lain_Shell_ReadPipe = 12;
 Lain_Shell_WritePipe = 13;
 Lain_Shell_ErrorPipe = 14;

Const
 PathSh = '/bin/sh';
 PathBash = '/bin/bash';
 
Const
 ShShellID = 0;
 BashShellID = 1;

Type
 TLainShellList = packed record
  Sh :Boolean;
  Bash :Boolean;
 end;

var
 OpenShellExists :Boolean = False;
 ShellInput :Text;
 ShellOutPut :Text;
 ShellError :Text;

 function LainShellList(var Connection :TTcpIpCustomConnection) :Longint;

implementation

uses {$ifdef unix} UnixBase {$endif} Engine;

function LainShellList(var Connection :TTcpIpCustomConnection) :Longint;
var
 VLainShellList :TLainShellList;
begin
 VLainShellList.Sh := FileExists(PathSh);
 VLainShellList.Bash := FileExists(PathBash);
 if Connection.Send(VLainShellList, SizeOf(VLainShellList)) = SizeOf(VLainShellList) then
  Result := Lain_Ok else
  Result := Lain_Error;
end;

function LainShellChShell(var Connection :TTcpIpCustomConnection) :Longint;
var
 ShellID :Byte;
 Path :String;
begin
 Result := Lain_Ok;
 if Connection.Recv(ShellID, SizeOf(ShellID)) = SizeOf(ShellID) then
  Result := Lain_Ok else
  Result := Lain_Error;
 case ShellID of
  ShShellID: Path := PathSh;
  BashShellID: Path := PathBash
 else
  Result := Lain_Error;
 end;
{$ifdef unix}
 if OpenShellExists then
 begin
  Writeln(ShellOutput, 'exit');
  Close(ShellInput);
  Close(ShellOutput);
  Close(ShellError);
 end;
 if AssignStream(ShellInput, ShellOutput, ShellError, Path, []) <> -1 then
  Result := Lain_Ok else
  Result := Lain_Error;
{$endif}
end;

end.

