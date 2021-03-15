object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Simple HTTP Server'
  ClientHeight = 107
  ClientWidth = 277
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 24
    Width = 20
    Height = 13
    Caption = 'Port'
  end
  object ePort: TEdit
    Left = 88
    Top = 21
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '9000'
  end
  object btnStart: TButton
    Left = 88
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 1
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 169
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 2
    OnClick = btnStopClick
  end
end
