# Proyectos de prueba de integración de Asphyre con el ratón en ultibo.

Nota: En las opciones del proyecto, compiler options,path; poner en los campos Other unit files e Include files poner la ruta a la librería Asphyre (version githut)

## Primera prueba:

El ejemplo BasicGL de Asphyre se añade el ratón. En esta prueba la posición del ratón se actualiza cada vez	que se asphyre refresca la pantalla. Había problemas con la inercia, pero tras consultar en el foro de 	ultibo, se usar la función "MouseReadEx" que no es bloqueante y soluciona los problemas de "inercia"

## Segunda prueba:

El ratón se controla en un hilo, pero no acaba de ir bien del todo. Es mejor controlar el ratón el hilo que se ejecuta la animación.

Más información sobre el ratón en el hilo del foto de Ultibo:
https://ultibo.org/forum/viewtopic.php?f=13&t=1218