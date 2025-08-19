package com.monitoring.controller;

import com.monitoring.model.User;
import com.monitoring.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping("/users")
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @PostMapping("/users")
    public User createUser(@RequestBody User user) {
        return userService.createUser(user);
    }

    @GetMapping("/metrics")
    public Object getMetrics() {
        return userService.getMetrics();
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}