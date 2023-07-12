program DrvC2000pp;
{$mode objfpc}{$H+}
uses
{$ifdef unix}
  cthreads, // the c memory manager is on some systems much faster for multi-threading
{$endif}
  Forms, Interfaces,
  mMain in 'mMain.pas' {aMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TaMain, aMain);
  Application.Run;
end.
