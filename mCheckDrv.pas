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
    procedure AppExit;
  end;

const
  LiveTime = 60;

var
  LiveCount: array[1..2] of word; {FormTimer}
  CheckDrv: TCheckDrv;

implementation

uses
  mMain, SysUtils, DateUtils;

procedure TCheckDrv.Execute;
var
  i: byte;
begin
  while not Terminated do
  begin
    sleep(1000);
    if (LiveCount[1] + LiveCount[2]) > 0 then
      if ExistDebugKey('debug_log') then
        Log(Format('main=%d, comm=%d', [LiveCount[1], LiveCount[2]]));

    for i := 1 to 2 do
    begin
      if LiveCount[i] = LiveTime then
      begin
        Log('Аварийный останов модуля!!!');
        break;
      end
      else if LiveCount[i] > LiveTime then
        Synchronize(AppExit);
    end;

    Inc(LiveCount[1]);
    Inc(LiveCount[2]);
  end;

end;

procedure TCheckDrv.AppExit;
begin
  Halt;
end;


end.
