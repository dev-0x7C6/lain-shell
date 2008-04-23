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

unit Addons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main, Crt;

 function CMD_Clear(var Params :TParams) :Longint;
 function CMD_Help(var Params :TParams) :Longint;
 function CMD_About(var Params :TParams) :Longint;
 function CMD_Status(var Params :TParams) :Longint;

implementation

uses Extensions, Lang, Network;

function CMD_About(var Params :TParams) :Longint;
begin
 Writeln('  ', MultiLanguageSupport.GetString('MainProgramer'));
 Writeln;
 Writeln('  ', MultiLanguageSupport.GetString('EnLang'));
 Writeln('  ', MultiLanguageSupport.GetString('PlLang'));
 Writeln;
 Result := CMD_Done;
end;

function CMD_Clear(var Params :TParams) :Longint;
begin
 ClrScr;
 PaintConsoleTitle;
 Exit(CMD_Done);
end;

function CMD_Help(var Params :TParams) :Longint;
var
 X :Byte;
begin
 for X := Low(HelpList) to High(HelpList) do
 begin
  Write('  ', HelpList[X][0], ' -   ');
  Writeln(HelpList[X][1]);
 end;
 Writeln;
 Result := 0;
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

