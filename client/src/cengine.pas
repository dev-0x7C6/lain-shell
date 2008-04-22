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


unit CEngine;

interface

uses Classes, SysUtils;

Const
 SendQueryDone = 0;
 SendQueryFail = 1;
 
 Lain_Error = -1;
 Lain_Disconnect = 0;
 Lain_Logoff = 1;
 
 
 
type
 TUserIdent = packed record
  Username :Array[0..63] of WideChar;
  Password :Array[0..63] of WideChar;
 end;

var
 QueryEvent :PRTLEvent;
 EngineEvent :PRTLEvent;

 procedure LainClientInitQueryEngine;
 procedure LainClientResetQueryEngine;
 procedure LainClientDoneQueryEngine(TimeOut :Longint);

 function LainClientSendQuery(ID :Word) :Longint;
 function LainClientQueryLoop :Longint;


implementation

uses Main;


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
