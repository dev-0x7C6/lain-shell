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

unit Loop;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 
  
{$ifdef unix}

 function UnixMainLoop(QuitLoop :PBoolean; var CodeStat :Longint) :Boolean;

 function UnixMainLoopInit :Boolean;
 
 procedure UnixMainLoopDone;
 procedure UnixMainLoopKill;
 
 
{$endif}
{$ifdef windows}

 function WindowsMainLoopInit :Boolean;
 
 procedure WindowsMainLoop;
 procedure WindowsMainLoopDone;
{$endif}

implementation

uses
{$ifdef unix}
 BaseUnix, ShareMem, IPC;
{$endif}
{$ifdef windows}
 Windows;
{$endif}

{$ifdef unix}

 procedure UnixMainLoopKill;
 var
  SharedMemoryConfig :TSharedMemoryConfig;
  SharedMemoryRec :TSharedMemoryRec;
  CriticalSection :TRTLCriticalSection;
 begin
  InitCriticalSection(CriticalSection);
  DefaultConfigForSharedMemory(SharedMemoryConfig);
  SharedMemoryConfig.AccessMode := 0;
  SharedMemoryConfig.BlockSize := 0;
  if LainOpenSharedMemory(SharedMemoryRec, SharedMemoryConfig) then
  begin
  EnterCriticalSection(CriticalSection);
   LainWriteSharedMemory(SharedMemoryRec, $FF);
  LeaveCriticalSection(CriticalSection);
   LainCloseSharedMemory(SharedMemoryRec);
  end;
  DoneCriticalSection(CriticalSection);
 end;

var
 SharedMemoryConfig :TSharedMemoryConfig;
 SharedMemoryRec :TSharedMemoryRec;
 CriticalSection :TRTLCriticalSection;
 Dump :Longint;

 function UnixMainLoopInit :Boolean;
 begin
  InitCriticalSection(CriticalSection);
  DefaultConfigForSharedMemory(SharedMemoryConfig);
  if LainOpenSharedMemory(SharedMemoryRec, SharedMemoryConfig) then
   Result := LainReadSheredMemory(SharedMemoryRec) <> $F0 else
   Result := False;
 end;
 
 procedure UnixMainLoopDone;
 begin
 EnterCriticalSection(CriticalSection);
  LainWriteSharedMemory(SharedMemoryRec, $00);
 LeaveCriticalSection(CriticalSection);
  LainCloseSharedMemory(SharedMemoryRec);
  DoneCriticalSection(CriticalSection);
 end;
 
 
 function UnixMainLoop(QuitLoop :PBoolean; var CodeStat :Longint) :Boolean;
 begin
 EnterCriticalSection(CriticalSection);
  LainWriteSharedMemory(SharedMemoryRec, $F0);
 LeaveCriticalSection(CriticalSection);
  Dump := $F0;
  while ((Dump <> $FF) and (QuitLoop^ <> True)) do
  begin
  EnterCriticalSection(CriticalSection);
   Dump := LainReadSheredMemory(SharedMemoryRec);
  LeaveCriticalSection(CriticalSection);
   sleep(10);
  end;
 end;

{$endif}

{$ifdef windows}

 var
  Window :TWNDClass;
  WindowControl :HWND;
  Msg :TMsg;

 function WindowsMainLoopInit :Boolean;
 begin
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
  Result := (WindowControl > 0);
 end;
 
 
 procedure WindowsMainLoop;
 begin
  while GetMessage(msg, 0, 0, 0) do DispatchMessage(msg);
 end;

{$endif}

end.

