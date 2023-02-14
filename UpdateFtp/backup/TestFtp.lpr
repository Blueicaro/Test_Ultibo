program TestFtp;

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
  Console,
  uTFTP,
  Winsock2;

var
  Ventana: TWindowHandle;
  IpAddress: String;

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
    if Ventana = INVALID_HANDLE_VALUE then
    begin
      exit;
    end;
    ConsoleWindowWrite(Ventana, Msg);
  end;


begin
  Ventana := ConsoleWindowCreate(ConsoleDeviceGetDefault, CONSOLE_POSITION_FULL, False);
  ConsoleWindowWriteln('Esperando por dirección IP');

  IpAddress := WaitForIPComplete;
  ConsoleWindowWriteln(Ventana, IpAddress);
  SetOnMsg(@Mensajes);
  ThreadHalt(0);
end.
