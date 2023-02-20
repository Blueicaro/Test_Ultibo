program server;

{$mode objfpc}{$H+}

{ Raspberry Pi Application                                                     }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }

{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

{  To build for the QEMU target select Project, Project Options ... from the   }
{  menu, go to Config and Target and choose the appropriate Target Controller. }

uses
  RaspberryPi,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo,
  Winsock2,
  uTFTP, WebSocket2,
  Console,
  Logging;      {Para poder hacer looging}


var
  VentanaPrincipal: TWindowHandle;
  ipAddress: string;

  function WaitForIPComplete: string;
  var
    TCP: TWinsock2TCPClient;
  begin
    TCP := TWinsock2TCPClient.Create;
    Result := TCP.LocalAddress;
    if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
      begin
        sleep(1000);
        Result := TCP.LocalAddress;
      end;
    end;
    TCP.Free;
  end;

  procedure Mensajes(Sender: TObject; Msg: string);
  begin
    ConsoleWindowWrite(VentanaPrincipal, Msg);
  end;

begin
  VentanaPrincipal := ConsoleWindowCreate(ConsoleDeviceGetDefault,
    CONSOLE_POSITION_LEFT, True);
  SetOnMsg(@Mensajes);


  { Por defecto loggind está desactivado, así que hay que activarlo }
  CONSOLE_REGISTER_LOGGING := True;
  LoggingConsoleDeviceAdd(ConsoleDeviceGetDefault);
  LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_CONSOLE));

  //Mensajes por la consola de depuración
  LoggingOutput('Esperando por Ip');
  ipAddress := WaitForIPComplete;
  LoggingOutput('Ip actual: ' + ipAddress);
  ThreadHalt(0);
end.
