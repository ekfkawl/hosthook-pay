unit Hook.Types;

interface

uses
  Winapi.Windows, System.SysUtils, System.DateUtils, System.Classes, System.StrUtils, Winapi.Messages, REST.Json, REST.Json.Types;

type
  TNotification = class
  private
    FKey: WideString;
    FPostTime: Int64;
    FPlatform: Integer;
    FVersion: Integer;
    FCategory: WideString;
    FTitle: WideString;
    FText: WideString;
    FPackageName: WideString;
    FTimestamp: Int64;
    FNotificationClass: Integer;
    FImportance: Integer;
    FAppName: WideString;
  published
    [JSONName('key')]
    property Key: WideString read FKey write Fkey;
    [JSONName('postTime')]
    property PostTime: Int64 read FPostTime write FPostTime;
    [JSONName('platform')]
    property Platform : Integer read FPlatform write FPlatform;
    [JSONName('version')]
    property Version: Integer read FVersion write FVersion;
    [JSONName('category')]
    property Category: WideString read FCategory write FCategory;
    [JSONName('title')]
    property Title: WideString read FTitle write FTitle;
    [JSONName('text')]
    property Text: WideString read FText write FText;
    [JSONName('packageName')]
    property PackageName: WideString read FPackageName write FPackageName;
    [JSONName('timestamp')]
    property Timestamp: Int64 read FTimestamp write FTimestamp;
    [JSONName('notificationClass')]
    property NotificationClass: Integer read FNotificationClass write FNotificationClass;
    [JSONName('importance')]
    property Importance: Integer read FImportance write FImportance;
    [JSONName('appName')]
    property AppName: WideString read FAppName write FAppName;
  public
    class function EpochMilliNow: Int64; static;
    class function UnixMilliToDateTime(EpochMs: Int64): TDateTime; static;
    function IsPast: Boolean;
  end;

implementation

{ TNotification }

class function TNotification.EpochMilliNow: Int64;
var
  LNow: TDateTime;
begin
  LNow:= Now;
  Result:= DateTimeToUnix(LNow, False) * 1000 + MilliSecondOf(LNow);
end;

class function TNotification.UnixMilliToDateTime(EpochMs: Int64): TDateTime;
begin
  Result:= UnixToDateTime(EpochMs div 1000);
  Result:= IncMilliSecond(Result, EpochMs mod 1000);
end;

function TNotification.IsPast: Boolean;
const
  GraceMs = 30 * 1000;
begin
  Result:= TimeStamp < (EpochMilliNow - GraceMs);
end;
end.
