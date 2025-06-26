package org.example.parser;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class IBKSmsParser {
    private static final Pattern IBK_PATTERN = Pattern.compile(
              "(?<date>\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2})\\R" +
                    "입금\\s*(?<amount>[\\d,]+)원\\R" +
                    "잔액 [\\d,]+원\\R" +
                    "(?<name>.+)\\R" +
                    "(?<account>[\\d*]+)",
            Pattern.MULTILINE
    );

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm");

    public static TransactionInfo parse(String sms) {
        Matcher m = IBK_PATTERN.matcher(sms);
        if (!m.find()) {
            throw new IllegalArgumentException("지원하지 않는 IBK SMS 포맷입니다.");
        }

        LocalDateTime dateTime = LocalDateTime.parse(m.group("date"), DATE_FMT);
        BigDecimal amount = new BigDecimal(m.group("amount").replace(",", ""));
        String name = m.group("name");
        String account = m.group("account");

        return new TransactionInfo(dateTime, amount, name, account);
    }
}
