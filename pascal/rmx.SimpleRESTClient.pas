//******************************************************************************
// By carlos@decumont.be , Inspired from lot of sources
// see https://github.com/jamiei/SimpleRestClient
// see Latest Delphi REST framework
//******************************************************************************
// Licensed under the BSD-3 Open source license.
//******************************************************************************
// test with https://httpbin.org/
// test with curl
//******************************************************************************
unit rmx.SimpleRESTClient;

interface

Uses System.Classes, System.SysUtils, SuperObject,
  IdHttp, IdAuthentication, IdMultipartFormData, IdURI, IdSSL, IdSSLOpenSSLHeaders, IdSSLOpenSSL,
  rmx.Consts, rmx.MimeTypes;

Type
  THttpRestResponse = class;
  THttpRestRequest = class;

  /// <summary>Designates standard HTTP/REST Methods. All methods may affect single or multiple objects/entities.</summary>
  /// <remarks>See http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html</remarks>
  THTTPRequestMethod = (
    /// <summary>
    /// Sends a NEW object/entity to the server.
    /// </summary>
    rmPOST,

    /// <summary>Updates an already existing object/entity on the server. PUT may also allow for sending a new entity (depends on the actual server/API implementation).</summary>
    rmPUT,

    /// <summary>Retrieves an object/entity from the server.</summary>
    rmGET,

    /// <summary>Deletes an object/entity from the server.</summary>
    rmDELETE,
      /// <summary>Patches an object/entity on the server, by only updating the pairs that are sent within that PATCH body.</summary>
    rmPATCH,
      /// <summary>Options ?</summary>
    rmOptions,
      /// <summary>Trace ?</summary>
    rmTrace
    );

  /// <summary>Http ResponseCode/ResponseStr</summary>
  THttpRestResponse = class(TObject)
  private
    ///	<summary>The Http Response code returned</summary>
    fResponseCode : integer;

    ///	<summary>The Body returned or an exception message.</summary>
    fResponseStr  : string;

    function GetResponseOK: Boolean;

  public
    property ResponseOK   : Boolean                 read GetResponseOK;
    property ResponseCode : integer                 read fResponseCode;
    property ResponseStr  : String                  read fResponseStr;
  end;

  THttpRestBeforeRequest= procedure(Const aRestRequest: THttpRestRequest) of Object;
  THttpRestAfterRequest = procedure(Const aRestRequest: THttpRestRequest) of Object;
  THttpRestAfterError   = procedure(Const aRestRequest: THttpRestRequest) of Object;

  /// <summary>Http Request Builder and Runner</summary>
  THttpRestRequest = class(TObject)
  protected
    fScheme         : string;
    fDomain         : string;
    fPaths          : TStringList;
    fHeaders        : TStringList;
    fQueryParams    : TStringList;
    fTxtParams      : TStringList;
    fSinglePart     : TStringStream;
    fSinglePartType : String;
    fMultiParts     : TIdMultiPartFormDataStream;

    fResponse       : THttpRestResponse;
    fUserAgent      : String;
    fConnection     : String;
    fAccept         : string;
    fAcceptCharSet  : String;
    fAcceptEncoding : String;
    fAcceptLanguage : String;
    fBeforeRequest  : THttpRestBeforeRequest;
    fAfterRequest   : THttpRestAfterRequest;
    fAfterError     : THttpRestAfterError;
    fOnProgress     : TrmxProgressMsg;
    fConnectTimeout : Integer;
    fReadTimeout    : Integer;

    fSslHandler     : TIdSSLIOHandlerSocketOpenSSL;
    fStrBuilder     : TStringBuilder;
    fHttpClient     : TIdHttp;
    fDataStream     : TStream;
    fMethod         : THTTPRequestMethod;

    function getURLAsStr: string;
    function urlEncode(Const Value: string): string;

  protected
    procedure CreateHttpClient;
    procedure CreateDataStream;
    procedure doBeforeRequest;
    procedure doAfterRequest;
    procedure doAfterError;
    procedure doTrace(Const Msg:String);

  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    procedure Clear;

    function Scheme(Const aScheme: string): THttpRestRequest;
    function Domain(Const aDomain: string): THttpRestRequest;
    function Path(Const aPath: string): THttpRestRequest;
    function QueryParam(Const aKey: string): THttpRestRequest;overload;
    function QueryParam(Const aKey: string;Const aValue: string): THttpRestRequest;overload;
    function QueryParam(Const aKey: string;Const aValue: Boolean): THttpRestRequest;overload;
    function QueryParamIf(Const aCondition:string;Const aKey: string;Const aValue: string): THttpRestRequest;overload;
    function QueryParamIf(Const aCondition:Boolean;Const aKey: string;Const aValue: string): THttpRestRequest;overload;
    function WithHeader(Const aName: string;Const aValue: string): THttpRestRequest;

    function TextParam(Const aKey: string;Const aValue: string): THttpRestRequest;

    function AddSinglePartJSON(const AFieldName: String; AFieldValue: ISuperObject; const AFileName: string = ''): THttpRestRequest;overload;

    function AddMultiPartFormField(const AFieldName, AFieldValue: string; const ACharset: string = ''; const AContentType: TrmxMimeType = ctNone; const AFileName: string = ''): THttpRestRequest;overload;
    function AddMultiPartJSON(const AFieldName: String; AFieldValue: ISuperObject; const AFileName: string = ''): THttpRestRequest;overload;
    function AddMultiPartFile(const AFieldName, AFileName: String; const AContentType: TrmxMimeType = ctNone): THttpRestRequest;overload;

    function Method(Const aMethod:THTTPRequestMethod): THttpRestRequest;

    function Execute: THttpRestResponse;overload;
    function Execute(Const aMethod:THTTPRequestMethod): THttpRestResponse;overload;

    property FullUrl        : string                  read getURLAsStr;
    property UserAgent      : string                  read fUserAgent      write fUserAgent;
    property Connection     : string                  read fConnection     write fConnection;
    property Accept         : string                  read fAccept         write fAccept;
    property AcceptCharSet  : String                  read FAcceptCharSet  write FAcceptCharSet;
    property AcceptEncoding : String                  read FAcceptEncoding write FAcceptEncoding;
    property AcceptLanguage : String                  read FAcceptLanguage write FAcceptLanguage;

    property ConnectTimeout : Integer                 read fConnectTimeout write fConnectTimeout default 5000;
    property ReadTimeout    : Integer                 read fReadTimeout    write fReadTimeout    default 5000;
    property BeforeRequest  : THttpRestBeforeRequest  read fBeforeRequest  write fBeforeRequest;
    property AfterRequest   : THttpRestAfterRequest   read fAfterRequest   write fAfterRequest;
    property AfterError     : THttpRestAfterError     read fAfterError     write fAfterError;
    property OnProgress     : TrmxProgressMsg         read fOnProgress     write fOnProgress;

    property Response       : THttpRestResponse       read FResponse;
  end;


implementation

{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function THttpRestResponse.GetResponseOK: Boolean;
Var LResponseDigit: Integer;
begin
  LResponseDigit := fResponseCode div 100;
  result:=(LResponseDigit=2)
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
constructor THttpRestRequest.Create;
begin
  inherited Create;
  FHeaders    := TStringList.Create;
  FPaths      := TStringList.Create;
  fQueryParams:= TStringList.Create;
  fTxtParams  := TStringList.Create;
  fResponse   := THttpRestResponse.Create;

  fConnectTimeout := 5000;
  fReadTimeout    := 5000;
end;
destructor THttpRestRequest.Destroy;
begin
  fHttpClient.Free;
  fDataStream.Free;
  fStrBuilder.Free;
  FSslHandler.Free;

  fResponse.Free;

  fTxtParams.Free;
  fSinglePart.Free;
  fMultiParts.Free;

  fQueryParams.Free;
  FPaths.Free;
  FHeaders.Free;

  inherited;
end;
{______________________________________________________________________________}
procedure THttpRestRequest.Clear;
Begin
  FreeAndNil(fHttpClient);
  FreeAndNil(fDataStream);

  if fPaths<>nil then
    fPaths.Clear;

  if fHeaders<>nil then
    fHeaders.Clear;

  if fQueryParams<>nil then
    fQueryParams.Clear;

  FreeAndNil(fSinglePart);
  FreeAndNil(fMultiParts);
  if fTxtParams<>nil then
    fTxtParams.Clear;

  if fStrBuilder<>nil then
    fStrBuilder.Clear;

  fResponse.fResponseCode:=0;
  fResponse.fResponseStr:=EmptyStr;
End;
{______________________________________________________________________________}
function THttpRestRequest.urlEncode(Const Value: string): string;
Const super_hex_chars = '0123456789abcdef';
Var i,l:Integer;
    c:Char;
begin
  if fStrBuilder=nil then
    fStrBuilder:=TStringBuilder.Create;
  fStrBuilder.Clear;

  l:=Value.Length;
  for i:=0 to Pred(l) do Begin
    c:=Value.Chars[i];
    if not CharInSet(c,['A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_', '.', '~']) then Begin
      fStrBuilder.Append('%'+IntToHex(Ord(c), 2));
    End else
      fStrBuilder.Append(c);
    end;

  Result:=fStrBuilder.ToString
end;
{______________________________________________________________________________}
function THttpRestRequest.getURLAsStr: string;
var fp,p,pKey,pVal: string;
  i: integer;
begin
  for i := 0 to Self.FPaths.Count - 1 do begin
    fp := fp + '/' + Self.FPaths.Strings[i];
    end;

  if Self.fQueryParams.Count > 0 then begin
    p := '?';
    for i := 0 to Self.fQueryParams.Count - 1 do begin
      if i > 0 then
        p := p + '&';
      pKey:=Self.fQueryParams.Names[i];
      if pKey<>EmptyStr then Begin
        pVal:=Self.fQueryParams.ValueFromIndex[i];
        if pVal<>Emptystr then
          p := p + urlEncode(pKey) + '=' + urlEncode(pVal) else
          p := p + urlEncode(pKey)
      End else
        p := p + urlEncode(fQueryParams[i])
    end end;

  if FScheme=EmptyStr then
     Result :='https://' else
     Result := FScheme + '://';

  Result := Result + FDomain + fp + p;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function THttpRestRequest.Scheme(Const aScheme: string): THttpRestRequest;
begin
  Self.FScheme := Trim(aScheme);
  Result := Self;
end;
function THttpRestRequest.Domain(Const aDomain: string): THttpRestRequest;
begin
  Self.FDomain := Trim(aDomain);
  Result := Self;
end;
function THttpRestRequest.Path(Const aPath: string): THttpRestRequest;
begin
  Self.FPaths.Append(aPath);
  Result := Self;
end;
function THttpRestRequest.WithHeader(Const aName, aValue: string): THttpRestRequest;
begin
  Self.FHeaders.Add(aName + '=' + aValue);
  Result := Self;
end;
function THttpRestRequest.QueryParam(Const aKey: string): THttpRestRequest;
begin
  Self.fQueryParams.Add(aKey);
  Result := Self;
end;
function THttpRestRequest.QueryParam(Const aKey, aValue: string): THttpRestRequest;
begin
  Self.fQueryParams.Add(aKey + '=' + aValue);
  Result := Self;
end;
function THttpRestRequest.QueryParam(Const aKey: string;Const aValue: Boolean): THttpRestRequest;
begin
  if aValue then
    Self.fQueryParams.Add(aKey + '=true') else
    Self.fQueryParams.Add(aKey + '=false');
  Result := Self;
end;
function THttpRestRequest.QueryParamIf(Const aCondition:string;Const aKey, aValue: string): THttpRestRequest;
begin
  if aCondition<>EmptyStr then
    Self.fQueryParams.Add(aKey + '=' + aValue);
  Result := Self;
end;
function THttpRestRequest.QueryParamIf(Const aCondition:Boolean;Const aKey, aValue: string): THttpRestRequest;
begin
  if aCondition then
    Self.fQueryParams.Add(aKey + '=' + aValue);
  Result := Self;
end;
function THttpRestRequest.Method(Const aMethod:THTTPRequestMethod): THttpRestRequest;
Begin
  fMethod:=aMethod;
  Result := Self;
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function THttpRestRequest.TextParam(Const aKey, aValue: string): THttpRestRequest;
begin
  Self.fTxtParams.Add(aKey + '=' + aValue);
  Result := Self;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function THttpRestRequest.AddSinglePartJSON(const AFieldName: String; AFieldValue: ISuperObject; const AFileName: string = ''): THttpRestRequest;
begin
  FreeAndNil(fSinglePart);
  fSinglePart:=TStringStream.Create(AFieldValue.AsJSon,TEncoding.UTF8);
  fSinglePartType := MimeType2Str(ctAPPLICATION_JSON)+'; charset=utf-8';
  Result := Self;
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function THttpRestRequest.AddMultiPartFormField(const AFieldName, AFieldValue: string; const ACharset: string = ''; const AContentType: TrmxMimeType = ctNone; const AFileName: string = ''): THttpRestRequest;
Var f:TIdFormDataField;
begin
  if fMultiParts=nil then
    fMultiParts:=TIdMultiPartFormDataStream.Create;
  f:=fMultiParts.AddFormField(AFieldName,AFieldValue,ACharset,'',aFileName);
  if AContentType<>ctNone then
    f.ContentType:=MimeType2Str(AContentType);
  Result := Self;
end;
function THttpRestRequest.AddMultiPartJSON(const AFieldName: String; AFieldValue: ISuperObject; const AFileName: string = ''): THttpRestRequest;
Var f:TIdFormDataField;
begin
  if fMultiParts=nil then
    fMultiParts:=TIdMultiPartFormDataStream.Create;
  f:=fMultiParts.AddFormField(AFieldName,AFieldValue.AsJSon,'','',aFileName);
  f.ContentType:=MimeType2Str(ctAPPLICATION_JSON);
  f.ContentTransfer := sContentTransferBinary;
  f.Charset:= 'UTF-8';
  Result := Self;
End;
function THttpRestRequest.AddMultiPartFile(const AFieldName, AFileName: String; Const AContentType: TrmxMimeType = ctNone): THttpRestRequest;
Var f:TIdFormDataField;
    mt:String;
begin
  if fMultiParts=nil then
    fMultiParts:=TIdMultiPartFormDataStream.Create;
  f:=fMultiParts.AddFile(AFieldName,aFileName,'');
  if AContentType=ctNone then Begin
    if LoadMimeType(aFileName,mt) Then
      f.ContentType:=mt;
  End else
    f.ContentType:=MimeType2Str(AContentType);
  Result := Self;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure THttpRestRequest.CreateHttpClient;
begin
  FreeAndNil(fHttpClient);
  FreeAndNil(fDataStream);

  fHttpClient := TIdHttp.Create(nil);
  fHttpClient.ConnectTimeout  := fConnectTimeout;
  fHttpClient.ReadTimeout     := fReadTimeout;
  fHttpClient.HTTPOptions     := [hoWaitForUnexpectedData,hoWantProtocolErrorContent, hoNoProtocolErrorException];
  fHttpClient.HandleRedirects := True;

  // Create an SSL Handler if we need to.
  if (fScheme=EmptyStr)or(SameText(fScheme,'https')) then Begin
    if Self.FSslHandler<>nil then
      Self.FSslHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    fHttpClient.IOHandler := FSslHandler;
  End else
    fHttpClient.IOHandler := nil;

  fHttpClient.Request.UserAgent           := fUserAgent;
  fHttpClient.Request.Connection          := fConnection;

  if (Self.FHeaders=nil)or(Self.FHeaders.Count=0) then Begin
    // Add some default Headers ?
  End else
    fHttpClient.Request.CustomHeaders.AddStrings(Self.FHeaders);

  if fAccept=EmptyStr then
    fHttpClient.Request.Accept            :='*/*' else
    fHttpClient.Request.Accept            := fAccept;
  fHttpClient.Request.AcceptCharSet       := fAcceptCharSet;//'UTF-8';
  fHttpClient.Request.AcceptEncoding      := fAcceptEncoding;//'gzip, deflate';
  fHttpClient.Request.AcceptLanguage      := fAcceptLanguage;
end;
{______________________________________________________________________________}
procedure THttpRestRequest.CreateDataStream;
var StreamStream:TStringStream;
    key, value: string;
    strParam: string;
    i: Integer;
Begin
  FreeAndNil(fDataStream);

  if not (fMethod in [rmPOST,rmPUT,rmPATCH]) Then Begin
    Assert((fTxtParams=nil)or(fTxtParams.Count=0));
    Assert(fSinglePart=nil);
    Assert(fMultiParts=nil);
    Exit;
    end;

  if (fMultiParts<>nil) then begin
    fHttpClient.Request.ContentType := fMultiParts.RequestContentType;
    Assert((fTxtParams=nil)or(fTxtParams.Count=0));
    Assert(fSinglePart=nil);
    fDataStream:=fMultiParts;
    fMultiParts:=nil;
    Exit;
    end;

  if (fSinglePart<>nil) then begin
    fHttpClient.Request.ContentType      := fSinglePartType;
    Assert((fTxtParams=nil)or(fTxtParams.Count=0));
    Assert(fMultiParts=nil);
    fDataStream:=fSinglePart;
    fSinglePart:=nil;
    Exit;
    end;

  if (fTxtParams=nil)or(fTxtParams.Count=0) Then Begin
//    raise Exception.Create('no Body specified');
    fHttpClient.Request.ContentLength:=0;
    Exit;
    end;

  StreamStream:=TStringStream.Create;
  fDataStream := StreamStream;
  for i := 0 to fTxtParams.Count - 1 do begin
    key := fTxtParams.Names[i];
    if key<>EmptyStr then Begin
      value := fTxtParams.ValueFromIndex[i];
      if value<>EmptyStr then Begin
        strParam := urlEncode(key) + '=' + urlEncode(value);
      end else
        strParam := urlEncode(key);
    end else
      strParam := urlEncode(key);

    if (i>0) then
      strParam := '&'+strParam;

    StreamStream.WriteString(strParam);
    end;

  fHttpClient.Request.ContentType:= MimeType2Str(ctAPPLICATION_X_WWW_FORM_URLENCODED);
  fHttpClient.Request.CharSet:='utf-8';
end;
{______________________________________________________________________________}
procedure THttpRestRequest.doBeforeRequest;
begin
  if Assigned(FBeforeRequest) then
    FBeforeRequest(Self);
end;
procedure THttpRestRequest.doAfterRequest;
begin
  if Assigned(fAfterRequest) then
    fAfterRequest(Self);
end;
procedure THttpRestRequest.doAfterError;
begin
  if Assigned(fAfterError) then
    fAfterError(Self);
end;
procedure THttpRestRequest.doTrace(Const Msg:String);
begin
  if Assigned(fOnProgress) then
    fOnProgress(Msg);
end;
{______________________________________________________________________________}
function THttpRestRequest.Execute(Const aMethod:THTTPRequestMethod): THttpRestResponse;
Begin
  fMethod:=aMethod;
  Result:=Self.Execute
End;
function THttpRestRequest.Execute: THttpRestResponse;
var url,respStr: string;
begin
  FreeAndNil(fHttpClient);
  FreeAndNil(fDataStream);
  try Self.CreateHttpClient;
      Self.CreateDataStream;
      Self.doBeforeRequest;
      url:=Self.getURLAsStr;
      doTrace('Execute:'+url);
      try case fMethod of
            rmPOST   :respStr := fhttpClient.Post   (url, fDataStream);
            rmPUT    :respStr := fhttpClient.Put    (url, fDataStream);
            rmPATCH  :respStr := fhttpClient.Patch  (url, fDataStream);
            rmDELETE :respStr := fhttpClient.Delete (url);
            rmOptions:respStr := fhttpClient.Options(url);
            rmTrace  :respStr := fhttpClient.Trace  (url);
            else      respStr := fhttpClient.Get    (url);
            end;
          fResponse.fResponseCode := fHttpClient.ResponseCode;
          if respStr=EmptyStr then
            fResponse.fResponseStr:= fHttpClient.ResponseText else
            fResponse.fResponseStr  := respStr;
          if fResponse.ResponseOK then
            Self.doAfterRequest else
            Self.doAfterError;
      except on E: EIdHTTPProtocolException do begin
          fResponse.fResponseCode := fHttpClient.ResponseCode;
          fResponse.fResponseStr  := fHttpClient.ResponseText;
          Self.doAfterError;
          end;
      on E: Exception do begin
          fResponse.fResponseStr  := e.Message;
          fResponse.fResponseCode :=-999;
          Self.doAfterError;
      end end;

      doTrace('Code:'+IntToStr(fResponse.fResponseCode));
    doTrace('Res:'+fResponse.fResponseStr);
      result:=fResponse

  finally
      FreeAndNil(fDataStream);
      FreeAndNil(fHttpClient);
  end;
end;

end.
