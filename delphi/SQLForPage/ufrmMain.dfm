object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 440
  ClientWidth = 783
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 783
    Height = 73
    Align = alTop
    Caption = 'pnlTop'
    TabOrder = 0
    object btnGetPageSQL: TButton
      Left = 4
      Top = 25
      Width = 101
      Height = 25
      Caption = 'btnGetPageSQL'
      TabOrder = 0
      OnClick = btnGetPageSQLClick
    end
    object btnRecordCountSQL: TButton
      Left = 208
      Top = 16
      Width = 129
      Height = 25
      Caption = 'btnRecordCountSQL'
      TabOrder = 1
      OnClick = btnRecordCountSQLClick
    end
    object edtPageIndex: TEdit
      Left = 4
      Top = 2
      Width = 121
      Height = 21
      TabOrder = 2
      Text = '0'
    end
  end
  object pgcMain: TPageControl
    Left = 0
    Top = 73
    Width = 783
    Height = 367
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      object mmoTemplate: TMemo
        Left = 0
        Top = 0
        Width = 775
        Height = 339
        Align = alClient
        Lines.Strings = (
          'select [selectlist]'
          '       bx.BoxName, b.BoxPortID, b.DeviceName'
          '       [/selectlist]'
          '  from wn_device b'
          '    left join wn_box bx on b.BoxID = bx.BoxID'
          '  [page]'
          '  [countIgnore]'
          '  order by bx.BoxName'
          '  [/countIgnore]')
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'TabSheet2'
      ImageIndex = 1
      object mmoSQL: TMemo
        Left = 0
        Top = 0
        Width = 775
        Height = 339
        Align = alClient
        Lines.Strings = (
          'mmoSQL')
        TabOrder = 0
      end
    end
  end
end
