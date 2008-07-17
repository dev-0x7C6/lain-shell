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

unit Network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils, Main, KeyBoard;

  
Const
 AuthTable :Array[0..15] of Byte =   ($d5, $8b, $6a, $97, $c4, $3e, $c5, $59, $2f,
                                      $0b, $c0, $33, $c7, $2e, $d5, $13);
 AcceptTable :Array[0..15] of Byte = ($4a, $be, $77, $c2, $01, $ff, $11, $66, $3c,
                                      $cd, $f5, $2f, $d6, $ec, $ea, $86);
 DefaultServerPort = 9896;
 
  
{$ifdef unix}
 type
  TUnixRCConnectThread = Class(TThread)
  protected
   procedure Execute; override;
  public
   constructor Create;
  end;
{$endif}


 function CMD_RCConnect(var Params :TParams) :Longint;
 function CMD_Connect(var Params :TParams) :Longint;
 function CMD_Disconnect(var Params :TParams) :Longint;
 

var
 RCConnection :TTcpIpSocketServer;
 RCThreadFree :Byte = 0;

var
 Connections :Array of TConnection;

implementation

uses
 {$ifdef windows} Windows, {$endif} Addons, Engine, Extensions, NLang, Sockets, Threads;

var
{$ifdef unix}
 UnixThread :TUnixThread;
{$endif}
{$ifdef windows}
 WindowsThread :TWindowsThread;
{$endif}

 ThreadEvent :PRTLEvent;
 ConnectionAccept :Boolean = False;
 ThreadFree :Boolean = False;

procedure ConnectThread;
var
 AuthBuffer :Array[0..15] of Byte;
 X :Longint;
 Verfication :Boolean;
begin
 if Main.Connection.Connect then
 begin
  if Connection.Send(AuthTable, SizeOf(AuthTable)) = SizeOf(AuthTable) then
  begin
   if Connection.Recv(AuthBuffer, SizeOf(AuthBuffer)) = SizeOf(AuthBuffer) then
   begin
    Verfication := True;
    for X := Low(AcceptTable) to High(AcceptTable) do
     if AcceptTable[X] = AuthBuffer[X] then
      Verfication := Verfication and True else
      Verfication := Verfication and False;
   EnterCriticalSection(CriticalSection);
    ConnectionAccept := Verfication;
   LeaveCriticalSection(CriticalSection);
   end else
   begin
   EnterCriticalSection(CriticalSection);
    ConnectionAccept := False;
   LeaveCriticalSection(CriticalSection);
   end;
  end else
  begin
  EnterCriticalSection(CriticalSection);
   ConnectionAccept := False;
  LeaveCriticalSection(CriticalSection);
  end;
 end;
EnterCriticalSection(CriticalSection);
 ThreadFree := True;
 RTLEventSetEvent(ThreadEvent);
LeaveCriticalSection(CriticalSection);
end;

{$ifdef unix}
 function UnixConnectThreadBind(P :Pointer) :Longint;
 begin
  ConnectThread;
 end;
{$endif}

{$ifdef windows}
 function WindowsConnectThreadBind(P :Pointer) :Longint; stdcall;
 begin
  ConnectThread;
 end;
{$endif}

function CMD_Connect(var Params :TParams) :Longint;
var
 X :Longint;
 Key :TKeyEvent;
begin
 if Connection.Connected = True then
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgAlreadyConnected'), EndLineChar);
  Exit(CMD_Fail);
 end;
 
 if Length(Params) < 2 then
 begin
  Writeln(MultiLanguageSupport.GetString('UsingConnect'), EndLineChar);
  Exit(CMD_Fail);
 end;

 LainClientData.Authorized := False;
 
 LainClientData.Hostname := ExtractHostFromHostName(Params[1]);
 LainClientData.Port     := IntToStr(ExtractPortFromHostName(Params[1]));
 if LainClientData.Port = '-1' then
  LainClientData.Port := IntToStr(DefaultServerPort);
  
 Connection.Hostname := GetIpByHost(PChar(AnsiString(LainClientData.Hostname)));
 Connection.Port     := StrToIntDef(LainClientData.Port, 9896);
  
 if Connection.Hostname = '' then
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgCantFindHostname'), EndLineChar);
  Exit(CMD_Fail);
 end;


 Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgCancelConnect'), EndLineChar);
 ThreadEvent := RTLEventCreate;
 ThreadFree := False;
 
{$ifdef unix}
 UnixThread := TUnixThread.Create(@UnixConnectThreadBind, nil);
 UnixThread.CreateThread;
{$endif}
{$ifdef windows}
 WindowsThread := TWindowsThread.Create(@WindowsConnectThreadBind, nil);
 WindowsThread.CreateThread;
{$endif}

 InitKeyBoard;
 repeat
  if Keyboard.KeyPressed then
  begin
   Key := GetKeyEvent;
   Key := TranslateKeyEvent(Key);
   if GetKeyEventChar(Key) = kbdReturn then
   begin
   EnterCriticalSection(CriticalSection);
    Write(Prefix_Out, MultiLanguageSupport.GetString('MsgCloseSocket') + ' ');
    if Main.Connection.Disconnect then
     Writeln(MultiLanguageSupport.GetString('FieldDone') + EndLineChar) else
     Writeln(MultiLanguageSupport.GetString('FieldFail') + EndLineChar);
   LeaveCriticalSection(CriticalSection);
    RTLEventWaitFor(ThreadEvent);
    Break;
   end;
  end else
   Sleep(10);
 until ThreadFree = True;
 DoneKeyBoard;
 RTLEventDestroy(ThreadEvent);

{$ifdef unix}
 UnixThread.Free;
{$endif}
{$ifdef windows}
 WindowsThread.Free;
{$endif}

 if (Connection.Connected = True) then
 begin
  ConsoleHost := LainClientData.Hostname;
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgConnected') + ' ', ConsoleHost, EndLineChar);
  Result := CMD_Done;
 end else
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgCantConnect'), EndLineChar);
  Exit(CMD_Fail);
 end;
 
 if (ConnectionAccept = False) then
 begin
  Connection.Disconnect;
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgUnknownProto'), EndLineChar);
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgDisconnect'), EndLineChar);
  Result := CMD_Fail;
 end;
end;

function CMD_Disconnect(var Params :TParams) :Longint;
begin
 if Connection.Connected then
 begin
  ConnectionClosedGracefullyErrorShow := False;
  if LainClientData.Authorized = True then
  begin
   CMD_Logout(Params);
  end;
  Connection.Disconnect;
  LainClientData.Authorized := False;
  ConsoleUser := MultiLanguageSupport.GetString('FieldUsername');
  ConsoleHost := MultiLanguageSupport.GetString('FieldLocation');
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgDisconnected'), EndLineChar);
 end else
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgNotConnected'), EndLineChar);
 Result := CMD_Done;
end;

var
{$ifdef unix}
 UnixRCConnectThread :TUnixRCConnectThread;
{$endif}
 RCConnectThreadEvent :PRTLEvent;

procedure RCConnectionAccepted(Connection :TConnection); forward;

function RCThread(P :Pointer) :Longint;
begin
 RCConnection.OnAccepted := @RCConnectionAccepted;
 RCConnection.Start;
EnterCriticalSection(CriticalSection);
 RTLEventSetEvent(RCConnectThreadEvent);
LeaveCriticalSection(CriticalSection);
end;

var ConnectionID :Longint = 0;

procedure RCConnectionAccepted(Connection :TConnection);
var
 Conn :TTcpIpCustomConnection;
 Verfication :Boolean;
 AuthBuffer :Array[0..15] of Byte;
 X :Longint;

begin
EnterCriticalSection(CriticalSection);
 SetLength(Connections, Length(Connections) + 1);
 Connections[Length(Connections) - 1] := Connection;
 Conn := TTcpIpCustomConnection.Create;
 Conn.SetConnection(Connection);
 InterLockedIncrement(ConnectionID);
LeaveCriticalSection(CriticalSection);

 if Conn.Send(AuthTable, SizeOf(AuthTable)) = SizeOf(AuthTable) then
 begin
  if Conn.Recv(AuthBuffer, SizeOf(AuthBuffer)) = SizeOf(AuthBuffer) then
  begin
   Verfication := True;
   for X := Low(AcceptTable) to High(AcceptTable) do
    if AcceptTable[X] = AuthBuffer[X] then
     Verfication := Verfication and True else
     Verfication := Verfication and False;
   if Verfication = True then
   begin
    EnterCriticalSection(CriticalSection);
     Writeln(' --- ID=', ConnectionID, ' Accepted connection with ', HostAddrToStr(NetToHost(Connection.Addr.sin_addr)), EndLineChar);
    LeaveCriticalSection(CriticalSection);
   end else
   begin
    EnterCriticalSection(CriticalSection);
     Writeln(' --- Unknown connection protocol ', HostAddrToStr(NetToHost(Connection.Addr.sin_addr)), EndLineChar);
     SetLength(Connections, Length(Connections) - 1);
     InterLockedDecrement(ConnectionID);
    LeaveCriticalSection(CriticalSection);
   end;
  end;
 end;
 Conn.Free;
end;

{$ifdef unix}
 procedure TUnixRCConnectThread.Execute;
 begin
  RCThread(nil);
 end;

 constructor TUnixRCConnectThread.Create;
 begin
  inherited Create(False);
  FreeOnTerminate := False;
 end;
{$endif}


function CMD_RCConnect(var Params :TParams) :Longint;
var
 Key :TKeyEvent;
 Str :WideString;
 ID, X :Longint;
{$ifdef windows}
 ThreadID :LongWord;
{$endif}
begin
 if Connection.Connected = True then
 begin
  Writeln(MultiLanguageSupport.GetString('MsgAlreadyConnected'), EndLineChar);
  Exit(CMD_Fail);
 end;
 
 if Length(Params) < 3 then
 begin
  Writeln(MultiLanguageSupport.GetString('UsingRConnect'), EndLineChar);
  Exit(CMD_Fail);
 end;

 RCConnection := TTcpIpSocketServer.Create;
 RCConnection.Port := StrToIntDef(Params[1], 9897);
 RCConnection.MaxConnections := StrToIntDef(Params[2], 0);
 RCThreadFree := 0;
 ConnectionID := 0;
 Connections := nil;

 Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgRConnectPressEnter'), EndLineChar);
 Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgRConnectWaiting'), EndLineChar);
 RCConnectThreadEvent := RTLEventCreate;

{$ifdef unix}
 UnixRCConnectThread := TUnixRCConnectThread.Create;
{$endif}
{$ifdef windows}
 Windows.CreateThread(nil, 0, @RCThread, nil, 0, ThreadID);
{$endif}

 InitKeyBoard;
 repeat
  Key := GetKeyEvent;
  Key := TranslateKeyEvent(Key);
  if GetKeyEventChar(Key) = kbdReturn then
  begin
   RCConnection.Shutdown;
   RCConnection.CloseSocket;
   Write(Prefix_Out, MultiLanguageSupport.GetString('MsgRConnectThreadEnd'));
   RTLEventWaitFor(RCConnectThreadEvent);
   Writeln(MultiLanguageSupport.GetString('FieldDone'), EndLineChar);
   Break;
  end;
 until False;
 DoneKeyBoard;
 RCConnection.Free;

 RTLEventDestroy(RCConnectThreadEvent);
{$ifdef unix}
 UnixRCConnectThread.Free;
{$endif}

 if Length(Connections) > 0 then
 begin
  repeat
   Write(MultiLanguageSupport.GetString('MsgRConnectChose') + ' ');
   Str := GetTextln;
   ID := StrToIntDef(Str, -1);
   if ((ID = -1) or (ID > Length(Connections))) then
   begin
    Writeln(MultiLanguageSupport.GetString('MsgRConnectUnknownID'), EndLineChar);
    Continue;
   end;
   Connection.SetConnection(Connections[ID - 1]);
   Connection.Hostname := HostAddrToStr(NetToHost(Connections[ID - 1].Addr.Sin_addr));
   Connection.Port := StrToIntDef(Params[1], 9897);
   LainClientData.Hostname := Connection.Hostname;
   LainClientData.Port := Params[1];
   ConsoleHost := LainClientData.Hostname;
  until True;
  For X := 0 to Length(Connections) - 1 do
   if X <> (ID - 1) then
   begin
    ShutDown(Connections[X].Sock, 2);
    CloseSocket(Connections[X].Sock);
   end;
 end;

 Connections := nil;
end;

end.

