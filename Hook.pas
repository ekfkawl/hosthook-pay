unit Hook;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils, Winapi.Messages, System.Math, REST.Json, System.DateUtils,
  MemoryUtils, TlHelp32Utils, Hook.Types;

procedure HookNotifications(OrigAddr: Pointer);
procedure Writeln(const Fmt: string; const Args: array of const);

implementation

var
  pOrigNotifications: function(Unused1, Buffer: UInt64): Pointer;

function HijacNotifications(Unused1, Buffer: UInt64): Pointer;
const
  KEY_TAG: WideString = '{"key":"';
var
  pBuffer: PWideChar;
  Noti: TNotification;
  i: UInt32;
  FindOffset: Boolean;
begin
  Result:= pOrigNotifications(Unused1, Buffer);

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
      if Noti.PackageName <> 'com.apple.MobileSMS' then
        Exit;

      if Noti.IsPast then
        Exit;

      Writeln('%s%s%s', [Noti.Title, #13#10, Noti.Text]);
    finally
      Noti.Free;
    end;
  except;
  end;
end;

procedure HookNotifications(OrigAddr: Pointer);
begin
  pOrigNotifications:= PPointer(OrigAddr)^;
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

procedure Writeln(const Fmt: string; const Args: array of const);
begin
  {$IFDEF DEBUG}
  System.Writeln(Format(Fmt, Args));
  {$ENDIF}
end;
end.
