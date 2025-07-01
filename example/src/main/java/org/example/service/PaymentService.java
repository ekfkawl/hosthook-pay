package org.example.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.entity.Order;
import org.example.parser.TransactionInfo;
import org.example.repository.OrderRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {
    private final OrderRepository orderRepository;

    protected Order matchPendingOrder(TransactionInfo ti) {
        List<Order> list = orderRepository.findPendingOrders(
                Order.Status.PENDING,
                ti.getSenderName(),
                ti.getAmount().intValue(),
                PageRequest.of(0, 1)
        );

        return list.stream()
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("매칭 가능한 PENDING 주문이 없습니다."));
    }

    @Transactional
    public void processDeposit(TransactionInfo ti) {
        Order order = matchPendingOrder(ti);
        order.setStatus(Order.Status.COMPLETED);
        log.info("결제 처리 완료: {}", ti.toString());
    }
}