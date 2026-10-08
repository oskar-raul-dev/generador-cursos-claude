package dev.ms.orders.config;

import dev.ms.orders.inventory.GrpcInventory;
import dev.ms.orders.inventory.Inventory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.grpc.client.GrpcChannelFactory;

@Configuration
public class InventoryGrpcConfig {
    // El canal lo abre la fábrica de Boot con spring.grpc.client.channel.inventory.target.
    @Bean
    Inventory inventory(GrpcChannelFactory channels, OrdersProperties props) {
        return new GrpcInventory(channels.createChannel("inventory"), props.inventory().deadlineMs());
    }
}
