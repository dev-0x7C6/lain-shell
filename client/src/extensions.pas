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

unit Extensions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main, KeyBoard;
  
{$define ASCII_TRANSLATE}
//{$define UNICODE_TRANSLATE} // not usesfull
  
Const
 kbdReturn = #13;
 kbdSpace = ' ';
 kbdBSpace = #8;
 kbdEsc = #27;

 function CmdToParams(const Cmd :WideString; var Params :TParams) :Longint;
 function GetTextln :WideString;
 function GetText :WideString;
 function GetPasswdln(Show :Char) :WideString;
 function GetPasswd(Show :Char) :WideString;

implementation

function CmdToParams(const Cmd :WideString; var Params :TParams) :Longint;
var
 Offsets :Array of Longint;
 X :Longint;
begin
 if Length(Cmd) = 0 then
 begin
  Params := nil;
  Exit(CMD_Fail);
 end;

 for X := 1 to length(Cmd) do
 if Cmd[X] = ' ' then
 begin
  SetLength(Offsets, Length(Offsets) + 1);
  Offsets[Length(Offsets) - 1] := x;
 end;
   
 SetLength(Offsets, Length(Offsets) + 1);
 Offsets[Length(Offsets) - 1] := Length(Cmd) + 1;

 SetLength(Params, 1);
 if Length(Offsets) <= 1 then
  Params[0] := Copy(Cmd, 1, Offsets[0]) else
  Params[0] := Copy(Cmd, 1, Offsets[0] - 1);
  
 if Length(Offsets) > 1 then
 begin
  for X := 1 to Length(Offsets) - 1 do
  begin
   if ((Offsets[X] - Offsets[X - 1] - 1) > 0) then
   begin
    SetLength(Params, Length(Params) + 1);
    Params[Length(Params) - 1] := Copy(Cmd, Offsets[X - 1] + 1, Offsets[X] - Offsets[X - 1] - 1);
   end;
  end;
 end;

 Offsets := nil;
end;

function GetPasswdln(Show :Char) :WideString;
begin
 Result := GetPasswd(Show);
 Writeln;
end;

function GetPasswd(Show :Char) :WideString;
var
 Key :TKeyEvent;
begin
 InitKeyBoard;
 Result := '';
 repeat
  Key := GetKeyEvent;
 {$ifdef ASCII_TRANSLATE}
  Key := TranslateKeyEvent(Key);
 {$endif}
 {$ifdef UNICODE_TRANSLATE}
  Key := TranslateKeyEventUniCode(Key);
 {$endif}
  if ((GetKeyEventChar(Key) <> kbdReturn) and
      (GetKeyEventFlags(Key) = kbASCII)) then
  begin
   if (GetKeyEventChar(Key) <> kbdBSpace) then
   begin
    Result := Result + GetKeyEventChar(Key);
    Write(Show);
   end else
   begin
    if Length(Result) > 0 then
    begin
     SetLength(Result, Length(Result) - 1);
     Write(kbdBSpace);
     Write(kbdSpace);
     Write(kbdBSpace);
    end;
   end;
  end;
 until GetKeyEventChar(Key) = kbdReturn;
 DoneKeyBoard;
end;

function GetTextln :WideString;
begin
 Result := GetText;
 Writeln;
end;

function GetText :WideString;
var
 Key :TKeyEvent;
begin
 InitKeyBoard;
 Result := '';
 repeat
  Key := GetKeyEvent;
 {$ifdef ASCII_TRANSLATE}
  Key := TranslateKeyEvent(Key);
 {$endif}
 {$ifdef UNICODE_TRANSLATE}
  Key := TranslateKeyEventUniCode(Key);
 {$endif}
  if ((GetKeyEventChar(Key) <> kbdReturn) and
      (GetKeyEventFlags(Key) = kbASCII)) then
  begin
   if (GetKeyEventChar(Key) <> kbdBSpace) then
   begin
    Result := Result + GetKeyEventChar(Key);
    Write(GetKeyEventChar(Key));
   end else
   begin
    if Length(Result) > 0 then
    begin
     SetLength(Result, Length(Result) - 1);
     Write(kbdBSpace);
     Write(kbdSpace);
     Write(kbdBSpace);
    end;
   end;
  end;
 until GetKeyEventChar(Key) = kbdReturn;
 DoneKeyBoard;
end;

end.

