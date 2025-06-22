unit AOBScanUtil;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils, System.Types, Generics.Collections;

type
  TScanStructure = record
    Value: string;
    StartAddr: UInt64;
    EndAddr: UInt64;
  end;

  EAOBScanError = class(Exception);
  TAOBScanner = class
  private
    FScanStructure: TScanStructure;
    constructor Create;
    function InitializePattern(const Value: string): TByteDynArray;
    function ReadMemory(const BaseAddress: Pointer; Size: SIZE_T): TBytes;
    function IsPatternMatch(const Buffer: TBytes; const Pattern: TByteDynArray): boolean;
  public
    class function GetInstance: TAOBScanner;
    function AOBSCAN: TList<UInt64>; overload;
    function AOBSCAN(Val: string; Index: Integer = 0): UInt64; overload;
    function AOBSCAN(Val: string; Index: Integer; CallbackProc: TProc<UInt64>): UInt64; overload;
    procedure UpdateScanStructure(AStartAddr, AEndAddr: UInt64);
  end;

implementation

var
  SingletonInstance: TAOBScanner;

{ TAOBScanner }

constructor TAOBScanner.Create;
begin
  inherited Create;
end;

class function TAOBScanner.GetInstance: TAOBScanner;
begin
  if not Assigned(SingletonInstance) then
    SingletonInstance:= TAOBScanner.Create;
  Result:= SingletonInstance;
end;

function TAOBScanner.InitializePattern(const Value: string): TByteDynArray;
var
  ArrStr: TStringDynArray;
begin
  ArrStr:= SplitString(Trim(Value), ' ');
  SetLength(Result, Length(ArrStr));
  for var i:= 0 to High(ArrStr) do
    if ArrStr[i] <> '??' then
      Result[i]:= ('0x' + ArrStr[i]).ToInteger
    else
      Result[i]:= 0;
end;

function TAOBScanner.ReadMemory(const BaseAddress: Pointer; Size: SIZE_T): TBytes;
begin
  SetLength(Result, Size);
  CopyMemory(Result, BaseAddress, Size);
end;

function TAOBScanner.IsPatternMatch(const Buffer: TBytes; const Pattern: TByteDynArray): Boolean;
var
  i: Integer;
begin
  Result:= False;
  if Length(Buffer) < Length(Pattern) then
    Exit;

  for i:= 0 to High(Pattern) do
    if (Pattern[i] <> 0) and (Buffer[i] <> Pattern[i]) then
      Exit;

  Result:= True;
end;

function TAOBScanner.AOBSCAN: TList<UInt64>;
var
  PrevScanAddr, ScanAddr: Pointer;
  mbi: TMemoryBasicInformation;
  Pattern, Buffer: TBytes;
  BaseAddress: UInt64;
  i: NativeUInt;
  prot: DWORD;
begin
  Result:= TList<UInt64>.Create;
  Pattern:= InitializePattern(FScanStructure.Value);
  ScanAddr:= Ptr(FScanStructure.StartAddr);

  while UInt64(ScanAddr) < FScanStructure.EndAddr do
  begin
    PrevScanAddr:= ScanAddr;
    if VirtualQuery(ScanAddr, mbi, SizeOf(mbi)) = 0 then
      break;

    try
      if mbi.RegionSize <= 0 then
      begin
        mbi.RegionSize:= $1000;
        Continue;
      end;

      if mbi.State <> MEM_COMMIT then
        Continue;

      prot:= mbi.Protect and $FF;
      if (prot = PAGE_EXECUTE_READ) or (prot = PAGE_EXECUTE) then
      begin
        Buffer:= ReadMemory(mbi.BaseAddress, mbi.RegionSize);
        BaseAddress:= UInt64(mbi.BaseAddress);
        if Length(Buffer) > 0 then
          for i:= 0 to High(Buffer) - Length(Pattern) + 1 do
            if IsPatternMatch(Copy(Buffer, i, Length(Pattern)), Pattern) then
              Result.Add(BaseAddress + i);
      end;
    finally
      ScanAddr:= Ptr(UInt64(mbi.BaseAddress) + mbi.RegionSize);
      if ScanAddr = PrevScanAddr then
        ScanAddr:= Ptr(UInt64(mbi.BaseAddress) + $1000);
    end;
  end;
end;

function TAOBScanner.AOBSCAN(Val: string; Index: Integer = 0): UInt64;
var
  Results: TList<UInt64>;
begin
  FScanStructure.Value:= Val;
  Results:= AOBSCAN;
  try
    if (Index < Results.Count) then
      Result:= Results[Index]
    else
      raise EAOBScanError.CreateFmt('AOB scan failed (pattern="%s")', [Val]);
  finally
    Results.Free;
  end;
end;

function TAOBScanner.AOBSCAN(Val: string; Index: Integer; CallbackProc: TProc<UInt64>): UInt64;
begin
  FScanStructure.Value:= Val;
  Result:= AOBSCAN(Val, Index);
  if (Result > 0) and (Assigned(CallbackProc)) then
    CallbackProc(Result);
end;

procedure TAOBScanner.UpdateScanStructure(AStartAddr, AEndAddr: UInt64);
begin
  FScanStructure.StartAddr:= AStartAddr;
  FScanStructure.EndAddr:= AEndAddr;
end;

initialization
  SingletonInstance:= nil;

finalization
  if Assigned(SingletonInstance) then
    SingletonInstance.Free;

end.
