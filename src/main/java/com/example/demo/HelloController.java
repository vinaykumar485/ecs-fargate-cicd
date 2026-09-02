package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Hello from ECS Fargate CI/CD!";
    }

    @GetMapping("/health")
    public String health() {
        return "Application is healthy";
    }
}
