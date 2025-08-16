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
      var ScanStartAddr:= UInt64(GetModuleHandle('YourPhone.Connectivity.Bluetooth.Managed.dll'));
      var ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('YourPhone.Connectivity.Bluetooth.Managed.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('BF 01 00 00 00 B8 03 00 00 00 83 7E 10 00', 0, procedure(Address: UInt64)
      begin
        HookNotifications(Address - $11, TMemoryHelper.GetInstance.GetLeaAddress(Address - $11));
      end);
    except
      on E: EAOBScanError do
        Writeln('%s', [E.ClassName + ', ' + E.Message]);
    end;
  end;

  LoadFilters;
end.
