unit uBasePluginFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, uICMDExecuter, superobject, uIJSonConfig, uIUIChild, uIPrepare,
  uIRelationObject, uKeyInterface, uIFreeObject, uRelationObjectWrapper,
  uIValueGSetter;

type
  TBasePluginFrame = class(TFrame, IUIChild,
    ICMDExecuter,
    IJSonConfig,
    IPrepareForCreate,
    IFreeObject,
    IRelationObject,
    IStringValueGetter,
    IStringValueSetter)
  private
    FChildObjectList: TKeyInterface;

    FInstanceID: Integer;
    
    FInstanceName: String;

    procedure freeRelationChildren;
  protected
    FRelationOwner:IRelationObject;  
    FJSonData: ISuperObject;
    
    FConfig: ISuperObject;

    /// <summary>
    ///   执行命令(ICMDExecuter， 接口)
    ///   由子类去根据pvCMDIndex实现各种功能。
    /// </summary>
    function DoExecuteCMD(pvCMDIndex:Integer; pvPass:ISuperObject): Integer; virtual;

    /// <summary>
    ///   获取Json的配置(IJSonConfig 接口)
    /// </summary>
    function getJSonConfig: ISuperObject; stdcall;

    /// <summary>
    ///   设置Json的配置(IJSonConfig 接口)
    /// </summary>
    procedure setJSonConfig(const pvConfig: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   获取实例的ID （IUIChild 接口)
    /// </summary>
    function getInstanceID: Integer; stdcall;

    /// <summary>
    ///   获取实例的名 （IUIChild 接口)
    /// </summary>
    function getInstanceName: string; stdcall;

    /// <summary>
    ///   设置实例的名 （IUIChild 接口)
    /// </summary>
    procedure setInstanceName(const pvValue: string); stdcall;

    /// <summary>
    ///   调用面板的Free方法 （IUIChild 接口)
    /// </summary>
    procedure UIFree; stdcall;

    /// <summary>
    ///   将面板布局在一个Parent上面 （IUIChild 接口)
    /// </summary>
    procedure ExecuteLayout(pvParent:TWinControl); stdcall;

    /// <summary>
    ///   执行方法 （IPrepareForCreate 接口)
    ///   子类去重写该方法，一般调用者在设置一些参数后，执行
    /// </summary>
    procedure PrepareForCreate; virtual; stdcall;

    /// <summary>
    ///   设置实例对象 （IUIChild 接口)
    /// </summary>
    function getObject: TWinControl; stdcall;

    /// <summary>
    ///   调用面板的Free方法 （IFreeObject 接口)
    /// </summary>
    procedure FreeObject; stdcall;

  protected

    /// <summary>
    ///   添加一个子对象 （IRelationObject 接口)
    /// </summary>
    procedure addChildObject(pvInstanceID:PAnsiChar; pvChild:IInterface); stdcall;

    /// <summary>
    ///   根据InstanceID查找一个子对象 （IRelationObject 接口)
    /// </summary>
    function findChildObject(pvInstanceID: PAnsiChar): IInterface; stdcall;

    /// <summary>
    ///   根据InstanceID移除一个子对象 （IRelationObject 接口)
    /// </summary>
    procedure removeChildObject(pvInstanceID:PAnsiChar); stdcall;

    /// <summary>
    ///   根据索引序号移除一个子对象 （IRelationObject 接口)
    /// </summary>
    procedure DeleteChildObject(pvIndex:Integer); stdcall;

    /// <summary>
    ///   设置父对象 （IRelationObject 接口)
    /// </summary>
    procedure setOwnerObject(pvOwnerObject: IRelationObject); stdcall;

    /// <summary>
    ///   根据InstanceID判断是否存在子对象 （IRelationObject 接口)
    /// </summary>
    function existsChildObject(pvInstanceID: PAnsiChar):Boolean;stdcall;

    /// <summary>
    ///   子对象个数 （IRelationObject 接口)
    /// </summary>
    function getCount():Integer; stdcall;

    /// <summary>
    ///   根据索引序号查找一个子对象 （IRelationObject 接口)
    /// </summary>
    function getChildObjectItems(pvIndex:Integer): IInterface; stdcall;

    /// <summary>
    ///    获取父对象接口
    /// </summary>
    /// <returns>
    ///    返回父对象的接口,父对象可以为Nil
    /// </returns>
    function GetOwnerObject: IRelationObject; stdcall;
  protected
    /// <summary>
    ///   设置一个字符串值 （IStringValueSetter接口)
    /// </summary>
    procedure setStringValue(pvValueID, pvValue: String); virtual; stdcall;

    /// <summary>
    ///   获取一个字符串值 （IStringValueGetter接口)
    /// </summary>
    function getValueAsString(pvValueID:string): String; virtual; stdcall;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

constructor TBasePluginFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChildObjectList := TKeyInterface.Create();
  FJSonData := SO();
  Randomize;
  FInstanceID :=
    StrToInt(intToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    );

end;

destructor TBasePluginFrame.Destroy;
begin
  freeRelationChildren;
  FJSonData := nil;
  FConfig := nil;
  
  FChildObjectList.clear;
  FChildObjectList.Free;
  inherited Destroy;
end;

procedure TBasePluginFrame.addChildObject(pvInstanceID: PAnsiChar; pvChild:
    IInterface);
begin
  FChildObjectList.put(pvInstanceID, pvChild);
end;

procedure TBasePluginFrame.DeleteChildObject(pvIndex:Integer);
begin
  FChildObjectList.Delete(pvIndex);
end;

function TBasePluginFrame.DoExecuteCMD(pvCMDIndex: Integer; pvPass:
    ISuperObject): Integer;
begin
  ;
end;

procedure TBasePluginFrame.ExecuteLayout(pvParent: TWinControl);
begin
  Self.Parent := pvParent;
  if self.Parent <> nil then
  begin
    Align := alClient;
  end else
  begin
    Align := alNone;
  end;
end;

function TBasePluginFrame.existsChildObject(pvInstanceID: PAnsiChar): Boolean;
begin
  Result := FChildObjectList.exists(pvInstanceID);  
end;

function TBasePluginFrame.findChildObject(pvInstanceID: PAnsiChar): IInterface;
begin
  Result := FChildObjectList.find(pvInstanceID);
end;

procedure TBasePluginFrame.FreeObject;
begin
  Self.Free;
end;

procedure TBasePluginFrame.freeRelationChildren;
begin
  try
    if FRelationOwner <> nil then
    begin
      FRelationOwner.removeChildObject(PAnsiChar(AnsiString(FInstanceName)));
    end;
    TRelationObjectWrapper.RemoveAndFreeChilds(Self);

    FRelationOwner := nil;
  except
  end;   
end;

function TBasePluginFrame.getJSonConfig: ISuperObject;
begin
  Result := FConfig;   
end;

function TBasePluginFrame.getChildObjectItems(pvIndex:Integer): IInterface;
begin
  Result := FChildObjectList.Values[pvIndex];
end;

function TBasePluginFrame.getCount: Integer;
begin
  Result := FChildObjectList.count;
end;

function TBasePluginFrame.getInstanceID: Integer;
begin
  Result := FInstanceID;
end;

function TBasePluginFrame.getInstanceName: string;
begin
  Result := FInstanceName;  
end;

function TBasePluginFrame.getObject: TWinControl;
begin
  Result := Self;
end;

function TBasePluginFrame.GetOwnerObject: IRelationObject;
begin
  Result := FRelationOwner;
end;

function TBasePluginFrame.getValueAsString(pvValueID:string): String;
begin
  Result := '';
end;

procedure TBasePluginFrame.PrepareForCreate;
begin
  ;
end;

procedure TBasePluginFrame.removeChildObject(pvInstanceID: PAnsiChar);
begin
  FChildObjectList.remove(pvInstanceID);
end;

procedure TBasePluginFrame.setInstanceName(const pvValue: string);
begin
  FInstanceName := pvValue;
end;

procedure TBasePluginFrame.setJSonConfig(const pvConfig: ISuperObject);
begin
  FConfig := pvConfig;
end;

procedure TBasePluginFrame.setOwnerObject(pvOwnerObject: IRelationObject);
begin
  FRelationOwner := pvOwnerObject;
end;

procedure TBasePluginFrame.setStringValue(pvValueID, pvValue: String);
begin

end;

procedure TBasePluginFrame.UIFree;
begin
  FreeObject;
end;

end.
