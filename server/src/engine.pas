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

unit Engine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils;

Const
 Lain_Error = -1;
 Lain_Disconnect = 0;
 Lain_Logoff = 1;
 Lain_Ok;


function LainServerRecvQuery(var Connection :TTcpIpCustomConnection) :Longint;
function LainServerQueryEngine(var Connection :TTcpIpCustomConnection; Value :Word) :Longint;
 
implementation

uses Shell;

function LainServerRecvQuery(var Connection :TTcpIpCustomConnection) :Longint;
var
 Value :Word;
begin
 Value := 2;
 while ((Value = Lain_Disconnect) or (Value = Lain_Logoff)) <> True do
 begin
  if Connection.Recv(Value, SizeOf(Value)) <> SizeOf(Value) then
   Exit(Lain_Error);
  if Connection.Send(Value, SizeOf(Value)) <> SizeOf(Value) then
   Exit(Lain_Error);
 end;
 Result := Value;
end;

function LainServerQueryEngine(var Connection :TTcpIpCustomConnection; Value :Word) :Longint;
begin
 case Value of
  Lain_Shell_List: Result := LainShellList(Connection);
 end;
end;

end.

