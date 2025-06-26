package org.example.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class OrderNumberRequest {
    @NotBlank(message = "주문번호를 입력해주세요.")
    private String orderNumber;
}