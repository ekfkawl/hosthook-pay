unit Hook;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils, Winapi.Messages, System.Math, REST.Json, System.DateUtils, Generics.Collections,
  MemoryUtils, TlHelp32Utils, DbgUtils, Hook.Types;

procedure HookNotifications1(OrigAddr: Pointer);
procedure HookNotifications2(HookAddr: UInt64; OrigAddr: Pointer);

implementation

const
  KEY_TAG: WideString = '{"key":"';

var
  pOrigNotifications1: function(Unused1, Buffer: UInt64): Pointer;
  pOrigNotifications2: procedure(Buffer, Unused1: UInt64);

  DupKeyFilter: TDictionary<WideString, Byte>;
  TitleFilter: TDictionary<WideString, Byte>;
  PackageFilter: TDictionary<WideString, Byte>;

function IsValidNotification(Noti: TNotification): Boolean;
begin
  Result:= False;

  if DupKeyFilter.Count > 1_000 then
    DupKeyFilter.Clear;

  if not DupKeyFilter.TryAdd(Noti.Key, 0) then
    Exit;

  if not Noti.IsRecentNotification then
    Exit;

  if not TitleFilter.ContainsKey(Noti.Title) then
    Exit;

  if not PackageFilter.ContainsKey(Noti.PackageName) then
    Exit;

  Result:= True;
end;

function HijacNotifications(Unused1, Buffer: UInt64): Pointer;
var
  pBuffer: PWideChar;
  Noti: TNotification;
  i: UInt32;
  FindOffset: Boolean;
begin
  Result:= pOrigNotifications1(Unused1, Buffer);

  try
    if Buffer <= 0 then
      Exit;
      
    const BufferBase = PUInt64(Buffer + $30)^;
    if BufferBase <= 0 then
      Exit;

    i:= 8;
    FindOffset:= False;
    while i <= $200 do
    begin
      if CompareMem(Ptr(BufferBase + i), Ptr(UInt64(KEY_TAG)), SizeOf(KEY_TAG)) then
      begin
        FindOffset:= True;
        break;
      end;
      Inc(i, 4);
    end;

    if not FindOffset then
      Exit;

    pBuffer:= Ptr(BufferBase + i);
    Noti:= TJson.JsonToObject<TNotification>(pBuffer);
    try
      if not IsValidNotification(Noti) then
        Exit;

      Writeln('1: %s%s%s%s%s', [#13#10, Noti.Title, #13#10, Noti.Text, #13#10]);

    finally
      Noti.Free;
    end;
  except;
  end;
end;

procedure HookNotifications1(OrigAddr: Pointer);
begin
  PackageFilter.Add('com.apple.MobileSMS', 0);

  pOrigNotifications1:= PPointer(OrigAddr)^;
  TThread.CreateAnonymousThread(
    procedure
    begin
      while True do
      begin
        Sleep(1);
        if PPointer(OrigAddr)^ <> @HijacNotifications then
          PPointer(OrigAddr)^:= @HijacNotifications;
      end;
    end).Start;
end;

procedure HijacNotifications2(Buffer, Unused1: UInt64);
var
  pBuffer: PWideChar;
  Noti: TNotification;
begin
  pOrigNotifications2(Buffer, Unused1);

  try
    if Buffer <= 0 then
      Exit;

    const BufferBase = PUInt64(PUInt64(PUInt64(Buffer)^)^ + $10)^;
    if BufferBase <= 0 then
      Exit;

    if not CompareMem(Ptr(BufferBase), Ptr(UInt64(KEY_TAG)), SizeOf(KEY_TAG)) then
      Exit;

    pBuffer:= Ptr(BufferBase);
    Noti:= TJson.JsonToObject<TNotification>(pBuffer);
    try
      if not IsValidNotification(Noti) then
        Exit;

      Writeln('2: %s%s%s%s%s', [#13#10, Noti.Title, #13#10, Noti.Text, #13#10]);

    finally
      Noti.Free;
    end;
  except;
  end;
end;

procedure HookNotifications2(HookAddr: UInt64; OrigAddr: Pointer);
begin
  pOrigNotifications2:= OrigAddr;
  with TMemoryHelper.GetInstance do
  begin
    const Chain = AllocAbove(UInt64(OrigAddr));
    JumpHook(Chain, @HijacNotifications2);
    CallHook(HookAddr, Ptr(Chain));
  end;
end;

initialization
  DupKeyFilter:= TDictionary<WideString, Byte>.Create;
  TitleFilter:= TDictionary<WideString, Byte>.Create;
  PackageFilter:= TDictionary<WideString, Byte>.Create;

finalization
  DupKeyFilter.Free;
  TitleFilter.Free;
  PackageFilter.Free;

end.
