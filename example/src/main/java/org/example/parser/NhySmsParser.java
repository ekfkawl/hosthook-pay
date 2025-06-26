package org.example.parser;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.temporal.ChronoField;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class NhySmsParser {
    private static final Pattern NH_PATTERN = Pattern.compile(
              "농협\\s*입금\\s*(?<amount>[\\d,]+)원\\R" +
                    "(?<date>\\d{2}/\\d{2}\\s*\\d{1,2}:\\d{2})\\s+" +
                    "(?<account>[\\d*-]+)\\R" +
                    "(?<name>[^\\r\\n]+)\\s+잔액\\s+[\\d,]+원",
            Pattern.MULTILINE
    );

    private static final DateTimeFormatter DATE_FMT = new DateTimeFormatterBuilder()
            .appendPattern("MM/dd HH:mm")
            .parseDefaulting(ChronoField.YEAR, LocalDate.now().getYear())
            .toFormatter();

    public static TransactionInfo parse(String sms) {
        Matcher m = NH_PATTERN.matcher(sms);
        if (!m.find()) {
            throw new IllegalArgumentException("지원하지 않는 농협 SMS 포맷입니다.");
        }

        BigDecimal amount = new BigDecimal(m.group("amount").replace(",", ""));
        LocalDateTime dateTime = LocalDateTime.parse(m.group("date"), DATE_FMT);
        String account = m.group("account").trim();
        String name = m.group("name").trim();

        return new TransactionInfo(dateTime, amount, name, account);
    }
}