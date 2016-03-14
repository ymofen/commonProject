object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 460
  ClientWidth = 929
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
    Width = 929
    Height = 65
    Align = alTop
    Caption = 'pnlTop'
    TabOrder = 0
    object btnParseJSON: TButton
      Left = 0
      Top = 21
      Width = 75
      Height = 25
      Caption = 'btnParseJSON'
      TabOrder = 0
      OnClick = btnParseJSONClick
    end
    object btnEncodeJSON: TButton
      Left = 120
      Top = 21
      Width = 75
      Height = 25
      Caption = 'btnEncodeJSON'
      TabOrder = 1
      OnClick = btnEncodeJSONClick
    end
    object btnClear: TButton
      Left = 256
      Top = 21
      Width = 75
      Height = 25
      Caption = 'btnClear'
      TabOrder = 2
      OnClick = btnClearClick
    end
  end
  object mmoData: TMemo
    Left = 0
    Top = 65
    Width = 929
    Height = 395
    Align = alClient
    Lines.Strings = (
      '{'
      '  "AccountList":                                       //'#24080#22871#21015#34920
      '  {'
      '   "AccountGroup":                                  //'#24080#22871#20998#32452
      '    ['
      '      {'
      
        '        "Id":1,                                      //'#20998#32452'ID('#20174'1'#24320#22987 +
        ')'
      '        "Name":"'#26131#26539#21697#29260#24080#22871'",                       //'#20998#32452#21517#31216' '
      '        "AccountConfig":                             //'#24080#22871#37197#32622
      '         [ '
      '            {'
      '              "OnlyCode":10001,                    //'#21807#19968#30721
      '              "DbConfig":'
      '               {'
      
        '                   "main":"Yr_Sale",                //'#20027#25968#25454#24211#37197#32622'ID('#25968 +
        #25454#24211#22788#29702#26381#21153#22120#25968#25454#28304'ID) '
      
        '                 "sys":"Yr_sys"                   //'#31995#32479#25454#24211#37197#32622'ID('#25968#25454#24211 +
        #22788#29702#26381#21153#22120#25968#25454#28304'ID) '
      '               }  // end DbConfig'
      '            },'#9'// end AccountConfig-1'#9#9#9'  '
      '            {'
      '              "OnlyCode":10002,                    //'#21807#19968#30721
      '            },  // end AccountConfig-2 '
      '          ],  // end AccountConfig'
      '      }, // end array 1'
      
        '      //---------------------------------------'#31532#20108#20010#24179#34892#24080#22871'----------' +
        '-----------------------------------'
      '      {'
      
        '        "Id":2,                                      //'#20998#32452'ID('#20174'1'#24320#22987 +
        ')'
      '        "Name":"'#24935#21451#21697#29260#24080#22871'",                       //'#20998#32452#21517#31216' '
      '      },'
      '    ]'
      '  }'
      '}')
    TabOrder = 1
  end
end
