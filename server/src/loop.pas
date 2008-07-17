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
 function UnixMainLoop(QuitLoop :PBoolean) :Boolean;
 function UnixMainLoopInit :Boolean;
 procedure UnixMainLoopDone;
 procedure UnixMainLoopKill;
 
{$endif}
{$ifdef windows}
 function CheckForCopy(Param :String) :Boolean;
 function WindowsMainLoopInit :Boolean;
 procedure WindowsMainLoop;
 procedure WindowsMainLoopDone;
 
{$endif}

implementation

uses
{$ifdef unix}
 BaseUnix, IPC, LibC;
{$endif}
{$ifdef windows}
 Windows;
{$endif}

{$ifdef unix}

Const
 LockFileName = '/tmp/lainshell.lock';

var
 CriticalSection :System.TRTLCriticalSection;
 FD :Integer;
 
 Dump :Longint;
 
 procedure UnixMainLoopKill;
 begin
  DeleteFile(LockFileName);
 end;
 
 function FileLocked :Integer;
 begin
  Result := Open(LockFileName, O_RDWR or O_CREAT or O_EXCL, 438);
 end;

 function UnixMainLoopInit :Boolean;
 begin
  FD := FileLocked;
  if FD <> -1 then
   Result := True else
   Result := False;
  if Result = False then
   Writeln('Remove: ', LockFileName) else
   System.InitCriticalSection(CriticalSection);
 end;
 
 procedure UnixMainLoopDone;
 begin
  __close(FD);
  unlink(LockFileName);
    DeleteFile(LockFileName);
  DoneCriticalSection(CriticalSection);
 end;
 
 
 function UnixMainLoop(QuitLoop :PBoolean) :Boolean;
 begin
  while ((FileExists(LockFileName) = True) and (QuitLoop^ <> True)) do
  begin
   sleep(10);
  end;
 end;

{$endif}

{$ifdef windows}

 var
  Window :TWNDClass;
  WindowControl :HWND;
  Msg :TMsg;

 function WndProc(wnd :hwnd; umsg :uint; wpar :wparam; lpar :lparam) :lresult; stdcall;
 begin
 Result := 0;
  case UMsg of
   wm_destroy: PostQuitMessage(0);
   wm_queryendsession: PostQuitMessage(0);
   else Result := DefWindowProc(wnd, umsg, wpar, lpar);
  end;
 end;

 function CheckForCopy(Param :String) :Boolean;
 var
  WindowHandle :THandle;
 begin
  Result := True;
  WindowHandle := FindWindow('lainshell-server', 'lainshell');
  if (WindowHandle <> 0) then
  begin
   if (Param = '--stop') then
   begin
    SendMessage(WindowHandle, WM_DESTROY, 0, 0);
    while FindWindow('lainshell-server', 'lainshell') = 0 do sleep(10);
    Exit(False);
   end else
    Exit(False);
  end;
 end;

 function WindowsMainLoopInit :Boolean;
 var
  WindowHandle :THandle;
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

 procedure WindowsMainLoopDone;
 begin
 end;

{$endif}

end.

