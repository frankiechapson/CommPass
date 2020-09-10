unit hkSend; 
 
interface 
 
uses 
  SysUtils, 
  Messages, 
  Forms, 
  Windows, 
  Classes; 
 
type 
  TSendKeyError = (skNone, skFailSetHook, skInvalidToken, skUnknownError); 
 
function SendKeys(S: String; Wait: Boolean): TSendKeyError; 
 
implementation 
 
type 
  ESendKeyError = class(Exception); 
  ESetHookError = class(ESendKeyError); 
  EInvalidToken = class(ESendKeyError); 
 
  TKeyDef = record 
    Key : String; 
    Code: UINT; 
  end; 
 
  TMessageList = class(TList) 
  public 
    destructor Destroy; override; 
  end; 
 
const 
  MaxKeys = 43; 
  ShiftKey = '+'; 
  ControlKey = '^'; 
  AltKey = '%'; 
  EnterKey = '~'; 
 
  KeyGroupOpen = '{'; 
  KeyGroupClose = '}'; 
 
  KeyTokens = '{}~%^+'; 
 
  KeyDefs : array[1..MaxKeys] of TKeyDef = ( 
   (Key: 'BACKSPACE'  ; Code: VK_BACK), 
   (Key: 'BKSP'       ; Code: VK_BACK), 
   (Key: 'BS'         ; Code: VK_BACK), 
   (Key: 'CAPS'       ; Code: VK_CAPITAL), 
   (Key: 'CAPSLOCK'   ; Code: VK_CAPITAL), 
   (KEy: 'CLEAR'      ; Code: VK_CLEAR), 
   (Key: 'DEL'        ; Code: VK_DELETE), 
   (Key: 'DELETE'     ; Code: VK_DELETE), 
   (Key: 'DOWN'       ; Code: VK_DOWN), 
   (Key: 'END'        ; Code: VK_END), 
   (Key: 'ENTER'      ; Code: VK_RETURN), 
   (Key: 'ESC'        ; Code: VK_ESCAPE), 
   (Key: 'ESCAPE'     ; Code: VK_ESCAPE), 
   (Key: 'HOME'       ; Code: VK_HOME), 
   (Key: 'INS'        ; Code: VK_INSERT), 
   (Key: 'INSERT'     ; Code: VK_INSERT), 
   (Key: 'LEFT'       ; Code: VK_LEFT), 
   (Key: 'NUM'        ; Code: VK_NUMLOCK), 
   (Key: 'NUMLOCK'    ; Code: VK_NUMLOCK), 
   (Key: 'DOWN'       ; Code: VK_DOWN), 
   (Key: 'PAGEDOWN'   ; Code: VK_NEXT), 
   (Key: 'PGDN'       ; Code: VK_NEXT), 
   (Key: 'PAGEUP'     ; Code: VK_PRIOR), 
   (Key: 'PGUP'       ; Code: VK_PRIOR), 
   (Key: 'RIGHT'      ; Code: VK_RIGHT), 
   (Key: 'SCROLL'     ; Code: VK_SCROLL), 
   (Key: 'SCROLLLOCK' ; Code: VK_SCROLL), 
   (Key: 'PRINTSCREEN'; Code: VK_SNAPSHOT), 
   (Key: 'PRTSC'      ; Code: VK_SNAPSHOT), 
   (Key: 'TAB'        ; Code: VK_TAB), 
   (Key: 'UP'         ; Code: VK_UP), 
   (Key: 'F1'         ; Code: VK_F1), 
   (Key: 'F2'         ; Code: VK_F2), 
   (Key: 'F3'         ; Code: VK_F3), 
   (Key: 'F4'         ; Code: VK_F4), 
   (Key: 'F5'         ; Code: VK_F5), 
   (Key: 'F6'         ; Code: VK_F6), 
   (Key: 'F7'         ; Code: VK_F7), 
   (Key: 'F8'         ; Code: VK_F8), 
   (Key: 'F9'         ; Code: VK_F9), 
   (Key: 'F10'        ; Code: VK_F10), 
   (Key: 'F11'        ; Code: VK_F11), 
   (Key: 'F12'        ; Code: VK_F12)); 
 
var 
  bPlaying, 
  bAltPressed, 
  bControlPressed, 
  bShiftPressed    : Boolean; 
  Delay, CurDelay  : Integer; 
  Event            : TEventMsg; 
  MessageList      : TMessageList; 
  iMsgCount        : Integer; 
  HookHandle       : hHook; 
 
destructor TMessageList.Destroy; 
var 
  i : Integer; 
begin 
  for i:=0 to Count-1 do 
   Dispose(PEventMsg(Items[i])); 
  inherited; 
end; 
 
procedure StopPlayback; 
begin 
  if bPlaying then UnhookWindowsHookEx(HookHandle); 
  MessageList.Free; 
  bPlaying := False; 
end; 
 
function Playback(nCode: Integer; wp: wParam; lp: lParam): Longint; stdcall; export; 
begin 
  Result := 0; 
  case nCode of 
    HC_SKIP: 
     begin 
       inc(iMsgCount); 
       if iMsgCount>=MessageList.Count then 
        StopPlayback 
       else 
        begin 
          Event := TEventMsg(MessageList.Items[iMsgCount]^); 
          CurDelay := Delay; 
        end; 
     end; 
    HC_GETNEXT: 
     begin 
       with PEventMsg(lp)^ do 
        begin 
          Message := Event.Message; 
          ParamL  := Event.ParamL; 
          ParamH  := Event.ParamH; 
          Time    := Event.Time; 
          hWnd    := Event.hWnd; 
        end; 
        Result := CurDelay; 
        CurDelay := 0; 
     end; 
    else 
     begin 
       Result := CallNextHookEx(HookHandle, nCode, wp, lp); 
     end; 
  end; 
end; 
 
procedure StartPlayback; 
begin 
  Event := TEventMsg(MessageList.Items[0]^); 
  iMsgCount := 0; 
  HookHandle := SetWindowsHookEx(WH_JOURNALPLAYBACK, @Playback, hInstance, 0); 
  if HookHandle=0 then 
   raise ESetHookError.Create('Could not set hook') 
  else 
   bPlaying := True; 
end; 
 
procedure MakeMessage(vKey, M: UINT); 
var 
  E: PEventMsg; 
begin 
  New(E); 
  with E^ do 
   begin 
     Message := M; 
     ParamL  := vKey; 
     ParamH  := MapVirtualKey(vKey, 0); 
     Time    := GetTickCount; 
     hWnd    := 0; 
   end; 
  MessageList.Add(E); 
end; 
 
function FindKeyInArray(Key: String; var Code: UINT): Boolean; 
var 
  i : Integer; 
begin 
  Result := False; 
  for i:=Low(KeyDefs) to High(KeyDefs) do 
   if UpperCase(Key)=KeyDefs[i].Key then 
    begin 
      Code := KeyDefs[i].Code; 
      Result := True; 
      Exit; 
    end; 
end; 
 
const 
  vkKeySet = [VK_SPACE, Ord('A')..Ord('Z'), VK_MENU, VK_F1..VK_F12]; 
 
procedure SimulateKey(Code: UINT; Down: Boolean); 
const 
  KeyMsg: array[Boolean] of UINT = (WM_KEYUP, WM_KEYDOWN); 
  SysMsg: array[Boolean] of UINT = (WM_SYSKEYUP, WM_SYSKEYDOWN); 
begin 
  if bAltPressed and (not bControlPressed) and (Code in vkKeySet) then 
   MakeMessage(Code, SysMsg[Down]) 
  else 
   MakeMessage(Code, KeyMsg[Down]) 
end; 
 
procedure SimulateKeyPress(Code: UINT); 
begin 
  if bAltPressed then SimulateKey(VK_MENU, True); 
  if bControlPressed then SimulateKey(VK_CONTROL, True); 
  if bShiftPressed and not bControlPressed then SimulateKey(VK_SHIFT, True); 
  SimulateKey(Code, True); 
  SimulateKey(Code, False); 
  if bShiftPressed and not bControlPressed then 
   begin 
     SimulateKey(VK_SHIFT, False); 
     bShiftPressed := False; 
   end; 
  if bControlPressed then 
   begin 
     SimulateKey(VK_CONTROL, False); 
     bControlPressed := False; 
   end; 
  if bAltPressed then 
   begin 
     SimulateKey(VK_MENU, False); 
     bAltPressed := False; 
   end; 
end; 
 
procedure NormalKeyPress(C: Char); 
var 
  KeyCode, 
  Shift  : UINT; 
begin 
  KeyCode := vkKeyScan(C); 
  Shift := HiByte(KeyCode); 
  if (Shift and 1)=1 then bShiftPressed := True; 
  if (Shift and 2)=2 then bControlPressed := True; 
  if (Shift and 4)=4 then bAltPressed := True; 
  SimulateKeyPress(LoByte(KeyCode)) 
end; 
 
function CheckDelay(Token: String): Boolean; 
begin 
  Token := UpperCase(Token); 
  Result := Pos('DELAY', Token)=1; 
  if Result then 
   begin 
     Delete(Token, 1, 5); 
     if (Length(Token)>0) and (Token[1]='=') then Delete(Token, 1, 1); 
     Delay := StrToIntDef(Token, 0); 
   end; 
end; 
 
procedure ProcessKey(S: String); 
var 
  Index  : Integer; 
  Token  : String; 
  KeyCode: UINT; 
begin 
  Index := 1; 
  repeat 
    case S[Index] of 
      KeyGroupOpen: 
       begin 
         Token := ''; 
         inc(Index); 
         while (Index<Length(S)) and (S[Index]<>KeyGroupClose) do 
          begin 
            Token := Token + S[Index]; 
            inc(Index); 
            if (Length(Token)=12) and (S[Index]<>KeyGroupClose) then 
             raise EInvalidToken.Create('No closing brace') 
          end; 
         if (Length(Token)=1) and (Pos(Token, KeyTokens)>0) then 
          NormalKeyPress(Token[1]) 
         else if FindKeyInArray(Token, KeyCode) then 
          SimulateKeyPress(KeyCode) 
         else if not CheckDelay(Token) then 
          raise EInvalidToken.Create('Invalid token'); 
       end; 
      AltKey: 
       bAltPressed := True; 
      ControlKey: 
       bControlPressed := True; 
      ShiftKey: 
       bShiftPressed := True; 
      EnterKey: 
       SimulateKeyPress(VK_RETURN); 
      else 
       NormalKeyPress(S[Index]); 
    end; 
    inc(Index); 
  until Index > Length(S); 
end; 
 
function SendKeys(S: String; Wait: Boolean): TSendKeyError; 
begin 
  bAltPressed := False; 
  bControlPressed := False; 
  bShiftPressed := False; 
  Result := skNone; 
  Delay := 0; 
  if bPlaying or (S='') then Exit; 
  try 
    MessageList := TMessageList.Create; 
    ProcessKey(S); 
    StartPlayback; 
    if Wait then 
     repeat 
       Application.ProcessMessages; 
     until bPlaying = False; 
  except 
   on E:ESendKeyError do 
    begin 
      MessageList.Free; 
      if E is ESetHookError then 
       Result := skFailSetHook 
      else if E is EInvalidToken then 
       Result := skInvalidToken; 
    end 
   else 
    Result := skUnknownError; 
  end; 
end; 
 
exports 
   Playback; 
 
end. 