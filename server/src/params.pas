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
  {$ifdef unix} BaseUnix, Unix, IPC, {$endif} Classes, SysUtils, Md5;


var
 HelpMsg :String = 'Main functions:' + LineEnding +
                   '  --config  - run configurator' + LineEnding +
                   '  --help    - show this message' + LineEnding +
                   '  --stop    - stop running deamon' + LineEnding + LineEnding  +
                   'User database functions:' + LineEnding +
                   '  --createdb - create empty database' + LineEnding +
                   '  --adduser - add new user' + LineEnding +
                   '  --deluser - delete user' + LineEnding +
                   '  --chkuser - check user md5sums' + LineEnding +
                   '  --lstuser - show user list' + LineEnding +
                   '  --pwduser - change user password';

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

 procedure LainServerParamHelp;
 procedure LainServerParamStop;
 
 procedure LainServerParamCreateDB;
 procedure LainServerParamAddUser;
 procedure LainServerParamDelUser;
 procedure LainServerParamChkUser;
 procedure LainServerParamLstUser;
 procedure LainServerParamPwdUser;
 
implementation

uses {$ifdef windows} Windows, {$endif} Main, Consts, Loop;

procedure LainServerParamHelp;
begin
{$ifdef unix}
 Writeln(HelpMsg, EndLineChar);
{$endif}
{$ifdef windows}
 MessageBox(GetForegroundWindow, PChar(HelpMsg), 'Help page', MB_OK + MB_ICONINFORMATION);
{$endif}
end;

procedure LainServerParamStop;
begin
{$ifdef unix}
 UnixMainLoopKill;
{$endif}
{$ifdef windows}
{$endif}
end;

procedure LainServerParamAddUser;
begin
 if ((ParamStr(2) = '') or (ParamStr(3) = '')) then
 begin
 {$ifdef unix}
  Writeln(UsageAddUser, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, Pchar(UsageAddUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
 end;

 if LainDBControlClass.AddUserToLainDB(ParamStr(2), ParamStr(3)) then
 {$ifdef unix}
  Writeln(MsgUserAdded, EndLineChar) else
  Writeln(MsgUserNoAdded, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserAdded), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgUserNoAdded), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
end;

procedure LainServerParamDelUser;
begin
 if (ParamStr(2) = '') then
 begin
{$ifdef unix}
  Writeln(UsageDelUser, EndLineChar);
{$endif}
{$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsageDelUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
{$endif}
  Exit;
 end;
 if LainDBControlClass.DelUserFromLainDB(ParamStr(2)) then
{$ifdef unix}
 Writeln(MsgUserDeleted, EndLineChar) else
 Writeln(MsgUserNotDeleted, EndLineChar);
{$endif}
{$ifdef windows}
 MessageBox(GetForegroundWindow, PChar(MsgUserDeleted), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
 MessageBox(GetForegroundWindow, PChar(MsgUserNotDeleted), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
{$endif}
end;

procedure LainServerParamChkUser;
begin
 if (ParamStr(2) = '') then
 begin
 {$ifdef unix}
  Writeln(UsageChkUser, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsageChkUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
 if LainDBControlClass.FindUserInLainDB(ParamStr(2)) = -1 then
 begin
 {$ifdef unix}
  Writeln(MsgUserNotFound, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNotFound), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
 if LainDBControlClass.CheckUserInLainDB(ParamStr(2)) <> -1 then
 {$ifdef unix}
  Writeln(MsgUserCheckSumOk, EndLineChar) else
  Writeln(MsgUserCheckSumFail, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserCheckSumOk), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgUserCheckSumFail), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
end;

procedure LainServerParamLstUser;

var
 X :LongWord;
{$ifdef windows}
 UserList :TStringList;
{$endif}
begin
 if Length(LainDBControlClass.AccountList) = 0 then
 begin
 {$ifdef unix}
  Writeln(MsgUserNoUsers, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNoUsers), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
{$ifdef windows}
 UserList := TStringList.Create;
{$endif}
 for X := 0 to Length(LainDBControlClass.AccountList) - 1 do
 {$ifdef unix}
  Writeln('User ID = ', X, ' Name = ', LainDBControlClass.AccountList[X].UsernameStr, EndLineChar);
 {$endif}
{$ifdef windows}
  UserList.Add('User ID = ' + IntToStr(X) + ' Name = ' + LainDBControlClass.AccountList[X].UsernameStr);
 MessageBox(GetForegroundWindow, PChar(UserList.Text), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 UserList.Free;
{$endif}
end;

procedure LainServerParamPwdUser;
var
 X :LongWord;
begin
 if ((ParamStr(2) = '') or (ParamStr(3) = '')) then
 begin
 {$ifdef unix}
  Writeln(UsagePwdUser, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(UsagePwdUser), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
 X := LainDBControlClass.FindUserInLainDB(ParamStr(2));
 if X = -1 then
 begin
 {$ifdef unix}
  Writeln(MsgUserNotFound, EndLineChar);
 {$endif}
 {$ifdef windows}
  MessageBox(GetForegroundWindow, PChar(MsgUserNotFound), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
 {$endif}
  Exit;
 end;
 LainDBControlClass.AccountList[X].Password := MD5String(ParamStr(3));
 LainDBControlClass.AccountList[X].PasswordMD5:= MD5Buffer(LainDBControlClass.AccountList[X].Password, SizeOf(LainDBControlClass.AccountList[X].Password));
{$ifdef unix}
 Writeln(MsgUserNewPasswordSet, EndLineChar);
{$endif}
{$ifdef windows}
 MessageBox(GetForegroundWindow, PChar(MsgUserNewPasswordSet), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
{$endif}
end;

procedure LainServerParamCreateDB;
begin
 LainDBControlClass.CreateLainDB;
{$ifdef unix}
 if LainDBControlClass.SaveLainDBToFile(DataBaseFileName) then
  Writeln(MsgNewDBCreate, EndLineChar) else
  Writeln(MsgNewDBNotCreate, EndLineChar);
{$endif}
{$ifdef windows}
 if LainDBControlClass.SaveLainDBToRegistry(RegistryKey, RegistryValue) then
  MessageBox(GetForegroundWindow, PChar(MsgNewDBCreate), MBInfoTitle, MB_OK + MB_ICONINFORMATION) else
  MessageBox(GetForegroundWindow, PChar(MsgNewDBNotCreate), MBInfoTitle, MB_OK + MB_ICONINFORMATION);
{$endif}
end;

end.

