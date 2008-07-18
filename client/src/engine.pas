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

uses Classes, SysUtils, Main, Md5;

Var
 ConnectionClosedGracefullyErrorShow :Boolean = True;

Const
 SendQueryDone = 0;
 SendQueryFail = 1;
 
 Lain_Error = -1;
 Lain_Disconnect = 0;
 Lain_Logoff = 1;
 
 procedure LainClientInitQueryEngine;
 procedure LainClientResetQueryEngine;
 procedure LainClientDoneQueryEngine(TimeOut :Longint);

 function LainClientSendQuery(ID :Word) :Longint;
 function LainClientQueryLoop :Longint;
 
 procedure LainClientWaitForQuery;
 procedure LainClientEngineInit;
 procedure LainClientEngineDone;

{$ifdef unix}
 function UnixLainClientQueryLoopBind(P :Pointer) :Longint;
{$endif}

{$ifdef windows}
 function WindowsLainClientQueryLoopBind(P :Pointer) :Longint; stdcall;
{$endif}

implementation

uses Execute, Extensions, NLang, Process, SysInfo, Threads, Users, auth;


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

var
 QueryEvent :PRTLEvent;
 EngineEvent :PRTLEvent;

procedure LainClientWaitForQuery;
begin
 RTLEventWaitFor(QueryEvent);
EnterCriticalSection(CriticalSection);
 RTLEventSetEvent(QueryEvent);
LeaveCriticalSection(CriticalSection);
end;


function LainClientSendQuery(ID :Word) :Longint;
var
 Query :Word;
begin
 if Connection.Connected = True then
 begin
  Query := ID;
  LainClientWaitForQuery;
 EnterCriticalSection(CriticalSection);
  RTLEventResetEvent(QueryEvent);
 LeaveCriticalSection(CriticalSection);
  if Connection.Send(Query, SizeOf(Query)) = SizeOf(Query) then
   Exit(SendQueryDone) else
   Exit(SendQueryFail);
 end else
  Result := SendQueryFail;
end;

procedure LainClientEngineInit;
begin
 LainClientResetQueryEngine;
EnterCriticalSection(CriticalSection);
 RTLEventResetEvent(EngineEvent);
 ConnectionClosedGracefullyErrorShow := True;
LeaveCriticalSection(CriticalSection);
end;

procedure LainClientEngineDone;
begin
EnterCriticalSection(CriticalSection);
 ConnectionClosedGracefullyErrorShow := False;
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
LeaveCriticalSection(CriticalSection);
end;


function LainClientQueryLoop :Longint;
var
 Value :Word;
begin
 LainClientEngineInit;
 repeat
  if Connection.Recv(Value, SizeOf(Value)) <> SizeOf(Value) then
  begin
   Connection.Disconnect;
   LainClientData.Authorized := False;
   EnterCriticalSection(CriticalSection);
   RTLEventSetEvent(QueryEvent);
   RTLEventSetEvent(EngineEvent);
   if ConnectionClosedGracefullyErrorShow then
   begin
    Writeln(OutPut, #13);
    Writeln(OutPut, Prefix_Out, 'Connection closed gracefully'#13);
    Writeln(OutPut, #13);
   end;
   DrawCommandPath;
   LeaveCriticalSection(CriticalSection);
   Exit;
  end;
  
  case Value of
   0: Connection.Disconnect;
   Lain_Execute: CMD_Execute_Query;
   Lain_SysInfo_GetInfo: CMD_SysInfo_Query;
   Lain_Process_GetList: CMD_ProcessList_Query;
/// USERS
   Lain_Users_CAddUser  :CMD_Users_AddUser_Query;
   Lain_Users_CDelUser  :CMD_Users_DelUser_Query;
   Lain_Users_CLstUser  :CMD_Users_LstUser_Query;
   Lain_Users_CCUser    :CMD_Users_CheckUser_Query;
   Lain_Users_CCUserPwd :CMD_Users_ChangeUserPwd_Query;
   
  end;
  EnterCriticalSection(CriticalSection);
  RTLEventSetEvent(QueryEvent);
  LeaveCriticalSection(CriticalSection);
 until ((Value = 0) or (Value = 1));
 LainClientEngineDone;
end;

procedure LainClientInitQueryEngine;
begin
EnterCriticalSection(CriticalSection);
 QueryEvent := RTLEventCreate;
 EngineEvent := RTLEventCreate;
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
LeaveCriticalSection(CriticalSection);
end;

procedure LainClientDoneQueryEngine(TimeOut :Longint);
begin
EnterCriticalSection(CriticalSection);
 RTLEventWaitFor(EngineEvent, TimeOut);
 RTLEventDestroy(EngineEvent);
 RTLEventDestroy(QueryEvent);
LeaveCriticalSection(CriticalSection);
end;

procedure LainClientResetQueryEngine;
begin
EnterCriticalSection(CriticalSection);
 RTLEventSetEvent(QueryEvent);
 RTLEventSetEvent(EngineEvent);
LeaveCriticalSection(CriticalSection);
end;

end.
