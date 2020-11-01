-- Restricciones y Reglas del Negocio

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


--2) Controlar que no se pueda colocar una orden si no hay fondos suficientes.

CREATE OR REPLACE FUNCTION TRFN_G29_OrdenSaldoSuficiente()
RETURNS trigger AS
$$
BEGIN

        IF (EXISTS(SELECT 1
			FROM g29_billetera b
            JOIN g29_mercado m ON m.nombre = NEW.mercado
            WHERE (b.moneda = m.moneda_o) AND (b.saldo < NEW.valor)))THEN   --TODO Consultar sobre moneda_o o moneda_d

             RAISE EXCEPTION 'No hay fondos suficientes para realizar la orden';
        END IF;
RETURN NEW;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER TR_G29_Orden_OrdenSaldoSuficiente
BEFORE INSERT ON g29_orden
FOR EACH ROW
EXECUTE PROCEDURE TRFN_G29_OrdenSaldoSuficiente();

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
                       AND (b.saldo < (NEW.valor +(SELECT sum(o.valor)
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


-- 4) La opcionalidad del numero de bloque en Movimiento, debe coincidir con la opcionalidad de Direccion, es decir que ambos son nulos o ambos no lo son.
ALTER TABLE g29_movimiento
ADD CONSTRAINT CK_G29_Movimiento_BloqueDireccionNulidad
CHECK ( NOT ((( bloque IS NULL) AND (direccion IS NOT NULL)) OR (( bloque IS NOT NULL) AND (direccion IS NULL))));



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
