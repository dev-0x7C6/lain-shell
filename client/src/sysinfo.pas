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
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgNotConnectedAndAuthorized'), EndLineChar);
  Exit(CMD_Fail);
 end;
 
 Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgWaitForResponse'), EndLineChar);
 Writeln(EndLineChar);
 
 LainClientSendQuery(Lain_SysInfo_GetInfo);
 LainClientWaitForQuery;
 Result := CMD_Done;
end;

function CMD_SysInfo_Query :Longint;
var
 StrList :TStringList;
 StrNum :Longint;
 Text :String;
 Fammily :Byte;

begin
 StrList := TStringList.Create;
 Connection.Recv(Fammily, SizeOf(Fammily));
 Connection.RecvString(Text);
 StrList.Add(Text);
 EnterCriticalSection(CriticalSection);
 if StrList.Count > 0 then
 begin
  For StrNum := 0 to StrList.Count - 1 do
   Writeln(StrList[StrNum]);
 end;
 Writeln(MultiLanguageSupport.GetString('MsgEndOfData'), EndLineChar);
 LeaveCriticalSection(CriticalSection);
 StrList.Free;
end;

end.

