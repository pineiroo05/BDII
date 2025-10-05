--Insert para empleado conductor 1--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('1a2b3c', 111222333, 'Juanito Fernandez Lopez', '12345678901', '12345678a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('1a2b3c', 'C1', 45);
--Insert para empleado conductor 2--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('2a2b2c', 123456789, 'Alvarito Perez Gomez', '12345678901', '12345678a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('2a2b2c', 'C1', 50);
--Insert para empleado conductor 3--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('3a3b3c', 987654321, 'Manolito Sanchez Lopez', '12345678901', '12345678a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('3a3b3c', 'C1', 44);
--Insert para mecanico--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('2b1a3c', 444555666, 'Pepito Gonzalez Lopez', '10987654321', '87654321b');
INSERT into MECANICO (ID_EMPLEADO, ESPECIALIDAD) values ('2b1a3c', 'Carroceria');
--Insert para administrativo--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('3c2b1a', 777888999, 'Menganito Martinez Lopez', '20987654321', '1357248c');
INSERT into ADMINISTRATIVO (ID_EMPLEADO, DEPARTAMENTO) values ('3c2b1a', 'Contabilidad');

--Vehiculo "normal" sin conductor asignado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps1', 'modelo300', '123abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam1a', 'gps1', NULL, '1234ABC', 7400);
--Vehiculo "normal" con conductor asignado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps2', 'modelo300', '456abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam2a', 'gps2', '1a2b3c', '1234CBA', 7400);
--Vehiculo adr--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps3', 'modelo300', '789abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam3a', 'gps3', '2a2b2c', '1234DCB', 7400);
--Vehiculo refrigerado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps4', 'modelo300', '147abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam4a', 'gps4', '3a3b3c', '1234FCP', 7400);

--Ruta y paradas--
INSERT into RUTA (ID_RUTA, NOMBRE, DISTANCIA_KM) values ('ruta1a', 'Vigo-Ourense', 95);
INSERT into PARADA (N_PARADA, ID_RUTA, CIUDAD, HORAPREVISTA) values ('1', 'ruta1a', 'Ourense', TO_DATE('08:10:00', 'HH24:MI:SS'));
INSERT into PARADA (N_PARADA, ID_RUTA, CIUDAD, HORAPREVISTA) values ('2', 'ruta1a', 'VIGO', TO_DATE('10:10:00', 'HH24:MI:SS'));

--Cliente persona--
INSERT into CLIENTE (ID_CLIENTE, NOMBRE, TELEFONO) values ('cl001', 'Pedro', 656454343);
INSERT into PERSONA (ID_CLIENTE, DNI, NOMBRE_COMPLETO) values ('cl001', '87654321B', 'Pedro Perez Lopez');

--Cliente empresa-
INSERT into CLIENTE (ID_CLIENTE, NOMBRE, TELEFONO) values ('em001', 'Empresa', 987123456);
INSERT into EMPRESA (ID_CLIENTE, NIF, NOMBREEMPRESA) values ('em001', 'B87654321', 'Empresa abc');

--Envio y paquetes--
INSERT into ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) values ('abc123', '123ab', TO_DATE('2025-10-10', 'YYYY-MM-DD'), 'En camino');
INSERT into PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) values (1, 'abc123', 1000, 'Material peligroso');

--Ejecucion y ejecucion conductor--
INSERT into EJECUCION (ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA) values ('987zy', TO_DATE('2025-10-9', 'YYYY-MM-DD'), 'cam2a', 'ruta1a');
INSERT into EJECUCION_CONDUCTOR (ID_EJECUCION, ID_EMPLEADO) values ('987zy', '1a2b3c');

--Supervisa--
INSERT into SUPERVISA (ID_EMPLEADO_SUPERVISADO, ID_EMPLEADO_SUPERVISOR) values ('2a2b2c', '1a2b3c');