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

unit Params;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Md5;
  
var
{$ifdef windows}
 MBInfoTitle :PChar = 'Info';
{$endif}
 UsageAddUser :String = 'Usage: adduser <username> <password>';
 UsageDelUser :String = 'Usage: deluser <username>';
 UsageChkUser :String = 'Usage: chkuser <username>';
 UsagePwdUser :String = 'Usage: pwduser <username> <password>';

 MsgUserAdded :String =        'User added successful';
 MsgUserNoAdded :String =      'Can''t add user';
 MsgUserDeleted :String =      'User deleted succesful';
 MsgUserNotDeleted :String =   'Can''t delete user';
 
 MsgUserNotFound :String =       'User not found';
 MsgUserCheckSumOk :String =     'User MD5Sums are correct';
 MsgUserCheckSumFail :String =   'User MD5Sums aren''t correct';
 MsgUserNoUsers :String =        'No users in database';
 MsgUserNewPasswordSet :String = 'New password set';
 MsgNewDBCreate :String =        'New database created';
 MsgNewDBNotCreate :String =     'Can''t create new database';
 
 
var
 Param :AnsiString;
 
 function LainServerParamAddUser(var OutPut :Text) :Boolean;
 function LainServerParamDelUser(var OutPut :Text) :Boolean;
 function LainServerParamChkUser(var OutPut :Text) :Boolean;
 function LainServerParamLstUser(var OutPut :Text) :Boolean;
 function LainServerParamPwdUser(var OutPut :Text) :Boolean;
 
implementation

uses {$ifdef windows} Windows, {$endif} Main;

function LainServerParamAddUser(var OutPut :Text) :Boolean;
begin
 if ((ParamStr(2) = '') or (ParamStr(3) = '')) then
 begin
 {$ifdef unix}
  Writeln(OutPut, UsageAddUser);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, Pchar(UsageAddUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION)
 {$endif}
  Exit(True);
 end;

 if LainDBControlClass.AddUserToLainDB(ParamStr(2), ParamStr(3)) then
 {$ifdef unix}
  Writeln(OutPut, MsgUserAdded) else
  Writeln(OutPut, MsgUserNoAdded);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserAdded), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgUserNotAdded), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
 Result := True;
end;

function LainServerParamDelUser(var OutPut :Text) :Boolean;
begin
 if (ParamStr(2) = '') then
 begin
 {$ifdef unix}
  Writeln(OutPut, UsageDelUser);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsageDelUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit(True);
 end;
 if LainDBControlClass.DelUserFromLainDB(ParamStr(2)) then
 {$ifdef unix}
  Writeln(OutPut, MsgUserDeleted) else
  Writeln(OutPut, MsgUserNotDeleted);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserDeleted), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgUserNotDeleted), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
 Result := True;
end;

function LainServerParamChkUser(var OutPut :Text) :Boolean;
begin
 if (ParamStr(2) = '') then
 begin
 {$ifdef unix}
  Writeln(OutPut, UsageChkUser);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsageChkUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit(True);
 end;
 if LainDBControlClass.FindUserInLainDB(ParamStr(2)) = -1 then
 begin
 {$ifdef unix}
  Writeln(OutPut, MsgUserNotFound);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNotFound), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit(True);
 end;
 if LainDBControlClass.CheckUserInLainDB(ParamStr(2)) <> -1 then
 {$ifdef unix}
  Writeln(OutPut, MsgUserCheckSumOk) else
  Writeln(OutPut, MsgUserCheckSumFail);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserCheckSumOk), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgUserCheckSumFail), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
 Result := True;
end;

function LainServerParamLstUser(var OutPut :Text) :Boolean;

var
 X :LongWord;
{$ifdef windows}
 UserList :TStringList;
{$endif}
begin
 if Length(LainDBControlClass.AccountList) = 0 then
 begin
 {$ifdef unix}
  Writeln(OutPut, MsgUserNoUsers);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNoUsers), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit(True);
 end;
{$ifdef windows}
 UserList := TStringList.Create;
{$endif}
 for X := 0 to Length(LainDBControlClass.AccountList) - 1 do
 {$ifdef unix}
  Writeln(OutPut, 'User ID = ', X, ' Name = ', LainDBControlClass.AccountList[X].UsernameStr);
 {$endif}
{$ifdef windows}
  UserList.Add('User ID = ' + IntToStr(X) + ' Name = ' + LainDBControlClass.AccountList[X].UsernameStr)
 MessageBox(GetForegroundWindow, PChar(UserList.Text), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 UserList.Free;
{$endif}
 Result := True;
end;

function LainServerParamPwdUser(var OutPut :Text) :Boolean;
var
 X :LongWord;
begin
 if ((ParamStr(2) = '') or (ParamStr(3) = '')) then
 begin
 {$ifdef unix}
  Writeln(OutPut, UsagePwdUser);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsagePwdUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit(True);
 end;
  X := LainDBControlClass.FindUserInLainDB(ParamStr(2));
  if X = -1 then
  begin
  {$ifdef unix}
   Writeln(OutPut, MsgUserNotFound);
  {$endif}
  {$ifdef windows}
   MessageBox(GetForegroundWindow, PChar(MsgUserNotFound), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
  {$endif}
   Exit(True);
  end;
  LainDBControlClass.AccountList[X].Password := MD5String(ParamStr(3));
  LainDBControlClass.AccountList[X].PasswordMD5:= MD5Buffer(LainDBControlClass.AccountList[X].Password, SizeOf(LainDBControlClass.AccountList[X].Password));
 {$ifdef unix}
  Writeln(OutPut, MsgUserNewPasswordSet);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNotFound), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Result := True;
end;

function LainServerParamPwdUser(var OutPut :Text) :Boolean;
begin
 LainDBControlClass.CreateLainDB;
 if LainDBControlClass.SaveLainDBToFile(DataBaseFileName) then
 {$ifdef unix}
  Writeln(OutPut, MsgNewDBCreate) else
  Writeln(OutPut, MsgNewDBNotCreate);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgNewDBCreate), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgNewDBNotCreate), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
 Exit;
end;

end.

