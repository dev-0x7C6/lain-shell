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
  Main, SysUtils, Authorize, Engine, Sockets, Config, Execute,
  Sysinfo, Process, LainDataBase, Params, diskmgr, convnum, FSUtils, NetUtils,
  loop, consts, sharemem;


Const
 MsgDBNoUsers :String = 'Please add user to database, run program with parametrs adduser <username> <password>';

Const
{$ifdef unix}
 ConfigFileName :AnsiString = 'lainconf.conf';
 ConfigDirectory :AnsiString = '.lainconf';
{$endif}
{$ifdef windows}
 ConfigFileName :AnsiString = 'lainconf.txt';
{$endif}

var
{$ifdef unix}
 Dump :LongInt;
 LainDirectory :AnsiString;
 ConfigExists :Boolean = False;
 NanoPath :WideString;
{$endif}
{$ifdef windows}
 SharedMemoryRec :TSharedMemoryRec;
 SharedMemoryCfg :TSharedMemoryCfg;
 WindowHandle :THandle;
 ShareMemory :THandle = 0;
 ExecuteBlock :THandle = 0;
 RestartBlock :THandle = 0;
 RegEdit :TRegistry;
{$endif}
 CreateConfig :Boolean = False;


function MainProc :Longint;
var
 X :Longint;
begin
{$ifdef windows}
 DefaultConfigForSharedMemory(SharedMemoryCfg);
 SharedMemoryCfg.IdentCharSet := 'lainshell-server-blocker';
 while LainCreateSharedMemory(SharedMemoryRec, SharedMemoryCfg) = False do
 begin
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
  begin
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);
  end;
 end;
 
 RegEdit := TRegistry.Create;
 RegEdit.RootKey := HKEY_CURRENT_USER;
 RegEdit.OpenKey('Software\LainShell', true);
 if not RegEdit.ValueExists('IsConfigured') then
  CreateConfig := True;
 RegEdit.Free;

 if CreateConfig = True then
 begin
  ConfigFile := TConfigFile.Create;
  ConfigFile.GenerateConfig;
  ConfigFile.SaveConfig(ConfigFileName);
  ConfigFile.Free;
  RegEdit := TRegistry.Create;
  RegEdit.RootKey := HKEY_CURRENT_USER;
  RegEdit.OpenKey('Software\LainShell', true);
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

 LainShellDataConfigure;
{$endif}


{$ifdef unix}
 if UnixMainLoopInit then
 begin
  InitConnections(ClientConnection, ServerConnection);
  UnixMainLoop(@TerminateApp, Dump);
  DoneConnections(CThreadList, ClientConnection, ServerConnection);
  UnixMainLoopDone;
 end;
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


function Main :Longint;
var
 X :Longint;
 Param :String;
begin
 if ParamCount > 0 then
  Param := LowerCase(ParamStr(1)) else
  Param := '';
  
{$ifdef unix}
 LainDirectory := IsDir(GetHomeDirectory + ConfigDirectory);
 if not CreateConfigDirectory(LainDirectory) then Exit;
 LoadLainDataBaseFromSystem(LainDBControlClass, LainDirectory + DataBaseFileName);
{$endif}
{$ifdef windows}
 LoadLainDataBaseFromSystem(LainDBControlClass, '');
{$endif}

 if Param = '--config' then
  CreateConfig := True else
  CreateConfig := False;
   
 if Param = '--help' then
 begin
  LainServerParamHelp;
  Exit;
 end;
 
 if Param = '--stop' then
 begin
  LainServerParamStop;
  Exit;
 end;
 
 if Param = '--adduser' then
 begin
  LainServerParamAddUser;
  Exit;
 end;
   
 if Param = '--deluser' then
 begin
  LainServerParamDelUser;
 end;
 
 if Param = '--chkuser' then
 begin
  LainServerParamChkUser;
  Exit;
 end;
 
 if Param = '--lstuser' then
 begin
  LainServerParamLstUser;
  Exit;
 end;
 
 if Param = '--pwduser' then
 begin
  LainServerParamPwdUser;
  Exit;
 end;
 
 if Param = '--createdb' then
 begin
  LainServerParamCreateDB;
  Exit;
 end;
 
{$ifdef windows}
 if ((Param = '--stop') or (Param = '--restart')) then
 begin
  ExecuteBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-block');
  if GetLastError = ERROR_ALREADY_EXISTS then Exit;
 end else
 begin
  if Param = '--restart' then
  begin
   RestartBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-restart-block');
   if GetLastError = ERROR_ALREADY_EXISTS then Exit;
  end;
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then SendMessage(WindowHandle, WM_DESTROY, 0, 0);
  if Param = '--stop' then Exit;
  Sleep(1000);
  repeat
   ExecuteBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-block');
  until ExecuteBlock <> 0;
  if Param = '--restart' then CloseHandle(RestartBlock);
 end;
{$endif}

{$ifdef unix}
 CreateConfig := not FileExists(LainDirectory + ConfigFileName) or CreateConfig;
 if CreateConfig = True then
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
 LainShellDataConfigure;
{$endif}

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
end;

begin
 InitCriticalSection(CriticalSection);
 LainDBControlClass := TLainDBControlClass.Create;
 Main;
{$ifdef unix}
 LainDBControlClass.SaveLainDBToFile(LainDirectory + DataBaseFileName);
 Writeln(EndLineChar);
{$endif}
{$ifdef windows}
 LainDBControlClass.SaveLainDBToRegistry(RegistryKey, RegistryValue);
 LainCloseSharedMemory(SharedMemoryRec);
 if ShareMemory <> 0 then CloseHandle(ShareMemory);
 if ExecuteBlock <> 0 then CloseHandle(ExecuteBlock);
{$endif}
 LainDBControlClass.Free;
 DoneCriticalSection(CriticalSection);
end.


