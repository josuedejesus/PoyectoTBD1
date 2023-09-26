import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './AfiliadosForm.css'

function AfiliadoForm() {
  const [primerNombre, setPrimerNombre] = useState('');
  const [segundoNombre, setSegundoNombre] = useState('');
  const [primerApellido, setPrimerApellido] = useState('');
  const [segundoApellido, setSegundoApellido] = useState('');
  const [calle, setCalle] = useState('');
  const [avenida, setAvenida] = useState('');
  const [casa, setCasa] = useState('');
  const [ciudad, setCiudad] = useState('');
  const [departamento, setDepartamento] = useState('');
  const [referencia, setReferencia] = useState('');
  const [fechaNacimiento, setFechaNacimiento] = useState('2002-01-01');
  const [telefono, setTelefono] = useState('');
  const [correo, setCorreo] = useState('');
  const [anoMinimo, setAnoMinimo] = useState('');
  const [respuesta, setRespuesta] = useState('');

  const handleAgregarAfiliado = () => {
    console.log('Haciendo click');
    const nuevoAfiliado = {
      primerNombre,
      segundoNombre,
      primerApellido,
      segundoApellido,
      calle,
      avenida,
      casa,
      ciudad,
      departamento,
      referencia,
      fechaNacimiento,
      telefono,
      correo,
    };

    console.log('Datos del nuevo afiliado:');
    
    axios.post('http://localhost:4000/api/crear-afiliado', nuevoAfiliado) 
      .then((response) => {
        if (response.data.success) {
          console.log('Afiliado creado con exito');
          setRespuesta(response.data.message);
        } else {
          console.error('Error al crear el afiliado: ', response.data.message);
        }
      })
      .catch((error) => {
        console.error('Error en la solicitud', error);
      })
      setPrimerNombre('');
      setSegundoNombre('');
      setPrimerApellido('');
      setSegundoApellido('');
      setCalle('');
      setAvenida('');
      setCasa('');
      setCiudad('');
      setDepartamento('');
      setReferencia('');
      setFechaNacimiento('2002-01-01');
      setTelefono('');
      setCorreo('');
      console.log(respuesta);
  };

  useEffect(() => {
    const fechaActual = new Date();

    const anoMinimoCalculado = fechaActual.getFullYear() - 21;

    setAnoMinimo(anoMinimoCalculado.toString());
  }, []);


  return (
    <div className='form-container'>
      <h3>Nuevo Afiliado</h3>
      <form>
        <div className="form-group">
          <label>Primer Nombre:</label>
          <input
            type="text"
            value={primerNombre}
            onChange={(e) => setPrimerNombre(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Segundo Nombre:</label>
          <input
            type="text"
            value={segundoNombre}
            onChange={(e) => setSegundoNombre(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Primer Apellido:</label>
          <input
            type="text"
            value={primerApellido}
            onChange={(e) => setPrimerApellido(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Segundo Apellido:</label>
          <input
            type="text"
            value={segundoApellido}
            onChange={(e) => setSegundoApellido(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Calle:</label>
          <input
            type="text"
            value={calle}
            onChange={(e) => setCalle(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Avenida:</label>
          <input
            type="text"
            value={avenida}
            onChange={(e) => setAvenida(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Casa:</label>
          <input
            type="text"
            value={casa}
            onChange={(e) => setCasa(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Ciudad:</label>
          <input
            type="text"
            value={ciudad}
            onChange={(e) => setCiudad(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Departamento:</label>
          <input
            type="text"
            value={departamento}
            onChange={(e) => setDepartamento(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Referencia:</label>
          <input
            type="text"
            value={referencia}
            onChange={(e) => setReferencia(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Fecha de Nacimiento:</label>
          <input
            type="date"
            value="2002-01-01"
            max={`${anoMinimo}-01-01`}
            onChange={(e) => setFechaNacimiento(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Teléfono:</label>
          <input
            type="number"
            value={telefono}
            onChange={(e) => setTelefono(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Correo:</label>
          <input
            type="text"
            value={correo}
            onChange={(e) => setCorreo(e.target.value)}
          />
        </div>
        <div className="form-group">
          <button type="button" onClick={handleAgregarAfiliado}>Agregar</button>
        </div>
        <div>
          <p>{respuesta}</p>
        </div>
      </form>
      
    </div>
  );
}

export default AfiliadoForm;
