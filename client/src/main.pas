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
 ConsoleTitle :WideString = 'LainShell Client v0.00.60.9';
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
 OutPut :Text;

var
 Connection :TTcpIpCustomConnection;
 ConsoleHost :WideString = '';
 ConsoleUser :WideString = '';
 CriticalSection :TRTLCriticalSection;
 LainClientData :TLainClientData;
 Params :TParams;
 UserIdent :TUserIdent;
 ConsoleEvent :PRTLEvent;

 function CheckConnectionAndAuthorization :Boolean;

implementation

uses Addons, Engine, Execute, Extensions, Lang, Network, Process, SysInfo;

function CheckConnectionAndAuthorization :Boolean;
begin
 if ((Connection.Connected = False) or (LainClientData.Authorized = False)) then
 begin
  if ((LainClientData.Authorized = False) and (Connection.Connected = False)) then
  begin
   Writeln(OutPut, MultiLanguageSupport.GetString('MsgNotConnectedAndAuthorized'));
   Exit(False);
  end else
   begin
    if Connection.Connected = False then
     Writeln(OutPut, MultiLanguageSupport.GetString('MsgNotConnected'));
    if LainClientData.Authorized = False then
     Writeln(OutPut, MultiLanguageSupport.GetString('MsgNotAuthorized'));
    Exit(False);
   end;
  Result := True;
 end;
end;

procedure DrawConsoleTitle;
begin
 CClrScr(OutPut);
 Writeln(OutPut, ParamStr(0));
 Extensions.CWrite(Output, White, format(MultiLanguageSupport.GetString('MsgWelcome'), [ConsoleTitle]), True);
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
   CWrite(OutPut, LightGreen, ConsoleUser + '@' + ConsoleHost, False);
   CWrite(OutPut, LightBlue, ' ~ # ', False);
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
 InitCriticalSection(CriticalSection);
 ConsoleEvent := RTLEventCreate;
 RTLEventResetEvent(ConsoleEvent);
{$ifdef windows}
 Variables := Variables + '\CodePage';
{$endif}
 AssignFile(OutPut, '');
 ReWrite(OutPut);
 STDOutPut := OutPut;
 LainClientInitQueryEngine;
 MultiLanguageSupport := nil;
 MultiLanguageInit;

 Connection := TTcpIpCustomConnection.Create;
 FillChar(UserIdent, SizeOf(UserIdent), 0);
 LainClientData.Authorized := False;
 LainClientData.Username := '';
 LainClientData.Password := '';
 LainClientData.Hostname := '';
 LainClientData.Port := '';
 UserIdent.Username := MD5String('');
 UserIdent.Password := MD5String('');
end;

finalization
begin
 RTLEventDestroy(ConsoleEvent);
 if LainClientData.Authorized = True then
  CMD_Logout(Params);
 if Connection.Connected = True then
  CMD_Disconnect(Params);
 LainClientDoneQueryEngine(10000);
 MultiLanguageSupport.Free;
 Connection.Free;
 Writeln(OutPut);
 CloseFile(OutPut);
 DoneCriticalSection(CriticalSection);
end;

end.

