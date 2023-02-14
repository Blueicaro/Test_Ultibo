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
  uTFTP,
  Ultibo,
  Console,
  wsutils,
  wsmessages,
  wsstream,
  websocketserver,
  Winsock2;

type

  { TSocketHandler }

  TSocketHandler = class(TThreadedWebsocketHandler)
  private
    procedure ConnectionClosed(Sender: TObject);
    procedure MessageReceived(Sender: TObject);
  public
    function Accept(const ARequest: TRequestData;
      const ResponseHeaders: TStrings): boolean; override;
    procedure DoHandleCommunication(ACommunication: TWebsocketCommunicator);
      override;
  end;
var
  Ventana: TWindowHandle;
  socket: TWebSocketServer;
  ipString: string;

  procedure TSocketHandler.ConnectionClosed(Sender: TObject);
  var
    Comm: TWebsocketCommunicator;
  begin
    Comm := TWebsocketCommunicator(Sender);
    ConsoleWindowWriteLn(Ventana, 'Connection to ' +
      Comm.SocketStream.RemoteAddress.Address + ' clossed');
  end;

  procedure TSocketHandler.MessageReceived(Sender: TObject);
  var
    Messages: TWebsocketMessageOwnerList;
    m: TWebsocketMessage;
    Comm: TWebsocketCommunicator;
  begin
    ConsoleWindowWriteLn(Ventana, 'MessageReciived');
    Comm := TWebsocketCommunicator(Sender);
    Messages := TWebsocketMessageOwnerList.Create(True);
    try
      Comm.GetUnprocessedMessages(Messages);
      for m in Messages do
        if m is TWebsocketStringMessage then
        begin
          ConsoleWindowWriteLn(Ventana, 'Message from ' +
            Comm.SocketStream.RemoteAddress.Address + ': ' +
            TWebsocketStringMessage(m).Data);
        end;
    finally
      Messages.Free;
    end;
  end;


  function TSocketHandler.Accept(const ARequest: TRequestData;
  const ResponseHeaders: TStrings): boolean;
  begin
    Result := True;
  end;

  procedure TSocketHandler.DoHandleCommunication(ACommunication: TWebsocketCommunicator);
  var
    str: string;
  begin
    ConsoleWindowWriteLn(Ventana,'Connected to '+ACommunication.SocketStream.RemoteAddress.Address);
    ACommunication.OnReceiveMessage := @MessageReceived;
    ACommunication.OnClose := @ConnectionClosed;
    while ACommunication.Open do
    begin
      //ReadLn(str);
      str := '';
      if not ACommunication.Open then
        Break; // could be closed by the time ReadLn takes
      if str <> '' then
      begin
        ACommunication.WriteStringMessage(str);
        ConsoleWindowWriteLn(Ventana,'Message to '+ACommunication.SocketStream.RemoteAddress.Address);
      end;

    end;
    socket.Stop(True);
  end;

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
  ConsoleWindowWriteLn(Ventana, 'WebServer starting');
  ConsoleWindowWriteLn(Ventana, 'Waiting for ip');
  ipString := WaitForIPComplete;
  ConsoleWindowWriteLn(Ventana, 'Ip :' + ipString);
  SetOnMsg(@Mensajes);
  socket := TWebSocketServer.Create(8080);
  socket.Output := Ventana;
  ConsoleWindowWriteLn(Ventana, 'socket create');
  try
    socket.FreeHandlers := True;
    socket.RegisterHandler('*', '*', TSocketHandler.Create, True, True);
    ConsoleWindowWriteLn(Ventana, 'socket start');
    socket.Start;
  finally
    ConsoleWindowWriteLn(Ventana, 'finally');
    socket.Free;
  end;
  ThreadHalt(0);
end.
