unit TlHelp32Utils;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, TlHelp32;

type
  TProcessHelper = class
  private
    FProcessId: THandle;
    constructor Create(ProcessId: THandle = 0);
  public
    class function GetInstance: TProcessHelper;
    function GetProcessId(const AProcessName: String): DWORD; overload;
    function GetProcessId: DWORD; overload;
    procedure SetProcessId(ProcessId: THandle);
    function GetModuleBase(const ModuleName: string): Pointer;
    function GetModuleSize(const ModuleName: string): Cardinal;
  end;

implementation

var
  SingletonInstance: TProcessHelper;

constructor TProcessHelper.Create(ProcessId: THandle = 0);
begin
  FProcessId:= ProcessId;
  inherited Create;
end;

class function TProcessHelper.GetInstance: TProcessHelper;
begin
  if not Assigned(SingletonInstance) then
    SingletonInstance:= TProcessHelper.Create;
  Result:= SingletonInstance;
end;

function TProcessHelper.GetProcessId(const AProcessName: String): DWORD;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  hSnapshot: THandle;
  pe32: TProcessEntry32;
  hProc: THandle;
  CreationTime, ExitTime, KernelTime, UserTime: FILETIME;
  LatestCreationFT: UInt64;
  CurrentFT: UInt64;
begin
  Result:= 0;
  LatestCreationFT:= 0;

  hSnapshot:= CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnapshot = INVALID_HANDLE_VALUE) then
    Exit;

  try
    pe32.dwSize:= SizeOf(pe32);
    if Process32First(hSnapshot, pe32) then
    begin
      repeat
        if SameText(pe32.szExeFile, AProcessName) then
        begin
          hProc:= OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pe32.th32ProcessID);
          if hProc <> 0 then
          begin
            try
              if GetProcessTimes(hProc, CreationTime, ExitTime, KernelTime, UserTime) then
              begin
                CurrentFT:= (UInt64(CreationTime.dwHighDateTime) shl 32) or UInt64(CreationTime.dwLowDateTime);
                if CurrentFT > LatestCreationFT then
                begin
                  LatestCreationFT:= CurrentFT;
                  Result:= pe32.th32ProcessID;
                  FProcessId:= pe32.th32ProcessID;
                end;
              end;
            finally
              CloseHandle(hProc);
            end;
          end;
        end;
      until not Process32Next(hSnapshot, pe32);
    end;
  finally
    CloseHandle(hSnapshot);
  end;
end;

function TProcessHelper.GetProcessId: DWORD;
begin
  Result:= FProcessId;
end;

procedure TProcessHelper.SetProcessId(ProcessId: THandle);
begin
  FProcessId:= ProcessId;
end;

function QueryModuleEntry(const ProcessID: THandle; const ModuleName: string; out ME: MODULEENTRY32): Boolean;
const
  TH32CS_SNAPMODULE32 = $00000010;
var
  hSnap: THandle;
begin
  Result:= False;
  FillChar(ME, SizeOf(ME), 0);
  ME.dwSize:= SizeOf(ME);

  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPMODULE or TH32CS_SNAPMODULE32, ProcessID);
  if hSnap = INVALID_HANDLE_VALUE then
    Exit;

  try
    if Module32First(hSnap, ME) then
    repeat
      if SameText(ME.szModule, ModuleName) then
        Exit(True);
    until not Module32Next(hSnap, ME);
  finally
    CloseHandle(hSnap);
  end;
end;

function TProcessHelper.GetModuleBase(const ModuleName: string): Pointer;
var
  ME: MODULEENTRY32;
begin
  if QueryModuleEntry(FProcessId, ModuleName, ME) then
    Result:= ME.modBaseAddr
  else
    Result:= nil;
end;

function TProcessHelper.GetModuleSize(const ModuleName: string): Cardinal;
var
  ME: MODULEENTRY32;
begin
  if QueryModuleEntry(FProcessId, ModuleName, ME) then
    Result:= ME.modBaseSize
  else
    Result:= 0;
end;

initialization
  SingletonInstance:= nil;

finalization
  if Assigned(SingletonInstance) then
    SingletonInstance.Free;

end.
