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
 ConsoleTitle :WideString = 'LainShell Client v0.00.50.0';
 Prefix = ' >>> ';
 
Const
 CMD_Done = 0;
 CMD_Fail = 1;
 
var
 Variables :WideString = 'Lang';

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
 OutPut :Text;

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
 Writeln(OutPut, ParamStr(0));
 TextColor(White);
 Writeln(OutPut, format(MultiLanguageSupport.GetString('MsgWelcome'), [ConsoleTitle]));
 TextColor(LightGray);
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
  Writeln(OutPut);
  repeat
   TextColor(LightGreen); Write(OutPut, ConsoleUser, '@', ConsoleHost);
   TextColor(LightBlue); Write(OutPut, ' ~ # ');
   TextColor(White);
   Cmd := Extensions.GetTextln;
   TextColor(LightGray);
   CmdToParams(Cmd, Params);
   if (LowerCase(Cmd) <> 'exit') and (LowerCase(Cmd) <> 'quit') and
      (LowerCase(Cmd) <> '')  then
   begin
    CMDCase(Params);
    if Length(Cmd) <> 0 then Writeln(OutPut);
   end;
   SetLength(Params, 0);
  until ((LowerCase(Cmd) = 'exit') or (LowerCase(Cmd) = 'quit'));
  SetLength(Params, 0);
  Result := CMD_Done;
  writeln(OutPut);
 end;

end;

function CMDSetCase(var Params :TParams) :Longint; forward;

function CMDCase(var Params :TParams) :Longint;
var
 Cmd :WideString;
begin
 if Length(Params) <= 0 then Exit(CMD_Fail);
 Cmd := LowerCase(Params[0]);
 
 if (Cmd = 'about') then Exit(CMD_About(Params));
 if (CMD = 'clear') then Exit(CMD_Clear(Params));
 if (Cmd = 'connect') then Exit(CMD_Connect(Params));
 if (Cmd = 'disconnect') then Exit(CMD_Disconnect(Params));
 if (Cmd = 'help') then Exit(CMD_Help(Params));
 if (Cmd = 'login') then Exit(CMD_Login(Params));
 if (Cmd = 'logout') then Exit(CMD_Logout(Params));
 if (Cmd = 'rconnect') then Exit(CMD_RCConnect(Params));
 if (Cmd = 'set') then Exit(CMDSetCase(Params));
 if (Cmd = 'status') then Exit(CMD_Status(Params));
 
 if Length(Params[0]) > 0 then
 begin
  Writeln(OutPut, Prefix, format(MultiLanguageSupport.GetString('MsgCmdNotFound'), [Params[0]]));
 end;
end;

function CMDSetCase(var Params :TParams) :Longint;
var
 Cmd :WideString;
begin
 if Length(Params) < 2 then
 begin
  Writeln(OutPut, Format(MultiLanguageSupport.GetString('UsingSet'), [Variables]));
  Exit(CMD_Fail);
 end;
 Cmd := LowerCase(Params[1]);
 if (Cmd = 'lang') then Exit(CMD_SetLang(Params));
{$ifdef windows}
 if (Cmd = 'codepage') then Exit(CMD_SetConsoleCodePage(Params));
{$endif}
 Writeln(OutPut, Format(MultiLanguageSupport.GetString('MsgSetVariableUnknown'), [Cmd]));
end;
 
var
 X :Longint;
 
initialization
begin
{$ifdef windows}
 Variables := Variables + '\CodePage';
{$endif}
 AssignCrt(OutPut);
 ReWrite(OutPut);
 STDOutPut := OutPut;
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
 CloseFile(OutPut);
end;

end.

