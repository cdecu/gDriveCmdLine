{******************************************************************************}
{  Inspired from Delphi JOSE Library                                           }
{  https://github.com/paolo-rossi/delphi-jose-jwt Copyright (c) Paolo Rossi    }
{  https://github.com/php/php-src/blob/master/ext/openssl/openssl.c            }
{  https://github.com/delphiunderground/eid-mw-sdk-delphi/blob/master/OpenSSL-Delphi/ssl_evp.pas }
{                                                                              }
{******************************************************************************}
unit rmx.JWT;

interface

Uses System.Classes, System.SysUtils, System.DateUtils,
  System.Hash, System.NetEncoding;

Type
  TJWT = Class;

  TJOSEAlgorithmId = (
                       Unknown, None,
                       HS256, HS384, HS512,
                       RS256, RS384, RS512,
                       ES256, ES384, ES512,
                       PS256, PS384, PS512
                       );

  TJWTHeader = Class
  private
    fAlg           : TJOSEAlgorithmId;
    fTyp           : String;
  public
    ///<summary>Clear</summary>
    procedure Clear;
    ///<summary>Getter</summary>
    function json: String;

    property Alg       : TJOSEAlgorithmId read fAlg          write fAlg;
    property Typ       : String           read fTyp          write fTyp;
  end;

  TJWTPayload = Class
  private
    fAudience      : string;
    fExpiration    : TDateTime;
    fIssuedAt      : TDateTime;
    fIssuer        : string;
    fJWTId         : string;
    fNotBefore     : TDateTime;
    fSubject       : string;
    fCustomKeys    : TStringList;
    ///<summary>Getter</summary>
    function GetCustomKey(const aKey: string): String;
    ///<summary>Getter</summary>
    procedure SetCustomKey(const aKey, Value: String);
  public
    ///<summary>destructor</summary>
    destructor Destroy; override;

    ///<summary>Clear</summary>
    procedure Clear;
    ///<summary>Getter</summary>
    function json: String;

    property Audience  : string           read fAudience     write fAudience;
    property Expiration: TDateTime        read fExpiration   write fExpiration;
    property IssuedAt  : TDateTime        read fIssuedAt     write fIssuedAt;
    property Issuer    : string           read fIssuer       write fIssuer;
    property JWTId     : string           read fJWTId        write fJWTId;
    property NotBefore : TDateTime        read fNotBefore    write fNotBefore;
    property Subject   : string           read fSubject      write fSubject;
    property CustomKey[Const aKey:string] : String read GetCustomKey write SetCustomKey;
  End;

  TJWTSign = Class Abstract
  private
    fSignature  : String;
  public
    ///<summary>Clear</summary>
    procedure Clear;virtual;
    ///<summary>Clear</summary>
    procedure Sign(Const aJWT:TJWT;Const aKey:String);virtual;abstract;

    property Signature : String           read fSignature;
  end;

  TJWT = Class
  private
    fHeader     : TJWTHeader;
    fPayload    : TJWTPayload;
    fSign       : TJWTSign;

    fHeaderJson : String;
    fPayloadJson: String;
    fSignJson   : String;
    fStrBuilder : TStringBuilder;

    ///<summary>Getter</summary>
    function GetHeader: TJWTHeader;
    ///<summary>Getter</summary>
    function GetPayload: TJWTPayload;
    ///<summary>Getter</summary>
    function JSONEncode64(Const Value:String): String;
  public
    ///<summary>destructor</summary>
    destructor Destroy; override;

    ///<summary>Clear</summary>
    procedure Clear;
    ///<summary>Clear</summary>
    procedure Sign(Const aKey:String);
    ///<summary>Getter</summary>
    function jwt: String;

    property Header : TJWTHeader  read GetHeader;
    property Payload: TJWTPayload read GetPayload;
  end;

implementation

uses IdSSLOpenSSLHeaders, IdSSLOpenSSL;

Const
  LIBEAY_DLL_NAME = 'libeay32.dll';  {Do not localize}

  JOSEAlgorithmId : Array[TJOSEAlgorithmId] of String = (
'Unknown', 'None',
'HS256', 'HS384', 'HS512',
'RS256', 'RS384', 'RS512',
'ES256', 'ES384', 'ES512',
'PS256', 'PS384', 'PS512'
);

Type
  THMACSign = Class(TJWTSign)
  public
    ///<summary>Clear</summary>
    procedure Sign(Const aJWT:TJWT;Const aKey:String);override;
  end;

  TRS256Sign = Class(TJWTSign)
  private
    fLastError : String;
    FPublicKey: pEVP_PKEY;
    FPrivateKey: pEVP_PKEY;
    FCryptedBuffer: TBytes;
    ///<summary>LoadPrivateKey</summary>
    procedure RaiseLastSSLError;
    ///<summary>LoadPrivateKey</summary>
    function LoadPrivateKey(Const aKey: String): pEVP_PKEY;
  public
    ///<summary>destructor</summary>
    destructor Destroy; override;
    ///<summary>Clear</summary>
    procedure Sign(Const aJWT:TJWT;Const aKey:String);override;
  end;

//TODO   @OpenSSL_add_all_ciphers := LoadFunctionCLib(fn_OpenSSL_add_all_ciphers);
procedure BIO_free_all(a: pBIO); cdecl;external LIBEAY_DLL_NAME;
function RSA_private_encrypt(flen: Integer; from: PByte; _to: PByte; rsa: PRSA; padding: Integer): Integer;cdecl;external LIBEAY_DLL_NAME;

function EVP_MD_CTX_create: PEVP_MD_CTX; cdecl;external LIBEAY_DLL_NAME;
procedure EVP_MD_CTX_destroy(ctx: PEVP_MD_CTX); cdecl;external LIBEAY_DLL_NAME;

{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TJWTHeader.Clear;
begin

end;
function TJWTHeader.json: String;
begin
  Result:='{"alg":"'+JOSEAlgorithmId[fAlg]+'","typ":"'+fTyp+'"}';
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
destructor TJWTPayload.Destroy;
begin
  fCustomKeys.Free;
  inherited;
end;
{______________________________________________________________________________}
function TJWTPayload.GetCustomKey(const aKey: string): String;
begin
  if fCustomKeys<>nil then Begin
    Result:=fCustomKeys.Values[aKey]
  End else
    Result:=EmptyStr;
end;
procedure TJWTPayload.SetCustomKey(const aKey, Value: String);
begin
  Assert(aKey<>EmptyStr);
  Assert(Value<>EmptyStr);
  if fCustomKeys=nil then Begin
    fCustomKeys:=TStringList.Create;
    fCustomKeys.Duplicates:=dupIgnore;
  end;
  fCustomKeys.Values[aKey]:=Value;
end;
{______________________________________________________________________________}
procedure TJWTPayload.Clear;
begin
  if fCustomKeys<>nil then
    fCustomKeys.Clear;
end;
function TJWTPayload.json: String;
Var k,v:String;
  i:Integer;
begin
  Result:='';

  if fIssuer  <>EmptyStr then Result:=Result+',"iss":"'+fIssuer  +'"';
  if fAudience<>EmptyStr then Result:=Result+',"aud":"'+fAudience+'"';
  if fJWTId   <>EmptyStr then Result:=Result+',"jti":"'+fJWTId+'"';
  if fIssuedAt<>0        then Result:=Result+',"iat":"'+IntToStr(DateTimeToUnix(fIssuedAt  ,False))+'"';
  if fExpiration<>0      then Result:=Result+',"exp":"'+IntToStr(DateTimeToUnix(fExpiration,False))+'"';
  if fNotBefore<>0       then Result:=Result+',"nbf":"'+IntToStr(DateTimeToUnix(fNotBefore ,False))+'"';
  if fSubject <>EmptyStr then Result:=Result+',"sub":"'+fSubject+'"';

  if fCustomKeys<>nil then Begin
    for i:=0 to Pred(fCustomKeys.Count) do Begin
      k:=fCustomKeys.Names[i];
      v:=fCustomKeys.ValueFromIndex[i];
      Result:=Result+',"'+k+'":"'+v+'"';
    end end;

  Result[1]:='{';
  Result:=Result+'}';
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TJWTSign.Clear;
begin
  SetLength(fSignature,0);
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
destructor TJWT.Destroy;
begin
  fStrBuilder.Free;
  fSign.Free;
  fPayload.Free;
  fHeader.Free;
  inherited;
end;
{______________________________________________________________________________}
procedure TJWT.Clear;
Begin
  SetLength(fHeaderJson ,0);
  SetLength(fPayloadJson,0);
  SetLength(fSignJson   ,0);

  if fSign<>nil then
    fSign.Clear;
  if fPayload<>nil then
    fPayload.Clear;
  if fHeader<>nil then
    fHeader.Clear;
End;
{______________________________________________________________________________}
function TJWT.GetHeader: TJWTHeader;
begin
  if fHeader=nil then
    fHeader:=TJWTHeader.Create;
  Result:=fHeader;
end;
{______________________________________________________________________________}
function TJWT.GetPayload: TJWTPayload;
begin
  if fPayload=nil then
    fPayload:=TJWTPayload.Create;
  Result:=fPayload;
end;
{______________________________________________________________________________}
function TJWT.JSONEncode64(Const Value:String): String;
Const super_hex_chars = '0123456789abcdef';
Var i,l:Integer;
  c:Char;
Begin
  if fStrBuilder=nil then
    fStrBuilder:=TStringBuilder.Create;
  fStrBuilder.Clear;

  l:=Value.Length;
  for i:=0 to Pred(l) do Begin
    c:=Value.Chars[i];
    if (c > #255) then Begin
      fStrBuilder.Append(c);
      Assert(False);
    End else
      if (c < #32) or (c > #127) then Begin
        fStrBuilder.Append('\u00');
        fStrBuilder.Append(super_hex_chars[ord(c) shr 4]);
        fStrBuilder.Append(super_hex_chars[ord(c) and $f]);
      End else
        fStrBuilder.Append(c);
  end;

  Result:=TNetEncoding.Base64.Encode(fStrBuilder.ToString);

  Result := StringReplace(Result, #13#10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13   , '', [rfReplaceAll]);
  Result := StringReplace(Result, #10   , '', [rfReplaceAll]);
  Result := StringReplace(Result, '+'   , '-', [rfReplaceAll]);
  Result := StringReplace(Result, '/'   , '_', [rfReplaceAll]);
  Result := Result.TrimRight(['=']);
End;
{______________________________________________________________________________}
procedure TJWT.Sign(Const aKey:String);
begin
  if fHeader=nil then
    raise Exception.Create('Header not set');
  fHeaderJson:=JSONEncode64(fHeader.json);

  if fPayload=nil then
    raise Exception.Create('Payload not set');
  fPayloadJson:=JSONEncode64(fPayload.json);

  FreeAndNil(fSign);
  case fHeader.fAlg of
    HS256, HS384, HS512:fSign:=THMACSign.Create;
    RS256:fSign:=TRS256Sign.Create;
  else raise Exception.Create('Unsupoorted Alg '+JOSEAlgorithmId[fHeader.fAlg]);
  end;

  fSign.Sign(Self,aKey);
  fSignJson:=fSign.fSignature;
  FreeAndNil(fSign);
end;
{______________________________________________________________________________}
function TJWT.jwt: String;
begin
  Result:=fHeaderJson+'.'+fPayloadJson+'.'+fSignJson
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure THMACSign.Sign(Const aJWT:TJWT;Const aKey:String);
var LHashAlg:THashSHA2.TSHA2Version;
  Input,Res:TBytes;
begin
  case aJWT.fHeader.fAlg of
    HS256: LHashAlg := THashSHA2.TSHA2Version.SHA256;
    HS384: LHashAlg := THashSHA2.TSHA2Version.SHA384;
  else   LHashAlg := THashSHA2.TSHA2Version.SHA512;
  end;
  Input:=TEncoding.UTF8.GetBytes(aJWT.fHeaderJson+'.'+aJWT.fPayloadJson);
  Res:=THashSHA2.GetHMACAsBytes(Input, AKey, LHashAlg);
  fSignature := TNetEncoding.Base64.EncodeBytesToString(Res);
  fSignature := StringReplace(fSignature, #13#10, '', [rfReplaceAll]);
  fSignature := StringReplace(fSignature, #13   , '', [rfReplaceAll]);
  fSignature := StringReplace(fSignature, #10   , '', [rfReplaceAll]);
  fSignature := StringReplace(fSignature, '+'   ,'-', [rfReplaceAll]);
  fSignature := StringReplace(fSignature, '/'   ,'_', [rfReplaceAll]);
  fSignature := fSignature.TrimRight(['=']);
end;
{______________________________________________________________________________}
destructor TRS256Sign.Destroy;
begin
  EVP_cleanup;
  ERR_free_strings;

  if FPublicKey <> nil then
    EVP_PKEY_free(FPublicKey);
  if FPrivateKey <> nil then
    EVP_PKEY_free(FPrivateKey);

  inherited;
end;
procedure TRS256Sign.RaiseLastSSLError;
Var err: Cardinal;
Begin
  fLastError:='SSL Error';
  repeat err := ERR_get_error;
    if err=0 then
      break;
    fLastError := fLastError + slinebreak + string(ERR_error_string(err, nil));
  until True;
  raise Exception.Create(fLastError);
End;
function TRS256Sign.LoadPrivateKey(Const aKey: String): pEVP_PKEY;
var keystring: AnsiString;
  mem, keybio: pBIO;
  k: pEVP_PKEY;
begin
  keystring := AnsiString(aKey);
  keybio := BIO_new_mem_buf(PAnsiChar(keystring),length(keystring));
  mem := BIO_new(BIO_s_mem());
  try k:=nil;
    BIO_read(mem, PAnsiChar(keystring), length(PAnsiChar(keystring)));
    result := PEM_read_bio_PrivateKey(keybio,@k, nil, nil);
  finally
    BIO_free_all(mem);
    BIO_free(keybio);
  end;
end;
procedure TRS256Sign.Sign(Const aJWT:TJWT;Const aKey:String);
var md_ctx:PEVP_MD_CTX;
  mdtype:PEVP_MD;
  siglen:Integer;
  Input:TBytes;
begin
  if not IdSSLOpenSSL.LoadOpenSSLLibrary then
    raise Exception.Create('Unable to load OpenSSL');

  Input:=TEncoding.UTF8.GetBytes(aJWT.fHeaderJson+'.'+aJWT.fPayloadJson);
  FPrivateKey := LoadPrivateKey(aKey);
  if FPrivateKey = nil then
    RaiseLastSSLError;

  mdtype:=EVP_get_digestbyname('RSA-SHA256');//sha512WithRSAEncryption');//RSA-SHA256');//sha256WithRSAEncryption');//shaWithRSAEncryption');//RSA-SHA256');//sha256WithRSAEncryption');
  if mdtype=nil then
    RaiseLastSSLError;

  siglen := EVP_PKEY_size(FPrivateKey);
  SetLength(FCryptedBuffer,siglen);
  md_ctx:=EVP_MD_CTX_create;
  if md_ctx<>nil then Begin
    try
      if EVP_DigestInit(md_ctx, mdtype)<>0 then Begin
        if EVP_SignUpdate(md_ctx,@Input[0],Length(Input))<>0 then Begin
          if EVP_SignFinal(md_ctx,@FCryptedBuffer[0],@siglen, FPrivateKey)<>0 Then Begin
            fSignature := TNetEncoding.Base64.EncodeBytesToString(FCryptedBuffer);
          end else
            RaiseLastSSLError;
        end else
          RaiseLastSSLError;
      end else
        RaiseLastSSLError;
    finally
      EVP_MD_CTX_destroy(md_ctx);
    end;
  End else
    RaiseLastSSLError;
end;

end.
