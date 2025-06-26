package org.example.parser;

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.Data;
import lombok.Getter;

import java.io.IOException;
import java.time.Instant;

@Data
public class Notification {
    private String key;
    private long postTime;
    private int platform;
    private int version;
    private String category;
    private String title;
    private String text;
    private String packageName;
    private long timestamp;
    private int notificationClass;
    private int importance;
    private String appName;

    public Instant getPostInstant() {
        return Instant.ofEpochMilli(postTime);
    }
    public Instant getTimestampInstant() {
        return Instant.ofEpochMilli(timestamp);
    }

    public static Notification parseNotification(String message) {
        ObjectMapper mapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        try {
            return mapper.readValue(message, Notification.class);
        } catch (JsonParseException e) {
            System.err.println("JSON 구문 오류: " + e.getMessage());
        } catch (JsonMappingException e) {
            System.err.println("매핑 오류: " + e.getMessage());
        } catch (IOException e) {
            System.err.println("I/O 오류: " + e.getMessage());
        }
        return null;
    }
}
