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
 {$endif} Classes, SysUtils, NetUtils, Md5;


Const
 ConsoleHost :WideString = '';
 ConsoleUser :WideString = '';
 EndLineChar = #13;

Const
 ConsoleTitle :WideString = 'LainShell Client v0.00.70.0';
 Prefix = ' >>> ';
 
Const
 CMD_Done = 0;
 CMD_Fail = 1;
 
var
 Variables :WideString = 'Lang';

type
 TUserIdent = packed record
  Username :TMD5Digest;
  Password :TMD5Digest;
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
 
 procedure DrawConsoleTitle;
 procedure DrawCommandPath;

var
 Connection :TTcpIpCustomConnection;

 CriticalSection :TRTLCriticalSection;
 LainClientData :TLainClientData;
 Params :TParams;
 UserIdent :TUserIdent;

 function CheckConnectionAndAuthorization :Boolean;

implementation

uses Addons, Engine, Execute, Extensions, Lang, Network, Process, SysInfo, Users;

function CheckConnectionAndAuthorization :Boolean;
begin
 if ((Connection.Connected = False) or (LainClientData.Authorized = False)) then
 begin
  if ((LainClientData.Authorized = False) and (Connection.Connected = False)) then
  begin
   Writeln(MultiLanguageSupport.GetString('MsgNotConnectedAndAuthorized'), EndLineChar);
   Exit(False);
  end else
   begin
    if Connection.Connected = False then
     Writeln(MultiLanguageSupport.GetString('MsgNotConnected'), EndLineChar);
    if LainClientData.Authorized = False then
     Writeln(MultiLanguageSupport.GetString('MsgNotAuthorized'), EndLineChar);
    Exit(False);
   end;
  Result := True;
 end;
end;

procedure DrawConsoleTitle;
begin
 CClrScr(OutPut);
 Writeln(ParamStr(0), EndLineChar);
 Extensions.CWrite(Output, White, format(MultiLanguageSupport.GetString('MsgWelcome') + EndLineChar, [ConsoleTitle]), True);
end;

procedure DrawCommandPath;
begin
 CWrite(OutPut, LightGreen, ConsoleUser + '@' + ConsoleHost, False);
 CWrite(OutPut, LightBlue, ' ~ # ', False);
end;

function MainFunc :Longint;
var
 Cmd :WideString;
begin
{$ifdef windows}
 Windows.SetConsoleTitle(PChar(String(ConsoleTitle)));
{$endif}
 CClrScr(OutPut);
 if AnyLanguageSupport then
 begin
  DrawConsoleTitle;
  Writeln(OutPut);
  repeat
   DrawCommandPath;
   Cmd := Extensions.GetTextln;
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
 if (Cmd = 'clear') then Exit(CMD_Clear(Params));
 if (Cmd = 'connect') then Exit(CMD_Connect(Params));
 if (Cmd = 'disconnect') then Exit(CMD_Disconnect(Params));
 if (Cmd = 'execute') then Exit(CMD_Execute(Params));
 if (Cmd = 'help') then Exit(CMD_Help(Params));
 if (Cmd = 'login') then Exit(CMD_Login(Params));
 if (Cmd = 'logout') then Exit(CMD_Logout(Params));
 if (Cmd = 'processlist') then Exit(CMD_ProcessList(Params));
 if (Cmd = 'rconnect') then Exit(CMD_RCConnect(Params));
 if (Cmd = 'set') then Exit(CMDSetCase(Params));
 if (Cmd = 'status') then Exit(CMD_Status(Params));
 if (Cmd = 'sysinfo') then Exit(CMD_SysInfo(Params));
 if (Cmd = 'users') then Exit(CMD_UsersCase(Params));
 
 if Length(Params[0]) > 0 then
 begin
  Writeln(Prefix, format(MultiLanguageSupport.GetString('MsgCmdNotFound'), [Params[0]]), EndLineChar);
 end;
end;

function CMDSetCase(var Params :TParams) :Longint;
var
 Cmd :WideString;
begin
 if Length(Params) < 2 then
 begin
  Writeln(Format(MultiLanguageSupport.GetString('UsingSet'), [Variables]), EndLineChar);
  Exit(CMD_Fail);
 end;
 Cmd := LowerCase(Params[1]);
 if (Cmd = 'lang') then Exit(CMD_SetLang(Params));
{$ifdef windows}
 if (Cmd = 'codepage') then Exit(CMD_SetConsoleCodePage(Params));
{$endif}
 Writeln(Format(MultiLanguageSupport.GetString('MsgSetVariableUnknown'), [Cmd]), EndLineChar);
end;


end.

