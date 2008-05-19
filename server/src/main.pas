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
 {$endif} Classes, SysUtils, NetUtils, LainDataBase;

{$ifdef unix}
 {$define verbose}
{$endif}

Const
 ClientReconnectTime = 30000;
 EndLineChar = #13;

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

type
 TConnectionArray = Array of TConnectionThread;
 

var
 MainThreads :Array[0..1] of TMainThread;
 CThreadList :TConnectionArray; // Connections Thread List

var

 CriticalSection :TRTLCriticalSection;
 ClientServiceSettings :TClientServiceSettings;
 ServerServiceSettings :TServerServiceSettings;
 ClientConnection :TTcpIpSocketClient;
 ServerConnection :TTcpIpSocketServer;
 
 function ClientServiceThread(P :Pointer) :Longint;
 function ServerServiceThread(P :Pointer) :Longint;
 
 procedure InitConnections(var ClientClass :TTcpIpSocketClient; var ServerClass :TTcpIpSocketServer);
 procedure DoneConnections(var ConnectionArray :TConnectionArray; var ClientClass :TTcpIpSocketClient; var ServerClass :TTcpIpSocketServer);

var
 TerminateApp :Boolean = False;
 LainDBControlClass :TLainDBControlClass;

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

procedure InitConnections(var ClientClass :TTcpIpSocketClient; var ServerClass :TTcpIpSocketServer);
var
 ProcCriticalSection :TRTLCriticalSection;
begin
InitCriticalSection(ProcCriticalSection);
 ClientClass := TTcpIpSocketClient.Create;
 ServerClass := TTcpIpSocketServer.Create;

EnterCriticalSection(ProcCriticalSection);
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
 
LeaveCriticalSection(ProcCriticalSection);
DoneCriticalSection(ProcCriticalSection);
end;

procedure DoneConnections(var ConnectionArray :TConnectionArray; var ClientClass :TTcpIpSocketClient; var ServerClass :TTcpIpSocketServer);
var
 ProcCriticalSection :TRTLCriticalSection;
 Item :TConnectionThread;
 X :Longint;
begin
 InitCriticalSection(ProcCriticalSection);
 EnterCriticalSection(ProcCriticalSection);
 TerminateApp := True;
 ClientClass.Disconnect;
 ServerClass.Shutdown;
 ServerClass.CloseSocket;
 LeaveCriticalSection(ProcCriticalSection);

 if MainThreads[0].Created = True then
 begin
  RTLEventWaitFor(MainThreads[0].Event);
  RTLEventDestroy(MainThreads[0].Event);
  ClientClass.Free;
 end;

 if MainThreads[1].Created = True then
 begin
  RTLEventWaitFor(MainThreads[1].Event);
  RTLEventDestroy(MainThreads[1].Event);
  ServerClass.Free;
 end;

 if Length(CThreadList) > 0 then
 begin
  for X := 0 to Length(ConnectionArray) - 1 do
  begin
   EnterCriticalSection(ProcCriticalSection);
   Item := ConnectionArray[x];
   LeaveCriticalSection(ProcCriticalSection);
   if Item.ThreadInfo.Created = True then
   begin
    EnterCriticalSection(ProcCriticalSection);
    Shutdown(Item.Connection.Sock, 2);
    CloseSocket(Item.Connection.Sock);
    LeaveCriticalSection(ProcCriticalSection);
    RTLEventWaitFor(Item.ThreadInfo.Event);
    RTLEventDestroy(Item.ThreadInfo.Event);
   end;
  end;
 end;
 ConnectionArray := nil;
 DoneCriticalSection(ProcCriticalSection);
end;

end.

