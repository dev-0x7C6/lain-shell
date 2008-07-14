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

unit nLang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main;

Const
 MainLangDirectory = 'lang';
  
type
 DoubleChar = Array[0..1] of Char;
  
type
 TNMultiLanguageSupport = class
 private
  Headers :TStringList;
  Sources :TStringList;
 public
  constructor Create(LangIdent :DoubleChar);
  //destructor Destroy; override;
  
  //function GetString(const Value :WideString) :WideString; virtual;
 end;
 
var
 MultiLanguageSupport :TNMultiLanguageSupport;
 AnyLanguageSupport :Boolean = True;

implementation

Const
{$ifdef windows} IDir = '\'; {$endif}
{$ifdef unix} IDir = '/'; {$endif}

constructor TNMultiLanguageSupport.Create(LangIdent :DoubleChar);
const
 IFileName = 'index.txt';
var
 IFile :TStringList;
 IFilePath :AnsiString;
 
 Count :Longint;
begin
 inherited Create;
 IFilePath := MainLangDirectory + IDir + LangIdent + IDir + IFileName;
 if FileExists(IFilePath) then
 begin
  IFile := TStringList.Create;
  IFile.LoadFromFile(IFilePath);
  if IFile.Count <> 0 then
  begin
   for Count := 0 to IFile.Count - 1 do
    if FileExists(MainLangDirectory + IDir + LangIdent + IDir + IFile.Strings[Count]) then
    begin
    end;
  end;
  IFile.Free;
 end;
end;

initialization
begin

end;

end.

