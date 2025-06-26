program injector;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Messages,
  Winapi.Windows,
  TlHelp32,
  TlHelp32Utils in '..\TlHelp32Utils.pas';

type TInjectThread = class(TThread)
private
protected
  procedure Execute; override;
public
  constructor Create;
end;

procedure InjectDLL(hProcess: DWORD; DllPath: String);
var
  pRemoteBuffer: Pointer;
  ThreadId: DWORD;
  hThread: THandle;
begin
  pRemoteBuffer:= VirtualAllocEx(hProcess, nil, Length(DllPath), MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  if (pRemoteBuffer <> nil) And (WriteProcessMemory(hProcess, pRemoteBuffer, @DllPath[1], Length(DllPath) * 2, PSIZE_T(nil)^)) then
  begin
    hThread:= CreateRemoteThread(hProcess, nil, 0, GetProcAddress(LoadLibrary('kernel32.dll'), 'LoadLibraryW'), pRemoteBuffer, 0, ThreadId);
    WaitForSingleObject(hThread, 5000);
    VirtualFreeEx(hProcess, pRemoteBuffer, Length(DllPath), MEM_RELEASE);
    CloseHandle(hThread);
  end;
end;

{ TInjectThread }

constructor TInjectThread.Create;
begin
  inherited Create(False);
  FreeOnTerminate:= True;
end;

procedure TInjectThread.Execute;
begin
  while not Terminated do
  begin
    Sleep(1000);

    const ProcessId = TProcessHelper.GetInstance.GetProcessId('PhoneExperienceHost.exe');
    if ProcessId > 0 then
    begin
      const hProcess = OpenProcess(PROCESS_ALL_ACCESS, False, ProcessId);

      InjectDLL(hProcess, GetCurrentDir + '\HostHook.dll');
      CloseHandle(hProcess);

      ExitProcess(0);
    end;
  end;
end;

begin
  try
    TInjectThread.Create;
    Writeln('wait for PhoneExperienceHost.exe ...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
