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
 public
  procedure CreateThread;
  property ThreadID :THandle read AThreadID;
  constructor Create(WinThreadProc :TWinThreadProc; AMem :Pointer);
 end;
{$endif}

{$ifdef unix}

type
 TUnixThread = class
 private
  AUnixThreadProc :TThreadFunc;
  AThreadID :TThreadID;
  APointer :Pointer;
 protected
 public
  procedure CreateThread;
  constructor Create(UnixThreadProc :TThreadFunc; AMem :Pointer);
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

constructor TUnixThread.Create(UnixThreadProc :TThreadFunc; AMem :Pointer);
begin
 AUnixThreadProc := UnixThreadProc;
 APointer := AMem;
 inherited Create;
end;

procedure TUnixThread.CreateThread;
begin
 BeginThread(AUnixThreadProc, APointer, AThreadID);
end;
{$endif}

end.

