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

program UniServer;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  CThreads,
{$endif}
{$ifdef windows}
  Windows,
{$endif}
  Main, SysUtils, authorize, FSUtils, NetUtils, Engine;

begin
 ClientConnection := TTcpIpSocketClient.Create;
 ServerConnection := TTcpIpSocketServer.Create;
 
 ClientServiceSettings.Hostname := '127.0.0.1';
 ClientServiceSettings.Port := 9897;
 ServerServiceSettings.MaxConnections := 0;
 ServerServiceSettings.Port := 9896;
 
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

/// at the moment, the server app is only for tests
{$ifdef unix}
 Writeln('Press Enter to exit');
 Readln;
{$endif}
{$ifdef windows}
 while true do sleep(100);
{$endif}
end.

