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
 Lain_Ok = 2;


function LainServerQueryEngine(var Connection :TTcpIpCustomConnection; const Value :Longint) :Longint;
 
implementation

uses Execute, Process, SysInfo, Users;

function LainServerQueryEngine(var Connection :TTcpIpCustomConnection; const Value :Longint) :Longint;
begin
 case Value of
  Lain_Execute: Result := LainShellExecuteCmd(Connection);
  Lain_SysInfo_GetInfo: Result := LainShellSystemInformation(Connection);
  Lain_Process_GetList: Result := LainShellProcessGetList(Connection);
/// USERS
  Lain_Users_CAddUser  : Result := CMD_Users_AddUser(Connection);
  Lain_Users_CDelUser  : Result := CMD_Users_DelUser(Connection);
  Lain_Users_CLstUser  : Result := CMD_Users_LstUser(Connection);
  Lain_Users_CCUser    : Result := CMD_Users_CheckUser(Connection);
  Lain_Users_CCUserPwd : Result := CMD_Users_ChangeUserPwd(Connection);
 end;
end;

end.

