/*
Vistas actualizables son con las q puedo hacer inserciones, actualizaciones o borrados, y esos cambios se reflejan en dicha tabla (si no hay group by ni nada de eso).
Vistas no actualizables son aquellas q el contenido de las tablas no se pueden modificar directamente, debido a q hay campos calculados, funciones de agregacion o uniones entre tablas.
*/

--DROPS--
DROP VIEW  CASCADE CONSTRAINTS;
DROP VIEW  CASCADE CONSTRAINTS;

--CREACION DE VISTAS--
CREATE OR REPLACE VIEW VISTA_CLIENTE_PERSONA AS 
    SELECT C.ID_CLIENTE, C.NOMBRE, C.TELEFONO, P.DNI, P.NOMBRE_COMPLETO
    FROM CLIENTE C, PERSONA P
    WHERE C.ID_CLIENTE = P.ID_CLIENTE


CREATE OR REPLACE VIEW VISTA_EMPLEADO_CONDUCTOR AS
    SELECT E.ID_EMPLEADO, E.TELEFONO, E.NOMBRE_COMPLETO, E.NSS, E.DNI, C.LICENCIA, C.HORAS_SEMANA
    FROM EMPLEADO E, CONDUCTOR C
    WHERE E.ID_EMPLEADO = C.ID_EMPLEADO

--Son actualizables pq por ej, sobre los clientes puedo hacer actualizaciones facilmente sin q haya problemas de q la bd no sepa donde hacerlos (con empleado y conductor igual).

CREATE OR REPLACE VIEW VISTA_EJECUCION AS
    SELECT E.ID_EJECUCION, E.FECHA_EJECUCION, E.ID_VEHICULO, E.ID_RUTA, EC.ID_CONDUCTOR
    FROM EJECUCION E, VEHICULO V, EMPLEADO EM, RUTA R, EJECUCION_CONDUCTOR EC
    WHERE E.ID_VEHICULO = V.ID_VEHICULO AND E.ID_RUTA = R.ID_RUTA AND E.ID_EJECUCION = EC.ID_EJECUCION AND EC.ID_CONDUCTOR = EM.ID_CONDUCTOR

--No seria actualizable pq al hacer una actualizacion de cualquier tipo, la bd tendria q trabajar con 5 tablas diferentes, lo q hace que los insert (p.ej) sean complicados, ya q no sabemos donde hacerlo primero.