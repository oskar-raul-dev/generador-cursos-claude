import java.io.File;
import java.math.BigDecimal;
import java.time.Instant;
import org.apache.avro.Conversions;
import org.apache.avro.Schema;
import org.apache.avro.file.DataFileWriter;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;

public class EscribeAbonos {
    public static void main(String[] args) throws Exception {
        Schema schema = new Schema.Parser().parse(new File("abono.avsc"));
        Schema valor = schema.getField("valor").schema();
        var decimal = new Conversions.DecimalConversion();
        try (var writer = new DataFileWriter<GenericRecord>(new GenericDatumWriter<>(schema))) {
            writer.create(schema, new File("abonos.avro"));
            for (String sede : new String[] {"Suba", "Centro", "Zipaquirá"}) {
                GenericRecord r = new GenericData.Record(schema);
                r.put("sede", sede);
                r.put("valor", decimal.toBytes(new BigDecimal("1250000.10"), valor, valor.getLogicalType()));
                r.put("momento", Instant.parse("2026-10-05T14:30:00Z").toEpochMilli());
                writer.append(r);
            }
        }
        System.out.println("Java escribió abonos.avro con " + schema.getFullName());
    }
}
