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

unit pwdutils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, KeyBoard;

const
 ASCIIRange :Array[0..1] of Byte = (32, 126);
 ASCIIBackspace = #8;
 ASCIIReturn = #13;
 
 Error_EmptyPassword  = 01;
 
 function SetPasswd(var Passwd :AnsiString; Error :Byte) :Boolean;
 function GetPasswd(var Passwd :AnsiString; Msg :AnsiString; Error :Byte) :Boolean;
 function CapturePassword(var Passwd :AnsiString) :Byte;
  
implementation

function GetPasswd(var Passwd :AnsiString; Msg :AnsiString; Error :Byte) :Boolean;
var
 Password :AnsiString;
begin
 Write(Msg);
 CapturePassword(Password);
end;

function SetPasswd(var Passwd :AnsiString; Error :Byte) :Boolean;
var
 Password1, Password2 :AnsiString;
 CheckError :Byte;
begin
 Write('New Password: ');
 CheckError := CapturePassword(Password1);
 case CheckError of
  Error_EmptyPassword: Writeln('Error: Password is empty'#13);
 end;
 if CheckError <> 0 then
  Exit(False);
 Write('Re-Type New Password: ');
 CheckError := CapturePassword(Password2);
 case CheckError of
  Error_EmptyPassword: Writeln('Error: Password is empty'#13);
 end;
 if CheckError <> 0 then
  Exit(False);
  
 if Password1 = Password2 then
 begin
  Passwd := Password1;
  Writeln('Password change successful');
  Exit(True);
 end else
 begin
  Writeln('Error: Passwords aren''t same'#13);
  Exit(False);
 end;
end;

function CapturePassword(var Passwd :AnsiString) :Byte;
var
 Key :TKeyEvent;
 KeyChar :Char;
 Check :Boolean;
begin
 InitKeyBoard;
 Passwd := '';
 repeat
  Key := GetKeyEvent;
  Key := TranslateKeyEvent(Key);
  KeyChar := GetKeyEventChar(Key);
  if GetKeyEventFlags(Key) = kbASCII then
  begin
   if (KeyChar = ASCIIReturn) then
    Break;
   if ((KeyChar = ASCIIBackspace) and (Length(Passwd) > 0)) then
   begin
    SetLength(Passwd, Length(Passwd) - 1);
    Write(ASCIIBackspace);
    Write(' ');
    Write(ASCIIBackspace);
    Continue;
   end;
  end;
  if ((Ord(KeyChar) >= ASCIIRange[0]) and (Ord(KeyChar) <= ASCIIRange[1])) then
  begin
   Passwd := Passwd + GetKeyEventChar(Key);
   Write('*');
  end;
 until False;
 DoneKeyBoard;
 Writeln(ASCIIReturn);
 Check := True;
 if Length(Passwd) > 0 then
  Result := 0 else
  Result := Error_EmptyPassword;
end;

end.

