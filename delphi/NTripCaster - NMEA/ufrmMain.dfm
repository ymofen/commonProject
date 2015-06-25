object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'NtripCaster'
  ClientHeight = 374
  ClientWidth = 597
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 597
    Height = 374
    ActivePage = tsConfig
    Align = alClient
    TabOrder = 0
    object tsConfig: TTabSheet
      Caption = #37197#32622
      object Label1: TLabel
        Left = 32
        Top = 77
        Width = 48
        Height = 13
        Caption = #25509#20837#31471#21475
      end
      object Label2: TLabel
        Left = 32
        Top = 149
        Width = 76
        Height = 13
        Caption = 'NMEA'#36716#21457#35831#27714
      end
      object edtPort: TEdit
        Left = 86
        Top = 74
        Width = 121
        Height = 21
        TabOrder = 0
        Text = '2101'
      end
      object btnStart: TButton
        Left = 32
        Top = 16
        Width = 75
        Height = 25
        Action = actStart
        TabOrder = 1
      end
      object edtNMEAHost: TEdit
        Left = 86
        Top = 168
        Width = 121
        Height = 21
        TabOrder = 2
        Text = '127.0.0.1'
      end
      object edtNMEAPort: TEdit
        Left = 86
        Top = 195
        Width = 121
        Height = 21
        TabOrder = 3
        Text = '4001'
      end
    end
    object tsMonitor: TTabSheet
      Caption = #30417#25511#38754#26495
      ImageIndex = 1
    end
    object tsLog: TTabSheet
      Caption = #26085#24535
      ImageIndex = 2
      object mmoLog: TMemo
        Left = 0
        Top = 0
        Width = 589
        Height = 346
        Align = alClient
        TabOrder = 0
      end
    end
  end
  object actlstMain: TActionList
    Left = 412
    Top = 32
    object actStart: TAction
      Caption = #24320#21551#26381#21153
      OnExecute = actStartExecute
    end
  end
  object tmrCheck: TTimer
    Enabled = False
    Interval = 20000
    Left = 408
    Top = 80
  end
end
