using System;
using System.Data;
using System.Windows.Forms;
using Sige.DataAccess;

namespace Sige.Forms
{
    /// <summary>
    /// Consulta de existencias por almacen. Uno de los 340 formularios de 2017, y el unico que el
    /// curso construye: tiene busqueda, grilla con volumen real, edicion y un reporte, asi que
    /// sirve de caso de prueba para todo el Bloque C.
    ///
    /// El diseñador (StockForm.Designer.cs) no esta en el repositorio a proposito: son 400 lineas
    /// generadas de posiciones de controles que no enseñan nada. Los controles se declaran aqui,
    /// con los nombres que el diseñador les habria puesto, y los textos en español porque los leen
    /// las noventa personas de Cordillera.
    ///
    /// Este archivo NO SE MODERNIZA. Lo que se hace con el esta en las fases 12 y 13.
    /// </summary>
    public partial class StockForm : Form
    {
        private ComboBox cmbAlmacen;
        private TextBox txtBuscar;
        private Button btnConsultar;
        private DataGridView grdExistencias;
        private Label lblEstado;

        private InventoryDataAccess dataAccess;

        public StockForm()
        {
            InitializeComponent();
            this.dataAccess = new InventoryDataAccess();
        }

        /// <summary>
        /// El manejador del boton. Aqui esta TODO: la validacion, la consulta, el filtrado, el
        /// calculo del total y el pintado. Son 60 lineas y no hay forma de probar ninguna sin
        /// levantar el formulario.
        ///
        /// Y bloquea la interfaz: mientras la consulta corre -ocho segundos para el almacen de
        /// Bogota-, la ventana no repinta y Windows la marca como "no responde".
        /// </summary>
        private void btnConsultar_Click(object sender, EventArgs e)
        {
            if (this.cmbAlmacen.SelectedItem == null)
            {
                MessageBox.Show("Seleccione un almacen.", "SIGE");
                return;
            }

            string codigoAlmacen = this.cmbAlmacen.SelectedItem.ToString().Substring(0, 3);

            this.btnConsultar.Enabled = false;
            this.lblEstado.Text = "Consultando...";

            try
            {
                // La llamada sincronica que congela la ventana. En 2017 no habia alternativa
                // razonable en este codigo: async/await existia desde 2012 pero quien escribio
                // esto aprendio C# de un libro anterior.
                DataSet datos = this.dataAccess.GetStockByWarehouse(codigoAlmacen);

                DataTable tabla = datos.Tables["EXISTENCIAS"];

                // El filtro de busqueda, aplicado en memoria sobre el DataTable. Con 50.000 filas
                // esto asigna una cadena por fila y vuelve a recorrer todo en cada tecla si
                // alguien conecta el TextChanged, que es lo que paso en 2019 y se revirtio.
                if (this.txtBuscar.Text.Trim().Length > 0)
                {
                    string filtro = "TITULO LIKE '%" + this.txtBuscar.Text.Trim().Replace("'", "''") + "%'";
                    tabla.DefaultView.RowFilter = filtro;
                }

                this.grdExistencias.DataSource = tabla;

                // El total, calculado recorriendo la grilla a mano. La logica de negocio -que un
                // ajuste negativo resta y una devolucion suma- esta AQUI y en ningun otro sitio,
                // asi que nadie la puede probar ni reusar.
                int total = 0;
                int sinTitulo = 0;

                for (int i = 0; i < tabla.DefaultView.Count; i++)
                {
                    DataRowView fila = tabla.DefaultView[i];

                    if (fila["SALDO"] != DBNull.Value)
                    {
                        total = total + Convert.ToInt32(fila["SALDO"]);
                    }

                    // Los movimientos cuya edicion ya no existe: el titulo viene en blanco y el
                    // almacen ya esta acostumbrado a verlos asi.
                    if (fila["TITULO"] == DBNull.Value || fila["TITULO"].ToString().Length == 0)
                    {
                        sinTitulo = sinTitulo + 1;
                    }
                }

                this.lblEstado.Text = "Total: " + total.ToString("N0") +
                                      " unidades en " + tabla.DefaultView.Count.ToString("N0") + " registros" +
                                      (sinTitulo > 0 ? " (" + sinTitulo.ToString() + " sin titulo)" : "");
            }
            catch (Exception ex)
            {
                // MessageBox como manejo de errores. En dos formularios de SIGE este MessageBox
                // quedo en produccion dentro de un bucle, y el usuario tiene que cerrar cuarenta
                // ventanas seguidas.
                MessageBox.Show("Error al consultar: " + ex.Message, "SIGE",
                                MessageBoxButtons.OK, MessageBoxIcon.Error);
                this.lblEstado.Text = "Error";
            }
            finally
            {
                this.btnConsultar.Enabled = true;
            }
        }
    }
}
