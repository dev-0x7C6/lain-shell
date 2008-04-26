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

unit Config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Type
 TDoubleString = Array[0..1] of String;
  
Const
 ConfigVariablesCount = 3;

Var
 DefaultConfigVariables :Array[0..ConfigVariablesCount]of TDoubleString =
 (('ServerPort','9896'),
  ('ServerMaxConnections', '0'),
  ('ReverseConnectHostname', '127.0.0.1'),
  ('ReverseConnectPort', '9897'));

 DefaultComments :Array[0..ConfigVariablesCount]of String =
 (('# ServerPort is a number variable, define lisining port'),
  ('# ServerMaxConnections is a nubmer variable, limited incoming connections (unlimited=0)'),
  ('# ReverseConnectHostname is a string variable, connect to hostname'),
  ('# ReverseConnectPort is a number variable, connect to hostname at port'));
 

type TConfigFile = class
 private
  FConfig :TStringList;
 protected
 public
  constructor Create;
  destructor Destroy; override;
 
  procedure GenerateConfig;
  function OpenConfig(Source :WideString) :Boolean;
  function SaveConfig(Dest :WideString) :Boolean;
end;

var
 ConfigFile : TConfigFile;

implementation

 constructor TConfigFile.Create;
 begin
  inherited Create;
  FConfig := TStringList.Create;
 end;
 
 destructor TConfigFile.Destroy;
 begin
  FConfig.Free;
  inherited Destroy;
 end;
 
 procedure TConfigFile.GenerateConfig;
 var
  X :Longint;
 begin
  FConfig.Clear;
  for X := 0 to ConfigVariablesCount do
  begin
   FConfig.Add(DefaultComments[X]);
   FConfig.Add(DefaultConfigVariables[X][0] + '=' + DefaultConfigVariables[X][1]);
   FConfig.Add('');
  end;
 end;
 
 function TConfigFile.OpenConfig(Source :WideString) :Boolean;
 begin
  FConfig.Clear;
  Result := FileExists(Source);
  if Result = True then
   FConfig.LoadFromFile(Source);
 end;
 
 function TConfigFile.SaveConfig(Dest :WideString) :Boolean;
 begin
 {$I-}
  FConfig.SaveToFile(Dest);
 {$I+}
  Result := (IOResult = 0);
 end;

end.
