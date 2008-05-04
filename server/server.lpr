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
  CThreads, IPC, BaseUnix, Unix, Signals,
{$endif}
{$ifdef windows}
  Windows, Registry, ShellApi,
{$endif}
  Main, SysUtils, authorize, FSUtils, NetUtils, Engine, Sockets, Config,
execute, sysinfo, process, security;

{$ifdef unix}
 const
  AccessMode = SHM_R or SHM_W;
  SegmentSize = SizeOf(LongWord);
  IdentValue = $F3D8;
{$endif}

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
 shmid :Integer;
 pMemory :Pointer;
 MemLongWord :^Longword;
 HomeDirectory :WideString;
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

procedure ExitProcedure;
begin
{$ifdef unix}
 CloseFile(OutPut);
{$endif}
{$ifdef windows}
 if ShareMemory <> 0 then CloseHandle(ShareMemory);
 if ExecuteBlock <> 0 then CloseHandle(ExecuteBlock);
{$endif}
  DoneCriticalSection(CriticalSection);
end;

  
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

var
 HelpMsg :AnsiString;
 
{$ifdef unix}
function GetHomeDirectory :AnsiString;
var
 Pipe :Text;
begin
 POpen(Pipe, 'echo $HOME', 'R');
 Readln(Pipe, Result);
 PClose(Pipe);
end;

function IsDir(const Str :AnsiString) :AnsiString;
begin
 if (Str[Length(Str)] = '/') then
  Result := Str else
  Result := Str + '/';
end;

{$endif}
  
begin
 if ParamCount > 0 then
  Param := LowerCase(ParamStr(1)) else
  Param := '';
  
 if Param = 'help' then
 begin
 
  HelpMsg := 'config  - run configurator' + LineEnding +
             'help    - show this message' + LineEnding +
             'restart - restart running deamon' + LineEnding +
             'stop    - stop running deamon' + LineEnding;
 {$ifdef unix}
  writeln(HelpMsg);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(HelpMsg), 'Help page', MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
  
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

 InitCriticalSection(CriticalSection);
 AddExitProc(@ExitProcedure);

 CreateConfig := (Param = 'config');
 
{$ifdef unix}
 AssignFile(OutPut, '');
 ReWrite(OutPut);
 NetUtils.STDOutPut := OutPut;
 
 HomeDirectory :=  GetHomeDirectory;
 if FpChdir(HomeDirectory) <> -1 then
 begin
  if not DirectoryExists(IsDir(HomeDirectory) + ConfigDirectory) then
   Mkdir(IsDir(HomeDirectory) + ConfigDirectory);
  if FpChdir(IsDir(HomeDirectory) + ConfigDirectory) <> -1 then
   CreateConfig := (not FileExists(ConfigFileName)) or CreateConfig;
 end;
 
 if CreateConfig= True then
 begin
  if FileExists(ConfigFileName) then
   DeleteFile(ConfigFileName);
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
 
{$endif}

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


{$ifdef unix}
 if Param = 'stop' then
 begin
  shmid := shmget(IdentValue, 0, 0);
  if shmid =-1 then
  begin
   Writeln(OutPut, 'nothing to stop');
   Exit;
  end;
  
  pMemory := shmat(shmid, nil, 0);

  if Integer(pMemory) = -1 then
  begin
   shmdt(pMemory);
   Writeln(OutPut, 'access denided');
   Exit;
  end;
  
  MemLongWord := pMemory;
  MemLongWord^ := $FF;
  Writeln(OutPut, 'Done');
  shmdt(pMemory);
  Exit;
 end;
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

end.

