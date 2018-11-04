program project1;

{$mode delphi}{$H+}

{ Raspberry Pi 3 Application                                                   }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }
{                                                                              }
{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo,
  Console
  { Add additional units here },
  FrameBuffer,
  {Unidades para control remoto }
  Shell,
  ShellFileSystem,
  ShellUpdate,
  RemoteShell,
  {Unidades para ratón}
  Mouse,
  DWCOTG,
  {Unidades para ASphyre }
  PXL.TypeDef,
  PXL.Types,
  PXL.Timing,
  PXL.Devices,
  PXL.ImageFormats,
  PXL.Canvas,
  PXL.SwapChains,
  PXL.Images,
  PXL.Fonts,
  PXL.Providers,
  PXL.Classes,
  PXL.Providers.GLES,  {Par usar OpenGL ES con Asphyre }
  PXL.ImageFormats.Auto,
  VC4;   {Incluir VC4 para que la PI tenga soporte OpenGL ES }

   { TRaton }
 Type
 TRaton = Class (TThread)
 private
   FFrame: PFramebufferDevice;
   FFramebufferProperties: TFramebufferProperties;
   FMaxCursorX: integer;
   FMaxCursorY: integer;
   FMinCursorX: integer;
   FMinCursorY: integer;
   FCursorX: integer;
   FCursorY: integer;
   protected
     procedure Execute;
   public
     Constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt=DefaultStackSize);
     property Frame:PFramebufferDevice read FFrame write FFrame;
     property MinCursorX:integer read FMinCursorX write FMinCursorX;
     property MaxCursorX:integer read FMaxCursorX write FMaxCursorX;
     property MinCursorY : integer read FMinCursorY write FMinCursorY;
     property MaxCursorY:integer read FMaxCursorY write FMaxCursorY;
 end;
type
  TMainForm = class(TObject)
    function FormCreate(Sender: TObject): Boolean;
    procedure FormDestroy(Sender: TObject);
  private
    Name: String;
    Handle: THandle;


    WindowX: Integer;
    WindowY: Integer;

    ClientWidth: Integer;
    ClientHeight: Integer;
    FramebufferDevice: PFramebufferDevice;
    //Mouse
    MouseData:  TMouseData;
    Count: LongWord;
    //Cursor
    CursorX: Integer;
    CursorY: Integer;
    MinCursorX,MinCursorY : Integer;
    MaxCursorX,MaxCursorY : Integer;

    { private declarations }
    ImageFormatManager: TImageFormatManager;
    ImageFormatHandler: TCustomImageFormatHandler;

    DeviceProvider: TGraphicsDeviceProvider;

    EngineDevice: TCustomSwapChainDevice;
    EngineCanvas: TCustomCanvas;
    EngineImages: TAtlasImages;
    EngineFonts: TBitmapFonts;
    EngineTimer: TMultimediaTimer;

    DisplaySize: TPoint2px;
    EngineTicks: Integer;

    ImageLenna: Integer;
    FontTahoma: Integer;

    procedure ApplicationIdle(Sender: TObject);

    procedure EngineTiming(const Sender: TObject);
    procedure EngineProcess(const Sender: TObject);

    procedure RenderWindow;
    procedure RenderScene;
  public
    { public declarations }
    Raton : TRaton;
  end;



var
  MainForm: TMainForm;

{ TRaton }



procedure TRaton.Execute;
var
   MouseData:  TMouseData;
   Count: LongWord;
   CodigoError: integer;
begin
  Sleep(2000);
  if FFrame = nil Then
  begin
   ConsoleWriteLn('FFrame es nil');
   Sleep(1000);
   ThreadHalt(0);
  end;
  FramebufferDeviceGetProperties(FFrame,@FFramebufferProperties);
  CodigoError:=  FramebufferDeviceSetCursor(FFrame,0,0,0,0,nil,0);
  If CodigoError = ERROR_SUCCESS then
  begin
   FCursorX := FFramebufferProperties.PhysicalWidth div 2;
   FCursorY := FFramebufferProperties.PhysicalHeight div 2;
   FramebufferDeviceUpdateCursor(FFrame,True,FCursorX,FCursorY,False);
  end
  else
  begin
    ConsoleWriteLn('Fallo en raton execute:'+IntTostr(CodigoError));
    Sleep(1000);
    ThreadHalt(0);
  end;
  repeat
  if MouseRead(@MouseData,SizeOf(TMouseData),Count)=ERROR_SUCCESS then
  begin
   If (MouseData.OffsetX<>0) or (MouseData.OffsetY<>0) then
   begin
    //Por ahora no controlo los botones
    FCursorX:=FCursorX+MouseData.OffsetX;
    if FCursorX <FMinCursorX then FCursorX:=FMinCursorX;
    if FCursorX > (FMaxCursorX-1) then FCursorX:=FMaxCursorX-1;

    FCursorY:=FCursorY+MouseData.OffsetY;
    if FCursorY <FMinCursorY then FCursorY:=FMinCursorY;
    if FCursorY > FMaxCursorY-1 then FCursorY:=FMaxCursorY-1;

    //Actualizar posición
    FramebufferDeviceUpdateCursor(FFrame,True,FCursorX,FCursorY,False);
     Sleep(100);
   end;
    Sleep(100);
  end;
  until Terminated=True;
  //if MouseRead(@MouseData,SizeOf(TMouseData),Count)=ERROR_SUCCESS then
  //begin
  // If (MouseData.OffsetX<>0) or (MouseData.OffsetY<>0) then
  // begin
  //  //Por ahora no controlo los botones
  //  FCursorX:=FCursorX+MouseData.OffsetX;
  //  if FCursorX <FMinCursorX then FCursorX:=FMinCursorX;
  //  if FCursorX > (FMaxCursorX-1) then FCursorX:=FMaxCursorX-1;
  //
  //  FCursorY:=FCursorY+MouseData.OffsetY;
  //  if FCursorY <FMinCursorY then FCursorY:=FMinCursorY;
  //  if FCursorY > FMaxCursorY-1 then FCursorY:=FMaxCursorY-1;
  //
  //  //Actualizar posición
  //  FramebufferDeviceUpdateCursor(FFrame,True,FCursorX,FCursorY,False);
  // end;
  // end;
  //until Terminated = true;
  //
end;

constructor TRaton.Create(CreateSuspended: Boolean; const StackSize: SizeUInt);
begin
  FreeOnTerminate:=True;

  Inherited Create(CreateSuspended);
end;

function TMainForm.FormCreate(Sender: TObject): Boolean;
var

  FramebufferProperties: TFramebufferProperties;

begin
  Result := False;
   FramebufferDevice := nil;
  if Length(Name) <> 0 then
  begin
   FramebufferDevice := FramebufferDeviceFindByName(Name);
   if FramebufferDevice = nil then
     FramebufferDevice := FramebufferDeviceFindByDescription(Name);
  end;

  if FramebufferDevice = nil then
    FramebufferDevice := FramebufferDeviceGetDefault;

  if FramebufferDevice = nil then
  begin
    ConsoleWriteLn('Failed to locate Framebuffer Device.');
    Exit;
  end;
  ConsoleWriteLn('Located Framebuffer Device.');

  if FramebufferDeviceGetProperties(FramebufferDevice, @FramebufferProperties) <> ERROR_SUCCESS then
  begin
    ConsoleWriteLn('Failed to get Framebuffer properties.');
    Exit;
  end;
  ConsoleWriteLn('Got Framebuffer properties.');
  Handle := THandle(FramebufferDevice);
  ClientWidth := FramebufferProperties.PhysicalWidth;
  //Forzar tamaño a 800X480
  if ClientWidth > 800 then ClientWidth := 800;
  ClientHeight := FramebufferProperties.PhysicalHeight;
  if ClientHeight > 480 then ClientHeight := 480;
  ConsoleWriteLn('Llamando al ratón');
  sleep(2000);
  //Inicializar ratón
  Raton := TRaton.Create(True,THREAD_STACK_DEFAULT_SIZE);
  Raton.Frame:=  FramebufferDevice;
  Raton.MinCursorX:=0;
  Raton.MinCursorX:=0;
  Raton.MaxCursorX:=ClientWidth;
  Raton.MaxCursorY:=ClientHeight;
  if ClientWidth < FramebufferProperties.PhysicalWidth then
  begin
   Raton.MinCursorX:=(FramebufferProperties.PhysicalWidth-ClientWidth) div 2;
   Raton.MaxCursorX:=MinCursorX+ClientWidth;
  end;
  if ClientHeight < FramebufferProperties.PhysicalHeight then
  begin
   Raton.MinCursorY:=(FramebufferProperties.PhysicalHeight-ClientHeight) div 2;
   Raton.MaxCursorY:=MinCursorY+ClientHeight;
  end;


  ImageFormatManager := TImageFormatManager.Create;
  ImageFormatHandler := CreateDefaultImageFormatHandler(ImageFormatManager);

  DeviceProvider := TGLESProvider.Create(ImageFormatManager); {Force use of the GLES provider}
  EngineDevice := DeviceProvider.CreateDevice as TCustomSwapChainDevice;

  DisplaySize := Point2px(ClientWidth, ClientHeight);
  EngineDevice.SwapChains.Add(Handle, DisplaySize);

  if ClientWidth < FramebufferProperties.PhysicalWidth then
    WindowX := (FramebufferProperties.PhysicalWidth - ClientWidth) div 2;
  if ClientHeight < FramebufferProperties.PhysicalHeight then
    WindowY := (FramebufferProperties.PhysicalHeight - ClientHeight) div 2;

  if (WindowX <> 0) or (WindowY <> 0) then
    EngineDevice.Move(0, Point2px(WindowX, WindowY));

  if not EngineDevice.Initialize then
  begin
    ConsoleWriteLn('Failed to initialize PXL Device.');
    Exit;
  end;
  ConsoleWriteLn('Initialized PXL Device.');

  EngineCanvas := DeviceProvider.CreateCanvas(EngineDevice);
  if not EngineCanvas.Initialize then
  begin
    ConsoleWriteLn('Failed to initialize PXL Canvas.');
    Exit;
  end;
  ConsoleWriteLn('Initialized PXL Canvas.');

  EngineImages := TAtlasImages.Create(EngineDevice);

  ImageLenna := EngineImages.AddFromFile(CrossFixFileName('C:\Lenna.png'));
  if ImageLenna = -1 then
  begin
    ConsoleWriteLn('Could not load Lenna image.');
    Exit;
  end;
  ConsoleWriteLn('Loaded Lenna image.');

  EngineFonts := TBitmapFonts.Create(EngineDevice);
  EngineFonts.Canvas := EngineCanvas;

  FontTahoma := EngineFonts.AddFromBinaryFile(CrossFixFileName('C:\Tahoma9b.font'));
  if FontTahoma = -1 then
  begin
    ConsoleWriteLn('Could not load Tahoma font.');
    Exit;
  end;
  ConsoleWriteLn('Loaded Tahoma font.');

  EngineTimer := TMultimediaTimer.Create;
  EngineTimer.OnTimer := EngineTiming;
  EngineTimer.OnProcess := EngineProcess;
  EngineTimer.MaxFPS := 4000;

  EngineTicks := 0;

  Result := True;

end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  EngineTimer.Free;
  EngineFonts.Free;
  EngineImages.Free;
  EngineCanvas.Free;
  EngineDevice.Free;
  DeviceProvider.Free;
  ImageFormatHandler.Free;
  ImageFormatManager.Free;
end;

procedure TMainForm.ApplicationIdle(Sender: TObject);
begin
  EngineTimer.NotifyTick;
end;

procedure TMainForm.EngineTiming(const Sender: TObject);
begin
  RenderWindow;
end;

procedure TMainForm.EngineProcess(const Sender: TObject);
begin
  Inc(EngineTicks);
end;

procedure TMainForm.RenderWindow;
begin
  EngineTimer.Enabled := False;
  try
    if EngineDevice.BeginScene then
    try
      EngineDevice.Clear([TClearType.Color], 0);

      if EngineCanvas.BeginScene then
      try
        RenderScene;
      finally
        EngineCanvas.EndScene;
      end;

      { Invoke "EngineProcess" event (60 times per second, independently of rendering speed) to do processing and calculations
        while GPU is busy rendering the scene. }
      EngineTimer.Process;
    finally
      EngineDevice.EndScene;
    end;
  finally
    EngineTimer.Enabled := True;
  end;
end;

procedure TMainForm.RenderScene;
begin
  EngineCanvas.FillRect(FloatRect(0,DisplaySize.Y-50.0,DisplaySize.X,50),IntColor4($FFbdc3c7 ,$FFbdc3c7,$FFbdc3c7,$FFbdc3c7));
  EngineFonts[FontTahoma].DrawText(
    Point2(4.0, 4.0),
    'FPS: ' + IntToStr(EngineTimer.FrameRate),
    IntColor2($FFFFE887, $FFFF0000));

  EngineFonts[FontTahoma].DrawText(
    Point2(4.0, 24.0),
    'Technology: ' + GetFullDeviceTechString(EngineDevice),
    IntColor2($FFE8FFAA, $FF12C312));
  EngineFonts[FontTahoma    ].DrawText(Point2(4.0,44),'Jorge probando',IntColor2($FFE8FFAA, $FF12C312));
  EngineFonts[FontTahoma].DrawText(Point2(4.0,64),'Ancho texto: '+IntToStr(EngineFonts[FontTahoma].Width),IntColor2($FFE8FFAA, $FF12C312));
  EngineFonts[FontTahoma].DrawText(Point2(4.0,82),'Alto texto: '+IntToStr(EngineFonts[FontTahoma].Height),IntColor2($FFE8FFAA, $FF12C312));

end;

begin
  // Create a console window
  ConsoleWindowCreate(ConsoleDeviceGetDefault, CONSOLE_POSITION_FULLSCREEN, True);

  // Wait for C: drive to be ready
  ConsoleWriteLn('Waiting for C:\ drive.');
  while not DirectoryExists('C:\') do
  begin
    // Sleep for a second
    Sleep(1000);
  end;
  ConsoleWriteLn('C:\ drive is ready.');
  ConsoleWriteLn('Starting example.');

  MainForm := TMainForm.Create;
  if MainForm.FormCreate(nil) then
  begin
    MainForm.Raton.Execute;
    ConsoleWriteLn('MainForm Created.');

    while not ConsoleKeyPressed do
    begin
      // Refresh the image
      MainForm.ApplicationIdle(nil);
     end;

    ConsoleReadKey;

    MainForm.FormDestroy(nil);
    ConsoleWriteLn('MainForm Destroyed.');

    ConsoleWriteLn('Example completed.');
  end;
  MainForm.Free;

  ThreadHalt(0);
end.


