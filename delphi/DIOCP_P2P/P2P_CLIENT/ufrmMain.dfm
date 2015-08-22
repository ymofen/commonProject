object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 563
  ClientWidth = 1028
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
    Width = 161
    Height = 563
    Align = alLeft
    BevelKind = bkTile
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 11
      Top = 16
      Width = 72
      Height = 13
      Caption = #26412#22320#20390#21548#31471#21475
    end
    object Label2: TLabel
      Left = 11
      Top = 173
      Width = 35
      Height = 13
      Caption = #25105#30340'ID'
    end
    object edtPort: TEdit
      Left = 8
      Top = 35
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '9984'
    end
    object btnAbout: TButton
      Left = 8
      Top = 560
      Width = 75
      Height = 25
      Caption = #20851#20110
      TabOrder = 1
    end
    object btnP2PEngine: TButton
      Left = 8
      Top = 129
      Width = 75
      Height = 25
      Caption = #24320#21551'P2P'
      TabOrder = 2
      OnClick = btnP2PEngineClick
    end
    object edtRemoteIP: TEdit
      Left = 8
      Top = 75
      Width = 121
      Height = 21
      TabOrder = 3
      Text = '127.0.0.1'
    end
    object edtRemotPort: TEdit
      Left = 8
      Top = 102
      Width = 65
      Height = 21
      TabOrder = 4
      Text = '9008'
    end
    object edtMyID: TEdit
      Left = 11
      Top = 192
      Width = 121
      Height = 21
      TabOrder = 5
    end
    object edtRemoteID: TEdit
      Left = 11
      Top = 248
      Width = 121
      Height = 21
      TabOrder = 6
    end
    object btnRequestConnect: TButton
      Left = 11
      Top = 275
      Width = 86
      Height = 25
      Caption = #35831#27714#36830#25509
      TabOrder = 7
      OnClick = btnRequestConnectClick
    end
  end
  object mmoLog: TMemo
    Left = 161
    Top = 0
    Width = 867
    Height = 563
    Align = alClient
    TabOrder = 1
  end
  object tmrSendTimer: TTimer
    OnTimer = tmrSendTimerTimer
    Left = 600
    Top = 72
  end
end
