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
      var ScanStartAddr:= UInt64(GetModuleHandle('Windows.Web.dll'));
      var ScanEndAddr:= ScanStartAddr + TProcessHelper.GetInstance.GetModuleSize('Windows.Web.dll');
      UpdateScanStructure(ScanStartAddr, ScanEndAddr);
      TAOBScanner.GetInstance.AOBSCAN('0F 1F 44 00 00 83 65 FC 00 48 8D 4D F0 4C 8B C3 48 89 45 F0 33 D2 89 ?? F8 E8 ?? ?? ?? ?? 8B ?? 85 C0 0F 88', 0, procedure(Address: UInt64)
      begin
        HookNotifications(Address - $7, TMemoryHelper.GetInstance.GetLeaAddress(Address - $7));
      end);

    except
      on E: EAOBScanError do
        Writeln('%s', [E.ClassName + ', ' + E.Message]);
    end;
  end;

  LoadFilters;
end.
