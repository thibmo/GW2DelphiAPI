{
    GW2DelphiAPI - An API port for Guild Wars 2 written in Delphi ( Object-Pascal )
    Copyright (C) 2017  Thimo Braker

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit GW2DelphiAPI;

interface
{$I GW2DelphiAPI.inc}

implementation

{ API data types }
// TGW2ColorDetail
function TGW2ColorDetail.GetRGB(aIndex: Integer): Integer;
begin
  Result := fRGB[aIndex];
end;


procedure TGW2ColorDetail.SetRGB(aIndex, aValue: Integer);
begin
  fRGB[aIndex] := aValue;
end;


// TGW2Color
function TGW2Color.GetRGB(aIndex: Integer): Integer;
begin
  Result := fBase_RGB[aIndex];
end;


procedure TGW2Color.SetRGB(aIndex, aValue: Integer);
begin
  fBase_RGB[aIndex] := aValue;
end;


{ Web handler class }
constructor TWebHandler.Create;
begin
  Inherited Create;
end;


function TWebHandler.SendRequest(aUrl: string): TErrorMessage;
var
  Response: string;
  Error:    TErrorMessage;
begin
   Error.HadError := False;
   Error.Msg := '';

  try
    Response := fHTTPClient.Get(aUrl);
  except
    // Indy protocol exception
    on E:EIdHTTPProtocolException do
    begin
      Error.Msg := 'Error: Indy raised a protocol error!'       + sLineBreak +
                   'HTTP status code: ' + IntToStr(E.ErrorCode) + sLineBreak +
                   'Error message'      + E.Message             + sLineBreak;
      Error.HadError := True;
    end;
    // Indy SSL Library exception
    on E:EIdOSSLCouldNotLoadSSLLibrary do
    begin
      Error.Msg := 'Error: Indy could not load SSL library!' + sLineBreak +
                   'Exception class: ' + E.ClassName                                + sLineBreak +
                   'Error message: '   + E.Message                                  + sLineBreak;
      Error.HadError := True;
    end;
    // Indy server closed connection exception
    on E:EIdConnClosedGracefully do
    begin
      Error.Msg := 'Error: Indy reports, that connection was closed by the server!' + sLineBreak +
                   'Exception class: ' + E.ClassName                                + sLineBreak +
                   'Error message: '   + E.Message                                  + sLineBreak;
      Error.HadError := True;
    end;
    // Indy low-level socket exception
    on E:EIdSocketError do
    begin
      Error.Msg := 'Error: Indy raised a socket error!'    + sLineBreak +
                   'Error code: '  + IntToStr(E.LastError) + sLineBreak +
                   'Error message' + E.Message             + sLineBreak;
      Error.HadError := True;
    end;
    // Indy read-timeout exception
    on E:EIdReadTimeout do
    begin
      Error.Msg := 'Error: Indy raised a read-timeout error!' + sLineBreak +
                   'Exception class: ' + E.ClassName          + sLineBreak +
                   'Error message: '   + E.Message            + sLineBreak;
      Error.HadError := True;
    end;
    // All other Indy exceptions
    on E:EIdException do
    begin
      Error.Msg := 'Error: Something went wrong with Indy!' + sLineBreak +
                   'Exception class: ' + E.ClassName        + sLineBreak +
                   'Error message: '   + E.Message          + sLineBreak;
      Error.HadError := True;
    end;
    // All other Delphi exceptions
    on E:Exception do
    begin
      Error.Msg := 'Error: Something non-Indy related raised an exception!' + sLineBreak +
                   'Exception class: ' + E.ClassName                        + sLineBreak +
                   'Error message: '   + E.Message                          + sLineBreak;
      Error.HadError := True;
    end;
  end;

  if not Error.HadError then
    Error.Msg := Response;

  if fHTTPClient.ResponseCode = 404 then
    raise Exception.Create('Error: API function or value does not exist!');

  if fHTTPClient.ResponseCode = 403 then
    raise Exception.Create('Error: Unauthorized access, please provide a valid API key!');

  Result := Error;
end;


function TWebHandler.BuildParamString(aParams: TUrlParams): string;
var
  Param:     TUrlParam;
  ResultStr: string;
begin
  ResultStr := '';

  for Param in aParams do
  begin
    if ResultStr = '' then
      ResultStr := '?' + Param.Name + '=' + Param.Value
    else
      ResultStr := ResultStr + '&' + Param.Name + '=' + Param.Value;
  end;

  Result := ResultStr;
end;


//* Version: 9
//* Class: WebHandler
//* Retrieve the raw reply of a specific URL
//* aUrl: The complete URL that you wish to call
//* Result: Returns the full reply in plain-text
function TWebHandler.FetchRawEndpoint(aUrl: string): string;
var
  Response: TErrorMessage;
begin
  Response := SendRequest(aUrl);

  if Response.HadError then
    raise Exception.Create(Response.Msg);

  Result := Response.Msg;
end;


//* Version: 32
//* Class: WebHandler
//* Retrieve the raw reply of a specific URL
//* aUrl: The complete URL that you wish to call
//* Result: Returns the full reply as an object
function TWebHandler.FetchRawEndpoint<T>(aUrl: string): T;
var
  Response: TErrorMessage;
  JSObject: TJSONObject;
begin
  Response := SendRequest(aUrl);

  if Response.HadError then
    raise Exception.Create(Response.Msg);

  JSObject := TJSONObject.ParseJSONValue(Response.Msg) as TJSONObject;
  Result   := TJson.JsonToObject<T>(JSObject);
end;


//* Version: 9
//* Class: WebHandler
//* Retrieve the raw reply of a specific API version and function with parameters
//* aVersion: The API version enum value
//* aFunction: The API function enum value
//* aParams: An array of parameters, these can be IDs and Language codes
//* Result: Returns the full reply in plain-text
function TWebHandler.FetchEndpoint(aVersion: TAPIVersion; aFunction: TAPIFunction; aParams: TUrlParams): string;
var
  Url:      string;
  Response: TErrorMessage;
begin
  Url := CONST_API_URL_BASE + CONST_API_Versions[aVersion] + '/' + CONST_API_Functions[aFunction];

  if (Length(aParams) > 0) and not (aParams = nil) then
    Url := Url + BuildParamString(aParams);

  Response := SendRequest(Url);

  if Response.HadError then
    raise Exception.Create(Response.Msg);

  if Response.Msg = '[null]' then
    raise Exception.Create('Error: Empty response!');

  Result := Response.Msg;
end;


//* Version: 32
//* Class: WebHandler
//* Retrieve the raw reply of a specific API version and function with parameters
//* aVersion: The API version enum value
//* aFunction: The API function enum value
//* aParams: An array of parameters, these can be IDs and Language codes
//* Result: Returns the full reply as an object
function TWebHandler.FetchEndpoint<T>(aVersion: TAPIVersion; aFunction: TAPIFunction; aParams: TUrlParams): T;
var
  Url:      string;
  Response: TErrorMessage;
  JSObject: TJSONObject;
begin
  Url := CONST_API_URL_BASE + CONST_API_Versions[aVersion] + '/' + CONST_API_Functions[aFunction];

  if (Length(aParams) > 0) and not (aParams = nil) then
    Url := Url + BuildParamString(aParams);

  Response := SendRequest(Url);

  if Response.HadError then
    raise Exception.Create(Response.Msg);

  JSObject := TJSONObject.ParseJSONValue(Response.Msg) as TJSONObject;
  Result   := TJson.JsonToObject<T>(JSObject);
end;


//* Version: 15
//* Class: WebHandler
//* Retrieve the raw reply of a specific API version and function with parameters and authentication
//* aVersion: The API version enum value
//* aFunction: The API function enum value
//* aParams: An array of parameters, these can be IDs and Language codes
//* aAuthString: Your API auth string
//* Result: Returns the full reply in plain-text
function TWebHandler.FetchAuthEndpoint(aVersion: TAPIVersion; aFunction: TAPIFunction; aParams: TUrlParams; aAuthString: string): string;
begin
  if aAuthString = '' then
    raise Exception.Create('This API function requires authentication.');

  SetLength(aParams, Length(aParams) + 1);
  aParams[Length(aParams) - 1].Name  := 'access_token';
  aParams[Length(aParams) - 1].Value := aAuthString;

  Result := FetchEndpoint(aVersion, aFunction, aParams);
end;


//* Version: 32
//* Class: WebHandler
//* Retrieve the raw reply of a specific API version and function with parameters and authentication
//* aVersion: The API version enum value
//* aFunction: The API function enum value
//* aParams: An array of parameters, these can be IDs and Language codes
//* aAuthString: Your API auth string
//* Result: Returns the full reply as an object
function TWebHandler.FetchAuthEndpoint<T>(aVersion: TAPIVersion; aFunction: TAPIFunction; aParams: TUrlParams; aAuthString: string): T;
begin
  if aAuthString = '' then
    raise Exception.Create('This API function requires authentication.');

  SetLength(aParams, Length(aParams) + 1);
  aParams[Length(aParams) - 1].Name  := 'access_token';
  aParams[Length(aParams) - 1].Value := aAuthString;

  Result := FetchEndpoint<T>(aVersion, aFunction, aParams);
end;


{ Utilities }
//* Version: 21
//* Class: Utils
//* aString: Enum value name
//* Result: Returns the enum value from a string
function TGW2Helper.StringToEnum<TEnum>(const aString: string): TEnum;
var
  TypeInf: PTypeInfo;
  Value:   Integer;
  PValue:  Pointer;
begin
  typeInf := PTypeInfo(TypeInfo(TEnum));
    if typeInf^.Kind <> tkEnumeration then
      raise EInvalidCast.CreateRes(@SInvalidCast);

  Value  := GetEnumValue(TypeInfo(TEnum), aString);

  if Value = -1 then
    raise Exception.CreateFmt('Enum %s not found', [aString]);

  PValue := @Value;
  Result := TEnum(PValue^);
end;


//* Version: 21
//* Class: Utils
//* aEnumValue: Enum value
//* Result: Returns the value of an enum value as a Integer
function TGW2Helper.EnumToInt<TEnum>(const aEnumValue: TEnum): Integer;
begin
  Result := 0;
  Move(aEnumValue, Result, sizeOf(aEnumValue));
end;


//* Version: 21
//* Class: Utils
//* aEnumValue: Enum value
//* Result: Returns the name of an enum value as a string
function TGW2Helper.EnumToString<TEnum>(const aEnumValue: TEnum): string;
begin
  Result := GetEnumName(TypeInfo(TEnum), EnumToInt(aEnumValue));
end;


//* Version: 21
//* Class: Utils
//* aWebHandler: The API webhandler object
//* aAuthStr: The API auth string
//* Result: Returns an API security token
function TGW2Helper.GetTokenInfo(aWebHandler: TWebHandler; aAuthStr: string): TGW2Token;
begin
  Result := aWebHandler.FetchAuthEndpoint<TGW2Token>(APIv2, v2Tokeninfo, nil, aAuthStr);
end;


//* Version: 36
//* Class: Utils
//* aArr: The array to check
//* aValue: The value to search
//* Result: True if the value exists
function TGW2Helper.ArrContains(aArr: TStringArray; aValue: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := Low(aArr) to High(aArr) do
    if aArr[I] = aValue then
    begin
      Result := True;
      Exit;
    end;
end;


//* Version: 36
//* Class: Utils
//* aArr: The array to check
//* aValue: The value to search
//* Result: True if the value exists
function TGW2Helper.ArrContains(aArr: TIntegerArray; aValue: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := Low(aArr) to High(aArr) do
    if aArr[I] = aValue then
    begin
      Result := True;
      Exit;
    end;
end;


{ API Account functions class }
//* Version: 37
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns the account info
function TGW2APIAccount.GetAccount(aWebHandler: TWebHandler; aState: TStateHoler): TGW2Account;
var
  Utils: TGW2Helper;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'account') then
      Result := aWebHandler.FetchAuthEndpoint<TGW2Account>(APIv2, v2Account, nil, aState.AuthString)
    else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 41
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of account achievements
function TGW2APIAccount.GetAchievements(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountAchievementArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'progression') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountAchievements, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountAchievement>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 42
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of account bank items
function TGW2APIAccount.GetBank(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountBankItemArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'inventories') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountBank, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountBankItem>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 44
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array dye IDs
function TGW2APIAccount.GetDyes(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountDyes, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 45
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of finishers
function TGW2APIAccount.GetFinishers(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountFinisherArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountFinishers, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountFinisher>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 46
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of Inventory items
function TGW2APIAccount.GetInventory(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountInventoryItemArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'inventories') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountInventory, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountInventoryItem>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 49
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of masteries
function TGW2APIAccount.GetMasteries(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountMasteryArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'progression') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountMasteries, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountMastery>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 48
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of materials
function TGW2APIAccount.GetMaterials(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountMaterialArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'inventories') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountMaterials, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountMaterial>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 50
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array mini IDs
function TGW2APIAccount.GetMinis(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountMinis, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 51
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array mini IDs
function TGW2APIAccount.GetOutfits(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountOutfits, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 52
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array recipe IDs
function TGW2APIAccount.GetRecipes(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'inventories') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountRecipes, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 53
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array skin IDs
function TGW2APIAccount.GetSkins(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountSkins, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 54
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array skin IDs
function TGW2APIAccount.GetTitles(aWebHandler: TWebHandler; aState: TStateHoler): TIntegerArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'unlocks') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountTitles, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        Result[I] := StrToInt(JSArr.Items[I].Value);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


//* Version: 55
//* Class: Account
//* aWebHandler: The API webhandler object
//* aState: The API state object
//* Result: Returns an array of wallet items
function TGW2APIAccount.GetWallet(aWebHandler: TWebHandler; aState: TStateHoler): TGW2AccountWalletItemArray;
var
  Utils:    TGW2Helper;
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Utils := TGW2Helper.Create;

  if aState.AuthString <> '' then
    if Utils.ArrContains(aState.AuthToken.Permissions, 'inventories') then
    begin
      Reply := aWebHandler.FetchAuthEndpoint(APIv2, v2AccountWallet, nil, aState.AuthString);
      JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
      SetLength(Result, JSArr.Count);

      for I := 0 to JSArr.Count - 1 do
      begin
        if JSArr.Items[I].Null then
          Continue;

        JSObject  := JSArr.Items[I] as TJSONObject;
        Result[I] := TJson.JsonToObject<TGW2AccountWalletItem>(JSObject);
      end;
    end else
      raise Exception.Create('Error: The provided API key does not have enough permissions!')
  else
    raise Exception.Create('Error: No valid API key has been entered!');
end;


{ API Achievements functions class }
//* Version: 56
//* Class: Achievements
//* aWebHandler: The API webhandler object
//* Result: Returns an array achievement IDs
function TGW2APIAchievements.GetAchievementIDs(aWebHandler: TWebHandler): TIntegerArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Achievements, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    if JSArr.Items[I].Null then
      Continue;

    Result[I] := StrToInt(JSArr.Items[I].Value);
  end;
end;


//* Version: 56
//* Class: Achievements
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids and lang)
//* Result: Returns an array of achievements
function TGW2APIAchievements.GetAchievements(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2AchievementArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Achievements, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    if JSArr.Items[I].Null then
      Continue;

    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2Achievement>(JSObject);
  end;
end;


{ API Misc functions class }
//* Version: 9
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns the GW2 build number
function TGW2APIMisc.GetBuild(aWebHandler: TWebHandler): TGW2Version;
begin
  Result := aWebHandler.FetchEndpoint<TGW2Version>(APIv2, v2Build, nil);
end;


//* Version: 12
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of color IDs
function TGW2APIMisc.GetColorIDs(aWebHandler: TWebHandler): TIntegerArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Colors, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := StrToInt(JSArr.Items[I].Value);
end;


//* Version: 12
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids and lang)
//* Result: Returns an array of color objects
function TGW2APIMisc.GetColors(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2ColorArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Colors, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2Color>(JSObject);
  end;
end;


//* Version: 10
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of Quaggan IDs
function TGW2APIMisc.GetQuagganIDs(aWebHandler: TWebHandler): TStringArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Quaggans, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := JSArr.Items[I].Value;
end;


//* Version: 23
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids)
//* Result: Returns an array of Quaggan objects
function TGW2APIMisc.GetQuaggans(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2QuagganArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Quaggans, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2Quaggan>(JSObject);
  end;
end;


//* Version: 25
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of world IDs
function TGW2APIMisc.GetWorldIDs(aWebHandler: TWebHandler): TIntegerArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Worlds, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := StrToInt(JSArr.Items[I].Value);
end;


//* Version: 25
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids and lang)
//* Result: Returns an array of world objects
function TGW2APIMisc.GetWorlds(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2WorldArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Worlds, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2World>(JSObject);
  end;
end;


//* Version: 28
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of currency IDs
function TGW2APIMisc.GetCurrencyIDs(aWebHandler: TWebHandler): TIntegerArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Currencies, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := StrToInt(JSArr.Items[I].Value)
end;


//* Version: 28
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids and lang)
//* Result: Returns an array of currency objects
function TGW2APIMisc.GetCurrencies(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2CurrencyArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Currencies, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2Currency>(JSObject);
  end;
end;


//* Version: 29
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of file IDs
function TGW2APIMisc.GetFileIDs(aWebHandler: TWebHandler): TStringArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Files, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := JSArr.Items[I].Value;
end;


//* Version: 29
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids)
//* Result: Returns an array of file objects
function TGW2APIMisc.GetFiles(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2FileArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Files, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2File>(JSObject);
  end;
end;


//* Version: 30
//* Class: Misc
//* aWebHandler: The API webhandler object
//* Result: Returns an array of Mini IDs
function TGW2APIMisc.GetMiniIDs(aWebHandler: TWebHandler): TIntegerArray;
var
  Reply: string;
  JSArr: TJSONArray;
  I:     Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Minis, nil);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
    Result[I] := StrToInt(JSArr.Items[I].Value)
end;


//* Version: 30
//* Class: Misc
//* aWebHandler: The API webhandler object
//* aParams: The parameters (ids and lang)
//* Result: Returns an array of Mini objects
function TGW2APIMisc.GetMinis(aWebHandler: TWebHandler; aParams: TUrlParams): TGW2MiniArray;
var
  Reply:    string;
  JSArr:    TJSONArray;
  JSObject: TJSONObject;
  I:        Integer;
begin
  Reply := aWebHandler.FetchEndpoint(APIv2, v2Minis, aParams);
  JSArr := TJSONObject.ParseJSONValue(Reply) as TJSONArray;
  SetLength(Result, JSArr.Count);

  for I := 0 to JSArr.Count - 1 do
  begin
    JSObject  := JSArr.Items[I] as TJSONObject;
    Result[I] := TJson.JsonToObject<TGW2Mini>(JSObject);
  end;
end;


{ Main API class }
//TODO 1 -oThimo -cMain: Add functions/procedures for the API
constructor TGW2API.Create(aTimeoutSeconds: Integer = 15);
begin
  Inherited Create;

  // Initialize the HTTP client
  fStateHolder.HTTPClient                   := TIdHTTP.Create(nil);
  fStateHolder.HTTPClient.Request.UserAgent := 'Mozilla/5.0 (compatible; GW2DelphiAPI/' +
                                               CONST_VERSION_SHORT + ')';

  // Set initial info
  SetTimeout(aTimeoutSeconds);
  fWebHandler            := TWebHandler.Create;
  fWebHandler.HTTPClient := fStateHolder.HTTPClient;
  fUtils                 := TGW2Helper.Create;
  fMisc                  := TGW2APIMisc.Create;
  fAccount               := TGW2APIAccount.Create;
end;


destructor TGW2API.Destroy;
begin
  fStateHolder.HTTPClient.Disconnect;
  FreeAndNil(fWebHandler);
  FreeAndNil(fStateHolder.HTTPClient);
  FreeAndNil(fUtils);
  FreeAndNil(fMisc);
  FreeAndNil(fAccount);
end;


//* Version: 9
//* Class: GW2API
//* Sets the read/write timeout for the websocket
//* aSeconds: Number of seconds
procedure TGW2API.SetTimeout(aSeconds: SmallInt);
begin
  fStateHolder.HTTPTimeout               := aSeconds * CONST_ONE_SECOND;
  fStateHolder.HTTPClient.ConnectTimeout := fStateHolder.HTTPTimeout;
  fStateHolder.HTTPClient.ReadTimeout    := fStateHolder.HTTPTimeout;
end;


//* Version: 9
//* Class: GW2API
//* Sets the security token for this API session
//* aAuthString: The API auth string
//* Result: Returns an error or string of permissions
function TGW2API.Authenticate(aAuthString: string): string;
var
  AuthToken: TGW2Token;
  StrValue:  string;
begin
  if not TRegEx.IsMatch(aAuthString, '^(?:[A-F\d]{4,20}-?){8,}$') then
  begin
    Result := 'The provided API key does not match the expected format.';
    Exit;
  end;

  fStateHolder.AuthString := aAuthString;
  fStateHolder.AuthToken  := nil;

  AuthToken := fUtils.GetTokenInfo(fWebHandler, aAuthString);

  for StrValue in AuthToken.Permissions do
    if Result = '' then
      Result := 'Permissions granted to this API key: ' + StrValue
    else
      Result := Result + ', ' + StrValue;

  fStateHolder.AuthToken := AuthToken;
end;

end.
