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

{$ifdef unix}
 type
  TLainClientQueryLoopThread = class(TThread)
  protected
   procedure Execute; override;
  public
   constructor Create;
  end;
{$endif}

 function LainClientSendQuery(ID :Word) :Longint;
 function LainClientQueryLoop :Longint;

implementation

uses Main;

{$ifdef unix}
 constructor TLainClientQueryLoopThread.Create;
 begin
  inherited Create(False);
  FreeOnTerminate := True; //
 end;
 
 procedure TLainClientQueryLoopThread.Execute;
 begin
  LainClientQueryLoop;
 end;
{$endif}


function LainClientSendQuery(ID :Word) :Longint;
var
 Query :Word;
begin
 if Connection.Connected = True then
 begin
  Query := ID;
  RTLEventWaitFor(QueryEvent);
  if Connection.Send(Query, SizeOf(Query)) = SizeOf(Query) then
   RTLEventResetEvent(QueryEvent) else
   Exit(SendQueryFail);
  Result := SendQueryDone;
 end else
  Result := SendQueryFail;
end;

function LainClientQueryLoop :Longint;
var
 Value :Word;
begin
 while Connection.Recv(Value, SizeOf(Value)) = SizeOf(Value) do
 begin
  Case Value of
   0: Break;
   1: Break;
  end;
  RTLEventSetEvent(QueryEvent);
 end;
end;



initialization
begin
 QueryEvent := RTLEventCreate;
 RTLEventSetEvent(QueryEvent);
end;
 
finalization
 RTLEventDestroy(QueryEvent);

end.
