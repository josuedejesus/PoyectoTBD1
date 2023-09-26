import React, { useState } from 'react';
import SelectorRango from './SelectorRango';
import axios from 'axios';
import './Reportes.css';

function Reportes() {
  const [mensaje, setMensaje] = useState('');
  const [mostrarTabla, setMostarTabla] = useState(false);
  const [reporteData, setReporteData] = useState('');
  const [fechaInicio, setFechaInicio] = useState('');
  const [fechaFin, setFechaFin] = useState('');

  const handleGenerarReporte = () => {
    axios.get(`http://localhost:4000/api/generar-reporte?fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`)
      .then((response) => {
        if (response.data.success) {
            setReporteData(response.data.data.generar_reporte_dividendos);
            setMostarTabla(true);
            setMensaje('');
        } else {
            setMostarTabla(false);
            setMensaje('No se encontraron datos.');
        }
      })
      console.log(fechaInicio);
      console.log(fechaFin);
  };

  const handleRangoSeleccionado = ({fechaInicio, fechaFin}) => {
    setFechaInicio(fechaInicio);
    setFechaFin(fechaFin);
  }

  return (
    <div>
      <div className='date-container'>
        <div>
          <h2>Generar Reportes</h2>
          <SelectorRango onPeriodoSeleccionado={handleRangoSeleccionado}/>
          <button onClick={handleGenerarReporte}>Generar Reporte</button>
          <p>{mensaje}</p>
        </div>
      </div>
      
      {mostrarTabla && (
    <div className='container-datos'>
        <table>
            <thead>
                <tr>
                    <th>Código Afiliado</th>
                    <th>Fecha</th>
                    <th>Nombre</th>
                    <th>Saldo en Aportaciones</th>
                    <th>Porcentaje de Ganancia</th>
                    <th>Ganancia</th>
                </tr>
            </thead>
            <tbody>
                {reporteData.map((afiliado, index) => (
                    <React.Fragment key={index}>
                        <tr>
                            <td>{afiliado.codigo_afiliado}</td>
                            <td>{afiliado.detalle[0].fecha}</td>
                            <td>{afiliado.detalle[0].primer_nombre} {afiliado.detalle[0].primer_apellido}</td>
                            <td>L. {afiliado.detalle[0].saldo_aportaciones}</td>
                            <td>{afiliado.detalle[0].porcentaje_participacion}%</td>
                            <td>L. {afiliado.detalle[0].ganancia}</td>
                        </tr>
                        {afiliado.detalle.slice(1).map((detalle, i) => (
                            <tr key={i}>
                                <td></td>
                                <td>{detalle.fecha}</td>
                                <td>{detalle.primer_nombre} {detalle.primer_apellido}</td>
                                <td>L. {detalle.saldo_aportaciones}</td>
                                <td>{detalle.porcentaje_participacion}%</td>
                                <td>L. {detalle.ganancia}</td>
                            </tr>
                        ))}
                        <tr className='tr-totales'>
                            <td>Totales</td>
                            <td>------------</td>
                            <td>------------</td>
                            <td>------------</td>
                            <td>------------</td>
                            <td>L. {afiliado.ganancia_total}</td>
                        </tr>
                        
                    </React.Fragment>
                ))}
            </tbody>
        </table>
    </div>
)}
    </div>
  );
}

export default Reportes;
