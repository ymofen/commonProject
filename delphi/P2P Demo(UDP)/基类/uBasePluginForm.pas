unit uBasePluginForm;

interface

uses
  Forms, uIUIForm, uIModuleINfo, Classes, superobject, uIMainForm, ComObj,
  SysUtils, uICMDExecuter, uIRelationObject, uKeyInterface, uIFreeObject,
  uIValueGSetter, uIPrepare, Windows, Messages, DBGridEh;

type
  TBasePluginForm = class(TForm, IUIForm, IModuleINfo,
    ICMDExecuter,
    IFreeObject,
    IRelationObject,
    IPrepareForCreate,
    IStringValueGetter,
    IStringValueSetter)
  private
    FChildObjectList: TKeyInterface;
    FInstanceID: Integer;
    FInstanceKey: string;
    FInstanceName: String;
    /// <summary>
    ///   移除所有的子对象，如果有Owner，从Owner中移除掉自己
    /// </summary>
    procedure freeRelationChildren;
    Procedure DoEnterAsTab(var Msg:Tmsg; var Handle:boolean);
  protected
    FRelationOwner: IRelationObject;
    FConfig: ISuperObject;
    FJSonPass: ISuperObject;

    FJSonData: ISuperObject;

    FModuleFuncIndex:Integer;
    procedure DoClose(var Action: TCloseAction); override;



    ////===========================================
    /// <summary>
    ///  设置窗体标题 （IModuleINfo 接口)
    /// </summary>
    procedure setCaption(pvCaption: string); stdcall;

    /// <summary>
    ///  获取窗体标题 （IModuleINfo 接口)
    /// </summary>
    function getCaption: string; stdcall;

    /// <summary>
    ///   设置配置 （IModuleINfo 接口)
    /// </summary>
    procedure setConfig(pvConfig: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   获取配置 （IModuleINfo 接口)
    /// </summary>
    function getConfig: ISuperObject; stdcall;

    /// <summary>
    ///   设置传入的参数信息 （IModuleINfo 接口)
    /// </summary>
    procedure setJSonPass(pvData: ISuperObject); virtual; stdcall;

    /// <summary>
    ///   获取传入的参数信息 （IModuleINfo 接口)
    /// </summary>
    function getJSonPass: ISuperObject; stdcall;

    /// <summary>
    ///   获取模块实例主键 （IModuleINfo 接口)
    /// </summary>
    function getInstanceKey: string; stdcall;

    /// <summary>
    ///   获取模块模块编号 （IModuleINfo 接口)
    /// </summary>
    function getModuleFuncIndex: Integer; stdcall;

    /// <summary>
    ///   设置模块使用编号 （IModuleINfo 接口)
    /// </summary>
    procedure setModuleFuncIndex(const Value: Integer); stdcall;

    /// <summary>
    ///   执行方法 （IModuleINfo 接口)
    ///   子类去重写该方法，一般调用者在设置一些参数后，执行
    /// </summary>
    procedure PrepareForCreate; virtual; stdcall;
    ////////////////////////=============================


    //获取模块的Data数据
    function getJSonData():ISuperObject; stdcall;

    ///////////////===========================================
    /// <summary>
    ///   作为MDI模式显示 (IUIForm接口)
    /// </summary>
    procedure showAsMDI; stdcall;

    /// <summary>
    ///   作为模态模式显示 (IUIForm接口)
    /// </summary>
    function showAsModal: Integer; stdcall;

    /// <summary>
    ///   获取窗体对象 （IUIForm 接口)
    /// </summary>
    function getObject: TWinControl; stdcall;

    /// <summary>
    ///  关闭窗体  (IUIForm接口)
    /// </summary>
    procedure UIFormClose; stdcall;

    //
    /// <summary>
    ///  释放窗体  (IUIForm接口)
    /// </summary>
    procedure UIFormFree; stdcall;

    /// <summary>
    ///  获取实例ID  (IUIForm接口)
    /// </summary>     
    function getInstanceID: Integer; stdcall;
    /////////////////////////////////////////////////////

    /// <summary>
    ///   执行命令(ICMDExecuter， 接口)
    ///   由子类去根据pvCMDIndex实现各种功能。
    /// </summary>
    function DoExecuteCMD(pvCMDIndex:Integer; pvPass:ISuperObject): Integer; virtual;
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
    procedure FreeObject; stdcall;

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

uses
  mBeanFrameVars, mBeanModuleTools, uMainFormTools, uRelationObjectWrapper;

procedure TBasePluginForm.addChildObject(pvInstanceID: PAnsiChar;
  pvChild: IInterface);
begin
  FChildObjectList.put(pvInstanceID, pvChild);
end;

constructor TBasePluginForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChildObjectList := TKeyInterface.Create;
  FJSonData := SO();
  
  FInstanceKey := CreateClassID;
  Randomize;
  
  FInstanceID :=
    StrToInt(intToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    + IntToStr(Random(9))
    );

  application.OnMessage := DoEnterAsTab;
end;

destructor TBasePluginForm.Destroy;
begin
  FConfig := nil;
  FJSonData := nil;
  
  //通知从主窗体中移除掉本插件
  TMainFormTools.removePlugin(self.FInstanceID);

  //如果共享变量中存在改接口则进行移除(可以提早移除)
  TmBeanFrameVars.removeObject(IntToStr(FInstanceID));

  freeRelationChildren;
  FChildObjectList.clear;
  FChildObjectList.Free;

  inherited Destroy;
end;

procedure TBasePluginForm.DoClose(var Action: TCloseAction);
begin
  if not (fsModal in self.FFormState) then action := caFree;
  inherited DoClose(Action);
end;

procedure TBasePluginForm.DoEnterAsTab(var Msg: Tmsg; var Handle: boolean);
begin
  if  Msg.message = WM_KEYDOWN then
  begin
    if ((Msg.wParam = VK_RETURN) and (not (Screen.ActiveForm.ActiveControl is TDBGridEh))) then
      Keybd_event(VK_TAB,0,0,0);
  end;
end;

function TBasePluginForm.DoExecuteCMD(pvCMDIndex: Integer;
  pvPass: ISuperObject): Integer;
begin
  ;
end;

function TBasePluginForm.existsChildObject(pvInstanceID: PAnsiChar): Boolean;
begin
  Result := FChildObjectList.exists(pvInstanceID);  
end;

function TBasePluginForm.findChildObject(pvInstanceID: PAnsiChar): IInterface;
begin
  Result := FChildObjectList.find(pvInstanceID);
end;

function TBasePluginForm.getCaption: string;
begin
  Result := self.Caption;
end;

function TBasePluginForm.getChildObjectItems(pvIndex:Integer): IInterface;
begin
  Result := FChildObjectList.Values[pvIndex];
end;

function TBasePluginForm.getConfig: ISuperObject;
begin
  Result := FConfig;   
end;

function TBasePluginForm.getCount: Integer;
begin
  Result := FChildObjectList.count;
end;

function TBasePluginForm.getInstanceID: Integer;
begin
  Result := FInstanceID;
end;

function TBasePluginForm.getInstanceKey: string;
begin

end;

function TBasePluginForm.getJSonData: ISuperObject;
begin
  Result := FJSonData;
end;

function TBasePluginForm.getJSonPass: ISuperObject;
begin
  Result := FJSonPass;
end;

function TBasePluginForm.getModuleFuncIndex: Integer;
begin
  Result := FModuleFuncIndex;
end;

function TBasePluginForm.getObject: TObject;
begin
  Result := Self;
end;

function TBasePluginForm.GetOwnerObject: IRelationObject;
begin
  Result := FRelationOwner;
end;

function TBasePluginForm.getValueAsString(pvValueID: string): String;
begin
  Result := '';
end;

procedure TBasePluginForm.PrepareForCreate;
begin
  if FConfig <> nil then
  begin
    //标题
    if FConfig.S['editor.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['editor.Caption'];
    end else if FConfig.S['list.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['list.Caption'];
    end else if FConfig.S['editor.Caption'] <> '' then
    begin
      self.Caption := FConfig.S['editor.Caption'];
    end else if FConfig.S['__config.caption'] <> '' then
    begin
      self.Caption := FConfig.S['__config.caption'];
    end;
  end;
end;

procedure TBasePluginForm.DeleteChildObject(pvIndex:Integer);
begin
  FChildObjectList.Delete(pvIndex);
end;

procedure TBasePluginForm.FreeObject;
begin
  Self.Free;
end;

procedure TBasePluginForm.removeChildObject(pvInstanceID: PAnsiChar);
begin
  FChildObjectList.remove(pvInstanceID);
end;

procedure TBasePluginForm.freeRelationChildren;
begin
  try
    if FRelationOwner <> nil then
    begin
      FRelationOwner.removeChildObject(PAnsiChar(AnsiString(FInstanceName)));
    end;
    TRelationObjectWrapper.RemoveAndFreeChilds(Self);
  except
  end;   
end;

procedure TBasePluginForm.setCaption(pvCaption: string);
begin
  self.Caption := pvCaption;
end;

procedure TBasePluginForm.setConfig(pvConfig: ISuperObject);
begin
  FConfig := pvConfig;
end;

procedure TBasePluginForm.setJSonPass(pvData: ISuperObject);
begin
  FJSonPass := pvData;
end;

procedure TBasePluginForm.setModuleFuncIndex(const Value: Integer);
begin
  FModuleFuncIndex := Value;  
end;

procedure TBasePluginForm.setOwnerObject(pvOwnerObject: IRelationObject);
begin
  FRelationOwner := pvOwnerObject;
end;

procedure TBasePluginForm.setStringValue(pvValueID, pvValue: String);
begin
  
end;

procedure TBasePluginForm.showAsMDI;
begin
  self.FormStyle := fsMDIChild;
  self.WindowState := wsMaximized;
  self.Show;
end;

function TBasePluginForm.showAsModal: Integer;
begin
  Result := ShowModal();
end;

{ TBasePluginForm }

procedure TBasePluginForm.UIFormClose;
begin
  Self.Close;
end;

procedure TBasePluginForm.UIFormFree;
begin
  Self.Free;
end;

end.
