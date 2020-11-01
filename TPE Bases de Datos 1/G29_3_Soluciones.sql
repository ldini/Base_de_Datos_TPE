-- Restricciones y Reglas del Negocio

--1) Controlar que los numeros de bloque sean consecutivos para los movimientos de Entrada y Salida del Blockchain por moneda y fecha
CREATE OR REPLACE FUNCTION TRFN_MovimientosBloquesConsecutivos()
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


CREATE TRIGGER TR_MovimientosBloquesConsecutivos
BEFORE INSERT ON g29_movimiento
FOR EACH ROW
EXECUTE PROCEDURE TRFN_MovimientosBloquesConsecutivos();


--2) Controlar que no se pueda colocar una orden si no hay fondos suficientes.

CREATE OR REPLACE FUNCTION TRFN_OrdenSaldoSuficiente()
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

CREATE TRIGGER TR_OrdenSaldoSuficiente
BEFORE INSERT ON g29_orden
FOR EACH ROW
EXECUTE PROCEDURE TRFN_OrdenSaldoSuficiente();

--3) No se pueden hacer retiros de una moneda, si esos fondos estan en ordenes activas.
CREATE OR REPLACE FUNCTION TRFN_RetiroFondosSuficiente()
RETURNS trigger AS
$$
BEGIN
    IF (EXISTS (SELECT 1
			FROM g29_billetera b
            WHERE ((NEW.id_usuario = b.id_usuario) AND (NEW.moneda = b.moneda)
                       AND (b.saldo < (NEW.valor +(SELECT sum(o.valor)
                                                    FROM  g29_orden o
                                                    JOIN g29_mercado m on o.mercado = m.nombre
                                                     WHERE ((m.moneda_o = NEW.moneda) AND (o.estado = 'ACTIVA') AND (o.id_usuario = NEW.id_usuario)))))))) THEN
        RAISE EXCEPTION 'No se pueden hacer retiros si esos fondos estan en ordenes activas';

        END IF;
    RETURN NEW;
END
$$
LANGUAGE plpgsql;


CREATE TRIGGER TR_RetiroFondosSuficiente
BEFORE INSERT ON g29_movimiento
FOR EACH ROW
WHEN (NEW.tipo = 's')
EXECUTE PROCEDURE TRFN_RetiroFondosSuficiente();


-- 4) La opcionalidad del numero de bloque en Movimiento, debe coincidir con la opcionalidad de Direccion, es decir que ambos son nulos o ambos no lo son.
ALTER TABLE g29_movimiento
ADD CONSTRAINT chk_Bloque_Direccion_Nulidad
CHECK ( NOT ((( bloque IS NULL) AND (direccion IS NOT NULL)) OR (( bloque IS NOT NULL) AND (direccion IS NULL))));



--SERVICIOS
---1)
--a)
create or replace function TRFN_Calcular_20Porciento() returns trigger as $$
declare
    compra double precision;
    venta double precision;
    begin

    select sum(valor)*0.2 into compra
    from g29_orden
        where (new.mercado = mercado) and (tipo = 'COMPRA');

    select sum(valor)*0.2 into venta
    from g29_orden
        where (new.mercado = mercado) and (tipo = 'VENTA');

    update g29_mercado set
        precio_mercado = FN_Precio_Mercado(new.mercado,compra,venta)
        where (nombre = new.mercado);

    return new;
end; $$ language plpgsql;



create trigger TR_Calcular_20Porciento after insert or update of estado
    on g29_orden for each row
    execute function TRFN_Calcular_20Porciento();



create or replace function FN_Precio_Mercado(mercadoo varchar(20),compra double precision, venta double precision) returns double precision as $$
declare
    PromedioCompra double precision;
    PromedioVenta double precision;
    i int;
    aux double precision;
    begin
    i = 0;
    aux = 0;
        while (PromedioCompra < compra) loop
        select (valor*(cantidad/compra)) into aux
        from g29_orden
        where(mercadoo = g29_orden.mercado) and (tipo = 'compra')
        order by valor desc
        limit 1
        offset i;
        i = i+1;
        PromedioCompra = PromedioCompra + aux;
        end loop;
        i = 0;
        aux = 0;
        while (PromedioVenta < venta) loop
        select (valor*(cantidad/venta)) into aux
        from g29_orden
        where(mercadoo = g29_orden.mercado) and (tipo = 'venta')
        order by valor
        limit 1
        offset i;
        i = i+1;
        PromedioVenta = PromedioVenta + aux;
end loop;

    return (PromedioCompra + PromedioVenta)/2;

end; $$ language plpgsql;

