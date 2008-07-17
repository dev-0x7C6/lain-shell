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

unit Authorize;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils, MD5;

const
 AuthorizeSuccessful = 0;
 AuthorizeFailed = 1;
 
type
 TUserIdent = packed record
  Username :TMD5Digest;
  Password :TMD5Digest;
 end;

 
{$ifdef windows}
 function OnConnect(P :Pointer) :DWord; stdcall;
{$endif}
{$ifdef unix}
 function OnConnect(P :Pointer) :Longint;
{$endif}
 function FAuthorize(AConnection :TConnection) :Longint;

var
 ServerUserIdent :TUserIdent;

implementation

uses
 Main, Engine;


{$ifdef windows}
 function OnConnect(P :Pointer) :DWord; stdcall;
{$endif}
{$ifdef unix}
 function OnConnect(P :Pointer) :Longint;
{$endif}
var
 Index :^Longint;
 Item :TConnectionThread;
begin
 Index := P;
 EnterCriticalSection(CriticalSection);
 Item := CThreadList[Index^];
 LeaveCriticalSection(CriticalSection);
 
 Result := FAuthorize(Item.Connection);

 Dispose(Index);
 RTLEventSetEvent(Item.ThreadInfo.Event);
end;

function FAuthorize(AConnection :TConnection) :Longint;
var
 Connection :TTcpIpCustomConnection;
 ControlSum :Longword;
 Verfication :Boolean;
 UserIdent :TUserIdent;
 X, Y :Longint;
 Value :Word;
begin
 Connection := TTcpIpCustomConnection.Create;
 Connection.SetConnection(AConnection);
 ControlSum := $F8D6;
 Writeln(ControlSum);
 if Connection.Send(ControlSum, SizeOf(ControlSum)) = SizeOf(ControlSum) then
 repeat
  ControlSum := $0;
  if Connection.Recv(ControlSum, SizeOf(ControlSum)) <> SizeOf(ControlSum) then break;
  if ControlSum <> $F8D6 then
  begin
   Verfication := False;
   if Connection.Send(Verfication, SizeOf(Verfication)) <> SizeOf(Verfication) then break;
   Continue;
  end else
   Verfication := True;
   
  if Connection.Send(Verfication, SizeOf(Verfication)) <> SizeOf(Verfication) then break;
  if Connection.Recv(UserIdent, SizeOf(UserIdent)) <> SizeOf(UserIdent) then break;
  
  X :=  LainDBControlClass.CheckUserInLainDBByDigest(UserIdent.Username);
  Verfication := X <> -1;
  if Verfication = True then
  begin
   for Y := Low(TMD5Digest) to High(TMD5Digest) do
   begin
    Verfication := Verfication and (LainDBControlClass.AccountList[X].Password[Y] = UserIdent.Password[Y]);
    if Verfication = False then
     Break;
   end;
  end;

  if Connection.Send(Verfication, SizeOf(Verfication)) <> SizeOf(Verfication) then break;

  if Verfication then
  begin
   repeat
    if Connection.Recv(Value, SizeOf(Value)) <> SizeOf(Value) then
    begin
     Connection.Free;
     Exit(Lain_Error);
    end;
    
    if Connection.Send(Value, SizeOf(Value)) <> SizeOf(Value) then
    begin
     Connection.Free;
     Exit(Lain_Error);
    end;
    
    if Value = Lain_Disconnect then
    begin
     Connection.Free;
     Exit(Lain_Error);
    end;
    
    LainServerQueryEngine(Connection, Value);
   until Value =  Lain_Logoff;
  end;
  
 until ((Connection.Connected = False) or (TerminateApp = True));
 Result := Lain_OK;
 Connection.Free;
end;

initialization
begin
 FillChar(ServerUserIdent, SizeOf(ServerUserIdent), 0);
end;

//finalization
//begin
//end;

end.

