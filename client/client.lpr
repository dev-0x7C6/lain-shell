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

program LainClient;

{$mode objfpc}{$H+}

uses
{$IFDEF UNIX}
  cthreads,
{$ENDIF}
{$ifdef windows}
 Windows,
{$endif}
 Classes, SysUtils, CustApp, Main, Extensions, Lang, Threads, Network,
 Engine, execute, sysinfo, process, NetUtils, Md5;

type
 TLainShellClient = class(TCustomApplication)
 protected
   procedure DoRun; override;
 public
   constructor Create(TheOwner: TComponent); override;
   destructor Destroy; override;
 end;

procedure TLainShellClient.DoRun;
begin

{$ifdef windows}
 Variables := Variables + '\CodePage';
{$endif}
 LainClientInitQueryEngine;
 MultiLanguageSupport := nil;
 MultiLanguageInit;

 Connection := TTcpIpCustomConnection.Create;
 FillChar(UserIdent, SizeOf(UserIdent), 0);
 LainClientData.Authorized := False;
 LainClientData.Username := '';
 LainClientData.Password := '';
 LainClientData.Hostname := '';
 LainClientData.Port := '';
 UserIdent.Username := MD5String('');
 UserIdent.Password := MD5String('');
 MainFunc;
 

 if LainClientData.Authorized = True then
 begin
  CMD_Logout(Main.Params);
 end;
 LainClientDoneQueryEngine(1000);
 
 if Connection.Connected = True then
 begin
  CMD_Disconnect(Main.Params);
 end;

 MultiLanguageSupport.Free;
 Connection.Free;
 Writeln(EndLineChar);
 Terminate;
end;

constructor TLainShellClient.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 StopOnException := True;
end;

destructor TLainShellClient.Destroy;
begin
 inherited Destroy;
end;

var
 LainShellClient: TLainShellClient;
 
begin
 InitCriticalSection(CriticalSection);
 LainShellClient := TLainShellClient.Create(nil);
 LainShellClient.Title := 'Lain Shell Client';
 LainShellClient.Run;
 LainShellClient.Free;
 DoneCriticalSection(CriticalSection);
end.

