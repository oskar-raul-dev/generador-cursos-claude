namespace Sige.Forms
{
    /// <summary>
    /// Generado por el diseñador de Visual Studio 2015 y editado a mano dos veces desde entonces.
    ///
    /// El original tiene 400 lineas con las posiciones de veintitres controles; aqui estan los
    /// cinco que el curso usa, con la misma forma que el diseñador genera: posiciones en pixeles
    /// absolutos -que es lo que se rompe con densidad por monitor- y nombres con prefijo de tipo.
    ///
    /// NO SE EDITA A MANO en el curso: se edita con el diseñador, y comprobar que el diseñador
    /// sigue funcionando despues de migrar es el criterio 1 del miniproyecto de la fase 12.
    /// </summary>
    partial class StockForm
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.cmbAlmacen = new System.Windows.Forms.ComboBox();
            this.txtBuscar = new System.Windows.Forms.TextBox();
            this.btnConsultar = new System.Windows.Forms.Button();
            this.grdExistencias = new System.Windows.Forms.DataGridView();
            this.lblEstado = new System.Windows.Forms.Label();
            this.SuspendLayout();

            // cmbAlmacen
            this.cmbAlmacen.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cmbAlmacen.Location = new System.Drawing.Point(12, 12);
            this.cmbAlmacen.Name = "cmbAlmacen";
            this.cmbAlmacen.Size = new System.Drawing.Size(220, 21);
            this.cmbAlmacen.Items.AddRange(new object[] {
                "BOG - Bogota",
                "MEX - Ciudad de Mexico",
                "LIM - Lima"});

            // txtBuscar
            this.txtBuscar.Location = new System.Drawing.Point(248, 12);
            this.txtBuscar.Name = "txtBuscar";
            this.txtBuscar.Size = new System.Drawing.Size(300, 20);

            // btnConsultar
            this.btnConsultar.Location = new System.Drawing.Point(564, 10);
            this.btnConsultar.Name = "btnConsultar";
            this.btnConsultar.Size = new System.Drawing.Size(96, 25);
            this.btnConsultar.Text = "Consultar";
            this.btnConsultar.Click += new System.EventHandler(this.btnConsultar_Click);

            // grdExistencias
            this.grdExistencias.AllowUserToAddRows = false;
            this.grdExistencias.Location = new System.Drawing.Point(12, 45);
            this.grdExistencias.Name = "grdExistencias";
            this.grdExistencias.ReadOnly = true;
            this.grdExistencias.Size = new System.Drawing.Size(860, 420);

            // lblEstado
            this.lblEstado.Location = new System.Drawing.Point(12, 476);
            this.lblEstado.Name = "lblEstado";
            this.lblEstado.Size = new System.Drawing.Size(860, 18);
            this.lblEstado.Text = "Listo";

            // StockForm
            this.ClientSize = new System.Drawing.Size(884, 505);
            this.Controls.Add(this.lblEstado);
            this.Controls.Add(this.grdExistencias);
            this.Controls.Add(this.btnConsultar);
            this.Controls.Add(this.txtBuscar);
            this.Controls.Add(this.cmbAlmacen);
            this.Name = "StockForm";
            this.Text = "SIGE - Existencias por almacen";
            this.ResumeLayout(false);
        }
    }
}
