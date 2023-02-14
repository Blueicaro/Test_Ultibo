# Trabajando con Ultibo

[Ultibo](https://ultibo.org/) core es un entorno de desarrollo integrado o bare metal para Raspberry Pi. No es un sistema operativo, pero proporciona muchos de los mismos servicios que un sistema operativo, como administración de memoria, redes, sistemas de archivos y subprocesamiento, y mucho más. Así que no tienes que empezar de cero solo para crear tus ideas.



## Actualización automática via FTP

Para poder actualizar el programa que se ejecuta en la rasperry pi, lo normal retirar la tarjeta SD es colocar los archivos nuevos en ella y volver a colocar la placa en la Raspberry Pi, y reiniciarla.

Existe la opción de acutalizar la tarjeta de manera automática si la placa Raspberry Pi está conectada en red. Para ello se deben cumpliar varios requisitos.

* La placa Raspberry debe tener conexión a red.
* Añadir la unidad uTFTP.pas. Esta unidad es original de pjde y se puede descargar de su [Github](https://github.com/pjde/ultibo-tftp).

En la  carpeta [UpdateFtp](./UpdateFtp/] hay ejemplo basado en el original.


