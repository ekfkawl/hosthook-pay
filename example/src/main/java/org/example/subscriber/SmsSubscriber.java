package org.example.subscriber;

import lombok.RequiredArgsConstructor;
import org.example.parser.IBKSmsParser;
import org.example.parser.Notification;
import org.example.parser.TransactionInfo;
import org.example.service.PaymentService;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class SmsSubscriber {
    private final PaymentService paymentService;

    public void onMessage(String message) {
        Notification noti = Notification.parseNotification(message);
        if (noti == null) {
            return;
        }

        try {
            TransactionInfo ti = IBKSmsParser.parse(noti.getText());
            paymentService.processDeposit(ti);
        } catch (IllegalArgumentException e) {
            System.err.println("SMS 포맷 오류: " + e.getMessage());
        }
    }
}