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

unit Process;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils;
  
Const
 Lain_Process_GetList = 30;
 
 function LainShellProcessGetList(var Connection :TTcpIpCustomConnection) :Longint;

implementation

{$ifdef unix}
 uses Unix;
{$endif}
{$ifdef windows}
 uses Windows, ShellApi;
{$endif}

function LainShellProcessGetList(var Connection :TTcpIpCustomConnection) :Longint;

var
 ProcessList :TStringList;
{$ifdef unix}
 Pipe :Text;
 Str :AnsiString;
{$endif}
{$ifdef windows}
{$endif}
begin

 ProcessList := TStringList.Create;
{$ifdef unix}
 POpen(Pipe, 'ps -A', 'R');
 while not Eof(Pipe) do
 begin
  Readln(Pipe, Str);
  ProcessList.Add(Str);
 end;
 PClose(Pipe);
{$endif}
{$ifdef windows}
{$endif}
 Connection.SendString(ProcessList.Text);
 ProcessList.Free;
end;

end.

