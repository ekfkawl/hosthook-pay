package org.example.dto;

import lombok.Builder;
import lombok.Data;
import org.example.entity.Order;

import java.time.LocalDateTime;

@Data
@Builder
public class OrderResponse {
    private String orderNumber;
    private String status;
    private Integer orderAmount;
    private LocalDateTime orderDate;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static OrderResponse fromEntity(Order o) {
        return OrderResponse.builder()
                .orderNumber(o.getOrderNumber())
                .status(o.getStatus().name())
                .orderAmount(o.getOrderAmount())
                .orderDate(o.getOrderDate())
                .createdAt(o.getCreatedAt())
                .updatedAt(o.getUpdatedAt())
                .build();
    }
}