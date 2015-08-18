object MainForm: TMainForm
  Left = 192
  Top = 114
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'P2P UDP Demo'
  ClientHeight = 165
  ClientWidth = 233
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ListView1: TListView
    Left = 8
    Top = 8
    Width = 217
    Height = 150
    Columns = <
      item
        Caption = #29992#25143#21517
        Width = 60
      end
      item
        Caption = 'IP'#22320#22336
        Width = 100
      end
      item
        Caption = #31471#21475
      end>
    GridLines = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Timer1: TTimer
    Interval = 30000
    OnTimer = Timer1Timer
    Left = 184
    Top = 112
  end
end
