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
 SupportLangs :WideString = 'en/es/pl';
 
Type
 TCmdHint = Array[0..1] of WideString;

var
 HelpList :Array[0..15] of TCmdHint =
  (('About      ', ''),
   ('Connect    ', ''),
   ('Clear      ', ''),
   ('Disconnect ', ''),
   ('Execute    ', ''),
   ('Exit       ', ''),
   ('Help       ', ''),
   ('Login      ', ''),
   ('Logout     ', ''),
   ('ProcessList', ''),
   ('RConnect   ', ''),
   ('Set        ', ''),
   ('Status     ', ''),
   ('Sysinfo    ', ''),
   ('Quit       ', ''),
   ('Users      ', '')
  );
  
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
  function GetString(const Value :AnsiString) :AnsiString;
  function Load(LangIdent :DoubleChar) :Boolean;
 end;
 
var
 MultiLanguageSupport :TNMultiLanguageSupport;
 AnyLanguageSupport :Boolean = True;

 procedure LanShellReconfLang;
 function CMD_SetLang(var Params :TParams) :Longint;
{$ifdef windows}
 function CMD_SetConsoleCodePage(var Params :TParams) :Longint;
{$endif}
 
implementation

Const
{$ifdef windows} IDir = '\'; {$endif}
{$ifdef unix} IDir = '/'; {$endif}

function CMD_SetLang(var Params :TParams) :Longint;
begin
 if Length(Params) < 3 then
 begin
  Writeln(MultiLanguageSupport.GetString(Format('UsingSetLang', [SupportLangs])), EndLineChar);
  Exit(CMD_Fail);
 end;
 if MultiLanguageSupport.Load(LowerCase(Params[2])) = True then
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgSetVariableDone'), EndLineChar);
  LanShellReconfLang;
  Result := CMD_Done;
 end else
 begin
  Writeln(Prefix_Out, MultiLanguageSupport.GetString('MsgSetVariableFail'), EndLineChar);
  Result := CMD_Fail;
 end;
end;

{$ifdef windows}
 function CMD_SetConsoleCodePage(var Params :TParams) :Longint;
 var
  Value :Longint;
 begin
  if Length(Params) < 2 then
  begin
   Writeln(MultiLanguageSupport.GetString('UsingSetCodePage'), EndLineChar);
   Exit(CMD_Fail);
  end;
  Value := StrToIntDef(Params[2], 0);
  WindowsManualCodePage := (Value <> 0);
  WindowsManualCodePageID := Value;
  if WindowsManualCodePage = True then
  begin
   SetConsoleCP(WindowsManualCodePageID);
   Writeln(Prefix, MultiLanguageSupport.GetString('MsgSetVariableDone'), EndLineChar);
  end;
  Result := CMD_Done;
 end;
{$endif}

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

function TNMultiLanguageSupport.GetString(const Value :AnsiString) :AnsiString;
var
 X :Longint;
begin
 Result := '';
 if ((Headers.Count > 0) and (Sources.Count > 0) and (Headers.Count = Sources.Count)) then
  for X := 0 to Headers.Count - 1 do
   if LowerCase(Headers.Strings[X]) = LowerCase(Value) then
   begin
    Result := Sources.Strings[X];
    Break;
   end;
end;

function TNMultiLanguageSupport.Load(LangIdent :DoubleChar) :Boolean;
const
{$ifdef windows}
 IFileName = 'index.dos';
{$endif}
{$ifdef unix}
 IFileName = 'index.unix';
{$endif}
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

procedure LanShellReconfLang;
begin
 {$ifdef windows}
  SetConsoleCP(StrToIntDef(MultiLanguageSupport.GetString('WindowsConsoleCodePage'), 437));
 {$endif}
  HelpList[00][1] := MultiLanguageSupport.GetString('HelpAbout');
  HelpList[01][1] := MultiLanguageSupport.GetString('HelpConnect');
  HelpList[02][1] := MultiLanguageSupport.GetString('HelpClear');
  HelpList[03][1] := MultiLanguageSupport.GetString('HelpDisconnect');
  HelpList[04][1] := MultiLanguageSupport.GetString('HelpExecute');
  HelpList[05][1] := MultiLanguageSupport.GetString('HelpExit');
  HelpList[06][1] := MultiLanguageSupport.GetString('HelpHelp');
  HelpList[07][1] := MultiLanguageSupport.GetString('HelpLogin');
  HelpList[08][1] := MultiLanguageSupport.GetString('HelpLogout');
  HelpList[09][1] := MultiLanguageSupport.GetString('HelpProcessList');
  HelpList[10][1] := MultiLanguageSupport.GetString('HelpRConnect');
  HelpList[11][1] := MultiLanguageSupport.GetString('HelpSet');
  HelpList[12][1] := MultiLanguageSupport.GetString('HelpStatus');
  HelpList[13][1] := MultiLanguageSupport.GetString('HelpSysinfo');
  HelpList[14][1] := MultiLanguageSupport.GetString('HelpQuit');
  HelpList[15][1] := MultiLanguageSupport.GetString('HelpUsers');
  if ConsoleUser = '' then
   ConsoleUser := MultiLanguageSupport.GetString('FieldUsername');
  if ConsoleHost = '' then
   ConsoleHost := MultiLanguageSupport.GetString('FieldLocation');
end;

initialization
begin
 MultiLanguageSupport.Init;
 if not MultiLanguageSupport.Load('en') then
 begin
  Writeln('Can''t find default language files, please check directory "lang/en"'#13);
  Readln;
  Halt;
 end;
 LanShellReconfLang;
end;

finalization
 MultiLanguageSupport.Done;

end.

