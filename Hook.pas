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
  pOrigNotifications: function(Unused1, Unused2: Pointer): Pointer;

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

function HijacNotifications(Unused1, Unused2: Pointer): Pointer;
var
  Res: Pointer;
  pBuffer: PWideChar;
  Noti: TNotification;
begin
  Res:= pOrigNotifications(Unused1, Unused2);

  pBuffer:= Ptr(PUInt64(UInt64(Res) + $8)^ + $C);
  try
    if not CompareMem(pBuffer, Ptr(UInt64(KEY_TAG)), SizeOf(KEY_TAG)) then
      Exit(Res);

    Noti:= TJson.JsonToObject<TNotification>(pBuffer);
    try
      if not IsValidNotification(Noti) then
        Exit(Res);

      Redis.Publish(TOPIC, pBuffer);

      Writeln('%s', [#13#10 + Noti.Title + #13#10 + Noti.Text, #13#10]);
    finally
      Noti.Free;
    end;
  except
    on E: Exception do
      Writeln('Error: %s', [E.ClassName + ' - ' + E.Message]);
  end;

  Result:= Res;
end;

procedure HookNotifications(HookAddr: UInt64; OrigAddr: Pointer);
begin
  pOrigNotifications:= PPointer(OrigAddr)^;
  with TMemoryHelper.GetInstance do
  begin
    const Chain = AllocAbove(UInt64(OrigAddr));
    JumpHook(Chain, @HijacNotifications);
    CallHook(HookAddr, Ptr(Chain), 5);
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
