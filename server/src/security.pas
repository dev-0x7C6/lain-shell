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
  UsernameMD5 :TMDDigest;
  Password :TMDDigest;
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
 public
 //
  constructor Create;
  destructor Destroy; override;
  
 // list
  AccountList :TUserAccountList;
  
 // users
  function AddUserToLainDB(const Username, Password :AnsiString) :Boolean;
  function DelUserFromLainDB(const Username :AnsiString) :Boolean;
  function PasUserFromLainDB(const Username, Password :AnsiString) :Boolean;
 // file
  function LoadFromLainDB(const FPath :AnsiString) :Boolean;
  function SaveToLainDB(const FPath :AnsiString) :Boolean;
 end;
 
implementation

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
 inherited Destroy;
end;

function TLainDBControlClass.LoadFromLainDB(const FPath :AnsiString) :Boolean;
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
   for x := 0 to Num do
    MemoryMapOfLainDB.ReadBuffer(AccountList[x], SizeOf(TUserAccount));
  Result := True;
 end else
 begin
  MemoryMapOfLainDB.Clear;
  MemoryMapOfLainDB.Seek(HeadOffset, 0);
  Exit(False);
 end;
  
end;

function TLainDBControlClass.SaveToLainDB(const FPath :AnsiString) :Boolean;
begin
 if not FileExists(FPath) then
 begin
 end;
end;

function TLainDBControlClass.AddUserToLainDB(const Username, Password :AnsiString) :Boolean;
begin
end;

function TLainDBControlClass.DelUserFromLainDB(const Username :AnsiString) :Boolean;
begin
end;

function TLainDBControlClass.PasUserFromLainDB(const Username, Password :AnsiString) :Boolean;
begin
end;

end.

