package com.monitoring.service;

import com.monitoring.model.User;
import com.monitoring.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Cacheable("users")
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User createUser(User user) {
        User savedUser = userRepository.save(user);
        redisTemplate.delete("users");
        return savedUser;
    }

    public Map<String, Object> getMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("activeUsers", userRepository.count());
        metrics.put("responseTime", new Random().nextInt(100) + 50);
        metrics.put("cacheHitRate", new Random().nextInt(40) + 60);
        return metrics;
    }
}