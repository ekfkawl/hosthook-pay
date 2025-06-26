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
  Hook.Config in 'Hook.Config.pas',
  RedisUtils in 'RedisUtils.pas',
  DbgUtils in 'DbgUtils.pas';

begin
  {$IFDEF DEBUG}
  AllocConsole;
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}

  with TAOBScanner.GetInstance do
  begin
    try
      var ScanStartAddr:= UInt64(GetModuleHandle('YourPhone.Notifications.WinRT.dll'));
      var ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('YourPhone.Notifications.WinRT.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('48 8D 15 ?? ?? ?? ?? 48 8D 4C 24 28 E8 ?? ?? ?? ?? 90 F0 48', 0, procedure(Address: UInt64)
      begin
        HookNotifications(Address + $C, TMemoryHelper.GetInstance.GetCallAddress(Address + $C));
      end);
    except
      on E: EAOBScanError do
        Writeln('%s', [E.ClassName + ', ' + E.Message]);
    end;
  end;

  LoadFilters;
end.
