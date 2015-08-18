object MainForm: TMainForm
  Left = 192
  Top = 114
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'P2P UDP Demo(Client)'
  ClientHeight = 338
  ClientWidth = 458
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 12
  object Gauge1: TGauge
    Left = 8
    Top = 312
    Width = 396
    Height = 20
    ForeColor = clGreen
    Progress = 0
  end
  object Label4: TLabel
    Left = 272
    Top = 8
    Width = 174
    Height = 12
    Caption = #22312#32447#21517#21333#65292#21333#20987#19982#20854#24314#31435'P2P'#36830#25509
  end
  object Label5: TLabel
    Left = 408
    Top = 312
    Width = 6
    Height = 12
  end
  object Label6: TLabel
    Left = 408
    Top = 168
    Width = 36
    Height = 36
    Caption = #19981#26174#31034#13#20002#21253#37325#13#21457#20449#24687
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 257
    Height = 97
    Caption = #36830#25509#26381#21153#22120#35774#32622
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 36
      Height = 12
      Caption = 'IP'#22320#22336
    end
    object Label2: TLabel
      Left = 16
      Top = 40
      Width = 24
      Height = 12
      Caption = #31471#21475
    end
    object Label3: TLabel
      Left = 16
      Top = 64
      Width = 36
      Height = 12
      Caption = #30331#24405#21517
    end
    object EdtIP: TEdit
      Left = 80
      Top = 16
      Width = 121
      Height = 20
      TabOrder = 0
    end
    object EdtPort: TEdit
      Left = 80
      Top = 40
      Width = 121
      Height = 20
      TabOrder = 1
    end
    object EdtName: TEdit
      Left = 80
      Top = 64
      Width = 121
      Height = 20
      TabOrder = 2
    end
    object btnConnect: TButton
      Left = 208
      Top = 64
      Width = 43
      Height = 20
      Caption = #30331#24405
      TabOrder = 3
      OnClick = btnConnectClick
    end
  end
  object ListBox1: TListBox
    Left = 272
    Top = 24
    Width = 177
    Height = 81
    ItemHeight = 12
    TabOrder = 1
    OnClick = ListBox1Click
  end
  object EdtMessage: TEdit
    Left = 8
    Top = 264
    Width = 393
    Height = 20
    TabOrder = 2
    OnKeyPress = EdtMessageKeyPress
  end
  object btnSend: TButton
    Left = 408
    Top = 264
    Width = 41
    Height = 20
    Caption = #21457#36865
    TabOrder = 3
    OnClick = btnSendClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 112
    Width = 393
    Height = 145
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object EdtFile: TEdit
    Left = 8
    Top = 288
    Width = 369
    Height = 20
    Enabled = False
    TabOrder = 5
  end
  object btnBrowse: TButton
    Left = 384
    Top = 288
    Width = 20
    Height = 20
    Caption = '..'
    TabOrder = 6
    OnClick = btnBrowseClick
  end
  object btnSendFile: TButton
    Left = 408
    Top = 288
    Width = 41
    Height = 20
    Caption = #21457#36865
    TabOrder = 7
    OnClick = btnSendFileClick
  end
  object btnClear: TButton
    Left = 408
    Top = 238
    Width = 41
    Height = 20
    Caption = #28165#31354
    TabOrder = 8
    OnClick = btnClearClick
  end
  object btnRefresh: TButton
    Left = 408
    Top = 112
    Width = 43
    Height = 20
    Caption = #21047#26032
    TabOrder = 9
    OnClick = btnRefreshClick
  end
  object CheckBox1: TCheckBox
    Left = 408
    Top = 152
    Width = 49
    Height = 17
    TabOrder = 10
  end
  object TimerMakeHole: TTimer
    Enabled = False
    OnTimer = TimerMakeHoleTimer
    Left = 320
    Top = 136
  end
  object OpenDialog1: TOpenDialog
    Left = 320
    Top = 168
  end
  object SaveDialog1: TSaveDialog
    Left = 288
    Top = 168
  end
  object TimerKeepOnline: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = TimerKeepOnlineTimer
    Left = 288
    Top = 136
  end
end
