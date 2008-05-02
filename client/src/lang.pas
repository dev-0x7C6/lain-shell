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

unit Lang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main;

Const
 WindowsCodePageEn :WideString = '437';
 WindowsCodePageEs :WideString = '850';
 WindowsCodePagePl :WideString = '852';

Const
 SupportLangs :WideString = 'en/es/pl';
 
Var
 WindowsManualCodePageID :Longint = 437;
 WindowsManualCodePage :Boolean = False;

var
 LangDirectory :WideString = 'lang';
 LangFileName :WideString = 'lang';
 LangFileExt :WideString = 'txt';
 DefaultLang :WideString = 'en';

type
 TMultiLanguageSupport = class
 private
  Index :TStringList;
  Source :TStringList;
 public
  function GetString(const Value :WideString) :WideString; virtual;
  constructor Create(const Value :WideString);
  destructor Destroy; override;
 end;

Type
 TCmdHint = Array[0..1] of WideString;

var
 HelpList :Array[0..12] of TCmdHint =
  (('About     ', ''),
   ('Connect   ', ''),
   ('Clear     ', ''),
   ('Disconnect', ''),
   ('Execute   ', ''),
   ('Exit      ', ''),
   ('Help      ', ''),
   ('Login     ', ''),
   ('Logout    ', ''),
   ('RConnect  ', ''),
   ('Set       ', ''),
   ('Status    ', ''),
   ('Quit      ', '')
  );

var
 MultiLanguageSupport :TMultiLanguageSupport;
 AnyLanguageSupport :Boolean = True;
{$ifdef windows}
{$endif}
 
 function MultiLanguageInit :Longint;
 function CMD_SetLang(var Params :TParams) :Longint;
 {$ifdef windows}
  function CMD_SetConsoleCodePage(var Params :TParams) :Longint;
 {$endif}
 
implementation

{$ifdef windows} uses Windows; {$endif}

function CMD_SetLang(var Params :TParams) :Longint;
begin
 if Length(Params) < 3 then
 begin
  Writeln(OutPut, MultiLanguageSupport.GetString(Format('UsingSetLang', [SupportLangs])));
  Exit(CMD_Fail);
 end;
 
 DefaultLang := LowerCase(Params[2]);
 Result := MultiLanguageInit;
 if Result = CMD_Done then
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgSetVariableDone')) else
  Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgSetVariableFail'));
end;

{$ifdef windows}
 function CMD_SetConsoleCodePage(var Params :TParams) :Longint;
 var
  Value :Longint;
 begin
  if Length(Params) < 2 then
  begin
   Writeln(OutPut, MultiLanguageSupport.GetString('UsingSetCodePage'));
   Exit(CMD_Fail);
  end;
  Value := StrToIntDef(Params[2], 0);
  WindowsManualCodePage := (Value <> 0);
  WindowsManualCodePageID := Value;
  if WindowsManualCodePage = True then
  begin
   SetConsoleCP(WindowsManualCodePageID);
   Writeln(OutPut, Prefix, MultiLanguageSupport.GetString('MsgSetVariableDone'));
  end;
  Result := CMD_Done;
 end;
{$endif}

function TMultiLanguageSupport.GetString(const Value :WideString) :WideString;
var
 X, Offset :Longint;
begin
 Offset := -1;
 for X := 0 to Index.Count - 1 do
 begin
  if LowerCase(Index.Strings[X]) = (LowerCase(Value) + ':') then
  begin
   Offset := X;
   Break;
  end;
 end;
 if Offset <> -1 then
  Result := Source.Strings[Offset] else
  Result := '';
end;

constructor TMultiLanguageSupport.Create(const Value :WideString);
var
 X, Y, Offset, Segment :Longint;
 Lang :TStringList;

function DelSpaces(Source :WideString) :WideString;
var
 X :Longint;
begin
 if Length(Source) > 0 then
 begin
  Result := '';
  for X := 1 to length(Source) do
   if Source[x] <> ' ' then
    Result := Result + Source[X];
 end else
  Result := '';
end;

begin
 inherited Create;
 Lang := TStringList.Create;
 Index := TStringList.Create;
 Source := TStringList.Create;
 if FileExists(Value) then
 begin
  Lang.LoadFromFile(Value);
  for X := 0 to Lang.Count - 1 do
  begin
   Offset := -1;
   Segment := -1;
   for Y := 1 to Length(Lang.Strings[X]) do
   begin
    if Lang.Strings[X][Y] = '"' then
    begin
     if Offset <> -1 then
     begin
      Segment := Y;
      Break;
     end else
      Offset := Y;
    end;
   end;
   if ((Offset <> -1) and (Segment <> -1)) then
   begin
    Index.Add(DelSpaces(Copy(Lang.Strings[X], 1, Offset - 1)));
    Source.Add(Copy(Lang.Strings[X], Offset + 1, Segment - Offset - 1));
   end;
  end;
 end;
 Lang.Free;
end;

destructor TMultiLanguageSupport.Destroy;
begin
 Index.Free;
 Source.Free;
 inherited Destroy;
end;

var
 LangFile :WideString;
{$ifdef windows}
 CodePage :WideString;
{$endif}

function MultiLanguageInit :Longint;
begin
{$ifdef unix}
  LangFile := LangDirectory + '/' + DefaultLang + '/' + LangFileName + '.' + LangFileExt;
 {$endif}
 {$ifdef windows}
  CodePage := '';
  if WindowsManualCodePage = False then
  begin
   if DefaultLang = 'en' then CodePage := '_cp' + WindowsCodePageEn;
   if DefaultLang = 'es' then CodePage := '_cp' + WindowsCodePageEs;
   if DefaultLang = 'pl' then CodePage := '_cp' + WindowsCodePagePl;
  end else
   CodePage := '_cp' + IntToStr(WindowsManualCodePageID);

  LangFile :=  LangDirectory + '\' + DefaultLang + '\' + LangFileName +
              CodePage + '.' + LangFileExt;
 {$endif}
 if not FileExists(LangFile) then
 begin
  Writeln(OutPut, 'Can''t find language file: ', LangFile, ' Not Found');
  Writeln(OutPut);
  if MultiLanguageSupport = nil then AnyLanguageSupport := False;
  Result := CMD_Fail;
  Readln;
 end else
 begin
  if MultiLanguageSupport <> nil then MultiLanguageSupport.Free;
  MultiLanguageSupport := TMultiLanguageSupport.Create(LangFile);
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
  HelpList[09][1] := MultiLanguageSupport.GetString('HelpRConnect');
  HelpList[10][1] := MultiLanguageSupport.GetString('HelpSet');
  HelpList[11][1] := MultiLanguageSupport.GetString('HelpStatus');
  HelpList[12][1] := MultiLanguageSupport.GetString('HelpQuit');
  if ConsoleUser = '' then
   ConsoleUser := MultiLanguageSupport.GetString('FieldUsername');
  if ConsoleHost = '' then
   ConsoleHost := MultiLanguageSupport.GetString('FieldLocation');
  Result := CMD_Done;
 end;
end;

end.

