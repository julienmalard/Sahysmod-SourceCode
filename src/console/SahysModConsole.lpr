{$mode Delphi}
program SahysModConsole;

uses
  SysUtils,
  Forms,
  Interfaces,
  UMain in 'UMain.pas',
  UDataMod in 'UDataMod.pas',
  UExtraUtils in 'UExtraUtils.pas',
  UInputData in 'UInputData.pas',
  UDataTest in 'UDataTest.pas',
  UInitialCalc in 'UInitialCalc.pas',
  UMainCalc in 'UMainCalc.pas';

var
  InitDir, OutDir: string;
  InitDirStr, OutDirStr: string;

begin
  Application.CreateForm(TDataMod, DataMod);

  InitDirStr:= ParamStr(1);
  OutDirStr:=  ParamStr(2);

  InitDir:= InitDirStr;
  OutDir:= OutDirStr;

  if FileExists (InitDir) then
    InputOpened:=true
  else
    begin
      Writeln ('Input file does not exist.');
      Write(InitDir);
      exit;
    end;
    InputOpen_Execute(InitDir, OutDir);
end.
