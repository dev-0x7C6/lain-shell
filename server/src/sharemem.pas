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

unit ShareMem;

{$mode objfpc}{$H+}

interface

uses
{$ifdef unix} BaseUnix, Unix, IPC, {$endif}{$ifdef windows} Windows, {$endif} Classes, SysUtils;
  
{$ifdef unix}

const
 Default_IdentValue = $F3D8;
 Default_AccessMode = IPC_CREAT or SHM_R or SHM_W;
 Default_BlockSize = SizeOf(LongWord);

type TSharedMemoryRec = packed record
 shmid :Integer;
 MemLongInt :^LongWord;
 Usesful :Boolean;
end;

type TSharedMemoryConfig = packed record
 IdentValue :Longint;
 AccessMode :Longint;
 BlockSize :Longint;
end;

 procedure DefaultConfigForSharedMemory(var Config :TSharedMemoryConfig);

 function LainOpenSharedMemory(var SharedMemoryRec :TSharedMemoryRec; Config :TSharedMemoryConfig) :Boolean;
 function LainReadSheredMemory(var SharedMemoryRec :TSharedMemoryRec) :Longint;
 procedure LainWriteSharedMemory(var SharedMemoryRec :TSharedMemoryRec; Data :Longint);
 procedure LainCloseSharedMemory(var SharedMemoryRec :TSharedMemoryRec);
 
{$endif}

implementation

{$ifdef unix}

 procedure DefaultConfigForSharedMemory(var Config :TSharedMemoryConfig);
 begin
  Config.IdentValue := Default_IdentValue;
  Config.AccessMode := Default_AccessMode;
  Config.BlockSize := Default_BlockSize;
 end;

 function LainOpenSharedMemory(var SharedMemoryRec :TSharedMemoryRec; Config :TSharedMemoryConfig) :Boolean;
 begin
  SharedMemoryRec.shmid := shmget(Config.IdentValue, Config.BlockSize, Config.AccessMode);
  if SharedMemoryRec.shmid = -1 then
   Exit(False);
  SharedMemoryRec.MemLongInt := shmat(SharedMemoryRec.shmid, nil, 0);
  if Integer(SharedMemoryRec.MemLongInt) = -1 then
   Exit(False);
  SharedMemoryRec.Usesful := True;
 end;
 
 function LainReadSheredMemory(var SharedMemoryRec :TSharedMemoryRec) :Longint;
 begin
  Result := SharedMemoryRec.MemLongInt^;
 end;
 
 procedure LainWriteSharedMemory(var SharedMemoryRec :TSharedMemoryRec; Data :Longint);
 begin
  SharedMemoryRec.MemLongInt^ := Data
 end;
 
 procedure LainCloseSharedMemory(var SharedMemoryRec :TSharedMemoryRec);
 begin
  shmdt(SharedMemoryRec.MemLongInt);
  SharedMemoryRec.Usesful := False;
 end;

{$endif}

end.

