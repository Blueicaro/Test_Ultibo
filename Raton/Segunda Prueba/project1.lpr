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
  VC4;   {Incluir VC4 para que la PI tenga soporte OpenGL Es }


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
  FramebufferDevice: PFramebufferDevice = nil;
  FramebufferProperties: TFramebufferProperties;
begin
  Result := False;

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
  if ClientWidth > 1280 then ClientWidth := 1280;
  ClientHeight := FramebufferProperties.PhysicalHeight;
  if ClientHeight > 720 then ClientHeight := 720;

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
var
  J, I: Integer;
  Quad: Integer = 100;
  Omega, Kappa: VectorFloat;
begin
  // Draw gray background.
  for J := 0 to DisplaySize.Y div Quad do
    for I := 0 to DisplaySize.X div Quad do
      EngineCanvas.FillQuad(
        FloatRect4(I * Quad, J * Quad, Quad, Quad),
        IntColor4($FF585858, $FF505050, $FF484848, $FF404040));

  for I := 0 to DisplaySize.X div Quad do
    EngineCanvas.Line(
      Point2(I * Quad, 0.0),
      Point2(I * Quad, DisplaySize.Y),
      $FF555555);

  for J := 0 to DisplaySize.Y div Quad do
    EngineCanvas.Line(
      Point2(0.0, J * Quad),
      Point2(DisplaySize.X, J * Quad),
      $FF555555);

  // Draw an animated hole.
  EngineCanvas.QuadHole(
    Point2(0.0, 0.0),
    DisplaySize,
    Point2(
      DisplaySize.X * 0.5 + Cos(EngineTicks * 0.0073) * DisplaySize.X * 0.25,
      DisplaySize.Y * 0.5 + Sin(EngineTicks * 0.00312) * DisplaySize.Y * 0.25),
    Point2(80.0, 100.0),
    $20FFFFFF, $80955BFF, 16);

  // Draw the image of famous Lenna.
  EngineCanvas.UseImage(EngineImages[ImageLenna]);
  EngineCanvas.TexQuad(FloatRect4RC(
    // TPoint2(DisplaySize) * 0.5  -  Internal Error in FPC
    Point2(DisplaySize.X * 0.5, DisplaySize.Y * 0.5),
    Point2(300.0, 300.0),
    EngineTicks * 0.01),
    IntColorAlpha(128));

  // Draw an animated Arc.
  Omega := EngineTicks * 0.0274;
  Kappa := 1.25 * Pi + Sin(EngineTicks * 0.01854) * 0.5 * Pi;

  EngineCanvas.FillArc(
    Point2(DisplaySize.X * 0.1, DisplaySize.Y * 0.9),
    Point2(75.0, 50.0),
    Omega, Omega + Kappa, 32,
    IntColor4($FFFF0000, $FF00FF00, $FF0000FF, $FFFFFFFF));

  // Draw an animated Ribbon.
  Omega := EngineTicks * 0.02231;
  Kappa := 1.25 * Pi + Sin(EngineTicks * 0.024751) * 0.5 * Pi;

  EngineCanvas.FillRibbon(
    Point2(DisplaySize.X * 0.9, DisplaySize.Y * 0.85),
    Point2(25.0, 20.0),
    Point2(70.0, 80.0),
    Omega, Omega + Kappa, 32,
    IntColor4($FFFF0000, $FF00FF00, $FF0000FF, $FFFFFFFF));

  EngineFonts[FontTahoma].DrawText(
    Point2(4.0, 4.0),
    'FPS: ' + UniString(IntToStr(EngineTimer.FrameRate)),
    IntColor2($FFFFE887, $FFFF0000));

  EngineFonts[FontTahoma].DrawText(
    Point2(4.0, 24.0),
    'Technology: ' + UniString(GetFullDeviceTechString(EngineDevice)),
    IntColor2($FFE8FFAA, $FF12C312));
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


