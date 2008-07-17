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
 AuthTable :Array[0..15] of Byte =   ($d5, $8b, $6a, $97, $c4, $3e, $c5, $59, $2f,
                                      $0b, $c0, $33, $c7, $2e, $d5, $13);
 AcceptTable :Array[0..15] of Byte = ($4a, $be, $77, $c2, $01, $ff, $11, $66, $3c,
                                      $cd, $f5, $2f, $d6, $ec, $ea, $86);
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
 AuthBuffer :Array[0..15] of Byte;
 ControlSum :Longword;
 Verfication :Boolean;
 UserIdent :TUserIdent;
 X, Y :Longint;
 Value :Word;
begin
 Connection := TTcpIpCustomConnection.Create;
 Connection.SetConnection(AConnection);
 if Connection.Recv(AuthBuffer, SizeOf(AuthBuffer)) = SizeOf(AuthBuffer) then
 begin
  Verfication := True;
  for X := Low(AuthTable) to High(AuthTable) do
   if AuthTable[X] = AuthBuffer[X] then
    Verfication := Verfication and True else
    Verfication := Verfication and False;
    
  FillChar(AuthBuffer, SizeOf(AuthBuffer), 0);
  if Verfication = True then
   for X := Low(AcceptTable) to High(AcceptTable) do  AuthBuffer[X] := AcceptTable[X];
   
  if ((Connection.Send(AuthBuffer, SizeOf(AuthBuffer)) = SizeOf(AuthBuffer)) and (Verfication = True)) then
   repeat

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

    if not Verfication then Continue;

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
    
  until ((Connection.Connected = False) or (TerminateApp = True));
 end;
 Result := Lain_OK;
 Connection.Free;
end;

initialization
begin
 FillChar(ServerUserIdent, SizeOf(ServerUserIdent), 0);
end;

end.

