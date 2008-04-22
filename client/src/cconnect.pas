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

unit CConnect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main, Crt, Keyboard;

{$ifdef unix}
 type
  TUnixConnectThread = class(TThread)
  protected
   procedure Execute; override;
  public
   constructor Create;
  end;
{$endif}

 function CMD_Connect(var Params :TParams) :Longint;
 function CMD_Disconnect(var Params :TParams) :Longint;
 function CMD_Status(var Params :TParams) :Longint;

implementation

uses {$ifdef windows} Windows, {$endif} NetUtils, Lang, Extensions, CAddons;

var
{$ifdef unix}
 UnixConnectThread :TUnixConnectThread;
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
 constructor TUnixConnectThread.Create;
 begin
  inherited Create(False);
  FreeOnTerminate := False;
 end;
 
 procedure TUnixConnectThread.Execute;
 begin
  ConnectThread;
 end;
{$endif}

function CMD_Connect(var Params :TParams) :Longint;
var
 X, Offset :Longint;
 Key :TKeyEvent;

{$ifdef windows}
 Handle :THandle;
{$endif}

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
 UnixConnectThread := TUnixConnectThread.Create;
{$endif}
{$ifdef windows}
 CreateThread(nil, 0, @ConnectThread, nil, 0, Handle);
{$endif}

 InitKeyBoard;

 repeat
  if Keyboard.KeyPressed then
  begin
   Key := GetKeyEvent;
   Key := TranslateKeyEvent(Key);
   if GetKeyEventChar(Key) = kbdReturn then
   begin
    Write(Prefix, MultiLanguageSupport.GetString('MsgCloseSocket') + ' ');
    if Main.Connection.Disconnect then
     Writeln(MultiLanguageSupport.GetString('FieldDone')) else
     Writeln(MultiLanguageSupport.GetString('FieldFail'));
    RTLEventWaitFor(ThreadEvent);
    Break;
   end;
  end else
   Sleep(10);
 until ThreadFree = True;

 DoneKeyBoard;
 RTLEventDestroy(ThreadEvent);
{$ifdef unix}
 UnixConnectThread.Free;
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


function CMD_Status(var Params :TParams) :Longint;
var
 X :Longint;
begin
 Writeln(Prefix, MultiLanguageSupport.GetString('StatusAuthorized') + ' = ', LainClientData.Authorized);
 Writeln(Prefix, MultiLanguageSupport.GetString('StatusConnected') + ' = ', Connection.Connected);
 if Connection.Connected = true then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('StatusHostname') + ' = ', ConsoleHost, '(', Connection.Hostname, ')');
  Writeln(Prefix, MultiLanguageSupport.GetString('StatusPort') + ' = ', Connection.Port);
 end;
 if LainClientData.Authorized = true then
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('StatusUsername') + ' = ', ConsoleUser);
  Write(Prefix, MultiLanguageSupport.GetString('StatusPassword') + ' = ');
  if LainClientData.Password = '' then
   Writeln(MultiLanguageSupport.GetString('FieldEmpty')) else
   begin
    for X := 1 to length(LainClientData.Password) do
    write('*');
    writeln;
   end;
 end;
 Writeln;
 Result := CMD_Done;
end;
 
end.

