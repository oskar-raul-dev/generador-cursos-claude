using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace Sige.DataAccess
{
    /// <summary>
    /// Acceso a datos de la liquidacion de regalias. Mismo estilo, misma epoca.
    /// El calculo no esta aqui: esta en SP_LIQREGAL_CALC, y esta clase solo lo
    /// invoca y trae el resultado.
    ///
    /// Que la logica de negocio viva en el procedimiento no fue una decision de
    /// arquitectura: fue donde los pasantes sabian ponerla, porque venian de
    /// FoxPro y en FoxPro la logica estaba en el codigo del formulario o en el
    /// motor. Lo que no cupo en el procedimiento quedo en el Click del boton.
    /// </summary>
    public class RoyaltyDataAccess
    {
        private string connectionString;

        public RoyaltyDataAccess()
        {
            this.connectionString =
                ConfigurationManager.ConnectionStrings["SigeConnection"].ConnectionString;
        }

        /// <summary>
        /// Dispara la liquidacion de un trimestre. Seis horas. Sin forma de
        /// detenerla, sin forma de reanudarla, y si falla se reinicia desde cero.
        /// </summary>
        public int RunSettlement(string period)
        {
            int settlements = 0;
            SqlConnection connection = null;

            try
            {
                connection = new SqlConnection(this.connectionString);
                connection.Open();

                SqlCommand command = new SqlCommand("SP_LIQREGAL_CALC", connection);
                command.CommandType = CommandType.StoredProcedure;

                // Cero significa sin limite. Es lo que hay que poner cuando el
                // procedimiento tarda seis horas y no se puede partir.
                command.CommandTimeout = 0;

                command.Parameters.Add("@PERIODO", SqlDbType.Char, 6).Value = period;

                SqlDataReader reader = command.ExecuteReader();

                if (reader.Read())
                {
                    settlements = Convert.ToInt32(reader["LIQUIDACIONES"]);
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                LogError("RunSettlement", ex);
                throw;
            }
            finally
            {
                if (connection != null)
                {
                    connection.Close();
                }
            }

            return settlements;
        }

        /// <summary>
        /// Trae una liquidacion con su detalle, para el formulario de consulta.
        /// Dos consultas en el mismo DataSet, relacionadas a mano porque no hay
        /// llaves foraneas que el adaptador pueda descubrir.
        /// </summary>
        public DataSet GetSettlement(string settlementNumber)
        {
            DataSet result = new DataSet();
            SqlConnection connection = null;

            try
            {
                connection = new SqlConnection(this.connectionString);

                // SQL concatenado con el parametro adentro. Con un char(12) que
                // viene de una grilla nunca fue un problema, y por eso sigue asi.
                string sql =
                    "SELECT * FROM LIQREGAL WHERE NROLIQUI = '" + settlementNumber + "' " +
                    "AND BORRADO = 'N'; " +
                    "SELECT * FROM LIQDETAL WHERE NROLIQUI = '" + settlementNumber + "' " +
                    "AND BORRADO = 'N' ORDER BY NROLINEA";

                SqlCommand command = new SqlCommand(sql, connection);
                command.CommandTimeout = 120;

                SqlDataAdapter adapter = new SqlDataAdapter(command);
                adapter.Fill(result);

                result.Tables[0].TableName = "LIQUIDACION";
                result.Tables[1].TableName = "DETALLE";

                // La relacion, a mano. Si el detalle trae una liquidacion que no
                // esta en la primera tabla, esto revienta con una excepcion cuyo
                // mensaje no dice cual fila fue.
                result.Relations.Add(
                    "LIQ_DET",
                    result.Tables["LIQUIDACION"].Columns["NROLIQUI"],
                    result.Tables["DETALLE"].Columns["NROLIQUI"]);
            }
            catch (Exception ex)
            {
                LogError("GetSettlement", ex);
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
            }
        }
    }
}
