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

unit Threads;

{$mode objfpc}{$H+}

interface

uses
 {$ifdef windows} Windows, {$endif}
 {$ifdef unix} CThreads, {$endif} Classes, SysUtils;
  
{$ifdef windows}
Type
 TWinThreadProc = function(P :Pointer) :Longint; stdcall;

type
 TWindowsThread = class
 private
  AWinThreadProc :TWinThreadProc;
  AThreadID :THandle;
  APointer :Pointer;
 protected
  procedure CreateThread;
 public
  property ThreadID :THandle read AThreadID;
  constructor Create(WinThreadProc :TWinThreadProc; AMem :Pointer);
 end;
{$endif}

{$ifdef unix}
Type
 TUnixThreadProc = function(P :Pointer) :Longint; cdecl;

type
 TUnixThread = class(TThread)
 private
  AUnixThreadProc :TUnixThreadProc;
  AThreadID :Longint;
  APointer :Pointer;
 protected
  procedure Execute; override;
 public
  constructor Create(UnixThreadProc :TUnixThreadProc; AMem :Pointer; ACanSuspend :Boolean; AFreeOnTerminate :Boolean);
 end;
{$endif}

implementation

{$ifdef windows}
constructor TWindowsThread.Create(WinThreadProc :TWinThreadProc; AMem :Pointer);
begin
 inherited Create;
 AWinThreadProc := WinThreadProc;
 AThreadID := 0;
end;

procedure TWindowsThread.CreateThread;
begin
 Windows.CreateThread(nil, 0, AWinThreadProc, APointer, 0, AThreadID);
end;
{$endif}

{$ifdef unix}

constructor TUnixThread.Create(UnixThreadProc :TUnixThreadProc; AMem :Pointer; ACanSuspend :Boolean; AFreeOnTerminate :Boolean);
begin
 inherited Create(ACanSuspend);
 APointer := AMem;
 FreeOnTerminate := AFreeOnTerminate;
 AUnixThreadProc := UnixThreadProc;
end;

procedure TUnixThread.Execute;
begin
 AUnixThreadProc(APointer);
end;
{$endif}

end.

