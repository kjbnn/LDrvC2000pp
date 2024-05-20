program DrvC2000pp;
{$mode objfpc}{$H+}
uses
{$ifdef unix}
  cthreads, // the c memory manager is on some systems much faster for multi-threading
{$endif}
  UniqueInstance, UniqueInstanceRaw,
  Forms, Interfaces, Dialogs,
  mMain in 'mMain.pas' {aMain};

{$R *.res}

var
  MyProg: TUniqueInstance;

begin
  MyProg := TUniqueInstance.Create(nil);
  MyProg.Identifier:= 'DrvC2000pp';
  MyProg.Enabled:= True;
  if InstanceRunning then
  begin
    MyProg.Free;
    Halt(1);
  end;

  Application.Initialize;
  Application.CreateForm(TaMain, aMain);
  Application.Run;
end.
