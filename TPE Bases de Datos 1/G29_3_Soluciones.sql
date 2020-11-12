--TODO ERROR EN CK_G29 LINEA 123

-- Restricciones y Reglas del Negocio


--TODO HACER SENTENCIAS DE ACTIVACION COMENTADAS
--1) Controlar que los numeros de bloque sean consecutivos para los movimientos de Entrada y Salida del Blockchain por moneda y fecha
CREATE OR REPLACE FUNCTION TRFN_G29_MovimientosBloquesConsecutivos()
RETURNS trigger AS
$$
BEGIN
	IF (EXISTS (SELECT 1
			FROM g29_movimiento m
			WHERE  ((m.moneda = NEW.moneda) and (m.fecha <= NEW.fecha) and (m.bloque > NEW.bloque)))) THEN
            RAISE EXCEPTION 'Un movimiento no puede tener un numero de bloque inferior al de los movimientos anteriores en la misma moneda ';
    END IF;
RETURN NEW;
END
$$
LANGUAGE plpgsql;


CREATE TRIGGER TR_G29_Movimiento_MovimientosBloquesConsecutivos
BEFORE INSERT ON g29_movimiento
FOR EACH ROW
EXECUTE PROCEDURE TRFN_G29_MovimientosBloquesConsecutivos();
--Sentencias de activacion
-- insert into g29_movimiento values (100,'USDT','2018-01-01 00:00:00','e',0,50,50,'A2020'); -- este seria el ultimo movimiento
-- insert into g29_movimiento values (100,'USDT',current_date,'e',0,1000,49,'A2020'); -- no procede por ser el bloque menor
-- insert into g29_movimiento values (100,'USDT',current_date,'e',0,1000,51,'A2020'); -- procede


--************************************************************
--2) Controlar que no se pueda colocar una orden si no hay fondos suficientes.

CREATE OR REPLACE FUNCTION TRFN_G29_OrdenSaldoSuficiente()
RETURNS trigger AS
$$
BEGIN
    IF(new.tipo = 'COMPRA') THEN
        IF (EXISTS(SELECT 1
			FROM g29_billetera b
            WHERE (b.id_usuario = NEW.id_usuario) AND(b.moneda = (SELECT m.moneda_d
                                                                  FROM g29_mercado m
                                                                  WHERE m.nombre = NEW.mercado))
              AND (b.saldo < NEW.valor * NEW.cantidad)))THEN   --TODO Consultar sobre moneda_o o moneda_d
                RAISE EXCEPTION 'No hay fondos suficientes para realizar la orden';
        END IF;
    ELSE
        IF(new.tipo = 'VENTA') THEN
            IF (EXISTS(SELECT 1
			FROM g29_billetera b
            WHERE (b.id_usuario = NEW.id_usuario) AND (b.moneda = (SELECT m.moneda_o
                                                                  FROM g29_mercado m
                                                                  WHERE m.nombre = NEW.mercado))
              AND (b.saldo < NEW.cantidad)))THEN
                RAISE EXCEPTION 'No hay fondos suficientes para realizar la orden';
            END IF;
        END IF;
    END IF;
RETURN NEW;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER TR_G29_Orden_OrdenSaldoSuficiente
BEFORE INSERT ON g29_orden
FOR EACH ROW
EXECUTE PROCEDURE TRFN_G29_OrdenSaldoSuficiente();

--Sentencias de prueba

-- insert into g29_usuario values (9999,'Juan','Perez','05-06-2014', 'none', 'none', 'password', '442543353', '55254'); -- se crea un usuario
-- update g29_billetera set saldo = 1000
--     where id_usuario = 9999 and moneda = 'USDT';  --se carga el saldo de la billetera del usuario en 1000 USDT
-- insert into g29_orden values (9999996554889,'Mercado 1', 9999,'COMPRA', current_date, null, 11000, 1, 'ACTIVA'); --no procede, la cantidad *valor supera el saldo en la billetera
-- insert into g29_orden values (99999939989,'Mercado 1', 9999,'COMPRA', current_date, null, 11000, 0.01, 'ACTIVA'); --procede


--************************************************************
--3) No se pueden hacer retiros de una moneda, si esos fondos estan en ordenes activas.
CREATE OR REPLACE FUNCTION TRFN_G29_RetiroFondosSuficientes()
RETURNS trigger AS
$$
BEGIN
    IF (EXISTS (SELECT 1
			FROM g29_billetera b
            WHERE ((NEW.id_usuario = b.id_usuario) AND (NEW.moneda = b.moneda)
                       AND (b.saldo < (NEW.valor +(SELECT sum(o.cantidad)
                                                    FROM  g29_orden o
                                                    JOIN g29_mercado m on o.mercado = m.nombre
                                                     WHERE ((m.moneda_o = NEW.moneda) AND (o.estado = 'ACTIVA') AND (o.tipo = 'VENTA')AND (o.id_usuario = NEW.id_usuario)))))))
            OR EXISTS(SELECT 1
			FROM g29_billetera b
            WHERE ((NEW.id_usuario = b.id_usuario) AND (NEW.moneda = b.moneda)
                       AND (b.saldo < (NEW.valor +(SELECT sum(o.valor *o.cantidad )
                                                    FROM  g29_orden o
                                                    JOIN g29_mercado m on o.mercado = m.nombre
                                                     WHERE ((m.moneda_d = NEW.moneda) AND (o.estado = 'ACTIVA') AND (o.tipo = 'COMPRA') AND (o.id_usuario = NEW.id_usuario)))))))
        ) THEN
        RAISE EXCEPTION 'No se pueden hacer retiros si esos fondos estan en ordenes activas';

        END IF;
    RETURN NEW;
END
$$
LANGUAGE plpgsql;


CREATE TRIGGER TR_G29_Movimiento_RetiroFondosSuficientes
BEFORE INSERT ON g29_movimiento
FOR EACH ROW
WHEN (NEW.tipo = 's')
EXECUTE PROCEDURE TRFN_G29_RetiroFondosSuficientes();

--Sentencias de prueba
--teniendo en cuenta la orden creada (la que procede) en las sentencia de prueba anterior:

-- insert into g29_movimiento values (9999,'USDT',current_date,'s', 0, 1000, 900, 'B348738'); -- No procede, el saldo en su billetera es 1000, pero tiene una orden de compra que se "resta" a este saldo.
-- insert into g29_movimiento values (9999,'USDT',current_date,'s', 0, 50, 900, 'B348738'); --Procede


--************************************************************
-- 4) La opcionalidad del numero de bloque en Movimiento, debe coincidir con la opcionalidad de Direccion, es decir que ambos son nulos o ambos no lo son.

ALTER TABLE g29_movimiento
ADD CONSTRAINT CK_G29_Movimiento_BloqueDireccionNulidad
CHECK ( NOT ((( bloque IS NULL) AND (direccion IS NOT NULL)) OR (( bloque IS NOT NULL) AND (direccion IS NULL))));

--Sentencias de prueba

-- insert into g29_movimiento values (9999,'USDT','12-05-2021','e', 0, 1000, null, 'A59393'); --No procede
-- insert into g29_movimiento values (9999,'USDT','12-06-2021','e', 0, 1000, 901, null); --No procede
-- insert into g29_movimiento values (9999,'USDT','12-05-2022','e', 0, 1000, null, null); -- Procede
-- insert into g29_movimiento values (9999,'USDT','12-05-2023','e', 0, 1000, 901, 'A477389'); -- Procede


--SERVICIOS
---1)
--A) Brinde el precio actual de cotizacion en un mercado determinado
create or replace function TRFN_G29_Calcular20Porciento() returns trigger as $$
declare
    compra double precision;
    venta double precision;
    begin

    select sum(cantidad)*0.2 into compra
    from g29_orden
        where (new.mercado = mercado) and (tipo = 'COMPRA');

    select sum(cantidad)*0.2 into venta
    from g29_orden
        where (new.mercado = mercado) and (tipo = 'VENTA');

    update g29_mercado set
        precio_mercado = FN_G29_PrecioMercado(new.mercado,compra,venta)
        where (nombre = new.mercado);

    return new;
end; $$ language plpgsql;


create trigger TR_G29_OrdenCalcular20Porciento after insert or update of estado
    on g29_orden for each row
    execute function TRFN_G29_Calcular20Porciento();



create or replace function FN_G29_PrecioMercado(mercadop varchar(20),compra double precision, venta double precision) returns double precision as $$
declare
    PromedioCompra double precision;
    PromedioVenta double precision;
    i int;
    cantidadActual double precision;
    ordenActual g29_orden;
    begin
    PromedioVenta = 0;
    PromedioCompra = 0;

     i = 0;
    cantidadActual = 0;
    while (cantidadActual < compra) loop
        select * into ordenActual
        from g29_orden
        where(mercadop = g29_orden.mercado) and (tipo = 'COMPRA') and (estado = 'ACTIVA')
        order by valor desc
        limit 1
        offset i;
        i = i+1;
        PromedioCompra = PromedioCompra + (ordenActual.valor *(ordenActual.cantidad/ compra));
        cantidadActual = cantidadActual + ordenActual.cantidad;

        end loop;

        cantidadActual = 0;
        i = 0;
        while (cantidadActual < venta) loop
            select * into ordenActual
            from g29_orden
            where(mercadop = g29_orden.mercado) and (tipo = 'VENTA')
            order by valor
            limit 1
            offset i;
            PromedioVenta = PromedioVenta + (ordenActual.valor*(ordenActual.cantidad/venta));
            cantidadActual = cantidadActual + ordenActual.cantidad;
        end loop;

    return (PromedioCompra + PromedioVenta)/2;

end; $$ language plpgsql;

--Sentencias de prueba
-- insert into g29_orden values (9999999998,'Mercado 1', 9999, 'VENTA', current_date, null, 12000, 0.01, 'ACTIVA');
-- select precio_mercado
-- from g29_mercado
-- where nombre = 'Mercado 1';

--************************************************************
--B) Ejecute una orden de mercado (orden de tipo Market) para compra y venta

create or replace function TRFN_G29_EjecutarOrdenMarket() returns trigger as $$
declare
    valorActual decimal;
    proximo decimal;
    ordenActual g29_orden;
    cantidadTotal decimal;
    begin
        cantidadTotal = 0;
        if (new.tipo = 'COMPRA') then
            valorActual= NEW.valor;

            select * into ordenActual     --tomo la orden mas barata de venta para empezar a comparar
            from g29_orden
            where(new.mercado = mercado) and (tipo = 'VENTA') and (new.id_usuario <> id_usuario) and (estado = 'ACTIVA')
            order by valor
            limit 1;

            proximo = ordenActual.valor * ordenActual.cantidad;
            while (valorActual >= proximo) loop
                valorActual = valorActual - proximo;
                cantidadTotal = cantidadTotal + ordenActual.cantidad;

                update g29_orden set
                estado = 'EJECUTADA'
                where id = ordenActual.id;

               update g29_billetera set
                saldo = saldo + proximo
                where id_usuario = ordenActual.id_usuario
                    and moneda = (select m.moneda_d
                            from g29_mercado m
                            where m.nombre = new.mercado);

                update g29_billetera set
                saldo = saldo - ordenActual.cantidad
                where id_usuario = ordenActual.id_usuario
                    and moneda = (select m.moneda_o
                            from g29_mercado m
                            where m.nombre = new.mercado);


                select * into ordenActual      --tomo la orden mas barata de venta para empezar a comparar
                from g29_orden
                where(new.mercado = mercado) and (tipo = 'VENTA') and (new.id_usuario <> id_usuario) and (estado = 'ACTIVA')
                order by valor
                limit 1;

                proximo = ordenActual.valor * ordenActual.cantidad;
            end loop;

            update g29_billetera set
            saldo = saldo + valorActual - new.valor
            where id_usuario = new.id_usuario
                and moneda = (select m.moneda_d
                            from g29_mercado m
                            where m.nombre = new.mercado);

            update g29_billetera set
            saldo = saldo + cantidadTotal
            where id_usuario = new.id_usuario
                and moneda = (select m.moneda_o
                            from g29_mercado m
                            where m.nombre = new.mercado);

        end if;

        if (new.tipo = 'VENTA') then
            valorActual = new.cantidad;

            select * into ordenActual       --tomo la orden mas alta de compra para empezar a comparar
            from g29_orden
            where(new.mercado = mercado) and (tipo = 'COMPRA') and (new.id_usuario <> id_usuario) and (estado = 'ACTIVA')
            order by valor desc
            limit 1;

            proximo = ordenActual.cantidad;
            while (valorActual >= proximo) loop
               valorActual = valorActual - proximo;
                cantidadTotal = cantidadTotal + ordenActual.valor;

               update g29_orden set
                estado = 'EJECUTADA'
                where id = ordenActual.id;

               update g29_billetera set
                saldo = saldo + proximo
                where id_usuario = ordenActual.id_usuario
                    and moneda = (select m.moneda_o
                            from g29_mercado m
                            where m.nombre = new.mercado);

                update g29_billetera set
                saldo = saldo - ordenActual.valor
                where id_usuario = ordenActual.id_usuario
                    and moneda = (select m.moneda_d
                            from g29_mercado m
                            where m.nombre = new.mercado);

                select * into ordenActual      --tomo la orden mas barata de venta para empezar a comparar
                from g29_orden
                where(new.mercado = mercado) and (tipo = 'COMPRA') and (new.id_usuario <> id_usuario) and (estado = 'ACTIVA')
                order by valor desc
                limit 1;

                proximo = ordenActual.cantidad;
            end loop;
            update g29_billetera set
            saldo = saldo + valorActual - new.cantidad
            where id_usuario = new.id_usuario
                and moneda = (select m.moneda_o
                            from g29_mercado m
                            where m.nombre = new.mercado);

            update g29_billetera set
            saldo = saldo + cantidadTotal
            where id_usuario = new.id_usuario
                and moneda = (select m.moneda_d
                            from g29_mercado m
                            where m.nombre = new.mercado);
        end if;
 return new;
end  $$ language plpgsql;


create trigger TR_G29_Orden_EjecutarOrdenMarket after insert or update of estado
    on g29_orden for each row
    when (new.estado = 'EJECUTADA')
    execute function TRFN_G29_EjecutarOrdenMarket();

--Sentencias de prueba
--Para chequear este servicio se tiene que cambiar el valor de una orden de compra o venta por 'EJECUTADA', Y despues controlar las ordenes que queden y las billeteras de los usuarios.
-- update g29_billetera set saldo = 0.51  -- (tiene 0.01 en otra orden de venta creada en la sentencia anterior)
-- where id_usuario = 9999 and moneda = 'BTC';
-- insert into g29_orden values (999997999999995, 'Mercado 1', 9999, 'VENTA', current_date, current_date, 10000, 0.5, 'ACTIVA');


--************************************************************
--C) Dado un mercado X y una fecha, retome un listado con todas las ordenes ordenadas en forma cronologica junto con su tipo y estado
create or replace function FN_G29_ListarOrdenes(mercadop varchar(20), fecha date)
RETURNS TABLE( out_id integer, out_tipo varchar(10), out_estado varchar(10), out_fecha date) AS
$$
DECLARE
    reg RECORD;
BEGIN
    FOR REG IN (SELECT id, tipo, estado, fecha_creacion
                FROM g29_orden
                where fecha_creacion <= fecha and mercado = mercadop) LOOP
        out_id = reg.id;
        out_tipo = reg.tipo;
        out_estado = reg.estado;
        out_fecha = reg.fecha_creacion;
        RETURN NEXT;
    END LOOP;
    RETURN;
END
 $$ LANGUAGE 'plpgsql';


---D) DEFINICION DE VISTAS

--1.
CREATE OR REPLACE VIEW G29_saldo_usuario_por_moneda AS
    SELECT id_usuario, moneda, saldo
    FROM g29_billetera b
    ORDER BY id_usuario;
----
--2.

CREATE OR REPLACE FUNCTION FN_G29_COTIZACION_MONEDA(origen varchar, destino varchar, saldo float) returns float as $$
 BEGIN
     RETURN (SELECT (saldo/precio_mercado) AS cot FROM g29_mercado WHERE moneda_o = destino AND moneda_d = origen);
 END;
 $$ language plpgsql;

CREATE OR REPLACE VIEW G29_saldo_cotizado AS -- Si hay nulos es por que no hay mercado para ese par de monedas
    SELECT id_usuario, moneda, saldo ,FN_G29_COTIZACION_MONEDA(moneda, 'BTC',saldo) as cot_BTC, FN_G29_COTIZACION_MONEDA(moneda,'USDT',saldo) as cot_USDT FROM G29_saldo_usuario_por_moneda;

----
--3

CREATE OR REPLACE VIEW G29_usuarios_con_mas_dinero AS -- COMO EN LA ANTERIOR VISTA SE COTIZAN TODAS LAS MONEDAS, SE SUMA UNA DE LAS COTIZACIONES PARA DETERMINAR QUIEN TIENE MAS DINERO
    SELECT id_usuario, sum(cot_BTC) as saldo_total FROM G29_saldo_cotizado
    GROUP BY id_usuario
    ORDER BY saldo_total DESC
    LIMIT 10;


