unit commPP;

interface

uses
  Classes, synaser, Graphics, SysUtils;

const
  MaxTransmitAttempt = 10;

type
  TProcess = procedure(IsWrite: boolean) of object;

  TBuf = array [0..255] of byte;

  { TPort }
  TPort = class(TThread)
  protected
    ser: TBlockSerial;
    procedure Execute; override;
  public
    ProcessProc: TProcess;
    PortName, Baud, Bits, Stop: string;
    Owner: pointer;
    LiveId: byte;
    procedure DumpExceptionCallStack;
  end;

function GetCRC16(Buffer: TBuf; Number: byte): word;
function CRC16(Buffer: TBuf; Number: byte): word;


implementation

uses
  Forms,
  mCheckDrv, mLogging,
  mMain;

function ArrayToStr(Ar: TBuf; Count: byte): string;
var
  i: byte;
begin
  Result := '';
  for i := 1 to Count do
    Result := Result + IntToHex(Ar[i - 1], 2);
end;

procedure TPort.Execute;

  function PortErrorInfo: string;
  begin
    Result := Format('%s ошибка #%d -> %s',
      [PortName, ser.LastError, ser.GetErrorDesc(ser.LastError)]);
  end;

var
  waiting: integer;
  TotalWaiting: word;
  crc: word;
  s: string;
begin
  ser := TBlockSerial.Create;
  ser.RaiseExcept := False;
  ser.LinuxLock := False;
  Log(Format('%s открытие...', [PortName]));

  try
    ser.Connect(PortName);
    ser.Config(StrToInt(Baud), StrToInt(Bits), 'N', StrToInt(Stop), False, False);
    if ser.LastError <> 0 then
      raise Exception.Create(PortErrorInfo);
    Log(Format('%s открыт, handle %d', [PortName, ser.Handle]));
    InitState(Owner);

    while (not Terminated) do
      with Tline(Owner) do
      begin
        sleep(20);
        if length(Live) > LiveId then Live[LiveId] := 0;

        {отправка}
        CurPp := NextPp;
        if CurPp = nil then
          raise Exception.Create(
            Format('%s не содержит конфигурацию С2000-ПП',
            [PortName]));
        ProcessProc(True);

        if (Option.Debug and 2) > 0 then
          with CurPp do
          begin
            Log(Format('%s W> %s', [PortName, ArrayToStr(w, wCount)]));
            ser.SendBuffer(@w, wCount);
          end;
        if ser.LastError <> 0 then
          raise Exception.Create(PortErrorInfo);

        {прием}
        FillChar(CurPp.r, 255, 0);
        CurPp.rCount := 0;
        TotalWaiting := 0;
        waiting := 0;
        s := 'waiting:';
        repeat
          waiting := ser.WaitingData;
          if (CurPp.rCount > 0) and (waiting = 0) then
            break;
          s := s + Format(' %d', [waiting]);
          ser.RecvBuffer(@CurPp.r[CurPp.rCount], waiting);
          if ser.LastError <> 0 then
            Log(PortErrorInfo);
          CurPp.rCount := CurPp.rCount + waiting;
          Inc(TotalWaiting);
          sleep(5);
        until ((CurPp.rCount > 0) and (waiting = 0)) or (TotalWaiting >= 100);

        if (Option.Debug and 2) > 0 then
          with CurPp do
            Log(Format('%s R> %s %s', [PortName, ArrayToStr(r, rCount), s]));

        {обработка приема}
        if (CurPp.rCount < 5) or (CurPp.w[0] <> CurPp.r[0]) or
          (CurPp.w[1] <> (CurPp.r[1] and $7F)) then
          CurPp.Connected := False
        else
        begin
          crc := CRC16(CurPp.r, CurPp.rCount - 2);
          if (CurPp.r[CurPp.rCount - 2] = hi(crc)) and
            (CurPp.r[CurPp.rCount - 1] = lo(crc)) then
          begin
            CurPp.Connected := True;
            ProcessProc(False);
          end
          else
            CurPp.Connected := False;
        end;
      end;

  except
    on E: Exception do
    begin
      Log(E.ToString);
      if (Option.Debug and 1) > 0 then
        DumpExceptionCallStack;
      Log(Format('%s закрытие...', [PortName]));
      FreeAndNil(ser);
    end;
  end;

  Log(Format('%s закрыт', [PortName]));
end;

//**Original Code from Sky devil**
function GetCRC16(Buffer: TBuf; Number: byte): word;
var
  crc: word;
  Mask: word;
  i: integer;
  j: integer;
begin
  crc := $FFFF;
  for i := 1 to Number do
  begin
    crc := crc xor Buffer[i - 1];
    for j := 1 to 8 do
    begin
      Mask := 0;
      if ((crc / 2) <> (crc div 2)) then
        Mask := $A001;
      crc := (crc div 2) and $7FFF;
      crc := crc xor Mask;
    end;
  end;
  Result := ((crc and $FF) shl 8) + (crc shr 8);
end;


function CRC16(Buffer: TBuf; Number: byte): word;
const
  ArrayCRCHi: array [0..255] of byte = (
    $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
    $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
    $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
    $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
    $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
    $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
    $81, $40, $01, $C0, $80, $41, $00, $C1, $81, $40,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
    $01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
    $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
    $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
    $01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
    $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
    $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
    $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
    $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
    $80, $41, $00, $C1, $81, $40);

  ArrayCRCLo: array [0..255] of byte = (
    $00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06,
    $07, $C7, $05, $C5, $C4, $04, $CC, $0C, $0D, $CD,
    $0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09,
    $08, $C8, $D8, $18, $19, $D9, $1B, $DB, $DA, $1A,
    $1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC, $14, $D4,
    $D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3,
    $11, $D1, $D0, $10, $F0, $30, $31, $F1, $33, $F3,
    $F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
    $3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A,
    $3B, $FB, $39, $F9, $F8, $38, $28, $E8, $E9, $29,
    $EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED,
    $EC, $2C, $E4, $24, $25, $E5, $27, $E7, $E6, $26,
    $22, $E2, $E3, $23, $E1, $21, $20, $E0, $A0, $60,
    $61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67,
    $A5, $65, $64, $A4, $6C, $AC, $AD, $6D, $AF, $6F,
    $6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
    $78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E,
    $7F, $BF, $7D, $BD, $BC, $7C, $B4, $74, $75, $B5,
    $77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71,
    $70, $B0, $50, $90, $91, $51, $93, $53, $52, $92,
    $96, $56, $57, $97, $55, $95, $94, $54, $9C, $5C,
    $5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B,
    $99, $59, $58, $98, $88, $48, $49, $89, $4B, $8B,
    $8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
    $44, $84, $85, $45, $87, $47, $46, $86, $82, $42,
    $43, $83, $41, $81, $80, $40);
var
  i, Index: integer;
  CRCHi, CRCLo: byte;
begin
  CRCHi := $FF;
  CRCLo := $FF;
  for i := 1 to Number do
  begin
    Index := CRCHi xor Buffer[i - 1];
    CRCHi := CRCLo xor ArrayCRCHi[Index];
    CRCLo := ArrayCRCLo[Index];
  end;
  Result := (CRCHi shl 8) or CRCLo;
end;


procedure TPort.DumpExceptionCallStack;
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
