program DrvC2000pp;
{$mode objfpc}{$H+}
uses
  {$ifdef unix}
  cthreads, // the c memory manager is on some systems much faster for multi-threading
  {$endif}
  UniqueInstance,
  UniqueInstanceRaw,
  Forms,
  Interfaces,
  Dialogs,
  mLogging,
  mCheckDrv,
  SysUtils,
  mMain in 'mMain.pas' {aMain},
  cIniKey;

  {$R *.res}

var
  MyProg: TUniqueInstance;

begin
  MyProg := TUniqueInstance.Create(nil);
  MyProg.Identifier := 'DrvC2000pp';
  MyProg.Enabled := True;
  try
    if InstanceRunning then
      raise Exception.Create(
        'Разрешено запускать только одну копию программы!');

    CheckDrv := TCheckDrv.Create(False);
    CheckDrv.FreeOnTerminate:= True;
    CheckDrv.NameThreadForDebugging('CheckDrv', CheckDrv.ThreadID);

    Application.Initialize;
    Application.CreateForm(TaMain, aMain);
    Application.Run;
  finally
    MyProg.Free;
    setkey('LastConDevs', Option.LastConDevs);
  end;
end.



