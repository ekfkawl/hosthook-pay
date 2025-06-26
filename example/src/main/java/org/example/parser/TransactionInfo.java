package org.example.parser;

import lombok.Data;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TransactionInfo {
    private final LocalDateTime dateTime;
    private final BigDecimal amount;
    private final String senderName;
    private final String accountNumber;

    @Override
    public String toString() {
        return "TransactionInfo{" +
                "dateTime=" + dateTime +
                ", amount=" + amount +
                ", senderName='" + senderName + '\'' +
                ", accountNumber='" + accountNumber + '\'' +
                '}';
    }
}
