{ Copyright (C) 2007 Bartlomiej Burdukiewicz

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
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

unit FSUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;


type
 TFileSystemBrowser = class
 private
  FCurrentDirectory :WideString;
 {$ifdef windows}
  FCurrentDiskPath :WideString;
 {$endif}
  FDirectoryList :TStringList;
  FFileList :TStringList;
 protected
  FSeparator :WideString;
  function GetCurrentDirectory :WideString;
  procedure SetCurrentDirectory(Value :WideString);
 public
  constructor Create;
  destructor Destroy; override;
  
  property CurrentDirectory :WideString read GetCurrentDirectory write SetCurrentDirectory;
  property Directories :TStringList read FDirectoryList;
  property Files :TStringList read FFileList;

  function DirectoryUp :boolean;
  procedure Sort;
  procedure UpdateList;
end;


implementation

 constructor TFileSystemBrowser.Create;
 begin
  inherited Create;
  FDirectoryList := TStringList.Create;
  FFileList := TStringList.Create;
  {$ifdef unix}
   FSeparator := '/';
  {$endif}
  {$ifdef windows}
   FCurrentDiskPath := 'C:\';
   FSeparator := '\';
  {$endif} 
 end;
 
 destructor TFileSystemBrowser.Destroy;
 begin
  FDirectoryList.Free;
  FFileList.Free;
  inherited Destroy;
 end;
 

 function TFileSystemBrowser.GetCurrentDirectory :WideString;
 begin
  Result := FCurrentDirectory;
 end;
 
 procedure TFileSystemBrowser.SetCurrentDirectory(Value :WideString);

  function Dir(Value :WideString) :WideString;
  begin
   if Value[Length(Value)] = FSeparator then
    Result := Value else
    Result := Value + FSeparator;
  end;

{$ifdef windows}
 var
  DiskPath :WideString;
{$endif}
     
 begin
  if DirectoryExists(Value) then
  begin
  {$ifdef windows}
   FCurrentDiskPath := UpperCase(Copy(Value, 1, 2));
  {$endif}
   FCurrentDirectory := Dir(Value);
   UpdateList;
  end;
 end;
 
 function TFileSystemBrowser.DirectoryUp :boolean;
 var
  x :longint;
  Offset, Segment :longint;
 begin
  Offset := 0;
  Segment := 0;
  for x := length(FCurrentDirectory) downto 1 do
   if FCurrentDirectory[x] = FSeparator then
    if Segment = 0 then Segment := x else
    begin
     Offset := x + 1;
     break;
    end;

  if ((Offset <> 0) and (Segment <> 0)) then
  begin
   Delete(FCurrentDirectory, Offset, Segment);
   SetCurrentDirectory(FCurrentDirectory); // for call
   Result := True;
  end else
   Result := False;
 end;
 
 procedure TFileSystemBrowser.UpdateList;
 var
  FileList :TSearchRec;
  FileCount :Integer;
 begin
  FDirectoryList.Clear;
  FFileList.Clear;
  
  {$ifdef unix}
   FileCount := FindFirst(FCurrentDirectory + '*', faAnyFile, FileList);
  {$endif}
  
  {$ifdef windows}
   FileCount := FindFirst(FCurrentDirectory + FCurrentDirectory + '*', faAnyFile, FileList);
  {$endif}
  
  try
   while (FileCount = 0) do
   begin
    if ((FileList.Attr and faDirectory) = faDirectory) then
     FDirectoryList.Add(FileList.Name) else
     FFileList.Add(FileList.Name);
    FileCount := FindNext(FileList);
   end;
  finally
   FindClose(FileList);
  end;
 end;
 
 procedure TFileSystemBrowser.Sort;
 begin
  FDirectoryList.Sort;
  FFileList.Sort;
 end;


end.

