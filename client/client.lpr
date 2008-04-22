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
 Classes, SysUtils, CustApp, NetUtils, Main, Authorize, Extensions, CConnect,
 CAddons, lang, CEngine, cserver, Crt, threads;

type
 TUniStrikeApp = class(TCustomApplication)
 protected
   procedure DoRun; override;
 public
   constructor Create(TheOwner: TComponent); override;
   destructor Destroy; override;
 end;

{ TUniStrikeApp }

procedure TUniStrikeApp.DoRun;
begin
 MainFunc;
 Terminate;
end;

constructor TUniStrikeApp.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 StopOnException := True;
end;

destructor TUniStrikeApp.Destroy;
begin
 inherited Destroy;
end;

var
 Application: TUniStrikeApp;
begin
 Application := TUniStrikeApp.Create(nil);
 Application.Title := 'Lain Shell Client';
 Application.Run;
 Application.Free;
end.

