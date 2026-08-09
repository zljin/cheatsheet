---
tags:
  - TechBase
categories: Frameworks
date: 2025-11-29 08:00:45
title: Liquibase
---


[Liquibase](https://www.liquibase.com/) 可以理解为数据库[[MySQL]]的[[Git]],可以对数据库变化进行跟踪，管理，迁移，回滚

会将每次changeset操作记录到表DATABASECHANGELOG中，可以通过tag进行回滚
通过DATABASECHANGELOGLOCK表保证并发安全

SprintBoot+Jpa+Liquibase+rollback API最佳实践：
https://github.com/zljin/flashbuy/pull/1/commits/4cfee68b5d9568fad58c5c02100d890870a1dea4

