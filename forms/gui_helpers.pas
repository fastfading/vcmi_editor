{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013-2016 Alexander Shishkin alexvins@users.sourceforge.net

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit gui_helpers;

{$I compilersetup.inc}

{$MODESWITCH NESTEDPROCVARS}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, CheckLst,

  editor_types, base_info, logical_id_condition, editor_str_consts,
  editor_classes;

type

  TBaseInfoFilter = function (ATarget: TBaseInfo): boolean is nested;

  { TCheckListBoxHelper }

  TCheckListBoxHelper = class helper for TCustomCheckListBox
  public
    procedure FillFromList(AFullList: THashedCollection; ASrc: TStrings);
    procedure SaveToList(ADest: TStrings);

    procedure SaveToCondition(AFullList: THashedCollection; ADest: TLogicalIDCondition; Permissive: Boolean);

    procedure FillFromCondition(AFullList: THashedCollection; ASrc: TLogicalIDCondition);

    procedure FillFromCondition(AFullList: THashedCollection; ASrc: TLogicalIDCondition; AFilter: TBaseInfoFilter);

    function SelectedInfo: TBaseInfo;
  end;

  { TListBoxHelper }

  TListBoxHelper = class helper for TCustomListBox
  public
    procedure FillFromList(AFullList: THashedCollection; ASelected: AnsiString);
    procedure FillFromList(AFullList: THashedCollection; ASelected: TBaseInfo);
    procedure FillFromList(AFullList: THashedCollection; ASelected: AnsiString; AFilter: TBaseInfoFilter);
    procedure FillFromList(AFullList: THashedCollection; ASelected: TBaseInfo; AFilter: TBaseInfoFilter);
    function SelectedInfo: TBaseInfo;
    function SelectedIdentifier: AnsiString;
  end;

  { TComboBoxHelper }

  TComboBoxHelper = class helper for TCustomComboBox
  public
    procedure FillFromList(AFullList: THashedCollection; ASelected: AnsiString);
    procedure FillFromList(AFullList: THashedCollection; ASelected: TBaseInfo);

    procedure FillFromListWithEmptyOption(AFullList: THashedCollection; ASelected: AnsiString);
    procedure FillFromListWithEmptyOption(AFullList: TStrings; ASelected: AnsiString);

    //assumes items filed from AFullList
    procedure SetValueWithEmptyOption(AFullList: THashedCollection; ASelected: AnsiString);
    procedure SetValueWithEmptyOption(AFullList: TStrings; ASelected: AnsiString);

    //assumes items filed from AFullList
    procedure SetValue(AFullList: THashedCollection; ASelected: AnsiString);
    procedure SetValue(AFullList: THashedCollection; ASelected: TBaseInfo);

    function SelectedInfo: TBaseInfo;
    function SelectedIdentifier: AnsiString;
  end;

  procedure FillItems(ATarget: TStrings; AFullList: THashedCollection);

implementation

procedure FillItems(ATarget: TStrings; AFullList: TStrings);
var
  i: Integer;
  info: TBaseInfo;
begin
  ATarget.Clear;
  for i := 0 to AFullList.Count - 1 do
  begin
    info := AFullList.Objects[i] as TBaseInfo;
    ATarget.AddObject(info.Name+'('+info.Identifier+')',info);
  end;
end;

procedure FillItems(ATarget: TStrings; AFullList: THashedCollection);
var
  i: Integer;
  info: TBaseInfo;
begin
  ATarget.Clear;
  for i := 0 to AFullList.Count - 1 do
  begin
    info := AFullList.Items[i] as TBaseInfo;
    ATarget.AddObject(info.Name+'('+info.Identifier+')',info);
  end;
end;

function FillItems(ATarget: TStrings; AFullList: THashedCollection; ASelected: AnsiString; AFilter: TBaseInfoFilter): integer;
var
  i: Integer;
  info: TBaseInfo;
begin
  Result := -1;

  ATarget.Clear;
  for i := 0 to AFullList.Count - 1 do
  begin
    info := AFullList.Items[i] as TBaseInfo;
    if AFilter(info) then
    begin
      ATarget.AddObject(info.Name+'('+info.Identifier+')',info);
      if(ASelected <>'') and (info.Identifier = ASelected) then
      begin
        Result := ATarget.Count - 1;
      end;
    end;
  end;
end;

function FillItems(ATarget: TStrings; AFullList: THashedCollection; ASelected: AnsiString): integer;
var
  i: Integer;
  info: TBaseInfo;
begin
  Result := -1;

  ATarget.Clear;
  for i := 0 to AFullList.Count - 1 do
  begin
    info := AFullList.Items[i] as TBaseInfo;

    ATarget.AddObject(info.Name+'('+info.Identifier+')',info);
    if(ASelected <>'') and (info.Identifier = ASelected) then
    begin
      Result := ATarget.Count - 1;
    end;

  end;
end;

procedure FillItems(ATarget: TStrings; AFullList: THashedCollection; AFilter: TBaseInfoFilter);
var
  i: Integer;
  info: TBaseInfo;
begin
  ATarget.Clear;
  for i := 0 to AFullList.Count - 1 do
  begin
    info := AFullList.Items[i] as TBaseInfo;
    if AFilter(info) then
    begin
      ATarget.AddObject(info.Name+'('+info.Identifier+')',info);
    end;
  end;
end;

procedure FillCheckListBox(ATarget: TCustomCheckListBox; AFullList: THashedCollection; ASrc: TStrings);
var
  i: Integer;
  info: TBaseInfo;
begin
  FillItems(ATarget.Items, AFullList);

  for i := 0 to ATarget.Items.Count - 1 do
  begin
    info := ATarget.Items.Objects[i] as TBaseInfo;
    ATarget.Checked[i] := ASrc.IndexOf(info.Identifier)>=0;
  end;
end;

procedure FillCheckListBox(ATarget: TCustomCheckListBox; AFullList: THashedCollection; ASrc: TLogicalIDCondition; AFilter: TBaseInfoFilter);
var
  i: Integer;
  info: TBaseInfo;
begin
  FillItems(ATarget.Items, AFullList);

  for i := 0 to ATarget.Items.Count - 1 do
  begin
    info := ATarget.Items.Objects[i] as TBaseInfo;
    ATarget.Checked[i] := ASrc.IsAllowed(info.Identifier);
  end;
end;


function GetSelectedInfo(AItems: TStrings; AIndex: Integer): TBaseInfo;
var
  tmp: TObject;
begin
  if AIndex < 0 then
  begin
    Exit(nil);
  end
  else
  begin
    tmp := AItems.Objects[AIndex];
    if Assigned(tmp) then
    begin
      Exit(tmp as TBaseInfo);
    end
    else
    begin
      Exit(nil);
    end;
  end;
end;

procedure SaveCheckListBox(ATarget: TCustomCheckListBox; ADest: TStrings);
var
  info: TBaseInfo;
  i: Integer;
begin
  ADest.Clear;
  for i := 0 to ATarget.Items.Count - 1 do
  begin
    info := ATarget.Items.Objects[i] as TBaseInfo;
    if ATarget.Checked[i] then
    begin
      ADest.Add(info.Identifier);
    end;
  end;
end;

procedure SaveCheckListBox(ATarget: TCustomCheckListBox; AFullList: THashedCollection; ADest: TLogicalIDCondition; Permissive: Boolean);
var
  info: TBaseInfo;
  i: Integer;

  ban_list: TStringList;
begin
  ADest.Clear;

  ban_list := TStringList.Create;

  try
    for i := 0 to ATarget.Items.Count - 1 do
    begin
      info := ATarget.Items.Objects[i] as TBaseInfo;
      if not ATarget.Checked[i] then
      begin
        ban_list.Add(info.Identifier);
      end;
    end;

    if Permissive then
    begin
      ADest.NoneOf.Assign(ban_list);
    end
    else begin
      for i := 0 to AFullList.Count - 1 do
      begin
        info := AFullList.Items[i] as TBaseInfo;

        if ban_list.IndexOf(info.Identifier) < 0 then
        begin
          ADest.AnyOf.Add(info.Identifier);
        end;
      end;
    end;

  finally
    ban_list.Free;
  end;
end;

{ TComboBoxHelper }

procedure TComboBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: AnsiString);
begin
  text := '';

  ItemIndex := FillItems(Items,AFullList, ASelected);

  if ItemIndex >=0 then
  begin
    Text := (Items.Objects[ItemIndex] as TBaseInfo).Name;
  end;
end;

procedure TComboBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: TBaseInfo);
var
  ID: AnsiString;
begin
  if Assigned(ASelected) then
    ID := ASelected.Identifier
  else
    ID := '';
  FillFromList(AFullList, ID)
end;

procedure TComboBoxHelper.FillFromListWithEmptyOption(
  AFullList: THashedCollection; ASelected: AnsiString);
var
  idx: Integer;
begin
  FillItems(Items, AFullList);

  Items.Insert(0, rsEmpty);

  if ASelected = '' then
  begin
    ItemIndex:= 0;
  end
  else
  begin
    idx := AFullList.IndexOfName(ASelected);

    ItemIndex := idx+1;
  end;

end;

procedure TComboBoxHelper.FillFromListWithEmptyOption(AFullList: TStrings;
  ASelected: AnsiString);
var
  idx: Integer;
begin
  FillItems(Items, AFullList);

  Items.Insert(0, rsEmpty);

  if ASelected = '' then
  begin
    ItemIndex:= 0;
  end
  else
  begin
    idx := AFullList.IndexOfName(ASelected);

    ItemIndex := idx+1;
  end;
end;

procedure TComboBoxHelper.SetValueWithEmptyOption(AFullList: THashedCollection;
  ASelected: AnsiString);
var
  idx: Integer;
begin
  idx := AFullList.IndexOfName(ASelected);

  itemindex := idx+1;
end;

procedure TComboBoxHelper.SetValueWithEmptyOption(AFullList: TStrings;
  ASelected: AnsiString);
var
  idx: Integer;
begin
  idx := AFullList.IndexOf(ASelected);

  itemindex := idx+1;
end;

procedure TComboBoxHelper.SetValue(AFullList: THashedCollection;
  ASelected: AnsiString);
var
  idx: Integer;
begin
  idx := AFullList.IndexOfName(ASelected);

  itemindex := idx;
end;

procedure TComboBoxHelper.SetValue(AFullList: THashedCollection;
  ASelected: TBaseInfo);
var
  ID: AnsiString;
begin
  if Assigned(ASelected) then
    ID := ASelected.Identifier
  else
    ID := '';
  SetValue(AFullList, ID);
end;

function TComboBoxHelper.SelectedInfo: TBaseInfo;
begin
  Result := GetSelectedInfo(Items,ItemIndex);
end;

function TComboBoxHelper.SelectedIdentifier: AnsiString;
var
  info: TBaseInfo;
begin
  info := SelectedInfo();
  if Assigned(info) then
    Result := SelectedInfo.Identifier
  else
    Result := '';
end;

{ TCheckListBoxHelper }

procedure TCheckListBoxHelper.FillFromList(AFullList: THashedCollection;
  ASrc: TStrings);
begin
  FillCheckListBox(Self,AFullList,ASrc)
end;

procedure TCheckListBoxHelper.SaveToList(ADest: TStrings);
begin
  SaveCheckListBox(Self,ADest);
end;

procedure TCheckListBoxHelper.SaveToCondition(AFullList: THashedCollection;
  ADest: TLogicalIDCondition; Permissive: Boolean);
begin
  SaveCheckListBox(Self,AFullList, ADest, Permissive);
end;

procedure TCheckListBoxHelper.FillFromCondition(AFullList: THashedCollection;
  ASrc: TLogicalIDCondition);

  function filter_stub(ATarget: TBaseInfo): Boolean;
  begin
    Result := True;
  end;

begin
  FillCheckListBox(Self,AFullList,ASrc, @filter_stub);
end;

procedure TCheckListBoxHelper.FillFromCondition(AFullList: THashedCollection;
  ASrc: TLogicalIDCondition; AFilter: TBaseInfoFilter);
begin
  FillCheckListBox(Self,AFullList,ASrc, AFilter);
end;

function TCheckListBoxHelper.SelectedInfo: TBaseInfo;
begin
  Result := GetSelectedInfo(Items,ItemIndex);
end;


{ TListBoxHelper }

procedure TListBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: AnsiString);
begin
  ItemIndex := FillItems(Self.Items,AFullList,ASelected);
end;

procedure TListBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: TBaseInfo);
begin
  FillItems(Self.Items, AFullList);
  if Assigned(ASelected) then
  begin
    ItemIndex := Items.IndexOfObject(ASelected);
  end;

end;

procedure TListBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: TBaseInfo; AFilter: TBaseInfoFilter);
begin
  if Assigned(ASelected) then
    FillFromList(AFullList, ASelected.Identifier, AFilter)
  else
    FillFromList(AFullList, '', AFilter)
end;

procedure TListBoxHelper.FillFromList(AFullList: THashedCollection;
  ASelected: AnsiString; AFilter: TBaseInfoFilter);
begin
  ItemIndex := FillItems(Self.Items, AFullList, ASelected, AFilter);
end;

function TListBoxHelper.SelectedInfo: TBaseInfo;
begin
  Result := GetSelectedInfo(Items,ItemIndex);
end;

function TListBoxHelper.SelectedIdentifier: AnsiString;
begin
  if Assigned(SelectedInfo) then
    Result := SelectedInfo.Identifier
  else
    Result := '';
end;

end.

