unit GW2DA_Misc;

interface
uses
  // System units
  Sysutils, Classes, REST.JSON, JSON,
  // GW2 Delphi API Units
  GW2DA_Defaults, GW2DA_Types, GW2DA_WebHandlers;

type
  TGW2APIMisc = class(TObject)
    public
      constructor Create;
      procedure GetBuild(aWebHandler: TWebHandler; aAPIVersion: TAPIVersion; aVersion: TGW2Version);
      procedure GetQuagganIDs(aWebHandler: TWebHandler; aStringList: TStringList);
  end;

implementation

constructor TGW2APIMisc.Create;
begin
  Inherited Create;
end;


procedure TGW2APIMisc.GetBuild(aWebHandler: TWebHandler; aAPIVersion: TAPIVersion; aVersion: TGW2Version);
var
  Result:   string;
  JSObject: TJSONObject;
begin
  case aAPIVersion of
    APINone:
      raise Exception.Create('Unsupported API version.');
    APIv1:
    begin
      Result      := aWebHandler.FetchEndpoint(APIv1, v1Build, nil);
      JSObject    := TJSONObject.ParseJSONValue(Result) as TJSONObject;
      aVersion.id := JSObject.GetValue<Integer>('build_id'); // Works
    end;
    APIv2:
    begin
      Result      := aWebHandler.FetchEndpoint(APIv2, v2Build, nil);
      JSObject    := TJSONObject.ParseJSONValue(Result) as TJSONObject;
      aVersion.id := JSObject.GetValue<Integer>('id'); // Works
    end;
  end;

  // Both of these fail... They return 0
  // FetchEndpoint returns the raw JSON string, eg: {"id":66577}
  //
  // aVersion := TJson.JsonToObject<TGW2Version>(IResult);
  // aVersion := TJson.JsonToObject<TGW2Version>(IJSONObject);
end;


procedure TGW2APIMisc.GetQuagganIDs(aWebHandler: TWebHandler; aStringList: TStringList);
var
  Result:  string;
  JSArr:   TJSONArray;
  JSValue: TJSONValue;
begin
  Result := aWebHandler.FetchEndpoint(APIv2, v2Quaggans, nil);
  JSArr  := TJSONObject.ParseJSONValue(Result) as TJSONArray;

  for JSValue in JSArr do
    aStringList.Add(JSValue.Value);
end;

end.
