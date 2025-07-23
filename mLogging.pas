unit mLogging;

interface

uses
  Classes, syncobjs;

type

  { TLog }

  TLog = class(TThread)
  private
  protected
    procedure Execute; override;
  public
    procedure OutputLog;
  end;

var
  MyLog: TLog;
  sl_log: TStringList;
  cs_log: TCriticalSection;

procedure WriteLog(str: string);
procedure Log(const str: string);


implementation

uses
  mMain, SysUtils, FileUtil, DateUtils;

procedure TLog.Execute;
begin
  while not Terminated do
  try
    Queue(nil, OutputLog);
    //Synchronize(nil, OutputLog);
    sleep(100);
  except
  end;
end;


procedure WriteLog(str: string);
var
  tf: TextFile;
  FileName, OldFileName, CurDir, s: string;
  AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: word;
  fSize: integer;
begin
  DecodeDateTime(now, AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
  CurDir := ExtractFilePath(ParamStr(0));
  with Option do
  begin
    FileName := FileMask + '.log';
    fSize := FileSize(CurDir + FileName);
    if fSize > MAX_LOG_SIZE then
    begin
      s := '_' + Format('%u%.2u%.2u_%.2u%.2u_%.2u%.3u',
        [AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond]);
      OldFileName := Option.FileMask + s + '.log';
      if not RenameFile(CurDir + FileName, CurDir + OldFileName) then
        str := str + #13#10' Ошибка переименования файла (' +
          CurDir + FileName + '): ' + IntToStr(GetLastOSError);
    end;
  end;

  AssignFile(tf, CurDir + FileName);
  try
    if FileExists(CurDir + FileName) then
      Append(tf)
    else
      rewrite(tf);
    Writeln(tf, str);
    Flush(tf);
  finally
    CloseFile(tf);
  end;

end;


procedure Log(const str: string);
var
  s: string;
  AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: word;
begin
  cs_log.Acquire;
  try
    DecodeDateTime(now, AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
    s := Format('%.2u.%.2u.%.4u %.2u:%.2u:%.2u:%.3u',
      [ADay, AMonth, AYear, AHour, AMinute, ASecond, AMilliSecond]);
    s := s + ' (' + sl_log.Count.ToString + ')';
    sl_log.Add(s + ' ' + str);
  finally
    cs_log.Release;
  end;
end;


procedure TLog.OutputLog;
begin
  cs_log.Acquire;
  if sl_log.Count = 0 then
  begin
    cs_log.Release;
    exit;
  end;

  aMain.Memo1.Lines.BeginUpdate;
  try
    {all to memo1}
    if Option.LogForm then
      with aMain.Memo1.Lines do
      begin
        if Count > 500 then Clear;
        AddStrings(sl_log);
      end;

    while (sl_log.Count > 0) do
    begin
      WriteLog(sl_log.Strings[0]);
      sl_log.Delete(0);
    end;

  finally
    aMain.Memo1.Lines.EndUpdate;
    aMain.Memo1.SelStart := Length(aMain.Memo1.Text);
    aMain.Memo1.SelLength := 0;
    cs_log.Release;
  end;
end;


initialization
  sl_log := TStringList.Create;
  cs_log := TCriticalSection.Create;

finalization
  sl_log.Free;
  cs_log.Free;

end.
