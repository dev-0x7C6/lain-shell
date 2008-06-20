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

unit Users;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NetUtils;

const
 Lain_Users_CAddUser = 40;
 Lain_Users_CDelUser = 41;
 Lain_Users_CLstUser = 42;
 Lain_Users_CCUser = 43;
 Lain_Users_CCUserPwd = 44;
  
 function CMD_Users_AddUser(var Connection :TTcpIpCustomConnection) :Longint;
 function CMD_Users_DelUser(var Connection :TTcpIpCustomConnection) :Longint;
 function CMD_Users_LstUser(var Connection :TTcpIpCustomConnection) :Longint;
 function CMD_Users_CheckUser(var Connection :TTcpIpCustomConnection) :Longint;
 function CMD_Users_ChangeUserPwd(var Connection :TTcpIpCustomConnection) :Longint;
 procedure SaveState;
  
var
{$ifdef unix}
 LainDirectory :String;
{$endif}
  
implementation

uses LainDataBase, Main, Consts, Md5;

 procedure SaveState;
 begin
 {$ifdef unix}
  LainDBControlClass.SaveLainDBToFile(LainDirectory + DataBaseFileName);
 {$endif}
 {$ifdef windows}
  LainDBControlClass.SaveLainDBToRegistry(RegistryKey, RegistryValue);
 {$endif}
 end;

 function CMD_Users_AddUser(var Connection :TTcpIpCustomConnection) :Longint;
 var
  Username :AnsiString;
  Password :AnsiString;
  Operation :Boolean;
 begin
  Connection.RecvString(Username);
  Connection.RecvString(Password);
  Operation := LainDBControlClass.AddUserToLainDB(Username, Password);
  if Operation then
   SaveState;
  Connection.Send(Operation, SizeOf(Operation));
 end;

 function CMD_Users_DelUser(var Connection :TTcpIpCustomConnection) :Longint;
 var
  Username :AnsiString;
  Operation :Boolean;
 begin
  Connection.RecvString(Username);
  Operation := LainDBControlClass.DelUserFromLainDB(Username);
  if Operation then
   SaveState;
  Connection.Send(Operation, SizeOf(Operation));
 end;

 function CMD_Users_LstUser(var Connection :TTcpIpCustomConnection) :Longint;
 var
  UserList :TStringList;
  X :Longint;
 begin;
  UserList := TStringList.Create;
  for X := 0 to Length(LainDBControlClass.AccountList) - 1 do
   UserList.Add(LainDBControlClass.AccountList[X].UsernameStr);
  Connection.SendString(UserList.Text);
  UserList.Free;
 end;

 function CMD_Users_CheckUser(var Connection :TTcpIpCustomConnection) :Longint;
 var
  Username :AnsiString;
  Operation :Boolean;
 begin
  Connection.RecvString(Username);
  Operation := LainDBControlClass.CheckUserInLainDB(Username) <> -1;
  if Operation then
   SaveState;
  Connection.Send(Operation, SizeOf(Operation));
 end;

 function CMD_Users_ChangeUserPwd(var Connection :TTcpIpCustomConnection) :Longint;
 var
  Username :AnsiString;
  Password :AnsiString;
  Operation :Boolean;
  X :Longint;
 begin
  Connection.RecvString(Username);
  Connection.RecvString(Password);
  X := LainDBControlClass.FindUserInLainDB(Username);
  Operation := (X <> -1);
  if Operation then
  begin
   LainDBControlClass.AccountList[X].Password := MD5String(ParamStr(3));
   LainDBControlClass.AccountList[X].PasswordMD5:= MD5Buffer(LainDBControlClass.AccountList[X].Password, SizeOf(LainDBControlClass.AccountList[X].Password));
   SaveState;
  end;
  
  Connection.Send(Operation, SizeOf(Operation));
 end;

end.

