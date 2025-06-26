unit Hook.Config;

interface

uses
  Winapi.Windows, System.SysUtils, System.IOUtils, System.JSON, System.Generics.Collections;

type
  TRedisConfig = record
    Host, Password: string;
    Port: Word;
  end;

function GetRedisConfig: TRedisConfig;
procedure GetPackageFilter(out List: TList<WideString>);
procedure GetTitleFilter(out List: TList<WideString>);

const
  CUSTOM_SETTINGS_JSON = 'C:\hosthookpay.json';

implementation

function GetRedisConfig: TRedisConfig;
const
  DEFAULT_HOST = 'localhost';
  DEFAULT_PORT = 6379;
  DEFAULT_PASSWORD = '';
var
  JSONValue: TJSONValue;
  JObject, JRedis: TJSONObject;
begin
  Result.Host:= DEFAULT_HOST;
  Result.Port:= DEFAULT_PORT;
  Result.Password:= DEFAULT_PASSWORD;

  if not TFile.Exists(CUSTOM_SETTINGS_JSON) then
    Exit;

  JSONValue:= TJSONObject.ParseJSONValue(TFile.ReadAllText(CUSTOM_SETTINGS_JSON, TEncoding.UTF8), False, True);
  try
    if not (JSONValue is TJSONObject) then
      Exit;
    JObject:= JSONValue as TJSONObject;

    JRedis:= JObject.GetValue('Redis') as TJSONObject;
    if JRedis = nil then
      Exit;

    Result.Host:= JRedis.GetValue<string>('Host', DEFAULT_HOST);
    Result.Port:= JRedis.GetValue<Integer>('Port', DEFAULT_PORT);
    Result.Password:= JRedis.GetValue<string>('Password', DEFAULT_PASSWORD);
  finally
    JSONValue.Free;
  end;
end;

function ParseFilterArray(JSON: TJSONObject; const Name: string): TList<WideString>;
var
  Arr: TJSONArray;
  Elem: TJSONValue;
begin
  Result:= TList<WideString>.Create;
  Arr:= JSON.GetValue<TJSONArray>(Name);
  if Arr = nil then
    Exit;

  for Elem in Arr do
  begin
    if Elem is TJSONString then
    begin
      Result.Add(WideString(TJSONString(Elem).Value));
      Continue;
    end;

    if Elem is TJSONObject then
    begin
      var Obj:= TJSONObject(Elem);
      var Key:= Obj.GetValue<string>('Package', '');
      if Key = '' then
        Key:= Obj.GetValue<string>('Title', '');
      if Key <> '' then
        Result.Add(WideString(Key));
    end;
  end;
end;

procedure GetPackageFilter(out List: TList<WideString>);
var
  JSONValue: TJSONValue;
  JObject: TJSONObject;
begin
  if not TFile.Exists(CUSTOM_SETTINGS_JSON) then
  begin
    List:= TList<WideString>.Create;
    Exit;
  end;

  JSONValue:= TJSONObject.ParseJSONValue(TFile.ReadAllText(CUSTOM_SETTINGS_JSON, TEncoding.UTF8), False, True);
  try
    if (JSONValue is TJSONObject) then
    begin
      JObject:= JSONValue as TJSONObject;
      List:= ParseFilterArray(JObject, 'PackageFilter');
      Exit;
    end;
    List:= TList<WideString>.Create;
  finally
    JSONValue.Free;
  end;
end;

procedure GetTitleFilter(out List: TList<WideString>);
var
  JSONValue: TJSONValue;
  JObject: TJSONObject;
begin
  if not TFile.Exists(CUSTOM_SETTINGS_JSON) then
  begin
    List:= TList<WideString>.Create;
    Exit;
  end;

  JSONValue:= TJSONObject.ParseJSONValue(TFile.ReadAllText(CUSTOM_SETTINGS_JSON, TEncoding.UTF8), False, True);
  try
    if (JSONValue is TJSONObject) then
    begin
      JObject:= JSONValue as TJSONObject;
      List:= ParseFilterArray(JObject, 'TitleFilter');
      Exit;
    end;
    List:= TList<WideString>.Create;
  finally
    JSONValue.Free;
  end;
end;

end.
