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

unit Main;

{$mode objfpc}{$H+}

interface

uses
 {$ifdef windows}
  Windows,
 {$endif} Classes, SysUtils, NetUtils, Crt;


Const
 ConsoleTitle :WideString = 'LainShell Client v0.00.40.9';
 Prefix = ' >>> ';
 
Const
 CMD_Done = 0;
 CMD_Fail = 1;

type
 TUserIdent = packed record
  Username :Array[0..63] of WideChar;
  Password :Array[0..63] of WideChar;
 end;

 
type
 TParams = Array of WideString;
 
type
 TLainClientData = packed record
  Authorized :Boolean;
  Hostname :WideString;
  Port :WideString;
  Username :WideString;
  Password :WideString;
 end;
 
 function CMDCase(var Params :TParams) :Longint;
 function MainFunc :Longint;
 procedure PaintConsoleTitle;


var
 Connection :TTcpIpCustomConnection;
 ConsoleHost :WideString = '';
 ConsoleUser :WideString = '';
 CriticalSection :TRTLCriticalSection;
 LainClientData :TLainClientData;
 Params :TParams;
 UserIdent :TUserIdent;


implementation

uses Addons, Engine, Extensions, Lang, Network;

procedure PaintConsoleTitle;
begin
 Writeln(ParamStr(0));
 TextColor(White);
 Writeln(format(MultiLanguageSupport.GetString('MsgWelcome'), [ConsoleTitle]));
 TextColor(LightGray);
 Writeln;
end;

function MainFunc :Longint;
var
 Cmd :WideString;
begin
{$ifdef windows}
 Windows.SetConsoleTitle(PChar(String(ConsoleTitle)));
{$endif}
 ClrScr;
 if AnyLanguageSupport then
 begin
  PaintConsoleTitle;
  repeat
   TextColor(LightGreen); Write(ConsoleUser, '@', ConsoleHost);
   TextColor(LightBlue); Write(' ~ # ');
   TextColor(White);
   Cmd := Extensions.GetTextln;
   TextColor(LightGray);
   CmdToParams(Cmd, Params);
   if (LowerCase(Cmd) <> 'exit') and (LowerCase(Cmd) <> 'quit') and
      (LowerCase(Cmd) <> '')  then CMDCase(Params);
   SetLength(Params, 0);
  until ((LowerCase(Cmd) = 'exit') or (LowerCase(Cmd) = 'quit'));
  SetLength(Params, 0);
  Result := CMD_Done;
  writeln;
 end;

end;

function CMDSetCase(var Params :TParams) :Longint; forward;

function CMDCase(var Params :TParams) :Longint;
var
 Cmd :WideString;
begin
 if Length(Params) <= 0 then Exit(CMD_Fail);
 Cmd := LowerCase(Params[0]);
 
 if (Cmd = 'about') then Exit(CMD_About(Params)); // CAddons
 if (CMD = 'clear') then Exit(CMD_Clear(Params)); // CAddons
 if (Cmd = 'connect') then Exit(CMD_Connect(Params)); // CNetwork
 if (Cmd = 'disconnect') then Exit(CMD_Disconnect(Params)); // CNetwork
 if (Cmd = 'help') then Exit(CMD_Help(Params)); // CAddons
 if (Cmd = 'login') then Exit(CMD_Login(Params)); // CAddons
 if (Cmd = 'logout') then Exit(CMD_Logout(Params)); // CAddons
 if (Cmd = 'rconnect') then Exit(CMD_RCConnect(Params)); // CNetwork
 if (Cmd = 'set') then Exit(CMDSetCase(Params)); // Main
 if (Cmd = 'status') then Exit(CMD_Status(Params)); // CAddons
 
 if Length(Params[0]) > 0 then
 begin
  Writeln(Prefix, format(MultiLanguageSupport.GetString('MsgCmdNotFound'), [Params[0]]));
  Writeln;
 end;
end;

function CMDSetCase(var Params :TParams) :Longint;
var
 Cmd :WideString;
begin
 if Length(Params) < 2 then
 begin
  Writeln(MultiLanguageSupport.GetString('MsgCmdSetUsing'));
  Writeln;
  Exit(CMD_Fail);
 end;
 Cmd := LowerCase(Params[1]);
 if (Cmd = 'lang') then Exit(CMD_SetLang(Params));
{$ifdef windows}
 if (Cmd = 'codepage') then Exit(CMD_SetConsoleCodePage(Params));
{$endif}
 Writeln(Format(MultiLanguageSupport.GetString('MsgCmdSetUnknownVariable'), [Cmd]));
 Writeln;
end;
 
var
 X :Longint;
 
initialization
begin
 Crt.AssignCrt(NetUtils.STDOutPut);
 ReWrite(NetUtils.STDOutPut);
 LainClientInitQueryEngine;
 InitCriticalSection(CriticalSection);
 Connection := TTcpIpCustomConnection.Create;
 FillChar(UserIdent, SizeOf(UserIdent), 0);
 LainClientData.Authorized := False;
 LainClientData.Username := '';
 LainClientData.Password := '';
 LainClientData.Hostname := '';
 LainClientData.Port := '';
 
 for X := Low(UserIdent.Username) to High(UserIdent.Username) do
  UserIdent.Username[X] := Chr(Ord(UserIdent.Username[X]) xor 127);

 for X := Low(UserIdent.Password) to High(UserIdent.Password) do
  UserIdent.Password[X] := Chr(Ord(UserIdent.Password[X]) xor 127);
end;

finalization
begin
 Connection.Disconnect;
 Connection.Free;
 LainClientDoneQueryEngine(10000);
 DoneCriticalSection(CriticalSection);
 CloseFile(NetUtils.STDOutPut);
end;

end.

