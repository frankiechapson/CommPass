unit UCommPass;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, sndkey32, ComCtrls, xmldom, XMLIntf, msxmldom, XMLDoc,  ClipBrd,
  Grids;

type


  TFCP = class(TForm)
    PageControl: TPageControl;
    XMLDocument: TXMLDocument;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StringGridEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure StringGridMouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;   Rect: TRect; State: TGridDrawState);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer;   var CanSelect: Boolean);
    procedure PageControlResize(Sender: TObject);
  private
    { Private declarations }
    xmlNodes     : IXMLNode;
    Command      : String;
    PasteString  : String;
    StringToDrop : String;
    Tabok        : Array [1..50] of TTabSheet;
    TabCount     : Integer;
  public
    { Public declarations }
  end;

var
  FCP: TFCP;

implementation

{$R *.dfm}

function GetWndFromClientPoint(ClientWnd: HWND; Pt: TPoint): HWND;
begin
  MapWindowPoints(ClientWnd, GetDesktopWindow, Pt, 1);
  Result := WindowFromPoint(Pt);
end;


procedure TFCP.FormShow(Sender: TObject);
var
    i           : Integer;
    xmlNodei    : IXMLNode;
    j           : Integer;
    xmlNodej    : IXMLNode;
    StringGrid  : TStringGrid;
begin
  TabCount  := 0;
  for i := 0 to xmlNodes.ChildNodes.Count - 1 do
    begin
      xmlNodei := xmlNodes.ChildNodes.Get(i);
      Inc(TabCount);
      Tabok[TabCount]                := TTabSheet.Create(PageControl);
      Tabok[TabCount].Caption        := xmlNodei.Attributes['NAME'] ;
      Tabok[TabCount].Align          := alClient;
      Tabok[TabCount].PageControl    := PageControl;

      StringGrid                     := TStringGrid.Create(Tabok[TabCount]);
      StringGrid.Parent              := Tabok[TabCount];
      StringGrid.Align               := alClient;
      StringGrid.ColCount            := 3;
      StringGrid.RowCount            := 0;
      StringGrid.ColWidths[0]        := 0;
      StringGrid.ColWidths[1]        := 0;
      StringGrid.ColWidths[2]        := PageControl.Width-10;
      StringGrid.ScrollBars          := ssVertical;
      StringGrid.Options             := StringGrid.Options - [goRangeSelect];
      StringGrid.OnSelectCell        := StringGridSelectCell;
      StringGrid.OnMouseDown         := StringGridMouseDown;
      StringGrid.OnEndDrag           := StringGridEndDrag;
      StringGrid.OnDrawCell          := StringGridDrawCell;
      for j := 0 to xmlNodei.ChildNodes.Count - 1 do
        begin
          xmlNodej              := xmlNodei.ChildNodes.Get(j);
          StringGrid.RowCount   := j+1;
          StringGrid.Cells[2,j] := xmlNodej.Text ;
          StringGrid.Cells[0,j] := uppercase(xmlNodej.NodeName);
          if uppercase(xmlNodej.NodeName) = 'CP' then StringGrid.Cells[1,j] := xmlNodej.Attributes['With'] ;
        end;
    end;
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.FormCreate(Sender: TObject);
begin
    XMLDocument.Encoding := 'UTF-8';
    XMLDocument.LoadFromFile(ChangeFileExt( Application.ExeName, '.XML' ));
    xmlNodes             := XMLDocument.DocumentElement;
    XMLDocument.Active   := False;
end;

(*-------------------------------------------------------------------------*)
procedure StrToClipbrd(StrValue: string);
var
  hMem: THandle;
  pMem: PChar;
begin
  hMem := GlobalAlloc(GHND or GMEM_SHARE, Length(StrValue) + 1);
  if hMem <> 0 then
  begin
    pMem := GlobalLock(hMem);
    if pMem <> nil then
    begin
      StrPCopy(pMem, StrValue);
      GlobalUnlock(hMem);
      if OpenClipboard(0) then
      begin
        EmptyClipboard;
        SetClipboardData(CF_TEXT, hMem);
        CloseClipboard;
      end
      else
        GlobalFree(hMem);
    end
    else
      GlobalFree(hMem);
  end;
end;

(*-------------------------------------------------------------------------*)
function GetStrFromClipbrd: string;
begin
  if Clipboard.HasFormat(CF_TEXT) then
    Result := Clipboard.AsText
  else
  begin
    ShowMessage('There is no text in the Clipboard!');
    Result := '';
  end;
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.StringGridEndDrag(Sender, Target: TObject; X, Y: Integer);
var
    Wnd        : HWND;
    KBDKeys    : String;
begin
    Wnd := GetWndFromClientPoint(HWND_DESKTOP, Point(X, Y));
    SetForegroundWindow( WND );

    if Command = 'CP' then
      begin
        StringToDrop := StringReplace( StringToDrop, '{lt}', '<', [rfReplaceAll, rfIgnoreCase]);
        StringToDrop := StringReplace( StringToDrop, '{gt}', '>', [rfReplaceAll, rfIgnoreCase]);
        StringToDrop := StringReplace( StringToDrop, '{at}', '@', [rfReplaceAll, rfIgnoreCase]);
        StringToDrop := StringReplace( StringToDrop, '{and}', '&', [rfReplaceAll, rfIgnoreCase]);
        StringToDrop := StringReplace( StringToDrop, '{enter}', chr(13), [rfReplaceAll, rfIgnoreCase]);
        StrToClipbrd(StringToDrop);
        KBDKeys := PasteString;
      end
    else
      KBDKeys := StringToDrop;

    SendKeys(pchar(KBDKeys), True);
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.StringGridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    (Sender as TStringGrid).BeginDrag(true);
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;  Rect: TRect; State: TGridDrawState);
begin
  if (Sender as TStringGrid).Cells[0,ARow] = 'COMMENT' then
    begin
      (Sender as TStringGrid).Canvas.Brush.Color := $CCCCFF;
    end
  else
    begin
      (Sender as TStringGrid).Canvas.Brush.Color := $CCFFCC;
    end;
      (Sender as TStringGrid).Canvas.Brush.Style:= bsSolid;
      (Sender as TStringGrid).Canvas.Pen.Style  := psClear;
  (Sender as TStringGrid).Canvas.FillRect(Rect);
  (Sender as TStringGrid).Canvas.TextOut(Rect.Left+2,Rect.Top+2,(Sender as TStringGrid).Cells[ACol, ARow]);
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer;  var CanSelect: Boolean);
begin
  if (Sender as TStringGrid).Cells[0,ARow] = 'COMMENT' then
    begin
      StringToDrop := '';
      Command      := '';
      PasteString  := '';
    end
  else
    begin
      Command      := (Sender as TStringGrid).Cells[0,ARow];
      PasteString  := (Sender as TStringGrid).Cells[1,ARow];
      StringToDrop := (Sender as TStringGrid).Cells[2,ARow];
    end;
end;

(*-------------------------------------------------------------------------*)
procedure TFCP.PageControlResize(Sender: TObject);
var
    i           : Integer;
    j           : Integer;
begin
  for i := 1 to TabCount do
    for j := 0 to Tabok[i].ComponentCount - 1 do
      if Tabok[i].Components[j].ClassType = TStringGrid then
        (Tabok[i].Components[j] as TStringGrid).ColWidths[2] := PageControl.Width-10;
end;


end.
