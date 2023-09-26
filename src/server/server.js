const express = require('express');
const cors = require('cors');
const app = express();
const port = 4000;
const pool = require('./db');

app.use(cors());
app.use(express.json());

app.post('/api/crear-afiliado', async (req, res) => {
    const nuevoAfiliado = req.body;
    const fechaNacimientoFormated = new Date(nuevoAfiliado.fechaNacimiento);
    try {
        const query = 'SELECT crear_afiliado($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)';

        const values = [
            nuevoAfiliado.primerNombre,
            nuevoAfiliado.segundoNombre,
            nuevoAfiliado.primerApellido,
            nuevoAfiliado.segundoApellido,
            nuevoAfiliado.calle,
            nuevoAfiliado.avenida,
            nuevoAfiliado.casa,
            nuevoAfiliado.ciudad,
            nuevoAfiliado.departamento,
            nuevoAfiliado.referencia,
            fechaNacimientoFormated,
            nuevoAfiliado.telefono,
            nuevoAfiliado.correo,
        ];

        const result = await pool.query(query, values);
        const responseCrearAfiliado = result.rows[0].crear_afiliado;
        if (responseCrearAfiliado == true) {
            res.json({ success: true, message: 'Afiliado creado exitosamente.'});
        } else {
            res.json({ success: true, message: 'Hubo un problema al momento de crear el afiliado.'});
        }
        
    } catch (error) {
        console.error('Error al crear el afiliado', error);
        res.status(500).json({ success: false, message: 'Error: Uno o más de los datos son invalidos.' });
    }
});

app.post('/api/deposito', async (req, res) => {
    const {cuentaSeleccionada, monto, fecha, comentario} = req.body;
    const montoFinal = parseInt(monto);
    try {
        const query = 'SELECT crear_abono($1, $2, $3, $4)';

        const values = [
            cuentaSeleccionada,
            montoFinal,
            fecha,
            comentario,
        ];
        const result = await pool.query(query, values);
        if (result.rows[0].crear_abono == 1) {
            res.json({ success: true, message: 'Deposito realizado exitosamente.'});

        } else {
            res.json({ success: true, message: 'Hubo en problema con la transacción. '})
        }
    } catch (error) {
        console.error('Error al tratar de realizar deposito', error);
        res.status(500).json({ success: false, message: 'Error al crear afiliado' });
    }
});

app.post('/api/retiro', async (req, res) => {
    const {cuentaSeleccionada, monto, fecha, comentario} = req.body;
    const montoFinal = parseInt(monto)
    try {
        const query = 'SELECT retirar($1, $2, $3, $4)';

        const values = [
            cuentaSeleccionada,
            montoFinal,
            fecha,
            comentario,
        ];
        const result = await pool.query(query, values);
        
        const retiroData = result.rows[0];
        console.log(retiroData.retirar);
        if (retiroData.retirar == true) {
            res.json({ success: true, message: 'Retiro realizado exitosamente. ' });
        } else {
            res.json({ success: true, message: 'Hubo un problema con la transacción.' });
        }
    } catch (error) {
        console.error('Error al tratar de realizar deposito', error);
        res.status(500).json({ success: false, message: 'Error al crear afiliado' });
    }

})

app.post('/api/liquidacion', async (req, res) => {
    const {codigoAfiliado, tipoLiquidacion, fecha} = req.body;
    console.log(codigoAfiliado);
    console.log(tipoLiquidacion);
    console.log(fecha);
    try {
        let query;
        let values;
        let result;
        let liquidacionData;
        if (tipoLiquidacion == 'Total') {
            query = 'SELECT liquidacion_total($1)';
            values = [ codigoAfiliado];
            result = await pool.query(query, values);
            liquidacionData = result.rows[0].liquidacion_total;
        } else if (tipoLiquidacion == 'Parcial') {
            query = 'SELECT liquidacion_parcial($1,$2)';
            values = [ codigoAfiliado, fecha ];
            result = await pool.query(query, values);
            liquidacionData = result.rows[0].liquidacion_parcial;
        }
        console.log(liquidacionData);
        if (tipoLiquidacion == 'Total') {
            if (liquidacionData == true) {
                res.json({ success: true, message: 'Liquidación realizada exitosamente.'});
            } else {
                res.json({ success: true, message: 'No se pudo solicitar la liquidación ya que el afiliado cuenta con un prestamo pendiente.'});
            }
        } else if (tipoLiquidacion == 'Parcial') {
            console.log(liquidacionData);
            if (liquidacionData == true) {
                res.json({ success: true, message: 'Liquidación realizada exitosamente.'});
            } else {
                res.json({ success: true, message: 'Liquidación parcial solo se puede solicitar despues del cierre del mes de diciembre del año actual.'});
            }
        }
        

    } catch (error) {

    }
})

app.post('/api/solicitar-prestamo', async (req, res) => {
    const {codigoAfiliado, tipoPrestamo, monto, periodos} = req.body;
    try {
        const query = 'SELECT nuevo_prestamo($1, $2, $3, $4)';

        const values = [ codigoAfiliado,tipoPrestamo, monto, periodos ];
        const result = await pool.query(query, values);
        if (result.rows[0].nuevo_prestamo == 1) {
            res.json({ success: true, message: 'Prestamo solicitado exitosamente.'});
        } else {
            res.json({ success: false, message: 'No se pudo solicitar el prestamo.'});
        }
        
    } catch (error) {
        console.error('Error al tratar de solicitar prestamo', error);
        res.status(500).json({ success: false, message: 'Error al crear prestamo' });
    }
})

app.get('/api/obtener-afiliado', async (req, res) => {
    const codigoAfiliado = req.query.codigoAfiliado;
    try {
        const query = 'SELECT obtener_afiliado($1)';
        const values = [codigoAfiliado];
        const result = await pool.query(query, values);
        
        if (result.rows.length > 0) {
            const afiliadoData = result.rows[0];
            console.log(afiliadoData);
            res.json({ success: true, data: afiliadoData });
        } else {
            res.json({ success: false, data: afiliadoData });
        }
        
    } catch (error) {
    console.error('Error al leer afiliados', error);
    res.status(500).json({ success: false, message: 'Error al leer afiliados' });
    }
})

app.get('/api/obtener-limite', async (req, res) => {
    const codigoAfiliado = req.query.codigoAfiliado;
    const tipoPrestamo = req.query.tipoPrestamo;
    try {
        const query = 'SELECT limite_prestamo($1, $2)';
        const values = [codigoAfiliado, tipoPrestamo];
        const result = await pool.query(query, values);        
        if (result.rows.length > 0) {
            const limitePrestamo = result.rows[0];
            console.log(limitePrestamo);
            res.json({ success: true, data: limitePrestamo });
        } else {
            console.log('No se encontraron registros');
            res.json({ success: false, data: limitePrestamo });
        }
        
    } catch (error) {
    console.error('Error al leer afiliados', error);
    res.status(500).json({ success: false, message: 'Error al leer afiliados' });
    }
})



app.post('/api/cierre', async (req, res) => {
    const fecha = req.body.fecha;
    console.log(fecha);
    try {
        const query = 'select fin_de_mes($1)';
        const values = [fecha];
        const result = await pool.query(query,values);
        console.log(result.rows[0].fin_de_mes);
        if (result.rows[0].fin_de_mes == true) {
            res.json({ success: true, message: 'Cierre de mes realizado exitosamente.'});
        } else {
            res.json({ success: false, message: 'Ya se realizó el cierre de mes para este periodo.'});
        }
        
    } catch (error) {
        console.error('Error al tratar de ejecutar fin_de_mes', error);
        res.status(500).json({ success: false, message: 'Error al realizar cierre' });
    }
})

app.get('/api/obtener-dividendos', async (req, res) => {
    const fecha = req.query.fecha;
    console.log(fecha);
    try {
        const query = 'SELECT obtener_dividendos($1)';
        const values = [fecha];
        const result = await pool.query(query, values)
        if (result.rows.length > 0) {
            const dividendosData = result.rows[0];
            if (dividendosData.obtener_dividendos != null) {
                res.json({ success: true, data: dividendosData });
            } else {
                res.json({ success: false, message: 'No se encontraron datos para la fecha seleccionada.' });
            }
            
        }
    } catch {
        res.status(500).json({success: false, message: 'Error al tratar de obtener dividendos. '})
    }
});

app.get('/api/generar-reporte', async (req, res) => {
    const fechaInicio = req.query.fechaInicio;
    const fechaFin = req.query.fechaFin;
    try {
        const query = 'SELECT generar_reporte_dividendos($1,$2)';
        const values = [fechaInicio, fechaFin];
        const result = await pool.query(query, values);
        if (result.rows.length > 0) {
            const reportesData = result.rows[0];
            console.log(fechaInicio);
            console.log(fechaFin);
            console.log(reportesData.generar_reporte_dividendos);
            if (reportesData.generar_reporte_dividendos != null) {
                res.json({ success: true, data: reportesData});
            } else {
                res.json({ success: false, message: 'No se encontraros datos dentro del rango seleccionado.'})
            }
        } else {
            res.status(500).json({success: false, message: 'Error al tratar de obtener reporte. '})
        }
    } catch {

    }
})

app.get('/api/obtener-estado-cuenta', async (req, res) => {
    const numeroCuenta = req.query.numeroCuenta;
    const fechaInicio = req.query.fechaInicio;
    const fechaFin = req.query.fechaFin;
    try {
        const query = 'SELECT generar_estado_cuenta($1,$2,$3)';
        const values = [numeroCuenta, fechaInicio, fechaFin];
        const result = await pool.query(query, values);
        if (result.rows.length > 0) {
            const reportesData = result.rows[0];
            if (reportesData.generar_estado_cuenta != null) {
                res.json({ success: true, data: reportesData});
            } else {
                res.json({ success: false, message: 'No se encontraros datos dentro del rango seleccionado.'})
            }
        } else {
            res.status(500).json({success: false, message: 'Error al tratar de obtener reporte. '})
            console.log('No se puedo obtener los datos');
        }
    } catch {
        console.log('No se puedo obtener los datos');
    }
})

app.get('/api/obtener-estado-dividendos', async (req, res) => {
    const codigoAfiliado = req.query.codigoAfiliado;
    const fechaInicio = req.query.fechaInicio;
    const fechaFin = req.query.fechaFin;
    try {
        console.log(codigoAfiliado);
        console.log(fechaInicio);
        console.log(fechaFin);
        const query = 'SELECT obtener_estado_dividendos($1,$2,$3)';
        const values = [codigoAfiliado, fechaInicio, fechaFin];
        const result = await pool.query(query, values);
        const reportesDividendos = result.rows[0].obtener_estado_dividendos;
        console.log(reportesDividendos);
        if (reportesDividendos != null) {
            res.json({ success: true, data: reportesDividendos});
        } else {
            res.json({ success: false, message: 'No se encontraros datos dentro del rango seleccionado.'})
        }
    } catch {
        console.log('No se puedo obtener los datos');
    }
})

app.get('/api/obtener-estado-prestamos', async (req, res) => {
    const codigoAfiliado = req.query.codigoAfiliado;
    const fechaInicio = req.query.fechaInicio;
    const fechaFin = req.query.fechaFin;
    try {
        console.log(codigoAfiliado);
        console.log(fechaInicio);
        console.log(fechaFin);
        const query = 'SELECT obtener_estado_prestamos($1,$2,$3)';
        const values = [codigoAfiliado, fechaInicio, fechaFin];
        const result = await pool.query(query, values);
        const reportesPagos = result.rows[0].obtener_estado_prestamos;
        console.log(reportesPagos);
        if (reportesPagos != null) {
            res.json({ success: true, data: reportesPagos});
        } else {
            res.json({ success: false, message: 'No se encontraron datos dentro del rango seleccionado.'})
        }
    } catch {
        console.log('No se pudo obtener los datos de los pagos');
    }
})

app.get('/api/obtener-fecha-actual', async (req, res) => {
    try {
        const query = 'SELECT obtener_fecha_actual()';
        const result = await pool.query(query);
        const fechaActual = result.rows[0].obtener_fecha_actual;
        console.log(fechaActual);
        if (fechaActual != null) {
            res.json({ success: true, data: fechaActual});
        } else {
            res.json({ success: false, message: 'No se encontro fecha.'})
        }
    } catch {
        console.log('No se encontro fecha');
    }
})


app.listen(port, '0.0.0.0', () => {
    console.log(`Servidor Express escuchando en el puerto ${port}`);
});

