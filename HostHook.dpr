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
      var ScanStartAddr:= UInt64(GetModuleHandle('YourPhone.Notifications.Managed.dll'));
      var ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('YourPhone.Notifications.Managed.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('48 8D 4E 38 48 8B D0 FF 15 ?? ?? ?? ?? FF 15 ?? ?? ?? ?? 4C 8B F0', 0, procedure(Address: UInt64)
      begin
        HookNotifications(Address - $A, TMemoryHelper.GetInstance.GetLeaAddress(Address - $A));
      end);

    except
      on E: EAOBScanError do
        Writeln('%s', [E.ClassName + ', ' + E.Message]);
    end;
  end;

  LoadFilters;
end.
