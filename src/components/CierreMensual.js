import React, { useState } from 'react';
import axios from 'axios';
import SelectorPeriodo from './SelectorPeriodo';
import './CierreMensual.css'

function CierreMensual() {

  
  //const fechaActual = new Date;
  const [fecha, setFecha] = useState('');
  const [mensaje, setMensaje] = useState('');

  const handleCierreMensual = () => {
    axios.post('http://localhost:4000/api/cierre', {fecha})
      .then((response) => {
        if (response.data.success) {
          setMensaje(response.data.message);
          console.log(response.data.message);
        } else {
          setMensaje(response.data.message);
        }
      })
  }

  const handleFechaSeleccionada = (periodo) => {
    setFecha(periodo)
  }

  return (
    <div className='date-container'>
      
      <div>
        <h2>Cierre Mensual</h2>
        <SelectorPeriodo onPeriodoSeleccionado={handleFechaSeleccionada}/>
        <button onClick={handleCierreMensual}>Cerrar Mes</button>
        <p>{mensaje}</p>
      </div>
      
    </div>
  )
}

export default CierreMensual;
