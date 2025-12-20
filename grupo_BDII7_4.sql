--DROPS--
SET AUTOCOMMIT on; 
SET SERVEROUTPUT on;
 
-- Drops entidades
DROP TABLE VEHICULO CASCADE CONSTRAINTS; 
DROP TABLE VEHICULO_REFRIGERADO CASCADE CONSTRAINTS; 
DROP TABLE VEHICULO_ADR CASCADE CONSTRAINTS; 
DROP TABLE GPS CASCADE CONSTRAINTS; 
DROP TABLE PARADA CASCADE CONSTRAINTS; 
DROP TABLE RUTA CASCADE CONSTRAINTS; 
DROP TABLE ENVIO CASCADE CONSTRAINTS; 
DROP TABLE PAQUETE CASCADE CONSTRAINTS; 
DROP TABLE CLIENTE CASCADE CONSTRAINTS; 
DROP TABLE PERSONA CASCADE CONSTRAINTS; 
DROP TABLE EMPRESA CASCADE CONSTRAINTS; 
DROP TABLE EMPLEADO CASCADE CONSTRAINTS; 
DROP TABLE MECANICO CASCADE CONSTRAINTS; 
DROP TABLE ADMINISTRATIVO CASCADE CONSTRAINTS; 
DROP TABLE CONDUCTOR CASCADE CONSTRAINTS; 
-- Drops relaciones
DROP TABLE EJECUCION CASCADE CONSTRAINTS; 
DROP TABLE EJECUCION_CONDUCTOR CASCADE CONSTRAINTS; 
DROP TABLE SUPERVISA CASCADE CONSTRAINTS; 
--Drops vistas--
DROP VIEW VISTA_CLIENTE_PERSONA CASCADE CONSTRAINTS;
DROP VIEW VISTA_CLIENTE CASCADE CONSTRAINTS;
--Drops indices--
DROP INDEX IND_EMPLEADO_DNI;
DROP INDEX IND_EMPLEADO_NOMBRE;
DROP INDEX IND_CONDUCTOR_HORAS;
DROP INDEX IND_FECHA;
DROP INDEX IND_ESTADO;
DROP INDEX IND_EJECUCION_VEHICULO_FECHA;
DROP INDEX IND_EJECUCION_VEHICULO_RUTA;
--Drops funciones y procedimientos--
DROP FUNCTION CalcularHorasTotales;
DROP FUNCTION ObtenerEntregados;
DROP PROCEDURE ListarVehiculosConEntregas;
DROP PROCEDURE ActualizarEnvioAEntregado;
DROP PROCEDURE AsignarConductorAVehiculo;
DROP PROCEDURE RegistrarEjecucionRuta;
DROP FUNCTION ObtenerPesoTotalVehiculo;
DROP FUNCTION ObtenerCantPendienteClientes;
DROP FUNCTION VehiculoDisponible;
--Drops trigger--
DROP TRIGGER TRG_VEHICULO_CAPACIDAD;
DROP TRIGGER TRG_CONDUCTOR_LIMITE_HORAS;
DROP TRIGGER TRG_ENVIO_FECHA_AUTOMATICA;
DROP TRIGGER TRG_VEHICULO_REFRIGERADO_CHECK;
DROP TRIGGER TRG_VEHICULO_ADR_CHECK;

--CREACION TABLAS--
CREATE TABLE GPS
(
	ID_GPS	VARCHAR(9) NOT NULL,
	MODELO 	VARCHAR(10),
	NUM_SERIE	VARCHAR(10),
	PRIMARY KEY (ID_GPS)
);

CREATE TABLE EMPLEADO
(
	ID_EMPLEADO 	VARCHAR(10) NOT NULL,
	TELEFONO		NUMBER(9),
	NOMBRE_COMPLETO VARCHAR(40),
	NSS	VARCHAR(12),
	DNI	VARCHAR(9),
	PRIMARY KEY(ID_EMPLEADO)
);

CREATE TABLE CONDUCTOR
(
	ID_EMPLEADO VARCHAR(10) NOT NULL,
	LICENCIA VARCHAR(10),
	HORAS_SEMANA NUMBER(2),
	PRIMARY KEY (ID_EMPLEADO),
	FOREIGN KEY (ID_EMPLEADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE,
	CHECK(HORAS_SEMANA >= 0)
);

CREATE TABLE MECANICO
(
	ID_EMPLEADO VARCHAR(10) NOT NULL,
	ESPECIALIDAD VARCHAR(40),
    PRIMARY KEY(ID_EMPLEADO),
    FOREIGN KEY (ID_EMPLEADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE
);

CREATE TABLE ADMINISTRATIVO
(
	ID_EMPLEADO VARCHAR(10) NOT NULL,
	DEPARTAMENTO VARCHAR(12),
	PRIMARY KEY (ID_EMPLEADO),
	FOREIGN KEY (ID_EMPLEADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE
);

CREATE TABLE VEHICULO (
    ID_VEHICULO   VARCHAR(5) NOT NULL,
    ID_GPS        VARCHAR(9) NOT NULL,
    ID_EMPLEADO   VARCHAR(10),
    MATRICULA     VARCHAR(7) UNIQUE,
    CAPACIDAD_KG  NUMBER(4),
    PRIMARY KEY (ID_VEHICULO),
    FOREIGN KEY (ID_EMPLEADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE,
    FOREIGN KEY (ID_GPS) REFERENCES GPS(ID_GPS) ON DELETE CASCADE,
	CHECK(CAPACIDAD_KG >= 0)
);

CREATE TABLE VEHICULO_REFRIGERADO(
    ID_VEHICULO	VARCHAR(5) NOT NULL,
    TEMP_MIN 		NUMBER(2),
    TEMP_MAX		NUMBER(2),
    PRIMARY KEY (ID_VEHICULO),
    FOREIGN KEY (ID_VEHICULO) REFERENCES VEHICULO (ID_VEHICULO) ON DELETE CASCADE,
	CHECK(TEMP_MAX>TEMP_MIN)
);

CREATE TABLE VEHICULO_ADR
(
	ID_VEHICULO VARCHAR(5) NOT NULL,
	CLASEMERCANCIA VARCHAR (10),
	PRIMARY KEY(ID_VEHICULO),
	FOREIGN KEY(ID_VEHICULO) REFERENCES VEHICULO (ID_VEHICULO) ON DELETE CASCADE,
	CHECK (CLASEMERCANCIA IN ('1','2','3','4.1','4.2','4.3','5.1','5.2','6.1','6.2','7','8','9'))
);

CREATE TABLE RUTA
(
	ID_RUTA	VARCHAR(8) NOT NULL,
	NOMBRE	VARCHAR(16),
	DISTANCIA_KM NUMBER(4),
	PRIMARY KEY (ID_RUTA),
	CHECK(DISTANCIA_KM>0)
);

CREATE TABLE PARADA
(
	N_PARADA NUMBER(2) NOT NULL,
	ID_RUTA VARCHAR(8) NOT NULL,
	CIUDAD VARCHAR(9),
	HORAPREVISTA DATE,
	PRIMARY KEY(N_PARADA, ID_RUTA),
	FOREIGN KEY(ID_RUTA) REFERENCES RUTA(ID_RUTA) ON DELETE CASCADE
);

CREATE TABLE CLIENTE
(
	ID_CLIENTE VARCHAR(5) NOT NULL,
	NOMBRE VARCHAR(9),
	TELEFONO NUMBER(9),
	PRIMARY KEY(ID_CLIENTE)
);

CREATE TABLE PERSONA
(
	ID_CLIENTE	VARCHAR(5) NOT NULL,
	DNI		VARCHAR(9),
	NOMBRE_COMPLETO	VARCHAR(40),
	PRIMARY KEY(DNI),
	FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE(ID_CLIENTE) ON DELETE CASCADE
);

CREATE TABLE EMPRESA
(
	ID_CLIENTE VARCHAR(5) NOT NULL,
	NIF VARCHAR(9),
	NOMBREEMPRESA VARCHAR(40),
	PRIMARY KEY(NIF),
    FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE(ID_CLIENTE) ON DELETE CASCADE
);

CREATE TABLE ENVIO
(
    ID_ENVIO 	VARCHAR (10) NOT NULL,
    ID_CLIENTE VARCHAR(5) NOT NULL,
    FECHA	DATE,
    ESTADO 	VARCHAR(10)  NOT NULL,
    PRIMARY KEY (ID_ENVIO),
    FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE(ID_CLIENTE) ON DELETE CASCADE,
	CHECK(ESTADO IN ('Entregado','Pendiente','En camino'))
);

CREATE TABLE PAQUETE
(
    N_PAQUETE 	NUMBER(4) NOT NULL,
    ID_ENVIO 		VARCHAR (10) NOT NULL,
    PESO 			NUMBER(5),
    CONTENIDO 		VARCHAR(30),
    PRIMARY KEY (N_PAQUETE,ID_ENVIO),	
    FOREIGN KEY (ID_ENVIO) REFERENCES ENVIO(ID_ENVIO) ON DELETE CASCADE,
	CHECK(N_PAQUETE >= 0 AND PESO >= 0)
);

CREATE TABLE EJECUCION
(
	ID_EJECUCION VARCHAR(5) NOT NULL,
	FECHA_EJECUCION DATE NOT NULL,
	ID_VEHICULO VARCHAR (5) NOT NULL,
	ID_RUTA VARCHAR(8) NOT NULL,
	PRIMARY KEY(ID_EJECUCION),
	FOREIGN KEY (ID_VEHICULO) REFERENCES VEHICULO(ID_VEHICULO) ON DELETE CASCADE,
    FOREIGN KEY (ID_RUTA) REFERENCES RUTA(ID_RUTA) ON DELETE CASCADE
);

CREATE TABLE EJECUCION_CONDUCTOR
(
	ID_EJECUCION VARCHAR(5)  NOT NULL,
    ID_EMPLEADO VARCHAR(10) NOT NULL,
    PRIMARY KEY(ID_EJECUCION, ID_EMPLEADO),
    FOREIGN KEY (ID_EJECUCION) REFERENCES EJECUCION(ID_EJECUCION) ON DELETE CASCADE,
    FOREIGN KEY (ID_EMPLEADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE
);

CREATE TABLE SUPERVISA
(
	ID_EMPLEADO_SUPERVISADO VARCHAR(10) NOT NULL,
	ID_EMPLEADO_SUPERVISOR VARCHAR(10) NOT NULL,
	PRIMARY KEY(ID_EMPLEADO_SUPERVISOR, ID_EMPLEADO_SUPERVISADO),
	FOREIGN KEY (ID_EMPLEADO_SUPERVISOR) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE,
	FOREIGN KEY (ID_EMPLEADO_SUPERVISADO) REFERENCES EMPLEADO(ID_EMPLEADO) ON DELETE CASCADE
);

--CREACION DE VISTAS--

--No actualizable pq daria errores al hacer el update, ya q el sgbd no sabe en q tabla hacer esa actualizacion
CREATE OR REPLACE VIEW VISTA_CLIENTE_PERSONA AS 
    SELECT C.ID_CLIENTE, C.NOMBRE, C.TELEFONO AS TELEFONO, P.DNI AS DNI_PERSONA, P.NOMBRE_COMPLETO AS NOMBRE_COMPLETO
    FROM CLIENTE C, PERSONA P
    WHERE C.ID_CLIENTE = P.ID_CLIENTE;

UPDATE VISTA_CLIENTE_PERSONA
SET TELEFONO = '987654321' 
WHERE DNI_PERSONA = '12345678';

--Actualizable pq en este caso ya seria capaz de hacer esa actualizacio, pq esta trabajando solo con una tabla
CREATE OR REPLACE VIEW VISTA_CLIENTE AS
    SELECT ID_CLIENTE, NOMBRE, TELEFONO
    FROM CLIENTE
    WHERE ID_CLIENTE IN (SELECT ID_CLIENTE FROM ENVIO WHERE ESTADO IN('Pendiente', 'En camino'));

UPDATE VISTA_CLIENTE
SET TELEFONO = '987654321'
WHERE ID_CLIENTE = 'cl001';

--INDICES--
CREATE INDEX IND_EMPLEADO_DNI ON EMPLEADO (DNI);
SELECT *
FROM EMPLEADO
WHERE DNI = '12345678A';

CREATE INDEX IND_EMPLEADO_NOMBRE ON EMPLEADO (NOMBRE_COMPLETO);
SELECT *
FROM EMPLEADO
WHERE NOMBRE_COMPLETO = 'Pepe Lopez Perez';

CREATE INDEX IND_CONDUCTOR_HORAS ON CONDUCTOR (HORAS_SEMANA);
SELECT *
FROM CONDUCTOR
WHERE HORAS_SEMANA > 40;
	
CREATE INDEX IND_FECHA ON ENVIO (FECHA);
SELECT *
FROM ENVIO
WHERE FECHA BETWEEN TO_DATE('2024-12-12', 'YYYY-MM-DD') AND TO_DATE('2025-01-12', YYYY-MM-DD);

CREATE INDEX IND_ESTADO ON ENVIO (ESTADO);
SELECT *
FROM ENVIO
WHERE ESTADO = 'Pendiente';

CREATE INDEX IND_EJECUCION_VEHICULO_FECHA ON EJECUCION (ID_VEHICULO, FECHA_EJECUCION);
SELECT *
FROM EJECUCION
WHERE ID_VEHICULO = 'cam1a' AND FECHA_EJECUCION BETWEEN '2024-12-12' AND '2025-01-12';

CREATE INDEX IND_EJECUCION_VEHICULO_RUTA ON EJECUCION (ID_VEHICULO, ID_RUTA);
SELECT *
FROM EJECUCION
WHERE ID_VEHICULO = 'cam1a' AND ID_RUTA = 'ruta1a';

--INSERTS--

--Insert para empleado conductor 1--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('1a1b1c', 111111111, 'Juanito Fernandez Lopez', '11111111111', '11111111a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('1a1b1c', 'C1', 45);
--Insert para empleado conductor 2--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('2a2b2c', 222222222, 'Alvarito Perez Gomez', '22222222222', '22222222a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('2a2b2c', 'C1', 50);
--Insert para empleado conductor 3--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('3a3b3c', 333333333, 'Manolito Sanchez Lopez', '33333333333', '33333333a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('3a3b3c', 'C1', 35);
--Insert para empleado conductor 4--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('4a4b4c', 444444444, 'Pedro Perez Lopez', '44444444444', '44444444a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('4a4b4c', 'C1', 40);
--Insert para empleado conductor 5--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('5a5b5c', 555555555, 'Fernando Fernandez Fernandez', '55555555555', '55555555a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('5a5b5c', 'C1', 49);
--Insert para empleado conductor 6--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('6a6b6c', 666666666, 'Gonzalo Gonzalez Gonzalez', '66666666666', '66666666a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('6a6b6c', 'C1', 48);
--Insert para empleado conductor 7--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('7a7b7c', 777777777, 'Marta Martinez Martinez', '77777777777', '77777777a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('7a7b7c', 'C1', 50);
--Insert para empleado conductor 8--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('8a8b8c', 888888888, 'Jose Perez Perez', '88888888888', '88888888a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('8a8b8c', 'C1', 46);
--Insert para empleado conductor 9--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('9a9b9c', 999999999, 'Manolito Sanchez Sanchez', '99999999999', '99999999a');
INSERT into CONDUCTOR (ID_EMPLEADO, LICENCIA, HORAS_SEMANA) values ('9a9b9c', 'C1', 44);
--Insert para mecanicos (Tienen horas por defecto)--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('1b1a1c', 121212121, 'Pepito Gonzalez Lopez', '12121212121', '12121212b');
INSERT into MECANICO (ID_EMPLEADO, ESPECIALIDAD) values ('1b1a1c', 'Carroceria');
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('2b2a2c', 232323232, 'Tomas Gonzalez Rodriguez', '23232323232', '23232323b');
INSERT into MECANICO (ID_EMPLEADO, ESPECIALIDAD) values ('2b2a2c', 'Mecanica');
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('3b3a3c', 343434343, 'Juan Perez Lopez', '34343434343', '34343434b');
INSERT into MECANICO (ID_EMPLEADO, ESPECIALIDAD) values ('3b3a3c', 'Electronica');
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('4b4a4c', 454545454, 'Luis Lopez Lopez', '45454545454', '45454545b');
INSERT into MECANICO (ID_EMPLEADO, ESPECIALIDAD) values ('4b4a4c', 'Mecanica');
--Insert para administrativos (Tienen horas por defecto)--
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('1c1b1a', 212121212, 'Menganito Martinez Lopez', '20987654321', '11111111c');
INSERT into ADMINISTRATIVO (ID_EMPLEADO, DEPARTAMENTO) values ('1c1b1a', 'Contabilidad');
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('2c2b2a', 323232323, 'Fulanito Martinez Lopez', '20987654323', '22222222c');
INSERT into ADMINISTRATIVO (ID_EMPLEADO, DEPARTAMENTO) values ('2c2b2a', 'Trafico');
INSERT into EMPLEADO (ID_EMPLEADO, TELEFONO, NOMBRE_COMPLETO, NSS, DNI) values ('3c3b3a', 434343434, 'Pepito Martinez Lopez', '20987654324', '33333333c');
INSERT into ADMINISTRATIVO (ID_EMPLEADO, DEPARTAMENTO) values ('3c3b3a', 'Secretario');

--Vehiculo "normal" sin conductor asignado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps1', 'modelo300', '123abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam1a', 'gps1', NULL, '1234ABC', 7400);
--Vehiculo "normal" con conductor asignado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps2', 'modelo300', '456abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam2a', 'gps2', '1a1b1c', '1234CBA', 7400);
--Vehiculo adr--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps3', 'modelo300', '789abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam3a', 'gps3', '2a2b2c', '1234DCB', 7400);
INSERT into VEHICULO_ADR (ID_VEHICULO, CLASEMERCANCIA) values ('cam3a', '3');
--Vehiculo refrigerado--
INSERT into GPS (ID_GPS, MODELO, NUM_SERIE) values ('gps4', 'modelo300', '147abc');
INSERT into VEHICULO (ID_VEHICULO, ID_GPS, ID_EMPLEADO, MATRICULA, CAPACIDAD_KG) values ('cam4a', 'gps4', '3a3b3c', '1234FCP', 7400);
INSERT into VEHICULO_REFRIGERADO (ID_VEHICULO, TEMP_MIN, TEMP_MAX) values ('cam4a', -5, 5);

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

--Envio 'ejec1' transportado en Ejecución 'ejec1' por 'cam2a'
INSERT into ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) values ('ejec1', 'cl001', TO_DATE('2025-10-10', 'YYYY-MM-DD'), 'En camino');
INSERT into PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) values (1, 'ejec1', 1000, 'Material peligroso');
INSERT into EJECUCION (ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA) values ('ejec1', TO_DATE('2025-10-10', 'YYYY-MM-DD'), 'cam2a', 'ruta1a');
INSERT into EJECUCION_CONDUCTOR (ID_EJECUCION, ID_EMPLEADO) values ('ejec1', '1a1b1c');

--Envio 'ejec2' transportado en Ejecución 'ejec2' por 'cam2a'
INSERT into ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) values ('ejec2', 'cl001', TO_DATE('2025-11-10', 'YYYY-MM-DD'), 'Pendiente');
INSERT into PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) values (1, 'ejec2', 100, 'Material peligroso');
INSERT into EJECUCION (ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA) values ('ejec2', TO_DATE('2025-11-10', 'YYYY-MM-DD'), 'cam2a', 'ruta1a');
INSERT into EJECUCION_CONDUCTOR (ID_EJECUCION, ID_EMPLEADO) values ('ejec2', '2a2b2c');
--Supervisa--
INSERT into SUPERVISA (ID_EMPLEADO_SUPERVISADO, ID_EMPLEADO_SUPERVISOR) values ('2a2b2c', '1a1b1c');

--SENTENCIAS SQL DE COMPROBACION--
-- 1. GPS
SELECT * 
FROM GPS;
-- 2. EMPLEADO
SELECT * 
FROM EMPLEADO;
-- 3. CONDUCTOR
SELECT * 
FROM CONDUCTOR;
-- 4. MECANICO
SELECT * 
FROM MECANICO;
-- 5. ADMINISTRATIVO
SELECT * 
FROM ADMINISTRATIVO;
-- 6. VEHICULO
SELECT * 
FROM VEHICULO;
-- 7. VEHICULO_REFRIGERADO
SELECT * 
FROM VEHICULO_REFRIGERADO;
-- 8. VEHICULO_ADR
SELECT * 
FROM VEHICULO_ADR;
-- 9. RUTA
SELECT * 
FROM RUTA;
-- 10. PARADA
SELECT * 
FROM PARADA;
-- 11. CLIENTE
SELECT * 
FROM CLIENTE;
-- 12. PERSONA
SELECT * 
FROM PERSONA;
-- 13. EMPRESA
SELECT * 
FROM EMPRESA;
-- 14. ENVIO
SELECT * 
FROM ENVIO;
-- 15. PAQUETE
SELECT * 
FROM PAQUETE;
-- 16. EJECUCION
SELECT * 
FROM EJECUCION;
-- 17. EJECUCION_CONDUCTOR
SELECT * 
FROM EJECUCION_CONDUCTOR;
-- 18. SUPERVISA
SELECT *
FROM SUPERVISA;

/*
PL-SQL
*/

CREATE OR REPLACE FUNCTION CalcularHorasTotales RETURN NUMBER IS
	Horas_Totales      NUMBER(8) := 0;
    v_horas            NUMBER(8);
    n_mecanicos        NUMBER(8);
    n_administrativos  NUMBER(8);

	CURSOR c_h_conductores IS
		SELECT COALESCE(HORAS_SEMANA,0) 
		FROM CONDUCTOR;
BEGIN
	SELECT COUNT(*) INTO n_mecanicos
		FROM MECANICO;
	SELECT COUNT(*) INTO n_administrativos
		FROM ADMINISTRATIVO;
	OPEN c_h_conductores;
	LOOP
		FETCH c_h_conductores INTO v_horas;
		EXIT WHEN c_h_conductores%NOTFOUND;
		Horas_Totales := Horas_Totales + v_horas;
	END LOOP;
	CLOSE c_h_conductores;
	Horas_Totales := Horas_Totales + n_mecanicos*40 + n_administrativos*40;
	RETURN Horas_Totales;
END CalcularHorasTotales;
/

CREATE OR REPLACE TYPE t_entregas AS TABLE OF VARCHAR2(20);
/
CREATE OR REPLACE FUNCTION ObtenerEntregados(v_id_cliente IN VARCHAR2) RETURN t_entregas IS
    ID_INVALIDO_EXCEPTION EXCEPTION;
	n_clientes NUMBER(5);
	v_entregas_cliente t_entregas := t_entregas();
    CURSOR c_entregas IS
        SELECT E.ID_ENVIO
        FROM CLIENTE C
        JOIN ENVIO E ON C.ID_CLIENTE = E.ID_CLIENTE
        WHERE C.ID_CLIENTE = v_id_cliente
          AND E.ESTADO = 'Entregado';
    v_id_envio ENVIO.ID_ENVIO%TYPE;
BEGIN
    --existe el cliente?
	SELECT COUNT(*) INTO n_clientes
	FROM CLIENTE
	WHERE ID_CLIENTE = v_id_cliente;
	IF (n_clientes = 0) THEN
		RAISE ID_INVALIDO_EXCEPTION;
	END IF;
    OPEN c_entregas;
    LOOP
        FETCH c_entregas INTO v_id_envio;
        EXIT WHEN c_entregas%NOTFOUND;
        v_entregas_cliente.EXTEND; --aumenta el tamaño del array
        v_entregas_cliente(v_entregas_cliente.COUNT):=v_id_envio; --mete el valor en el array
    END LOOP;
    CLOSE c_entregas;
	RETURN v_entregas_cliente;
EXCEPTION 
	WHEN ID_INVALIDO_EXCEPTION THEN
		RAISE_APPLICATION_ERROR(-20001, 'La ID_Cliente que has puesto no existe');
	WHEN OTHERS THEN
		RAISE;
END ObtenerEntregados;
/

CREATE OR REPLACE PROCEDURE ListarVehiculosConEntregas IS
    CURSOR c_veh IS
        SELECT V.ID_VEHICULO, E.ID_ENVIO, E.ESTADO
        FROM VEHICULO V
        JOIN EJECUCION EJ ON V.ID_VEHICULO = EJ.ID_VEHICULO
        JOIN ENVIO E ON EJ.ID_EJECUCION = E.ID_ENVIO;
    v_id_vehiculo VEHICULO.ID_VEHICULO%TYPE; --crea una variable del mismo tipo que ID_VEHICULO
    v_id_envio ENVIO.ID_ENVIO%TYPE;
    v_estado ENVIO.ESTADO%TYPE;
BEGIN
    OPEN c_veh;
    LOOP
        FETCH c_veh INTO v_id_vehiculo, v_id_envio, v_estado;
        EXIT WHEN c_veh%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            'Vehículo: ' || v_id_vehiculo ||
            ' | Envío: ' || v_id_envio ||
            ' | Estado: ' || v_estado);
    END LOOP;
    CLOSE c_veh;
END ListarVehiculosConEntregas;
/

CREATE OR REPLACE PROCEDURE ActualizarEnvioAEntregado(p_id_envio VARCHAR2) IS
    ID_ENVIO_EXCEPTION EXCEPTION;
    CURSOR c_envio IS
        SELECT ESTADO
        FROM ENVIO
        WHERE ID_ENVIO = p_id_envio
        FOR UPDATE;
    v_estado_actual ENVIO.ESTADO%TYPE;
BEGIN
    OPEN c_envio;
    FETCH c_envio INTO v_estado_actual;
    IF c_envio%FOUND THEN 
        UPDATE ENVIO
        SET ESTADO = 'Entregado'
        WHERE CURRENT OF c_envio;
    ELSE
        RAISE ID_ENVIO_EXCEPTION;
    END IF;
    CLOSE c_envio;
EXCEPTION
    WHEN ID_ENVIO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20008, 'El ID de envío ' || p_id_envio || ' no existe.');
    WHEN OTHERS THEN
        RAISE;
END ActualizarEnvioAEntregado;
/

CREATE OR REPLACE PROCEDURE AsignarConductorAVehiculo(p_id_vehiculo VARCHAR2, p_id_conductor VARCHAR2) IS
    ID_VEHICULO_EXCEPTION EXCEPTION;
    CURSOR c_veh IS
        SELECT ID_EMPLEADO
        FROM VEHICULO
        WHERE ID_VEHICULO = p_id_vehiculo
        FOR UPDATE;
    v_id_empleado_actual VEHICULO.ID_EMPLEADO%TYPE;
BEGIN
    OPEN c_veh;
    FETCH c_veh INTO v_id_empleado_actual;
    IF c_veh%FOUND THEN
        UPDATE VEHICULO
        SET ID_EMPLEADO = p_id_conductor
        WHERE CURRENT OF c_veh;
    ELSE
        RAISE ID_VEHICULO_EXCEPTION;
    END IF;
    CLOSE c_veh;
EXCEPTION
    WHEN ID_VEHICULO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20009, 'El ID de vehículo ' || p_id_vehiculo || ' no existe.');
    WHEN OTHERS THEN
        RAISE;
END AsignarConductorAVehiculo;
/

CREATE OR REPLACE PROCEDURE RegistrarEjecucionRuta(p_id_ejecucion IN VARCHAR2, p_fecha IN DATE, p_id_vehiculo IN VARCHAR2, p_id_ruta IN VARCHAR2) IS
    ID_VEHICULO_EXCEPTION EXCEPTION;
    ID_RUTA_EXCEPTION EXCEPTION;
    v_vehiculo_existe NUMBER := 0;
    v_ruta_existe NUMBER := 0;
    -- Cursor para verificar la existencia del vehículo
    CURSOR c_verif_vehiculo IS
        SELECT 1 FROM VEHICULO WHERE ID_VEHICULO = p_id_vehiculo;
    -- Cursor para verificar la existencia de la ruta
    CURSOR c_verif_ruta IS
        SELECT 1 FROM RUTA WHERE ID_RUTA = p_id_ruta;
BEGIN
    -- Verificar existencia del vehículo con cursor
    OPEN c_verif_vehiculo;
    FETCH c_verif_vehiculo INTO v_vehiculo_existe;
    CLOSE c_verif_vehiculo;
    IF v_vehiculo_existe = 0 THEN
        RAISE ID_VEHICULO_EXCEPTION;
    END IF;
    -- Verificar existencia de la ruta con cursor
    OPEN c_verif_ruta;
    FETCH c_verif_ruta INTO v_ruta_existe;
    CLOSE c_verif_ruta;
    IF v_ruta_existe = 0 THEN
        RAISE ID_RUTA_EXCEPTION;
    END IF;
    -- Si ambos existen, realizar la inserción
    INSERT INTO EJECUCION(ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA)
    VALUES (p_id_ejecucion, p_fecha, p_id_vehiculo, p_id_ruta);
EXCEPTION
    WHEN ID_VEHICULO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20010, 'Error: El vehículo ' || p_id_vehiculo || ' no existe.');
    WHEN ID_RUTA_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20011, 'Error: La ruta ' || p_id_ruta || ' no existe.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error: La ID de Ejecución ' || p_id_ejecucion || ' ya existe.');
    WHEN OTHERS THEN
        RAISE;
END RegistrarEjecucionRuta;
/

--No hace falta cursor pq el peso se calcula directamente con el sum del select--
CREATE OR REPLACE FUNCTION ObtenerPesoTotalVehiculo(v_id_vehiculo IN VARCHAR2) RETURN NUMBER IS
    ID_VEHICULO_EXCEPTION EXCEPTION;
    peso_total NUMBER:=0;
    v_existe NUMBER:=0;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM VEHICULO
    WHERE ID_VEHICULO=v_id_vehiculo;
    --Mira si existe--
    IF v_existe=0 THEN
        RAISE ID_VEHICULO_EXCEPTION;
    END IF;
    --Saca el peso total--
    SELECT NVL(SUM(P.PESO),0) INTO peso_total
    FROM EJECUCION E
    JOIN ENVIO EN ON E.ID_EJECUCION = EN.ID_ENVIO
    JOIN PAQUETE P ON EN.ID_ENVIO = P.ID_ENVIO
    WHERE E.ID_VEHICULO=v_id_vehiculo;
    RETURN peso_total;
EXCEPTION
    WHEN ID_VEHICULO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20002, 'El id del vehiculo no existe');
    WHEN OTHERS THEN
        RAISE;
END ObtenerPesoTotalVehiculo;
/

CREATE OR REPLACE FUNCTION ObtenerCantPendienteClientes(v_id_cliente IN VARCHAR2) RETURN NUMBER IS 
v_cantidad NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_cantidad
    FROM ENVIO
    WHERE ID_CLIENTE = v_id_cliente
      AND ESTADO IN ('Pendiente','En camino');

    RETURN v_cantidad;
END ObtenerCantPendienteClientes;
/

CREATE OR REPLACE FUNCTION VehiculoDisponible(v_id_vehiculo IN VARCHAR2, v_fecha IN DATE) RETURN NUMBER IS
    ID_VEHICULO_EXCEPTION EXCEPTION;    
    v_cont NUMBER := 0;
    v_existe NUMBER:=0;
BEGIN
    --existe?--
    SELECT COUNT(*) INTO v_existe
    FROM VEHICULO
    WHERE ID_VEHICULO=v_id_vehiculo;
    IF v_existe=0 THEN
        RAISE ID_VEHICULO_EXCEPTION;
    END IF;
    --peso--
    SELECT COUNT(*) INTO v_cont
    FROM EJECUCION
    WHERE ID_VEHICULO = v_id_vehiculo
      AND FECHA_EJECUCION = v_fecha;

    IF v_cont > 0 THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
EXCEPTION
    WHEN ID_VEHICULO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20003, 'El id del vehiculo no existe');
    WHEN OTHERS THEN
        RAISE;
END VehiculoDisponible;
/
--bloque pruebas--
DECLARE
    v_entregas_cliente t_entregas;
    v_num NUMBER;
    v_estado VARCHAR2(20);
    v_conductor VARCHAR2(10);
BEGIN
    -------------------------------
    -- 1. ListarVehiculosConEntregas
    -------------------------------
    DBMS_OUTPUT.PUT_LINE('== INICIO PROCEDIMIENTO: ListarVehiculosConEntregas ==');
    BEGIN
        ListarVehiculosConEntregas;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ListarVehiculosConEntregas]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE('== FIN PROCEDIMIENTO: ListarVehiculosConEntregas ==');
    DBMS_OUTPUT.NEW_LINE;

    -------------------------------
    -- 2. ActualizarEnvioAEntregado
    -------------------------------
    DBMS_OUTPUT.PUT_LINE('== INICIO PROCEDIMIENTO: ActualizarEnvioAEntregado ==');
    BEGIN
        ActualizarEnvioAEntregado('ejec1');
        BEGIN
            SELECT ESTADO INTO v_estado FROM ENVIO WHERE ID_ENVIO = 'ejec1';
            DBMS_OUTPUT.PUT_LINE('Estado actualizado para ejec1: ' || v_estado);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No existe el envío ejec1');
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ActualizarEnvioAEntregado]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE('== FIN PROCEDIMIENTO: ActualizarEnvioAEntregado ==');
    DBMS_OUTPUT.NEW_LINE;

    -------------------------------
    -- 3. AsignarConductorAVehiculo
    -------------------------------
    DBMS_OUTPUT.PUT_LINE('== INICIO PROCEDIMIENTO: AsignarConductorAVehiculo ==');
    BEGIN
        AsignarConductorAVehiculo('cam1a', '1a1b1c');
        BEGIN
            SELECT ID_EMPLEADO INTO v_conductor FROM VEHICULO WHERE ID_VEHICULO = 'cam1a';
            DBMS_OUTPUT.PUT_LINE('Conductor asignado a cam1a: ' || v_conductor);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No existe el vehículo cam1a');
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN AsignarConductorAVehiculo]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE('== FIN PROCEDIMIENTO: AsignarConductorAVehiculo ==');
    DBMS_OUTPUT.NEW_LINE;

    -------------------------------
    -- 4. RegistrarEjecucionRuta
    -------------------------------
    DBMS_OUTPUT.PUT_LINE('== INICIO PROCEDIMIENTO: RegistrarEjecucionRuta ==');
    BEGIN
        RegistrarEjecucionRuta('222zy', TO_DATE('2025-12-01','YYYY-MM-DD'), 'cam2a', 'ruta1a');
        SELECT COUNT(*) INTO v_num FROM EJECUCION WHERE ID_EJECUCION = '222zy';
        IF v_num = 1 THEN
            DBMS_OUTPUT.PUT_LINE('Ejecución registrada correctamente: 111zy');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error al registrar ejecución 111zy');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN RegistrarEjecucionRuta]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE('== FIN PROCEDIMIENTO: RegistrarEjecucionRuta ==');
    DBMS_OUTPUT.NEW_LINE;

    -------------------------------
    -- FUNCIONES
    -------------------------------
    BEGIN
        v_num := CalcularHorasTotales;
        DBMS_OUTPUT.PUT_LINE('Horas totales de empleados: ' || v_num);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN CalcularHorasTotales]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;

    BEGIN
        v_entregas_cliente := ObtenerEntregados('cl001');
        DBMS_OUTPUT.PUT_LINE('Cantidad de envíos entregados para cl001: ' || v_entregas_cliente.COUNT);
        FOR i IN 1..v_entregas_cliente.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(' -ID del envio: ' || v_entregas_cliente(i));
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ObtenerEntregados]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;

    BEGIN
        v_num := ObtenerCantPendienteClientes('cl001');
        DBMS_OUTPUT.PUT_LINE('Cantidad de envíos pendientes/en camino para cl001: ' || v_num);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ObtenerCantPendienteClientes]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;

    BEGIN
        v_num := ObtenerPesoTotalVehiculo('cam2a');
        DBMS_OUTPUT.PUT_LINE('Peso total transportado por cam2a: ' || v_num);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ObtenerPesoTotalVehiculo]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;

    BEGIN
        v_num := VehiculoDisponible('cam1a', TO_DATE('2025-10-10','YYYY-MM-DD'));
        IF v_num = 1 THEN
            DBMS_OUTPUT.PUT_LINE('cam1a está disponible el 2025-10-10');
        ELSE
            DBMS_OUTPUT.PUT_LINE('cam21 NO está disponible el 2025-10-10');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN VehiculoDisponible]');
            DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE || ' Mensaje: ' || SQLERRM);
    END;
    DBMS_OUTPUT.NEW_LINE;
    -------------------------------
    -- PRUEBAS DE EXCEPCIONES
    -------------------------------
    BEGIN
        DBMS_OUTPUT.PUT_LINE('== PRUEBA EXCEPCIÓN: Vehiculo no existe ==');
        v_num := VehiculoDisponible('noExiste', SYSDATE);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Se capturó excepción correctamente: ' || SQLERRM);
    END;

    BEGIN
        DBMS_OUTPUT.PUT_LINE('== PRUEBA EXCEPCIÓN: Cliente no existe ==');
        v_entregas_cliente := ObtenerEntregados('noExiste');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Se capturó excepción correctamente: ' || SQLERRM);
    END;

END;
/

/*
TRIGGRES
*/

CREATE OR REPLACE TRIGGER TRG_VEHICULO_CAPACIDAD
BEFORE INSERT OR UPDATE ON PAQUETE
FOR EACH ROW
DECLARE
    v_capacidad_vehiculo VEHICULO.CAPACIDAD_KG%TYPE;
    v_peso_actual_envio NUMBER;
    v_id_vehiculo EJECUCION.ID_VEHICULO%TYPE;
    v_nuevo_peso NUMBER := :NEW.PESO;
BEGIN
    -- 1. Obtener el ID_VEHICULO de la ejecución asociada al ENVIO
    SELECT ID_VEHICULO INTO v_id_vehiculo
    FROM EJECUCION
    WHERE ID_EJECUCION = :NEW.ID_ENVIO;

    -- 2. Obtener la capacidad máxima del vehículo
    SELECT CAPACIDAD_KG INTO v_capacidad_vehiculo
    FROM VEHICULO
    WHERE ID_VEHICULO = v_id_vehiculo;

    -- 3. Calcular el peso total actual del ENVIO (excluyendo o ajustando el registro actual)
    SELECT NVL(SUM(PESO), 0) INTO v_peso_actual_envio
    FROM PAQUETE
    WHERE ID_ENVIO = :NEW.ID_ENVIO
    AND NOT (ID_ENVIO = :NEW.ID_ENVIO AND N_PAQUETE = :NEW.N_PAQUETE);

    -- 4. Verificar la capacidad
    IF (v_peso_actual_envio + v_nuevo_peso) > v_capacidad_vehiculo THEN
        RAISE_APPLICATION_ERROR(-20005, 
            'Error: El peso total (' || (v_peso_actual_envio + v_nuevo_peso) || 
            ' Kg) excede la capacidad del vehículo (' || v_capacidad_vehiculo || ' Kg).');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error de validación: No se encontró la Ejecución/Vehículo para el Envío ' || :NEW.ID_ENVIO);
END;
/


CREATE OR REPLACE TRIGGER TRG_CONDUCTOR_LIMITE_HORAS
BEFORE INSERT OR UPDATE OF HORAS_SEMANA ON CONDUCTOR
FOR EACH ROW
BEGIN
    IF :NEW.HORAS_SEMANA > 50 THEN
        RAISE_APPLICATION_ERROR(-20007, 
            'Error: Las horas semanales de un conductor no pueden exceder las 50 horas (' || :NEW.HORAS_SEMANA || ' h).');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_ENVIO_FECHA_AUTOMATICA
BEFORE INSERT ON ENVIO
FOR EACH ROW
BEGIN
    -- Si la fecha no está especificada, se establece automáticamente a la fecha actual
    IF :NEW.FECHA IS NULL THEN
        :NEW.FECHA := SYSDATE;
        DBMS_OUTPUT.PUT_LINE('Trigger TRG_ENVIO_FECHA_AUTOMATICA: Fecha de envío asignada a SYSDATE.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_VEHICULO_REFRIGERADO_CHECK
BEFORE INSERT ON VEHICULO_REFRIGERADO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Comprobar si el VEHICULO ya existe como VEHICULO_ADR
    SELECT COUNT(*) INTO v_count
    FROM VEHICULO_ADR
    WHERE ID_VEHICULO = :NEW.ID_VEHICULO;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 
            'Error: El vehículo ' || :NEW.ID_VEHICULO || ' ya está registrado como VEHICULO_ADR. No puede ser Refrigerado al mismo tiempo.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VEHICULO_ADR_CHECK
BEFORE INSERT ON VEHICULO_ADR
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Comprobar si el VEHICULO ya existe como VEHICULO_REFRIGERADO
    SELECT COUNT(*) INTO v_count
    FROM VEHICULO_REFRIGERADO
    WHERE ID_VEHICULO = :NEW.ID_VEHICULO;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 
            'Error: El vehículo ' || :NEW.ID_VEHICULO || ' ya está registrado como VEHICULO_REFRIGERADO. No puede ser ADR al mismo tiempo.');
    END IF;
END;
/

-- ====================================================================
-- BLOQUE DE PRUEBAS PARA TRIGGERS (PRACTICA 4)
-- ====================================================================
DECLARE
    v_matricula_temp VEHICULO.MATRICULA%TYPE := '9999XYZ';
    v_id_vehiculo_temp VEHICULO.ID_VEHICULO%TYPE := 'TMP01';
    v_id_gps_temp GPS.ID_GPS%TYPE := 'gpsTMP';
    v_id_envio_temp ENVIO.ID_ENVIO%TYPE := 'ENV_T';
    v_id_paquete_temp PAQUETE.N_PAQUETE%TYPE := 100;
    v_id_conductor_temp CONDUCTOR.ID_EMPLEADO%TYPE := '8a8b8c'; -- 46h
    v_id_conductor_limite CONDUCTOR.ID_EMPLEADO%TYPE := '7a7b7c'; -- 50h
    v_id_cliente_temp CLIENTE.ID_CLIENTE%TYPE := 'cl001';
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '-------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-- INICIO: PRUEBAS DE TRIGGERS SEMÁNTICOS Y AUTOMÁTICOS --');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    -- Preparación para TRG_VEHICULO_CAPACIDAD (Capacidad: 7400 kg)
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- PREPARACION: VEHICULO, GPS y ENVIO TEMPORALES (Capacidad 7400kg) ---');
    INSERT INTO GPS (ID_GPS, MODELO, NUM_SERIE) VALUES (v_id_gps_temp, 'Test', '111SERIE');
    INSERT INTO VEHICULO (ID_VEHICULO, ID_GPS, MATRICULA, CAPACIDAD_KG) VALUES (v_id_vehiculo_temp, v_id_gps_temp, v_matricula_temp, 7400);
    INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_temp, v_id_cliente_temp, SYSDATE, 'Pendiente');
    INSERT INTO EJECUCION (ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA) VALUES (v_id_envio_temp, SYSDATE, v_id_vehiculo_temp, 'ruta1a');
    COMMIT;

    -- ===================================================
    -- PRUEBA 1: TRG_VEHICULO_CAPACIDAD (BEFORE INSERT/UPDATE ON PAQUETE)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 1. TRG_VEHICULO_CAPACIDAD ---');
    
    -- CASO A: Éxito (Inserción de paquete que respeta la capacidad 7400kg)
    BEGIN
        INSERT INTO PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) 
        VALUES (v_id_paquete_temp, v_id_envio_temp, 7000, 'Carga ligera');
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Paquete 7000kg insertado correctamente. Peso total: 7000kg.');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Inserción que excede la capacidad 7400kg)
    BEGIN
        INSERT INTO PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) 
        VALUES (v_id_paquete_temp + 1, v_id_envio_temp, 500, 'Carga pesada');
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20005 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (Capacidad). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;

    -- ===================================================
    -- PRUEBA 2: TRG_CONDUCTOR_LIMITE_HORAS (BEFORE INSERT/UPDATE ON CONDUCTOR)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 2. TRG_CONDUCTOR_LIMITE_HORAS ---');
    
    -- CASO A: Éxito (Actualizar a 50 horas, el límite)
    BEGIN
        UPDATE CONDUCTOR SET HORAS_SEMANA = 50 WHERE ID_EMPLEADO = v_id_conductor_temp; -- Era 46
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Horas de ' || v_id_conductor_temp || ' actualizadas a 50 (límite).');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Actualizar a más de 50 horas)
    BEGIN
        UPDATE CONDUCTOR SET HORAS_SEMANA = 51 WHERE ID_EMPLEADO = v_id_conductor_temp;
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20007 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (Límite de Horas). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;
    
    -- ===================================================
    -- PRUEBA 3: TRG_ENVIO_FECHA_AUTOMATICA (BEFORE INSERT ON ENVIO)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 3. TRG_ENVIO_FECHA_AUTOMATICA ---');
    
    DELETE FROM ENVIO WHERE ID_ENVIO IN ('ENV_AUTO', 'ENV_FIJA');
    
    -- CASO A: Éxito (Insertar sin fecha, debe asignar SYSDATE)
    DECLARE
        v_fecha_check DATE;
        v_id_envio_auto ENVIO.ID_ENVIO%TYPE := 'ENV_AUTO';
    BEGIN
        INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_auto, v_id_cliente_temp, NULL, 'Pendiente');
        SELECT FECHA INTO v_fecha_check FROM ENVIO WHERE ID_ENVIO = v_id_envio_auto;
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Envío insertado. Fecha (esperada SYSDATE): ' || TO_CHAR(v_fecha_check, 'YYYY-MM-DD HH24:MI:SS'));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;
    
    -- CASO B: Éxito (Insertar CON fecha, NO debe cambiarla)
    DECLARE
        v_fecha_check DATE;
        v_fecha_fija DATE := TO_DATE('2023-12-25', 'YYYY-MM-DD');
        v_id_envio_fija ENVIO.ID_ENVIO%TYPE := 'ENV_FIJA';
    BEGIN
        INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_fija, v_id_cliente_temp, v_fecha_fija, 'Pendiente');
        SELECT FECHA INTO v_fecha_check FROM ENVIO WHERE ID_ENVIO = v_id_envio_fija;
        DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Envío insertado. Fecha (esperada 2023): ' || TO_CHAR(v_fecha_check, 'YYYY-MM-DD'));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- ===================================================
    -- PRUEBA 4: TRG_VEHICULO_REFRIGERADO_CHECK / TRG_VEHICULO_ADR_CHECK (BEFORE INSERT)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 4. TRG_REFRIGERADO_ADR\_CHECK ---');
    
    -- CASO A: Éxito (Insertar cam1a como Refrigerado, no es ADR)
    BEGIN
        INSERT INTO VEHICULO_REFRIGERADO (ID_VEHICULO, TEMP_MIN, TEMP_MAX) VALUES ('cam1a', -10, 0);
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] cam1a registrado como Refrigerado (no era ADR).');
        ROLLBACK; -- Para no afectar otros tests
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Insertar cam3a como Refrigerado, YA es ADR)
    BEGIN
        INSERT INTO VEHICULO_REFRIGERADO (ID_VEHICULO, TEMP_MIN, TEMP_MAX) VALUES ('cam3a', -5, 5); -- cam3a ya es ADR
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20008 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (ADR ya existe). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;
    
    -- CASO C: Fallo (Insertar cam4a como ADR, YA es Refrigerado)
    BEGIN
        INSERT INTO VEHICULO_ADR (ID_VEHICULO, CLASEMERCANCIA) VALUES ('cam4a', '9'); -- cam4a ya es Refrigerado
        DBMS_OUTPUT.PUT_LINE('C. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20009 THEN
                DBMS_OUTPUT.PUT_LINE('C. [ÉXITO] Excepción capturada (Refrigerado ya existe). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('C. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;

    -- Limpieza (borrar temporales)
    DELETE FROM EJECUCION WHERE ID_EJECUCION = v_id_envio_temp;
    DELETE FROM ENVIO WHERE ID_ENVIO = v_id_envio_temp;
    DELETE FROM VEHICULO WHERE ID_VEHICULO = v_id_vehiculo_temp;
    DELETE FROM GPS WHERE ID_GPS = v_id_gps_temp;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '-------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-- FIN: PRUEBAS DE TRIGGERS SEMÁNTICOS Y AUTOMÁTICOS --');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
END;
/

