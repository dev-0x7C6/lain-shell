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

unit auth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 
  
 function Auth :Longint;
 
 function AuthLogin(const Username, Password :AnsiString) :Boolean;
 function AuthLExit :Boolean;
 
implementation

uses Main, MD5, Engine, nLang, Threads;

function AuthLogin(const Username, Password :AnsiString) :Boolean;
var
 X :Longint;
begin
 if Connection.Connected = True then
 begin
  LainClientData.Username := Username;
  LainClientData.Password := Password;

  UserIdent.Username := MD5String(LainClientData.Username);
  UserIdent.Password := MD5String(LainClientData.Password);

  if LainClientData.Username = '' then
   ConsoleUser := MultiLanguageSupport.GetString('FieldUsername') else
   ConsoleUser := LainClientData.Username;
  Result := (Auth = CMD_Done);
 end;
end;


function AuthLExit :Boolean;
begin
 if ((LainClientData.Authorized = True) and (Connection.Connected = True)) then
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgLogoff'), EndLineChar);
  if  LainClientSendQuery(Lain_Logoff) = SendQueryFail then
  begin
   Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgCantLogoff'), EndLineChar);
   Connection.Disconnect;
   LainClientData.Authorized := False;
   Exit(False);
  end else
   LainClientData.Authorized := False;
  LainClientWaitForQuery;
  Result := True;
 end else
  Result := True;
end;

function Auth :Longint;
var
{$ifdef unix}
 UnixThread :TUnixThread;
{$endif}
{$ifdef windows}
 WindowsThread :TWindowsThread;
{$endif}
 ControlSum :Longword;
 Verfication :Byte;
begin
 LainClientResetQueryEngine;
 if not Connection.Send(UserIdent, SizeOf(UserIdent)) = SizeOf(UserIdent) then Exit(CMD_Fail);
 if not Connection.Recv(Verfication, SizeOf(Verfication)) = SizeOf(Verfication) then Exit(CMD_Fail);

 if Verfication = Byte(True) then
 begin
  LainClientData.Authorized := True;
  Writeln(OutPut, Prefix_Out, MultiLanguageSupport.GetString('MsgAuthorized'), #13);
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
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgCantAuthorize'), #13);
  Exit(CMD_Fail);
 end;
 Result := CMD_Fail;
end;


end.

