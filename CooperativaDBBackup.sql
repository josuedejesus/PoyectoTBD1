PGDMP         /                {            Cooperativa    15.4    15.4 X    Y           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            Z           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            [           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            \           1262    16400    Cooperativa    DATABASE     �   CREATE DATABASE "Cooperativa" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Spanish_Honduras.1252';
    DROP DATABASE "Cooperativa";
                postgres    false            ]           0    0    DATABASE "Cooperativa"    ACL     :   GRANT ALL ON DATABASE "Cooperativa" TO "CooperativaUser";
                   postgres    false    3420            �            1255    16911    actualizar_antiguedad() 	   PROCEDURE     �   CREATE PROCEDURE public.actualizar_antiguedad()
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE cuentas
	set antiguedad = antiguedad + 1;
END;
$$;
 /   DROP PROCEDURE public.actualizar_antiguedad();
       public          postgres    false            �            1255    16800 1   actualizar_estado_penalizacion(character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.actualizar_estado_penalizacion(IN p_numero_cuenta character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF p_numero_cuenta IS NOT NULL THEN
		/*UPDATE cuentas
		SET penalizable = false
		WHERE numero_cuenta = p_numero_cuenta;*/
		
		UPDATE cuentas
		SET penalizable = CASE
    		WHEN tipo_cuenta = 'Aportaciones' AND aportacion_mensual >= 200 THEN false
    		WHEN tipo_cuenta = 'Ahorro' AND saldo >= 200 THEN false
    		ELSE true
		END
		WHERE numero_cuenta = p_numero_cuenta;
	ELSE
		UPDATE cuentas
		SET penalizable = CASE
    		WHEN tipo_cuenta = 'Aportaciones' THEN TRUE
    		WHEN tipo_cuenta = 'Ahorro' AND saldo <= 200 THEN true
    		ELSE false
		END;
	END IF;
END;
$$;
 \   DROP PROCEDURE public.actualizar_estado_penalizacion(IN p_numero_cuenta character varying);
       public          postgres    false            �            1255    16791 ,   actualizar_saldo(character varying, numeric) 	   PROCEDURE     k  CREATE PROCEDURE public.actualizar_saldo(IN p_numero_cuenta character varying, IN p_monto numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
	saldo_actual numeric(12,2);
BEGIN
	SELECT saldo
	INTO saldo_actual
	FROM cuentas
	WHERE numero_cuenta = p_numero_cuenta;
	
	UPDATE cuentas
	SET saldo = saldo_actual + p_monto
	WHERE numero_cuenta = p_numero_cuenta;
END;
$$;
 b   DROP PROCEDURE public.actualizar_saldo(IN p_numero_cuenta character varying, IN p_monto numeric);
       public          postgres    false            �            1255    16995 5   actualizar_saldo_prestamo(character varying, numeric) 	   PROCEDURE     �  CREATE PROCEDURE public.actualizar_saldo_prestamo(IN p_codigo_afiliado character varying, IN p_monto numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
	saldo_prestamo numeric(12,2);
	estado_prestamo boolean;
	saldo_nuevo numeric(12,2);
	p_numero_prestamo varchar;
BEGIN
	select numero_prestamo, activo into p_numero_prestamo, estado_prestamo from prestamos where codigo_afiliado = p_codigo_afiliado;
	CASE
		WHEN activo == true THEN
			select saldo into saldo_nuevo from prestamos where numero_prestamo = p_numero_prestamo;
			saldo_nuevo := saldo_nuevo - p_monto;
			update prestamos
			set saldo = saldo_nuevo
			where numero_prestamo = p_numero_prestamo;
			
	END CASE;
END;
$$;
 m   DROP PROCEDURE public.actualizar_saldo_prestamo(IN p_codigo_afiliado character varying, IN p_monto numeric);
       public          postgres    false            
           1255    17030    calcular_dividendos(date) 	   PROCEDURE     �  CREATE PROCEDURE public.calcular_dividendos(IN p_fecha date)
    LANGUAGE plpgsql
    AS $$
DECLARE
	suma_intereses numeric(12,2);
	suma_saldos numeric(12,2);
	porcentaje_participacion numeric(5,2);
	intereses_generados numeric(12,2);
	afiliados_record RECORD;
	p_numero_cuenta varchar;
BEGIN
	
	
	
	SELECT SUM(intereses) INTO suma_intereses
	FROM pagos
	WHERE fecha = p_fecha;
	IF suma_intereses IS NULL THEN
		suma_intereses := 0;
	END IF;

	SELECT SUM(saldo) INTO suma_saldos
	FROM cuentas
	WHERE tipo_cuenta = 'Aportaciones';
	IF suma_saldos IS NULL THEN
		suma_saldos := 0;
	END IF;
	

	FOR afiliados_record IN (
		SELECT
			af.codigo_afiliado AS codigo_afiliado,
			af.primer_nombre AS nombre_afiliado,
			af.primer_apellido AS apellido_afiliado,
			cu.saldo AS saldo_aportaciones,
			cu.numero_cuenta AS numero_cuenta
		FROM afiliados af
		JOIN cuentas cu ON af.codigo_afiliado = cu.codigo_afiliado
		WHERE cu.tipo_cuenta = 'Aportaciones'
	)
	LOOP
		p_numero_cuenta := afiliados_record.numero_cuenta;
		porcentaje_participacion := (afiliados_record.saldo_aportaciones / suma_saldos) * 100;
		intereses_generados := (porcentaje_participacion / 100) * suma_intereses;
		
		INSERT INTO dividendos(
			codigo_afiliado,
			primer_nombre,
			primer_apellido,
			saldo_aportaciones,
			porcentaje_participacion,
			ganancia,
			intereses_generados,
			fecha
		) VALUES (
			afiliados_record.codigo_afiliado,
			afiliados_record.nombre_afiliado,
			afiliados_record.apellido_afiliado,
			afiliados_record.saldo_aportaciones,
			porcentaje_participacion,
			intereses_generados,
			suma_intereses, 
			p_fecha
		);

		UPDATE cuentas
		SET saldo = saldo + intereses_generados
		WHERE numero_cuenta = p_numero_cuenta AND tipo_cuenta = 'Ahorro';
	END LOOP;
END;
$$;
 <   DROP PROCEDURE public.calcular_dividendos(IN p_fecha date);
       public          postgres    false            �            1255    16978 :   crear_abono(character varying, numeric, character varying)    FUNCTION       CREATE FUNCTION public.crear_abono(p_numero_cuenta character varying, p_monto numeric, p_comentario character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	p_codigo_abono varchar(20);
	numero_abonos integer;
	p_fecha date;
BEGIN
	CASE
		WHEN p_monto IS NOT NULL OR p_monto != 0 THEN
			SELECT COUNT(*) INTO numero_abonos FROM abonos WHERE numero_cuenta = p_numero_cuenta;
			p_codigo_abono := p_numero_cuenta || '-' || numero_abonos + 1;
			p_fecha := CURRENT_TIMESTAMP;
			INSERT INTO abonos(
				codigo_abono,
				numero_cuenta,
				monto,
				fecha,
				comentario
			) VALUES(
				p_codigo_abono,
				p_numero_cuenta,
				p_monto,
				p_fecha,
				p_comentario
			);
			
			IF p_monto > 0 THEN
				UPDATE cuentas
				SET aportacion_mensual = aportacion_mensual + p_monto
				WHERE numero_cuenta = p_numero_cuenta;
				CALL actualizar_estado_penalizacion(p_numero_cuenta);
			END IF;
			
			CALL actualizar_saldo(p_numero_cuenta, p_monto);
			
			RETURN true;
		ELSE
			RETURN false;
	END CASE;
	
	
END;
$$;
 v   DROP FUNCTION public.crear_abono(p_numero_cuenta character varying, p_monto numeric, p_comentario character varying);
       public          postgres    false                       1255    17573 @   crear_abono(character varying, numeric, date, character varying)    FUNCTION     �  CREATE FUNCTION public.crear_abono(p_numero_cuenta character varying, p_monto numeric, p_fecha date, p_comentario character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	p_codigo_abono varchar(20);
	numero_abonos integer;
BEGIN
	CASE
		WHEN p_monto IS NOT NULL OR p_monto != 0 THEN
			SELECT COUNT(*) INTO numero_abonos FROM abonos WHERE numero_cuenta = p_numero_cuenta;
			p_codigo_abono := p_numero_cuenta || '-' || numero_abonos + 1;
			INSERT INTO abonos(
				codigo_abono,
				numero_cuenta,
				monto,
				fecha,
				comentario
			) VALUES(
				p_codigo_abono,
				p_numero_cuenta,
				p_monto,
				p_fecha,
				p_comentario
			);
			
			IF p_monto > 0 THEN
				UPDATE cuentas
				SET aportacion_mensual = aportacion_mensual + p_monto
				WHERE numero_cuenta = p_numero_cuenta;
				CALL actualizar_estado_penalizacion(p_numero_cuenta);
			END IF;
			
			CALL actualizar_saldo(p_numero_cuenta, p_monto);
			
			RETURN true;
		ELSE
			RETURN false;
	END CASE;
	
	
END;
$$;
 �   DROP FUNCTION public.crear_abono(p_numero_cuenta character varying, p_monto numeric, p_fecha date, p_comentario character varying);
       public          postgres    false                       1255    17062 �   crear_afiliado(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, date, character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.crear_afiliado(primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, calle character varying, avenida character varying, casa character varying, ciudad character varying, departamento character varying, referencia character varying, fecha_nacimiento date, telefono character varying, correo character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	numero_cuenta_ahorro varchar(20);
	numero_cuenta_aportaciones varchar(20);
	ultimo_numero integer;
	nuevo_codigo varchar(20);
	fecha DATE := CURRENT_TIMESTAMP;
	fecha_ingreso DATE;
BEGIN
	IF primer_nombre IS NULL OR primer_nombre = '' OR
	   segundo_nombre IS NULL OR segundo_nombre = '' OR
	   primer_apellido IS NULL OR primer_apellido = '' OR
	   segundo_apellido IS NULL OR segundo_apellido = '' OR
	   calle IS NULL OR calle = '' OR
	   avenida IS NULL OR avenida = '' OR
	   casa IS NULL OR casa = '' OR
	   ciudad IS NULL OR ciudad = '' OR
	   departamento IS NULL OR departamento = '' OR
	   referencia IS NULL OR referencia = '' OR
	   fecha_nacimiento IS NULL OR
	   telefono IS NULL OR telefono = '' OR
	   correo IS NULL OR correo = '' THEN
	   RETURN false;
	END IF;
	fecha_ingreso := TO_CHAR(fecha, 'DD-MM-YYYY');
	SELECT NEXTVAL('afiliados_sequence') INTO ultimo_numero;
	nuevo_codigo := 'UNIAF-' || lpad((ultimo_numero)::text, 5, '0');
	CALL insertar_afiliado(
		nuevo_codigo,
		primer_nombre,
		segundo_nombre,
		primer_apellido,
		segundo_apellido,
		calle,
		avenida,
		casa, 
		ciudad,
		departamento,
		referencia,
		fecha_nacimiento,
		fecha_ingreso
	);
	
	numero_cuenta_ahorro := substring(nuevo_codigo, length(nuevo_codigo) - 7) || '-CAR';
    numero_cuenta_aportaciones := substring(nuevo_codigo, LENGTH(nuevo_codigo) - 7) || '-CAP';
	CALL insertar_cuenta(numero_cuenta_ahorro, nuevo_codigo, 'Ahorro', fecha_ingreso, 0.00);
	CALL insertar_cuenta(numero_cuenta_aportaciones, nuevo_codigo, 'Aportaciones', fecha_ingreso, 0.00);
	CALL insertar_telefono(nuevo_codigo, telefono);
	CALL insertar_email(nuevo_codigo, correo);
	PERFORM crear_abono(numero_cuenta_ahorro, 200.00, 'Abono Apertura');
	PERFORM crear_abono(numero_cuenta_aportaciones, 200.00, 'Abono Apertura');
	RETURN true;
END;
$$;
 �  DROP FUNCTION public.crear_afiliado(primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, calle character varying, avenida character varying, casa character varying, ciudad character varying, departamento character varying, referencia character varying, fecha_nacimiento date, telefono character varying, correo character varying);
       public          postgres    false                       1255    17020 #   crear_pago(character varying, date) 	   PROCEDURE     +
  CREATE PROCEDURE public.crear_pago(IN p_codigo_afiliado character varying, IN p_fecha date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    p_numero_pago varchar;
    ultimo_numero integer;
    p_numero_prestamo varchar;
    p_capital numeric(12, 2);
    p_saldo numeric(12, 2);
    p_intereses numeric(4, 2);
    p_monto_prestamo numeric(12, 2);
    p_monto numeric(12, 2);
    p_periodos integer;
    p_interes_mensual numeric(4, 2);
    p_interes_valor numeric(12, 2);
	c_saldo numeric(12, 2);
	p_numero_cuenta varchar(20);
BEGIN
    SELECT numero_prestamo, monto, interes, periodos, saldo
    INTO p_numero_prestamo, p_monto_prestamo, p_intereses, p_periodos, p_saldo
    FROM prestamos
    WHERE codigo_afiliado = p_codigo_afiliado AND saldo != 0;
	
	SELECT saldo INTO c_saldo
	FROM cuentas
	WHERE codigo_afiliado = p_codigo_afiliado AND tipo_cuenta = 'Ahorro';

    SELECT COUNT(*) INTO ultimo_numero
    FROM pagos
    WHERE numero_prestamo = p_numero_prestamo;
    p_numero_pago := lpad((ultimo_numero + 1)::text, 5, '0');

    p_interes_mensual := p_intereses / 12;
    p_monto := (p_monto_prestamo * p_interes_mensual * (1 + p_interes_mensual)^p_periodos) / (((1 + p_interes_mensual)^p_periodos) - 1);
    p_capital := p_monto_prestamo * p_interes_mensual * (1 + p_interes_mensual)^(p_periodos - (ultimo_numero + 1)) / (((1 + p_interes_mensual)^p_periodos) - 1);
    p_interes_valor := p_monto - p_capital;
	p_saldo := p_saldo - p_capital;

    INSERT INTO pagos(
        numero_pago,
        numero_prestamo,
        fecha,
        monto,
        intereses,
        capital,
		saldo
    ) VALUES (
        p_numero_pago,
        p_numero_prestamo,
        p_fecha,
        p_monto,
        p_interes_valor,
        p_capital,
		p_saldo
    );

	CASE
    WHEN p_monto < c_saldo THEN
        /*UPDATE cuentas
        SET saldo = saldo - p_monto
        WHERE codigo_afiliado = p_codigo_afiliado AND tipo_cuenta = 'Ahorro';*/
		SELECT numero_cuenta INTO p_numero_cuenta FROM cuentas WHERE codigo_afiliado = p_codigo_afiliado AND tipo_cuenta = 'Ahorro';
		PERFORM retirar(p_numero_cuenta, p_monto, p_fecha, 'Debito Prestamo');
	ELSE
		/*UPDATE cuentas
    	SET saldo = saldo - p_monto
    	WHERE codigo_afiliado = p_codigo_afiliado AND tipo_cuenta = 'Aportaciones';*/
		SELECT numero_cuenta INTO p_numero_cuenta FROM cuentas WHERE codigo_afiliado = p_codigo_afiliado AND tipo_cuenta = 'Aportaciones';
		PERFORM retirar(p_numero_cuenta, p_monto, p_fecha, 'Debito Prestamo');
    END CASE;

    UPDATE prestamos
    SET saldo = saldo - p_capital
    WHERE numero_prestamo = p_numero_prestamo;

END;
$$;
 [   DROP PROCEDURE public.crear_pago(IN p_codigo_afiliado character varying, IN p_fecha date);
       public          postgres    false            �            1255    17345     crear_periodo(character varying)    FUNCTION     �  CREATE FUNCTION public.crear_periodo(f_fecha_periodo character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
	periodo varchar;
begin
	select fecha_periodo into periodo from periodos_cerrados where fecha_periodo = f_fecha_periodo;
	if periodo is null then
		insert into periodos_cerrados(fecha_periodo) values(f_fecha_periodo);
		return true;
	else
		return false;
	end if;
end;
$$;
 G   DROP FUNCTION public.crear_periodo(f_fecha_periodo character varying);
       public          postgres    false            �            1255    16957 "   existe_prestamo(character varying)    FUNCTION     7  CREATE FUNCTION public.existe_prestamo(f_codigo_afiliado character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	numero_prestamos integer;
BEGIN
	SELECT COUNT(*) INTO numero_prestamos
	FROM prestamos
	WHERE codigo_afiliado = f_codigo_afiliado AND saldo > 0;
	RETURN numero_prestamos;
END
$$;
 K   DROP FUNCTION public.existe_prestamo(f_codigo_afiliado character varying);
       public          postgres    false            �            1255    17347    fin_de_mes(date)    FUNCTION     �  CREATE FUNCTION public.fin_de_mes(p_fecha date) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 
	mes integer;
	ano integer;
	dia integer;
	fecha varchar;
	periodo varchar;
BEGIN	
	
	mes := EXTRACT(MONTH FROM p_fecha);
	ano := EXTRACT(YEAR FROM p_fecha);
	periodo := TO_CHAR(p_fecha, 'yyyy-MM-dd');
	
	SELECT fecha_periodo INTO fecha FROM periodos_cerrados WHERE fecha_periodo = periodo;
	
	IF fecha IS NULL THEN
		PERFORM crear_periodo(periodo);
		UPDATE cuentas
		SET aportacion_mensual = 0;
		CALL actualizar_antiguedad();
		CALL penalizar(p_fecha);
		CALL actualizar_estado_penalizacion();
		CALL prestamos_fin_de_mes(p_fecha);
		CALL calcular_dividendos(p_fecha);
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$;
 /   DROP FUNCTION public.fin_de_mes(p_fecha date);
       public          postgres    false                       1255    17414 6   generar_debito(character varying, numeric, date, text) 	   PROCEDURE     �  CREATE PROCEDURE public.generar_debito(IN f_numero_cuenta character varying, IN f_monto numeric, IN f_fecha_actual date, IN comentario text)
    LANGUAGE plpgsql
    AS $$
DECLARE
	f_numero_retiros integer;
	f_codigo_retiro varchar(20);
BEGIN
	SELECT COUNT(*) INTO f_numero_retiros FROM retiros where numero_cuenta = f_numero_cuenta;
	f_codigo_retiro := f_numero_cuenta || '-' || 'DEB' || '-' || f_numero_retiros + 1;
	    
    CALL actualizar_saldo(f_numero_cuenta, f_monto);
	insert into retiros(
		codigo_retiro,
		numero_cuenta,
		monto,
		fecha,
		comentario
	) values(
		f_codigo_retiro,
		f_numero_cuenta,
		f_monto,
		f_fecha_actual,
		comentario
	);
END;
$$;
 �   DROP PROCEDURE public.generar_debito(IN f_numero_cuenta character varying, IN f_monto numeric, IN f_fecha_actual date, IN comentario text);
       public          postgres    false                       1255    17415 4   generar_estado_cuenta(character varying, date, date)    FUNCTION     �  CREATE FUNCTION public.generar_estado_cuenta(f_numero_cuenta character varying, fecha_inicio date, fecha_fin date) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	numero_cuenta_aportaciones varchar(20);
	numero_cuenta_ahorro varchar(20);
BEGIN
	/*SELECT numero_cuenta INTO numero_cuenta_aportaciones
	FROM cuentas WHERE codigo_afiliado = f_codigo_afiliado AND tipo_cuenta = 'Aportaciones';
	
	SELECT numero_cuenta INTO numero_cuenta_ahorro
	FROM cuentas WHERE codigo_afiliado = f_codigo_afiliado AND tipo_cuenta = 'Ahorro';*/

    RETURN (
        SELECT json_agg(
            json_build_object(
                'codigo', a.codigo_abono,
                'numero_cuenta', a.numero_cuenta,
                'monto', a.monto,
                'fecha', a.fecha,
                'comentario', a.comentario
            )
        )
        FROM (
			SELECT codigo_abono, numero_cuenta, monto, fecha, comentario
    		FROM abonos
    		WHERE numero_cuenta = f_numero_cuenta
    		AND fecha >= fecha_inicio AND fecha <= fecha_fin

    		UNION ALL

    		SELECT codigo_retiro, numero_cuenta, monto, fecha, comentario
    		FROM retiros
    		WHERE numero_cuenta = f_numero_cuenta
    		AND fecha >= fecha_inicio AND fecha <= fecha_fin

    		/*UNION ALL

    		SELECT codigo_abono, numero_cuenta, monto, fecha, comentario
    		FROM abonos
    		WHERE numero_cuenta = numero_cuenta_ahorro
    		AND fecha >= fecha_inicio AND fecha <= fecha_fin

    		UNION ALL

    		SELECT codigo_retiro, numero_cuenta, monto, fecha, comentario
    		FROM retiros
    		WHERE numero_cuenta = numero_cuenta_ahorro
    		AND fecha >= fecha_inicio AND fecha <= fecha_fin*/
		) AS a
    );
END;
$$;
 r   DROP FUNCTION public.generar_estado_cuenta(f_numero_cuenta character varying, fecha_inicio date, fecha_fin date);
       public          postgres    false            �            1255    17351 &   generar_reporte_dividendos(date, date)    FUNCTION     �  CREATE FUNCTION public.generar_reporte_dividendos(fecha_inicio date, fecha_fin date) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (
        SELECT json_agg(
            json_build_object(
                'codigo_afiliado', d.codigo_afiliado,
                'ganancia_total', d.ganancia_total,
                'detalle', d.detalle
            )
        )
        FROM (
            SELECT
                codigo_afiliado,
                SUM(ganancia) AS ganancia_total,
                json_agg(
                    json_build_object(
                        'fecha', fecha,
                        'primer_nombre', primer_nombre,
                        'primer_apellido', primer_apellido,
                        'saldo_aportaciones', saldo_aportaciones,
                        'porcentaje_participacion', porcentaje_participacion,
                        'ganancia', ganancia
                    )
                ) AS detalle
            FROM dividendos
            WHERE fecha >= fecha_inicio AND fecha <= fecha_fin AND ganancia != 0
            GROUP BY codigo_afiliado
            ORDER BY codigo_afiliado
        ) AS d
    );
END;
$$;
 T   DROP FUNCTION public.generar_reporte_dividendos(fecha_inicio date, fecha_fin date);
       public          postgres    false            �            1255    16723 �   insertar_afiliado(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, date, date) 	   PROCEDURE     �  CREATE PROCEDURE public.insertar_afiliado(IN codigo_afiliado character varying, IN primer_nombre character varying, IN segundo_nombre character varying, IN primer_apellido character varying, IN segundo_apellido character varying, IN calle character varying, IN avenida character varying, IN casa character varying, IN ciudad character varying, IN departamento character varying, IN referencia character varying, IN fecha_nacimiento date, IN fecha_ingreso date)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO afiliados(
		codigo_afiliado,
		primer_nombre,
		segundo_nombre,
		primer_apellido,
		segundo_apellido,
		calle,
		avenida,
		casa,
		ciudad,
		departamento,
		referencia,
		fecha_nacimiento,
		fecha_ingreso,
		activo
	) VALUES (
		codigo_afiliado,
		primer_nombre,
		segundo_nombre,
		primer_apellido,
		segundo_apellido,
		calle,
		avenida,
		casa,
		ciudad,
		departamento,
		referencia,
		fecha_nacimiento,
		fecha_ingreso,
		true
	);
END;
$$;
 �  DROP PROCEDURE public.insertar_afiliado(IN codigo_afiliado character varying, IN primer_nombre character varying, IN segundo_nombre character varying, IN primer_apellido character varying, IN segundo_apellido character varying, IN calle character varying, IN avenida character varying, IN casa character varying, IN ciudad character varying, IN departamento character varying, IN referencia character varying, IN fecha_nacimiento date, IN fecha_ingreso date);
       public          postgres    false            �            1255    16738 W   insertar_cuenta(character varying, character varying, character varying, date, numeric) 	   PROCEDURE     �  CREATE PROCEDURE public.insertar_cuenta(IN numero_cuenta character varying, IN codigo_afiliado character varying, IN tipo_cuenta character varying, IN fecha_apertura date, IN saldo numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO cuentas(
		numero_cuenta,
		codigo_afiliado,
		tipo_cuenta,
		fecha_apertura,
		saldo,
		antiguedad,
		penalizable,
		aportacion_mensual
	) VALUES (
		numero_cuenta,
		codigo_afiliado,
		tipo_cuenta,
		fecha_apertura,
		saldo,
		0,
		false,
		0.00
	);
END;
$$;
 �   DROP PROCEDURE public.insertar_cuenta(IN numero_cuenta character varying, IN codigo_afiliado character varying, IN tipo_cuenta character varying, IN fecha_apertura date, IN saldo numeric);
       public          postgres    false            �            1255    16699 4   insertar_email(character varying, character varying) 	   PROCEDURE     �   CREATE PROCEDURE public.insertar_email(IN codigo_afiliado character varying, IN correo character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO correos(
		codigo_afiliado,
		correo
	) values (
		codigo_afiliado,
		correo
	);
END;
$$;
 i   DROP PROCEDURE public.insertar_email(IN codigo_afiliado character varying, IN correo character varying);
       public          postgres    false            �            1255    16704 7   insertar_telefono(character varying, character varying) 	   PROCEDURE       CREATE PROCEDURE public.insertar_telefono(IN codigo_afiliado character varying, IN telefono character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO telefonos(
		codigo_afiliado,
		telefono
	) VALUES (
		codigo_afiliado,
		telefono
	);
END;
$$;
 n   DROP PROCEDURE public.insertar_telefono(IN codigo_afiliado character varying, IN telefono character varying);
       public          postgres    false            �            1255    16954 5   limite_prestamo(character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.limite_prestamo(f_codigo_afiliado character varying, f_tipo_prestamo character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    saldo_aportaciones NUMERIC;
    limite_monto NUMERIC(12,2);
BEGIN
    CASE 
        WHEN f_tipo_prestamo = 'Automatico' THEN
            SELECT saldo INTO saldo_aportaciones 
            FROM cuentas
            WHERE codigo_afiliado = f_codigo_afiliado AND tipo_cuenta = 'Aportaciones';
            limite_monto := saldo_aportaciones * 0.90;
        WHEN f_tipo_prestamo = 'Fiduciario' THEN
            limite_monto := 20000;
    END CASE;
    RETURN limite_monto;
END
$$;
 n   DROP FUNCTION public.limite_prestamo(f_codigo_afiliado character varying, f_tipo_prestamo character varying);
       public          postgres    false            �            1255    17059 ,   liquidacion_parcial(character varying, date)    FUNCTION     �  CREATE FUNCTION public.liquidacion_parcial(f_codigo_afiliado character varying, f_fecha date) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
	saldo_ahorros numeric(12,2);
	mes integer;
	dia integer;
	f_tiene_prestamo boolean;
	f_numero_cuenta varchar;
	existe_cierre integer;
begin
	select extract(month from f_fecha) into mes;
	select extract(day from f_fecha) into dia;
	select numero_cuenta into f_numero_cuenta from cuentas where codigo_afiliado = f_codigo_afiliado and tipo_cuenta = 'Ahorro';
	select saldo into saldo_ahorros from cuentas where numero_cuenta = f_numero_cuenta;
	select existe_prestamo(f_codigo_afiliado) into f_tiene_prestamo;
	saldo_ahorros := saldo_ahorros;
	
	select count(*) into existe_cierre from periodos_cerrados;
	
	case 
		when mes = 12 and dia = 31 and existe_cierre > 0 then
			perform retirar(f_numero_cuenta, saldo_ahorros, f_fecha, 'Liquidación');
			return true;
		else
			return false;
	end case;
end;
$$;
 ]   DROP FUNCTION public.liquidacion_parcial(f_codigo_afiliado character varying, f_fecha date);
       public          postgres    false            �            1255    17057 $   liquidacion_total(character varying)    FUNCTION        CREATE FUNCTION public.liquidacion_total(f_codigo_afiliado character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
	saldo_ahorros numeric(12,2);
	saldo_aportaciones numeric(12,2);
	tiene_prestamo boolean;
begin
	select saldo into saldo_ahorros from cuentas where codigo_afiliado = f_codigo_afiliado and tipo_cuenta = 'Ahorro';
	select saldo into saldo_aportaciones from cuentas where codigo_afiliado = f_codigo_afiliado and tipo_cuenta = 'Aportaciones';
	saldo_ahorros := saldo_ahorros * -1;
	saldo_aportaciones := saldo_aportaciones * -1;
	select existe_prestamo(f_codigo_afiliado) into tiene_prestamo;
	
	if tiene_prestamo = false then
		update cuentas
		set saldo = saldo + saldo_ahorros where codigo_afiliado = f_codigo_afiliado and tipo_cuenta = 'Ahorro';
		update cuentas
		set saldo = saldo + saldo_aportaciones where codigo_afiliado = f_codigo_afiliado and tipo_cuenta = 'Aportaciones';
		
		update afiliados
		set activo = false
		where codigo_afiliado = f_codigo_afiliado;
		return true;
	else
		return false;
	end if;
end;
$$;
 M   DROP FUNCTION public.liquidacion_total(f_codigo_afiliado character varying);
       public          postgres    false            �            1255    17041 F   nuevo_prestamo(character varying, character varying, numeric, integer)    FUNCTION     �  CREATE FUNCTION public.nuevo_prestamo(f_codigo_afiliado character varying, f_tipo_prestamo character varying, f_monto numeric, f_periodos integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    fecha date;
    ultimo_numero integer;
    numero_prestamo varchar;
	saldo_cuenta numeric(12,2);
    limite_prestamo numeric;
    interes numeric(4,2);
    tiene_prestamo integer;
	f_tipo_cuenta varchar;
BEGIN
    --SELECT COUNT(*) INTO ultimo_numero FROM prestamos;
	SELECT NEXTVAL('prestamos_sequence') INTO ultimo_numero;
	
    numero_prestamo := substring(f_codigo_afiliado, LENGTH(f_codigo_afiliado) - 7) || '-PT' || lpad((ultimo_numero)::text, 5, '0');
    SELECT existe_prestamo(f_codigo_afiliado) INTO tiene_prestamo;
	
	CASE
		WHEN f_tipo_prestamo = 'Automatico' THEN
			interes = 0.12;
			f_tipo_cuenta = 'Aportaciones';
		WHEN f_tipo_prestamo = 'Fiduciario' THEN
			interes = 0.16;
			f_tipo_cuenta = 'Ahorro';
	END CASE;
	
	SELECT saldo 
	INTO saldo_cuenta 
	FROM cuentas
	WHERE codigo_afiliado = f_codigo_afiliado AND tipo_cuenta = f_tipo_cuenta;
	
	CASE
		WHEN f_tipo_cuenta = 'Aportaciones' AND f_monto > saldo_cuenta * 0.90 OR f_tipo_cuenta = 'Ahorro' AND f_monto > 20000 THEN
			RETURN false;
		ELSE
			CASE
        WHEN tiene_prestamo = 0 THEN
            INSERT INTO prestamos(
                numero_prestamo,
                codigo_afiliado,
                tipo_prestamo,
                fecha,
                monto,
                periodos,
                saldo,
                interes,
                activo
            ) VALUES (
                numero_prestamo,
                f_codigo_afiliado,
                f_tipo_prestamo,
                current_date,
                f_monto,
                f_periodos,
                f_monto,
                interes,
                true
            );
            RETURN true;
        ELSE
            RETURN false;
    END CASE;
	END CASE;
END
$$;
 �   DROP FUNCTION public.nuevo_prestamo(f_codigo_afiliado character varying, f_tipo_prestamo character varying, f_monto numeric, f_periodos integer);
       public          postgres    false                        1255    16909 #   obtener_afiliado(character varying)    FUNCTION     J  CREATE FUNCTION public.obtener_afiliado(codigo character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (
        SELECT json_agg(
            json_build_object(
                'codigo_afiliado', a.codigo_afiliado,
                'primer_nombre', a.primer_nombre,
                'segundo_nombre', a.segundo_nombre,
                'primer_apellido', a.primer_apellido,
                'segundo_apellido', a.segundo_apellido,
                'calle', a.calle,
                'avenida', a.avenida,
                'casa', a.casa,
                'ciudad', a.ciudad,
                'departamento', a.departamento,
                'referencia', a.referencia,
                'fecha_nacimiento', a.fecha_nacimiento,
                'fecha_ingreso', a.fecha_ingreso,
                'antiguedad', c.antiguedad,
                'numero_cuenta', c.numero_cuenta,
                'tipo_cuenta', c.tipo_cuenta,
                'saldo', c.saldo,
                'estado', a.activo,
                'numero_prestamo', p.numero_prestamo,
                'monto_prestamo', p.monto,
                'saldo_prestamo', p.saldo
            )
        )
        FROM afiliados a
        LEFT JOIN cuentas c ON a.codigo_afiliado = c.codigo_afiliado
        LEFT JOIN (
            SELECT DISTINCT ON (codigo_afiliado) codigo_afiliado, numero_prestamo, monto, saldo
            FROM prestamos
            WHERE saldo > 0
            ORDER BY codigo_afiliado, fecha DESC
        ) AS p ON a.codigo_afiliado = p.codigo_afiliado
        WHERE a.codigo_afiliado = codigo AND a.activo = true 
    );
END;
$$;
 A   DROP FUNCTION public.obtener_afiliado(codigo character varying);
       public          postgres    false            �            1255    17028    obtener_dividendos(date)    FUNCTION     �  CREATE FUNCTION public.obtener_dividendos(p_fecha date) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare
		suma_monto numeric(12,2);
		suma_intereses numeric(12,2);
		prestamo_record RECORD;
		numero_prestamo varchar;
	begin
		RETURN (SELECT json_agg(json_build_object(
		'nombre_afiliado', nombre_afiliado,
		'apellido_afiliado', apellido_afiliado,
		'saldo_aportaciones', saldo_aportaciones,
		'porcentaje_participacion', porcentaje_participacion,
		'ganancia', intereses_mes_actual,
		'intereses_generados', intereses_generados
		)) AS resultado_json
		FROM (
			SELECT d.primer_nombre AS nombre_afiliado, d.primer_apellido AS apellido_afiliado,
			d.saldo_aportaciones AS saldo_aportaciones , d.porcentaje_participacion AS porcentaje_participacion,
			d.ganancia AS intereses_mes_actual, d.intereses_generados AS intereses_generados
			FROM dividendos d
			WHERE fecha = p_fecha
		) AS subconsulta);
	end;
	
$$;
 7   DROP FUNCTION public.obtener_dividendos(p_fecha date);
       public          postgres    false                       1255    17417 8   obtener_estado_dividendos(character varying, date, date)    FUNCTION     y  CREATE FUNCTION public.obtener_estado_dividendos(f_codigo_afiliado character varying, fecha_inicio date, fecha_fin date) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare
		suma_monto numeric(12,2);
		suma_intereses numeric(12,2);
		prestamo_record RECORD;
		numero_prestamo varchar;
	begin
		RETURN (SELECT json_agg(json_build_object(
		'fecha', fecha,
		'ganancia', ganancia
		)) AS resultado_json
		FROM (
			SELECT 
			d.fecha AS fecha, d.ganancia AS ganancia
			FROM dividendos d
			WHERE codigo_afiliado = f_codigo_afiliado AND fecha >= fecha_inicio AND fecha <= fecha_fin AND ganancia != 0
		) AS subconsulta);
	end;
	
$$;
 x   DROP FUNCTION public.obtener_estado_dividendos(f_codigo_afiliado character varying, fecha_inicio date, fecha_fin date);
       public          postgres    false                       1255    17484 7   obtener_estado_prestamos(character varying, date, date)    FUNCTION     �  CREATE FUNCTION public.obtener_estado_prestamos(f_codigo_afiliado character varying, fecha_inicio date, fecha_fin date) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare
		suma_monto numeric(12,2);
		suma_intereses numeric(12,2);
		prestamo_record RECORD;
		f_numero_prestamo varchar;
	begin
		SELECT numero_prestamo INTO f_numero_prestamo
		FROM prestamos WHERE codigo_afiliado = f_codigo_afiliado AND fecha >= fecha_inicio AND fecha <= fecha_fin;
		RETURN (SELECT json_agg(json_build_object(
		'numero_pago', numero_pago,
		'numero_prestamo', numero_prestamo,
		'fecha', fecha,
		'monto', monto,
		'interes', intereses,
		'capital', capital,
		'saldo', saldo
		)) AS resultado_json
		FROM (
			SELECT 
			p.numero_pago AS numero_pago, p.numero_prestamo AS numero_prestamo, p.fecha AS fecha, p.monto AS monto, p.intereses AS intereses, p.capital AS capital, p.saldo AS saldo
			FROM pagos p
			WHERE numero_prestamo = f_numero_prestamo AND fecha >= fecha_inicio AND fecha <= fecha_fin
		) AS subconsulta);
	end;
	
$$;
 w   DROP FUNCTION public.obtener_estado_prestamos(f_codigo_afiliado character varying, fecha_inicio date, fecha_fin date);
       public          postgres    false            	           1255    17597    obtener_fecha_actual()    FUNCTION     �  CREATE FUNCTION public.obtener_fecha_actual() RETURNS date
    LANGUAGE plpgsql
    AS $$
declare
	ultimo_periodo varchar;
begin
	SELECT CASE 
    WHEN EXTRACT(MONTH FROM ultima_fecha) = 12 THEN DATE_TRUNC('YEAR', ultima_fecha) + INTERVAL '1 YEAR'
    ELSE DATE_TRUNC('MONTH', ultima_fecha) + INTERVAL '1 MONTH'
	END INTO ultimo_periodo
	FROM (
    	SELECT MAX(TO_DATE(fecha_periodo, 'YYYY-MM-DD')) AS ultima_fecha
    	FROM periodos_cerrados
		
	) AS subconsulta;
	RETURN ultimo_periodo;
end;
$$;
 -   DROP FUNCTION public.obtener_fecha_actual();
       public          postgres    false                       1255    17017    penalizar(date) 	   PROCEDURE     �  CREATE PROCEDURE public.penalizar(IN p_fecha date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cuenta RECORD;
BEGIN
    FOR v_cuenta IN
        SELECT c.numero_cuenta
        FROM cuentas c
        JOIN afiliados a ON c.codigo_afiliado = a.codigo_afiliado
        WHERE c.penalizable = true AND a.activo = true
    LOOP
        BEGIN
            /*UPDATE cuentas
            SET saldo = saldo - 10
            WHERE numero_cuenta = v_cuenta.numero_cuenta;*/
			
			CALL generar_debito(v_cuenta.numero_cuenta, -10, p_fecha, 'Penalización');
			
            INSERT INTO penalizaciones(numero_cuenta, fecha, monto)
            VALUES(v_cuenta.numero_cuenta, p_fecha, -10);
     
        END;
    END LOOP;
END;
$$;
 2   DROP PROCEDURE public.penalizar(IN p_fecha date);
       public          postgres    false                       1255    17021    prestamos_fin_de_mes(date) 	   PROCEDURE     >  CREATE PROCEDURE public.prestamos_fin_de_mes(IN p_fecha date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    prestamo_record RECORD;
BEGIN
    FOR prestamo_record IN (SELECT codigo_afiliado FROM prestamos WHERE saldo > 0) 
    LOOP
        CALL crear_pago(prestamo_record.codigo_afiliado, p_fecha);
    END LOOP;
END;
$$;
 =   DROP PROCEDURE public.prestamos_fin_de_mes(IN p_fecha date);
       public          postgres    false                       1255    17039 /   retirar(character varying, numeric, date, text)    FUNCTION     �  CREATE FUNCTION public.retirar(f_numero_cuenta character varying, f_monto numeric, f_fecha_actual date, comentario text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    f_saldo_cuenta numeric(12,2);
	f_mes_actual integer;
	f_tipo_cuenta varchar(20);
	f_numero_retiros integer;
	f_codigo_retiro varchar(20);
BEGIN
	SELECT COUNT(*) INTO f_numero_retiros FROM retiros where numero_cuenta = f_numero_cuenta;
	f_codigo_retiro := f_numero_cuenta || '-' || 'DEB' || '-' || f_numero_retiros + 1;
	
    SELECT saldo, tipo_cuenta INTO f_saldo_cuenta, f_tipo_cuenta FROM cuentas WHERE numero_cuenta = f_numero_cuenta;
    SELECT EXTRACT(MONTH FROM f_fecha_actual) INTO f_mes_actual;
	
    IF f_saldo_cuenta IS NULL OR f_tipo_cuenta = 'Aportaciones' THEN
        RETURN false;
    END IF;
    
    IF f_monto <= f_saldo_cuenta AND (f_mes_actual = 6 OR f_mes_actual = 12) THEN
		f_monto := f_monto * -1;
		CALL actualizar_saldo(f_numero_cuenta, f_monto);
		insert into retiros(
			codigo_retiro,
			numero_cuenta,
			monto,
			fecha,
			comentario
		) values(
			f_codigo_retiro,
			f_numero_cuenta,
			f_monto,
			f_fecha_actual,
			comentario
		);
        RETURN true;
    ELSE
		f_monto := f_monto * -1;
		CALL actualizar_saldo(f_numero_cuenta, f_monto);
		insert into retiros(
			codigo_retiro,
			numero_cuenta,
			monto,
			fecha,
			comentario
		) values(
			f_codigo_retiro,
			f_numero_cuenta,
			f_monto,
			f_fecha_actual,
			comentario
		);
        RETURN false;
    END IF;
END;
$$;
 x   DROP FUNCTION public.retirar(f_numero_cuenta character varying, f_monto numeric, f_fecha_actual date, comentario text);
       public          postgres    false            �            1259    16611    abonos    TABLE     �   CREATE TABLE public.abonos (
    codigo_abono character varying(20) NOT NULL,
    numero_cuenta character varying(20),
    monto numeric(12,2),
    fecha date,
    comentario character varying(50)
);
    DROP TABLE public.abonos;
       public         heap    postgres    false            ^           0    0    TABLE abonos    ACL     5   GRANT ALL ON TABLE public.abonos TO cooperativauser;
          public          postgres    false    214            �            1259    16752 	   afiliados    TABLE       CREATE TABLE public.afiliados (
    codigo_afiliado character varying(20) NOT NULL,
    primer_nombre character varying(20),
    segundo_nombre character varying(20),
    primer_apellido character varying(20),
    segundo_apellido character varying(20),
    calle character varying(20),
    avenida character varying(20),
    casa character varying(20),
    ciudad character varying(20),
    departamento character varying(20),
    referencia character varying(50),
    fecha_nacimiento date,
    fecha_ingreso date,
    activo boolean
);
    DROP TABLE public.afiliados;
       public         heap    postgres    false            _           0    0    TABLE afiliados    ACL     8   GRANT ALL ON TABLE public.afiliados TO cooperativauser;
          public          postgres    false    215            �            1259    17079    afiliados_sequence    SEQUENCE     �   CREATE SEQUENCE public.afiliados_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 1000
    CACHE 1
    CYCLE;
 )   DROP SEQUENCE public.afiliados_sequence;
       public          postgres    false    215            `           0    0    afiliados_sequence    SEQUENCE OWNED BY     T   ALTER SEQUENCE public.afiliados_sequence OWNED BY public.afiliados.codigo_afiliado;
          public          postgres    false    223            a           0    0    SEQUENCE afiliados_sequence    ACL     M   GRANT SELECT,USAGE ON SEQUENCE public.afiliados_sequence TO cooperativauser;
          public          postgres    false    223            �            1259    16817    correos    TABLE     m   CREATE TABLE public.correos (
    codigo_afiliado character varying(20),
    correo character varying(50)
);
    DROP TABLE public.correos;
       public         heap    postgres    false            b           0    0    TABLE correos    ACL     6   GRANT ALL ON TABLE public.correos TO cooperativauser;
          public          postgres    false    219            �            1259    16773    cuentas    TABLE     -  CREATE TABLE public.cuentas (
    numero_cuenta character varying(20) NOT NULL,
    codigo_afiliado character varying(20),
    tipo_cuenta character varying(20),
    fecha_apertura date,
    saldo numeric(12,2),
    antiguedad integer,
    penalizable boolean,
    aportacion_mensual numeric(12,2)
);
    DROP TABLE public.cuentas;
       public         heap    postgres    false            c           0    0    TABLE cuentas    ACL     6   GRANT ALL ON TABLE public.cuentas TO cooperativauser;
          public          postgres    false    217            �            1259    17361 
   dividendos    TABLE     A  CREATE TABLE public.dividendos (
    codigo_afiliado character varying(20),
    primer_nombre character varying(20),
    primer_apellido character varying(20),
    saldo_aportaciones numeric(12,2),
    porcentaje_participacion integer,
    ganancia numeric(12,2),
    intereses_generados numeric(12,2),
    fecha date
);
    DROP TABLE public.dividendos;
       public         heap    postgres    false            d           0    0    TABLE dividendos    ACL     Q   GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.dividendos TO cooperativauser;
          public          postgres    false    226            �            1259    16979    pagos    TABLE     �   CREATE TABLE public.pagos (
    numero_pago character varying(10),
    numero_prestamo character varying(30),
    fecha date,
    monto numeric(12,2),
    intereses numeric(12,2),
    capital numeric(12,2),
    saldo numeric(12,2)
);
    DROP TABLE public.pagos;
       public         heap    postgres    false            e           0    0    TABLE pagos    ACL     4   GRANT ALL ON TABLE public.pagos TO cooperativauser;
          public          postgres    false    221            �            1259    16803    penalizaciones    TABLE     x   CREATE TABLE public.penalizaciones (
    numero_cuenta character varying(20),
    fecha date,
    monto numeric(6,0)
);
 "   DROP TABLE public.penalizaciones;
       public         heap    postgres    false            f           0    0    TABLE penalizaciones    ACL     =   GRANT ALL ON TABLE public.penalizaciones TO cooperativauser;
          public          postgres    false    218            �            1259    17339    periodos_cerrados    TABLE     O   CREATE TABLE public.periodos_cerrados (
    fecha_periodo character varying
);
 %   DROP TABLE public.periodos_cerrados;
       public         heap    postgres    false            g           0    0    TABLE periodos_cerrados    ACL     @   GRANT ALL ON TABLE public.periodos_cerrados TO cooperativauser;
          public          postgres    false    225            �            1259    16763 	   prestamos    TABLE     0  CREATE TABLE public.prestamos (
    numero_prestamo character varying(20) NOT NULL,
    codigo_afiliado character varying(20),
    tipo_prestamo character varying(20),
    fecha date,
    monto numeric(10,2),
    periodos integer,
    saldo numeric(12,2),
    interes numeric(4,2),
    activo boolean
);
    DROP TABLE public.prestamos;
       public         heap    postgres    false            h           0    0    TABLE prestamos    ACL     8   GRANT ALL ON TABLE public.prestamos TO cooperativauser;
          public          postgres    false    216            �            1259    17113    prestamos_sequence    SEQUENCE     }   CREATE SEQUENCE public.prestamos_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 1000
    CACHE 1;
 )   DROP SEQUENCE public.prestamos_sequence;
       public          postgres    false    216            i           0    0    prestamos_sequence    SEQUENCE OWNED BY     T   ALTER SEQUENCE public.prestamos_sequence OWNED BY public.prestamos.numero_prestamo;
          public          postgres    false    224            j           0    0    SEQUENCE prestamos_sequence    ACL     M   GRANT SELECT,USAGE ON SEQUENCE public.prestamos_sequence TO cooperativauser;
          public          postgres    false    224            �            1259    17046    retiros    TABLE     �   CREATE TABLE public.retiros (
    codigo_retiro character varying(20),
    numero_cuenta character varying(20),
    monto numeric(12,2),
    fecha date,
    comentario character varying(50)
);
    DROP TABLE public.retiros;
       public         heap    postgres    false            k           0    0    TABLE retiros    ACL     6   GRANT ALL ON TABLE public.retiros TO cooperativauser;
          public          postgres    false    222            �            1259    16825 	   telefonos    TABLE     q   CREATE TABLE public.telefonos (
    codigo_afiliado character varying(20),
    telefono character varying(20)
);
    DROP TABLE public.telefonos;
       public         heap    postgres    false            l           0    0    TABLE telefonos    ACL     8   GRANT ALL ON TABLE public.telefonos TO cooperativauser;
          public          postgres    false    220            J          0    16611    abonos 
   TABLE DATA           W   COPY public.abonos (codigo_abono, numero_cuenta, monto, fecha, comentario) FROM stdin;
    public          postgres    false    214   -�       K          0    16752 	   afiliados 
   TABLE DATA           �   COPY public.afiliados (codigo_afiliado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, calle, avenida, casa, ciudad, departamento, referencia, fecha_nacimiento, fecha_ingreso, activo) FROM stdin;
    public          postgres    false    215   ��       O          0    16817    correos 
   TABLE DATA           :   COPY public.correos (codigo_afiliado, correo) FROM stdin;
    public          postgres    false    219   q�       M          0    16773    cuentas 
   TABLE DATA           �   COPY public.cuentas (numero_cuenta, codigo_afiliado, tipo_cuenta, fecha_apertura, saldo, antiguedad, penalizable, aportacion_mensual) FROM stdin;
    public          postgres    false    217    �       V          0    17361 
   dividendos 
   TABLE DATA           �   COPY public.dividendos (codigo_afiliado, primer_nombre, primer_apellido, saldo_aportaciones, porcentaje_participacion, ganancia, intereses_generados, fecha) FROM stdin;
    public          postgres    false    226   J�       Q          0    16979    pagos 
   TABLE DATA           f   COPY public.pagos (numero_pago, numero_prestamo, fecha, monto, intereses, capital, saldo) FROM stdin;
    public          postgres    false    221   ��       N          0    16803    penalizaciones 
   TABLE DATA           E   COPY public.penalizaciones (numero_cuenta, fecha, monto) FROM stdin;
    public          postgres    false    218   |�       U          0    17339    periodos_cerrados 
   TABLE DATA           :   COPY public.periodos_cerrados (fecha_periodo) FROM stdin;
    public          postgres    false    225   ��       L          0    16763 	   prestamos 
   TABLE DATA           �   COPY public.prestamos (numero_prestamo, codigo_afiliado, tipo_prestamo, fecha, monto, periodos, saldo, interes, activo) FROM stdin;
    public          postgres    false    216   Y�       R          0    17046    retiros 
   TABLE DATA           Y   COPY public.retiros (codigo_retiro, numero_cuenta, monto, fecha, comentario) FROM stdin;
    public          postgres    false    222   �       P          0    16825 	   telefonos 
   TABLE DATA           >   COPY public.telefonos (codigo_afiliado, telefono) FROM stdin;
    public          postgres    false    220   ��       m           0    0    afiliados_sequence    SEQUENCE SET     A   SELECT pg_catalog.setval('public.afiliados_sequence', 10, true);
          public          postgres    false    223            n           0    0    prestamos_sequence    SEQUENCE SET     A   SELECT pg_catalog.setval('public.prestamos_sequence', 11, true);
          public          postgres    false    224            �           2606    16617    abonos abonos_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.abonos
    ADD CONSTRAINT abonos_pkey PRIMARY KEY (codigo_abono);
 <   ALTER TABLE ONLY public.abonos DROP CONSTRAINT abonos_pkey;
       public            postgres    false    214            �           2606    16756    afiliados afiliados_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.afiliados
    ADD CONSTRAINT afiliados_pkey PRIMARY KEY (codigo_afiliado);
 B   ALTER TABLE ONLY public.afiliados DROP CONSTRAINT afiliados_pkey;
       public            postgres    false    215            �           2606    16777    cuentas cuentas_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.cuentas
    ADD CONSTRAINT cuentas_pkey PRIMARY KEY (numero_cuenta);
 >   ALTER TABLE ONLY public.cuentas DROP CONSTRAINT cuentas_pkey;
       public            postgres    false    217            �           2606    16767    prestamos prestamos_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.prestamos
    ADD CONSTRAINT prestamos_pkey PRIMARY KEY (numero_prestamo);
 B   ALTER TABLE ONLY public.prestamos DROP CONSTRAINT prestamos_pkey;
       public            postgres    false    216            �           2606    16820 $   correos correos_codigo_afiliado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.correos
    ADD CONSTRAINT correos_codigo_afiliado_fkey FOREIGN KEY (codigo_afiliado) REFERENCES public.afiliados(codigo_afiliado);
 N   ALTER TABLE ONLY public.correos DROP CONSTRAINT correos_codigo_afiliado_fkey;
       public          postgres    false    219    215    3248            �           2606    16778 $   cuentas cuentas_codigo_afiliado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuentas
    ADD CONSTRAINT cuentas_codigo_afiliado_fkey FOREIGN KEY (codigo_afiliado) REFERENCES public.afiliados(codigo_afiliado);
 N   ALTER TABLE ONLY public.cuentas DROP CONSTRAINT cuentas_codigo_afiliado_fkey;
       public          postgres    false    217    215    3248            �           2606    17364 *   dividendos dividendos_codigo_afiliado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dividendos
    ADD CONSTRAINT dividendos_codigo_afiliado_fkey FOREIGN KEY (codigo_afiliado) REFERENCES public.afiliados(codigo_afiliado);
 T   ALTER TABLE ONLY public.dividendos DROP CONSTRAINT dividendos_codigo_afiliado_fkey;
       public          postgres    false    215    226    3248            �           2606    16982     pagos pagos_numero_prestamo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_numero_prestamo_fkey FOREIGN KEY (numero_prestamo) REFERENCES public.prestamos(numero_prestamo);
 J   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_numero_prestamo_fkey;
       public          postgres    false    216    221    3250            �           2606    16806 0   penalizaciones penalizaciones_numero_cuenta_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.penalizaciones
    ADD CONSTRAINT penalizaciones_numero_cuenta_fkey FOREIGN KEY (numero_cuenta) REFERENCES public.cuentas(numero_cuenta);
 Z   ALTER TABLE ONLY public.penalizaciones DROP CONSTRAINT penalizaciones_numero_cuenta_fkey;
       public          postgres    false    217    3252    218            �           2606    16768 (   prestamos prestamos_codigo_afiliado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.prestamos
    ADD CONSTRAINT prestamos_codigo_afiliado_fkey FOREIGN KEY (codigo_afiliado) REFERENCES public.afiliados(codigo_afiliado);
 R   ALTER TABLE ONLY public.prestamos DROP CONSTRAINT prestamos_codigo_afiliado_fkey;
       public          postgres    false    216    215    3248            �           2606    16828 (   telefonos telefonos_codigo_afiliado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.telefonos
    ADD CONSTRAINT telefonos_codigo_afiliado_fkey FOREIGN KEY (codigo_afiliado) REFERENCES public.afiliados(codigo_afiliado);
 R   ALTER TABLE ONLY public.telefonos DROP CONSTRAINT telefonos_codigo_afiliado_fkey;
       public          postgres    false    220    215    3248            J   �  x���Mn�@��p�\�hl����:ʺڢ���(%�Yz�"�<)Rc����7�y~�K疋��~�Q�_-vn��rc�\�84��t�6�i<ϗ��^������ŌdV�ɬ"�EE$����Ud�d�"$9 9���QE�H�*rBrR�������U��"$� �h��\������u1�!ar�f��x��Ǵ.�t����އ�x�G.��E<�QOP��r1e��G�:(�6��z��}����"ꭦ-���K�W�H!���V�-�6��z�m�ض���f���ؿ��/�r��c��X�NE���[�8�l��jʒw��P�f'������W�J,��Po�9J�?���Y�WPoͤ���eMƤ�e�#��G��q�<���{���m۶Bj�D      K   �  x�u��n�0�ϓ����@8"���J�Q�=���\���Yc*5o�c=�#�b;NiK�E�(���������p��A�l��.��;y���6��������t>�����"���b�ֲ��m;�����riKd��l�ʀH�9�<!)��f�� �:�B�i������`���@2`��!��2Ia�,��@Ȝ&l�*���q��ft�	 �A�E00�+��ϐ�g�2��-��=�i�AD� �b�)�'�L3M}�z���/��H���Ls��i��Me�������OG�����R��M`��O'	 �srjs`I�6E�Ն�y���PyO��)��S
��i�"�͞>��8��q�!��T�e�Л�� � ,	��ޢ9
����#h(��e��ѝ�%����Q�B+s��l<H���PR8�Xh��i�QB~��\(K"I�L�s�D�G��H>�w;4s�pɋ�7��a5s�Z���菧hʦ2j�-�"�vD#�$��fkkj+[�i��)[���)�S>�)#b��0V��op׿x��d���C]�r��'�;U�P�5Ns�<�\OAn"�
�6�[>�3�cD�r�]��� �-B��a���a���(\|������l6����4      O   �   x�uн�0F��}��6X�Xغ���@�$�"�>=����Hߕ���t^��:�
E��x>�B򌃄���%RG��`���2����dk�H���f�d��6�B�G-(�U��ٱ��Qe�A%�X#��<@�Q�� ��-ֵ�2��d.�_æi�xy�      M     x�u��j�0Fg�]�c��
�.�r�[�RZڥ)�}j.E��ϱ>K��8Bp|�����i��������Gh#I�	 aI��հ�,���Ȓ��e���/?{��l��ށpt ����&Av`&�0����L7m��jhuhf�f���T���/���������Ɂ;��F�y�n���^n�^���\�3s�X_�I�ګ9�ztoMŹs6�9L�PI�y��5r(�?�b;���2���L���j5�C����ơ��d�ь���j�x��a�z�a      V   e  x��ٿn7�z�#8���0ǆ2ܥ�@J���tQ�Q�B��^,��rah93�*5��G��#���׷�~ڹ����ǿN��x�p~�����G��s&�dC2��&gС߹����Ӛ��aon�_��-J�����X�b6�w�����p�vɦ]�fS,�M�����޼ޟ�}8,�.�o �P�48���������x~j���x�����{�����Z�˗l0P,ȟ�/����7��_Z:��c� ?9���.�����T3�S߱�(��io~�8��w�шBK�ͲN^w1���F�9���>���xy8�m�$?~�,-� [s���8������M(f���¬��R�g�C��R��Cgn�G����ΰtgu�Aް�3����OILo������!4�@�d�B��~W���G{��y��	P���	��;�_� ƷNiq��"�٭S�8�b}��i���~��hԡ�d���4ס%�bRzh��@�Rh�R�H�!4ס�u���Ǿ���,l�iԙ�'X{x��c��361�e�{��v�I�-S�L�թ��@�Z����/k�U�rz�uh�zX��Qo�b�A�ҡy�Y޴�Х�>�u���v��s�C[��v�R|�/Њ�(���R�օ'1�u���z(e7�RwVk��k8��2��3*����:���V�M�Ǉ�h=9/�q)?p��K�%���5�;,����� ���p}�����:��Y�z�8s������gqu�lNbv�,�o�N)�uF�����Y�΂�衳��
�ևR~�;�Kꇨ��,�e��`�d����K	np�s��gR�Y��R�V��R�[S��;PJv�)uMJx@	8A�? s�1%�P
��g(�� C)(�{�Q
���G�RP��˻���!��P
��#G)��y�q�z+���R.���2���J���VB�RT[)p���J��'Z�3��D+�R�Z��C�[�=��J�JIk%`(%��C))������(%��C)M�2��D+y�R�Z��!���y��2C)k��JYk��P�J+9�RV[	9JYk%�P���<�J�Q�j+e���Ñ&(%�)��0�H�J$S��Q"�p�H��%���J4A	8J�RJ}����qb��#CI�S1��!e�%eJ�QRG��q��� CI����hGI�z�~b�����iH)�)��H�cJ� 2☒6��Pҧ�XJ��ܘ����Ɣf�PJ���s/�/f9CJ��831̞���!1��Ya��2��QR�|H%mȗCib�G��41��(��=Ͻ�O�w8�L�22���D��6ϋ���� r��If��6���P���Qb(M� s�.������C��      Q   �  x�u�;��0Dc�]� :q������%/)�(�U5�xl��Yʯ�����o�kQV;x�Ek句;E��\D�9�xݠ^ĺ�93�3��A5Jj�]�.}_�Ҥ^�vC�c��/��p�$�䤎U������ԋl����7�$���0���@?�!��� Z�Dڮ ��`� ��y����S��[���WT{�'���k�<� (�� ��_ [���-:y+͑(�`��ɚ�쇾U�Р�r��'?Y(����,v�����LUd|�@�c��GO��5=OR{���N��f;�T[���?��5{�3|���y��۾�s|]�3�7��i_v�Ӿ�'/u�����o���z�����'�/����~op{G�-�� <�����'z��q0���V�s�/z�^߁��      N   p  x���Aj�@F�u|�)�,Y����z�s��E�c�#ل�a�s|���l���~�[��m�:������������	��X�X�Eڶκ��`��.]��L�,���s*4��l0��w�i�<�d�w�o�`�`�`�`�wѦ5�2إ�h�`�`�`�w�`/�e4s0S� K�����n�.���	��X�X��a/{��L�,����.;�e���f`&`
`	V`}����e4s0S� K��$tI�2��9��)X�%X��]
ޣ��h4s0S� K����2w���U�`�`�`�w���v�2�W=��	��X�X�Ea/ӻӃ��	��X�Փ�|,��Y"�      U   M   x�E���@D�;�``@]z��:�(an?/���4\�ei؟n��T���3��Πf��<���.f��lHn���"���!�      L   �   x���1� ����/'wg�ft	t)ڭKH�(��76�X���Ň7�H˱x��up;�B��0��9�8N $�C���Q��ϐf���_LE�v��!yiC$+�\%I+ɖ��/ɗ�c%y��c���_�����>��v�f+��e9�ey�k��RQY      R   �  x���?r�F�k�� 9�-v��R��*'u%Q�Ǟ�N�k��XhQ���`�3�}������t��w�?�����>v��G�}*�ҼKS��Ӻ�����_O_>}w����?>=�3�%c��tHi �bF�dD�z��vFL�q���]rn�X�#�}����r�.�8��x���]��4]η6�������韧�N����������r� ����<�#���x���Oȧ{��|��oȷ{�����wq8�N_6;�\�mF��i��u:�N��Hx��6���d:_�
�N�Ӛ/ȓNk~A�tZ�]��鴾~��I�5��'��|E�tZ�y�iͯȓN��wqx�����ӳ��˨�A;m2�N϶��>����}�>n~&I�gg��;A�y�N�|A��4� O�	��I�5��'��|E�tZ�y�iͯȓN��wq8�N��߱���e$̠]rW��r)��_o��Yu��]���3�]�|A�����o�d���m�,_�����]����m�6���ᢻ�-a�KEwi#�ڃbz��i��A1=�|׃bz���<�����I4��'=�|E��@�y�ͯȓ��wqx�=xI�tx1����8,����8���<qX�y��y����a�W�Úo��5�"O��տj���V��?�w�U��3��?�����O��4_�'�i�!O����<�O�W�������O������<�O�y��y����?�W��o��4�"O���տ�����V��;�V��3��?�����O��4_�'�i�!O����<�O���3�� 4e@��MFA�I qP@$�A��: � ���$�x�	 "ꀕu@g��"�m�D�E���D9�ڀL��:�� b�@L��u@%�D�H 1Q�$���:倖_�l�(4Л('H�I 1Q@L�A��: � b��$���	 &ꀕu@g��m�9Л(w/Л(�/�I �8v�EN_6 H �8v�D�W6�� 4q씉��l�J�ısBf�:Tf�1��L8r,#��3t.#��3t0"��3t2"��3t4"��3t6"��3t8"��3t�%�좧��D���3����3���a���=?��24�Y_��0��Фf���������e9,������ߧ�UB{�p{�7�/��������g      P   w   x�]�=
BA��=��D6?�dK���u��.$���b�x�O�;|�a�u���8�$E�I��FZ�2�� 5tB��S䚍���h�@�(RU
G�E"r~�����ųh����>����6�     