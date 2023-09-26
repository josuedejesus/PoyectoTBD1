import React from 'react';
import { createRoot } from 'react-dom/client'
import './index.css';
import App from './App';

const root = createRoot(document.getElementById('root')); // Reemplaza 'root' con el ID de tu elemento de montaje
root.render(<App />); // Reemplaza 'App' con tu componente principal

