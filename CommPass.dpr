program CommPass;

uses
  Forms,
  UCommPass in 'UCommPass.pas' {FCP};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFCP, FCP);
  Application.Run;
end.
