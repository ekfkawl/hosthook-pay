unit DbgUtils;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

procedure Writeln(const Fmt: string; const Args: array of const);

implementation

procedure Writeln(const Fmt: string; const Args: array of const);
begin
  {$IFDEF DEBUG}
  System.Writeln(Format(Fmt, Args));
  {$ENDIF}
end;

end.
