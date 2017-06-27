unit rmx.gDriveUtils;

interface

Uses System.Classes, System.SysUtils, System.StrUtils, System.DateUtils, System.Generics.Collections,
  IdURI, IdSSL, IdSSLOpenSSLHeaders, IdSSLOpenSSL, superobject,
  rmx.Consts, rmx.JWT, rmx.MimeTypes, rmx.SimpleRESTClient;

{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
{$M-}

Type
  TrmxGDriveFile = Class;
  TrmxGDriveFileList = Class;
  TrmxGDriveUtils = Class;

  TrmxGDriveScope = (
                      gdReadOnlyScope,
                      gdReadWriteScope,
                      gdFullScope
                      );

  TrmxGDriveFlag = (
                     gdFileUpdateDontMove,
                     gdFileUpdateStrictMatch
                     );
  TrmxGDriveFlags = Set Of TrmxGDriveFlag;

  TrmxGDriveFile = Class
  private
    fId               : string;
    fName             : string;
    fMimeType         : TrmxMimeType;
    fDescription      : string;
    fSize             : Int64;
    fVersion          : Int64;
//  "webContentLink": "https://drive.google.com/a/rmxgcp.com/uc?id=xxxx&export=download",
//  "webViewLink": "https://drive.google.com/a/rmxgcp.com/file/d/xxxx/view?usp=drivesdk",
//  "hasThumbnail": true,
//  "thumbnailLink": "https://lh3.googleusercontent.com/xxxx
    fParentIDs        : TStringList;
    fIgnored          : Boolean;

    ///<summary>Lasy create</summary>
    procedure ClearParentIDs;
    ///<summary>Lasy create</summary>
    procedure CheckParentIDs;
    ///<summary>Lasy create</summary>
    procedure SetParentIDs(Const aParentIDs:String);

    ///<summary>Call Back</summary>
    ///<remarks>https://developers.google.com/drive/v3/reference/files#resource</remarks>
    function AssignListResponse(Const so: ISuperObject):Boolean;
    ///<summary>Call Back</summary>
    function AssignCreateResponse(Const so: ISuperObject):Boolean;
    ///<summary>Call Back</summary>
    function AssignUpdateResponse(Const so: ISuperObject):Boolean;
    ///<summary>Call Back</summary>
    ///<remarks>https://developers.google.com/drive/v3/reference/files#resource</remarks>
    function AssignParents(Const so: ISuperObject):Boolean;
    ///<summary>Init from wanted File</summary>
    procedure InitNewFile(Const aGDrive: TrmxGDriveUtils);
    ///<summary>Init from wanted File</summary>
    procedure UpdateMetaData(Const aGDrive: TrmxGDriveUtils);

    ///<summary>Init from wanted File</summary>
    function NewFileAsSO:ISuperObject;
    ///<summary>Init from wanted File</summary>
    function UpdateAsSO:ISuperObject;
    ///<summary>Init from wanted File</summary>
    function FolderAsSO:ISuperObject;

  public
    ///<summary>destructor</summary>
    destructor Destroy; override;

    ///<summary>Setter. Return True if at least on parent resolved</summary>
    function CheckParents(Const aGDrive:TrmxGDriveUtils;Const aParents:TStringList):Boolean;

    property Id            : String          read fId;
    property MimeType      : TrmxMimeType    read fMimeType;
  End;

  TrmxGDriveFileList = Class(TObjectList<TrmxGDriveFile>)
  private
    fIncompleteSearch : Boolean;
    fNextPageToken    : String;

    ///<summary>Call Back</summary>
    function AssignListResponse(Const so: ISuperObject;Const doClear:Boolean):Boolean;
  End;

  TrmxGDriveRequest = class(THttpRestRequest)
  protected
    function GoogleAbout(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;
    function GoogleTeams(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;

    function GoogleFiles(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;
    function GoogleUploadFile(Const aGDrive:TrmxGDriveUtils;Const aFile:TrmxGDriveFile): TrmxGDriveRequest;

    function GoogleCreateFolder(Const aGDrive:TrmxGDriveUtils;Const aFolder:TrmxGDriveFile): TrmxGDriveRequest;
  end;

  TrmxGDriveUtils = Class
  protected
    fServiceName        : String;
    fServiceKey         : String;
    fUser               : String;
    fScope              : TrmxGDriveScope;
    fMyDisplayName      : String;
    fMyRootId           : String;

    fJWT                : TJWT;
    fToken              : String;
    fRESTRequest        : TrmxGDriveRequest;
    fParentList         : TrmxGDriveFileList;
    fFileList           : TrmxGDriveFileList;

    fTeamDrive          : String;
    fTeamDriveId        : String;

    fDestiParent        : String;
    fDestiParentId      : String;
    fDestiParents       : TStringList;
    fDestiParentIds     : TStringList;

    fSourceFile         : String;
    fSourceFilePath     : String;
    fSourceFileName     : String;
    fSourceDescr        : String;

    fOnProgress         : TrmxProgressMsg;
    fLastError          : String;

    ///<summary>Lasy create</summary>
    procedure ClearRequest;
    ///<summary>Setter</summary>
    procedure ClearFileList;
    ///<summary>Setter</summary>
    procedure ClearParentList;
    ///<summary>Parse DestiParent</summary>
    procedure BuildDestiParents;
    ///<summary>Setter</summary>
    function ResolveParentParentIDs:Boolean;
    ///<summary>Setter. Return True if at least on parent resolved</summary>
    function FindParentFromID(Const aParentID:String;Out aParent:TrmxGDriveFile):Boolean;
    ///<summary>Setter. Return True if at least on parent resolved</summary>
    function ResolveParentIDs(Const aParentIDs:TStringList):Boolean;
    ///<summary>Setter. Return True if at least on parent resolved</summary>
    function AddParent(Const so:ISuperObject):TrmxGDriveFile;
    ///<summary>Setter</summary>
    procedure SetSourceFile(const Value: String);
    ///<summary>Check before Update/Create File</summary>
    procedure CheckSourceFile;
    ///<summary>reponse to json</summary>
    function ParseReponse2JSON(Const res:THttpRestResponse;Var so:ISuperObject):Boolean;

    ///<summary>Lasy create</summary>
    ///<remarks>see http://www.webdelphi.ru/2013/05/testirovanie-zaprosov-k-api-google-sredstvami-delphi-komponent-oauthclient-dlya-delphi-xe-xe3/</remarks>
    function Initialize:TrmxGDriveRequest;
    ///<summary>Lasy create</summary>
    ///<remarks>see http://www.webdelphi.ru/2013/05/testirovanie-zaprosov-k-api-google-sredstvami-delphi-komponent-oauthclient-dlya-delphi-xe-xe3/</remarks>
    function Authorize:Boolean;
    ///<summary>Get About Info</summary>
    function About:Boolean;
    ///<summary>Find Wanted Team Drive</summary>
    function FindDrive:Boolean;
    ///<summary>Find Wanted Folder</summary>
    function FindDestiParent(Const CheckIgneded:Boolean;Out AParent:TrmxGDriveFile):Boolean;
    ///<summary>Find Wanted Folder</summary>
    function FindDestiParents:Boolean;
    ///<summary>Find Wanted Folder</summary>
    function CreateDestiParents(Const aRoot:TrmxGDriveFile;Const Destis:TStringList;Out Desti:TrmxGDriveFile):Boolean;

    ///<summary>Upload FileName</summary>
    function DoSearchFile:Boolean;
    ///<summary>Upload FileName</summary>
    function DoCreateFile:Boolean;
    ///<summary>Upload FileName</summary>
    function DoUpdateFile:Boolean;

  protected
    ///<summary>Raise LastError</summary>
    procedure RaiseLastError;
    ///<summary>Do Trace</summary>
    ///  just call OnProgress
    procedure DoTrace(Const Msg:String);

  public
    ///<summary>destructor</summary>
    destructor Destroy; override;

    ///<summary>Clear internal List, ...</summary>
    procedure Clear;

    ///<summary>Upload FileName</summary>
    function UpdateFile:Boolean;
    ///<summary>Upload FileName</summary>
    function UploadFile:Boolean;

    property ServiceName   : String          read fServiceName    write fServiceName;
    property ServiceKey    : String          read fServiceKey     write fServiceKey;
    property User          : String          read fUser           write fUser;
    property Scope         : TrmxGDriveScope read fScope          write fScope;

    property TeamDrive     : String          read fTeamDrive      write fTeamDrive;
    property DestiParent   : String          read fDestiParent    write fDestiParent;

    property SourceFile    : String          read fSourceFile     write SetSourceFile;
    property SourceDescr   : String          read fSourceDescr    write fSourceDescr;

    property OnProgress    : TrmxProgressMsg read fOnProgress     write fOnProgress;
    property LastError     : String          read fLastError;
  end;

implementation

uses IPPeerClient,
  rmx.FileUtils;

Const
  GoogleAuth_Domain        = 'accounts.google.com';

  GoogleApi_Domain         = 'www.googleapis.com';
  GoogleApi_AboutPath      = 'drive/v3/about';
  GoogleApi_FilesPath      = 'drive/v3/files';
  GoogleApi_TeamDrivePath  = 'drive/v3/teamdrives';


    /// <summary>Full, permissive scope to access all of a user's files, excluding the Application Data folder. Request this scope only when it is strictly necessary.</summary>
  Full_Scope = 'https://www.googleapis.com/auth/drive';

    /// <summary>Allows update</summary>
  ReadWrite_Scope = 'https://www.googleapis.com/auth/drive.file';

    /// <summary>Allows read-only access to file metadata and file content</summary>
  ReadOnly_Scope = 'https://www.googleapis.com/auth/drive.metadata.readonly';

{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
destructor TrmxGDriveUtils.Destroy;
Begin
  FreeAndNil(fDestiParentIds);
  FreeAndNil(fDestiParents);

  FreeAndNil(fFileList);
  FreeAndNil(fParentList);
  FreeAndNil(fRESTRequest);
  FreeAndNil(fJWT);
  inherited;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TrmxGDriveUtils.DoTrace(Const Msg:String);
Begin
  if Assigned(fOnProgress) then
    fOnProgress(Msg);
end;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.RaiseLastError;
begin
  if fLastError=EmptyStr then
    fLastError:='Internal Error';
  raise Exception.Create(fLastError);
end;
{______________________________________________________________________________}
function SingleQuote(Const Value:String):String;
Begin
  Result:=AnsiQuotedStr(Value,'''');
  Result:=AnsiReplaceStr(Result,'''''','\''');
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TrmxGDriveUtils.SetSourceFile(const Value: String);
begin
  fSourceFile     := Value;
  fSourceFilePath := ExtractFilePath(fSourceFile);
  fSourceFileName := ExtractFileName(fSourceFile);
end;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.CheckSourceFile;
Begin
  if not FileExists(fSourceFile) Then Begin
    fLastError:=Format('Invalid local file <%s>',[fSourceFile]);
    RaiseLastError;
  End;
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
procedure TrmxGDriveUtils.Clear;
Begin
  FreeAndNil(fFileList);
  FreeAndNil(fParentList);

  FreeAndNil(fRESTRequest);
End;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.ClearRequest;
Begin
  if (fRESTRequest<>nil) then
    fRESTRequest.Clear;
End;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.ClearFileList;
Begin
  if fFileList<>nil then
    fFileList.Clear;
End;
{______________________________________________________________________________}
procedure TrmxGDriveUtils.ClearParentList;
Begin
  if fParentList<>nil then
    fParentList.Clear;
End;
procedure TrmxGDriveUtils.BuildDestiParents;
Var Desti,Destis:String;
  i:Integer;
Begin
  if fDestiParents=nil Then
    fDestiParents:=TStringList.Create else
    fDestiParents.Clear;
  Destis:=fDestiParent;
  Destis:=Destis.TrimRight(['.','/','\',':','-','=']);
  repeat i:=Destis.IndexOf('.');
    if i>=0 then Begin
      Desti:=Destis.Substring(0,i);
      Destis:=Destis.Substring(i+1);
      fDestiParents.Add(Desti);
    End else
      fDestiParents.Add(Destis);
  until (i<0);
  Assert(fDestiParents<>nil);
  Assert(fDestiParents.Count>0);
End;
function TrmxGDriveUtils.AddParent(Const so:ISuperObject):TrmxGDriveFile;
Begin
  if fParentList=nil then
    fParentList:=TrmxGDriveFileList.Create;
  result:=TrmxGDriveFile.Create;
  Self.fParentList.Add(Result);
  result.AssignListResponse(so);
  result.fMimeType:=ctAPPLICATION_VND_GOOGLE_DRIVE_FOLDER;
  Assert(result.fId<>fMyRootId);
End;
function TrmxGDriveUtils.ResolveParentIDs(Const aParentIDs:TStringList):Boolean;
Var res:THttpRestResponse;
  d:TrmxGDriveFile;
  so:ISuperObject;
  parentId:String;
  i:Integer;
Begin
  DoTrace('..Resolve Parents IDs');

  Result:=False;
  Assert(fMyRootId<>EmptyStr);
  for i:=Pred(aParentIDs.Count) downto 0 do Begin
    parentId:=aParentIDs[i];
    if parentId<>fMyRootId then Begin
      if not FindParentFromID(parentId,d) then Begin
        res:=Self.Initialize
      .GoogleFiles(Self)
      .Path(parentId)
      .QueryParamIf(fTeamDriveId,'teamDriveId',fTeamDriveId)
      .QueryParam('supportsTeamDrives',fTeamDriveId<>'')
      .QueryParam('fields','id,name,parents')
      .Execute(rmGET);
        if ParseReponse2JSON(res,so) then
          Self.AddParent(so);
        Result:=True;
      end end end
End;
function TrmxGDriveUtils.ResolveParentParentIDs:Boolean;
Var d:TrmxGDriveFile;
  i,j:Integer;
Begin
  Assert(fMyRootId<>EmptyStr);
  if fDestiParentIds=nil then
    fDestiParentIds:=TStringList.Create else
    fDestiParentIds.Clear;
  for i:=0 to Pred(fParentList.Count) do Begin
    d:=fParentList[i];
    if (d<>nil)and(d.fParentIDs<>nil) Then Begin
      for j:=0 to Pred(d.fParentIDs.Count) do Begin
        if (d.fParentIDs[j]<>fMyRootId) then Begin
          fDestiParentIds.Add(d.fParentIDs[j]);
        end end end end;

  result:=ResolveParentIDs(fDestiParentIds);
  fDestiParentIds.Clear;
End;
function TrmxGDriveUtils.FindParentFromID(Const aParentID:String;Out aParent:TrmxGDriveFile):Boolean;
Var d:TrmxGDriveFile;
  i:Integer;
Begin
  Assert(fMyRootId<>EmptyStr);
  Assert(aParentID<>fMyRootId);
  if fParentList<>nil then Begin
    for i:=0 to Pred(fParentList.Count) do Begin
      d:=fParentList[i];
      if (d<>nil) Then Begin
        Assert(fMyRootId<>d.fId);
        if (d.fId=aParentID) Then Begin
          aParent:=d;
          Exit(True);
        end end end end;

  aParent:=nil;
  Exit(False);
End;
function TrmxGDriveUtils.FindDestiParent(Const CheckIgneded:Boolean;Out AParent:TrmxGDriveFile):Boolean;
Var Desti,SavParents,Sav:String;
  d:TrmxGDriveFile;
  i,SavLvls:Integer;
Begin
  Assert(fParentList<>nil);
  Assert(fDestiParents<>nil);
  Assert(fMyRootId<>EmptyStr);

  SavLvls:=fDestiParents.Count;
  SavParents:=fDestiParents.Text;
  if fParentList.Count>0 then Begin
    if fDestiParents.Count>0 then Begin
      Desti:=fDestiParents[Pred(fDestiParents.Count)];
      fDestiParents.Delete(Pred(fDestiParents.Count));
      Sav:=fDestiParents.Text;
      for i:=0 to Pred(fParentList.Count) do Begin
        d:=fParentList[i];
        if (d=nil) Then
          Continue;
        if (CheckIgneded and d.fIgnored) then
          Continue;
        if ((d.fParentIDs=nil)or(d.fParentIDs.Count=0))and(SavLvls>1) Then
          Continue;
        if not SameText(d.fName,Desti) Then
          Continue;
        fDestiParents.Text:=Sav;
        if d.CheckParents(Self,fDestiParents) then Begin
          fDestiParents.Text:=SavParents;
          AParent:=d;
          Exit(True);
        end end end end;

  fDestiParents.Text:=SavParents;
  Exit(False);
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.Initialize:TrmxGDriveRequest;
Begin
  if fRESTRequest=nil then
    fRESTRequest := TrmxGDriveRequest.Create;
  fRESTRequest.Clear;
  fRESTRequest.UserAgent :='Simple-Rest';
  fRESTRequest.Connection:='close';
  Result:=fRESTRequest;
End;
{______________________________________________________________________________}
function TrmxGDriveRequest.GoogleAbout(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;
begin
  Self.Clear;
  Self.FDomain := GoogleApi_Domain;
  Self.FPaths.Append(GoogleApi_AboutPath);
  Self.FHeaders.Add('Authorization=Bearer '+aGDrive.fToken);
  Result:=Self;
end;
{______________________________________________________________________________}
function TrmxGDriveRequest.GoogleTeams(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;
begin
  Self.Clear;
  Self.FDomain := GoogleApi_Domain;
  Self.FPaths.Append(GoogleApi_TeamDrivePath);
  Self.FHeaders.Add('Authorization=Bearer '+aGDrive.fToken);
  Result:=Self;
end;
{______________________________________________________________________________}
function TrmxGDriveRequest.GoogleFiles(Const aGDrive:TrmxGDriveUtils): TrmxGDriveRequest;
begin
  Self.Clear;
  Self.FDomain := GoogleApi_Domain;
  Self.FPaths.Append(GoogleApi_FilesPath);
  Self.FHeaders.Add('Authorization=Bearer '+aGDrive.fToken);
  if (aGDrive.fTeamDriveId<>'') then
    fQueryParams.Add('supportsTeamDrives=true') else
    fQueryParams.Add('supportsTeamDrives=false');
  Result:=Self;
end;
{______________________________________________________________________________}
function TrmxGDriveRequest.GoogleUploadFile(Const aGDrive:TrmxGDriveUtils;Const aFile:TrmxGDriveFile): TrmxGDriveRequest;
begin
  Self.Clear;
  Self.FDomain := GoogleApi_Domain;
  Self.FPaths.Append('upload');
  Self.FPaths.Append(GoogleApi_FilesPath);
  if aFile.fId<>EmptyStr then
    Self.FPaths.Append(aFile.fId);
  Self.FHeaders.Add('Authorization=Bearer '+aGDrive.fToken);
  Self.fQueryParams.Add('uploadType=multipart');//media');///multipart');//
  if (aGDrive.fTeamDriveId<>'') then
    fQueryParams.Add('supportsTeamDrives=true') else
    fQueryParams.Add('supportsTeamDrives=false');
  Result:=Self;
end;
{______________________________________________________________________________}
function TrmxGDriveRequest.GoogleCreateFolder(Const aGDrive:TrmxGDriveUtils;Const aFolder:TrmxGDriveFile): TrmxGDriveRequest;
begin
  Self.Clear;
  Self.FDomain := GoogleApi_Domain;
  Self.FPaths.Append(GoogleApi_FilesPath);
  Self.FHeaders.Add('Authorization=Bearer '+aGDrive.fToken);
  if (aGDrive.fTeamDriveId<>'') then
    fQueryParams.Add('supportsTeamDrives=true') else
    fQueryParams.Add('supportsTeamDrives=false');

  Self.AddSinglePartJSON('',aFolder.FolderAsSO);

  Result:=Self;
end;
{______________________________________________________________________________}
function TrmxGDriveUtils.ParseReponse2JSON(Const res:THttpRestResponse;Var so:ISuperObject):Boolean;
Begin
  if (not res.ResponseOK) then Begin
    fLastError:=res.ResponseStr;
    Self.ClearRequest;
    Exit(False);
  end;

  so:=SuperObject.SO(res.ResponseStr);
  if not SuperObject.ObjectIsType(so,stObject) then Begin
    fLastError:='Invalid Response';
    Self.ClearRequest;
    Exit(False);
  end;

  Exit(True);
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.Authorize:Boolean;
Var res:THttpRestResponse;
  JWTSigned:String;
  so:ISuperObject;
Begin
  DoTrace('Authorize');
  fMyDisplayName:=EmptyStr;
  fMyRootId:=EmptyStr;
  fToken:=EmptyStr;
  FreeAndNil(fJWT);
  fJWT:=TJWT.Create;

  // Set Header Google OAuth2 server uses RS256
  fJWT.Header.Alg:=TJOSEAlgorithmId.RS256;
  fJWT.Header.Typ:='JWT';

  // Set Payload
  fJWT.Payload.Issuer    := fServiceName;
  fJWT.Payload.Audience  :='https://accounts.google.com/o/oauth2/token';
  fJWT.Payload.IssuedAt  := now;
  fJWT.Payload.Expiration:= IncMinute(now,30);
  fJWT.Payload.Subject   := fUser;
  case fScope of
    gdFullScope:fJWT.Payload.CustomKey['scope'] := Full_Scope;
    gdReadWriteScope:fJWT.Payload.CustomKey['scope'] := ReadWrite_Scope;
  else fJWT.Payload.CustomKey['scope'] := ReadOnly_Scope;
  end;

  // Build JWT Header.Payload.Signature
  fJWT.Sign(fServiceKey);

  // Build JWT Header.Payload.Signature
  JWTSigned:=fJWT.jwt;
  FreeAndNil(fJWT);
  IdSSLOpenSSL.UnLoadOpenSSLLibrary;

  // Build Request
  res:=Self.Initialize
.Domain(GoogleAuth_Domain)
.Path('o/oauth2/token')
.TextParam('grant_type','urn:ietf:params:oauth:grant-type:jwt-bearer')
.TextParam('assertion' , JWTSigned)
.Execute(rmPOST);

  if ParseReponse2JSON(res,so) then Begin
    fToken:=so.S['access_token'];
    Result:=True
  End else
    Result:=False;
end;
{______________________________________________________________________________}
function TrmxGDriveUtils.About:Boolean;
Var res:THttpRestResponse;
  so:ISuperObject;
Begin
  DoTrace('About');
  res:=Self.Initialize
.GoogleAbout(Self)
.QueryParam('fields','user(displayName)')
.Execute(rmGet);

  if not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  End;
  fMyDisplayName:=so.S['user.displayName'];

  DoTrace('RootId');
  res:=Self.Initialize
.GoogleFiles(Self)
.Path('root')
.QueryParamIf(fTeamDriveId,'teamDriveId',fTeamDriveId)
.QueryParam('supportsTeamDrives',fTeamDriveId<>'')
.QueryParam('fields','id')
.Execute(rmGET);
  if not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;
  fMyRootId:=so.S['id'];
  Result:=True;
end;
{______________________________________________________________________________}
function TrmxGDriveUtils.FindDrive:Boolean;
Var so,teamDrives:ISuperObject;
  teamDrive:TSuperTableString;
  res:THttpRestResponse;
  a:TSuperArray;
  i:Integer;
Begin
  fTeamDriveId:=EmptyStr;
  if fTeamDrive=EmptyStr then Begin
    Exit(True);
  end;

  DoTrace('Find Team Drive '+fTeamDrive);
  res:=Self.Initialize
.GoogleTeams(Self)
.Execute(rmGET);
  if Not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;
  teamDrives:=so.O['teamDrives'];
  if not SuperObject.ObjectIsType(teamDrives,stArray) then Begin
    flastError:='teamDrives parse error';
    Exit(False);
  end;
  a:=teamDrives.AsArray;
  for i:=0 to Pred(a.Length) do Begin
    teamDrive:=a.O[i].AsObject;
    if SameText(fTeamDrive,teamDrive.S['name']) Then Begin
      fTeamDriveId:=teamDrive.S['id'];
      Break;
    end end;
  fLastError:='TeamDrive Not Found';
  Result:=fTeamDriveId<>EmptyStr;
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.FindDestiParents:Boolean;
Var SavParents,Desti,QueryNames,pid:String;
  res:THttpRestResponse;
  ppp,pp,p:TrmxGDriveFile;
  so:ISuperObject;
  i,j:Integer;
Begin
  fDestiParentId:=EmptyStr;
  if fDestiParent=EmptyStr then Begin
    Exit(True);
  end;

  DoTrace('Find Desti Folder '+fDestiParent);
  if fParentList=nil then
    fParentList:=TrmxGDriveFileList.Create else
    fParentList.Clear;
  Self.BuildDestiParents;
  for i:=0 to Pred(fDestiParents.Count) do Begin
    Desti:=fDestiParents[i];
    if i=0 then
      QueryNames:='(name='+SingleQuote(Desti)+')' else
      QueryNames:=QueryNames+' or (name='+SingleQuote(Desti)+')';
  end;
  res:=Self.Initialize
.GoogleFiles(Self)
.QueryParamIf(fTeamDriveId,'teamDriveId',fTeamDriveId)
.QueryParam('supportsTeamDrives',fTeamDriveId<>'')
.QueryParam('q','('+QueryNames+' and (mimeType='''+MimeType2Str(ctAPPLICATION_VND_GOOGLE_DRIVE_FOLDER)+'''))')
.QueryParam('fields','*')
.Execute(rmGET);
  if not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;
  fParentList.AssignListResponse(so,False);

  // Remove match with Invalid Parents
  if fParentList.Count>0 then Begin
    for i:=Pred(fParentList.Count) downto 0 do Begin
      p:=fParentList[i];
      Assert(not p.fIgnored);
      if (p=nil)or(p.fParentIDs=nil)or(p.fParentIDs.Count=0) Then
        Continue;
      ppp:=nil;
      for j:=0 to Pred(p.fParentIDs.Count) do Begin
        pid:=p.fParentIDs[j];
        if pid=fMyRootId then Begin
          ppp:=p;
          break;
        end;
        if Self.FindParentFromID(pid,pp) then Begin
          ppp:=pp;
          break;
        end end;
      fParentList[i].fIgnored:=(ppp=nil)
    end end;

  // Find Match with valid Parents
  SavParents:=fDestiParents.Text;
  if fParentList.Count>0 then Begin
    if Self.FindDestiParent(True,p) then Begin
      fDestiParentId:=p.fId;
      Exit(True);
    end end;

  // Create Missing parts
  if fDestiParentIds=nil then
    fDestiParentIds:=TStringList.Create else
    fDestiParentIds.Clear;
  fDestiParents.Text:=SavParents;
  repeat Desti:=fDestiParents[Pred(fDestiParents.Count)];
    fDestiParents.Delete(Pred(fDestiParents.Count));
    fDestiParentIds.Insert(0,Desti);
    if Self.FindDestiParent(True,p) then Begin
      if Self.CreateDestiParents(p,fDestiParentIds,pp) then Begin
        fDestiParentId:=pp.fId;
        Exit(True);
      End else Begin
        Assert(flastError<>EmptyStr);
        Exit(False);
      end end;
  until fDestiParents.Count=0;

  if Not Self.CreateDestiParents(nil,fDestiParentIds,pp) then Begin
    Assert(flastError<>EmptyStr);
    Exit(False);
  end;
  fDestiParentId:=pp.fId;
  Exit(True);
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.CreateDestiParents(Const aRoot:TrmxGDriveFile;Const Destis:TStringList;Out Desti:TrmxGDriveFile):Boolean;
Var res:THttpRestResponse;
  p,n:TrmxGDriveFile;
  so:ISuperObject;
  i:Integer;
Begin
  // Prepare File
  Assert(Destis<>nil);
  Assert(Destis.Count>0);
  Assert(fParentList<>nil);

  p:=aRoot;n:=nil;
  for i:=0 to Pred(Destis.Count) do Begin
    n:=TrmxGDriveFile.Create;fParentList.Add(n);
    n.fName:=Destis[i];
    if p<>nil then
      n.SetParentIDs(p.fId);
    n.fMimeType:=ctAPPLICATION_VND_GOOGLE_DRIVE_FOLDER;
    res:=Self.Initialize
  .GoogleCreateFolder(Self,n)
  .Execute(rmPOST);
    if not ParseReponse2JSON(res,so) then Begin
      Exit(False);
    end;
    n.AssignCreateResponse(so);
    p:=n;
  end;

  fLastError:='Not way to create '+fDestiParent;
  Desti:=n;
  result:=Desti<>nil;
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function TrmxGDriveUtils.DoSearchFile:Boolean;
Var res:THttpRestResponse;
  so:ISuperObject;
Begin
  DoTrace('Search File '+fSourceFileName);

  // Build Request
  Self.ClearFileList;
  res:=Self.Initialize
.GoogleFiles(Self)
.QueryParamIf(fTeamDriveId,'teamDriveId',fTeamDriveId)
.QueryParam('supportsTeamDrives',fTeamDriveId<>'')
.QueryParam('q','name='+SingleQuote(fSourceFileName))
.QueryParam('fields','*')
.Execute(rmGET);

  if not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;
  if fFileList=nil then
    fFileList:=TrmxGDriveFileList.Create;
  if not fFileList.AssignListResponse(so,True) then Begin
    fLastError:='FileList parse error';
    Exit(False);
  end;
  DoTrace('..Found '+IntToStr(fFileList.Count)+' File(s)');
  Result:=True;
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.DoUpdateFile:Boolean;
Var res:THttpRestResponse;
  ff:TrmxGDriveFile;
  so:ISuperObject;
Begin
  DoTrace('Update File '+fSourceFileName);
  Assert(fFileList<>nil);
  Assert(fFileList.Count=1);
  ff:=Self.fFileList[0];

  // Resolve parent
  if (ff.fParentIDs<>nil)and(ff.fParentIDs.Count>0) then Begin
    Self.ResolveParentIDs(ff.fParentIDs);
  end;

  // Build Request
  ff.UpdateMetaData(Self);
  res:=Self.Initialize
.GoogleUploadFile(Self,ff)
.AddMultiPartJSON('',ff.UpdateAsSO)
.AddMultiPartFile('',fSourceFile)
.Execute(rmPATCH);
  if not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;
  if not ff.AssignUpdateResponse(so) then Begin
    fLastError:='Assign Update Response parse error';
    Exit(False);
  end;

  // Check Parents
  if fDestiParentId<>EmptyStr then Begin
    if (ff.fParentIDs=nil)or(ff.fParentIDs.IndexOf(fDestiParentId)<0) Then Begin
      res:=Self.Initialize
    .GoogleFiles(Self)
    .Path(ff.fId)
    .QueryParam('removeParents',ff.fParentIDs.Text)
    .QueryParam('addParents',fDestiParentId)
    .Execute(rmPATCH);
      if ParseReponse2JSON(res,so) then Begin;
        DoTrace('..Moved to '+fDestiParent);
      End else Begin
        DoTrace('**Moved to '+fDestiParent+' Error'+sLinebreak+fLastError);
      end end end;

  DoTrace('..Updated');
  Result:=True;
End;
{______________________________________________________________________________}
function TrmxGDriveUtils.DoCreateFile:Boolean;
Var res:THttpRestResponse;
  ff:TrmxGDriveFile;
  so:ISuperObject;
Begin
  DoTrace('Create File '+fSourceFileName);

  // Prepare File
  if fFileList=nil then
    fFileList:=TrmxGDriveFileList.Create else
    fFileList.Clear;
  ff:=TrmxGDriveFile.Create;fFileList.Add(ff);
  ff.InitNewFile(Self);
  ff.SetParentIDs(fDestiParentId);

  // Build Request
  res:=Self.Initialize
.GoogleUploadFile(Self,ff)
.AddMultiPartJSON('',ff.NewFileAsSO)
.AddMultiPartFile('',fSourceFile)
.Execute(rmPOST);

  if Not ParseReponse2JSON(res,so) then Begin
    Exit(False);
  end;

  if not ff.AssignCreateResponse(so) then Begin
    fLastError:='Assign Update Response parse error';
    Exit(False);
  end;

  DoTrace('..Uploaded');
  Result:=True;
End;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function TrmxGDriveUtils.UpdateFile:Boolean;
Begin
  CheckSourceFile;
  try fScope:=gdFullScope;
    if Self.Authorize then Begin
      if Self.About then Begin
        if Self.FindDrive then Begin
          if Self.FindDestiParents then Begin
            if Self.DoSearchFile then Begin
              if (fFileList<>nil)and(fFileList.Count>0) then Begin
                Assert(fFileList[0].fId<>EmptyStr);
                While fFileList.Count>1 do fFileList.Delete(Pred(fFileList.Count));
                Result:=Self.DoUpdateFile;
              End else
                Result:=Self.DoCreateFile;
            End else
              Result:=False;
          end else
            Result:=False;
        end else
          Result:=False;
      end else
        Result:=False;
    end else
      Result:=False;
  except on e:exception do Begin
    fLastError:=e.message;
    Result:=False;
  end end;
end;
function TrmxGDriveUtils.UploadFile
:Boolean;
Begin
  CheckSourceFile;
  try fScope:=gdFullScope;
    if Self.Authorize then Begin
      if Self.About then Begin
        if Self.FindDrive then Begin
          if Self.FindDestiParents then Begin
            Result:=Self.DoCreateFile;
          End else
            Result:=False;
        End else
          Result:=False;
      End else
        Result:=False;
    End else
      Result:=False;
  except on e:exception do Begin
    fLastError:=e.message;
    Result:=False;
  end end;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
function TrmxGDriveFileList.AssignListResponse(const so: ISuperObject;Const doClear:Boolean):Boolean;
Var files:ISuperObject;
  ff:TrmxGDriveFile;
  a:TSuperArray;
  i:Integer;
begin
  if doClear then
    Self.Clear;

  // Go Array
  files:=so.O['files'];
  if not SuperObject.ObjectIsType(files,stArray) then
    Exit(False);

  a:=files.AsArray;
  for i:=0 to Pred(a.Length) do Begin
    ff:=TrmxGDriveFile.Create;Self.Add(ff);
    ff.AssignListResponse(a.O[i]);
  end;

  fIncompleteSearch:=so.B['incompleteSearch'];
  fNextPageToken   :=so.S['nextPageToken'];
  Result:=True;
end;
{______________________________________________________________________________}
{______________________________________________________________________________}
{______________________________________________________________________________}
destructor TrmxGDriveFile.Destroy;
begin
  fParentIDs.Free;
  inherited;
end;
{______________________________________________________________________________}
procedure TrmxGDriveFile.CheckParentIDs;
Begin
  if fParentIDs=nil then Begin
    fParentIDs:=TStringList.Create;
    fParentIDs.Delimiter:=',';
  end;
End;
procedure TrmxGDriveFile.ClearParentIDs;
Begin
  if fParentIDs<>nil then
    fParentIDs.Clear;
End;
procedure TrmxGDriveFile.SetParentIDs(Const aParentIDs:String);
Begin
  if aParentIDs<>EmptyStr then Begin
    CheckParentIDs;
    fParentIDs.Clear;
    fParentIDs.Add(aParentIDs)
  End else
    Self.ClearParentIDs;
End;
{______________________________________________________________________________}
function TrmxGDriveFile.AssignListResponse(Const so: ISuperObject):Boolean;
begin
////"kind":"drive#file",
  fId           := so.S['id'         ];
  fName         := so.S['name'       ];
  if Str2MimeType(so.S['mimeType'],fMimeType) then Begin
    //
  End else
    fMimeType   := ctNone;
  fDescription  := so.S['description'];
  fSize         := so.I['size'       ];
  fVersion      := so.I['version'    ];

  AssignParents(so);

  Result:=True;
end;
function TrmxGDriveFile.AssignCreateResponse(Const so: ISuperObject):Boolean;
Begin
////"kind":"drive#file",
  Assert(fId=EmptyStr);
  fId:=so.S['id'];
  Result:=True;
End;
function TrmxGDriveFile.AssignUpdateResponse(Const so: ISuperObject):Boolean;
Begin
////"kind":"drive#file",
  Assert(fId=so.S['id']);
  Result:=True;
End;
function TrmxGDriveFile.AssignParents(Const so: ISuperObject):Boolean;
Var aa:ISuperObject;
  a:TSuperArray;
  i:Integer;
Begin
  aa:=so.O['parents'];
  Self.ClearParentIDs;
  if superobject.ObjectIsType(aa,stArray) then Begin
    a:=aa.AsArray;
    for i:=0 to Pred(a.Length) do Begin
      Self.CheckParentIDs;
      fParentIDs.Add(a.S[i])
    end;
    Result:=True;
  End else
    Result:=False;
end;
{______________________________________________________________________________}
function TrmxGDriveFile.NewFileAsSO:ISuperObject;
Var o:TSuperTableString;
  a:ISuperObject;
  aa:TSuperArray;
  i: Integer;
Begin
  Result:=TSuperObject.Create(stObject);o:=Result.AsObject;
  o.S['name'          ] := fName;
  if fMimeType<>ctNone then
    o.S['mimeType'    ] := MimeType2Str(fMimeType);
  if fDescription<>EmptyStr then
    o.S['description' ] :=fDescription;

  if (fParentIDs<>nil)and(fParentIDs.Count>0)then Begin
    a:=TSuperObject.Create(stArray);aa:=a.AsArray;
    o.O['parents'     ] :=a;
    for i:=0 to Pred(fParentIDs.Count) do Begin
      aa.Add(fParentIDs[i]);
    end end;
End;
function TrmxGDriveFile.UpdateAsSO:ISuperObject;
Var o:TSuperTableString;
Begin
  Result:=TSuperObject.Create(stObject);o:=Result.AsObject;
  o.S['name'          ] := fName;
  if fMimeType<>ctNone then
    o.S['mimeType'    ] := MimeType2Str(fMimeType);
  if fDescription<>EmptyStr then
    o.S['description' ] :=fDescription;

  if fId<>EmptyStr then
    o.S['trashed'     ] :='false';
End;
{______________________________________________________________________________}
procedure TrmxGDriveFile.InitNewFile(Const aGDrive: TrmxGDriveUtils);
Var mt:String;
Begin
  fId           := EmptyStr;
  fName         := aGDrive.fSourceFileName;
  if rmx.MimeTypes.LoadMimeType(fName,mt) then Begin
    if Str2MimeType(mt,fMimeType) then Begin
      //
    End else
      fMimeType   := ctNone;
  End else
    fMimeType   := ctNone;
  fDescription  := aGDrive.fSourceDescr;
end;
procedure TrmxGDriveFile.UpdateMetaData(Const aGDrive: TrmxGDriveUtils);
Var smt:TrmxMimeType;
  mt:String;
Begin
  Assert(fId<>EmptyStr);
  fName         := aGDrive.fSourceFileName;
  if rmx.MimeTypes.LoadMimeType(fName,mt) then
    if Str2MimeType(mt,smt) then
      fMimeType := smt;
  if aGDrive.fSourceDescr<>EmptyStr then
    fDescription:= aGDrive.fSourceDescr;
end;
{______________________________________________________________________________}
function TrmxGDriveFile.CheckParents(Const aGDrive:TrmxGDriveUtils;const aParents: TStringList): Boolean;
Var p:TrmxGDriveFile;
  Desti,SavParents:String;
  i:Integer;
begin
  if (aParents=nil)or(aParents.Count=0) then Begin
    Result:=(fParentIDs=nil)or(fParentIDs.IndexOf(aGDrive.fMyRootId)>=0);
    Exit;
  end;

  Desti:=aParents[Pred(aParents.Count)];
  aParents.Delete(Pred(aParents.Count));
  SavParents:=aParents.Text;
  for i:=0 to Pred(fParentIDs.Count) do Begin
    if fParentIDs[i]<>aGDrive.fMyRootId then Begin
      aParents.Text:=SavParents;
      if aGDrive.FindParentFromID(fParentIDs[i],p) then Begin
        if SameText(p.fName,Desti) Then Begin
          if p.CheckParents(aGDrive,aParents) Then Begin
            Exit(True);
          end end end end end;

  Exit(False);
end;
{______________________________________________________________________________}
function TrmxGDriveFile.FolderAsSO:ISuperObject;
Var o:TSuperTableString;
  a:ISuperObject;
  aa:TSuperArray;
  i: Integer;
Begin
  Result:=TSuperObject.Create(stObject);o:=Result.AsObject;
  o.S['name'          ] := fName;
  o.S['mimeType'      ] := MimeType2Str(ctAPPLICATION_VND_GOOGLE_DRIVE_FOLDER);
  if fDescription<>EmptyStr then
    o.S['description' ] :=fDescription;
  if (fParentIDs<>nil)and(fParentIDs.Count>0)then Begin
    a:=TSuperObject.Create(stArray);aa:=a.AsArray;
    o.O['parents'     ] :=a;
    for i:=0 to Pred(fParentIDs.Count) do Begin
      aa.Add(fParentIDs[i]);
    end end;
End;

end.
