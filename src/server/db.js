const { Pool } = require('pg') ;

const pool = new Pool({
        user: 'cooperativauser',
        host: 'localhost',
        database: 'Cooperativa',
        password: '1234',
        port: 5432
})

module.exports = pool;