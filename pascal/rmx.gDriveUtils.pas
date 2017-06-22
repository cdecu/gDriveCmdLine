unit rmx.gDriveUtils;

interface

Uses System.Classes, System.SysUtils, System.StrUtils, System.DateUtils,
  IPPeerClient, REST.Client, REST.Types, REST.Authenticator.OAuth, System.JSON, System.JSON.Types,
  rmx.Consts, rmx.JWT;

{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
{$M-}

Type
  TrmxGDriveUtils = Class
  private
    fJWT                : TJWT;
    fOAuth2Authenticator: TOAuth2Authenticator;
    fRESTClient         : TRESTClient;
    fRESTRequest        : TRESTRequest;
    fRESTResponse       : TRESTResponse;
    fSourceFileName     : String;
    fURI                : String;
    fOnProgress         : TrmxProgressMsg;
    fLastError          : String;
    ///<summary>Lasy create</summary>
    ///<remarks>see http://www.webdelphi.ru/2013/05/testirovanie-zaprosov-k-api-google-sredstvami-delphi-komponent-oauthclient-dlya-delphi-xe-xe3/</remarks>
    procedure Init;
    ///<summary>Lasy create</summary>
    ///<remarks>see http://www.webdelphi.ru/2013/05/testirovanie-zaprosov-k-api-google-sredstvami-delphi-komponent-oauthclient-dlya-delphi-xe-xe3/</remarks>
    function Authorize:Boolean;
    ///<summary>CallBack</summary>
    procedure AfterAuth(Sender: TCustomRESTRequest);
    ///<summary>CallBack</summary>
    procedure AfterTest(Sender: TCustomRESTRequest);
    ///<summary>CallBack</summary>
    procedure AfterExecute(Sender: TCustomRESTRequest);

  protected
    ///<summary>Raise LastError</summary>
    procedure RaiseLastError;
    ///<summary>Do Trace</summary>
    ///  just call OnProgress
    procedure DoTrace(Const Msg:String);

  public
    ///<summary>destructor</summary>
    destructor Destroy; override;

    ///<summary>Lasy create</summary>
    procedure Clear;
    ///<summary>Lasy create</summary>
    procedure Test;
    ///<summary>Upload FileName</summary>
    function Upload:Boolean;

    property URI           : String          read fURI            write fURI;
    property SourceFileName: String          read fSourceFileName write fSourceFileName;
    property OnProgress    : TrmxProgressMsg read fOnProgress     write fOnProgress;
    property LastError     : String          read fLastError;
  end;

implementation

uses rmx.URI, rmx.FileUtils;

Const private_key =
        '-----BEGIN PRIVATE KEY-----'#10+
        '-----END PRIVATE KEY-----'#10;

{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
destructor TrmxGDriveUtils.Destroy;
Begin
  FreeAndNil(fRESTResponse);
  FreeAndNil(fRESTRequest);
  FreeAndNil(fRESTClient);
  FreeAndNil(fOAuth2Authenticator);
  FreeAndNil(fJWT);
  inherited;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TrmxGDriveUtils.DoTrace(Const Msg:String);
Begin
  if Assigned(fOnProgress) then
    fOnProgress(Msg)
end;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.RaiseLastError;
begin
  if fLastError=EmptyStr then
    fLastError:='Internal Error';
  raise Exception.Create(fLastError);
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TrmxGDriveUtils.Clear;
Begin
  FreeAndNil(fRESTResponse);
  FreeAndNil(fRESTRequest);
  FreeAndNil(fRESTClient);
  FreeAndNil(fOAuth2Authenticator);
End;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.Init;
Begin
  if fOAuth2Authenticator=nil then Begin
    fOAuth2Authenticator := TOAuth2Authenticator.Create(nil);
    fOAuth2Authenticator.TokenType := TOAuth2TokenType.ttBEARER;
  end;

  if fRESTClient=nil then Begin
    fRESTClient:= TRESTClient.Create(nil);
    fRESTClient.Name           := 'RESTClient';
    fRESTClient.BaseURL        := 'https://www.googleapis.com/drive/v3';
    fRESTClient.HandleRedirects:= True;
  end;

  if fRESTRequest=nil then Begin
    fRESTRequest := TRESTRequest.Create(nil);
    fRESTRequest.Name        := 'RESTRequest';
  end;

  if fRESTResponse=nil then Begin
    fRESTResponse := TRESTResponse.Create(nil);
    fRESTResponse.Name       := 'RESTResponse';
  end;

  fRESTClient.Authenticator       := nil;
  fRESTRequest.Client             := fRESTClient;
  fRESTRequest.OnAfterExecute     := nil;
  fRESTRequest.SynchronizedEvents := False;
  fRESTRequest.Response           := fRESTResponse;
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.Authorize:Boolean;
Var JWTSigned:String;
Begin
  FreeAndNil(fJWT);fJWT:=TJWT.Create;

  // Set Header Google OAuth2 server uses RS256
  fJWT.Header.Alg:=TJOSEAlgorithmId.RS256;
  fJWT.Header.Typ:='JWT';

  // Set Payload
  fJWT.Payload.Issuer    :='ddddddd@pppppppppppppp.gserviceaccount.com';
  fJWT.Payload.Audience  :='https://accounts.google.com/o/oauth2/token';
  fJWT.Payload.IssuedAt  := now;
  fJWT.Payload.Expiration:= IncMinute(now,30);
  fJWT.Payload.Subject   :='xxxx@yyyyyy.zzz';
  fJWT.Payload.CustomKey['scope'] := 'https://www.googleapis.com/auth/drive.metadata.readonly';

  // Build JWT Header.Payload.Signature
  fJWT.Sign(private_key);

  // Build JWT Header.Payload.Signature
  JWTSigned:=fJWT.jwt;
  FreeAndNil(fJWT);

  // Build Request
  fRESTRequest.ClearBody;
  fRESTRequest.Params.Clear;
  fRESTRequest.Resource:= EmptyStr;
  fRESTRequest.Method  := rmPOST;
  fRESTRequest.AddParameter('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
  fRESTRequest.AddParameter('assertion' , JWTSigned);

  // Post JWT
  fRESTClient.Authenticator       := nil;
  fRESTRequest.SynchronizedEvents := True;
  fRESTRequest.OnAfterExecute     := Self.AfterAuth;
  fRESTClient.BaseURL:='https://accounts.google.com/o/oauth2/token';
  fOAuth2Authenticator.AccessToken:= EmptyStr;
  fLastError:= EmptyStr;
  fRESTRequest.Execute;
  if (fRESTRequest.Response.StatusCode=200) then Begin
    fRESTClient.Authenticator     := fOAuth2Authenticator;
    fRESTRequest.OnAfterExecute   := nil;
    Result:=True
  End else
    Result:=False
End;
procedure TrmxGDriveUtils.AfterAuth(Sender: TCustomRESTRequest);
Var JSONValue: TJsonValue;
  token:String;
begin
  if (fRESTRequest.Response.StatusCode = 200) then Begin
    JSONValue:=Sender.Response.JSONValue;
    if (JSONValue<>nil)and(JSONValue.TryGetValue<string>('access_token',token)) then Begin
//    DoTrace('++StatusCode:'+IntToStr(fRESTRequest.Response.StatusCode));
//    DoTrace(Sender.Response.JSONText);
      fOAuth2Authenticator.AccessToken:= token;
    End else Begin
      DoTrace('**StatusCode:'+IntToStr(fRESTRequest.Response.StatusCode));
      fRESTRequest.Response.StatusCode:=201;
      DoTrace(Sender.Response.StatusText);
      DoTrace(Sender.Response.Content);
      fLastError:=Sender.Response.Content;
    end;
  End else Begin
    DoTrace('**StatusCode:'+IntToStr(fRESTRequest.Response.StatusCode));
    DoTrace(Sender.Response.StatusText);
    DoTrace(Sender.Response.Content);
    fLastError:=Sender.Response.StatusText;
  end;
end;
{______________________________________________________________________________}
function TrmxGDriveUtils.Upload:Boolean;
Var Proto,User,Pwd,Host,Port,Path:String;
  metadata,data:TRESTRequestParameter;
  LStream:TFileStream;
  LBytes: TBytes;
Begin
  Self.Init;
  if not Self.Authorize then Begin
    Exit(False);
  End;

  rmx.URI.ParseURI(fURI,Proto,User,Pwd,Host,Port,Path);
  if not SameText(Proto,'gDrive') then Begin
    fLastError:=Format('Invalid gDrive URI <%s>',[fURI]);
    Exit(False);
  End;

  DoTrace('..Upload to gDrive:'+fURI);
  fRESTClient.BaseURL:='https://www.googleapis.com/upload/drive/v3/';

  fRESTRequest.ClearBody;
  fRESTRequest.Params.Clear;
  fRESTRequest.Resource:='files';
  fRESTRequest.Method  := rmPOST;
  fRESTRequest.Params.AddUrlSegment('uploadType','multipart');

  metadata:=fRESTRequest.Params.AddItem;
  metadata.ContentType:=ctAPPLICATION_JSON;
  metadata.Kind       :=pkREQUESTBODY;
  metadata.name       :='metadata';
  metadata.Value      :='{"name": "+ExtractFileName(fSourceFileName)+"}';

  LStream := TFileStream.Create(fSourceFileName, 0);
  try SetLength(LBytes, LStream.Size);
    LStream.Seek(0, TSeekOrigin.soBeginning);
    LStream.Read(LBytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;

  data:=fRESTRequest.Params.AddItem('data',LBytes,pkREQUESTBODY,[],ctAPPLICATION_OCTET_STREAM);
  SetLength(LBytes, 0);

  fRESTRequest.OnAfterExecute    := Self.AfterExecute;
  fRESTRequest.SynchronizedEvents:=True;
  fRESTRequest.Execute;
  Result:=True;
end;
procedure TrmxGDriveUtils.AfterExecute(Sender: TCustomRESTRequest);
begin
  DoTrace(Sender.Response.JSONText);
end;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.Test;
Var metadata:TRESTRequestParameter;
begin
  Self.Init;
  if not Self.Authorize then Begin
    RaiseLastError;
  End;

  DoTrace('..Test gDrive files');
  fRESTClient.BaseURL:='https://www.googleapis.com/drive/v3/files';

  fRESTRequest.ClearBody;
  fRESTRequest.Params.Clear;
  fRESTRequest.Resource:='';
  fRESTRequest.Method  := rmGET;
  fRESTRequest.OnAfterExecute      := Self.AfterTest;
  fRESTRequest.SynchronizedEvents  := True;
  fRESTRequest.Execute;
end;
procedure TrmxGDriveUtils.AfterTest(Sender: TCustomRESTRequest);
begin
  DoTrace(Sender.Response.JSONText);
end;

end.
