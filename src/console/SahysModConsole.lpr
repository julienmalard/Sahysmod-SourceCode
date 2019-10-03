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
  step: boolean;

begin
  Application.CreateForm(TDataMod, DataMod);
  step:= true;
  while step do
  begin
    InitDirStr:= ParamStr(1);
    OutDirStr:=  ParamStr(2);

    InitDir:= InitDirStr;
    OutDir:= OutDirStr;
    InputOpen_Execute(InitDir, OutDir);

  end;
end.
