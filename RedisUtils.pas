unit RedisUtils;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.SyncObjs, System.Generics.Collections,
  System.Threading, Redis.Client, Redis.Commons, Redis.NetLib.INDY, Hook.Config;

type
  TRedis = class
  private
    FRedisClient: IRedisClient;
    FRedisSubscriber: IRedisClient;
    FIsDestroyed: Boolean;
    FLock: TCriticalSection;
    FSubscribedTopics: TList<string>;
    FCallbacks: TDictionary<string, TProc<string, string>>;
    FPingTask: ITask;
    FSubscribeTask: ITask;
    procedure InitClient;
    procedure InitSubscriber;
    procedure ReconnectClientOnly;
    procedure StartPingLoop;
    procedure StartSubscribeLoop;
    function IsClientConnected: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    class function GetInstance: TRedis; static;
    procedure Publish(const Topic, Message: string);
    procedure Subscribe(const Topic: string; Callback: TProc<string, string>);
  end;

var
  SingletonInstance: TRedis;

implementation

const
  CMD_TIMEOUT_MS = 3000;
  PING_INTERVAL_MS = 5000;
  RECONNECT_BASE_MS = 1000;

{ TRedis }

constructor TRedis.Create;
begin
  inherited Create;
  FLock:= TCriticalSection.Create;
  FSubscribedTopics:= TList<string>.Create;
  FCallbacks:= TDictionary<string, TProc<string, string>>.Create;

  InitClient;
  StartPingLoop;
end;

procedure TRedis.InitClient;
var
  cfg: TRedisConfig;
begin
  cfg:= GetRedisConfig;
  FLock.Enter;
  try
    if Assigned(FRedisClient) then
      FRedisClient.Disconnect;

    FRedisClient:= NewRedisClient(cfg.Host, cfg.Port);
    FRedisClient.SetCommandTimeout(CMD_TIMEOUT_MS);
    if cfg.Password <> '' then
      FRedisClient.AUTH(cfg.Password);
  finally
    FLock.Leave;
  end;
end;

procedure TRedis.InitSubscriber;
var
  cfg: TRedisConfig;
begin
  cfg:= GetRedisConfig;
  FLock.Enter;
  try
    if Assigned(FRedisSubscriber) then
      FRedisSubscriber.Disconnect;

    FRedisSubscriber:= NewRedisClient(cfg.Host, cfg.Port);
    FRedisSubscriber.SetCommandTimeout(CMD_TIMEOUT_MS);
    if cfg.Password <> '' then
      FRedisSubscriber.AUTH(cfg.Password);
  finally
    FLock.Leave;
  end;
end;

procedure TRedis.ReconnectClientOnly;
var
  Backoff: Integer;
begin
  Backoff:= RECONNECT_BASE_MS;
  while not FIsDestroyed do
  begin
    try
      InitClient;
      Break;
    except
      Sleep(Backoff);
      if Backoff < 30000 then
        Backoff:= Backoff * 2;
    end;
  end;
end;

function TRedis.IsClientConnected: Boolean;
begin
  FLock.Enter;
  try
    try
      Result:= Assigned(FRedisClient) and (FRedisClient.PING = 'PONG');
    except
      Result:= False;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRedis.StartPingLoop;
begin
  FPingTask:= TTask.Run(
    procedure
    begin
      while not FIsDestroyed do
      begin
        if not IsClientConnected then
          ReconnectClientOnly;
        Sleep(PING_INTERVAL_MS);
      end;
    end);
end;

procedure TRedis.StartSubscribeLoop;
var
  Backoff: Integer;
  Topics: TArray<string>;
begin
  Backoff:= RECONNECT_BASE_MS;
  FSubscribeTask:= TTask.Run(
    procedure
    begin
      while not FIsDestroyed do
      begin
        FLock.Enter;
        try
          Topics:= FSubscribedTopics.ToArray;
        finally
          FLock.Leave;
        end;
        if Length(Topics) = 0 then
        begin
          Sleep(PING_INTERVAL_MS);
          Continue;
        end;

        try
          InitSubscriber;

          FRedisSubscriber.SUBSCRIBE(
            Topics,
            procedure(Topic, Msg: string)
            begin
              try
                FLock.Enter;
                try
                  if FCallbacks.ContainsKey(Topic) then
                    FCallbacks[Topic](Topic, Msg);
                finally
                  FLock.Leave;
                end;
              except
              end;
            end,
            function: Boolean
            begin
              Result:= not FIsDestroyed;
            end
          );

          Backoff:= RECONNECT_BASE_MS;
        except
          on E: Exception do
          begin
            Writeln('Subscribe error: ', E.Message);
            Sleep(Backoff);
            if Backoff < 15000 then
              Backoff:= Backoff * 2;
          end;
        end;
      end;
    end);
end;

procedure TRedis.Publish(const Topic, Message: string);
begin
  try
    FRedisClient.PUBLISH(Topic, Message);
  except
    on E: Exception do
    begin
      Writeln('Publish error: ', E.Message);
      ReconnectClientOnly;
      FRedisClient.PUBLISH(Topic, Message);
    end;
  end;
end;

procedure TRedis.Subscribe(const Topic: string; Callback: TProc<string, string>);
begin
  FLock.Enter;
  try
    if not FSubscribedTopics.Contains(Topic) then
    begin
      FSubscribedTopics.Add(Topic);
      FCallbacks.Add(Topic, Callback);
    end
    else
      FCallbacks[Topic]:= Callback;

    if FSubscribedTopics.Count = 1 then
      StartSubscribeLoop;
  finally
    FLock.Leave;
  end;
end;

class function TRedis.GetInstance: TRedis;
begin
  if not Assigned(SingletonInstance) then
    SingletonInstance:= TRedis.Create;
  Result:= SingletonInstance;
end;

destructor TRedis.Destroy;
begin
  FIsDestroyed:= True;
  if Assigned(FPingTask) then
    FPingTask.Wait;
  if Assigned(FSubscribeTask) then
    FSubscribeTask.Wait;

  FLock.Enter;
  try
    if Assigned(FRedisClient) then
      FRedisClient.Disconnect;
    if Assigned(FRedisSubscriber) then
      FRedisSubscriber.Disconnect;
  finally
    FLock.Leave;
  end;

  FSubscribedTopics.Free;
  FCallbacks.Free;
  FLock.Free;
  inherited;
end;

initialization
  SingletonInstance:= nil;

finalization
  SingletonInstance.Free;

end.

