package org.example.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Entity
@Table(name = "orders",
        indexes = {
                @Index(name = "idx_orders_depositor_name", columnList = "depositor_name"),
                @Index(name = "idx_orders_order_date", columnList = "order_date"),
                @Index(name = "idx_orders_status", columnList = "status")
        }
)
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String depositorName;

    @Column(nullable = false, unique = true)
    private String orderNumber;

    @Column(nullable = false)
    private LocalDateTime orderDate;

    @Setter
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Status status;

    @Column(nullable = false)
    private Integer orderAmount;

    @Column(updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    public enum Status {
        PENDING,
        COMPLETED,
        CANCELLED
    }

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        orderDate = orderDate == null ? now : orderDate;
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    protected Order() {}

    public Order(String depositorName, String orderNumber, Status status, Integer orderAmount) {
        this.depositorName = depositorName;
        this.orderNumber = orderNumber;
        this.status = status;
        this.orderAmount = orderAmount;
    }
}
