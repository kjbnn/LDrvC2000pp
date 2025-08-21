unit mCheckDrv;

interface

uses
  Classes;

type

  { TCheckDrv }

  TCheckDrv = class(TThread)
  private
  protected
    procedure Execute; override;
    procedure TerminateApp;
    procedure HaltApp;
  public
    function AddId: byte;
  end;


const
  LiveTime = 120;

var
  Live: array of byte;
  CheckDrv: TCheckDrv;

implementation

uses
  mLogging, SysUtils, DateUtils, Forms, mMain;

procedure TCheckDrv.Execute;
var
  i, j: byte;
  LiveCheck: string;
begin

  LiveCheck:= '';
  try
    while not Terminated do
    begin
      sleep(1000);
      if length(Live) = 0 then
        continue;

      LiveCheck := 'Check: ';
      for i in Live do
        if i > 0 then
        begin
          for j in Live do LiveCheck := LiveCheck + IntToStr(j) + ' ';
          Log(LiveCheck);
          break;
        end;

      for i := low(Live) to high(Live) do
        if Live[i] < LiveTime then
          Inc(Live[i])
        else
        begin
          LiveCheck := Format(
            'Компонент #%d не отвечает.',
            [i]);
          exit;
        end;
    end;

  finally
    LiveCheck:= LiveCheck + ' Аварийный останов модуля !!!';
    Log(LiveCheck);
    Synchronize(TerminateApp);
    Sleep(10000);
    Synchronize(HaltApp);
  end;
end;

procedure TCheckDrv.TerminateApp;
begin
  if not Application.Terminated then
    Application.Terminate;
end;

procedure TCheckDrv.HaltApp;
begin
  if not Application.Terminated then
    Halt(1);
end;

function TCheckDrv.AddId: byte;
begin
  SetLength(Live, length(Live) + 1);
  Result := length(Live) - 1;
end;


end.
