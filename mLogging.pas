unit mLogging;

interface

uses
  Classes, syncobjs;

var
  sl_log: TStringList;
  cs_log: TCriticalSection;

procedure Log(const str: string);

implementation

uses
  mMain, SysUtils, FileUtil, DateUtils;

procedure Log(const str: string);
var
  FileName, OldFileName, CurDir, s, ftext, mtext: string;
  fSize: integer;
  AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond, fMode: word;
begin
  if (sl_log = nil) or (cs_log = nil) then
    exit;
  cs_log.Enter;

  DecodeDateTime(now, AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
  CurDir := ExtractFilePath(ParamStr(0));
  FileName := CurDir + Option.FileMask + '.log';
  s := Format('%.4u.%.2u.%.2u %.2u:%.2u:%.2u:%.3u',
    [AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond]);
  mtext := s + '  ' + str;
  sl_log.Add(mtext);

  fSize := FileSize(FileName);
  if fSize > MAX_LOG_SIZE then
  begin
    s := Format('%.4u%.2u%.2u_%.2u%.2u%.2u_%.3u',
    [AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond]);
    OldFileName := CurDir + Option.FileMask + '_' + s + '.log';
    if not RenameFile(FileName, OldFileName) then
      mtext := str + Format(
        ' Внимание! Ошибка #%d переименования файла %s',
        [FileName, GetLastOSError]);
  end;

  ftext := mtext + LineEnding;
  try
    if FileExists(FileName) then
      fMode := fmOpenWrite or fmShareDenyWrite
    else
      fMode := fmCreate or fmShareDenyWrite;
    with TFileStream.Create(FileName, fMode) do
    try
      Position := Size;
      WriteBuffer(PChar(ftext)^, Length(ftext) * SizeOf(char));
    finally
      Free;
    end;
  finally
    cs_log.Leave;
  end;
end;


initialization
  sl_log := TStringList.Create;
  cs_log := TCriticalSection.Create;

finalization
  FreeAndNil(sl_log);
  FreeAndNil(cs_log);

end.
