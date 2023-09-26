import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Dividendos.css'
import SelectorPeriodo from './SelectorPeriodo';



function Dividendos() {

  const [dividendosData, setDividendosData] = useState('');
  const [mostrarTabla, setMostarTabla] = useState(false);  
  const [mensaje, setMensaje] = useState('');
  const [fecha, setFecha] = useState('');

  const handleObtenerDividendos = () => {
    axios.get(`http://localhost:4000/api/obtener-dividendos?fecha=${fecha}`)
      .then((response) => {
        if (response.data.success) {
            setDividendosData(response.data.data.obtener_dividendos);
            setMostarTabla(true);
            setMensaje('');
        } else {
            setMostarTabla(false);
            setMensaje('No se encontraron datos.');
        }
      })
  }

  const handleFechaSeleccionada = (periodo) => {
    setFecha(periodo)
  }

  return (
    <div>
        <div className='date-container'>
          <div>
            <h2>Dividendos</h2>
            <SelectorPeriodo onPeriodoSeleccionado={handleFechaSeleccionada}/>
            <button onClick={handleObtenerDividendos}>Generar Dividendos</button>
            <p>{mensaje}</p>
          </div>
          
        </div>
        {mostrarTabla && (
            
            <div className='container-datos'>
                <div>
                    <p>Ganancia:</p>
                </div>
                <table>
                    <thead>
                    <tr>
                        <th>Afiliado</th>
                        <th>Saldo en Aportaciones</th>
                        <th>Porcentaje de Participación</th>
                        <th>Ganancia</th>
                    </tr>
                    </thead>
                    <tbody>
                        {dividendosData.map((dividendo, index) => (
                            <tr key={index}>
                                <td> {dividendo.nombre_afiliado} {dividendo.apellido_afiliado}</td>
                                <td>L. {dividendo.saldo_aportaciones}</td>
                                <td> {dividendo.porcentaje_participacion}%</td>
                                <td>L. {dividendo.ganancia} </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )
        }
    </div>
  )
}

export default Dividendos;
