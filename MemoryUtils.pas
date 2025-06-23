unit MemoryUtils;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils;

type
  EOpenProcess = class(Exception);
  EMemoryRead = class(Exception);
  EMemoryWrite = class(Exception);
  TMemoryHelper = class
  private
  public
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: TMemoryHelper;
    procedure Read(SourceAddress: UInt64; DestinationAddress: Pointer; Size: DWORD); overload;
    function Read<T>(SourceAddress: UInt64): T; overload;
    procedure Write<T>(Address: UInt64; const Buffer: T); overload;
    procedure Write(DestinationAddress: UInt64; SourceAddress: Pointer; Size: DWORD); overload;
    procedure Copy(DestinationAddress, SourceAddress, Size: UInt64);
    function AllocAbove(MinimumAddress: UInt64; Size: UInt64 = 4096): UInt64;
    function Alloc(Length: NativeUInt = 4096): UInt64;
    procedure CallHook(HookAddress: UInt64; DestAddress: Pointer; NopCount: Byte = 0);
    procedure JumpHook(HookAddress: UInt64; DestAddress: Pointer);
    function GetCallAddress(Address: UInt64): Pointer;
    function GetLeaAddress(Address: UInt64): Pointer;
  end;

implementation

var
  SingletonInstance: TMemoryHelper;

{ TMemoryHelper }

constructor TMemoryHelper.Create;
begin
  inherited Create;
end;

destructor TMemoryHelper.Destroy;
begin
  inherited;
end;

class function TMemoryHelper.GetInstance: TMemoryHelper;
begin
  if not Assigned(SingletonInstance) then
    SingletonInstance:= TMemoryHelper.Create;
  Result:= SingletonInstance;
end;

procedure TMemoryHelper.Read(SourceAddress: UInt64; DestinationAddress: Pointer; Size: DWORD);
begin
  if Size = 0 then
    Exit;
  CopyMemory(DestinationAddress, Ptr(SourceAddress), Size);
end;

function TMemoryHelper.Read<T>(SourceAddress: UInt64): T;
begin
  Read(SourceAddress, @Result, SizeOf(Result));
end;

procedure TMemoryHelper.Write<T>(Address: UInt64; const Buffer: T);
begin
  Write(Address, @Buffer, SizeOf(Buffer));
end;

procedure TMemoryHelper.Write(DestinationAddress: UInt64; SourceAddress: Pointer; Size: DWORD);
begin
  if Size = 0 then
    Exit;
  CopyMemory(Ptr(DestinationAddress), SourceAddress, Size);
end;

procedure TMemoryHelper.Copy(DestinationAddress, SourceAddress, Size: UInt64);
var
  Buffer: array of Byte;
begin
  SetLength(Buffer, Size);
  Read(SourceAddress, @Buffer[0], Size);
  Write(DestinationAddress, @Buffer[0], Size);
end;

function TMemoryHelper.AllocAbove(MinimumAddress: UInt64; Size: UInt64 = 4096): UInt64;
var
  TestAddress: NativeUInt;
begin
  TestAddress:= (MinimumAddress + 4096 - 1) and not (4096 - 1);
  while True do
  begin
    Result:= UInt64(VirtualAlloc(Ptr(TestAddress), Size, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE));
    if Result <> 0 then
      Exit
    else if GetLastError = ERROR_INVALID_ADDRESS then
      Inc(TestAddress, 4096);
  end;
end;

function TMemoryHelper.Alloc(Length: NativeUInt = 4096): UInt64;
begin
  Result:= UInt64(VirtualAlloc(nil, Length, MEM_COMMIT, PAGE_EXECUTE_READWRITE));
end;

procedure TMemoryHelper.CallHook(HookAddress: UInt64; DestAddress: Pointer; NopCount: Byte = 0);
type
  TAbsCall = packed record
    MovRax: Word;
    Target: UInt64;
    CallRax: Word;
  end;
var
  OldProtect: DWORD;
  Offs64: Int64;
  Rel32: Int32;
  Stub: TAbsCall;
  i: DWORD;
begin
  if not VirtualProtect(Ptr(HookAddress), SizeOf(TAbsCall), PAGE_EXECUTE_READWRITE, OldProtect) then
    Exit;

  try
    Offs64:= Int64(NativeUInt(DestAddress)) - Int64(HookAddress) - 5;
    if (Offs64 >= Low(Int32)) and (Offs64 <= High(Int32)) then
    begin
      Write<Byte>(HookAddress, $E8);
      Rel32:= Int32(Offs64);
      Write<Int32>(HookAddress + 1, Rel32);
      if NopCount > 0 then
      begin
        for i:= 0 to NopCount - 1 do
          Write<Byte>(HookAddress + 5 + i, $90);
      end;
    end
    else begin
      Stub.MovRax:= $B848;
      Stub.Target:= UInt64(DestAddress);
      Stub.CallRax:= $D0FF;
      Write(HookAddress, @Stub, SizeOf(Stub));
    end;
  finally
    VirtualProtect(Ptr(HookAddress), SizeOf(TAbsCall), OldProtect, @OldProtect);
  end;
end;

procedure TMemoryHelper.JumpHook(HookAddress: UInt64; DestAddress: Pointer);
type
  TAbsJump = packed record
    MovRax: Word;
    Target: UInt64;
    JmpRax: Word;
  end;
var
  OldProtect: DWORD;
  Offs64: Int64;
  Rel32: Int32;
  Stub: TAbsJump;
begin
  if not VirtualProtect(Ptr(HookAddress), SizeOf(TAbsJump), PAGE_EXECUTE_READWRITE, OldProtect) then
    Exit;

  try
    Offs64:= Int64(NativeUInt(DestAddress)) - Int64(HookAddress) - 5;
    if (Offs64 >= Low(Int32)) and (Offs64 <= High(Int32)) then
    begin
      Write<Byte>(HookAddress, $E9);
      Rel32:= Int32(Offs64);
      Write<Int32>(HookAddress + 1, Rel32);
    end
    else begin
      Stub.MovRax:= $B848;
      Stub.Target:= UInt64(DestAddress);
      Stub.JmpRax:= $E0FF;
      Write(HookAddress, @Stub, SizeOf(Stub));
    end;
  finally
    VirtualProtect(Ptr(HookAddress), SizeOf(TAbsJump), OldProtect, @OldProtect);
  end;
end;

function TMemoryHelper.GetCallAddress(Address: UInt64): Pointer;
var
  Rel32: Int32;
begin
  Rel32:= Read<Integer>(Address + 1);
  Result:= Ptr(Address + 5 + UInt64(Rel32));
end;

function TMemoryHelper.GetLeaAddress(Address: UInt64): Pointer;
var
  Disp32: Int32;
  InstrSize: UInt64;
  FirstByte: Byte;
begin
  FirstByte:= PByte(Address)^;

  if (FirstByte and $F0) = $40 then
  begin
    InstrSize:= 7;
    Disp32:= Read<Integer>(Address + 3);
  end
  else begin
    InstrSize:= 6;
    Disp32:= Read<Integer>(Address + 2);
  end;

  Result:= Pointer(Address + InstrSize + UInt64(Disp32));
end;

initialization
  SingletonInstance:= nil;

finalization
  SingletonInstance.Free;

end.
