unit ntrip.handler;

interface

uses
  diocp.ex.ntrip, Classes, SysUtils;

procedure ResponseSourceTableAndOK(pvRequest: TDiocpNTripRequest);

procedure ReloadSourceTable;

var
  __NMEAHost:String;
  __NMEAPort:Integer;

implementation

var
  __sourceTable:String;  // ≤‚ ‘ ˝æ›

procedure ReloadSourceTable;
var
  lvLoader:TStringList;
begin
  lvLoader := TStringList.Create();
  try
    lvLoader.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'sourceTable.txt');
    __sourceTable := lvLoader.Text;
    if __sourceTable = '' then
    begin
      __sourceTable :=
         'STR;ABMF0;Les-Abymes;RTCM 3.1;1004(1),1012(1),1006(10),1008(10),1013(10),1033(10),1019(30),1020(30);2;GPS+GLO;IGS;GLP;16.27;-61.52;1;0;TRIMBLE NETR9;none;B;N;2400;rgp-ip.ign.fr:2101/ABMF1(1)' +
          sLineBreak +
         'STR;ADIS0;Addis_Ababa;RTCM 3.0;1004(1),1006(10),1007(10),1019,1020;2;GPS+GLO;IGS;ETH;9.03;38.74;1;0;JPS LEGACY;none;B;N;1300;Adis Ababa University';    end;
  finally
    lvLoader.Free;
  end;

end;

procedure ResponseSourceTableAndOK(pvRequest: TDiocpNTripRequest);
var
  lvSourceTable:AnsiString;
begin
//  lvSourceTable :=
//     'STR;ABMF0;Les-Abymes;RTCM 3.1;1004(1),1012(1),1006(10),1008(10),1013(10),1033(10),1019(30),1020(30);2;GPS+GLO;IGS;GLP;16.27;-61.52;1;0;TRIMBLE NETR9;none;B;N;2400;rgp-ip.ign.fr:2101/ABMF1(1)' +
//      sLineBreak +
//     'STR;ADIS0;Addis_Ababa;RTCM 3.0;1004(1),1006(10),1007(10),1019,1020;2;GPS+GLO;IGS;ETH;9.03;38.74;1;0;JPS LEGACY;none;B;N;1300;Adis Ababa University';  lvSourceTalbe := __sourceTable;
  pvRequest.Response.SourceTableOKAndData(lvSourceTable);end;



end.
