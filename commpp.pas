unit commPP;

{$mode objfpc}{$H+}

interface

uses
  Classes, synaser, Graphics, SysUtils;

type
  TProcess = function(IsWrite: boolean): boolean of object;

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
    procedure DumpExceptionCallStack(E: Exception);
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

  procedure RaiseErrorInfo;
  var
    s: string;
  begin
    if ser.LastError <> 0 then
    begin
      with Tline(Owner) do
        if CurDev <> nil then
        begin
          CurDev.FNoAnswer := PP_DISCONNECTED;
          CurDev.Connected := False;
        end;
      s := Format('%s ошибка #%d -> %s',
        [PortName, ser.LastError, ser.GetErrorDesc(ser.LastError)]);
      Log(s);
      raise Exception.Create(s);
    end;
  end;

var
  waiting: integer;
  TotalWaiting: word;
  crc: word;
  s: string;
begin
  while (not Terminated) do
    with Tline(Owner) do
    try
      ser := TBlockSerial.Create;
      ser.RaiseExcept := False;
      ser.LinuxLock := False;
      Log(Format('%s открытие...', [PortName]));
      ser.Connect(PortName);
      ser.Config(StrToInt(Baud), StrToInt(Bits), 'N', StrToInt(Stop), False, False);
      if ser.LastError <> 0 then
        RaiseErrorInfo
      else
        Log(Format('%s открыт, handle %d', [PortName, ser.Handle]));

      {process}
      while (not Terminated) do
      begin
        sleep(20);

        if not ProcessProc(True) then
        begin
          s := Format('%s. Ошибка ProcessProc(True), ', [PortName]);
          if CurDev <> nil then
            s := s + Format('CurDev.Op: %d, CurDev.ObjNum: %d',
              [Ord(CurDev.Op), CurDev.CmdObj])
          else
            s := s + 'CurDev is nil';
          Log(s);
          sleep(3000);
          raise Exception.Create(s);
        end;

        {отправка}
        if TLine(Owner).CurDev <> nil then
          with TLine(Owner).CurDev do
            if Option.Debug then
              Log(Format('%s W> %s', [PortName, ArrayToStr(w, wCount)]));
        ser.SendBuffer(@CurDev.w, CurDev.wCount);
        if ser.LastError <> 0 then
          RaiseErrorInfo;

        {прием}
        FillChar(CurDev.r, 255, 0);
        CurDev.rCount := 0;
        TotalWaiting := 0;
        waiting := 0;
        s := 'waiting:';
        repeat
          waiting := ser.WaitingData;
          if (CurDev.rCount > 0) and (waiting = 0) then
            break;
          s := s + Format(' %d', [waiting]);
          ser.RecvBuffer(@CurDev.r[CurDev.rCount], waiting);
          CurDev.rCount := CurDev.rCount + waiting;
          Inc(TotalWaiting);
          sleep(5);
        until ((CurDev.rCount > 0) and (waiting = 0)) or (TotalWaiting >= 100);

        if TLine(Owner).CurDev <> nil then
          with TLine(Owner).CurDev do
            if Option.Debug then
              Log(Format('%s R> %s %s', [PortName, ArrayToStr(r, rCount), s]));

        if ser.LastError <> 0 then
          RaiseErrorInfo;

        if (CurDev.rCount < 5) or (CurDev.w[0] <> CurDev.r[0]) or
          (CurDev.w[1] <> (CurDev.r[1] and $7F)) then
          CurDev.Connected := False
        else
        begin
          crc := CRC16(CurDev.r, CurDev.rCount - 2);
          if (CurDev.r[CurDev.rCount - 2] = hi(crc)) and
            (CurDev.r[CurDev.rCount - 1] = lo(crc)) then
          begin
            CurDev.Connected := True;
            ProcessProc(False);
          end
          else
            CurDev.Connected := False;
        end;
      end;

    except
      on E: Exception do
      begin
        if Option.Debug then
          DumpExceptionCallStack(E);
        Log(Format('%s закрытие...', [PortName]));
        FreeAndNil(ser);
        Log(Format('%s закрыт', [PortName]));
        sleep(60000);
      end;
    end;

  Log(Format('%s завершение потока порта', [PortName]));
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


procedure TPort.DumpExceptionCallStack(E: Exception);
var
  I: integer;
  Frames: PPointer;
  s: string;
  //f: TextFile;
begin
  {
  AssignFile(f, '.\stack.log');
  Rewrite(f);
  DumpExceptionBackTrace(f);
  CloseFile(f);
  }
  s := 'Trace exception:' + LineEnding;
  if E <> nil then
  begin
    s := s + 'Exception class: ' + E.ClassName + 'Message: ' + E.Message + LineEnding;
  end;
  s := s + BackTraceStrFunc(ExceptAddr);
  Log(s);
  Frames := ExceptFrames;
  for I := 0 to ExceptFrameCount - 1 do
    Log(BackTraceStrFunc(Frames[I]));
end;

end.
