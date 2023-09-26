import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './AfiliadosList.css';
import Modal from 'react-modal';
import SelectorRango from './SelectorRango';
import { format, setDate } from 'date-fns';

Modal.setAppElement('#root');

function AfiliadosList() {
  const [codigoAfiliadoSearch, setCodigoAfiliadoSearch] = useState('');
  const [codigoAfiliado, setCodigoAfiliado] = useState('');
  const [afiliadoData, setAfiliadoData] = useState([]);
  const [numeroCuenta1, setNumeroCuenta1] = useState('');
  const [saldo1, setSaldo1] = useState('');
  const [numeroCuenta2, setNumeroCuenta2] = useState('');
  const [saldo2, setSaldo2] = useState('');
  const [primerNombre, setPrimerNombre] = useState('');
  const [segundoNombre, setSegundoNombre] = useState('');
  const [primerApellido, setPrimerApellido] = useState('');
  const [segundoApellido, setSegundoApellido] = useState('');
  const [direccion, setDireccion] = useState('');
  const [ubicacion, setUbicacion] = useState('');
  const [fechaNacimiento, setFechaNacimiento] = useState('');
  const [fechaIngreso, setFechaIngreso] = useState('');
  const [antiguedad, setAntiguedad] = useState('');
  const [cuentaSeleccionada, setCuentaSeleccionada] = useState('');
  const [depositarClicked, setDepositarClicked] = useState(false);
  const [retirarClicked, setRetirarClicked] = useState(false);
  const [monto, setMonto] = useState('0.00');
  const [modalIsOpen, setModalIsOpen] = useState(false);
  const [comentario, setComentario] = useState('');
  const [mensaje, setMensaje] = useState('');
  const [tipoCuenta1, setTipoCuenta1] = useState('');
  const [saldoSeleccionado, setSaldoSeleccionado] = useState('');
  const [tipoCuenta2, setTipoCuenta2] = useState('');
  const [tipoCuentaSelecionada, setTipoCuentaSeleccionada] = useState('');
  const [tipoPrestamo, setTipoPrestamo] = useState('Automatico');
  const [limitePrestamo, setLimiteprestamo] = useState('');
  const [modalPrestamoIsOpen, setmModalPrestamoIsOpen] = useState(false);
  const [periodos, setPeriodos] = useState('1');
  const [mostarDatos, setMostrarDatos] = useState(false);
  const [prestamoResponse, setPrestamoResponse] = useState('');
  const [depositoResponse, setDespositoResponse] = useState('');
  const [retiroResponse, setRetiroResponse] = useState('');
  //const fechaActual = new Date().toLocaleDateString('en-CA');
  const [fechaActual, setFechaActual] = useState('');
  const [fecha, setFecha] = useState(fechaActual);
  const [estado, setEstado] = useState('');
  const [modalLiquidacionIsOpen, setModalLiquidacionIsOpen] = useState(false);
  const [tipoLiquidacion, setTipoLiquidacion] = useState('Total');
  const [liquidacionResponse, setLiquidacionResponse] = useState('');
  const [numeroPrestamo, setNumeroPrestamo] = useState('');
  const [montoPrestamo, setMontoPrestamo] = useState('');
  const [saldoPrestamo, setSaldoPrestamo] = useState('');
  const [referencia, setReferencia] = useState('');
  const [fechaInicio, setFechaInicio] = useState('');
  const [fechaFin, setFechaFin] = useState('');
  const [estadoCuentaData, setEstadoCuentaData] = useState('');
  const [estadoCuentaData2, setEstadoCuentaData2] = useState('');
  const [estadoDividendos, setEstadoDividendos] = useState('');
  const [estadoPrestamos, setEstadoPrestamos] = useState('');

  const [mostrarTablaEstado, setMostarTablaEstado] = useState(false);
  const [mostrarTablaEstado2, setMostarTablaEstado2] = useState(false);
  const [mostrarTablaDividendos, setMostarTablaDividendos] = useState(false);
  const [mostrarTablaPagos, setMostrarTablaPagos] = useState(false);

  useEffect(() => {
    const handleFechaActual = () => {
      axios.get(`http://localhost:4000/api/obtener-fecha-actual`)
        .then((response) => {
          if (response.data.success) {
            setFechaActual(response.data.data);
            const fechaFormateada = format(new Date(response.data.data), 'yyyy-MM-dd');
            setFecha(fechaFormateada);
            console.log(fechaFormateada);
          } else {
            console.log('Error al cargar fecha', response.data.message);
          }
        });
    };
    handleFechaActual();
  }, []);

  const handleBuscarAfiliado = () => {
    axios.get(`http://localhost:4000/api/obtener-afiliado?codigoAfiliado=${codigoAfiliadoSearch}`)
      .then((response) => {
        if (response.data.success) {
          setAfiliadoData(response.data.data);
          if (response.data.data.obtener_afiliado != null) {
            setMostrarDatos(true);
          } else {
            setMostrarDatos(false);
          }
          
        } else {
          console.log('Error:', response.data.message);
        }
      })
      setMostarTablaEstado(false);
      setMostarTablaEstado2(false);
      setMostarTablaDividendos(false);
      setMostrarTablaPagos(false);
  };

  const handleDepositar = () => {
    axios.post('http://localhost:4000/api/deposito', {cuentaSeleccionada, monto, fecha, comentario}) 
      .then((response) => {
        if (response.data.success) {
          setDespositoResponse(response.data.message);
          handleBuscarAfiliado();
        } else {
          console.log('Error:', response.data.message);
        }
      })
      setMonto('0.00');
  }

  const handleRetirar = () => {
    axios.post('http://localhost:4000/api/retiro', {cuentaSeleccionada, monto, fecha, comentario}) 
      .then((response) => {
        if (response.data.success) {
          setRetiroResponse(response.data.message);
          handleBuscarAfiliado();
        }
      })
  }

  const handleSolicitarPrestamo = () => {
    axios.post('http://localhost:4000/api/solicitar-prestamo', {codigoAfiliado, tipoPrestamo, monto, periodos})
    .then((response) => {
      if (response.data.success) {
        setPrestamoResponse(response.data.message);
        handleBuscarAfiliado();
      } else {
        console.log('Error: ', response.data.message);
        setPrestamoResponse(response.data.message);
      }
    })
    setTipoPrestamo('Automatico');
    setLimiteprestamo('');
    setMonto('0.00');
    setPeriodos('1');
  }

  const openModalPrestamos = () => {    
    setmModalPrestamoIsOpen(true);
  }

  const handleLiquidar = () => {
    axios.post('http://localhost:4000/api/liquidacion', {codigoAfiliado, tipoLiquidacion, fecha})
      .then((response) => {
        if (response.data.success) {
          setLiquidacionResponse(response.data.message);
          handleBuscarAfiliado();
        } else {
          setLiquidacionResponse(response.data.message);
        }
      })
    console.log(liquidacionResponse);
  }

  const closeModalPrestamos = () => {
    setmModalPrestamoIsOpen(false);
    setDepositarClicked(false);
    setRetirarClicked(false);

    setTipoPrestamo('Automatico');
    setLimiteprestamo('');
    setMonto('0.00');
    setPeriodos('1');
    setPrestamoResponse('');
  }

  const handleRetirarClick = () => {
    setDepositarClicked(false);
    setRetirarClicked(true);
  }

  const handleTipoPrestamoChange = async (event) => {
    const valorSeleccionado = event.target.value;
    setTipoPrestamo(valorSeleccionado);
    try {
      const response = await axios.get(`http://localhost:4000/api/obtener-limite?codigoAfiliado=${codigoAfiliado}&tipoPrestamo=${valorSeleccionado}`);
      if (response.data.success) {
        setLimiteprestamo(response.data.data.limite_prestamo);   
        
      } else {
        console.log('Error al buscar el afiliado', response.data.message);
      }
    } catch (error) {
      console.error('Error:', error);
    }
  };

  const handlePeriodosChange = async (event) => {
    const valorSeleccionado = event.target.value;
    setPeriodos(valorSeleccionado);
  }
  

  const handleDepositarClick = () => {
    setRetirarClicked(false);
    setDepositarClicked(true);
  }

 

  const openModal = (numeroCuenta, saldo, tipoCuenta) => {
    setCuentaSeleccionada(numeroCuenta);
    setSaldoSeleccionado(saldo);
    setTipoCuentaSeleccionada(tipoCuenta)
    setModalIsOpen(true);
  }

  const closeModal = () => {
    setModalIsOpen(false);
    setDepositarClicked(false);
    setRetirarClicked(false);
    setMonto('');
    setComentario('');
    setDespositoResponse('');
    setRetiroResponse('');
  }

  const openModalLiquidacion = () => {
    setModalLiquidacionIsOpen(true);
  }

  const closeModalLiquidacion = () => {
    setModalLiquidacionIsOpen(false);
    setLiquidacionResponse('');
  }

  const handleRangoSeleccionado = ({fechaInicio, fechaFin}) => {
    setFechaInicio(fechaInicio);
    setFechaFin(fechaFin);
  }

  const handleEstadoCuenta = () => {
    axios.get(`http://localhost:4000/api/obtener-estado-cuenta?numeroCuenta=${numeroCuenta1}&fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`)
        .then((response) => {
          if (response.data.success) {
            const estadoCuenta = response.data.data.generar_estado_cuenta;
            setEstadoCuentaData(estadoCuenta);
            setMostarTablaEstado(true);
            console.log(estadoCuentaData);
          } else {
            setMostarTablaEstado(false)
            console.log('Error al buscar el afiliado', response.data.message);
          }
        });

    axios.get(`http://localhost:4000/api/obtener-estado-cuenta?numeroCuenta=${numeroCuenta2}&fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`)
        .then((response) => {
          if (response.data.success) {
            const estadoCuenta = response.data.data.generar_estado_cuenta;
            setEstadoCuentaData2(estadoCuenta);
            setMostarTablaEstado2(true);
            console.log(estadoCuentaData);
          } else {
            setMostarTablaEstado2(false)
            console.log('Error al buscar el afiliado', response.data.message);
          }
        });

    axios.get(`http://localhost:4000/api/obtener-estado-dividendos?codigoAfiliado=${codigoAfiliado}&fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`)
        .then((response) => {
          if (response.data.success) {
            const respuesta = response.data.data;
            setEstadoDividendos(respuesta);
            setMostarTablaDividendos(true);
            console.log(estadoDividendos);
          } else {
            setMostarTablaDividendos(false)
            console.log('Error al buscar el afiliado', response.data.message);
          }
        });

    axios.get(`http://localhost:4000/api/obtener-estado-prestamos?codigoAfiliado=${codigoAfiliado}&fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`)
        .then((response) => {
          if (response.data.success) {
            const respuesta = response.data.data;
            setEstadoPrestamos(respuesta);
            setMostrarTablaPagos(true);
            console.log(estadoPrestamos);
          } else {
            setMostrarTablaPagos(false)
            console.log('Error al buscar el afiliado', response.data.message);
          }
        });
  };

  useEffect(() => {
    if (afiliadoData && Array.isArray(afiliadoData.obtener_afiliado)) {
      const afiliados = afiliadoData.obtener_afiliado;
      setCodigoAfiliado(afiliados[0].codigo_afiliado);
      setPrimerNombre(afiliados[0].primer_nombre);
      setSegundoNombre(afiliados[0].segundo_nombre);
      setPrimerApellido(afiliados[0].primer_apellido);
      setSegundoApellido(afiliados[0].segundo_apellido);
      setNumeroCuenta1(afiliados[0].numero_cuenta);
      setTipoCuenta1(afiliados[0].tipo_cuenta);
      setSaldo1(afiliados[0].saldo);
      setNumeroCuenta2(afiliados[1].numero_cuenta);
      setTipoCuenta2(afiliados[1].tipo_cuenta);
      setSaldo2(afiliados[1].saldo);
      let dir = afiliados[0].calle + ' ' + afiliados[0].avenida + ' ' + afiliados[0].casa;
      let ubicacion = afiliados[0].ciudad + ', ' + afiliados[0].departamento;
      setDireccion(dir);
      setReferencia(afiliados[0].referencia);
      setUbicacion(ubicacion);
      setFechaNacimiento(afiliados[0].fecha_nacimiento);
      setFechaIngreso(afiliados[0].fecha_ingreso);
      setAntiguedad(afiliados[0].antiguedad);
      setNumeroPrestamo(afiliados[0].numero_prestamo);
      setMontoPrestamo(afiliados[0].monto_prestamo);
      setSaldoPrestamo(afiliados[0].saldo_prestamo);
      
      if (afiliados[0].estado == true) {
        setEstado('Activo');
      } else {
        setEstado('Inactivo');
      }
    } else {
      setPrimerNombre('');
      setSegundoNombre('');
      setPrimerApellido('');
      setSegundoApellido('');
      setNumeroCuenta1('');
      setTipoCuenta1('');
      setSaldo1('');
      setNumeroCuenta2('');
      setTipoCuenta2('');
      setSaldo2('');
      setEstado('');
      setReferencia('');
    }
    if (afiliadoData && Array.isArray(afiliadoData.obtener_afiliado)) {
      setMensaje('');        
    } else {
      setMensaje('No hay afiliado seleccionado.');  
    }
    handleTipoPrestamoChange({ target: { value: tipoPrestamo } });
  }) 

  return (
    <div>
      <div className='fecha-container'>
          <div className='cont-container'>
          <label>Fecha:</label>
          <input
            type="date"
            value={fecha}
            onChange={(e) => setFecha(e.target.value)}
          />
          </div>
          
      </div>
      <form className='searchbar-container'>
        <h2>Afiliados</h2>
        <div>
          
          <h3>Buscar Afiliado</h3>
          <input
            type="text"
            value={codigoAfiliadoSearch}
            placeholder="Codigo Afiliado"
            onChange={(e) => setCodigoAfiliadoSearch(e.target.value)}/>
          <button type="button" onClick={handleBuscarAfiliado}>Buscar</button>
          <p>{mensaje}</p>
        </div>
      </form>
      {mostarDatos && (
        <div>
      <div className='info-container'>
        <h3>Cuentas personales</h3>
        <h3> {primerNombre} {segundoNombre} {primerApellido} {segundoApellido} </h3>
        <h3> {codigoAfiliado} </h3>
        <h4>Cuenta - {tipoCuenta1}</h4>
        <div className='cuenta-container'>
          <li> 
            <a href={'#cuenta/${numeroCuenta1}'} onClick={(e) => openModal(numeroCuenta1, saldo1, tipoCuenta1)}>
              {numeroCuenta1}
            </a>
          </li>
        </div>
        <p> L. {saldo1} </p>
        <h4>Cuenta - {tipoCuenta2}</h4>
        <div className='cuenta-container'>
          <li> 
            <a href={'#cuenta/${numeroCuenta2}'} onClick={(e) => openModal(numeroCuenta2, saldo2, tipoCuenta2)}>
              {numeroCuenta2}
            </a>
          </li>
        </div>
        <p> L. {saldo2} </p>
        
      </div>

      <div className='info-container'>
        <h3>Datos del Afiliado</h3>
        <p>Dirección: {direccion}</p>
        <p>Referencia: {referencia}</p>
        <p>Ubicación: {ubicacion}</p>
        <p>Fecha de Nacimiento: {fechaNacimiento}</p>
        <p>Fecha de Ingreso: {fechaIngreso}</p>
        <p>Antiguedad: {antiguedad} meses</p>
        <p>Estado: {estado} </p>
      </div>

      <div className='info-container'>
        <h3>Préstamos</h3>
        <div>
          <h4>Préstamos Pendientes</h4>
          <p>Número: {numeroPrestamo} </p>
          <p>Monto: L. {montoPrestamo} </p>
          <p>Saldo: L. {saldoPrestamo} </p>
          <div className='acciones-div'>
            <li><a href={'#solicitarPrestamo'} onClick={(e) => openModalPrestamos()}>Solicitar prestamo</a></li>
          </div>
          
        </div>
      </div>

      <div className='info-container'>
        <h3>Liquidación</h3>
        <div className='acciones-div'>
          <li><a href="#liquidacion" onClick={(e) => openModalLiquidacion()}>Liquidar</a></li>
        </div>
      </div>

      <div className='info-container'>
        <h3>Estado de Cuenta</h3>
        <SelectorRango onPeriodoSeleccionado={handleRangoSeleccionado}/>
        <button type='button' onClick={handleEstadoCuenta}>Generar Reporte</button>
        <h4>Cuenta {tipoCuenta1}</h4>
        {mostrarTablaEstado && (
            <div className='tabla-reportes'>
                <table>
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Cuenta</th>
                        <th>Fecha</th>
                        <th>Descripción</th>
                        <th>Monto</th>
                    </tr>
                    </thead>
                    <tbody>
                        {estadoCuentaData.map((dato, index) => (
                            <tr key={index}>
                                <td> {dato.codigo}</td>
                                <td> {dato.numero_cuenta} </td>
                                <td> {dato.fecha} </td>
                                <td> {dato.comentario} </td>
                                <td className='monto'>L. {dato.monto} </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )
        }
        <h4>Cuenta {tipoCuenta2}</h4>
        {mostrarTablaEstado2 && (
            <div className='tabla-reportes'>
                <table>
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Cuenta</th>
                        <th>Fecha</th>
                        <th>Descripción</th>
                        <th>Monto</th>
                    </tr>
                    </thead>
                    <tbody>
                        {estadoCuentaData2.map((dato, index) => (
                            <tr key={index}>
                                <td> {dato.codigo}</td>
                                <td> {dato.numero_cuenta} </td>
                                <td> {dato.fecha} </td>
                                <td> {dato.comentario} </td>
                                <td className='monto'>L. {dato.monto}</td>
                                
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )
        }
        <h4>Dividendos Pagados</h4>
        {mostrarTablaDividendos && (
            <div className='tabla-reportes'>
                <table>
                    <thead>
                    <tr>
                        <th>Fecha</th>
                        <th>Monto</th>
                    </tr>
                    </thead>
                    <tbody>
                        {estadoDividendos.map((dato, index) => (
                            <tr key={index}>
                                <td> {dato.fecha} </td>
                                <td className='monto'>L. {dato.ganancia}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )
        }
        <h4>Pagos a Préstamos</h4>
        {mostrarTablaPagos && (
            <div className='tabla-reportes'>
                <table>
                    <thead>
                    <tr>
                        <th>Número Pago</th>
                        <th>Número Préstamo</th>
                        <th>Fecha</th>
                        <th>Monto</th>
                        <th>Intereses</th>
                        <th>Capital</th>
                        <th>Saldo</th>
                    </tr>
                    </thead>
                    <tbody>
                        {estadoPrestamos.map((pago, index) => (
                            <tr key={index}>
                                <td> {pago.numero_pago}</td>
                                <td> {pago.numero_prestamo} </td>
                                <td> {pago.fecha}</td>
                                <td className='monto'>L. {pago.monto}</td>
                                <td className='monto'>L. {pago.interes}</td>
                                <td className='monto'>L. {pago.capital}</td>
                                <td className='monto'>L. {pago.saldo}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )
        }
      </div>

      <Modal className="modal" isOpen={modalIsOpen} onRequestClose={closeModal} contentLabel="Modal">
        <div className='modal-content'>
          <h2>Cuenta - {tipoCuentaSelecionada}</h2>
          <h3>{cuentaSeleccionada}</h3>
          <h4>L. {saldoSeleccionado} </h4>
          <div className='opciones-cuenta-container'>
            <li><a href={'#cuenta/${depositar}'} onClick={handleDepositarClick} >Deposito</a></li>
            <li><a href={'#cuenta/${retirar}'} onClick={handleRetirarClick} >Retiro</a></li>
          </div>
            {depositarClicked ? (
              <div depositar-container>
                <h3>Deposito</h3>
                <input type="number" placeholder="Monto" value={monto} onChange={(e) => setMonto(e.target.value)}/>
                <input type="text" placeholder="Comentario" onChange={(e) => setComentario(e.target.value)}/>
                <button type="button" onClick={handleDepositar}>Aceptar</button>
                <div><p>{depositoResponse}</p></div>
              </div>
          ) : (
            null
          )}
            {retirarClicked ? (
              <div retirar-container>
                <h3>Retiro</h3>
                <input type="number" placeholder="Monto" value={monto} onChange={(e) => setMonto(e.target.value)}/>
                <input type="text" placeholder="Comentario" onChange={(e) => setComentario(e.target.value)}/>
                <button type="button" onClick={handleRetirar}>Aceptar</button>
                <div><p>{retiroResponse}</p></div>
              </div>
          ) : (
            null
          )}
        </div>
        
      </Modal>  
      <Modal className="modal-prestamos" isOpen={modalPrestamoIsOpen} onRequestClose={closeModalPrestamos} contentLabel="Modal">
      <div className='modal-content'>
        <h3>Solicitar Préstamo</h3>
        <form>
          <div>
            <label>Tipo de Prestamo: </label>
            <select onChange={handleTipoPrestamoChange} value={tipoPrestamo}>
              <option value="Automatico">Automático</option>
              <option value="Fiduciario">Fiduciario</option>
            </select>
          </div>
          <div>
            <label>Limite de Prestamo: L. {limitePrestamo}</label>
          </div>
          <div>
            <label>Monto:</label>
            <input type='number' 
              value={monto}
              placeholder="Monto"
              onChange={(e) => setMonto(e.target.value)}
            />
          </div>
          <div>
            <label>Periodo: </label>
            <select onChange={handlePeriodosChange} value={periodos}>
              {Array.from({ length: 12}, (_, index) => (
                <option key={index} value={index + 1}>
                  {index + 1} meses
                </option>
              ))}
            </select>
          </div>
          <div>
            <button type="button" onClick={handleSolicitarPrestamo}>Aceptar</button>
          </div>
          <div>
            <p>{prestamoResponse}</p>
          </div>
        </form>
      </div> 
      </Modal>

      <Modal className="modal-liquidacion" isOpen={modalLiquidacionIsOpen} onRequestClose={closeModalLiquidacion} contentLabel="Modal">
      <div className='modal-content'>
        <h3>Liquidación</h3>
        <form>
          <div>
            <label>Tipo de Liquidación: </label>
            <select  onChange={(e) => setTipoLiquidacion(e.target.value) }>
              <option value="Total">Total</option>
              <option value="Parcial">Parcial</option>
            </select>
          </div>
    
          <div>
            <button type="button" onClick={handleLiquidar}>Aceptar</button>
          </div>
          <div>
            <p>{liquidacionResponse}</p>
          </div>
        </form>
      </div> 
      </Modal>
        </div>
      )}

      
      
    </div>
  );
}

export default AfiliadosList;
