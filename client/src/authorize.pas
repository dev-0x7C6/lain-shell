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

unit Authorize;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

 function OnAuthorize :Longint;

implementation

uses Main, Lang;

 function OnAuthorize :Longint;
 var
  ControlSum :Longword;
  Verfication :Byte;
  
  procedure OnExit;
  begin
   writeln(Prefix, MultiLanguageSupport.GetString('MsgCantAuthorize'));
  end;
  
 begin
  ControlSum := $F8D6;
  if Connection.Send(ControlSum, SizeOf(ControlSum)) = SizeOf(ControlSum) then
  if Connection.Recv(Verfication, SizeOf(Verfication)) = SizeOf(Verfication) then
  if Verfication = Byte(True) then
  begin
   if Connection.Send(UserIdent, SizeOf(UserIdent)) = SizeOf(UserIdent) then
   if Connection.Recv(Verfication, SizeOf(Verfication)) = SizeOf(Verfication) then
   if Verfication = Byte(True) then
   begin
    LainClientData.Authorized := True;
    Writeln(Prefix, MultiLanguageSupport.GetString('MsgAuthorized'));
    Exit(CMD_Done);
   end else
   begin
    LainClientData.Authorized := False;
    OnExit;
    Exit(CMD_Fail);
   end;
  end;
  
  OnExit;
  Exit(CMD_Fail);
 end;

end.

