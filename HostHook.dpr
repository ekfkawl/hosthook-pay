library HostHook;

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  AOBScanUtils in 'AOBScanUtils.pas',
  TlHelp32Utils in 'TlHelp32Utils.pas',
  MemoryUtils in 'MemoryUtils.pas',
  Hook in 'Hook.pas',
  Hook.Types in 'Hook.Types.pas',
  Redis.Config in 'Redis.Config.pas',
  Redis.Utils in 'Redis.Utils.pas',
  DbgUtils in 'DbgUtils.pas';

begin
  {$IFDEF DEBUG}
  AllocConsole;
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}

  with TAOBScanner.GetInstance do
  begin
    try
      var ScanStartAddr:= UInt64(GetModuleHandle('YourPhone.Notifications.Managed.dll'));
      var ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('YourPhone.Notifications.Managed.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('48 8B C8 49 8B D6 4C 8D 1D ?? ?? ?? ?? 41 FF 13 48 8D 4E 38', 0, procedure(Address: UInt64)
      begin
        HookNotifications1(TMemoryHelper.GetInstance.GetLeaAddress(Address + 6));
      end);

      ScanStartAddr:= UInt64(GetModuleHandle('YourPhone.Notifications.WinRT.dll'));
      ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('YourPhone.Notifications.WinRT.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('48 8D 15 ?? ?? ?? ?? 48 8D 4C 24 28 E8 ?? ?? ?? ?? 90 F0 48' {'48 8B 16 4C 8D 4C 24 48 4C 8B C3 48 8B CF 48 8B C5 FF 15'}, 0, procedure(Address: UInt64)
      begin
        HookNotifications2(Address + $C, TMemoryHelper.GetInstance.GetCallAddress(Address + $C));
      end);
    except
      on E: EAOBScanError do
        Writeln('%s%s%s', [E.ClassName, ', ', E.Message]);
    end;
  end;
end.
