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

unit Security;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MD5;

Const
 DBFileHead :Array[0..2] of Char = 'LDB';

Const
 HeadOffset = 0000;
 NumOffset  = 0000 + SizeOf(DBFileHead);
 

type
 TUserAccount = packed record
  UsernameStr :Array[0..63] of Char;
  UsernameMD5 :TMD5Digest;
  Password :TMD5Digest;
  PasswordMD5 :TMD5Digest;
 end;

type
 TUserAccountList = Array of TUserAccount;

type
 TUserDBFile = packed record
  Head :Array[0..2] of Char;
  Num :LongWord;
  AccountList :TUserAccountList;
 end;

type
 TLainDBControlClass = class
 private
  MemoryMapOfLainDB :TMemoryStream;
  RWPriv :Boolean;
  function CheckLainDataBase :Boolean;
 public
  function FindUserInLainDB(const Username :AnsiString) :Longint;
  function FindUserInLainDBByDigest(const UserDigest :TMD5Digest) :Longint;
  function CheckUserInLainDB(const Username :AnsiString) :Longint;
  function CheckUserInLainDBByDigest(const UserDigest :TMD5Digest) :Longint;
  
  function AddUserToLainDB(const Username, Password :AnsiString) :Boolean;
  function DelUserFromLainDB(const Username :AnsiString) :Boolean;
  function PasUserFromLainDB(const Username, Password :AnsiString) :Boolean;

  function CreateLainDB :Boolean;
  function LoadLainDBFromFile(const FPath :AnsiString) :Boolean;
  function SaveLainDBToFile(const FPath :AnsiString) :Boolean;
 {$ifdef windows}
  function LoadLainDBFromRegistry(FKey, FValue :AnsiString) :Boolean;
  function SaveLainDBToRegistry(FKey, FValue :AnsiString) :Boolean;
 {$endif}

  AccountList :TUserAccountList;
  
  constructor Create;
  destructor Destroy; override;
 end;
 
implementation

{$ifdef windows}
 uses Windows;
{$endif}
{$ifdef unix}
 uses BaseUnix;
{$endif}

constructor TLainDBControlClass.Create;
begin
 inherited Create;
 MemoryMapOfLainDB := TMemoryStream.Create;
 RWPriv := False;
end;

destructor TLainDBControlClass.Destroy;
begin
 MemoryMapOfLainDB.Free;
 AccountList := nil;
 inherited Destroy;
end;

function TLainDBControlClass.LoadLainDBFromFile(const FPath :AnsiString) :Boolean;
var
 Head :Array[0..2] of Char;
 Num, X :LongWord;
begin
 if not FileExists(FPath) then Exit(False);
{$ifdef unix}
 RWPriv := ((fpAccess(FPath, W_OK) = 0) and (fpAccess(FPath, R_OK) = 0));
{$endif}
{$ifdef windows}
 RWPriv := True; // lame :)
{$endif}
 if RWPriv = False then Exit(RWPriv);

 MemoryMapOfLainDB.LoadFromFile(FPath);
 MemoryMapOfLainDB.Seek(HeadOffset, 0);
 if MemoryMapOfLainDB.Size >= (SizeOf(Head) + SizeOf(Num)) then
 begin
  MemoryMapOfLainDB.ReadBuffer(Head, SizeOf(Head));
  MemoryMapOfLainDB.ReadBuffer(Num, SizeOf(Num));
 end else
 begin
  MemoryMapOfLainDB.Clear;
  MemoryMapOfLainDB.Seek(HeadOffset, 0);
  Exit(False);
 end;
 
 if (((Num * SizeOf(TUserAccount)) + SizeOf(Head) + SizeOf(Num)) = MemoryMapOfLainDB.Size) then
 begin
  SetLength(AccountList, Num);
  if Num > 0 then
   for x := 0 to Num - 1 do
    MemoryMapOfLainDB.ReadBuffer(AccountList[x], SizeOf(TUserAccount));
  Result := True;
 end else
 begin
  MemoryMapOfLainDB.Clear;
  MemoryMapOfLainDB.Seek(HeadOffset, 0);
  Exit(False);
 end;
  
end;

function TLainDBControlClass.SaveLainDBToFile(const FPath :AnsiString) :Boolean;
begin
 if FileExists(FPath) then
 begin
  if SysUtils.DeleteFile(FPath) = False then
   Exit(False);
 end;
 if (MemoryMapOfLainDB.Size >= (SizeOf(DBFileHead) + SizeOf(LongWord))) then
  MemoryMapOfLainDB.SaveToFile(FPath) else
  Exit(False);
 Result := True;
end;

function TLainDBControlClass.CheckLainDataBase :Boolean;
var
 Head :Array[0..2] of Char;
begin
 if (MemoryMapOfLainDB.Size >= (SizeOf(DBFileHead) + SizeOf(LongWord))) then
 begin
  MemoryMapOfLainDB.Seek(HeadOffset, 0);
  MemoryMapOfLainDB.ReadBuffer(Head, SizeOf(Head));
  MemoryMapOfLainDB.Seek(0, 0);
  Result := (Head = DBFileHead);
 end else Exit(False);
end;

function TLainDBControlClass.AddUserToLainDB(const Username, Password :AnsiString) :Boolean;
var
 UserAccount :TUserAccount;
 Num :Longword;
begin
 if CheckLainDataBase = False then Exit(False);
 if FindUserInLainDB(Username) <> -1 then Exit(False);
 if Length(Username) > SizeOf(UserAccount.UsernameStr) then Exit(False);
 FillChar(UserAccount, SizeOf(UserAccount), #0);

 UserAccount.UsernameStr := Username;
 UserAccount.UsernameMD5 := MD5String(Username);
 UserAccount.Password := MD5String(Password);
 UserAccount.PasswordMD5 := MD5Buffer(UserAccount.Password, SizeOf(UserAccount.Password));

 MemoryMapOfLainDB.Seek(NumOffset, 0);
 MemoryMapOfLainDB.ReadBuffer(Num, SizeOf(Num));
 Num := Num + 1;
 MemoryMapOfLainDB.Seek(NumOffset, 0);
 MemoryMapOfLainDB.WriteBuffer(Num, SizeOf(Num));
 MemoryMapOfLainDB.Seek(MemoryMapOfLainDB.Size, 0);
 MemoryMapOfLainDB.WriteBuffer(UserAccount, SizeOf(UserAccount));
 MemoryMapOfLainDB.Seek(0, 0);
 
 SetLength(AccountList, Length(AccountList) + 1);
 AccountList[Length(AccountList) - 1] := UserAccount;
 Result := True;
end;

function TLainDBControlClass.DelUserFromLainDB(const Username :AnsiString) :Boolean;
var
 X :LongWord;
 Index :Longint;
 UserAccount :TUserAccount;
begin
 if CheckLainDataBase = False then Exit(False);
 if Length(AccountList) <= 0 then Exit(False);
 Index := FindUserInLainDB(Username);
 if Index = -1 then Exit(False);
 if Index = (Length(AccountList) - 1) then
 begin
  SetLength(AccountList, Length(AccountList) - 1);
  X := Length(AccountList);
  MemoryMapOfLainDB.SetSize(MemoryMapOfLainDB.Size - SizeOf(TUserAccount));
  MemoryMapOfLainDB.Seek(NumOffset, 0);
  MemoryMapOfLainDB.WriteBuffer(X, SizeOf(X));
 end else
 begin
  UserAccount := AccountList[Length(AccountList) - 1];
  SetLength(AccountList, Length(AccountList) - 1);
  AccountList[Index] := UserAccount;
  MemoryMapOfLainDB.SetSize(MemoryMapOfLainDB.Size - SizeOf(TUserAccount));
  MemoryMapOfLainDB.Seek(SizeOf(DBFileHead) + SizeOf(LongWord) + (Index * SizeOf(UserAccount)), 0); /// !!! Warning
  MemoryMapOfLainDB.WriteBuffer(UserAccount, SizeOf(UserAccount));
 end;
 MemoryMapOfLainDB.Seek(NumOffset, 0);
 X := Length(AccountList);
 MemoryMapOfLainDB.WriteBuffer(X, SizeOf(X));
 MemoryMapOfLainDB.Seek(0, 0);
 Result := True;
end;

function TLainDBControlClass.PasUserFromLainDB(const Username, Password :AnsiString) :Boolean;
var
 X :LongWord;
 Index :Longint;
begin
 if CheckLainDataBase = False then Exit(False);
 if Length(AccountList) <= 0 then Exit(False);
 Index := -1;
 for X := 0 to Length(AccountList) - 1 do
  if AccountList[X].UsernameStr = Username then
   Index := X;
 if Index = -1 then Exit(False);
 AccountList[Index].Password := MD5String(Password);
 MemoryMapOfLainDB.Seek(SizeOf(DBFileHead) + SizeOf(LongWord) + (Index * SizeOf(TUserAccount)), 0); /// !!! Warning
 MemoryMapOfLainDB.WriteBuffer(AccountList[Index], SizeOf(AccountList[Index]));
 MemoryMapOfLainDB.Seek(0, 0);
 Result := True
end;

function TLainDBControlClass.CreateLainDB :Boolean;
var
 DefaultNum :LongWord;
begin
 DefaultNum := 0;
 AccountList := nil;
 MemoryMapOfLainDB.Clear;
 MemoryMapOfLainDB.WriteBuffer(DBFileHead, SizeOf(DBFileHead));
 MemoryMapOfLainDB.WriteBuffer(DefaultNum, SizeOf(DefaultNum));
 MemoryMapOfLainDB.Seek(0, 0);
 Result := True;
end;

function TLainDBControlClass.FindUserInLainDB(const Username :AnsiString) :Longint;
var
 X :LongWord;
begin
 Result := -1;
 if Length(AccountList) > 0 then
 begin
  for X := 0 to Length(AccountList) - 1 do
   if AccountList[X].UsernameStr = Username then
   begin
    Result := X;
    Break;
   end;
 end;
end;

function TLainDBControlClass.FindUserInLainDBByDigest(const UserDigest :TMD5Digest) :Longint;
var
 X, Y :LongWord;
 Bool :Boolean;
begin
 Result := -1;
 if Length(AccountList) > 0 then
 begin
  for X := 0 to Length(AccountList) - 1 do
  begin
   Bool := True;
   for Y := Low(TMD5Digest) to High(TMD5Digest) do
   begin
    Bool := Bool and (UserDigest[Y] = AccountList[X].UsernameMD5[Y]);
    if Bool = False then Break;
   end;
   if Bool = True then
   begin
    Result := X;
    Break;
   end;
  end;
 end;
end;

function TLainDBControlClass.CheckUserInLainDBByDigest(const UserDigest :TMD5Digest) :Longint;
var
 X, Y :Longint;
 Digest :TMD5Digest;
 Bool :Boolean;
 UsernameStr :AnsiString;
begin
 Result := -1;
 X := FindUserInLainDBByDigest(UserDigest);
 if X <> -1 then
 begin
  Digest := MD5Buffer(AccountList[X].Password, SizeOf(AccountList[X].Password));
  UsernameStr := AccountList[X].UsernameStr;
  Bool := True;
  for Y := Low(TMD5Digest) to High(TMD5Digest) do
   Bool := Bool and (Digest[Y] = AccountList[X].PasswordMD5[Y]);
  Digest := UserDigest;
  for Y := Low(TMD5Digest) to High(TMD5Digest) do
   Bool := Bool and (Digest[Y] = AccountList[X].UsernameMD5[Y]);
  if Bool = True then
   Result := X;
 end;
end;

function TLainDBControlClass.CheckUserInLainDB(const Username :AnsiString) :Longint;
var
 X, Y :Longint;
 Digest :TMD5Digest;
 Bool :Boolean;
 UsernameStr :AnsiString;
begin
 Result := -1;
 X := FindUserInLainDB(Username);
 if X <> -1 then
 begin
  Digest := MD5Buffer(AccountList[X].Password, SizeOf(AccountList[X].Password));
  UsernameStr := AccountList[X].UsernameStr;
  Bool := True;
  for Y := Low(TMD5Digest) to High(TMD5Digest) do
   Bool := Bool and (Digest[Y] = AccountList[X].PasswordMD5[Y]);
  Digest := MD5String(Username);
  for Y := Low(TMD5Digest) to High(TMD5Digest) do
   Bool := Bool and (Digest[Y] = AccountList[X].UsernameMD5[Y]);
  if Bool = True then
   Result := X;
 end;
end;

end.

