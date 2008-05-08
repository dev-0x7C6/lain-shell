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

unit ConvNum;

interface

const
 BinConst = 2;
 OctConst = 8;
 HexConst = 16;
 

 function StrToNum(Source :AnsiString; NumSys :Longint) :Longint;
 function BinToDec(Source :AnsiString) :Longint;
 function OctToDec(Source :AnsiString) :Longint;
 function HexToDec(Source :AnsiString) :Longint;

implementation

function LMethod(X, Y :Longint) :Longint;
var
 I :Longint;
begin
 Result := 1;
 for I := 1 to Y do Result := Result * X;
end;

function StrToNum(Source :AnsiString; NumSys :Longint) :Longint;
var
 X, Y :Longint;
begin
 Result := 0;
 for X:= Length(Source) downto 1 do
 begin
  if(Source[X] <= '9') then
   Y := Longint(Source[X]) - Ord('0') else
   Y := Longint(Source[X]) - Ord('A') + 10;
  Result := Result + Y * LMethod(NumSys,(length(Source) - X));
 end;
end;

function BinToDec(Source :AnsiString) :Longint;
begin
 Result := StrToNum(Source, BinConst);
end;

function OctToDec(Source :AnsiString) :Longint;
begin
 Result := StrToNum(Source, OctConst);
end;

function HexToDec(Source :AnsiString) :Longint;
begin
 Result := StrToNum(Source, HexConst);
end;

end.
