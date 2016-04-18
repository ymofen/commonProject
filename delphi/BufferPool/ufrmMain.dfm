object Form1: TForm1
  Left = 316
  Top = 240
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    880
    441)
  PixelsPerInch = 96
  TextHeight = 13
  object btnNewPool: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnNewPool'
    TabOrder = 0
    OnClick = btnNewPoolClick
  end
  object btnFreePool: TButton
    Left = 8
    Top = 48
    Width = 75
    Height = 25
    Caption = 'btnFreePool'
    TabOrder = 1
    OnClick = btnFreePoolClick
  end
  object btnSimpleTester: TButton
    Left = 120
    Top = 8
    Width = 137
    Height = 25
    Caption = 'btnSimpleTester'
    TabOrder = 2
    OnClick = btnSimpleTesterClick
  end
  object btnThreadTester: TButton
    Left = 120
    Top = 48
    Width = 137
    Height = 25
    Caption = 'btnThreadTester'
    TabOrder = 3
    OnClick = btnThreadTesterClick
  end
  object btnThreadTester2: TButton
    Left = 304
    Top = 48
    Width = 137
    Height = 25
    Caption = 'btnThreadTester2'
    TabOrder = 4
    OnClick = btnThreadTester2Click
  end
  object mmoLog: TMemo
    Left = 8
    Top = 79
    Width = 864
    Height = 354
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'mmoLog')
    TabOrder = 5
  end
  object btnPoolInfo: TButton
    Left = 304
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnPoolInfo'
    TabOrder = 6
    OnClick = btnPoolInfoClick
  end
  object btnClear: TButton
    Left = 464
    Top = 48
    Width = 75
    Height = 25
    Caption = 'btnClear'
    TabOrder = 7
    OnClick = btnClearClick
  end
  object btnCheckBounds: TButton
    Left = 592
    Top = 8
    Width = 89
    Height = 25
    Caption = 'btnCheckBounds'
    TabOrder = 8
    OnClick = btnCheckBoundsClick
  end
  object btnOutOfBounds: TButton
    Left = 456
    Top = 8
    Width = 118
    Height = 25
    Caption = 'btnOutOfBounds'
    TabOrder = 9
    OnClick = btnOutOfBoundsClick
  end
  object btnSpeedTester: TButton
    Left = 592
    Top = 48
    Width = 89
    Height = 25
    Caption = 'btnSpeedTester'
    TabOrder = 10
    OnClick = btnSpeedTesterClick
  end
  object edtThread: TEdit
    Left = 687
    Top = 52
    Width = 121
    Height = 21
    TabOrder = 11
    Text = '5'
  end
  object btnSpinLocker: TButton
    Left = 687
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnSpinLocker'
    TabOrder = 12
    OnClick = btnSpinLockerClick
  end
end
