package co.coodrosan.contingencia.web;

import co.coodrosan.contingencia.model.Price;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

// La fachada del strangler (Fase 10): la misma pregunta que el contrato de pricing,
// GET /prices/{sku}?store=, contestada por Contingencia. Andrés la escribió para que el Gateway
// pudiera repartir el tráfico de precios entre el sistema viejo y el nuevo con la misma petición.
@WebServlet("/prices/*")
public class PriceFacadeServlet extends HttpServlet {

    @PersistenceContext(unitName = "contingencia")
    private EntityManager em;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String sku = req.getPathInfo() == null ? "" : req.getPathInfo().substring(1);
        String store = req.getParameter("store") == null ? "DRO-001" : req.getParameter("store");
        List<Price> found = em.createQuery(
                "SELECT p FROM Price p WHERE p.sku = :sku AND p.storeId = :store", Price.class)
            .setParameter("sku", sku).setParameter("store", store).getResultList();
        resp.setContentType("application/json");
        // Una cabecera para saber, desde afuera, quién contestó.
        resp.setHeader("X-Contestado-Por", "contingencia");
        if (found.isEmpty()) {
            resp.setStatus(404);
            resp.getWriter().write("{\"error\":\"not_found\"}");
            return;
        }
        resp.getWriter().write("{\"sku\":\"" + sku + "\",\"store\":\"" + store + "\",\"price\":"
            + found.get(0).getAmount() + ",\"currency\":\"COP\"}");
    }
}
