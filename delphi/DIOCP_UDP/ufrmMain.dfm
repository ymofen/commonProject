object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'DIOCP_UDP'
  ClientHeight = 595
  ClientWidth = 1035
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 161
    Height = 595
    Align = alLeft
    BevelKind = bkTile
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 72
      Height = 13
      Caption = #26412#22320#20390#21548#31471#21475
    end
    object btnStart: TButton
      Left = 8
      Top = 62
      Width = 75
      Height = 25
      Caption = #24320#22987#20390#21548
      TabOrder = 0
      OnClick = btnStartClick
    end
    object edtPort: TEdit
      Left = 8
      Top = 35
      Width = 121
      Height = 21
      TabOrder = 1
      Text = '9984'
    end
    object btnAbout: TButton
      Left = 8
      Top = 560
      Width = 75
      Height = 25
      Caption = #20851#20110
      TabOrder = 2
      OnClick = btnAboutClick
    end
  end
  object pnlClient: TPanel
    Left = 161
    Top = 0
    Width = 874
    Height = 595
    Align = alClient
    BevelKind = bkTile
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 0
      Top = 209
      Width = 870
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 281
      ExplicitWidth = 314
    end
    object pnlRecvPanel: TPanel
      Left = 0
      Top = 212
      Width = 870
      Height = 379
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object pnlRecvTop: TPanel
        Left = 0
        Top = 0
        Width = 870
        Height = 64
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object chkStringOut: TCheckBox
          Left = 20
          Top = 10
          Width = 97
          Height = 17
          Caption = #25991#26412#26041#24335#36755#20986
          Checked = True
          State = cbChecked
          TabOrder = 0
          OnClick = chkStringOutClick
        end
        object chkEcho: TCheckBox
          Left = 272
          Top = 12
          Width = 195
          Height = 17
          Caption = #25910#21040#21518#31435#21363#36820#22238#32473#23545#26041
          TabOrder = 1
          OnClick = chkEchoClick
        end
        object chkOutTime: TCheckBox
          Left = 132
          Top = 33
          Width = 97
          Height = 17
          Caption = #36755#20986#25509#25910#26102#38388
          Checked = True
          State = cbChecked
          TabOrder = 2
          OnClick = chkOutTimeClick
        end
        object chkWordWrap: TCheckBox
          Left = 132
          Top = 10
          Width = 97
          Height = 17
          Caption = #26029#34892#26174#31034
          Checked = True
          State = cbChecked
          TabOrder = 3
          OnClick = chkWordWrapClick
        end
        object btnClear: TButton
          Left = 440
          Top = 9
          Width = 75
          Height = 25
          Caption = #28165#31354
          TabOrder = 4
          OnClick = btnClearClick
        end
        object chkHexOut: TCheckBox
          Left = 20
          Top = 33
          Width = 97
          Height = 17
          Caption = '16'#36827#21046#26174#31034
          TabOrder = 5
          OnClick = chkHexOutClick
        end
      end
      object mmoRecv: TMemo
        Left = 0
        Top = 64
        Width = 870
        Height = 315
        Align = alClient
        TabOrder = 1
      end
    end
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 870
      Height = 209
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object PageControl1: TPageControl
        Left = 0
        Top = 0
        Width = 870
        Height = 209
        ActivePage = tsSendPage01
        Align = alClient
        TabOrder = 0
        object tsSendPage01: TTabSheet
          Caption = #21457#36865#20027#39029#38754
          object pnlSendTop: TPanel
            Left = 0
            Top = 0
            Width = 862
            Height = 50
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object edtRemoteIP: TEdit
              Left = 16
              Top = 11
              Width = 121
              Height = 21
              TabOrder = 0
              Text = '127.0.0.1'
            end
            object edtRemotPort: TEdit
              Left = 160
              Top = 11
              Width = 65
              Height = 21
              TabOrder = 1
              Text = '9984'
            end
            object btnSend: TButton
              Left = 240
              Top = 9
              Width = 75
              Height = 25
              Caption = #31435#21363#21457#36865
              TabOrder = 2
              OnClick = btnSendClick
            end
            object edtSendInterval: TEdit
              Left = 479
              Top = 11
              Width = 58
              Height = 21
              TabOrder = 3
              Text = '1000'
            end
            object chkSendTimer: TCheckBox
              Left = 352
              Top = 13
              Width = 121
              Height = 17
              Caption = #24320#21551#23450#26102#21457#36865'(ms)'
              TabOrder = 4
              OnClick = chkSendTimerClick
            end
          end
          object mmoSend: TMemo
            Left = 0
            Top = 50
            Width = 862
            Height = 131
            Align = alClient
            Lines.Strings = (
              #35201#21457#36865#30340#20869#23481)
            TabOrder = 1
          end
        end
        object tsSendPage02: TTabSheet
          Caption = #38468#21152#21457#36865#39029#38754
          ImageIndex = 1
          object mmoSend_02: TMemo
            Left = 0
            Top = 50
            Width = 862
            Height = 131
            Align = alClient
            Lines.Strings = (
              #35201#21457#36865#30340#20869#23481)
            TabOrder = 0
          end
          object Panel2: TPanel
            Left = 0
            Top = 0
            Width = 862
            Height = 50
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 1
            object edtRemoteIP_02: TEdit
              Left = 16
              Top = 11
              Width = 121
              Height = 21
              TabOrder = 0
              Text = '127.0.0.1'
            end
            object edtRemotePort_02: TEdit
              Left = 160
              Top = 11
              Width = 65
              Height = 21
              TabOrder = 1
              Text = '9984'
            end
            object btnSend_02: TButton
              Left = 240
              Top = 9
              Width = 75
              Height = 25
              Caption = #31435#21363#21457#36865
              TabOrder = 2
              OnClick = btnSend_02Click
            end
            object edtSendInterval_02: TEdit
              Left = 479
              Top = 11
              Width = 58
              Height = 21
              TabOrder = 3
              Text = '1000'
            end
            object chkSendTimer_02: TCheckBox
              Left = 352
              Top = 13
              Width = 121
              Height = 17
              Caption = #24320#21551#23450#26102#21457#36865'(ms)'
              TabOrder = 4
              OnClick = chkSendTimer_02Click
            end
          end
        end
      end
    end
  end
  object tmrSendTimer: TTimer
    Enabled = False
    OnTimer = tmrSendTimerTimer
    Left = 192
    Top = 120
  end
  object tmrSendTimer_02: TTimer
    Enabled = False
    OnTimer = tmrSendTimer_02Timer
    Left = 232
    Top = 120
  end
end
