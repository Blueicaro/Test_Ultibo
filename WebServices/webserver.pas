unit webserver;

{$mode ObjFPC}{$H+}

interface

uses
  WebSocket2;

type
  TTestWebSocketServer = class(TWebSocketServer)
  public
    function GetWebSocketConnectionClass(Socket: TTCPCustomConnectionSocket;
      Header: TStringList; ResourceName, Host, Port, Origin, Cookie: string;
      out HttpResult: integer;
      var Protocol, Extensions: string): TWebSocketServerConnections; override;
  end;

procedure StartServer;

implementation

procedure StartServer;
begin

  fServer := TTestWebSocketServer.Create(HostCombo.Text, PortCombo.Text);

  fServer.OnAfterAddConnection := OnAfterAddConnection;
  fServer.OnBeforeAddConnection := OnBeforeAddConnection;
  fServer.OnAfterRemoveConnection := OnAfterRemoveConnection;
  fServer.OnBeforeRemoveConnection := OnBeforeRemoveConnection;
  fServer.OnSocketError := OnServerSocketError;


  fServer.Start;

end;

end.
