object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'frmMain'
  ClientHeight = 385
  ClientWidth = 567
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pnlConnect: TPanel
    Left = 0
    Top = 0
    Width = 567
    Height = 41
    Align = alTop
    TabOrder = 0
    object edtHost: TEdit
      Left = 16
      Top = 11
      Width = 225
      Height = 21
      TabOrder = 0
      Text = 'mongodb://192.168.18.50:27017'
    end
    object btnConnect: TButton
      Left = 272
      Top = 9
      Width = 75
      Height = 25
      Caption = 'btnConnect'
      TabOrder = 1
      OnClick = btnConnectClick
    end
  end
  object btnInsert: TButton
    Left = 16
    Top = 56
    Width = 75
    Height = 25
    Caption = 'btnInsert'
    TabOrder = 1
    OnClick = btnInsertClick
  end
  object btnFindOne: TButton
    Left = 16
    Top = 104
    Width = 75
    Height = 25
    Caption = 'btnFindOne'
    TabOrder = 2
    OnClick = btnFindOneClick
  end
  object btnBatchInsert: TButton
    Left = 184
    Top = 56
    Width = 75
    Height = 25
    Caption = 'btnBatchInsert'
    TabOrder = 3
    OnClick = btnBatchInsertClick
  end
  object edtCounter: TEdit
    Left = 288
    Top = 58
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '100000'
  end
  object btnInsertBigBson: TButton
    Left = 184
    Top = 104
    Width = 113
    Height = 25
    Caption = 'btnInsertBigBson'
    TabOrder = 5
    OnClick = btnInsertBigBsonClick
  end
  object btnBson: TButton
    Left = 16
    Top = 152
    Width = 75
    Height = 25
    Caption = 'btnBson'
    TabOrder = 6
    OnClick = btnBsonClick
  end
  object edtCollection: TEdit
    Left = 448
    Top = 56
    Width = 121
    Height = 21
    TabOrder = 7
    Text = 'speed2'
  end
end
