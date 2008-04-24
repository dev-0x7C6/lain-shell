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


unit Engine;

interface

uses Classes, SysUtils, Main;

Const
 SendQueryDone = 0;
 SendQueryFail = 1;
 
 Lain_Error = -1;
 Lain_Disconnect = 0;
 Lain_Logoff = 1;
 
var
 QueryEvent :PRTLEvent;
 EngineEvent :PRTLEvent;

 function CMD_Login(var Params :TParams) :Longint;
 function CMD_Logout(var Params :TParams) :Longint;
 
 function OnAuthorize :Longint;

 procedure LainClientInitQueryEngine;
 procedure LainClientResetQueryEngine;
 procedure LainClientDoneQueryEngine(TimeOut :Longint);

 function LainClientSendQuery(ID :Word) :Longint;
 function LainClientQueryLoop :Longint;


implementation

uses Extensions, Lang, Threads;

function CMD_Logout(var Params :TParams) :Longint;
begin
 if ((LainClientData.Authorized = True) and (Connection.Connected = True)) then
 begin
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgLogoff'));
  if  LainClientSendQuery(Lain_Logoff) = SendQueryFail then
  begin
   Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgCantLogoff'));
   Connection.Disconnect;
   LainClientData.Authorized := False;
   Exit(CMD_Fail);
  end else
   LainClientData.Authorized := False;
  Result := CMD_Done;
 end else
  Exit(CMD_Fail);
end;

function CMD_Login(var Params :TParams) :Longint;
var
 X :Longint;
begin
 CMD_Logout(Params);
 Write(OutPut, Prefix, MultiLanguageSupport.GetString('MsgSetUsername') + ' '); LainClientData.Username := Extensions.GetText;
 if LainClientData.Username = '' then
  Writeln(OutPut, MultiLanguageSupport.GetString('FieldEmpty')) else
  Writeln(OutPut);
 Write(OutPut, Prefix, MultiLanguageSupport.GetString('MsgSetPassword') + ' '); LainClientData.Password := GetPasswd('*');
 if LainClientData.Password = '' then
  Writeln(OutPut, MultiLanguageSupport.GetString('FieldEmpty')) else
  Writeln(OutPut);

 if (Length(LainClientData.Username) > SizeOf(UserIdent.Username)) then
 begin
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgLongUsername'));
  Exit(CMD_Fail);
 end;

 if (Length(LainClientData.Password) > SizeOf(UserIdent.Password)) then
 begin
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgLongPassword'));
  Exit(CMD_Fail);
 end;

 UserIdent.Username := LainClientData.Username;
 UserIdent.Password := LainClientData.Password;

 for X := Low(UserIdent.Username) to High(UserIdent.Username) do
  UserIdent.Username[X] := Chr(Ord(UserIdent.Username[X]) xor 127);

 for X := Low(UserIdent.Password) to High(UserIdent.Password) do
  UserIdent.Password[X] := Chr(Ord(UserIdent.Password[X]) xor 127);

 if LainClientData.Username = '' then
  ConsoleUser := MultiLanguageSupport.GetString('FieldUsername') else
  ConsoleUser := LainClientData.Username;

 if Connection.Connected = True then
 begin
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgPreparAuthorize'));
  Result := OnAuthorize;
 end;

 Exit;
end;

var
{$ifdef unix}
UnixThread :TUnixThread;
{$endif}
{$ifdef windows}
WindowsThread :TWindowsThread;
{$endif}

{$ifdef unix}
function UnixLainClientQueryLoopBind(P :Pointer) :Longint;
begin
 LainClientQueryLoop;
end;
{$endif}

{$ifdef windows}
function WindowsLainClientQueryLoopBind(P :Pointer) :Longint; stdcall;
begin
 LainClientQueryLoop;
end;
{$endif}

function OnAuthorize :Longint;
var
 ControlSum :Longword;
 Verfication :Byte;

 procedure OnExit;
 begin
  writeln(Prefix, MultiLanguageSupport.GetString('MsgCantAuthorize'));
 end;

begin
 ControlSum := $F8D6;
 if Connection.Send(ControlSum, SizeOf(ControlSum)) = SizeOf(ControlSum) then
 if Connection.Recv(Verfication, SizeOf(Verfication)) = SizeOf(Verfication) then
 if Verfication = Byte(True) then
 begin
  if Connection.Send(UserIdent, SizeOf(UserIdent)) = SizeOf(UserIdent) then
  if Connection.Recv(Verfication, SizeOf(Verfication)) = SizeOf(Verfication) then
  if Verfication = Byte(True) then
  begin
   LainClientData.Authorized := True;
   Writeln(Prefix, MultiLanguageSupport.GetString('MsgAuthorized'));
   LainClientResetQueryEngine;
  {$ifdef unix}
   UnixThread := TUnixThread.Create(@UnixLainClientQueryLoopBind, nil);
   UnixThread.CreateThread;
   UnixThread.Free;
  {$endif}
  {$ifdef windows}
   WindowsThread := TWindowsThread.Create(@WindowsLainClientQueryLoopBind, nil);
   WindowsThread.CreateThread;
   WindowsThread.Free;
  {$endif}
   Exit(CMD_Done);
  end else
  begin
   LainClientData.Authorized := False;
   OnExit;
   Exit(CMD_Fail);
  end;
 end;

 OnExit;
 Exit(CMD_Fail);
end;

function LainClientSendQuery(ID :Word) :Longint;
var
 Query :Word;
begin
 if Connection.Connected = True then
 begin
  Query := ID;
  RTLEventWaitFor(QueryEvent);
  if Connection.Send(Query, SizeOf(Query)) = SizeOf(Query) then
  begin
   RTLEventResetEvent(QueryEvent);
   Exit(SendQueryDone);
  end else
   Exit(SendQueryFail);
 end else
  Result := SendQueryFail;
end;

function LainClientQueryLoop :Longint;
var
 Value :Word;
begin
 RTLEventResetEvent(EngineEvent);
 while Connection.Recv(Value, SizeOf(Value)) = SizeOf(Value) do
 begin
  Case Value of
   0: begin
       Connection.Disconnect;
       Break;
      end;
   1: Break;
  end;
  RTLEventSetEvent(QueryEvent);
 end;
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
end;

procedure LainClientInitQueryEngine;
begin
 QueryEvent := RTLEventCreate;
 EngineEvent := RTLEventCreate;
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
end;

procedure LainClientResetQueryEngine;
begin
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
end;

procedure LainClientDoneQueryEngine(TimeOut :Longint);
begin
 RTLEventDestroy(QueryEvent);
 RTLEventWaitFor(EngineEvent, TimeOut);
 RTLEventDestroy(EngineEvent);
end;

end.
