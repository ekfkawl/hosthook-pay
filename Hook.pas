unit Hook;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils, Winapi.Messages, System.Math, REST.Json, System.DateUtils, Generics.Collections,
  MemoryUtils, TlHelp32Utils, DbgUtils, Hook.Types, Hook.Config, RedisUtils;

procedure HookNotifications(HookAddr: UInt64; OrigAddr: Pointer);
procedure LoadFilters;

implementation

const
  KEY_TAG: WideString = '{"key":"';
  TOPIC = 'HostHookPayTopic';

var
  pOrigNotifications1: function(Unused1, Buffer: UInt64): Pointer;
  pOrigNotifications2: procedure(Buffer, Unused1: UInt64);

  DupKeyFilter: TDictionary<WideString, Byte>;
  TitleFilter: TDictionary<WideString, Byte>;
  PackageFilter: TDictionary<WideString, Byte>;

  Redis: TRedis;

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

procedure HijacNotifications(Buffer, Unused1: UInt64);
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

      Redis.Publish(TOPIC, pBuffer);

      Writeln('2: %s', [#13#10 + Noti.Title + #13#10 + Noti.Text, #13#10]);
    finally
      Noti.Free;
    end;
  except
    on E: Exception do
      Writeln('Error: %s', [E.ClassName + ' - ' + E.Message]);
  end;
end;

procedure HookNotifications(HookAddr: UInt64; OrigAddr: Pointer);
begin
  pOrigNotifications2:= OrigAddr;
  with TMemoryHelper.GetInstance do
  begin
    const Chain = AllocAbove(UInt64(OrigAddr));
    JumpHook(Chain, @HijacNotifications);
    CallHook(HookAddr, Ptr(Chain));
  end;
end;

procedure LoadFilters;
var
  PackageList, TitleList: TList<WideString>;
begin
  GetPackageFilter(PackageList);
  try
    for var s in PackageList do
    begin
      Writeln('Add PackageFilter: %s', [s]);
      PackageFilter.TryAdd(s, 0);
    end;
  finally
    PackageList.Free;
  end;

  GetTitleFilter(TitleList);
  try
    for var s in TitleList do
    begin
      Writeln('Add TitleFilter: %s', [s]);
      TitleFilter.TryAdd(s, 0);
    end;
  finally
    TitleList.Free;
  end;
end;

initialization
  DupKeyFilter:= TDictionary<WideString, Byte>.Create;
  TitleFilter:= TDictionary<WideString, Byte>.Create;
  PackageFilter:= TDictionary<WideString, Byte>.Create;
  Redis:= TRedis.Create;

finalization
  DupKeyFilter.Free;
  TitleFilter.Free;
  PackageFilter.Free;
  Redis.Free;

end.
