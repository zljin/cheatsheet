---
title: SpringSecurity
date: 2026-01-23 22:02:45
tags:
  - TechBase
categories: Frameworks
---

## SpringSecurity

> SpringSecurity 是身份验证和访问控制框架

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

please note:
由于jdk17,SpringBoot3升级，其SpringSecurity6的升级写法有较大的变化。
主要是SpringSecurity5 extends WebSecurityConfigurerAdapter已经废弃

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        String[] allowUri = {"/login","/error"};
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(allowUri).permitAll()//白名单
                .anyRequest().authenticated()//其他需要认证
            )
                //.addFilterBefore(devAuthFilter,UsernamePasswordAuthenticationFilter.class) //在UsernamePasswordAuthenticationFilter执行之前自定义filter
            //.formLogin() //开启表单验证后，则会开启 UsernamePasswordAuthenticationFilter的功能
            .exceptionHandling(c->c.accessDeniedHandler(accessDeniedHandler())
                    .authenticationEntryPoint(authenticationEntryPoint())
            )
                //.oauth2Login() //开启后，会启动oauth2验证,只会match oauth url pattern的时候才会触发
                .csrf(csrf -> csrf.disable()); // 开发时可禁用，生产建议启用

        return http.build();
    }
    private AuthenticationEntryPoint authenticationEntryPoint() {
        return (request, response, authException) -> {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "UNAUTHORIZED");
        };
    }

    private AccessDeniedHandler accessDeniedHandler() {
        return (request, response, accessDeniedException) -> {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied");
        };
    }
}
```

please note:

SpringSecurity 本质上是过滤器链,重点下面的过滤器

```
SecurityContextPersistenceFilter	安全上下文管理（有状态/无状态）	✅ 可配 Repository
UsernamePasswordAuthenticationFilter	表单登录	✅ 可继承自定义
BearerTokenAuthenticationFilter	JWT/API 认证	✅ 可配 Decoder
ExceptionTranslationFilter	异常处理入口	❌ 不可替换，但可配处理器
FilterSecurityInterceptor（被AuthorizationFilter替代）	权限校验终点	❌ 由配置驱动
```

重点关注 `AuthorizationFilter`来处理所有权限的检查，在SpringSecurity6+默认启用，并废弃了 `FilterSecurityInterceptor` 的配置方式

> AuthorizationFilter 源码

```java

public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain) throws ServletException, IOException {
    HttpServletRequest request = (HttpServletRequest)servletRequest;
    HttpServletResponse response = (HttpServletResponse)servletResponse;
    if (this.observeOncePerRequest && this.isApplied(request)) {
        chain.doFilter(request, response);
    } else if (this.skipDispatch(request)) {
        chain.doFilter(request, response);
    } else {
        String alreadyFilteredAttributeName = this.getAlreadyFilteredAttributeName();
        request.setAttribute(alreadyFilteredAttributeName, Boolean.TRUE);

        try {
            AuthorizationResult result = this.authorizationManager.authorize(this::getAuthentication, request);
            this.eventPublisher.publishAuthorizationEvent(this::getAuthentication, request, result);
            //鉴权
            if (result != null && !result.isGranted()) {
                throw new AuthorizationDeniedException("Access Denied", result);
            }

            chain.doFilter(request, response);
        } finally {
            request.removeAttribute(alreadyFilteredAttributeName);
        }

    }
}
//身份验证
private Authentication getAuthentication() {
    Authentication authentication = this.securityContextHolderStrategy.getContext().getAuthentication();
    if (authentication == null) {
        throw new AuthenticationCredentialsNotFoundException("An Authentication object was not found in the SecurityContext");
    } else {
        return authentication;
    }
}
```

> 所以自定义一个登陆接口时，在securityContextHolderStrategy.getContext().setAuthentication即可

```java

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class AuthenticatedUser implements OidcUser, Serializable {

    //override getName
    private String userId;

    //override getAuthorities
    private List<GrantedAuthority> authorities = new ArrayList<>();

    //override getClaims,getAttributes,
    private transient Map<String, Object> attributes = new HashMap<>();

    //略...

    public void login() {
        //Mock data
        String userId = "mike";
        List<GrantedAuthority> authorities = Arrays.asList("ADMIN_ROLE");
        
        AuthenticatedUser user = new AuthenticatedUser(userId,authorities);

        SecurityContext sc = SecurityContextHolder.getContext();
        PreAuthenticatedAuthenticationToken token = new PreAuthenticatedAuthenticationToken(user, "sso", user.getAuthorities());
        sc.setAuthentication(token);
    }
}



```

## OAuth2

> OAuth2 一种授权框架，目的是让一个客户端在用户授权的前提下，安全地访问该用户在另一个服务（资源服务器）上的受保护资源，而无需获取用户的用户名和密码

> OIDC:建立在OAuth2基础上的身份认证协议，主要是认证，OAuth2主要是授权，只关注授权吗流程即可

OIDC的好处就是直接使用已认证的用户信息，无需管理

OAuth2.0 授权码模式：
1、用户访问客户端网站（如知乎）
2、客户端重定向用户到授权服务器（如微信登录页）
3、用户登录并同意授权
4、授权服务器重定向回客户端，并附带一个临时的 code（授权码）
5、客户端用 code + 自己的 client_id/client_secret 向授权服务器换取 access_token
6、客户端用 access_token 访问资源服务器（如获取用户微信昵称）
7、资源服务器验证 token 后返回用户数据

课后作业：你可以基于SpringSecurity+OAuth2+OIDC授权码模式 集成Github的第三方登陆去实现



## Spring Session

Spring Session 的核心机制
它通过 SessionRepositoryFilter 包装了原生的 HttpSession，任何对 session.setAttribute(key, value) 的调用，
都会被代理到 SessionRepository（比如 JdbcIndexedSessionRepository）。 只要你调用了 setAttribute
无论 key 是什么（哪怕是 "SPRING_SECURITY_CONTEXT"），只要 session 是由 Spring Session 管理的，它就会：
序列化你的 value（这里是 SecurityContext 对象）
写入数据库表（如 SPRING_SESSION_ATTRIBUTES）

> 与Spring Session联动

1、配置
```xml
<!-- Spring Session JDBC -->
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-jdbc</artifactId>
</dependency>

        <!-- Spring Security -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

```yml
spring:
  session:
    store-type: jdbc
    jdbc:
      initialize-schema: always  # 自动建表（生产环境设为 never）Spring Boot 会自动创建 SPRING_SESSION 和 SPRING_SESSION_ATTRIBUTES 表
```

2、写入到数据库

```java
public R<String> login(HttpSession session){
    //直接set会写入到数据库中
    //securityContextRepository.saveContext()，Spring Security 已经为你自动处理了安全上下文的保存和恢复，不需要显示调用，下面只是加一行记录去数据库
    session.setAttribute("SPRING_SECURITY_CONTEXT",SecurityContextHolder.getContext());
}
```

3、登陆后再次触发其他API，Spring如何从数据库恢复 Session？

1️⃣ 入口：SessionRepositoryFilter（Spring Session 的核心）
当一个 HTTP 请求到达时，最先执行的 Filter 之一就是 SessionRepositoryFilter（在 Spring Security Filter 之前）。
它会：
从 Cookie 中读取 SESSION ID（默认 cookie 名为 SESSION）
调用 SessionRepository.findById(sessionId) → 从数据库（如 JDBC）加载完整 session 数据
包装成一个 SessionRepositoryRequestWrapper，替换原生 HttpServletRequest
后续所有 request.getSession() 调用都会返回这个 已从 DB 恢复的 session
✅ 所以：session 数据（包括属性）在进入 Spring Security 之前就已经从数据库加载好了！
2️⃣ Spring Security 读取安全上下文：SecurityContextPersistenceFilter
在 Spring Security Filter Chain 中，第二个执行的 Filter 通常是 SecurityContextPersistenceFilter（紧跟在 WebAsyncManagerIntegrationFilter 之后）。
它的作用是：

```java
SecurityContext context = securityContextRepository.loadContext(request);
SecurityContextHolder.setContext(context);
```

而默认的 securityContextRepository 是 HttpSessionSecurityContextRepository，它的 loadContext() 方法会：
```java
// 从 request.getSession() 中获取（此时 session 已由 Spring Session 从 DB 恢复！）
SecurityContext context = (SecurityContext) session.getAttribute(
        "org.springframework.security.web.context.HttpSessionSecurityContextRepository.SECURITY_CONTEXT"
);
```
✅ 所以：Spring Security 从 HttpSession 中读取安全上下文，而这个 session 已经由 Spring Session 从数据库还原。


## LDAP

> LDAP是轻量级目录访问协议，树形结构存储公司内部的组织架构数据，你可以理解未另外一种数据库，然后可以用LDAP进行login

Springboot 集成 LDAP 登陆



