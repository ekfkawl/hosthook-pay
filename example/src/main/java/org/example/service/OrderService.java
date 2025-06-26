package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.OrderRequest;
import org.example.entity.Order;
import org.example.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;

    public Optional<Order> findByOrderNumber(String no) {
        return orderRepository.findByOrderNumber(no);
    }

    @Transactional
    public Order createOrder(OrderRequest req) {
        String orderNumber = UUID.randomUUID().toString().substring(0, 8);

        Order o = new Order(req.getDepositorName(),
                orderNumber,
                Order.Status.PENDING,
                req.getOrderAmount());

        return orderRepository.save(o);
    }

    @Transactional
    public void cancelOrder(String orderNumber) {
        Order o = orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() ->
                        new IllegalArgumentException("취소할 주문을 찾을 수 없습니다: " + orderNumber));

        if (o.getStatus() != Order.Status.PENDING) {
            throw new IllegalStateException(
                    "현재 상태가 " + o.getStatus() + " 이므로 취소할 수 없습니다.");
        }

        o.setStatus(Order.Status.CANCELLED);
    }
}