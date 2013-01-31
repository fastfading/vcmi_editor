{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013 Alexander Shishkin alexvins@users.sourceforge.net

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

unit zlib_stream;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, ctypes, zlib;

type

  { TZlibInputStream }

  TZlibInputStream = class (TStream)
  strict private
    procedure PreInit(AInput: TStream; ADecompressedSize: SizeUInt);

  strict private
    FInput: TStream;
    FDecompressedSize: SizeUInt;

    FPosition: Int64;
    FOutputBuffer: TBytes;
    FInputBuffer: TBytes;

    FState: TZStream;

    //FInflateFinished:  Boolean;

    procedure DecompressTill(APosition: Int64);

  protected
    function GetPosition: Int64; override;
    function GetSize: Int64; override;
  public
    constructor Create(AInput: TStream; ADecompressedSize: SizeUInt);
    constructor CreateGZip(AInput: TStream; ADecompressedSize: SizeUInt);
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
      overload;



  end;


implementation

uses
  Math;

const
  INFLATE_BLOCK_SIZE = 10240;

{ TZlibInputStream }

constructor TZlibInputStream.Create(AInput: TStream; ADecompressedSize: SizeUInt);
var
  ret: cint;
begin

  PreInit(AInput,ADecompressedSize);

  ret := inflateInit(FState);
  if not ret = Z_OK then
  begin
    raise Exception.Create('Error init decompression');
  end;
  //FInflateFinished := False;
end;

constructor TZlibInputStream.CreateGZip(AInput: TStream; ADecompressedSize: SizeUInt
  );
var
  ret: cint;
  bits: Integer;
begin
  PreInit(AInput,ADecompressedSize);

  bits := 31;

  ret := inflateInit2(FState,bits);
  if not ret = Z_OK then
  begin
    raise Exception.Create('Error init decompression');
  end;
  //FInflateFinished := False;

end;

procedure TZlibInputStream.DecompressTill(APosition: Int64);
var
  to_end, file_ended, end_loop: Boolean;

  read_amount: Int64;
  ret: cint;
begin
  Assert(APosition < (100 * 1024 * 1024), 'File too large'); //just in case

  //if FInflateFinished then Exit;

  if (APosition >= 0) and (APosition <= FState.total_out) then
     Exit; //no need to decompress anything

  to_end := APosition < 0;

  if to_end and (Length(FOutputBuffer) = 0) then
    SetLength(FOutputBuffer, 16*1024);

  if (not to_end) and (Length(FOutputBuffer) < APosition) then
    SetLength(FOutputBuffer,APosition);

  file_ended := False;
  end_loop := False;

  repeat
    if FState.avail_in = 0 then
    begin
      read_amount := FInput.Read( FInputBuffer[0], Length(FInputBuffer));

      if read_amount <> Length(FInputBuffer) then
      begin
        file_ended := True;
      end;

      FState.avail_in := read_amount;
      FState.next_in := @FInputBuffer[0];
    end;

    FState.avail_out := Length(FOutputBuffer) - FState.total_out;
    {$push}{$r-}
    FState.next_out := @FOutputBuffer[FState.total_out];
    {$pop}

    ret := inflate(FState, Z_NO_FLUSH);

    case ret of
      Z_STREAM_END: end_loop := True;
      z_OK: end_loop := False ;
      Z_BUF_ERROR:begin
        if to_end then
        begin
          SetLength(FOutputBuffer,Length(FOutputBuffer)*2);
          end_loop := True;
        end
        else begin
          if not FState.total_out = FPosition then
          begin
            raise Exception.Create('Decomression error');
          end;
          end_loop := True;
        end;
      end;
      else
        raise Exception.Create('Decomression error');
    end;
  until end_loop;

  //if file_ended then
  //begin
  //  //inflateEnd(FState);
  //  FDecompressedSize := FState.total_out;
  //  //SetLength(FOutputBuffer,FDecompressedSize);
  //  //FInflateFinished := true;
  //end
  //else begin
    FDecompressedSize := FState.total_out;
  //end;
end;

destructor TZlibInputStream.Destroy;
begin
  inflateEnd(FState);
  inherited Destroy;
end;

function TZlibInputStream.GetPosition: Int64;
begin
  Result := FPosition;
end;

function TZlibInputStream.GetSize: Int64;
begin
  DecompressTill(-1);
  Result := FDecompressedSize;
end;

procedure TZlibInputStream.PreInit(AInput: TStream; ADecompressedSize: SizeUInt);
begin
  FInput := AInput;
  Assert(Assigned(AInput), 'TZlibStream: nil input stream');

  SetLength(FInputBuffer, INFLATE_BLOCK_SIZE);
  SetLength(FOutputBuffer, ADecompressedSize);

  FDecompressedSize := 0;
  FPosition := 0;


end;

function TZlibInputStream.Read(var Buffer; Count: Longint): Longint;
begin
  DecompressTill(FPosition+Count);

  Result := Min(Count,FDecompressedSize - FPosition);

  Move(FOutputBuffer[FPosition], Buffer,Result);

  inc(FPosition,Count)
end;

function TZlibInputStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var
  new_position: Int64;
begin
  case Origin of
    soBeginning:begin
      new_position := Offset;
    end;
    soCurrent:begin
      new_position := Offset + FPosition;
    end;
    soEnd: Assert(False);
  end;

  DecompressTill(new_position);

  FPosition := Min(new_position, FDecompressedSize);
  Result := FPosition;
end;

end.

