library HostHook;

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  AOBScanUtil in 'AOBScanUtil.pas',
  TlHelp32Utils in 'TlHelp32Utils.pas',
  MemoryUtils in 'MemoryUtils.pas',
  Hook in 'Hook.pas',
  Hook.Types in 'Hook.Types.pas';

const
  ScanModuleName = 'YourPhone.Notifications.Managed.dll';
begin
  {$IFDEF DEBUG}
  AllocConsole;
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}

  const ScanStartAddr = UInt64(GetModuleHandle(ScanModuleName));
  const ScanEndAddr = ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize(ScanModuleName);
  with TAOBScanner.GetInstance do
  begin
    UpdateScanStructure(ScanStartAddr, ScanEndAddr);

    try
      // 1.25042.96.0
      TAOBScanner.GetInstance.AOBSCAN('48 8B C8 49 8B D6 4C 8D 1D ?? ?? ?? ?? 41 FF 13 48 8D 4E 38', 0, procedure(Address: UInt64)
      begin
        HookNotifications(TMemoryHelper.GetInstance.GetLeaAddress(Address + 6));
      end);
    except
      on E: EAOBScanError do
        Writeln('%s%s%s', [E.ClassName, ', ', E.Message]);
    end;
  end;
end.
