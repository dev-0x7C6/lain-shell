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
 TNMultiLanguageSupport = object
 private
  Headers :TStringList;
  Sources :TStringList;
 public
  procedure Init;
  procedure Done;
  
  function Load(LangIdent :DoubleChar) :Boolean;
  //destructor Destroy; override;
  
  //function GetString(const Value :WideString) :WideString; virtual;
 end;
 
var
 NMultiLanguageSupport :TNMultiLanguageSupport;
 AnyLanguageSupport :Boolean = True;

implementation

Const
{$ifdef windows} IDir = '\'; {$endif}
{$ifdef unix} IDir = '/'; {$endif}

procedure TNMultiLanguageSupport.Init;
begin
 Headers := TStringList.Create;
 Sources := TStringList.Create;
end;

procedure TNMultiLanguageSupport.Done;
begin
 Headers.Free;
 Sources.Free;
end;

function TNMultiLanguageSupport.Load(LangIdent :DoubleChar) :Boolean;
const
 IFileName = 'index.txt';
var
 IFile :TStringList;
 IFilePath :AnsiString;
 Lang, List :TStringList;
 Count, X :Longint;
 d1, d2 :TPoint;
begin
 IFilePath := MainLangDirectory + IDir + LangIdent + IDir + IFileName;
 Result := False;
 if FileExists(IFilePath) then
 begin
  IFile := TStringList.Create;
  IFile.LoadFromFile(IFilePath);
  if IFile.Count > 0 then
  begin
   Lang := TStringList.Create;
   List := TStringList.Create;
   for Count := 0 to IFile.Count - 1 do
    if FileExists(MainLangDirectory + IDir + LangIdent + IDir + IFile.Strings[Count] + '.txt') then
    begin
     List.LoadFromFile(MainLangDirectory + IDir + LangIdent + IDir + IFile.Strings[Count] + '.txt');
     if List.Count > 0 then
      for X := 0 to List.Count - 1 do
       Lang.Add(List.Strings[X]);
     List.Clear;
    end;
   List.Free;
   if Lang.Count > 0 then
   begin
    Headers.Clear;
    Sources.Clear;
    Result := True;
    for Count := 0 to Lang.Count - 1 do
     if Length(Lang.Strings[Count]) > 0 then
     begin
      d1.X := 1;
      d1.Y := -1;
      for X := 1 to Length(Lang.Strings[Count]) do
       if Lang.Strings[Count][X] = ':' then
       begin
        d1.Y := X;
        break;
       end;
      if ((d1.Y <> -1) and (d1.Y < Length(Lang.Strings[Count]))) then
      begin
       d2.X := -1;
       d2.Y := -1;
       for X := d1.Y to Length(Lang.Strings[Count]) do
        if Lang.Strings[Count][X] = '"' then
        begin
         if d2.X <> -1 then
         begin
          d2.Y := X;
          Break;
         end else
          d2.X := X;
        end;
       if ((d2.X <> -1) and (d2.Y <> -1)) then
       begin
        Headers.Add(Copy(Lang.Strings[Count], d1.X, d1.Y - d1.X));
        Sources.Add(Copy(Lang.Strings[Count], d2.X+1, d2.Y - d2.X-1));
       end;
      end;
     end;
   end;
   Lang.Free;
  end;
  IFile.Free;
 end;
end;

initialization
begin

end;

end.

