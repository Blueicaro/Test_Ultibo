# Actualización automática via FTP

Instrucciones [originales en ingles](https://ultibo.org/forum/viewtopic.php?f=10&t=279#p994).


Simplemente copie uTFTP.pas en su directorio de trabajo (o agréguelo a la ruta de búsqueda) y agregue uTFTP a su cláusula de uses.

Si desea ver los mensajes generados durante la descarga, agregue SetOnMsg(@<una función>); 

    procedimiento LogMSg (Remitente: TObject; s: cadena); ver ejemplo

Para transferir, abra un símbolo del sistema y cambie el directorio a la carpeta que contiene su kernel7.img o kernel.img, luego escriba

tftp -i <ip de pi> PUT kernel7.img

Puede transferir cualquier archivo, aunque el pi se reiniciará después de descargar kernel.img o kernel7.img.

También puede usar la función GET para recuperar archivos de la tarjeta SD. es decir.

tftp -i <ip de pi> OBTENER readme.txt

Se tarda unos 16 segundos en descargar un archivo del kernel y otro par en guardarlo y reiniciarlo.

Si Windows se queja de que tftp no se reconoce, deberá habilitarlo a través de "Programas y características" en el Panel de control.

Disfrutar

