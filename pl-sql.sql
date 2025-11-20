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
    
    CURSOR c_entregas IS
        SELECT E.ID_ENVIO
        FROM CLIENTE C
        JOIN ENVIO E ON C.ID_CLIENTE = E.ID_CLIENTE
        WHERE C.ID_CLIENTE = v_id_cliente
          AND E.ESTADO = 'Entregado';
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
        JOIN EJECUCION EJ ON V.ID_VEHICULO = EJ.ID_VEHICULO
        JOIN ENVIO E ON EJ.ID_EJECUCION = E.ID_ENVIO;
BEGIN
    FOR reg IN c_veh LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Vehículo: ' || reg.ID_VEHICULO ||
            ' | Envío: ' || reg.ID_ENVIO ||
            ' | Estado: ' || reg.ESTADO);
    END LOOP;
END ListarVehiculosConEntregas;
/

CREATE OR REPLACE PROCEDURE ActualizarEnvioAEntregado(p_id_envio VARCHAR2) IS
    CURSOR c_envio IS
        SELECT ESTADO
        FROM ENVIO
        WHERE ID_ENVIO = p_id_envio
        FOR UPDATE;
BEGIN
    FOR reg IN c_envio LOOP
        UPDATE ENVIO
        SET ESTADO = 'Entregado'
        WHERE ID_ENVIO = p_id_envio;
    END LOOP;
END ActualizarEnvioAEntregado;
/


CREATE OR REPLACE PROCEDURE AsignarConductorAVehiculo(p_id_vehiculo  VARCHAR2, p_id_conductor VARCHAR2) IS
    CURSOR c_veh IS
        SELECT ID_EMPLEADO
        FROM VEHICULO
        WHERE ID_VEHICULO = p_id_vehiculo
        FOR UPDATE;
BEGIN
    FOR reg IN c_veh LOOP
        UPDATE VEHICULO
        SET ID_EMPLEADO = p_id_conductor
        WHERE ID_VEHICULO = p_id_vehiculo;
    END LOOP;
END AsignarConductorAVehiculo;
/

CREATE OR REPLACE PROCEDURE RegistrarEjecucionRuta(p_id_ejecucion VARCHAR2, p_fecha DATE, p_id_vehiculo VARCHAR2, p_id_ruta VARCHAR2) IS
    CURSOR c_verif IS
        SELECT ID_VEHICULO
        FROM VEHICULO
        WHERE ID_VEHICULO = p_id_vehiculo
        FOR UPDATE;
BEGIN
    FOR reg IN c_verif LOOP
        INSERT INTO EJECUCION(ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA)
        VALUES (p_id_ejecucion, p_fecha, p_id_vehiculo, p_id_ruta);
    END LOOP;
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
EXCEPTION
    WHEN ID_VEHICULO_EXCEPTION THEN
        RAISE_APPLICATION_ERROR(-20002, 'El id del vehiculo no existe');
    WHEN OTHERS THEN
        RAISE;
RETURN peso_total;
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
        ActualizarEnvioAEntregado('abc124');
        BEGIN
            SELECT ESTADO INTO v_estado FROM ENVIO WHERE ID_ENVIO = 'abc124';
            DBMS_OUTPUT.PUT_LINE('Estado actualizado para abc124: ' || v_estado);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No existe el envío abc124');
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
        RegistrarEjecucionRuta('999zy', TO_DATE('2025-12-01','YYYY-MM-DD'), 'cam2a', 'ruta1a');
        SELECT COUNT(*) INTO v_num FROM EJECUCION WHERE ID_EJECUCION = '999zy';
        IF v_num = 1 THEN
            DBMS_OUTPUT.PUT_LINE('Ejecución registrada correctamente: 999zy');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error al registrar ejecución 999zy');
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
        v_num := VehiculoDisponible('cam2a', TO_DATE('2025-10-10','YYYY-MM-DD'));
        IF v_num = 1 THEN
            DBMS_OUTPUT.PUT_LINE('cam2a está disponible el 2025-10-10');
        ELSE
            DBMS_OUTPUT.PUT_LINE('cam2a NO está disponible el 2025-10-10');
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