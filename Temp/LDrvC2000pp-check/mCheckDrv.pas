unit mCheckDrv;

interface

uses
  Classes;

type
  TCheckDrv = class(TThread)
  private
  protected
    procedure Execute; override;
    procedure WriteExit;
    procedure WriteState;
    procedure Log(str: string);
  end;

const
  LiveTime = 60;

var
  LiveCount: array[1..2] of word; {FormTimer, }
  CheckDrv: TCheckDrv;
  LogCount: int64;

implementation

uses mMain, SysUtils, DateUtils;

procedure TCheckDrv.Execute;
var
  i: byte;
begin
  while True do
  begin
    sleep(1000);
    if (LiveCount[1] + LiveCount[2]) > 0 then
      WriteState;

    for i := 1 to 2 do
    begin
      if LiveCount[i] = LiveTime then
      begin
        WriteExit;
        break;
      end
      else if LiveCount[i] > LiveTime then
        aMain.Close;
    end;

    Inc(LiveCount[1]);
    Inc(LiveCount[2]);
  end;

  aMain.Close;
end;


procedure TCheckDrv.WriteState;
var
  s: string;
begin
  s := Format('main=%d, comm=%d', [LiveCount[1], LiveCount[2]]);
  Log(s);
end;


procedure TCheckDrv.WriteExit;
begin
  Log('Аварийный останов зависшего модуля!!!');
end;


procedure TCheckDrv.Log(str: string);
const
  ext = '.state';
var
  tf: TextFile;
  //SysTime: SYSTEMTIME;
  FName: string;

begin
  //GetLocalTime(SysTime);
  FName := Option.FileMask + ext;
  AssignFile(tf, FName);
  try
    if FileExists(FName) then
      Append(tf)
    else
      rewrite(tf);
    Inc(LogCount);
    Writeln
    (tf,
      DateTimeToStr(now)
      {
      Format('%u-%.2u/%.2u/%.4u-%.2u:%.2u:%.2u ',
        [LogCount, SysTime.wDay, SysTime.wMonth, SysTime.wYear, SysTime.wHour,
        SysTime.wMinute, SysTime.wSecond] )
      } + ' ' + str
      );
    Flush(tf);
  finally
    CloseFile(tf);
  end;





end;



end.
