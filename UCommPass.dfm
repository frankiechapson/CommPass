object FCP: TFCP
  Left = 369
  Top = 231
  Width = 858
  Height = 496
  Caption = 'CommPass v 1.1 by Frankie Chapson'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 850
    Height = 462
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    Style = tsButtons
    TabOrder = 0
    OnResize = PageControlResize
  end
  object XMLDocument: TXMLDocument
    Active = True
    Left = 560
    Top = 16
    DOMVendorDesc = 'MSXML'
  end
end
