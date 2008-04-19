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

unit caddons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main;

 function CMD_Help(var Params :TParams) :Longint;
 function CMD_About(var Params :TParams) :Longint;
 function CMD_Login(var Params :TParams) :Longint;
 function CMD_Logout(var Params :TParams) :Longint;

implementation

uses CEngine, Extensions, Authorize, Lang;

function CMD_About(var Params :TParams) :Longint;
begin
 Writeln('  ', MultiLanguageSupport.GetString('MainProgramer'));
 Writeln;
 Writeln('  ', MultiLanguageSupport.GetString('EnLang'));
 Writeln('  ', MultiLanguageSupport.GetString('PlLang'));
 Writeln;
 Result := CMD_Done;
end;

function CMD_Help(var Params :TParams) :Longint;
var
 X :Byte;
begin
 for X := Low(HelpList) to High(HelpList) do
 begin
  Write('  ', HelpList[X][0], ' -   ');
  Writeln(HelpList[X][1]);
 end;
 Writeln;
 Result := 0;
end;

function CMD_Logout(var Params :TParams) :Longint;
var
 CMD_Value :Word;
begin
 if ((LainClientData.Authorized = True) and (Connection.Connected = True)) then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgLogoff'));
  CMD_Value := Lain_Logoff;
  if Connection.Send(CMD_Value, SizeOf(CMD_Value)) <> SizeOf(CMD_Value) then
  begin
   Writeln(Prefix, MultiLanguageSupport.GetString('MsgCantLogoff'));
   Connection.Disconnect;
   LainClientData.Authorized := False;
   Exit(CMD_Fail);
  end else
   LainClientData.Authorized := False;
  Writeln;
  Result := CMD_Done;
 end else
  Exit(CMD_Fail);
end;

function CMD_Login(var Params :TParams) :Longint;
var
 X :Longint;
begin
 CMD_Logout(Params);
 Write(Prefix, MultiLanguageSupport.GetString('MsgSetUsername') + ' '); LainClientData.Username := Extensions.GetText;
 if LainClientData.Username = '' then
  Writeln(MultiLanguageSupport.GetString('FieldEmpty')) else
  Writeln;
 Write(Prefix, MultiLanguageSupport.GetString('MsgSetPassword') + ' '); LainClientData.Password := GetPasswd('*');
 if LainClientData.Password = '' then
  Writeln(MultiLanguageSupport.GetString('FieldEmpty')) else
  Writeln;

 if (Length(LainClientData.Username) > SizeOf(UserIdent.Username)) then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgLongUsername'));
  Writeln;
  Exit(CMD_Fail);
 end;

 if (Length(LainClientData.Password) > SizeOf(UserIdent.Password)) then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgLongPassword'));
  Writeln;
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
  Writeln;
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgPreparAuthorize'));
  Result := OnAuthorize;
 end;
   
 Writeln;
 Exit;
end;

end.

