import React, { useState, useEffect } from 'react';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { format, addMonths, lastDayOfMonth, isFirstDayOfMonth, subMonths } from 'date-fns';
import es from 'date-fns/locale/es'; 

const SelectorRango = ({ onPeriodoSeleccionado }) => {
  const fechaActual = new Date();
  const primerDiaMesActual = new Date(fechaActual.getFullYear(), fechaActual.getMonth(), 1);
  const ultimoDiaMesActual = new Date(fechaActual.getFullYear(), fechaActual.getMonth() + 1, 0);
  const [fechaInicio, setFechaInicio] = useState(primerDiaMesActual);
  const [fechaFin, setFechaFin] = useState(ultimoDiaMesActual);

  const handleChangeInicio = (fechaSeleccionada) => {
    setFechaInicio(fechaSeleccionada);
  };

  const handleChangeFin = (fechaSeleccionada) => {
    setFechaFin(fechaSeleccionada);
  };

  const handleNextMonthStart = () => {
    const siguienteMes = addMonths(fechaInicio, 1);
    const primerDiaSiguienteMes = new Date(siguienteMes.getFullYear(), siguienteMes.getMonth(), 1);
    
    if (primerDiaSiguienteMes <= fechaFin) {
      setFechaInicio(primerDiaSiguienteMes);
    } else {
      setFechaInicio(primerDiaSiguienteMes);
      setFechaFin(lastDayOfMonth(primerDiaSiguienteMes));
    }
  };
  
  const handlePreviousMonthStart = () => {
    const mesPasado = subMonths(fechaInicio, 1);
    const primerDiaMesPasado = new Date(mesPasado.getFullYear(), mesPasado.getMonth(), 1);
    
    if (primerDiaMesPasado <= fechaFin) {
      setFechaInicio(primerDiaMesPasado);
    } else {
      setFechaInicio(primerDiaMesPasado);
      setFechaFin(lastDayOfMonth(primerDiaMesPasado));
    }
  };
  
  const handleNextMonthEnd = () => {
    const siguienteMes = addMonths(fechaFin, 1);
    const ultimoDia = lastDayOfMonth(siguienteMes);
    
    if (ultimoDia >= fechaInicio) {
      setFechaFin(ultimoDia);
    } else {
      setFechaFin(ultimoDia);
      setFechaInicio(new Date(siguienteMes.getFullYear(), siguienteMes.getMonth(), 1));
    }
  };
  
  const handlePreviousMonthEnd = () => {
    const mesPasado = subMonths(fechaFin, 1);
    const ultimoDiaMesPasado = lastDayOfMonth(mesPasado);
    setFechaFin(ultimoDiaMesPasado);
  };
  
  

  const formattedFechaInicio = format(fechaInicio, 'dd-MMMM yyyy', { locale: es });
  const formattedFechaFin = format(fechaFin, 'dd-MMMM yyyy', { locale: es });

  useEffect(() => {
    onPeriodoSeleccionado({
      fechaInicio: fechaInicio.toLocaleDateString('en-CA'),
      fechaFin: fechaFin.toLocaleDateString('en-CA'),
    });
  }, [fechaInicio, fechaFin, onPeriodoSeleccionado]);

  return (
    <div>
      <div><h4> {formattedFechaInicio} ---- {formattedFechaFin}</h4></div>
      <div>
        <label>Desde: </label>
        <button onClick={handlePreviousMonthStart}> &lt;</button>
        <DatePicker
          selected={fechaInicio}
          onChange={handleChangeInicio}
          dateFormat="dd-MM-yyyy"
          showMonthYearPicker
        />
        <button onClick={handleNextMonthStart}> &gt;</button>

        <label> Hasta: </label>
        <button onClick={handlePreviousMonthEnd}> &lt;</button>
        <DatePicker
          selected={fechaFin}
          onChange={handleChangeFin}
          dateFormat="dd-MM-yyyy"
          showMonthYearPicker
        />
        <button onClick={handleNextMonthEnd}> &gt;</button>
      </div>
    </div>
  );
};

export default SelectorRango;
