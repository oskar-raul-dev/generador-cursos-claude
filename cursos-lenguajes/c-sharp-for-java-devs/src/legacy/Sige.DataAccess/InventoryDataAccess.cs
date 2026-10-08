using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace Sige.DataAccess
{
    /// <summary>
    /// Acceso a datos del modulo de existencias. Escrito en 2017 sobre .NET
    /// Framework 4.5 por tres pasantes que aprendieron C# de un libro anterior
    /// a 2008: sin var, sin LINQ, sin async, sin genericos mas alla de List.
    ///
    /// El destino subio a 4.8 en 2021 porque una actualizacion de Windows rompio
    /// un controlador de impresora fiscal. Fue el unico cambio que este codigo
    /// recibio en nueve anios, y no arreglo nada de fondo.
    ///
    /// Este archivo NO SE MODERNIZA. Ni un var, ni un using, ni un nombre nuevo.
    /// Lo que se hace con el esta en las fases 09, 10 y 11.
    /// </summary>
    public class InventoryDataAccess
    {
        private string connectionString;

        public InventoryDataAccess()
        {
            // La cadena se lee del App.config de la instalacion. Cada uno de los
            // noventa equipos tiene su copia, y todas dicen lo mismo.
            this.connectionString =
                ConfigurationManager.ConnectionStrings["SigeConnection"].ConnectionString;
        }

        /// <summary>
        /// Devuelve las existencias de un almacen. El formulario llama a esto
        /// desde el Click del boton y ata la grilla directo al DataTable.
        /// </summary>
        public DataSet GetStockByWarehouse(string warehouseCode)
        {
            DataSet result = new DataSet();
            SqlConnection connection = null;

            try
            {
                connection = new SqlConnection(this.connectionString);

                SqlCommand command = new SqlCommand("SP_EXIST_ALMACEN", connection);
                command.CommandType = CommandType.StoredProcedure;
                command.CommandTimeout = 120;
                command.Parameters.Add("@CODALMA", SqlDbType.Char, 3).Value = warehouseCode;

                SqlDataAdapter adapter = new SqlDataAdapter(command);
                adapter.Fill(result, "EXISTENCIAS");
            }
            catch (Exception ex)
            {
                // Se registra en un archivo de texto y se relanza. El archivo se
                // rota a mano cuando alguien se acuerda.
                LogError("GetStockByWarehouse", ex);
                throw;
            }
            finally
            {
                // El try/finally escrito a mano, con la comprobacion de nulo antes
                // de cerrar. Es lo que se escribia antes de using, y es lo que hay
                // en los cuarenta metodos de esta clase.
                if (connection != null)
                {
                    connection.Close();
                }
            }

            return result;
        }

        /// <summary>
        /// Inserta un movimiento. Devuelve el consecutivo que asigno el motor.
        /// </summary>
        public int InsertMovement(
            string warehouseCode,
            string editionCode,
            string movementDate,
            string movementType,
            int quantity,
            decimal unitPrice,
            string documentNumber,
            string userCode)
        {
            int movementNumber = 0;
            SqlConnection connection = null;

            try
            {
                connection = new SqlConnection(this.connectionString);
                connection.Open();

                SqlCommand command = new SqlCommand("SP_MOVINVEN_INS", connection);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add("@CODALMA", SqlDbType.Char, 3).Value = warehouseCode;
                command.Parameters.Add("@CODEDIT", SqlDbType.Char, 10).Value = editionCode;
                command.Parameters.Add("@FECMOVTO", SqlDbType.Char, 8).Value = movementDate;
                command.Parameters.Add("@TIPOMOVTO", SqlDbType.Char, 1).Value = movementType;
                command.Parameters.Add("@CANTIDAD", SqlDbType.Int).Value = quantity;
                command.Parameters.Add("@VLRUNIT", SqlDbType.Decimal).Value = unitPrice;
                command.Parameters.Add("@NRODOCTO", SqlDbType.Char, 15).Value = documentNumber;
                command.Parameters.Add("@CODUSUA", SqlDbType.Char, 10).Value = userCode;

                object scalar = command.ExecuteScalar();

                if (scalar != null && scalar != DBNull.Value)
                {
                    movementNumber = Convert.ToInt32(scalar);
                }
            }
            catch (SqlException ex)
            {
                LogError("InsertMovement", ex);
                throw;
            }
            finally
            {
                if (connection != null)
                {
                    connection.Close();
                }
            }

            return movementNumber;
        }

        /// <summary>
        /// El reporte historico. Recibe el rango de anios y se lo pasa al
        /// procedimiento, que arma el UNION ALL de las treinta tablas.
        /// </summary>
        public DataSet GetSalesHistory(int yearFrom, int yearTo, string imprintCode)
        {
            DataSet result = new DataSet();
            SqlConnection connection = null;

            try
            {
                connection = new SqlConnection(this.connectionString);

                SqlCommand command = new SqlCommand("SP_VENTAS_HIST", connection);
                command.CommandType = CommandType.StoredProcedure;

                // Diez minutos. Se subio de 120 a 600 en 2022 porque el reporte
                // empezo a agotar el tiempo de espera, y ese fue el arreglo.
                command.CommandTimeout = 600;

                command.Parameters.Add("@ANIODESDE", SqlDbType.Int).Value = yearFrom;
                command.Parameters.Add("@ANIOHASTA", SqlDbType.Int).Value = yearTo;

                if (imprintCode == null || imprintCode.Length == 0)
                {
                    command.Parameters.Add("@CODSELLO", SqlDbType.Char, 3).Value = DBNull.Value;
                }
                else
                {
                    command.Parameters.Add("@CODSELLO", SqlDbType.Char, 3).Value = imprintCode;
                }

                SqlDataAdapter adapter = new SqlDataAdapter(command);

                // Trae las 500.000 filas a memoria, con un DataRow por fila y un
                // object por celda. En 2017 era la forma normal de traer un
                // resultado: IAsyncEnumerable no existia y no existiria hasta 2019.
                adapter.Fill(result, "VENTAS");
            }
            catch (Exception ex)
            {
                LogError("GetSalesHistory", ex);
                throw;
            }
            finally
            {
                if (connection != null)
                {
                    connection.Close();
                }
            }

            return result;
        }

        private void LogError(string operation, Exception ex)
        {
            try
            {
                string path = ConfigurationManager.AppSettings["RutaReportes"] + "\\sige_error.log";
                string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " +
                              operation + " " + ex.Message + Environment.NewLine;

                System.IO.File.AppendAllText(path, line);
            }
            catch
            {
                // Si no se puede escribir el log, no se hace nada. Es la razon por
                // la que a veces no hay rastro de un fallo.
            }
        }
    }
}
