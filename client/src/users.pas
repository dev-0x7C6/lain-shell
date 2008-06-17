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
  Classes, SysUtils, Main;
  
const
 CMDUsers = 'users';
 
 Lain_Users_CAddUser = 40;
 Lain_Users_CDelUser = 41;
 Lain_Users_CLstUser = 42;
 Lain_Users_CCUser = 43;
 Lain_Users_CCUserPwd = 44;

 function CMD_UsersCase(var Params :TParams) :Longint;
 function CMD_Users_AddUser(var Params :TParams) :Longint;
 function CMD_Users_AddUser_Query :Longint;
 function CMD_Users_DelUser(var Params :TParams) :Longint;
 function CMD_Users_DelUser_Query :Longint;
 function CMD_Users_LstUser(var Params :TParams) :Longint;
 function CMD_Users_LstUser_Query :Longint;
 function CMD_Users_CheckUser(var Params :TParams) :Longint;
 function CMD_Users_CheckUser_Query :Longint;
 function CMD_Users_ChangeUserPwd(var Params :TParams) :Longint;
 function CMD_Users_ChangeUserPwd_Query :Longint;


implementation

uses Extensions, Engine, Lang;

 function CMD_UsersCase(var Params :TParams) :Longint;
 var
  Param :String;
 begin
  if CheckConnectionAndAuthorization = False then
   Exit(CMD_Fail);
   
  if Length(Params) > 1 then
  begin
   if LowerCase(Params[0]) = 'users' then
   begin
    Param := LowerCase(Params[1]);
    if Param = 'adduser' then Result := CMD_Users_AddUser(Params) else
    if Param = 'deluser' then Result := CMD_Users_DelUser(Params) else
    if Param = 'lstuser' then Result := CMD_Users_LstUser(Params) else
    if Param = 'chkuser' then Result := CMD_Users_CheckUser(Params) else
    if Param = 'passwd' then Result := CMD_Users_ChangeUserPwd(Params) else
     Result := CMD_Done;
   end;
  end;
 end;

 function SendQuery(const Query :Word) :Longint;
 begin
  Writeln(Prefix, MultiLanguageSupport.GetString('MsgWaitForResponse'), EndLineChar);
  Result := LainClientSendQuery(Query);
  LainClientWaitForQuery;
 end;

 function CMD_Users_AddUser(var Params :TParams) :Longint;
 begin
  Result := SendQuery(Lain_Users_CAddUser);
 end;
 
 function CMD_Users_DelUser(var Params :TParams) :Longint;
 begin
  Result := SendQuery(Lain_Users_CDelUser);
 end;
 
 function CMD_Users_LstUser(var Params :TParams) :Longint;
 begin
  Result := SendQuery(Lain_Users_CLstUser);
 end;
 
 function CMD_Users_CheckUser(var Params :TParams) :Longint;
 begin
  Result := SendQuery(Lain_Users_CCUser);
 end;
 
 function CMD_Users_ChangeUserPwd(var Params :TParams) :Longint;
 begin
  Result := SendQuery(Lain_Users_CCUserPwd);
 end;
 
 function RecvResponse :Boolean;
 var
  Response :Boolean;
 begin
  Writeln(Prefix, 'Receiving response...', EndLineChar);                        /// MLS
  Response := False;
  Connection.Recv(Response, SizeOf(Response));
  Result := Response;
 end;
 
 function CMD_Users_AddUser_Query :Longint;
 var
  Username :AnsiString;
  Password :AnsiString;
  Response :Boolean;
 begin
  Writeln(Prefix, 'Create new profile', EndLineChar);                           /// MLS
  Writeln(EndLineChar);
  Write(Prefix, 'Profile name: '); Read(Username); Write(EndLineChar);          /// MLS
  Write(Prefix, 'Password: '); Read(Password); Write(EndLineChar);              /// MLS
  Writeln(EndLineChar);
  Writeln(Prefix, 'Sending data', EndLineChar);                                 /// MLS
  Connection.SendString(Username);
  Connection.SendString(Password);
  if RecvResponse  = true then
   Writeln(Prefix, 'Add new user successful', EndLineChar) else                 /// MLS
   Writeln(Prefix, 'Can''t add new user', EndLineChar);                         /// MLS
 end;
 
 function CMD_Users_DelUser_Query :Longint;
 var
  Name :AnsiString;
  Response :Boolean;
 begin;
  Writeln(Prefix, 'Delete profile', EndLineChar);                               /// MLS
  Writeln(EndLineChar);
  Write(Prefix, 'Profile name: '); Read(Name); Writeln(EndLineChar);            /// MLS
  Writeln(Prefix, 'Sending data', EndLineChar);                                 /// MLS
  Connection.SendString(Name);
  if RecvResponse = True then
   Writeln(Prefix, 'Delete profile successful', EndLineChar) else               /// MLS
   Writeln(Prefix, 'Can''t delete profile', EndLineChar);                       /// MLS
 end;
 
 function CMD_Users_LstUser_Query :Longint;
 var
  List :AnsiString;
 begin
  Connection.RecvString(List);
  Writeln(List);
 end;

 
 function CMD_Users_CheckUser_Query :Longint;
 begin
 end;

 
 function CMD_Users_ChangeUserPwd_Query :Longint;
 begin
 end;
 
end.

