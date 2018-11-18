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
  end;

var
  MainForm: TMainForm;

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

  //Inicializar ratón
  MinCursorX:=0;
  MinCursorY:=0;
  MaxCursorX:=ClientWidth;
  MaxCursorY:=ClientHeight;
  if ClientWidth < FramebufferProperties.PhysicalWidth then
  begin
   MinCursorX:=(FramebufferProperties.PhysicalWidth-ClientWidth) div 2;
   MaxCursorX:=MinCursorX+ClientWidth;
  end;
  if ClientHeight < FramebufferProperties.PhysicalHeight then
  begin
   MinCursorY:=(FramebufferProperties.PhysicalHeight-ClientHeight) div 2;
   MaxCursorY:=MinCursorY+ClientHeight;
  end;
  If FramebufferDeviceSetCursor(FramebufferDevice,0,0,0,0,nil,0) = ERROR_SUCCESS then
  begin
   CursorX := FramebufferProperties.PhysicalWidth div 2;
   CursorY := FramebufferProperties.PhysicalHeight div 2;
   FramebufferDeviceUpdateCursor(FramebufferDevice,True,CursorX,CursorY,False);
   ConsoleWriteLn('Ratón ok');
  end;
  //El movimiento del ratón lo pones el RenderScene

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
  //Leer Ratón
  if MouseReadEx(@MouseData,sizeOf(TMouseData),MOUSE_FLAG_NON_BLOCK,Count)=ERROR_SUCCESS then
  //if MouseRead(@MouseData,SizeOf(TMouseData),Count)=ERROR_SUCCESS then
  begin
   If (MouseData.OffsetX<>0) or (MouseData.OffsetY<>0) then
   begin
    //Por ahora no controlo los botones
    CursorX:=CursorX+MouseData.OffsetX;
    if CursorX <MinCursorX then CursorX:=MinCursorX;
    if CursorX > (MaxCursorX-1) then CursorX:=MaxCursorX-1;

    CursorY:=CursorY+MouseData.OffsetY;
    if CursorY <MinCursorY then CursorY:=MinCursorY;
    if CursorY > MaxCursorY-1 then CursorY:=MaxCursorY-1;

    //Actualizar posición
    FramebufferDeviceUpdateCursor(FramebufferDevice,True,CursorX,CursorY,False);
   end;
  end;
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


