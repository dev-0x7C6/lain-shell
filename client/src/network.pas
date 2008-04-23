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
  Classes, SysUtils, NetUtils, Main, Crt, Keyboard;

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
 {$ifdef windows} Windows, {$endif} Addons, Engine, Extensions, Lang, Sockets, Threads;

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
 ID :LongWord;
begin
 if Main.Connection.Connect then
 begin
  if Connection.Recv(ID, SizeOf(ID)) = SizeOf(ID) then
  begin
   EnterCriticalSection(CriticalSection);
   if ID = $F8D6 then
    ConnectionAccept := True else
    ConnectionAccept := False;
   LeaveCriticalSection(CriticalSection);
  end else
  begin
   EnterCriticalSection(CriticalSection);
   ConnectionAccept := False;
   LeaveCriticalSection(CriticalSection);
  end;
 end;

 EnterCriticalSection(CriticalSection);
 ThreadFree := True;
 LeaveCriticalSection(CriticalSection);
 RTLEventSetEvent(ThreadEvent);
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
 X, Offset :Longint;
 Key :TKeyEvent;

begin
 if Length(Params) < 2 then
 begin
  Writeln('');
  Writeln;
  Exit(CMD_Fail);
 end;

 if Connection.Connected = True then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgAlreadyConnected'));
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgDisconnectConnection'));
  Writeln;
  Exit(CMD_Fail);
 end;

 Offset := 0;
 for X := 1 to length(Params[1]) do if Params[1][X] = ':' then Offset := X;
 if Offset <> 0 then
 begin
  LainClientData.Hostname := Copy(Params[1], 1, Offset - 1);
  LainClientData.Port := Copy(Params[1], Offset + 1, Length(Params[1]) - Offset);
 end else
 begin
  LainClientData.Hostname := Params[1];
  LainClientData.Port := '9896';
 end;
 Connection.Hostname := GetIpByHost(PChar(AnsiString(LainClientData.Hostname)));

 if Connection.Hostname = '' then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgCantFindHostname'));
  Writeln;
  Exit(CMD_Fail);
 end;

 Connection.Port := StrToIntDef(LainClientData.Port, 9896);
 Writeln(Prefix, MultiLanguageSupport.GetString('MsgCancelConnect'));

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
    Write(Prefix, MultiLanguageSupport.GetString('MsgCloseSocket') + ' ');
    if Main.Connection.Disconnect then
     Writeln(MultiLanguageSupport.GetString('FieldDone')) else
     Writeln(MultiLanguageSupport.GetString('FieldFail'));
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
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgConnected') + ' ', ConsoleHost);
  Result := CMD_Done;
 end else
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgCantConnect'));
  Writeln;
  Exit(CMD_Fail);
 end;
 
 if (ConnectionAccept = False) then
 begin
  Connection.Disconnect;
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgUnknownProto'));
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgDisconnect'));
  Result := CMD_Fail;
 end;

 Writeln;
end;

function CMD_Disconnect(var Params :TParams) :Longint;
begin
 if Connection.Connected then
 begin
  if LainClientData.Authorized = True then
   CMD_Logout(Params);
   
  Connection.Disconnect;
  LainClientData.Authorized := False;
  ConsoleUser := MultiLanguageSupport.GetString('FieldUsername');
  ConsoleHost := MultiLanguageSupport.GetString('FieldLocation');
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgDisconnected'));
 end else
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgNotConnected'));
 Writeln;
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
 RTLEventSetEvent(RCConnectThreadEvent);
end;

var ConnectionID :Longint = 1;

procedure RCConnectionAccepted(Connection :TConnection);
var
 Conn :TTcpIpCustomConnection;
 ID :Longword;
 //OutPut :Text;
begin
 EnterCriticalSection(CriticalSection);
 //AssignCrt(OutPut);
 //ReWrite(OutPut);
 //Writeln(OutPut, 'Localhost <<< ', HostAddrToStr(NetToHost(Connection.Addr.sin_addr)));
 SetLength(Connections, Length(Connections) + 1);
 Connections[Length(Connections) - 1] := Connection;
 Conn := TTcpIpCustomConnection.Create;
 Conn.SetConnection(Connection);
 Conn.Recv(ID, SizeOf(ID));

 ConnectionID += 1;
 Conn.Free;
 //CloseFile(OutPut);
 LeaveCriticalSection(CriticalSection);
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
 if Length(Params) < 3 then
 begin
  Writeln(MultiLanguageSupport.GetString('MsgRConnectUsage'));
  Writeln;
  Exit(CMD_Fail);
 end;

 RCConnection := TTcpIpSocketServer.Create;
 RCConnection.Port := StrToIntDef(Params[1], 9897);
 RCConnection.MaxConnections := StrToIntDef(Params[2], 0);
 RCThreadFree := 0;
 ConnectionID := 1;
 Connections := nil;

 Writeln(Prefix, MultiLanguageSupport.GetString('MsgRConnectPressEnter'));
 Writeln(Prefix, MultiLanguageSupport.GetString('MsgRConnectWaiting'));
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
   Write(Prefix, MultiLanguageSupport.GetString('MsgRConnectThreadEnd'));
   RTLEventWaitFor(RCConnectThreadEvent);
   Writeln(MultiLanguageSupport.GetString('FieldDone'));
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
    Writeln(MultiLanguageSupport.GetString('MsgRConnectUnknownID'));
    Continue;
   end;
   Connection.SetConnection(Connections[ID - 1]);
   LainClientData.Hostname := HostAddrToStr(NetToHost(Connections[ID - 1].Addr.Sin_addr));
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

