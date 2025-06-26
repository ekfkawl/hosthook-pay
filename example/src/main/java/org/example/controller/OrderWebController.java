package org.example.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.entity.Order;
import org.example.dto.OrderNumberRequest;
import org.example.dto.OrderRequest;
import org.example.dto.OrderResponse;
import org.example.service.OrderService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
@RequiredArgsConstructor
public class OrderWebController {

    private final OrderService orderService;

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/order")
    public String showOrderForm(Model model) {
        model.addAttribute("orderRequest", new OrderRequest());
        return "order_form";
    }

    @PostMapping("/order")
    public String placeOrder(@Valid @ModelAttribute OrderRequest orderRequest, BindingResult bindingResult, Model model) {
        if (bindingResult.hasErrors()) {
            return "order_form";
        }

        Order o = orderService.createOrder(orderRequest);
        model.addAttribute("orderResponse", OrderResponse.fromEntity(o));
        return "order_success";
    }

    @PostMapping("/order/cancel/{orderNumber}")
    public String cancelOrderWeb(@PathVariable String orderNumber, Model model) {
        try {
            orderService.cancelOrder(orderNumber);
            Order o = orderService.findByOrderNumber(orderNumber).get();
            model.addAttribute("orderResponse", OrderResponse.fromEntity(o));
            model.addAttribute("message", "✅ 주문이 취소되었습니다.");
        } catch (Exception e) {
            model.addAttribute("error", e.getMessage());
            orderService.findByOrderNumber(orderNumber)
                    .ifPresent(o -> model.addAttribute("orderResponse", OrderResponse.fromEntity(o)));
        }
        return "status_result";
    }

    @GetMapping("/order/status")
    public String showStatusForm(Model model) {
        model.addAttribute("orderNumberRequest", new OrderNumberRequest());
        return "status_form";
    }

    @PostMapping("/order/status")
    public String checkStatus(
            @Valid @ModelAttribute OrderNumberRequest orderNumberRequest,
            BindingResult bindingResult,
            Model model) {

        if (bindingResult.hasErrors()) {
            return "status_form";
        }

        Order o = orderService.findByOrderNumber(orderNumberRequest.getOrderNumber())
                .orElse(null);

        if (o == null) {
            model.addAttribute("error", "해당 주문번호를 찾을 수 없습니다.");
            return "status_form";
        }

        model.addAttribute("orderResponse", OrderResponse.fromEntity(o));
        return "status_result";
    }
}