# Test JWT server to server google drive API access.


## Create service account in [Cloud Platform Console](https://console.cloud.google.com)
- [see Using OAuth 2.0 for Server to Server Applications](https://developers.google.com/identity/protocols/OAuth2ServiceAccount)
- Save the privated key generated

 

## Allow impersonation in [Admin Console](https://admin.google.com)
[see ManageOauthClients](https://admin.google.com/rmxgcp.com/AdminHome?chromeless=1#OGX:ManageOauthClients)


## Check google-api [git repo](https://github.com/google/google-api-nodejs-client)
read/test/play with samples ...

## Read The Fucking Doc
- [Google Drive API](https://developers.google.com/drive/v3/reference/)

## Start new node project
- npm i google-auth-library
- npm i googleapis


## Start new pascal project
- jwt.pas
- simpleRESClient.pas Simple RESClient Indy based
- gDriveUtils.pas
- sample console projet
```pascal
{$APPTYPE CONSOLE}
Var GDrive:TrmxGDriveUtils;
begin
  ReportMemoryLeaksOnShutdown:=True;
  GDrive:=TrmxGDriveUtils.Create;
  try GDrive.OnProgress:=procedure (Const aMsg:String) Begin Writeln(aMsg); end;
      GDrive.Test;

  except on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
```