unit ufrmP2P;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrmP2P = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmP2P: TfrmP2P;

procedure CreateP2PForm(pvRemoteID:Integer);

implementation

{$R *.dfm}

procedure CreateP2PForm(pvRemoteID:Integer);
begin
  with TfrmP2P.Create(Application) do
  begin
    Show();
  end;
end;

end.
