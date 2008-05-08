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
  Main, SysUtils, Authorize, FSUtils, NetUtils, Engine, Sockets, Config, Execute,
  Sysinfo, Process, Security, Params, diskmgr, convnum;

Const
{$ifdef unix}
 ConfigFileName :WideString = 'lainconf.conf';
 ConfigDirectory :WideString = '.lainconf';
{$endif}
{$ifdef windows}
 ConfigFileName :AnsiString = 'lainconf.txt';
{$endif}

var
 X :Longint;
 Item :TConnectionThread;
 Param :String;
{$ifdef unix}
 Dump :LongWord;
 WorkDirectory :WideString;
 ConfigExists :Boolean = False;
 NanoPath :WideString;
{$endif}
{$ifdef windows}
 Handle :THandle;
 Window :TWNDClass;
 WindowControl :HWND;
 Msg :TMsg;
 WindowHandle :THandle;
 ShareMemory :THandle = 0;
 ExecuteBlock :THandle = 0;
 RestartBlock :THandle = 0;
 RegEdit :TRegistry;
{$endif}
 CreateConfig :Boolean = False;

{$ifdef windows}
 function WndProc(wnd :hwnd; umsg :uint; wpar :wparam; lpar :lparam) :lresult; stdcall;
 begin
 Result := 0;
  case UMsg of
   wm_destroy: PostQuitMessage(0);
   wm_queryendsession: PostQuitMessage(0);
   else Result := DefWindowProc(wnd, umsg, wpar, lpar);
  end;
 end;
{$endif}

function MainProc :Longint;
begin
{$ifdef windows}
 ShareMemory := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-server');
 if GetLastError = ERROR_ALREADY_EXISTS then
 begin
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
  begin
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);

   while true do
   begin
    Sleep(1);
    WindowHandle := FindWindow('lainshell-server', 'lainshell');
    if ((WindowHandle = 0)) then break;
   end;
   Sleep(1000);
  end;
  ShareMemory := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-server');
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
  ShellExecuteA(WindowControl, 'open', 'notepad.exe', Pchar(ConfigFileName), '', SW_SHOW);
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

 RegEdit := TRegistry.Create;
 RegEdit.RootKey := HKEY_CURRENT_USER;
 RegEdit.OpenKey('Software\LainShell', true);
 if not RegEdit.ValueExists('Accounts') then
  LainDBControlClass.CreateLainDB;
 RegEdit.Free;
 
 if Length(LainDBControlClass.AccountList) = 0 then
 begin
  MessageBox(GetForegroundWindow, 'Please adduser first, run with params adduser <username> <password>'
             , 'Info', MB_ICONINFORMATION + MB_OK);
  Exit;
 end;

 LainShellDataConfigure;


 with Window do
 begin
  lpfnwndproc := @wndproc;
  hinstance := hinstance;
  lpszclassname := 'lainshell-server';
  hbrBackground := color_window;
 end;

 RegisterClass(Window);
 WindowControl := CreateWindow('lainshell-server', 'lainshell', 0, 100, 100, 100,
                               100, 0, 0, system.HINSTANCE, nil);
{$endif}


 ClientConnection := TTcpIpSocketClient.Create;
 ServerConnection := TTcpIpSocketServer.Create;

EnterCriticalSection(CriticalSection);
{$ifdef unix}
 MainThreads[0].Created := (BeginThread(@ClientServiceThread, nil, MainThreads[0].Handle) <> 0);
 MainThreads[1].Created := (BeginThread(@ServerServiceThread, nil, MainThreads[1].Handle) <> 0);
{$endif}

{$ifdef windows}
 CreateThread(nil, 0, @ClientServiceThread, nil, 0, MainThreads[0].Handle);
 CreateThread(nil, 0, @ServerServiceThread, nil, 0, MainThreads[1].Handle);
 MainThreads[0].Created := MainThreads[0].Handle <> 0;
 MainThreads[1].Created := MainThreads[1].Handle <> 0;
{$endif}

 if MainThreads[0].Created = True then MainThreads[0].Event := RTLEventCreate;
 if MainThreads[1].Created = True then MainThreads[1].Event := RTLEventCreate;
LeaveCriticalSection(CriticalSection);

/// at the moment, the server app is only for tests
{$ifdef unix}
 shmid := shmget(IdentValue, SegmentSize, IPC_CREAT or AccessMode);
 if shmid <> -1 then
 begin
  pMemory := shmat(shmid, nil, 0);
  if Integer(pMemory) <> -1 then
  begin
   MemLongWord := pMemory;
   if MemLongWord^ <> $F0 then
   begin
    EnterCriticalSection(CriticalSection);
    MemLongWord^ := $F0;
    Dump := MemLongWord^;
    LeaveCriticalSection(CriticalSection);
    while ((Dump <> $FF) and (TerminateApp <> True)) do
    begin
     EnterCriticalSection(CriticalSection);
     Dump := MemLongWord^;
     LeaveCriticalSection(CriticalSection);
     sleep(10);
    end
   end;
  end else
   Writeln(OutPut, 'Can''t include shared memory');
  MemLongWord^ := $00;
  shmdt(pMemory);
 end else
  Writeln(OutPut, 'Can''t create shared memory');

{$endif}

{$ifdef windows}
 while getmessage(msg, 0, 0, 0) do dispatchmessage(msg);
{$endif}

 EnterCriticalSection(CriticalSection);
 TerminateApp := True;
 ClientConnection.Disconnect;
 ServerConnection.Shutdown;
 ServerConnection.CloseSocket;
 LeaveCriticalSection(CriticalSection);

 if MainThreads[0].Created = True then
 begin
  RTLEventWaitFor(MainThreads[0].Event);
  
  RTLEventDestroy(MainThreads[0].Event);
 end;

 if MainThreads[1].Created = True then
 begin
  RTLEventWaitFor(MainThreads[1].Event);
  RTLEventDestroy(MainThreads[1].Event);
 end;

 ClientConnection.Free;
 ServerConnection.Free;

 if Length(CThreadList) > 0 then
 begin
  for x := 0 to Length(CThreadList) - 1 do
  begin
   EnterCriticalSection(CriticalSection);
   Item := CThreadList[x];
   LeaveCriticalSection(CriticalSection);

   if Item.ThreadInfo.Created = True then
   begin
    EnterCriticalSection(CriticalSection);
    Shutdown(Item.Connection.Sock, 2);
    CloseSocket(Item.Connection.Sock);
    LeaveCriticalSection(CriticalSection);

    RTLEventWaitFor(Item.ThreadInfo.Event);
    RTLEventDestroy(Item.ThreadInfo.Event);
   end;

  end;
 end;

 CThreadList := nil;

end;

procedure ExitProcedure;
begin
{$ifdef unix}
 LainDBControlClass.SaveLainDBToFile(DataBaseFileName);
 CloseFile(OutPut);
{$endif}
{$ifdef windows}
 LainDBControlClass.SaveLainDBToRegistry(RegistryKey, RegistryValue);
 if ShareMemory <> 0 then CloseHandle(ShareMemory);
 if ExecuteBlock <> 0 then CloseHandle(ExecuteBlock);
{$endif}
 LainDBControlClass.Free;
 DoneCriticalSection(CriticalSection);
end;

begin
 InitCriticalSection(CriticalSection);
 LainDBControlClass := TLainDBControlClass.Create;
 Main.OutPut := System.Output;
 NetUtils.STDOutPut := System.Output;
 
 if ParamCount > 0 then
  Param := LowerCase(ParamStr(1)) else
  Param := '';
 AddExitProc(@ExitProcedure);
 CreateConfig := (Param = 'config');
 
 if Param = 'help' then if LainServerParamHelp(OutPut) = True then Exit;
 if Param = 'stop' then if LainServerParamStop(OutPut) = True then Exit;

 
{$ifdef windows}
 LainDBControlClass.LoadLainDBFromRegistry(RegistryKey, RegistryValue);
{$endif}


{$ifdef unix}
 WorkDirectory := GetHomeDirectory;
 if DirectoryExists(WorkDirectory) = False then
 begin
  Writeln(OutPut, 'Home directory doesn''t exists');
  Exit;
 end;

 WorkDirectory := IsDir(WorkDirectory) + ConfigDirectory;
 if DirectoryExists(WorkDirectory) = False then
 begin
  if FpMkDir(WorkDirectory, OctToDec('700')) <> 0 then
  begin
   Writeln(OutPut, 'Access Denied, can''t create directory ', WorkDirectory);
   Exit;
  end;
 end else
 begin
  if FpChMod(WorkDirectory, OctToDec('700')) <> 0 then
  begin
   Writeln(OutPut, 'Access Denied, can''t new privileges to ', WorkDirectory);
   Exit;
  end;
 end;
 
 CreateConfig := (not FileExists(IsDir(WorkDirectory) + ConfigFileName)) or CreateConfig;

 if CreateConfig = True then
 begin
  if FileExists(IsDir(WorkDirectory) + ConfigFileName) then
  begin

  end;
  ConfigFile := TConfigFile.Create;
  ConfigFile.GenerateConfig;
  ConfigFile.SaveConfig(ConfigFileName);
  ConfigFile.Free;
  Writeln(OutPut, 'Warning !!!: Please config this file ' + IsDir(HomeDirectory) + IsDir(ConfigDirectory) + ConfigFileName);
  Writeln(OutPut);
  Exit;
 end;

 ConfigFile := TConfigFile.Create;
 ConfigFile.OpenConfig(ConfigFileName);

 for X := 0 to ConfigVariablesCount do
  DefaultConfigVariables[X][1] := ConfigFile.GetString(DefaultConfigVariables[X][0]);

 ConfigFile.Free;
 LainShellDataConfigure;

 if FileExists(DataBaseFileName) then
 begin
  if not LainDBControlClass.LoadLainDBFromFile(DataBaseFileName) then
  begin
   LainDBControlClass.Create;
   LainDBControlClass.SaveLainDBToFile(DataBaseFileName);
  end;
 end else
 begin
  LainDBControlClass.CreateLainDB;
  LainDBControlClass.SaveLainDBToFile(DataBaseFileName);
 end;
{$endif}


{$ifdef windows}
 if ((Param <> 'stop') and (Param <> 'restart')) then
 begin
  ExecuteBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-block');
  if GetLastError = ERROR_ALREADY_EXISTS then
   Exit;
 end else
 begin
  if Param = 'restart' then
  begin
   RestartBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-restart-block');
   if GetLastError = ERROR_ALREADY_EXISTS then
    Exit;
  end;
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);
  if Param = 'stop' then Exit;
  Sleep(1000);

  repeat
   ExecuteBlock := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-block');
  until ExecuteBlock <> 0;

  if Param = 'restart' then CloseHandle(RestartBlock);
 end;
{$endif}



 if Param = 'adduser' then if LainServerParamAddUser(OutPut) = True then Exit;
 if Param = 'deluser' then if LainServerParamDelUser(OutPut) = True then Exit;
 if Param = 'chkuser' then if LainServerParamChkUser(OutPut) = True then Exit;
 if Param = 'lstuser' then if LainServerParamLstUser(OutPut) = True then Exit;
 if Param = 'pwduser' then if LainServerParamPwdUser(OutPut) = True then Exit;
 if Param = 'createdb' then if LainServerParamCreateDB(OutPut) = True then Exit;

 MainProc;
end.

