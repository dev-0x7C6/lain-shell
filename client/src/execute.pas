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

unit Execute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main;

Const
 Lain_Execute = 10;

 function CMD_Execute(var Params :TParams) :Longint;
 function CMD_Execute_Query :Longint;

implementation

uses Engine, Lang;

var
 Command :AnsiString;
 CParams :AnsiString;

function CMD_Execute(var Params :TParams) :Longint;
var
 X :Longint;
begin
 if CheckConnectionAndAuthorization = False then
  Exit(CMD_Fail);

 if Length(Params) < 2 then
 begin
  Writeln(OutPut, MultiLanguageSupport.GetString('UsingExecute'));
  Exit(CMD_Fail);
 end;
 
 Command := Params[1];
 CParams := '';
 if Length(Params) > 2 then
 begin
  For X := 2 to Length(Params) - 1 do
   CParams := CParams + Params[X] + ' ';
  if CParams[Length(CParams)]  = ' ' then
   SetLength(CParams, Length(CParams) - 1);
 end;
 
 Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgWaitForResponse'));
 LainClientSendQuery(Lain_Execute);
 RTLEventWaitFor(ConsoleEvent);
 RTLEventResetEvent(ConsoleEvent);
 Result := CMD_Done;
end;

function CMD_Execute_Query :Longint;
begin
 Connection.SendString(Command);
 Connection.SendString(CParams);
 EnterCriticalSection(CriticalSection);
 Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgCommandExecuted'));
 RTLEventSetEvent(ConsoleEvent);
 LeaveCriticalSection(CriticalSection);
 Result := CMD_Done;
end;

end.

