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


unit CServer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils, Main, Keyboard, Crt;
  
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
 
var
 RCConnection :TTcpIpSocketServer;
 RCThreadFree :Byte = 0;

var
 Connections :Array of TConnection;
 
implementation

uses {$ifdef windows} Windows, {$endif} Lang, Sockets, Extensions;

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
 OutPut :Text;
begin
 EnterCriticalSection(CriticalSection);
 AssignCrt(OutPut);
 ReWrite(OutPut);
 Writeln(OutPut, 'Localhost <<< ', HostAddrToStr(NetToHost(Connection.Addr.sin_addr)));
 SetLength(Connections, Length(Connections) + 1);
 Connections[Length(Connections) - 1] := Connection;
 Conn := TTcpIpCustomConnection.Create;
 Conn.SetConnection(Connection);
 Conn.Recv(ID, SizeOf(ID));

 ConnectionID += 1;
 Conn.Free;
 CloseFile(OutPut);
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

initialization
begin

end;

finalization
begin
// while do
end;

end.

