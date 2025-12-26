unit mCheckDrv;

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  Process, Unix,
  {$ENDIF}
  Classes;

type

  { TCheckDrv }

  TCheckDrv = class(TThread)
  private
  protected
    procedure Execute; override;
  public
    function AddId: byte;
  end;

procedure DumpExceptionCallStack;

const
  LiveLimit: array [0..3] of word = (60, 60, 60, 60);

var
  Live: array of word;
  CheckDrv: TCheckDrv;

implementation

uses
  mLogging, SysUtils, DateUtils, Forms, mMain;

procedure TCheckDrv.Execute;
var
  i, j: word;
  LiveCheck: string;
begin
  LiveCheck := '';
  try
    while not Terminated do
    begin
      sleep(1000);
      if length(Live) = 0 then
        continue;

      LiveCheck := 'Check ';
      for i in Live do
        if i > 0 then
        begin
          for j in Live do LiveCheck := LiveCheck + IntToStr(j) + ' ';
          Log(LiveCheck);
          break;
        end;

      for i := low(Live) to high(Live) do
        if Live[i] < LiveLimit[i] then
          Inc(Live[i])
        else
        begin
          Log(Format('Компонент #%d не отвечает.', [i]));
          Raise Exception.Create('');
        end;
    end;
  finally
    Log('Аварийное завершение модуля !!!');
    {$IFDEF WINDOWS}
    TerminateProcess(GetCurrentProcess, 1);
    {$ELSE}
    Kill(GetProcessID, SIGKILL);
    {$ENDIF}
  end;
end;

function TCheckDrv.AddId: byte;
begin
  SetLength(Live, length(Live) + 1);
  Result := length(Live) - 1;
end;

procedure DumpExceptionCallStack;
var
  i: integer;
  Frames: PPointer;
  s: string;
begin
  s := 'Trace:' + LineEnding + BackTraceStrFunc(ExceptAddr);
  Log(s);
  Frames := ExceptFrames;
  for i := 0 to ExceptFrameCount - 1 do
    Log(BackTraceStrFunc(Frames[i]));
end;

end.
