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
  CThreads, IPC,
{$endif}
{$ifdef windows}
  Windows, Registry, ShellApi,
{$endif}
  Main, SysUtils, authorize, FSUtils, NetUtils, Engine, Sockets, config;

{$ifdef unix}
 const
  AccessMode = SHM_R or SHM_W;
  SegmentSize = SizeOf(LongWord);
  IdentValue = $F3D8;
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
{$endif}
{$ifdef windows}
 Handle :THandle;
 Window :TWNDClass;
 WindowControl :HWND;
 Msg :TMsg;
 WindowHandle :THandle;
 ShareMemory :THandle;
 RegEdit :TRegistry;
{$endif}
 Configure :Boolean = False;

procedure ExitProcedure;
begin
{$ifdef unix}
 CloseFile(OutPut);
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
  
begin
 InitCriticalSection(CriticalSection);
 AddExitProc(@ExitProcedure);

 if ParamCount > 0 then
  Param := ParamStr(1) else
  Param := '';

 Configure := (Param = 'config');

{$ifdef unix}
 AssignFile(OutPut, '');
 ReWrite(OutPut);
 NetUtils.STDOutPut := OutPut;

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

{$ifdef windows}
 if Param = 'stop' then
 begin
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);
  DoneCriticalSection(CriticalSection);
  Halt;
 end;
 
 ShareMemory := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 4, 'lainshell-server');
 if GetLastError = ERROR_ALREADY_EXISTS then
 begin
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
  begin
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);
   Handle := $FFFF;
   while Handle <> 0 do
   begin
    Handle := OpenFileMapping(FILE_MAP_ALL_ACCESS, True, 'lainshell-server'); sleep(1);
   end;
   Sleep(1000);
  end;
 end;
 
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

 if Configure = False then
 begin
  RegEdit := TRegistry.Create;
  RegEdit.RootKey := Windows.HKEY_CURRENT_USER;
  Configure := not RegEdit.KeyExists('Software\LainShell');
  RegEdit.Free;
 end;
 
 if Configure = True then
 begin
  ShellExecuteA(WindowControl, 'open', 'notepad.exe', 'config.txt', '', SW_SHOW);
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if WindowHandle <> 0 then
   SendMessage(WindowHandle, WM_DESTROY, 0, 0);
 end;
 
{$endif}

 ClientConnection := TTcpIpSocketClient.Create;
 ServerConnection := TTcpIpSocketServer.Create;
 
 ClientServiceSettings.Hostname := '127.0.0.1';
 ClientServiceSettings.Port := 9897;
 ServerServiceSettings.MaxConnections := 0;
 ServerServiceSettings.Port := 9896;
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
   EnterCriticalSection(CriticalSection);
   MemLongWord^ := 0;
   Dump := MemLongWord^;
   LeaveCriticalSection(CriticalSection);
   while Dump <> $FF do
   begin
    EnterCriticalSection(CriticalSection);
    Dump := MemLongWord^;
    LeaveCriticalSection(CriticalSection);
    sleep(10);
   end;
  end else
   Writeln(OutPut, 'Can''t include shared memory');
  shmdt(pMemory);
 end else
  Writeln(OutPut, 'Can''t create shared memory');


{$endif}

{$ifdef windows}
 while getmessage(msg, 0, 0, 0) do dispatchmessage(msg);
 
 if ShareMemory <> 0 then CloseHandle(ShareMemory);
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

