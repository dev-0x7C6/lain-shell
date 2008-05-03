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

Const
//
  Black         = 0;
  Blue          = 1;
  Green         = 2;
  Cyan          = 3;
  Red           = 4;
  Magenta       = 5;
  Brown         = 6;
  LightGray     = 7;
//
  DarkGray      = 8;
  LightBlue     = 9;
  LightGreen    = 10;
  LightCyan     = 11;
  LightRed      = 12;
  LightMagenta  = 13;
  Yellow        = 14;
  White         = 15;

const
  AnsiTbl : string[8]='04261537';
     
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
 procedure CWrite(var OutPut :Text; Attr :Longint; Str :String; NewLine :Boolean);
 procedure CClrScr(var OutPut :Text);

implementation

{$ifdef windows}
 uses Windows;
{$endif}

{$ifdef unix}
function Attr2Ansi(Attr :Longint):string;
var
 hstr : string[16];
 OFg,OBg,Fg,Bg : longint;

 procedure AddSep(ch:char);
 begin
  if length(hstr)>0 then
   hstr:=hstr+';';
  hstr:=hstr+ch;
 end;
begin
 Hstr:='';
 Fg:=Attr and $f;
 Bg:=Attr shr 4;
 if (OFg<>7) or (Fg=7) or ((OFg>7) and (Fg<8)) or ((OBg>7) and (Bg<8)) then
 begin
  hstr:='0';
  OFg:=7;
  OBg:=0;
 end;
 if (Fg>7) and (OFg<8) then
  begin
    AddSep('1');
    OFg:=OFg or 8;
  end;
 if (Bg and 8)<>(OBg and 8) then
  begin
    AddSep('5');
    OBg:=OBg or 8;
  end;
 if (Fg<>OFg) then
  begin
    AddSep('3');
    hstr:=hstr+AnsiTbl[(Fg and 7)+1];
  end;
 if (Bg<>OBg) then
  begin
    AddSep('4');
    hstr:=hstr+AnsiTbl[(Bg and 7)+1];
  end;
 if hstr='0' then
  hstr:='';
 Attr2Ansi:=#27'['+hstr+'m';
end;
{$endif}

procedure CClrScr(var OutPut :Text);
begin
{$ifdef unix}
 Writeln(OutPut, #27'[');
{$endif}
end;

procedure CWrite(var OutPut :Text; Attr :Longint; Str :String; NewLine :Boolean);
{$ifdef windows}
var
 AttrW :Longword;
 Data :TCONSOLESCREENBUFFERINFO;
{$endif}
begin
{$ifdef unix}
 Write(OutPut, Attr2Ansi(Attr and $F));
 if NewLine then
  Writeln(OutPut, Str) else
  Write(OutPut, Str);
 Write(OutPut, Attr2Ansi(LightGray and $F));
{$endif}
{$ifdef windows}
 GetConsoleScreenBufferInfo(GetStdhandle(STD_OUTPUT_HANDLE), Data);
 if NewLine then
  Writeln(OutPut, Str) else
  Write(OutPut, Str);
 FillConsoleOutputAttribute(GetStdhandle(STD_OUTPUT_HANDLE), (Attr and $8f), Length(Str), Data.dwCursorPosition, AttrW);
{$endif}
end;

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
 Writeln(OutPut);
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
    Write(OutPut, Show);
   end else
   begin
    if Length(Result) > 0 then
    begin
     SetLength(Result, Length(Result) - 1);
     Write(OutPut, kbdBSpace);
     Write(OutPut, kbdSpace);
     Write(OutPut, kbdBSpace);
    end;
   end;
  end;
 until GetKeyEventChar(Key) = kbdReturn;
 DoneKeyBoard;
end;

function GetTextln :WideString;
begin
 Result := GetText;
 Writeln(OutPut);
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
    Write(OutPut, GetKeyEventChar(Key));
   end else
   begin
    if Length(Result) > 0 then
    begin
     SetLength(Result, Length(Result) - 1);
     Write(OutPut, kbdBSpace);
     Write(OutPut, kbdSpace);
     Write(OutPut, kbdBSpace);
    end;
   end;
  end;
 until GetKeyEventChar(Key) = kbdReturn;
 DoneKeyBoard;
end;

end.
