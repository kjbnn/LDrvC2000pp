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
  mLogging, SysUtils, DateUtils;

procedure TCheckDrv.Execute;
var
  i,j: byte;
  LiveCheck: string;

begin

  while not Terminated do
  begin
    sleep(1000);
    if length(Live)=0 then
      continue;

    {Log}
    LiveCheck:='Check: ';
    for i in Live do
    if i>0 then
    begin
      for j in Live do LiveCheck:= LiveCheck + IntToStr(j) + ' ';
      Log(LiveCheck);
      break;
    end;

    {Pulling or halt}
    for i:= low(Live) to high(Live) do
    if Live[i] < LiveTime then
      inc(Live[i])
    else begin
      Log(Format('Поток #%d завис. Аварийный останов модуля !!!', [i]));
      Synchronize(AppExit);
      break;
    end;

  end;
end;

procedure TCheckDrv.AppExit;
begin
  Halt;
end;

function TCheckDrv.AddId: byte;
begin
  SetLength(Live, length(Live) + 1);
  result:= length(Live) - 1;
end;


end.
