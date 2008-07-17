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

unit NetUtils;

{$mode objfpc}{$H+}

interface

uses
{$ifdef unix} Unix, libC, {$endif}{$ifdef windows} WinSock, {$endif} Classes,
 SysUtils, Sockets;

const
 INVALID_SOCKET = -1;

type
 TTransmissionInfo = packed record
  Size :int64;
  PieceSize :integer;
 end;

type
 TBuffer = Array Of Byte;

type
 TConnection = packed record
  Sock :Longint;
  Addr :TInetSockAddr;
 end;

type
 TSocketEvent = procedure(P :Pointer);
 TOnAcceptedEvent = procedure(Connection :TConnection);


type
 TTcpIpSocketClient = class
 private
  FConnected :Boolean;
  FConnecting :Boolean;
  FHostname :WideString;
  FLastError :Longint;
  FPort :Word;
  FRecvFlags :Longint;
  FSendFlags :Longint;
  FSocketOpen :Boolean;
  FOnError :TSocketEvent;
  FOnConnected :TSocketEvent;
  FOnDisconnect :TSocketEvent;
 protected
  Addr :TINetSockAddr;
  Sock :Longint;
  function GetLastError :Longint;
  procedure SetLastError(Value :Longint);
 public
  constructor Create;
  destructor Destroy; override;
  property Connected :Boolean read FConnected;
  property Connecting :Boolean read FConnecting;
  property LastError :Longint read GetLastError;
  property Hostname :WideString read FHostname write FHostname;
  property Port :Word read FPort write FPort;
  property RecvFlags :Longint read FRecvFlags write FRecvFlags;
  property SendFlags :Longint read FSendFlags write FSendFlags;
  property SocketOpen :Boolean read FSocketOpen write FSocketOpen;
  property OnConnected :TSocketEvent read FOnConnected write FOnConnected;
  property OnDisconnect :TSocketEvent read FOnDisconnect write FOnDisconnect;
  property OnError :TSocketEvent read FOnError write FOnError;
  function Connect :Boolean;
  function Disconnect :Boolean;
  function GetConnection :TConnection;
  function Recv(var Buffer; Size :Longint) :Longint;
  function RecvStream(Stream :TStream) :Boolean;
  function RecvString(var Dest :AnsiString) :Boolean;
  function Send(const Buffer; Size :Longint) :Longint;
  function SendStream(Stream :TStream) :Boolean;
  function SendString(Source :AnsiString) :Boolean;
 end;
 
 TTcpIpCustomConnection = class(TTcpIpSocketClient)
 public
  procedure SetConnection(Connection :TConnection);
 end;

 TTcpIpSocketServer = class
 private
  FIsWorking :Boolean;
  FMaxConnections :Longint;
  FLastError :Longint;
  FPort :Word;
  FOnAccepted :TOnAcceptedEvent;
  FOnError :TSocketEvent;
  FOnStartServer :TSocketEvent;
  FOnStopServer :TSocketEvent;
  Addr :TInetSockAddr;
  Sock :Longint;
 protected
  function GetLastError :Longint;
  procedure SetLastError(Value :Longint);
 public
  constructor Create;
  destructor Destroy; override;
  property IsWorking :Boolean read FIsWorking write FIsWorking;
  property MaxConnections :Longint read FMaxConnections write FMaxConnections;
  property Port :Word read FPort write FPort;
  property OnAccepted :TOnAcceptedEvent read FOnAccepted write FOnAccepted;
  property OnError :TSocketEvent read FOnError write FOnError;
  property OnStartServer :TSocketEvent read FOnStartServer write FOnStartServer;
  property OnStopServer :TSocketEvent read FOnStopServer write FOnStopServer;
  procedure Start;
  procedure Shutdown;
  procedure CloseSocket;
 end;
 
 function GetIpByHost(host : PChar) : WideString;


 function ExtractHostFromHostName(const HostName :AnsiString) :AnsiString;
 function ExtractPortFromHostName(const HostName :AnsiString) :Longint;
 
implementation

 function GetIpByHost(Host : PChar) : WideString;
 var
  h: PHostEnt;
  p: PChar;
  i: Integer;
 begin
  GetIpByHost:='';
  h := GetHostByName(Host);
  if not (h = nil) then
  begin
   p := h^.H_Addr[0];
   for I := 0 to 3 do
    GetIpByHost += IntToStr(Byte(p[i])) + '.';
   delete(getipbyhost, length(getipbyhost), 1);
  end;
 end;
 
 
 function ExtPos(Value :Char; Src :AnsiString) :Longint;
 var
  X :Longint;
 begin
  if Length(Src) > 0 then
  begin
   for X := 1 to Length(Src) do
    if Src[X] = Value then
    begin
     Result := X;
     Break;
    end;
  end else
   Result := 0;
 end;

 function ExtractHostFromHostName(const HostName :AnsiString) :AnsiString;
 var
  Offset :Longint;
 begin
  Offset := ExtPos(':', HostName) - 1;
  if Offset > -1 then
   Result := Copy(HostName, 1, Offset) else
   Result := Hostname;
 end;
 
 function ExtractPortFromHostName(const HostName :AnsiString) :Longint;
 var
  Offset :Longint;
 begin
  Offset := ExtPos(':', HostName) + 1;
  if Offset > 1 then
   Result := StrToIntDef(Copy(Hostname, Offset, Length(Hostname) - (Offset - 1)), -1) else
   Result := -1;
 end;
 
 function Net_Connect(Sock: LongInt; const Addr; Addrlen: LongInt) :Boolean;
 begin
  Result := (FPConnect(Sock, @Addr, AddrLen) = 0);
 end;

// TTcpIPSocketClient //////////////////////////////////////////////////////////

 constructor TTcpIpSocketClient.Create;
 begin
  inherited Create;
  {$ifdef unix}
   FRecvFlags := MSG_WAITALL;
  {$endif}
  {$ifdef windows}
   FRecvFlags := 0;
  {$endif}
  FSendFlags := 0;
  FConnected := False;
  FConnecting := False;
  FLastError := 0;
  FHostname := '';
  FPort := 0;
  FSocketOpen := False;
  FOnError := nil;
  FOnConnected := nil;
  FOnDisconnect := nil;
 end;
 
 destructor TTcpIpSocketClient.Destroy;
 begin
  inherited Destroy;
 end;
 
 function TTcpIpSocketClient.GetLastError :Longint;
 begin
  Result := FLastError;
  FLastError := 0;
 end;
 
 procedure TTcpIpSocketClient.SetLastError(Value :Longint);
 begin
  FLastError := Value;
  if Assigned(FOnError) then FOnError(Self);
  Disconnect;
 end;
 
 function TTcpIpSocketClient.Connect :Boolean;
 var
  AddrSize :Longint;
 begin
  if FConnected or FConnecting then
   Disconnect;
  FConnecting := True;
  Sock := Socket(AF_INET, SOCK_STREAM, 0);
  if Sock = INVALID_SOCKET then
  begin
   FConnected := False;
   SetLastError(SocketError);
   Exit(False);
  end;
  FSocketOpen := True;
  AddrSize := SizeOf(TINetSockAddr);
  Addr.Family := AF_INET;
  Addr.Port := HTons(FPort);
  Addr.Sin_addr := HostToNet(StrToHostAddr(FHostname));
  FConnected := Net_Connect(Sock, Addr, AddrSize);
  FConnecting := False;
  Result := FConnected;
  if FConnected then
   if Assigned(FOnConnected) then FOnConnected(Self) else
   if Assigned(FOnError) then FOnError(Self);
 end;
 
 function TTcpIpSocketClient.Disconnect :Boolean;
 begin
  if FConnected or FConnecting or FSocketOpen then
  begin
   Shutdown(Sock, 2);
   if CloseSocket(Sock) = 0 then
    Result := True else
    Result := False;
   FConnected := False;
   FConnecting := False;
   FSocketOpen := False;
   if Assigned(FOnDisconnect) then FOnDisconnect(Self);
  end else
   Result := False;
 end;

 {$ifdef unix}
 // {$define debug}
 {$endif}
 
 function TTcpIpSocketClient.Recv(var Buffer; Size :Longint) :Longint;
 begin
  if FConnected then
  begin
   Result := Sockets.Recv(Sock, Buffer, Size, FRecvFlags);
   {$ifdef debug}
    writeln('Sock = ', Sock,'; Recv = ', Result);
   {$endif}
   if ((SocketError <> 0) and (Result <= 0)) then
   begin
    SetLastError(SocketError);
    Disconnect;
   end;
   
  end;
 end;
 
 function TTcpIpSocketClient.Send(const Buffer; Size :Longint) :Longint;
 begin
  if FConnected then
  begin
   Result := Sockets.SendTo(Sock, Buffer, Size, FSendFlags, Addr, SizeOf(Addr));
   {$ifdef debug}
    writeln('Sock = ', Sock,'; Send = ', Result);
   {$endif}
   if ((SocketError <> 0) and (Result <= 0)) then
   begin
    SetLastError(SocketError);
    Disconnect;
   end;

  end;
 end;

 function TTcpIpSocketClient.SendStream(Stream :TStream) :Boolean;
 var
  TransmissionInfo :TTransmissionInfo;
  PBufferSize :Integer;
  PBuffer :^TBuffer;
  Loop :Longint;
  LoopCount :Longint;
  Rest :longint;
  Stat :boolean;
 begin
  if ((Connected = False) or (Stream = nil)) then
  begin
   Result := False;
   Exit;
  end;

  Stream.Seek(0, 0);

  TransmissionInfo.Size := Stream.Size;
  TransmissionInfo.PieceSize := 1460;

  {$I-}
   LoopCount := TransmissionInfo.Size div TransmissionInfo.PieceSize;
   Rest := TransmissionInfo.Size mod TransmissionInfo.PieceSize;
  {$I+}

  if IOResult <> 0 then
   Stat := False else
   Stat := True;

  GetMem(pbuffer, transmissionInfo.PieceSize);
  Stat := Stat and (PBuffer <> nil);

  if Send(stat, sizeof(stat)) <> SizeOf(Stat) then
  begin
   if PBuffer <> nil then FreeMem(pbuffer, transmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  if (Stat = False) then
  begin
   if PBuffer <> nil then FreeMem(pbuffer, transmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  if Send(transmissionInfo, sizeof(transmissionInfo)) <> SizeOf(TransmissionInfo) then
  begin
   FreeMem(pbuffer, transmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  if Recv(stat, sizeof(stat)) <> SizeOf(Stat) then
  begin
   FreeMem(pbuffer, transmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  if (Stat <> True) then
  begin
   FreeMem(pbuffer, transmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  for Loop := 0 to (LoopCount - 1) do
  begin
   PBufferSize := Stream.Read(PBuffer^, TransmissionInfo.PieceSize);

   if Send(PBuffer^, PBufferSize) <> PBufferSize then
   begin
    FreeMem(pbuffer, transmissionInfo.PieceSize);
    Stream.Seek(0, 0);
    Exit;
   end;

  end;

  if (Rest <> 0) then
  begin
   PBufferSize := Stream.Read(PBuffer^, Rest);

   if Send(PBuffer^, Rest) <> Rest then
   begin
    FreeMem(pbuffer, transmissionInfo.PieceSize);
    Stream.Seek(0, 0);
    Exit;
   end;

  end;

  FreeMem(pbuffer, transmissionInfo.PieceSize);
  Stream.Seek(0, 0);
  Result := Connected;

 end;

 function TTcpIpSocketClient.RecvStream(Stream :TStream) :Boolean;
 var
  TransmissionInfo :TTransmissionInfo;
  PBuffer :^TBuffer;
  Loop :Longint;
  LoopCount :Longint;
  Rest :longint;
  Stat :boolean;
 begin

  if ((Connected = False) or (Stream = nil)) then
  begin
   Result := False;
   Exit;
  end;

  Stream.Seek(0, 0);

  if Recv(stat, sizeof(stat)) <> SizeOf(Stat) then
  begin
   Result := False;
   Exit;
  end;

  if Recv(transmissionInfo, sizeof(TransmissionInfo)) <> SizeOf(TransmissionInfo) then
  begin
   Result := False;
   Exit;
  end;

  if ((transmissionInfo.Size <= 0) or (transmissionInfo.PieceSize <= 0)) then
   stat := false else
   stat := true;

  {$I-}
   loopcount := transmissionInfo.Size div transmissionInfo.PieceSize;
   rest := transmissionInfo.Size mod transmissionInfo.PieceSize;
  {$I+}

  if IOResult <> 0 then
   stat := stat and false else
   stat := stat and true;

  GetMem(PBuffer, TransmissionInfo.PieceSize);
  Stat := Stat and (PBuffer <> nil);

  if Send(Stat, Sizeof(stat)) <> SizeOf(Stat) then
  begin
   if PBuffer <> nil then FreeMem(PBuffer, TransmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  if (Stat = False) then
  begin
   if PBuffer <> nil then FreeMem(PBuffer, TransmissionInfo.PieceSize);
   Result := False;
   Exit;
  end;

  for Loop := 0 to (LoopCount - 1) do
  begin
   if Recv(PBuffer^, TransmissionInfo.PieceSize) <> TransmissionInfo.PieceSize then
   begin
    FreeMem(PBuffer, TransmissionInfo.PieceSize);
    Result := False;
    Exit;
   end;
   Stream.WriteBuffer(PBuffer^, TransmissionInfo.PieceSize);
  end;

  if (Rest <> 0) then
  begin
   if Recv(PBuffer^, Rest) <> Rest then
   begin
    FreeMem(PBuffer, Rest);
    Result := False;
    Exit;
   end;
   Stream.WriteBuffer(PBuffer^, Rest);
  end;

  FreeMem(PBuffer, TransmissionInfo.PieceSize);
  Stream.Seek(0, 0);
  Result := Connected;
 end;

 function TTcpIpSocketClient.SendString(Source :AnsiString) :Boolean;
 var
  Stream :TMemoryStream;
 begin
  Stream := TMemoryStream.Create;
  Stream.WriteAnsiString(Source);
  Result := SendStream(Stream);
  Stream.Free;
 end;

 function TTcpIpSocketClient.RecvString(var Dest :AnsiString) :Boolean;
 var
  Stream :TMemoryStream;
 begin
  Stream := TMemoryStream.Create;
  Result := RecvStream(stream);
  Stream.Seek(0 ,0);
  Dest := Stream.ReadAnsiString;
  Stream.Free;
 end;
 
 function TTcpIpSocketClient.GetConnection :TConnection;
 begin
  Result.Sock := Sock;
  Result.Addr := Addr;
 end;
 
// TTcpIpCustomConnection //////////////////////////////////////////////////////
 
 procedure TTcpIpCustomConnection.SetConnection(Connection :TConnection);
 begin
  Addr := Connection.Addr;
  Sock := Connection.Sock;
  FConnected := True;
  FSocketOpen := True;
 end;
 
// TTcpIpSocketServer //////////////////////////////////////////////////////////

 constructor TTcpIpSocketServer.Create;
 begin
  inherited Create;
  FIsWorking := False;
  FMaxConnections := 0;
  FLastError := 0;
  FPort := 0;
  FOnAccepted := nil;
  FOnError := nil;
  FOnStartServer := nil;
  FOnStopServer := nil;
 end;
 
 destructor TTcpIpSocketServer.Destroy;
 begin
  Shutdown;
  CloseSocket;
  inherited Destroy;
 end;

 function TTcpIpSocketServer.GetLastError :Longint;
 begin
  Result := FLastError;
  FLastError := 0;
 end;
 
 procedure TTcpIpSocketServer.SetLastError(Value :Longint);
 begin
  FLastError := Value;
  if Assigned(FOnError) then FOnError(Self);
 end;
 
 procedure TTcpIpSocketServer.Start;
 var
  AddrSize :Longint;
  Connection :TConnection;
 begin
  Sock := Socket(AF_INET, SOCK_STREAM, 0);
  if (Sock = INVALID_SOCKET) then
  begin
   SetLastError(SocketError);
   Exit;
  end;

  AddrSize := SizeOf(TINetSockAddr);
  Addr.Family := AF_INET;
  Addr.Addr := INADDR_ANY;
  Addr.Port := HTons(FPort);
  
  if not Sockets.Bind(Sock, Addr, AddrSize) then
  begin
   SetLastError(SocketError);
   Exit;
  end;
  
  if not Sockets.Listen(Sock, FMaxConnections) then
  begin
   SetLastError(SocketError);
   Exit;
  end;
  FIsWorking := True;
  if Assigned(FOnStartServer) then FOnStartServer(Self);
  repeat
   Connection.Sock := Sockets.Accept(Sock, Connection.Addr, AddrSize);
   if ((Connection.Sock <> INVALID_SOCKET) and (SocketError = 0)) then
   begin
    if Assigned(FOnAccepted) then FOnAccepted(Connection);
   end;
   
  until Sock = INVALID_SOCKET;
  FIsWorking := False;
  if Assigned(FOnStopServer) then FOnStopServer(Self);
 end;
 
 procedure TTcpIpSocketServer.Shutdown;
 begin
  if Sock <> INVALID_SOCKET then
   Sockets.Shutdown(Sock, 2);
 end;
 
 procedure TTcpIpSocketServer.CloseSocket;
 begin
  if Sock <> INVALID_SOCKET then
  begin
   Sockets.CloseSocket(Sock);
   Sock := INVALID_SOCKET;
  end;
 end;
 
 
end.

