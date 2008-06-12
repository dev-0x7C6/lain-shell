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

program LainServer;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  CThreads, IPC, BaseUnix, Unix, UnixUtils, Signals,
{$endif}
{$ifdef windows}
  Windows, Registry, ShellApi,
{$endif}
  Main, SysUtils, Authorize, Engine, Sockets, Config, Execute, Sysinfo, Process,
  LainDataBase, Params, Diskmgr, ConvNum, FSUtils, NetUtils, Loop, Consts,
  ShareMem;

var
 Reconfigure :Boolean;


function MainProc :Longint;
var
 X :Longint;
{$ifdef unix}
 Dump :Longint;
{$endif}
{$ifdef windows}
 RegEdit :TRegistry;
{$endif}
begin
{$ifdef windows}
 RegEdit := TRegistry.Create;
 RegEdit.RootKey := HKEY_CURRENT_USER;
 RegEdit.OpenKey(RegistryKey, true);
 if not RegEdit.ValueExists('IsConfigured') then
  Reconfigure := True;
 RegEdit.Free;

 if Reconfigure = True then
 begin
  ConfigFile := TConfigFile.Create;
  ConfigFile.GenerateConfig;
  ConfigFile.SaveConfig(ConfigFileName);
  ConfigFile.Free;
  RegEdit := TRegistry.Create;
  RegEdit.RootKey := HKEY_CURRENT_USER;
  RegEdit.OpenKey(RegistryKey, true);
  RegEdit.WriteInteger('IsConfigured', 0);
  RegEdit.Free;
  ShellExecuteA(GetForegroundWindow, 'open', 'notepad.exe', Pchar(ConfigFileName), '', SW_SHOW);
  Exit;
 end;
 
 if FileExists(ConfigFileName) then
 begin
  ConfigFile := TConfigFile.Create;
  ConfigFile.OpenConfig(ConfigFileName);
  for X := 0 to ConfigVariablesCount do
   DefaultConfigVariables[X][1] := ConfigFile.GetString(DefaultConfigVariables[X][0]);
  ConfigFile.Free;
  DeleteFile(PChar(ConfigFileName));
  RegEdit := TRegistry.Create;
  RegEdit.RootKey := Windows.HKEY_CURRENT_USER;
  RegEdit.OpenKey('Software\LainShell', True);
  for X := 0 to ConfigVariablesCount do
   RegEdit.WriteString(DefaultConfigVariables[X][0], DefaultConfigVariables[X][1]);
  RegEdit.Free;
 end;

 RegEdit := TRegistry.Create;
 RegEdit.RootKey := Windows.HKEY_CURRENT_USER;
 RegEdit.OpenKey('Software\LainShell', True);
 for X := 0 to ConfigVariablesCount do
  DefaultConfigVariables[X][1] := RegEdit.ReadString(DefaultConfigVariables[X][0]);
 RegEdit.Free;
{$endif}



 LainShellDataConfigure;
{$ifdef unix}
 if UnixMainLoopInit then
 begin
  InitConnections(ClientConnection, ServerConnection);
  UnixMainLoop(@TerminateApp, Dump);
  DoneConnections(CThreadList, ClientConnection, ServerConnection);
  UnixMainLoopDone;
 end else
  Writeln('Can''t create shared memory, try with param --restart');
{$endif}

{$ifdef windows}
 if WindowsMainLoopInit = true then
 begin
  InitConnections(ClientConnection, ServerConnection);
  WindowsMainLoop;
  DoneConnections(CThreadList, ClientConnection, ServerConnection);
  WindowsMainLoopDone;
 end;
{$endif}

end;


var
 FirstParametr :String;
 X :Longint;
{$ifdef unix}
 LainDirectory :String;
{$endif}

procedure Exit_LainShellServer;
begin
{$ifdef unix}
 LainDBControlClass.SaveLainDBToFile(LainDirectory + DataBaseFileName);
 Writeln(EndLineChar);
{$endif}
{$ifdef windows}
 LainDBControlClass.SaveLainDBToRegistry(RegistryKey, RegistryValue);
{$endif}
 LainDBControlClass.Free;
 DoneCriticalSection(CriticalSection);
end;

begin
 InitCriticalSection(CriticalSection);
 LainDBControlClass := TLainDBControlClass.Create;
 System.AddExitProc(@Exit_LainShellServer);
 
{$ifdef unix}
 LainDirectory := IsDir(GetHomeDirectory + ConfigDirectory);
 if not CreateConfigDirectory(LainDirectory) then Exit;
 LoadLainDataBaseFromSystem(LainDBControlClass, LainDirectory + DataBaseFileName);
{$endif}
{$ifdef windows}
 LoadLainDataBaseFromSystem(LainDBControlClass, '');
{$endif}
 FirstParametr := LowerCase(ParamStr(1));

 Reconfigure := False;
 if FirstParametr = '--config' then Reconfigure := True else
 if FirstParametr = '--help' then LainServerParamHelp else
{$ifdef unix}
 if FirstParametr = '--stop' then LainServerParamStop else
{$endif}
{$ifdef windows}
 if FirstParametr = '--stop' then begin
  if not CheckForCopy(FirstParametr) then Exit;
 end else
{$endif}
 if FirstParametr = '--adduser' then LainServerParamAddUser else
 if FirstParametr = '--deluser' then LainServerParamDelUser else
 if FirstParametr = '--chkuser' then LainServerParamChkUser else
 if FirstParametr = '--lstuser' then LainServerParamLstUser else
 if FirstParametr = '--pwduser' then LainServerParamPwdUser else
 if FirstParametr = '--createdb' then LainServerParamCreateDB else
 begin
  if FirstParametr <> '' then
  begin
  {$ifdef unix}
   Writeln('Unknown parametr: ''', FirstParametr, '''');
   Writeln;
  {$endif}
   LainServerParamHelp;
   Exit;
  end;
 end;

{$ifdef unix}
 Reconfigure := not FileExists(LainDirectory + ConfigFileName) or Reconfigure;
 if Reconfigure = True then
 begin
  ConfigFile := TConfigFile.Create;
  ConfigFile.GenerateConfig;
  ConfigFile.SaveConfig(LainDirectory + ConfigFileName);
  ConfigFile.Free;
  Writeln('Please config this file ' + LainDirectory + ConfigFileName, EndLineChar);
  Exit;
 end;
 ConfigFile := TConfigFile.Create;
 ConfigFile.OpenConfig(ConfigFileName);
 for X := 0 to ConfigVariablesCount do
  DefaultConfigVariables[X][1] := ConfigFile.GetString(DefaultConfigVariables[X][0]);
 ConfigFile.Free;
{$endif}

 if FirstParametr <> '' then Exit;

 if Length(LainDBControlClass.AccountList) = 0 then
 begin
 {$ifdef unix}
  Writeln(MsgDBNoUsers);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgDBNoUsers), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;

 MainProc;
 
end.


