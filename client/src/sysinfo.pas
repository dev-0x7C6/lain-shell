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

unit Sysinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main;

Const
 Lain_SysInfo_GetInfo = 20;
   
 function CMD_SysInfo(var Params :TParams) :Longint;
 function CMD_SysInfo_Query :Longint;
 

implementation

uses Engine, Lang;

function CMD_SysInfo(var Params :TParams) :Longint;
begin
 if CheckConnectionAndAuthorization = False then
  Exit(CMD_Fail);
 Writeln(Prefix, MultiLanguageSupport.GetString('MsgWaitForResponse'), EndLineChar);
 Writeln(EndLineChar);
 
 LainClientSendQuery(Lain_SysInfo_GetInfo);
 RTLEventWaitFor(ConsoleEvent);
 RTLEventResetEvent(ConsoleEvent);
 Result := CMD_Done;
end;

function CMD_SysInfo_Query :Longint;
var
 Str :AnsiString;
 Fammily :Byte;
begin
 Connection.Recv(Fammily, SizeOf(Fammily));
 Connection.RecvString(Str);
 EnterCriticalSection(CriticalSection);
 Writeln(Str, EndLineChar);
 LeaveCriticalSection(CriticalSection);
end;

end.

