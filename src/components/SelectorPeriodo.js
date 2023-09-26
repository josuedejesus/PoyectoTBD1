import React, { useState, useEffect } from 'react';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { format, addMonths, subMonths, lastDayOfMonth } from 'date-fns';
import es from 'date-fns/locale/es'; 


const SelectorPeriodo = ({onPeriodoSeleccionado}) => {
  const fechaActual = new Date();
  const ultimoDiaMesActual = new Date(fechaActual.getFullYear(), fechaActual.getMonth() + 1, 0);
  const [fechaSeleccionada, setFechaSeleccionada] = useState(ultimoDiaMesActual);
  const [primerRender, setPrimerRender] = useState(true);

  useEffect(() => {
    if (!primerRender) {
      onPeriodoSeleccionado(fechaSeleccionada.toLocaleDateString('en-CA'));
    } else {
      setPrimerRender(false);
    }
  }, [fechaSeleccionada, primerRender, onPeriodoSeleccionado]);

  const handleChange = (fechaSeleccionada) => {
    setFechaSeleccionada(fechaSeleccionada);
  };

  const handleNextMonth = () => {
    const siguienteMes = addMonths(fechaSeleccionada, 1);
    const ultimoDia = lastDayOfMonth(siguienteMes);
    setFechaSeleccionada(ultimoDia);
    onPeriodoSeleccionado(fechaSeleccionada.toLocaleDateString('en-CA'));
  };

  const formattedDate = format(fechaSeleccionada, 'MMMM dd yyyy', { locale: es });

  return (
    <div>
      <div>Periodo Actual: {formattedDate}</div>
      <DatePicker
        selected={fechaSeleccionada}
        onChange={handleChange}
        dateFormat="dd-MM-yyyy"
        showMonthYearPicker
      />
      <button onClick={handleNextMonth}>Siguiente Periodo</button>
      
    </div>
  );
};

export default SelectorPeriodo;
