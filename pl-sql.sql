/*
Un cursor en PL/SQL es una estructura de control que permite procesar una consulta
SQL fila por fila, ya que maneja un conjunto de resultados. Actúa como un puntero 
que se posiciona sobre cada registro de una consulta SELECT, permitiendo que el 
programa acceda y manipule los datos de cada fila individualmente en un bucle.
*/

SET SERVEROUTPUT on;

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

CREATE OR REPLACE FUNCTION ObtenerCantidadEntregada(v_id_cliente IN VARCHAR2) RETURN NUMBER IS
    ID_INVALIDO_EXCEPTION EXCEPTION;
	n_clientes NUMBER(5);
	v_entregas_cliente NUMBER(6):=0;
    /*CURSOR c_entregas IS
        SELECT E.ID_ENVIO
        FROM CLIENTE C
        JOIN ENVIO E ON C.ID_CLIENTE = E.ID_CLIENTE
        WHERE C.ID_CLIENTE = v_id_cliente
          AND E.ESTADO = 'Entregado';*/
BEGIN
	SELECT COUNT(*) INTO n_clientes
	FROM CLIENTE
	WHERE ID_CLIENTE = v_id_cliente;
	IF (n_clientes = 0) THEN
		RAISE ID_INVALIDO_EXCEPTION;
	END IF;
	SELECT COUNT(*) INTO v_entregas_cliente
	FROM CLIENTE C INNER JOIN ENVIO E ON C.ID_CLIENTE = E.ID_CLIENTE
	WHERE E.ESTADO = 'Entregado' AND C.ID_CLIENTE =  v_id_cliente; 
	RETURN v_entregas_cliente;
EXCEPTION 
	WHEN ID_INVALIDO_EXCEPTION THEN
		RAISE_APPLICATION_ERROR(-20001, 'La ID_Cliente que has puesto no existe');
	WHEN OTHERS THEN
		RAISE;
END ObtenerCantidadEntregada;
/

CREATE OR REPLACE PROCEDURE ListarVehiculosConEntregas IS
    CURSOR c_veh IS
        SELECT V.ID_VEHICULO, E.ID_ENVIO, E.ESTADO
        FROM VEHICULO V
        JOIN EJECUCION EJ ON V.ID_VEHICULO = EJ.ID_VEHICULO  --crea una variable del mismo tipo que ID_VEHICULO
        JOIN ENVIO E ON EJ.ID_EJECUCION = E.ID_ENVIO;
    v_id_vehiculo VEHICULO.ID_VEHICULO%TYPE;
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
        RAISE_APPLICATION_ERROR(-20008, 'El ID de envío ' || p_id_envio || ' no existe.');
    END IF;
    CLOSE c_envio;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END ActualizarEnvioAEntregado;
/


CREATE OR REPLACE PROCEDURE AsignarConductorAVehiculo(p_id_vehiculo VARCHAR2, p_id_conductor VARCHAR2) IS
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
        RAISE_APPLICATION_ERROR(-20009, 'El ID de vehículo ' || p_id_vehiculo || ' no existe.');
    END IF;
    CLOSE c_veh;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END AsignarConductorAVehiculo;
/

CREATE OR REPLACE PROCEDURE RegistrarEjecucionRuta(p_id_ejecucion IN VARCHAR2, p_fecha IN DATE, p_id_vehiculo IN VARCHAR2, p_id_ruta IN VARCHAR2) IS
    v_vehiculo_existe NUMBER := 0;
    v_ruta_existe NUMBER := 0;
    -- Cursor para verificar la existencia del vehículo
    CURSOR c_verif_vehiculo IS
        SELECT 1 FROM VEHICULO WHERE ID_VEHICULO = p_id_vehiculo; --si los id coinciden se coje 1
    -- Cursor para verificar la existencia de la ruta
    CURSOR c_verif_ruta IS
        SELECT 1 FROM RUTA WHERE ID_RUTA = p_id_ruta;
BEGIN
    -- Verificar existencia del vehículo con cursor
    OPEN c_verif_vehiculo;
    FETCH c_verif_vehiculo INTO v_vehiculo_existe;
    CLOSE c_verif_vehiculo; --se cierra aqui pq ya no haria falta despues
    IF v_vehiculo_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Error: El vehículo ' || p_id_vehiculo || ' no existe.');
    END IF;
    -- Verificar existencia de la ruta con cursor
    OPEN c_verif_ruta;
    FETCH c_verif_ruta INTO v_ruta_existe;
    CLOSE c_verif_ruta;
    IF v_ruta_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Error: La ruta ' || p_id_ruta || ' no existe.');
    END IF;
    -- Si ambos existen, realizar la inserción
    INSERT INTO EJECUCION(ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA)
    VALUES (p_id_ejecucion, p_fecha, p_id_vehiculo, p_id_ruta);
EXCEPTION
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
    --esta libre?--
    SELECT COUNT(*) INTO v_cont
    FROM EJECUCION
    WHERE ID_VEHICULO = v_id_vehiculo
      AND FECHA_EJECUCION = v_fecha;

    IF v_cont > 0 THEN
        RETURN 0; --vehiculo ocupado -> no esta libre
    ELSE
        RETURN 1; -- vehiculo libre
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
        v_num := ObtenerCantidadEntregada('cl001');
        DBMS_OUTPUT.PUT_LINE('Cantidad de envíos entregados para cl001: ' || v_num);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ObtenerCantidadEntregada]');
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
        v_num := ObtenerCantidadEntregada('noExiste');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Se capturó excepción correctamente: ' || SQLERRM);
    END;

END;
/










