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
 {$endif} Classes, SysUtils, NetUtils, Security;

{$ifdef unix}
 {$define verbose}
{$endif}

Const
 ClientReconnectTime = 30000;

type
 TClientServiceSettings = packed record
  Hostname :WideString;
  Port :Word;
 end;

 TServerServiceSettings = packed record
  MaxConnections :Longint;
  Port :Word;
 end;
 

type
 TMainThread = packed record
  Created :Boolean;
  Event :PRTLEvent;
 {$ifdef unix}
  Handle :TThreadID;
 {$endif}
 {$ifdef windows}
  Handle :THandle;
 {$endif}
 end;
 
type
 TConnectionThread = packed record
  Connection :TConnection;
  ThreadInfo :TMainThread;
 end;

var
 MainThreads :Array[0..1] of TMainThread;
 CThreadList :Array of TConnectionThread; // Connections Thread List

var

 CriticalSection :TRTLCriticalSection;
 ClientServiceSettings :TClientServiceSettings;
 ServerServiceSettings :TServerServiceSettings;
 ClientConnection :TTcpIpSocketClient;
 ServerConnection :TTcpIpSocketServer;
 
 function ClientServiceThread(P :Pointer) :Longint;
 function ServerServiceThread(P :Pointer) :Longint;

var
 TerminateApp :Boolean = False;
 LainDBControlClass :TLainDBControlClass;
 OutPut :Text;

implementation

uses
 Authorize, Sockets;

function ClientServiceThread(P :Pointer) :Longint;
var
 Connection :TConnection;
 X :Longint;
begin
 EnterCriticalSection(CriticalSection);
 ClientConnection.Hostname := ClientServiceSettings.Hostname;
 ClientConnection.Port := ClientServiceSettings.Port;
 LeaveCriticalSection(CriticalSection);

 repeat
  if not ClientConnection.Connect then
  begin
   for X := 1 to (ClientReConnectTime div 10) do
   begin
    Sleep(10);
     if TerminateApp = True then Break;
   end;
  end else
  begin
   Connection := ClientConnection.GetConnection;
   FAuthorize(Connection);
  end;
 until TerminateApp=True;
 
 if ClientConnection.Connected then
  ClientConnection.Disconnect;
  
 Result := 0;
 RTLEventSetEvent(MainThreads[0].Event);
end;


procedure HaveAConnection(AConnection :TConnection);
var
 Index :^Longint;
 ThreadID :TThreadID;
begin
 New(Index);
 
 EnterCriticalSection(CriticalSection);
 
 SetLength(CThreadList, Length(CThreadList) + 1);
 Index^ := Length(CThreadList) - 1;
 CThreadList[Index^].Connection := AConnection;

{$ifdef unix}
 CThreadList[Index^].ThreadInfo.Created := (BeginThread(@OnConnect, Index,
 CThreadList[Index^].ThreadInfo.Handle) <> 0);
{$endif}

{$ifdef windows}
 CreateThread(nil, 0, @OnConnect, Index, 0, CThreadList[Index^].ThreadInfo.Handle);
 CThreadList[Index^].ThreadInfo.Created := CThreadList[Index^].ThreadInfo.Handle <> 0;
{$endif}

 if CThreadList[Index^].ThreadInfo.Created then
  CThreadList[Index^].ThreadInfo.Event := RTLEventCreate;

 LeaveCriticalSection(CriticalSection);
end;

function ServerServiceThread(P :Pointer) :Longint;
begin
 EnterCriticalSection(CriticalSection);
 ServerConnection.MaxConnections := ServerServiceSettings.MaxConnections;
 ServerConnection.Port := ServerServiceSettings.Port;
 LeaveCriticalSection(CriticalSection);
 ServerConnection.OnAccepted := @HaveAConnection;
 ServerConnection.Start;
 Result := 0;
 RTLEventSetEvent(MainThreads[1].Event);
end;

 
initialization
begin
end;

finalization
begin
end;

end.

