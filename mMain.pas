unit mMain;

interface

uses
  SysUtils, Variants, Classes,
  Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, Menus, Spin, FileUtil,
  laz2_DOM,
  laz2_XMLRead, FileInfo,
  cKsbmes,
  commPP,
  syncobjs;

const
  MAX_LOG_SIZE = 1e7;

  MB_BASE_ADR_ZONE = 40000;
  MB_BASE_ADR_OUTKEY = 10000;
  MB_BASE_ADR_PART = 44096;

  MB_MAX_RELAYS = 46144; // Максимальное количество реле
  MB_MAX_ZONES = 46145; // Максимальное количество зон
  MB_MAX_PARTS = 46146; // Максимальное количество разделов
  MB_MAX_ZONESTATES = 46147;
  // Максимальное количество состояний зон
  MB_MAX_PARTSTATES = 46148;
  // Максимальное количество состояний раздела
  MB_MAX_EVENTS = 46149; // Максимальное количество событий
  MB_MAX_EVENTLEN = 46150; // Максимальная длина события
  MB_HW_INFO = 46152; // HW инфо

  MB_EVENT_IS_READED = 46163;
  // Установка признака «Событие прочитано»
  MB_DATATIME = 46165; // Время и дата
  MB_SET_ZONE_NUM = 46176;
  // Установка номера зоны для запроса
  MB_SET_PART_NUM = 46177;
  // Установка номера раздела для запроса
  MB_EXT_ZONE_STATE = 46192;
  // Запрос расширенного состояния зоны
  MB_EXT_PART_STATE = 46200;
  // Запрос расширенного состояния раздела
  MB_EVENT = 46264; // Запрос события

  CO_NOLINK = 0;
  CO_NOLINK_FAULT = 2;
  CO_NOLINK_CORESTART = 4;
  CO_NOLINK_STOP = 6;
  CO_NOLINK_UNKNOWN = $FF;

  TYPEDEVICE_ORION = 21;
  TYPEDEVICE_PULT = 22;
  TYPEDEVICE_DEVICE = 23;
  TYPEDEVICE_ZONE = 24;
  TYPEDEVICE_OUTKEY = 25;
  TYPEDEVICE_READER = 26;
  TYPEDEVICE_PART = 27;
  TYPEDEVICE_PARTGROUP = 28;

  BASE_ROSTEK_MSG = 13000;
  ORION_ENABLE_MSG = 13501;
  ORION_DISABLE_MSG = 13502;

  ZONE_DISARM_MSG = 13551;
  ZONE_ARM_MSG = 13553;
  PART_DISARM_MSG = 13563;
  PART_ARM_MSG = 13564;
  RELAY_OFF_MSG = 13567;
  RELAY_ON_MSG = 13568;

  GET_STATES_MSG = 13600;
  STATEORION_MSG = 13601;
  STATEPULT_MSG = 13602;
  STATEDEVICE_MSG = 13603;
  STATEZONE_MSG = 13604;
  STATEOUTKEY_MSG = 13605;
  STATEREADER_MSG = 13606;
  STATEPART_MSG = 13607;
  STATEPARTGROUP_MSG = 13608;

  BASE_MSG = 13000;

  PP_DISCONNECTED = 10;

type

  TDevOp = (
    DOP_NOP,
    DOP_STOP,

    DOP_SET_TIME,
    DOP_MAX_RELAYS,
    DOP_MAX_ZONES,
    DOP_MAX_PARTS,
    DOP_MAX_ZONESTATES,
    DOP_MAX_PARTSTATES,
    DOP_MAX_EVENTS,
    DOP_MAX_EVENTLEN,
    DOP_HW_INFO,
    DOP_STATE,

    DOP_OUTKEYS_STATE,
    DOP_ZONE_ESTATE_NUM,
    DOP_ZONE_ESTATE,
    DOP_PART_ESTATE_NUM,
    DOP_PART_ESTATE,

    DOP_EVENT,
    DOP_EVENT_SET_READED,

    DOP_CMD_ZONE_DISARM,
    DOP_CMD_ZONE_ARM,
    DOP_CMD_ZONE_RESET,
    DOP_CMD_PART_DISARM,
    DOP_CMD_PART_ARM,
    DOP_CMD_RELAY_OFF,
    DOP_CMD_RELAY_ON
    );

  ParamKind = (PARAM_WORD, PARAM_TIME);

  TAct = (ComPortList, DeviceList, ShleifList, RelayList, ReaderList);

  TOption = record
    FileMask: string;
    Debug: byte; {1-exp, 2-port, 4-menu}
    Noport: boolean;
  end;

  TObjectType = (UNKNOWN, LINE, DEVPP, ZONE, OUTKEY, PART, USER);

  TOrionObj = class
  public
    Kind: TObjectType;
    Number, ZnType, Bigdevice, Smalldevice, Pultid: word;
    ParentObj: pointer;
    ChildsObj: TList;
    constructor Create;
    destructor Destroy; override;
    function FindChild(bKind: TObjectType; Num: word): word;
    function FindWithIdChild(bKind: TObjectType; Id: word): word;
  end;

  TPp = class;

  TCmdRec = record
    Op: TDevOp;
    ObjNum: word;
  end;

  { TLine }

  TLine = class(TOrionObj)
  private
    Port: TPort;
    procedure Process(IsWrite: boolean);
    procedure Read; //call from Process
  public
    CurPp: TPp;
    function NextPp: TPp;
    constructor Create;
    destructor Destroy; override;
  end;

  TPp = class(TOrionObj)
    FNoAnswer: byte;
    Op: TDevOp;
    TempIndex: word;
    NextOp: TDevOp;
    CmdOp: TDevOp;
    CmdObj: word;
    CmdTry: byte;
    z_c, r_c, p_c, u_c: word; //кол-во Zone, Part, User
    StateRequest: word;
    rCount, wCount: word;
    Cmds: TThreadList;
    function GetConnect: boolean;
    procedure SetConnect(Value: boolean);
    procedure AddCrc;
    procedure AddCmd(Opn: TDevOp; ObjNum: word);
    procedure GetCmd(var Op: TDevOp; var ObjNum: word);
  public
    w, r: TBuf;
    constructor Create;
    destructor Destroy; override;
    function NextObj(ObjKind: TObjectType): word;
  published
    property Connected: boolean read GetConnect write SetConnect;
  end;


  { TaMain }
  TaMain = class(TForm)
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    StatusBar1: TStatusBar;
    Memo1: TMemo;
    N1: TMenuItem;
    N2: TMenuItem;
    Indicator: TShape;
    FormTimer: TTimer;
    TimerVisible: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormTimerTimer(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure ReadParam;
    procedure FormConstrainedResize(Sender: TObject;
      var MinWidth, MinHeight, MaxWidth, MaxHeight: TConstraintSize);
    procedure N3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure IndicatorMouseMove(Sender: TObject);
    procedure TimerVisibleTimer(Sender: TObject);
  private
    LiveId, LiveDev: byte;
    XML: TXMLDocument;
    procedure ReadConfiguration;
    procedure ReadConfigNode(Node: TDOMNode; pParent: Pointer);
    function ConDevs: word;
    procedure SetIndicator;
  public
  end;


function GetVersion(FileName: string): string;
function FindPpWithPultid(PpId: word; KindObj: TObjectType; ObjId: word): TPp;
procedure Consider(mes: KSBMES; str: string);
procedure Send(mes: KSBMES); overload;
procedure Send(mes: KSBMES; str: pchar); overload;
procedure InitState(pLine: pointer = nil);

var
  aMain: TaMain;
  Option: TOption;
  Lines: TList;
  Pps: TList;
  Event: array [0..511] of string;
  RelayState: array [0..1] of string;
  OrionState: array [0..1] of string;
  cs_istate: TCriticalSection;

implementation

uses
  DateUtils,
  cForFormKsb,
  cIniKey,
  constants,
  cmesdriver_api,
  typinfo,
  mCheckDrv,
  mLogging;

  {$R *.lfm}

var
  ModuleNetDevice, ModuleBigDevice: word;

procedure TaMain.FormCreate(Sender: TObject);
const
  IndicatorSize = 15;
var
  i: word;
begin
  AppKsbInit(self);
  TimerVisible.Enabled := True;
  LiveId := CheckDrv.AddId;
  LiveDev := CheckDrv.AddId;

  try
    with Option do
    begin
      FileMask := GetKey('FileMask', '');
      if FileMask = '' then
        FileMask := ExtractFileName(ParamStr(0));
      if Pos('.exe', FileMask) > 0 then
        SetLength(FileMask, Length(FileMask) - 4);
    end;

    FormTimer.Enabled := True;
    Log('Старт модуля (вер. ' + GetVersion(Application.ExeName) + ')');
    Log('Чтение файла Setting.ini...');
    ReadParam;
    Log('Файл Setting.ini прочитан');

    StatusBar1.Panels.Items[0].Text := ' Старт: ' + DateTimeToStr(Now);
    StatusBar1.Panels.Items[2].Text :=
      Format(' Net=%d Big=%d, ', [ModuleNetDevice, ModuleBigDevice]) +
      GetKey('COMMENT', 'Комментарий...');

    Log('Чтение файла ' + Option.FileMask + '.xml...');
    ReadConfiguration;
    Log('Файл ' + Option.FileMask + '.xml прочитан');

    if not Option.Noport then
    begin
      Log('Инициализация связи с C2000-ПП');
      for i := 1 to Lines.Count do
        (TLine(Lines.Items[i - 1]).Port as TPort).Start;
    end
    else
      MessageDlg('Внимание',
        'Модуль загружен в режиме без связи с C2000-ПП !!!',
        mtWarning, [mbOK], 0, mbOK);

  except
    On E: Exception do
    begin
      Log(Format('Завершение работы с ошибкой: %s',
        [E.Message]));
      Close;
    end;
  end;

  Indicator.Parent := StatusBar1;
  Indicator.BorderSpacing.Left := StatusBar1.Panels[0].Width + 4;
  Indicator.BorderSpacing.Top := ((StatusBar1.Height - IndicatorSize) div 2);
  {$ifdef MSWINDOWS}
  Indicator.BorderSpacing.Left := Indicator.BorderSpacing.Left + 2;
  Indicator.BorderSpacing.Top := Indicator.BorderSpacing.Top - 2;

  {$endif}
  Indicator.Shape := stCircle;
  Indicator.Visible := True;
  Indicator.Width := IndicatorSize;
  Indicator.Height := IndicatorSize;
  Indicator.Pen.Color := clGray;
  Indicator.Brush.Color := clRed;
  Indicator.ShowHint := True;

  if (Option.Debug and 4) > 0 then
  begin
    SpinEdit1.Visible := True;
    SpinEdit2.Visible := True;
    MenuItem2.Visible := True;
  end;

end;

procedure TaMain.ReadParam;
begin
  KsbAppType := GetKey('NUMBER', APPLICATION_C2000PP);
  ModuleNetDevice := getkey('ModuleNetDevice', 1);
  ModuleBigDevice := getkey('ModuleBigDevice', 1);

  with Option do
  begin
    Debug := StrToInt(getkey('Debug', '0'));
    Noport := StrToInt(getkey('Noport', '0')) = 1;
  end;

  Left := StrToInt(getkey('POS_LEFT', '0'));
  Top := StrToInt(getkey('POS_TOP', '0'));
  Width := StrToInt(getkey('POS_WIDTH', '400'));
  Height := StrToInt(getkey('POS_HEIGHT', '450'));
end;

procedure TaMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Log('Останов модуля');
  CloseAction := caFree;
  setkey('POS_LEFT', left);
  setkey('POS_TOP', top);
  setkey('POS_WIDTH', Width);
  setkey('POS_HEIGHT', Height);
  inherited;
end;

procedure TaMain.FormConstrainedResize(Sender: TObject;
  var MinWidth, MinHeight, MaxWidth, MaxHeight: TConstraintSize);
begin
  MinWidth := 300;
  MinHeight := 150;
  MaxWidth := MaxWidth;
  MaxHeight := MaxHeight;
end;

procedure TaMain.ReadConfiguration;
begin
  with Option do
  begin
    ReadXMLFile(Xml, ExtractFilePath(Application.ExeName) + FileMask + '.xml');
    ReadConfigNode(Xml.FindNode('C2000ppConfig'), nil);
  end;
end;

procedure TaMain.ReadConfigNode(Node: TDOMNode; pParent: Pointer);
var
  XmlDocNode: TDOMNode;
  i: word;
  pObj: pointer;
  s: string;
begin
  if Node = nil then
    exit;
  for i := 1 to Node.ChildNodes.Count do
  begin
    pObj := nil;
    XmlDocNode := Node.ChildNodes.Item[i - 1];

    if XmlDocNode.NodeName = 'Line' then
    begin
      s := Format('%s Port=%s Baud=%s Bits=%s Stop=%s',
        [XmlDocNode.NodeName, TDOMElement(XmlDocNode).GetAttribute('Port'),
        TDOMElement(XmlDocNode).GetAttribute('Baud'),
        TDOMElement(XmlDocNode).GetAttribute('Bits'),
        TDOMElement(XmlDocNode).GetAttribute('Stop')]);
      Log(s);

      pObj := TLine.Create;
      with TLine(pObj) do
      begin
        ParentObj := pParent;
        Port := TPort.Create(True);
        //Port.FreeOnTerminate := True;
        Port.LiveId := CheckDrv.AddId;
        with Port as TPort do
        begin
          PortName := TDOMElement(XmlDocNode).GetAttribute('Port');
          NameThreadForDebugging(PortName, Port.ThreadID);
          Baud := TDOMElement(XmlDocNode).GetAttribute('Baud');
          Bits := TDOMElement(XmlDocNode).GetAttribute('Bits');
          Stop := TDOMElement(XmlDocNode).GetAttribute('Stop');
          Owner := pObj;
          ProcessProc := Process;
        end;
        Kind := LINE;
      end;
      Lines.Add(pObj);
    end;

    if XmlDocNode.NodeName = 'Pp' then
    begin
      s := Format('  %s Number=%s Pultid=%s Id=%s',
        [XmlDocNode.NodeName, TDOMElement(XmlDocNode).GetAttribute('Number'),
        TDOMElement(XmlDocNode).GetAttribute('Pultid'),
        TDOMElement(XmlDocNode).GetAttribute('Id')]);
      Log(s);

      pObj := TPp.Create;
      with TPp(pObj) do
      begin
        Kind := DEVPP;
        Number := TDOMElement(XmlDocNode).GetAttribute('Number').ToInteger;
        Pultid := TDOMElement(XmlDocNode).GetAttribute('Pultid').ToInteger;
        Bigdevice := TDOMElement(XmlDocNode).GetAttribute('Id').ToInteger;
        ParentObj := pParent;
        TOrionObj(ParentObj).ChildsObj.Add(pObj);
        Pps.Add(pObj);
      end;
    end;

    if XmlDocNode.NodeName = 'Zone' then
    begin
      s := Format('    %s Number=%s Type=%s Id=%s',
        [XmlDocNode.NodeName, TDOMElement(XmlDocNode).GetAttribute('Number'),
        TDOMElement(XmlDocNode).GetAttribute('Type'),
        TDOMElement(XmlDocNode).GetAttribute('Id')]);
      Log(s);

      pObj := TOrionObj.Create;
      with TOrionObj(pObj) do
      begin
        Kind := ZONE;
        Number := TDOMElement(XmlDocNode).GetAttribute('Number').ToInteger;
        ZnType := TDOMElement(XmlDocNode).GetAttribute('Type').ToInteger;
        Bigdevice := TOrionObj(pParent).Pultid;
        Smalldevice := TDOMElement(XmlDocNode).GetAttribute('Id').ToInteger;
        ParentObj := pParent;
        TOrionObj(ParentObj).ChildsObj.Add(pObj);
        Inc(TPp(ParentObj).z_c);
      end;
    end;

    if XmlDocNode.NodeName = 'Output' then
    begin
      s := Format('    %s Number=%s Id=%s', [XmlDocNode.NodeName,
        TDOMElement(XmlDocNode).GetAttribute('Number'),
        TDOMElement(XmlDocNode).GetAttribute('Id')]);
      Log(s);

      pObj := TOrionObj.Create;
      with TOrionObj(pObj) do
      begin
        Kind := OUTKEY;
        Number := TDOMElement(XmlDocNode).GetAttribute('Number').ToInteger;
        Bigdevice := TOrionObj(pParent).Pultid;
        Smalldevice := TDOMElement(XmlDocNode).GetAttribute('Id').ToInteger;
        ParentObj := pParent;
        TOrionObj(ParentObj).ChildsObj.Add(pObj);
        Inc(TPp(ParentObj).r_c);
      end;
    end;

    if XmlDocNode.NodeName = 'Part' then
    begin
      s := Format('    %s Number=%s Id=%s', [XmlDocNode.NodeName,
        TDOMElement(XmlDocNode).GetAttribute('Number'),
        TDOMElement(XmlDocNode).GetAttribute('Id')]);
      Log(s);

      pObj := TOrionObj.Create;
      with TOrionObj(pObj) do
      begin
        Kind := PART;
        Number := TDOMElement(XmlDocNode).GetAttribute('Number').ToInteger;
        Bigdevice := TOrionObj(pParent).Pultid;
        Smalldevice := TDOMElement(XmlDocNode).GetAttribute('Id').ToInteger;
        ParentObj := pParent;
        TOrionObj(ParentObj).ChildsObj.Add(pObj);
        Inc(TPp(ParentObj).p_c);
      end;
    end;

    if XmlDocNode.NodeName = 'User' then
    begin
      s := Format('    %s Number=%s Id=%s', [XmlDocNode.NodeName,
        TDOMElement(XmlDocNode).GetAttribute('Number'),
        TDOMElement(XmlDocNode).GetAttribute('Id')]);
      Log(s);

      pObj := TOrionObj.Create;
      with TOrionObj(pObj) do
      begin
        Kind := USER;
        Number := TDOMElement(XmlDocNode).GetAttribute('Number').ToInteger;
        Bigdevice := TOrionObj(pParent).Pultid;
        Smalldevice := TDOMElement(XmlDocNode).GetAttribute('Id').ToInteger;
        ParentObj := pParent;
        TOrionObj(ParentObj).ChildsObj.Add(pObj);
        Inc(TPp(ParentObj).u_c);
      end;
    end;

    ReadConfigNode(XmlDocNode, pObj);
  end;
end;


(* ------------------------------------- *)
(*   O R I O N O B J,  L I N E,  D E V   *)
(* ------------------------------------- *)

{ TOrionObj }
constructor TOrionObj.Create;
begin
  ChildsObj := TList.Create;
  kind := UNKNOWN;
end;

destructor TOrionObj.Destroy;
begin
  while ChildsObj.Count > 0 do
  begin
    TOrionObj(ChildsObj.Items[0]).Free;
    ChildsObj.Delete(0);
  end;
  inherited;
end;

function TOrionObj.FindChild(bKind: TObjectType; Num: word): word;
var
  i: word;
  Obj: TOrionObj;
begin
  Result := $FFFF;
  for i := 1 to ChildsObj.Count do
  begin
    Obj := ChildsObj.Items[i - 1];
    if (Obj.Kind = bKind) and (Obj.Number = Num) then
    begin
      Result := i - 1;
      Break;
    end
    else
      continue;
  end;
end;

function TOrionObj.FindWithIdChild(bKind: TObjectType; Id: word): word;
var
  i: word;
  Obj: TOrionObj;
begin
  Result := $FFFF;
  for i := 1 to ChildsObj.Count do
  begin
    Obj := ChildsObj.Items[i - 1];
    if (Obj.Kind = bKind) and (Obj.Smalldevice = Id) then
    begin
      Result := i - 1;
      Break;
    end
    else
      continue;
  end;
end;


{ TPp }
constructor TPp.Create;
begin
  inherited;
  FNoAnswer := PP_DISCONNECTED;
  NextOp := DOP_NOP;
  CmdOp := DOP_NOP;
  z_c := 0;
  r_c := 0;
  p_c := 0;
  u_c := 0;
  StateRequest := 0;
  Cmds := TThreadList.Create;
end;

destructor TPp.Destroy;
begin
  Cmds.Free;
  inherited;
end;

function TPp.GetConnect: boolean;
begin
  Result := False;
  if FNoAnswer < PP_DISCONNECTED then
    Result := True;
end;

procedure TPp.SetConnect(Value: boolean);
var
  mes: KSBMES;
  s: string;
begin
  if Value then
  begin
    if (FNoAnswer >= PP_DISCONNECTED) then
    begin
      Init(mes);
      mes.SysDevice := SYSTEM_OPS;
      mes.TypeDevice := TYPEDEVICE_ORION;
      mes.NetDevice := ModuleNetDevice;
      mes.BigDevice := Bigdevice;
      mes.Code := ORION_ENABLE_MSG;
      Send(mes);
      s := Format('%s PP#%d %s', [(TLine(ParentObj).Port as TPort).PortName,
        Number, OrionState[1]]);
      Log(s);
    end;
    FNoAnswer := 0;
  end

  else if (FNoAnswer < PP_DISCONNECTED) then
  begin
    Inc(FNoAnswer);

    if (FNoAnswer = PP_DISCONNECTED) then
    begin
      Init(mes);
      mes.SysDevice := SYSTEM_OPS;
      mes.TypeDevice := TYPEDEVICE_ORION;
      mes.NetDevice := ModuleNetDevice;
      mes.BigDevice := Bigdevice;
      mes.Code := ORION_DISABLE_MSG;
      Send(mes);
      s := Format('%s PP#%d %s', [(TLine(ParentObj).Port as TPort).PortName,
        Number, OrionState[0]]);
      Log(s);
    end;

  end;

end;

function TPp.NextObj(ObjKind: TObjectType): word;
var
  i: word; //???
  childs: word;
begin
  Result := $FFFF;

  if ObjKind = ZONE then
    if z_c = 0 then
      exit;
  if ObjKind = PART then
    if p_c = 0 then
      exit;
  if ObjKind = OUTKEY then
    if r_c = 0 then
      exit;

  childs := ChildsObj.Count;
  for i := (TempIndex + 1) mod $10000 to {ChildsObj.Count} childs - 1 do
    if (TOrionObj(ChildsObj.Items[i]).Kind = ObjKind) then
    begin
      Result := i;
      break;
    end;
end;

procedure TPp.AddCrc;
var
  crc: word;
begin
  crc := CRC16(w, wCount);
  w[wCount] := hi(crc);
  w[wCount + 1] := lo(crc);
  Inc(wCount, 2);
end;

procedure TPp.AddCmd(Opn: TDevOp; ObjNum: word);
var
  internalList: TList;
  pCmdRec: ^TCmdRec;
begin
  new(pCmdRec);
  pCmdRec^.Op := Opn;
  pCmdRec^.ObjNum := ObjNum;
  internalList := Cmds.LockList;
  internalList.Add(pCmdRec);
  Cmds.UnlockList;
end;

procedure TPp.GetCmd(var Op: TDevOp; var ObjNum: word);
var
  internalList: TList;
  pCmdRec: ^TCmdRec;
begin
  internalList := Cmds.LockList;
  if internalList.Count > 0 then
  begin
    PCmdRec := internalList.First;
    Op := PCmdRec^.Op;
    ObjNum := pCmdRec^.ObjNum;
    internalList.Remove(PCmdRec);
    Dispose(pCmdRec);
  end;
  Cmds.UnlockList;
end;

{ TLine }
constructor TLine.Create;
begin
  inherited Create;
end;

destructor TLine.Destroy;
begin
  inherited;
end;


procedure TLine.Process(IsWrite: boolean);
var
  cObj: TOrionObj;
  s: string;
  ch: char;
  Address: word;
  Sended: boolean;
begin
  if CurPp <> nil then
    s := Format('%s PP#%d ', [TPort(Port).PortName, CurPp.Number])
  else
    s := Format('%s PP(unknown) ', [TPort(Port).PortName]);

  ch := 'W';
  if not IsWrite then
    ch := 'R';

  if (Option.Debug and 2) > 0 then
    if CurPp <> nil then
      log(Format('%s%s %s (%d)', [s, ch, GetEnumName(TypeInfo(TDevOp), Ord(CurPp.Op)),
        Ord(CurPp.Op)]));


  { Write }
  if IsWrite then
  begin
    with CurPp do
    begin

      if Op = DOP_OUTKEYS_STATE then
        if TempIndex = $FFFF then
        begin
          TempIndex := NextObj(OUTKEY);
          if TempIndex = $FFFF then
            Op := DOP_ZONE_ESTATE_NUM;
        end;

      if Op = DOP_ZONE_ESTATE_NUM then
        if TempIndex = $FFFF then
        begin
          TempIndex := NextObj(ZONE);
          if TempIndex = $FFFF then
            Op := DOP_PART_ESTATE_NUM;
        end;

      if Op = DOP_PART_ESTATE_NUM then
        if TempIndex = $FFFF then
        begin
          TempIndex := NextObj(PART);
          if TempIndex = $FFFF then
            Op := DOP_EVENT;
        end;

    end;
  end

  { Read }
  else
    with CurPp do
    begin

      if (CurPp.Number <> r[0]) then
        Log(s + Format(
          'Ошибка приема PP#%d в запросе, PP#%d в ответе',
          [CurPp.Number, r[0]]));

      if (r[1] = (w[1] + $80)) then
      begin
        case r[2] of
          1: s := s +
              'Принятый код функции не может быть обработан на ведомом';
          2:
          begin
            s := s +
              'Адрес данных в запросе не доступен данному ведомому'
              + Format(
              ', ошибка в файле %s.xml для С2000-ПП #%d [%d]',
              [Option.FileMask, CurPp.Bigdevice, CurPp.Number]);
            //Close;
          end;
          3:
          begin
            s := s +
              'Величина в поле данных запроса является недопустимой для ведомого'
              + Format(
              ', ошибка в файле %s.xml для С2000-ПП #%d [%d]',
              [Option.FileMask, Bigdevice, Number]);
            case 256 * w[2] + w[3] of
              MB_SET_ZONE_NUM,
              MB_EXT_ZONE_STATE: s :=
                  s + Format('. Неизвестная для ПП зона #%d',
                  [256 * w[4] + w[5]]);
              MB_SET_PART_NUM,
              MB_EXT_PART_STATE: s :=
                  s + Format(
                  '. Неизвестный для ПП раздел #%d',
                  [256 * w[4] + w[5]]);
              MB_EVENT: s :=
                  s + Format('. Чтение события #%d',
                  [256 * w[4] + w[5]]);
              MB_EVENT_IS_READED: s :=
                  s + Format(
                  '. Неизвестное для ПП прочитанное событие #%d',
                  [256 * w[4] + w[5]]);
            end;
          end;
          6:
            s := s +
              'Ведомый занят обработкой команды. Повторите запрос позже или сбросьте ведомый по питанию';
          15: s := s +
              'Запрошенные данные пока не получены. Повторите запрос позже';
          else
            s := s + 'Причина неизвестна';
        end;

        Log(s + Format('(Ошибка #%d)', [r[2]]));

        case Op of
          DOP_CMD_ZONE_DISARM,
          DOP_CMD_ZONE_ARM,
          DOP_CMD_ZONE_RESET,
          DOP_CMD_PART_DISARM,
          DOP_CMD_PART_ARM,
          DOP_CMD_RELAY_OFF,
          DOP_CMD_RELAY_ON:
            if CmdTry > 0 then
            begin
              Dec(CmdTry);
              Sleep(500);
            end;
        end;

      end;
    end;


  { Write or Read }
  with CurPp do
    case Op of

      DOP_SET_TIME:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $10;
          w[2] := hi(MB_DATATIME);
          w[3] := lo(MB_DATATIME);
          w[4] := hi(3);
          w[5] := lo(3);
          w[6] := 6;
          w[7] := HourOf(now);
          w[8] := MinuteOf(now);
          w[9] := SecondOf(now);
          w[10] := DayOf(now);
          w[11] := MonthOf(now);
          w[12] := YearOf(now) mod 100;
          wCount := 13;
          AddCrc;
        end
        else
        begin
          TempIndex := $FFFF;
          Op := DOP_ZONE_ESTATE_NUM;
          Log(s + Format(
            'Установлено время: %.2d:%.2d:%.2d %.2d.%.2d.20%d',
            [w[7], w[8], w[9], w[10], w[11], w[12]]));
        end;

      DOP_MAX_RELAYS:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_RELAYS);
          w[3] := lo(MB_MAX_RELAYS);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_MAX_ZONES;
          Log(s + Format(
            'Максимальное количество реле: %d',
            [256 * r[3] + r[4]]));
        end;

      DOP_MAX_ZONES:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_ZONES);
          w[3] := lo(MB_MAX_ZONES);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_MAX_PARTS;
          Log(s + Format('Максимальное количество зон: %d',
            [256 * r[3] + r[4]]));
        end;

      DOP_MAX_PARTS:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_PARTS);
          w[3] := lo(MB_MAX_PARTS);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_MAX_ZONESTATES;
          Log(s + Format(
            'Максимальное количество разделов: %d',
            [256 * r[3] + r[4]]));
        end;

      DOP_MAX_ZONESTATES:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_ZONESTATES);
          w[3] := lo(MB_MAX_ZONESTATES);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_MAX_PARTSTATES;
          Log(s + Format(
            'Максимальное количество состояний зоны: %d',
            [
            256 * r[3] + r[4]]));
        end;

      DOP_MAX_PARTSTATES:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_PARTSTATES);
          w[3] := lo(MB_MAX_PARTSTATES);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_MAX_EVENTS;
          Log(s + Format(
            'Максимальное количество состояний раздела: %d',
            [256 * r[3] + r[4]]));
        end;

      DOP_MAX_EVENTS:
        if IsWrite then
        begin
          Op := DOP_MAX_EVENTLEN;
          Log(s + Format(
            'Максимальное количество событий: %d',
            [256 * r[3] + r[4]]));
        end
        else
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_EVENTS);
          w[3] := lo(MB_MAX_EVENTS);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end;

      DOP_MAX_EVENTLEN:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_MAX_EVENTLEN);
          w[3] := lo(MB_MAX_EVENTLEN);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_HW_INFO;
          Log(s + Format('Максимальная длина события: %d',
            [256 * r[3] + r[4]]));
        end;

      DOP_HW_INFO:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_HW_INFO);
          w[3] := lo(MB_HW_INFO);
          w[4] := hi(2);
          w[5] := lo(2);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_OUTKEYS_STATE;
          Log(s + Format('HW: %d %d', [256 * r[3] + r[4], 256 *
            r[5] + r[6]]));
        end;

      DOP_STATE:
        if IsWrite then
        begin
          cObj := ChildsObj.Items[TempIndex];
          if cObj.Kind = ZONE then
            Address := MB_BASE_ADR_ZONE + cObj.Number
          else if cObj.Kind = OUTKEY then
            Address := MB_BASE_ADR_OUTKEY + cObj.Number
          else if cObj.Kind = PART then
            Address := MB_BASE_ADR_PART + cObj.Number
          else
          begin
            Address := 0;
            raise Exception.Create(
              'DOP_STATE: ошибка вычисления Address!');
          end;
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(Address);
          w[3] := lo(Address);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Read;
          Inc(TempIndex);
          if TempIndex >= CurPp.ChildsObj.Count then
            Op := DOP_EVENT;
        end;

      {usable}
      DOP_OUTKEYS_STATE:
        if IsWrite then
        begin
          cObj := ChildsObj.Items[TempIndex];
          Address := MB_BASE_ADR_OUTKEY + cObj.Number - 1;
          w[0] := Number;
          w[1] := $01;
          w[2] := hi(Address);
          w[3] := lo(Address);
          w[4] := hi(1);
          w[5] := lo(1);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Read;
          TempIndex := NextObj(OUTKEY);
          if TempIndex = $FFFF then
            Op := DOP_ZONE_ESTATE_NUM;
        end;

      DOP_ZONE_ESTATE_NUM:
        if IsWrite then
        begin
          cObj := ChildsObj.Items[TempIndex];
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(MB_SET_ZONE_NUM);
          w[3] := lo(MB_SET_ZONE_NUM);
          w[4] := hi(cObj.Number);
          w[5] := lo(cObj.Number);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_ZONE_ESTATE;
        end;

      DOP_ZONE_ESTATE:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_EXT_ZONE_STATE);
          w[3] := lo(MB_EXT_ZONE_STATE);
          w[4] := hi(5);
          w[5] := lo(5);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Read;
          TempIndex := NextObj(ZONE);
          if TempIndex <> $FFFF then
            Op := DOP_ZONE_ESTATE_NUM
          else
            Op := DOP_PART_ESTATE_NUM;
        end;

      DOP_PART_ESTATE_NUM:
        if IsWrite then
        begin
          cObj := ChildsObj.Items[TempIndex];
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(MB_SET_PART_NUM);
          w[3] := lo(MB_SET_PART_NUM);
          w[4] := hi(cObj.Number);
          w[5] := lo(cObj.Number);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Op := DOP_PART_ESTATE;
        end;

      DOP_PART_ESTATE:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_EXT_PART_STATE);
          w[3] := lo(MB_EXT_PART_STATE);
          w[4] := hi(8);
          w[5] := lo(8);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Read;
          TempIndex := NextObj(PART);
          if TempIndex <> $FFFF then
            Op := DOP_PART_ESTATE_NUM
          else
            Op := DOP_EVENT;
        end;

      DOP_EVENT:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $03;
          w[2] := hi(MB_EVENT);
          w[3] := lo(MB_EVENT);
          w[4] := hi(14);
          w[5] := lo(14);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Read;
          if (r[3] <> 0) or (r[4] <> 0) or (r[5] <> 0) then
            Op := DOP_EVENT_SET_READED
          else
          begin
            if StateRequest > 0 then
              Dec(StateRequest);
            if StateRequest = 1 then
            begin
              TempIndex := $FFFF;
              Op := DOP_OUTKEYS_STATE;
            end
            else
            if (NextOp <> DOP_NOP) then
            begin
              TempIndex := $FFFF;
              Op := NextOp;
              NextOp := DOP_NOP;
            end
            else
            begin
              GetCmd(CmdOp, CmdObj);
              if CmdOp <> DOP_NOP then
              begin
                TempIndex := $FFFF;
                Op := CmdOp;
                CmdOp := DOP_NOP;
                CmdTry := 5;
              end;
            end;
          end;
        end;

      DOP_EVENT_SET_READED:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(MB_EVENT_IS_READED);
          w[3] := lo(MB_EVENT_IS_READED);
          w[4] := r[3];
          w[5] := r[4];
          wCount := 6;
          AddCrc;
        end
        else
        begin
            {
            if (w[4] = r[4]) and (w[5] = r[5]) then
              Log( 'Подтверждение. Прочитано >> #' + IntToStr(256 * r[4] + r[5]) );
            }
          Op := DOP_EVENT;
        end;

      DOP_CMD_ZONE_DISARM:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(word(MB_BASE_ADR_ZONE + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_ZONE + CmdObj - 1));
          w[4] := hi(109);
          w[5] := lo(109);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Снять шлейф #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

      DOP_CMD_ZONE_ARM:
        if IsWrite then
        begin
          w[0] := Number;
            {
            Когда в очредном NextDev придет очередь данного PP,
            в разделах DOP_CMD_ZONE_ARM...
            вычитается нужная именно для этого PP команда.
            Ведь даже GetCmd вычитывает команду при чтении события
            от Конкретного PP. В GetCmd н. убрать параметр номер PP,
            ведь он и так известен.
            }
          w[1] := $06;
          w[2] := hi(word(MB_BASE_ADR_ZONE + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_ZONE + CmdObj - 1));
          w[4] := hi(24);
          w[5] := lo(24);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Взять шлейф #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

      DOP_CMD_PART_DISARM:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(word(MB_BASE_ADR_PART + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_PART + CmdObj - 1));
          w[4] := hi(109);
          w[5] := lo(109);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Снять раздел #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

      DOP_CMD_PART_ARM:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $06;
          w[2] := hi(word(MB_BASE_ADR_PART + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_PART + CmdObj - 1));
          w[4] := hi(24);
          w[5] := lo(24);
          wCount := 6;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Взять раздел #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

      DOP_CMD_RELAY_OFF:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $0F;
          w[2] := hi(word(MB_BASE_ADR_OUTKEY + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_OUTKEY + CmdObj - 1));
          w[4] := hi(1);
          w[5] := lo(1);
          w[6] := 1;
          w[7] := 0;
          wCount := 8;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Выключить реле #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

      DOP_CMD_RELAY_ON:
        if IsWrite then
        begin
          w[0] := Number;
          w[1] := $0F;
          w[2] := hi(word(MB_BASE_ADR_OUTKEY + CmdObj - 1));
          w[3] := lo(word(MB_BASE_ADR_OUTKEY + CmdObj - 1));
          w[4] := hi(1);
          w[5] := lo(1);
          w[6] := 1;
          w[7] := 1;
          wCount := 8;
          AddCrc;
        end
        else
        begin
          Sended := False;
          if (w[0] = r[0]) and (w[1] = r[1]) and (w[2] = r[2]) and
            (w[3] = r[3]) and (w[4] = r[4]) and (w[5] = r[5]) then
          begin
            Log(s + Format(
              'Отправлен запрос. PP#%d Включить реле #%d',
              [Number, CmdObj]));
            Sended := True;
          end;
          if (Sended) or (CmdTry = 0) then
          begin
            CmdObj := 0;
            CmdOp := DOP_NOP;
            Op := DOP_EVENT;
          end;
        end;

    end; //case Op
end;

procedure TLine.Read;
var
  s: string;
  mes: KSBMES;
  i: word;
  Childindex: word;
  Child: TOrionObj;
  SynNorma, SynConnect: boolean;
begin
  with CurPp, aMain do
  begin
    s := Format('%s PP#%d ', [(Port as TPort).PortName, Number]);

    case Op of

      DOP_OUTKEYS_STATE:
      begin
        Child := ChildsObj.Items[TempIndex];
        s := s + Format('Реле #%d Состояние >> %s (%d)',
          [Child.Number, RelayState[r[3]], r[3]]);

        Init(mes);
        mes.NetDevice := ModuleNetDevice;
        mes.BigDevice := Child.Bigdevice;
        mes.SmallDevice := Child.Smalldevice;
        if r[3] = 0 then
          mes.Level := 402
        else
          mes.Level := 401;
        mes.TypeDevice := TYPEDEVICE_OUTKEY;
        mes.Code := STATEOUTKEY_MSG;
        Send(mes);
        Log(s);
      end;

      DOP_ZONE_ESTATE:
      begin
        Childindex := FindChild(ZONE, 256 * r[3] + r[4]);
        if Childindex <> $FFFF then
          Child := ChildsObj.Items[Childindex]
        else
        begin
          Log(s + Format('Зона %d не найдена в файле %s.xml !!!',
            [256 * r[3] + r[4], Option.FileMask]));
          exit; {???}
        end;

        s := s + Format('Зона #%d Состояние >>', [256 * r[3] + r[4]]);

        {защита: в пакете после неготов, потеря связи приходит взято, норма и т п.}
        SynNorma := True;
        SynConnect := True;
        for i := 1 to r[5] do
        begin
          s := s + Format(' %s (%d)', [Event[r[5 + i]], r[5 + i]]);
          if Child <> nil then
          begin
            Init(mes);
            mes.NetDevice := ModuleNetDevice;
            mes.BigDevice := Child.Bigdevice;
            mes.SmallDevice := Child.Smalldevice;
            mes.Level := r[5 + i];
            mes.TypeDevice := TYPEDEVICE_ZONE;
            mes.Code := STATEZONE_MSG;

            if (Child.ZnType = 3) then
              if (Child.Smalldevice = 0) then
              begin
                mes.TypeDevice := TYPEDEVICE_PULT;
                mes.Code := STATEPULT_MSG;
              end
              else
              begin
                mes.TypeDevice := TYPEDEVICE_DEVICE;
                mes.Code := STATEDEVICE_MSG;
              end;

            Send(mes);

            case mes.Code of
              STATEZONE_MSG:
              begin
                case mes.Level of
                  2, 41, 45, 82, 90, 165, 189,
                  190, 192, 194, 196, 198,
                  202, 205, 211, 212, 214,
                  215, 222, 224, 225:
                    SynNorma := False;
                end;
                case mes.Level of
                  187, 250:
                    SynConnect := False;
                end;
              end;
              STATEDEVICE_MSG,
              STATEPULT_MSG:
                case mes.Level of
                  2, 189, 190, 198,
                  202, 215, 222, 250:
                    SynNorma := False;
                end;
              {
              STATEOUTKEY_MSG:
                case mes.Level of
                  121, 122, 126, 189,
                  190, 215, 222, 250:
                    SyntNorma:= False;
                end;
              STATEPARTGROUP_MSG:;
              }
            end; //case
          end;
        end;
        Log(s);

        if SynNorma then
        begin
          mes.Level := $FFFF;
          send(mes);
        end;
        if not SynConnect then
        begin
          mes.Level := 250;
          send(mes);
        end;

      end;


      DOP_PART_ESTATE:
      begin

        Childindex := FindChild(PART, 256 * r[3] + r[4]);
        if Childindex <> $FFFF then
          Child := ChildsObj.Items[Childindex]
        else
        begin
          Log(Format(
            'Раздел #%d не найден в файле %s.xml !!!',
            [256 * r[3] + r[4], Option.FileMask]));
          exit;
        end;

        s := s + Format('Раздел #%d Состояние >>',
          [256 * r[3] + r[4]]);

        for i := 1 to r[5] do
        begin
          if r[5 + i] = 0 then
            continue;
          s := s + Format(' %s (%d)', [Event[r[5 + i]], r[5 + i]]);
          if Child <> nil then
          begin
            Init(mes);
            mes.NetDevice := ModuleNetDevice;
            mes.BigDevice := Child.Bigdevice;
            mes.SmallDevice := Child.Smalldevice;
            mes.Level := r[5 + i];
            mes.TypeDevice := TYPEDEVICE_PART;
            mes.Code := STATEPART_MSG;
            Send(mes);
          end;
        end;
        Log(s);
      end;


      DOP_EVENT:
      begin
        if (r[3] = 0) and (r[4] = 0) and (r[5] = 0) and (r[6] = 0) then
          exit;

        s := s + Format('СОБЫТИЕ #%d.%d >> %s ',
          [256 * r[3] + r[4], r[6], Event[r[6]]]);

        Init(mes);
        mes.SysDevice := 0;
        mes.NetDevice := ModuleNetDevice;
        mes.Code := BASE_ROSTEK_MSG + r[6];

        i := 7;
        while i <= (7 + r[5] - 1) do
        begin
          case r[i] of

            1:
            begin
              Childindex := FindChild(USER, 256 * r[i + 2] + r[i + 3]);
              if Childindex <> $FFFF then
              begin
                Child := ChildsObj.Items[Childindex];
                mes.User := Child.Smalldevice;
                s := s + Format(' Пользователь #%d',
                  [256 * r[i + 2] + r[i + 3]]);
              end
              else
              begin
                Log(s + Format(
                  'Пользователь #%d не найден в файле %s.xml !!!',
                  [256 * r[i + 2] + r[i + 3], Option.FileMask]));
              end;
              Inc(i, 4);
            end;

            2:
            begin
              Childindex := FindChild(PART, 256 * r[i + 2] + r[i + 3]);
              if Childindex <> $FFFF then
              begin
                Child := ChildsObj.Items[Childindex];
                if (mes.TypeDevice = 0) then
                begin
                  mes.TypeDevice := TYPEDEVICE_PART;
                  mes.BigDevice := Child.Bigdevice;
                  mes.SmallDevice := Child.Smalldevice;
                end
                else
                  mes.Partion := Child.Smalldevice;
                s := s + Format(' Раздел #%d ', [256 * r[i + 2] + r[i + 3]]);
              end
              else
              begin
                Log(s + Format(
                  'Раздел #%d не найден в файле %s.xml !!!',
                  [256 * r[i + 2] + r[i + 3], Option.FileMask]));
              end;

              {
              if mes.TypeDevice = TYPEDEVICE_PULT then
              begin
                mes.TypeDevice:= TYPEDEVICE_PART;
                mes.SmallDevice:= 256 * r[i+2] + r[i+3];
              end
              else
                mes.Partion:= 256 * r[i+2] + r[i+3];
              }

              Inc(i, 4);
            end;

            3:
            begin
              Childindex := FindChild(ZONE, 256 * r[i + 2] + r[i + 3]);
              if Childindex <> $FFFF then
              begin
                Child := ChildsObj.Items[Childindex];
                mes.BigDevice := Child.Bigdevice;
                mes.SmallDevice := Child.Smalldevice;
                s := s + Format(' Зона #%d', [256 * r[i + 2] + r[i + 3]]);
                if (mes.SmallDevice = 0) and (Child.ZnType in [3, 8]) then
                  mes.TypeDevice := TYPEDEVICE_PULT
                else if (mes.SmallDevice <> 0) and (Child.ZnType in [3, 8]) then
                  mes.TypeDevice := TYPEDEVICE_DEVICE
                else
                  mes.TypeDevice := TYPEDEVICE_ZONE;
              end
              else
              begin
                Log(s + Format(
                  'Зона #%d не найдена в файле %s.xml !!!',
                  [256 * r[i + 2] + r[i + 3], Option.FileMask]));
              end;
              Inc(i, 4);
            end;

            5:
            begin
              Childindex := FindChild(OUTKEY, 256 * r[i + 2] + r[i + 3]);
              if Childindex <> $FFFF then
              begin
                Child := ChildsObj.Items[Childindex];
                mes.BigDevice := Child.Bigdevice;
                mes.SmallDevice := Child.Smalldevice;
                s := s + Format(' Реле #%d', [256 * r[i + 2] + r[i + 3]]);
                mes.TypeDevice := TYPEDEVICE_OUTKEY;
              end
              else
              begin
                Log(s + Format(
                  'Реле #%d не найдено в файле %s.xml !!!',
                  [256 * r[i + 2] + r[i + 3], Option.FileMask]));
              end;
              Inc(i, 4);
            end;

            7:
            begin
              Childindex := FindChild(OUTKEY, 256 * r[i + 2] + r[i + 3]);
              if Childindex <> $FFFF then
              begin
                Child := ChildsObj.Items[Childindex];
                mes.BigDevice := Child.Bigdevice;
                mes.SmallDevice := Child.Smalldevice;
                s := s + Format(' Реле состояние #%d',
                  [256 * r[i + 2] + r[i + 3]]);
                mes.TypeDevice := TYPEDEVICE_OUTKEY;
              end
              else
              begin
                Log(s + Format(
                  'Реле %d не найдено в файле %s.xml !!!',
                  [Number, 256 * r[i + 2] + r[i + 3], Option.FileMask]));

              end;
              Inc(i, 4);
            end;

            11:
            begin

              try  //???
                if (r[i + 5] = 0) or (r[i + 6] = 0) then
                  mes.SendTime := 0
                else
                  mes.SendTime :=
                    EncodeDateTime(2000 + (r[i + 7] mod 100),
                    r[i + 6] mod 13, r[i + 5] mod 32, r[i + 2] mod
                    24, r[i + 3] mod 60, r[i + 4] mod 60, 0);
                s := s + Format(' Время: %s', [DateTimeToStr(mes.SendTime)]);
              except
              end;

              Inc(i, 8);
            end;

            24:
            begin
              mes.Num := 256 * r[i + 2] + r[i + 3];
              s := s + Format(' ID раздела: %d', [mes.Num]);
              Inc(i, 4);
            end;

            else
              Inc(i, 4);

          end;//case
        end;//while


        if mes.TypeDevice <> $FFFF then
        begin
          Send(mes);
          Log(s);
        end
        else
          Log(s + 'В ответе не определен объект !!!');

        if r[6] in [250, 251] then
          StateRequest := 500;

      end; //DOP_EVENT

    end;// Op

  end;// with

end;

function TLine.NextPp: TPp;
var
  Index: word;
  Value: integer;
begin
  Result := nil;
  Value := ChildsObj.Count;
  case Value of // Ситуации:
    0: ; // Нет
    1:   // Один
      CurPp := ChildsObj.Items[0];
    else
      if CurPp = nil then // Не было
        CurPp := ChildsObj.First
      else if CurPp = ChildsObj.Last then // Последний
        CurPp := ChildsObj.First
      else
      begin
        Index := ChildsObj.IndexOf(CurPp);
        CurPp := ChildsObj.Items[Index + 1];
      end;
  end;

  Result := CurPp;
end;

procedure InitState(pLine: pointer = nil);
var
  i1, i2: word;
  line: TLine;
  pp: TPp;
begin
  if (cs_istate = nil) then
    exit;
  cs_istate.Enter;

  try
    for i1 := 1 to Lines.Count do
    begin
      line := Lines.Items[i1 - 1];
      if (pLine <> nil) and (pLine <> line) then  continue;
      Log('Старт чтения состояний элементов ' +
        line.Port.PortName);
      for i2 := 1 to line.ChildsObj.Count do
      begin
        pp := line.ChildsObj.Items[i2 - 1];
        pp.Op := DOP_HW_INFO;
        {$IFDEF EXTENDINFO}
      pp.Op := DOP_MAX_RELAYS;
        {$ENDIF}
        {$IFDEF MASTER}
      pp.Op := DOP_SET_TIME;
        {$ENDIF}
        pp.TempIndex := $FFFF;
      end;
    end;
  finally
    cs_istate.Leave;
  end;
end;

(* --------------- *)
(*      KSBMES     *)
(* --------------- *)
procedure Send(mes: KSBMES; str: pchar);
const
  max_str_len = 100;
var
  s: string;
begin
  mes.Proga := KsbAppType;
  mes.NumDevice := mes.SmallDevice;
  WriteNet(mes, str);

  s := Format('SEND: %s Code=%d Sys=%d Type=%d Net=%d Big=%d Small=%d ' +
    'Mode=%d Part=%d Lev=%d Us=%d Num=%d Card=%d Mon=%d Cam=%d Prog=%d NumDev=%d',
    [DateTimeToStr(mes.SendTime), mes.Code, mes.SysDevice, mes.TypeDevice,
    mes.NetDevice, mes.BigDevice, mes.SmallDevice, mes.Mode, mes.Partion,
    mes.Level, mes.User, mes.Num, mes.NumCard, mes.Monitor, mes.Camera,
    mes.Proga, mes.NumDevice]);
  if (mes.Size > max_str_len) then
    s := s + 'Внимание!!! Длина строки более 1000'
  else if (mes.Size > 0) then
    s := s + Format(' str(%d)=%s', [mes.Size, Bin2Simbol(str, mes.Size)]);
  Log(s);
end;

procedure Send(mes: KSBMES);
begin
  Send(mes, '');
end;

procedure Consider(mes: KSBMES; str: string);
var
  s: string;
  i: word;
  arr: array of byte;
  pp: TPp;
  Param: word;
begin
  if (mes.Proga <> KsbAppType) and (mes.NetDevice = ModuleNetDevice) then
    case mes.Code of
      //CHECK_LIVE_PROGRAM,
      KILL_PROGRAM,
      EXIT_PROGRAM,
      BASE_ROSTEK_MSG..(BASE_ROSTEK_MSG + 999): ;
      else
        exit;
    end
  else
    exit;

  arr := nil;
  if mes.Size > 0 then
  begin
    SetLength(arr, int64(mes.Size));
    Simbol2Bin(str, @arr[0], mes.Size);
  end;

  s := Format('READ: Code=%d Sys=%d Type=%d Net=%d Big=%d Small=%d ' +
    'Mode=%d Part=%d Lev=%d Us=%d Card=%d Mon=%d Cam=%d Prog=%d NumDev=%d',
    [mes.Code, mes.SysDevice, mes.TypeDevice, mes.NetDevice, mes.BigDevice,
    mes.SmallDevice, mes.Mode, mes.Partion, mes.Level, mes.User,
    mes.NumCard, mes.Monitor, mes.Camera, mes.Proga, mes.NumDevice]);
  if mes.Size > 0 then
    s := s + Format(' str(%d)=%s', [mes.Size, str]);
  Log(s);

  s := '';
  case mes.Code of

    GET_STATES_MSG:
    begin
      InitState;
      for i := 1 to Pps.Count do
      begin
        pp := Pps.Items[i - 1];
        Init(mes);
        mes.SysDevice := SYSTEM_OPS;
        mes.TypeDevice := TYPEDEVICE_ORION;
        mes.NetDevice := ModuleNetDevice;
        mes.BigDevice := pp.Bigdevice;
        if pp.Connected then
          mes.Level := ORION_ENABLE_MSG
        else
          mes.Level := ORION_DISABLE_MSG;
        mes.Code := STATEORION_MSG;
        Send(mes);
        Log(
          Format('PP#%d Состояние >> %s',
          [pp.Number, OrionState[Ord(pp.Connected)]])
          );
        pp.NextOp := DOP_OUTKEYS_STATE;
      end;
    end;

    ZONE_DISARM_MSG:
    begin
      s := Format('Снять шлейф Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);

      pp := FindPpWithPultid(mes.BigDevice, ZONE, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(ZONE, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_ZONE_DISARM,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(
            ' -> найдено оборудование: PP#%d шлейф #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Шлейф не найден!';
    end;

    ZONE_ARM_MSG:
    begin
      s := Format('Взять шлейф Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);
      pp := FindPpWithPultid(mes.BigDevice, ZONE, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(ZONE, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_ZONE_ARM,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(
            ' -> найдено оборудование: PP#%d шлейф #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Шлейф не найден!';
    end;

    PART_DISARM_MSG:
    begin
      s := Format('Снять раздел Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);
      pp := FindPpWithPultid(mes.BigDevice, PART, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(PART, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_PART_DISARM,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(' -> найден элемент: PP#%d раздел #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Раздел не найден!';
    end;

    PART_ARM_MSG:
    begin
      s := Format('Взять раздел Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);
      pp := FindPpWithPultid(mes.BigDevice, PART, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(PART, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_PART_ARM,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(' -> найден элемент: PP#%d раздел #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Раздел не найден!';
    end;

    RELAY_OFF_MSG:
    begin
      s := Format('Выключить реле Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);
      pp := FindPpWithPultid(mes.BigDevice, OUTKEY, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(OUTKEY, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_RELAY_OFF,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(
            ' -> найдено оборудование: PP#%d реле #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Реле не найдено!';
    end;

    RELAY_ON_MSG:
    begin
      s := Format('Включить реле Big=%d Small=%d',
        [mes.BigDevice, mes.SmallDevice]);
      pp := FindPpWithPultid(mes.BigDevice, OUTKEY, mes.SmallDevice);
      if pp <> nil then
      begin
        Param := pp.FindWithIdChild(OUTKEY, mes.SmallDevice);
        if Param <> $FFFF then
        begin
          pp.AddCmd(DOP_CMD_RELAY_ON,
            TOrionObj(pp.ChildsObj.Items[Param]).Number);
          s := s + Format(
            ' -> найдено оборудование: PP#%d реле #%d',
            [pp.Number, TOrionObj(pp.ChildsObj.Items[Param]).Number]);
        end;
      end
      else
        s := s + '. Реле не найдено!';
    end;

  end;

  if s <> '' then
    Log('READ: Получена команда: ' + s);
end;

procedure TaMain.N1Click(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TaMain.N3Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TaMain.IndicatorMouseMove(Sender: TObject);
var
  i, total: word;
begin
  total := 0;
  for i := 1 to Pps.Count do
    if TPp(Pps.Items[i - 1]).GetConnect then
      Inc(total);

  TControl(Sender).Hint :=
    Format('На связи #%d из #%d приборов С2000-ПП',
    [total, Pps.Count]);
end;

function TaMain.ConDevs: word;
var
  i: word;
begin
  Result := 0;
  for i := 1 to Pps.Count do
    if TPp(Pps.Items[i - 1]).Connected then
      Inc(Result);
end;

procedure TaMain.SetIndicator;
var
  total: word;
begin
  total := ConDevs;
  with Indicator.Brush do
    if total = 0 then
      Color := clRed
    else if total < Pps.Count then
      Color := clYellow
    else
      Color := clLime;
end;

procedure TaMain.FormTimerTimer(Sender: TObject);
const
  MaxFormLog = 2000;
var
  i: longword;
begin
  SetIndicator;

  if length(Live) > 0 then
    Live[LiveId] := 0;
  if (length(Live) > 1) and (ConDevs = Pps.Count) then
    Live[LiveDev] := 0;

  if cs_log <> nil then
    if cs_log.TryEnter then
    try
      if (sl_log.Count > 0) then
      begin
        Memo1.Lines.BeginUpdate;
        Memo1.Lines.AddStrings(sl_log);

        if Memo1.Lines.Count > MaxFormLog then
          for i := 1 to MaxFormLog do
            Memo1.Lines.Delete(0);

        Memo1.Lines.EndUpdate;
        Memo1.SelStart := Length(Memo1.Text);
        Memo1.SelLength := 0;
      end;
    finally
      sl_log.Clear;
      cs_log.Leave;
    end;
end;

procedure TaMain.MenuItem10Click(Sender: TObject);
begin
  sleep(140000);
end;

procedure TaMain.MenuItem11Click(Sender: TObject);
begin
  Live[LiveDev] := LiveTime[LiveDev];
end;

procedure TaMain.MenuItem12Click(Sender: TObject);
begin
  Live[2] := LiveTime[2];
end;

procedure TaMain.MenuItem13Click(Sender: TObject);
begin
  while True do ;
end;

procedure TaMain.MenuItem1Click(Sender: TObject);
begin
  ShowMessage('Драйвер С2000-ПП,'#13#10'версия ' +
    GetVersion(Application.ExeName));
end;

procedure TaMain.MenuItem3Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_ZONE;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := ZONE_ARM_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem4Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_ZONE;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := ZONE_DISARM_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem5Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_PART;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := PART_ARM_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem6Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_PART;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := PART_DISARM_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem7Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_PART;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := RELAY_ON_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem8Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Proga := 1;
  mes.TypeDevice := TYPEDEVICE_PART;
  mes.NetDevice := ModuleNetDevice;
  mes.Bigdevice := SpinEdit1.Value;
  mes.Smalldevice := SpinEdit2.Value;
  mes.Code := RELAY_OFF_MSG;
  Consider(mes, '');
end;

procedure TaMain.MenuItem9Click(Sender: TObject);
var
  mes: KSBMES;
begin
  init(mes);
  mes.Code := 555;
  Send(mes);
end;

procedure TaMain.TimerVisibleTimer(Sender: TObject);
begin
  AppKsbTimer();
end;

function GetVersion(FileName: string): string;
var
  Version: TFileVersionInfo;
begin
  Version := TFileVersionInfo.Create(nil);
  Version.fileName := FileName;
  Version.ReadFileInfo;
  Result := Version.VersionStrings.Values['FileVersion'];
  {
  For i:= 1 to Version.VersionStrings.Count do
      amain.memo1.Lines.add('Version -> ' + Version.VersionStrings[i-1]);
  }
  Version.Free;
end;

function FindPpWithPultid(PpId: word; KindObj: TObjectType; ObjId: word): TPp;
var
  i: word;
  pp: TPp;
begin
  Result := nil;
  for i := 1 to Pps.Count do
  begin
    pp := Pps.Items[i - 1];
    if pp.Pultid = PpId then
      if pp.FindWithIdChild(KindObj, ObjId) <> $FFFF then
      begin
        Result := pp;
        Break;
      end
      else
        continue;
  end;
end;

{
function FindDevLine(Number: word): TLine;
var
  i: word;
  Line: TLine;

begin
  Result := nil;
  for i := 1 to Lines.Count do
  begin
    Line := Lines.Items[i - 1];
    if Line.FindChild(DEVPP, Number) <> $FFFF then
    begin
      Result := Line;
      break;
    end;
  end;
end;
}

procedure _AppKsbConsider(strmes: string);
var
  mes: KSBMES;
  tail: string;
  step: byte;
begin
  init(mes);
  tail := '';
  step := 0;
  try
    Unpack(strmes, mes, tail);
    step := 1;
    Consider(mes, tail);
  except
    if step = 0 then
      Log('Ошибка распаковки KSBMES сообщения !')
    else
      Log('Ошибка обработки KSBMES сообщения !');
  end;
end;


initialization
  Pointer_AppKsbConsider := @_AppKsbConsider;

  Lines := TList.Create;
  Pps := TList.Create;
  Event[1] := 'Восстановление сети 220В';
  Event[2] := 'Авария сети 220В';
  Event[3] := 'Тревога проникновения';
  Event[4] := 'Помеха';
  Event[5] := 'Реакция оператора';
  Event[6] := 'Помеха устранена';
  Event[9] := 'Активация УДП';
  Event[10] := 'Восстановление УДП';
  Event[17] := 'Неудачное взятие';
  Event[18] := 'Предъявлен код принуждения';
  Event[19] := 'Тест извещателя';
  Event[20] := 'Пожарное тестирование';
  Event[21] := 'Выключение пожарного тестирования';
  Event[22] := 'Восстановление контроля';
  Event[23] := 'Задержка взятия';
  Event[24] := 'Взятие зоны охраны';
  Event[25] := 'Доступ закрыт';
  Event[26] := 'Доступ отклонен';
  Event[27] := 'Дверь взломана';
  Event[28] := 'Доступ предоставлен';
  Event[29] := 'Запрет доступа';
  Event[30] := 'Восстановление доступ';
  Event[31] := 'Восстановление целостности двери';
  Event[32] := 'Проход';
  Event[33] := 'Дверь заблокирована';
  Event[34] := 'Идентификация';
  Event[35] := 'Восстановление технологического ШС';
  Event[36] := 'Нарушение технологического ШС';
  Event[37] := 'Тревога пожарного ШС';
  Event[38] := 'Нарушение 2 техн. ШС';
  Event[39] := 'Пожарное оборудование в норме';
  Event[40] := 'Тревога 2 пожарного ШС';
  Event[41] := 'Неисправность пожарного оборудования';
  Event[42] := 'Нестандартное оборудование';
  Event[44] := 'Внимание! Опастность пожара';
  Event[45] := 'Обрыв шлейфа';
  Event[46] := 'Обрыв ДПЛС';
  Event[47] := 'Восстановление ДПЛС';
  Event[58] := 'Тихая тревога';
  Event[67] := 'Изменение даты';
  Event[69] := 'Журнал заполнен';
  Event[70] := 'Журнал переполнен';
  Event[71] := 'Понижение уровня';
  Event[72] := 'Уровень в норме';
  Event[73] := 'Изменение времени';
  Event[74] := 'Повышение уровня';
  Event[75] := 'Аварийное повышение уровня';
  Event[76] := 'Повышение температуры';
  Event[77] := 'Аварийное понижение уровня';
  Event[78] := 'Температура в норме';
  Event[79] := 'Тревога затопления';
  Event[80] := 'Восстановление датчика затопления';
  Event[82] := 'Неисправность термометра';
  Event[83] := 'Восстановление термометра';
  Event[84] := 'Локальное программирование';
  Event[90] := 'Неисправность телефонной линии';
  Event[91] := 'Восстановление телефонной линии';
  Event[94] := 'Нагрев калорифера';
  Event[95] := 'Угроза охлаждения';
  Event[96] := 'Угроза замерзания';
  Event[97] := 'Перегрев обратной воды';
  Event[98] := 'Загрязнение воздушного фильтра';
  Event[99] := 'Отказ вентилятора';
  Event[100] := 'Лето-день';
  Event[101] := 'Лето-ночь';
  Event[102] := 'Зима-день';
  Event[103] := 'Лето-ночь';
  Event[109] := 'Снятие ШС';
  Event[110] := 'Сброс тревоги';
  Event[117] := 'Восстановление снятой зоны';
  Event[118] := 'Тревога зоны';
  Event[119] := 'Нарушение снятой зоны';
  Event[121] := 'Обрыв цепи выхода (реле)';
  Event[122] := 'Короткое замыкание цепи выхода (реле)';
  Event[123] := 'Восстановление цепи выхода (реле)';
  Event[126] := 'Отключение выхода (реле)';
  Event[127] := 'Подключение выхода (реле)';
  Event[128] :=
    'Изменение состояния выхода (включение/выключение реле)';
  Event[130] := 'Включение насоса';
  Event[131] := 'Выключение насоса';
  Event[135] := 'Ошибка при автоматическом тестировании';
  Event[136] := 'Восстановление напряжения питания';
  Event[137] := 'Срабатывание цепи пуска';
  Event[138] := 'Отказ цепи пуска';
  Event[139] := 'Неудачный пуск ПТ';
  Event[140] := 'Ручной тест';
  Event[141] := 'Задержка пуска АУП';
  Event[142] := 'Автоматика АУП выключена';
  Event[143] := 'Отмена пуска АУП';
  Event[144] := 'Тушение';
  Event[145] := 'Аварийный пуск АУП';
  Event[146] := 'Пуск АУП';
  Event[147] := 'Блокировка пуска АУП';
  Event[148] := 'Автоматика АУП включена';
  Event[149] := 'Тревога взлома';
  Event[150] := 'Пуск речевого оповещания';
  Event[151] := 'Сброс пуска речевого оповещания';
  Event[152] := 'Восстановление зоны контроля взлома';
  Event[153] := 'ИУ в рабочем состоянии';
  Event[154] := 'ИУ в исходном состоянии';
  Event[155] := 'Отказ ИУ';
  Event[156] := 'Ошибка ИУ';
  Event[158] := 'Восстановление внутренней зоны';
  Event[159] := 'Задержка пуска РО';
  Event[161] := 'Останов задержки пуска АУП';
  Event[165] := 'Ошибка параметров ШС';
  Event[172] := 'Включение принтера';
  Event[173] := 'Выключение принтера';
  Event[187] := 'ШС отключен (Потеря связи)';
  Event[188] := 'ШС подключен (Восстановление связи)';
  Event[189] := 'Потеря связи по ветви ДПЛС1';
  Event[190] := 'Потеря связи по ветви ДПЛС2';
  Event[191] := 'Восстановление связи по ветви ДПЛС1';
  Event[192] := 'Отключение выходного напряжения';
  Event[193] := 'Подключение выходного напряжения';
  Event[194] := 'Перегрузка источника питания';
  Event[195] := 'Перегрузка источника устранена';
  Event[196] := 'Неисправность ЗУ';
  Event[197] := 'Восстановление ЗУ';
  Event[198] := 'Неисправность источника питания';
  Event[199] := 'Восстановление источника питания';
  Event[200] := 'Восстановление батареи';
  Event[201] := 'Восстановление связи по ветви ДПЛС2';
  Event[202] := 'Неисправность батареи';
  Event[203] := 'Сброс сторожевого таймера';
  Event[204] := 'Требуется обслуживание';
  Event[205] := 'Ошибка теста АКБ';
  Event[206] := 'Понижение температуры';
  Event[211] := 'Батарея разряжена';
  Event[212] := 'Разряд резервной батареи';
  Event[213] := 'Восстановление резервной батареи';
  Event[214] := 'Короткое замыкание';
  Event[215] := 'Короткое замыкание ДПЛС';
  Event[216] := 'Сработка датчика';
  Event[217] := 'Отключение ветви интерфейса RS-485';
  Event[218] := 'Восстановление ветви интерфейса RS-485';
  Event[219] := 'Доступ открыт';
  Event[220] := 'Срабатывание СДУ';
  Event[221] := 'Отказ СДУ';
  Event[222] := 'Авария ДПЛС';
  Event[223] := 'Отметка наряда';
  Event[224] := 'Некорректный ответ устройства в ДПЛС';
  Event[225] := 'Неустойчивый ответ устройства в ДПЛС';
  Event[237] := 'Раздел снят по принуждению';
  Event[238] := 'Смена дежурства';
  Event[241] := 'Взятие раздела';
  Event[242] := 'Снятие раздела';
  Event[243] := 'Удаленный запрос на взятие';
  Event[244] := 'Удаленный запрос на снятие';
  Event[245] := 'Удаленный запрос доступа';
  Event[246] := 'Неверный пароль';
  Event[247] := 'Неверный раздел';
  Event[248] := 'Превышение полномочий';
  Event[249] :=
    'Программирование (произошло изменение параметров конфигарации)';
  Event[250] := 'Потерян контакт с устройством';
  Event[251] := 'Восстановлен контакт с прибором';
  Event[252] := 'Подмена прибора';
  Event[253] := 'Включение пульта С2000';
  Event[254] := 'Отметка даты';
  Event[255] := 'Отметка времени';
  Event[265] := 'Два пожара';
  Event[270] := 'Доступ предоставлен (по кнопке)';
  Event[271] := 'Проход (по кнопке)';
  Event[272] := 'Запрет доступа (по кнопке)';
  Event[280] := 'Взятие группы разделов';
  Event[281] := 'Снятие группы разделов';
  Event[311] := 'Включить';
  Event[312] := 'Выключить';
  Event[313] := 'Включить на время';
  Event[314] := 'Выключить на время';
  Event[315] := 'Мигать из состояния выключено';
  Event[316] := 'Мигатьиз состояния включено';
  Event[317] := 'Мигать из состояния выключено на время';
  Event[318] := 'Мигать из состояния включено на время';
  Event[319] := 'Лампа';
  Event[320] := 'ПЦН';
  Event[321] := 'АСПТ';
  Event[322] := 'Сирена';
  Event[323] := 'Пожарный ПЦН';
  Event[324] := 'Выход неисправности';
  Event[325] := 'Пожарная лампа';
  Event[326] := 'Старая тактика ПЦН';
  Event[327] := 'Включить на время перед взятием';
  Event[328] := 'Выключить на время перед взятием';
  Event[329] := 'Включить на время при взятии';
  Event[330] := 'Выключить на время при взятии';
  Event[331] := 'Включить на время при снятии';
  Event[332] := 'Выключить на время при снятии';
  Event[333] := 'Включить на время при невзятии';
  Event[334] := 'Выключить на время при невзятии';
  Event[335] :=
    'Включить на время при нарушении технологического ШС';
  Event[336] :=
    'Выключить на время при тушении технологического ШС';
  Event[337] := 'Включить при снятии';
  Event[338] := 'Выключить при снятии';
  Event[339] := 'Включить при взятии';
  Event[340] := 'Выключить при взятии';
  Event[341] :=
    'Включить при нарушении технологического ШС';
  Event[342] :=
    'Выключить при нарушении технологического ШС';
  Event[343] := 'АСПТ-1';
  Event[344] := 'АСПТ-А';
  Event[345] := 'АСПТ-А1';
  Event[360] := 'Запуск сценария управления';
  Event[380] := 'Передано сообщение';
  Event[390] := 'Запрос вкл. автоматики';
  Event[391] := 'Запрос выкл. автоматики';
  Event[392] := 'Запрос на пуск';
  Event[393] := 'Запрос на сброс пожаротушения';
  Event[401] := 'Включение реле';
  Event[402] := 'Выключение реле';
  Event[403] := 'Реле мигает 3';
  Event[404] := 'Реле мигает 4';
  Event[405] := 'Реле мигает 5';
  Event[406] := 'Реле мигает 6';
  Event[407] := 'Реле мигает 7';
  Event[408] := 'Реле мигает 8';
  Event[409] := 'Реле мигает 9';
  Event[440] := 'Изменение состояния';

  RelayState[0] := 'Выкл.';
  RelayState[1] := 'Вкл.';
  OrionState[0] := 'Связь потеряна';
  OrionState[1] := 'Связь установлена';

  cs_istate := TCriticalSection.Create;

finalization
  FreeAndNil(cs_istate);

end.
