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

unit Signals;

{$mode objfpc}{$H+}

interface


uses
 BaseUnix;

 procedure DoSigInt(sig :cint) cdecl;
 procedure DoSigTerm(sig :cint) cdecl;
 procedure DoSigKill(sig :cint) cdecl;
 procedure DoSigPipe(sig :cint) cdecl;
 

implementation

uses Main;

procedure TerminateLainShellServer;
begin
 TerminateApp := True;
end;

procedure DoSigInt(sig :cint) cdecl;
begin
 fpSignal(SigInt, SignalHandler(@DoSigInt));
 TerminateLainShellServer;
end;

procedure DoSigTerm(sig :cint) cdecl;
begin
 fpSignal(SigTerm, SignalHandler(@DoSigTerm));
 TerminateLainShellServer;
end;

procedure DoSigKill(sig :cint) cdecl;
begin
 fpSignal(SigKill, SignalHandler(@DoSigKill));
 TerminateLainShellServer;
end;

procedure DoSigPipe(sig :cint) cdecl;
begin
 fpSignal(SigPipe, SignalHandler(@DoSigPipe));
end;

initialization
begin
 fpSignal(SigInt, SignalHandler(@DoSigInt));
 fpSignal(SigTerm, SignalHandler(@DoSigTerm));
 fpSignal(SigKill, SignalHandler(@DoSigKill));
 fpSignal(SigPipe, SignalHandler(@DoSigPipe));
end;

end.

