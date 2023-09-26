import React from 'react';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import AfiliadosForm from './components/AfiliadosForm';
import AfiliadosList from './components/AfiliadosList';
import Reportes from './components/Reportes';
import CierreMensual from './components/CierreMensual';
import Dividendos from './components/Dividendos';
import './App.css';

function App() {
  return (
    <Router>
      <div>
        <nav>
          <ul>
            <li>
              <Link to="/afiliados">Agregar Afiliados</Link>
            </li>
            <li>
              <Link to="/afiliados-list">Afiliados</Link>
            </li>
            <li>
              <Link to="/cierre-mensual">Cierre Mensual</Link>
            </li>
            <li>
              <Link to="/dividendos">Dividendos</Link>
            </li>
            <li>
              <Link to="/reportes">Reportes</Link>
            </li>
          </ul>
        </nav>
        <Routes>
          <Route path="/afiliados" element={<AfiliadosForm />} />
          <Route path="/afiliados-list" element={<AfiliadosList />} />
          <Route path="/cierre-mensual" element={<CierreMensual />} />
          <Route path="/dividendos" element={<Dividendos />}/>
          <Route path="/reportes" element={<Reportes />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
