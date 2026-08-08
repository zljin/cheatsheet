---
tags:
  - TechBase
title: ElasticSearch
date: 2022-02-23 10:23:45
categories: Middleware
---

# 概念

索引 (index) : 相同类型文档的集合，类比与一张表

映射（mapping）: 类比与一张表结构

文档（document）: 表中的一行数据，类比与表的一行

字段（field）：表的列属性

词条（term）: 通过分词后的词组

es的倒排索引的查询步骤：

小米手机---> ik分词器---> 两个词条： 小米　and 手机 ----> 根据这两个词条查询文档id ---> 返回文档id的结果集

# 快速安装

    docker network create es-net # 网络创建，用来划分网络，kibana和es在同一个网断内


    # 安装es
    docker run -d \
    	--name elasticsearch \
        -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
        -e "discovery.type=single-node" \
        -v es-data:/usr/share/elasticsearch/data \
        -v es-plugins:/usr/share/elasticsearch/plugins \
        --privileged \
        --network es-net \
        -p 9200:9200 \
        -p 9300:9300 \
    elasticsearch:7.12.1

    es address: http://127.0.0.1:9200/

    # 安装kibana

    docker run -d \
    --name kibana \
    -e ELASTICSEARCH_HOSTS=http://192.168.26.1:9200 \
    --network es-net \
    -p 5601:5601  \
    kibana:7.12.1

    kibana address: http://192.168.26.1:5601

    # 安装ik中文分词器

    https://github.com/infinilabs/analysis-ik/releases?expanded=true&page=4&q=v7.12.1

    mv elasticsearch-analysis-ik-7.12.1 ik

    docker cp ik elasticsearch:/usr/share/elasticsearch/plugins

    docker restart elasticsearch

    # 分词器测试
    http://192.168.26.1:5601/app/dev_tools#/console

    GET _analyze
    {
      "analyzer": "ik_max_word",
      "text": "科比门徒，带你打开通往梦想的门"
    }

# 文档和索引操作

> kibana devtool: <http://192.168.26.1:5601/app/dev_tools#/console>

> DSL 是es提供得json风格得请求语句，用来操作es,实现CRUD,类比于sql语句

```json
# 索引操作
## 创建索引
PUT /my_index
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  },
  "mappings": {
    "properties": {
      "user": {
        "type": "text"
      },
      "post_date": {
        "type": "date"
      },
      "message": {
        "type": "text",
        "analyzer": "standard"
      },
      "age": {
        "type": "integer"
      },
      "location": {
        "type": "geo_point"
      }
    }
  }
}

## 查看索引
GET /my_index

## 删除索引
DELETE /my_index

## 修改索引 (mapping一旦创建无法修改，只可以添加新得字段)
PUT /my_index/_mapping
{
    "properties": {
      "newField": {
        "type": "text"
      }
    }
}

# 文档操作
## 添加文档
POST /my_index/_doc/1
{"user":"kimchy","post_date":"2023-06-01T12:00:00","message":"Trying out Elasticsearch","age":30,"location":"41.12,-71.34"}

## 查询文档
GET /my_index/_doc/1

## 删除文档
DELETE /my_index/_doc/1

## 全量修改文档
PUT /my_index/_doc/1
{"user":"kimchyyyyyyyyyyyyyyy","post_date":"2023-06-01T12:00:00","message":"Trying out Elasticsearch","age":30,"location":"41.12,-71.34"}

## 增量修改文档
POST /my_index/_update/1
{
	"doc": {
		"user": "kimchy"
	}
}

```

# 查询语句练习

> 数据集：<https://github.com/elastic/elasticsearch/blob/v6.8.18/docs/src/test/resources/accounts.json>

## 数据集准备

```json
# 创建bank索引

> "type": "keyword" 类型用于索引结构化字段，例如电子邮件地址、主机名、状态码、标签或类别等，这些字段的值通常不会被拆分为多个词

PUT /bank
{
  "mappings": {
    "properties": {
      "account_number": {
        "type": "integer"
      },
      "balance": {
        "type": "integer"
      },
      "firstname": {
        "type": "text"
      },
      "lastname": {
        "type": "text"
      },
      "age": {
        "type": "integer"
      },
      "gender": {
        "type": "keyword"
      },
      "address": {
        "type": "text"
      },
      "employer": {
        "type": "text"
      },
      "email": {
        "type": "keyword"
      },
      "city": {
        "type": "text"
      },
      "state": {
        "type": "keyword"
      }
    }
  }
}


# 批量导入数据集合，sample如下

POST /bank/_bulk
{"index":{"_id":"1"}}
{"account_number":1,"balance":39225,"firstname":"Amber","lastname":"Duke","age":32,"gender":"M","address":"880 Holmes Lane","employer":"Pyrami","email":"amberduke@pyrami.com","city":"Brogan","state":"IL"}
{"index":{"_id":"6"}}
{"account_number":6,"balance":5686,"firstname":"Hattie","lastname":"Bond","age":36,"gender":"M","address":"671 Bristol Street","employer":"Netagy","email":"hattiebond@netagy.com","city":"Dante","state":"TN"}
```

## 查询数据

```json
# 全局分页查询，并排序
GET /bank/_search
{
  "query": { "match_all": {} },
  "sort": [
    { "account_number": "asc" }
  ],
  "from": 10,
  "size": 10
}

# 查询address 字段中包含 mill 或者 lane的数据
GET /bank/_search
{
  "query": { "match": { "address": "mill lane" } }
}

# 查询段落匹配：match_phrase
GET /bank/_search
{
  "query": { "match_phrase": { "address": "mill lane" } }
}

# 多条件查询 bool query
GET /bank/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "age": "40" } }
      ],
      "must_not": [
        { "match": { "state": "ID" } }
      ]
    }
  }
}

# query and filter 区别

> query 子句(must,should,must_not)上下文给文档打分的，匹配越好 _score 越高
> filter 的条件只产生两种结果：符合与不符合，后者被过滤掉


GET /bank/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "state": "ND"
          }
        }
      ],
      "filter": [
        {
          "term": {
            "age": "40"
          }
        },
        {
          "range": {
            "balance": {
              "gte": 20000,
              "lte": 30000
            }
          }
        }
      ]
    }
  }
}


GET /bank/_search
{
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "age": "40"
          }
        },
        {
          "range": {
            "balance": {
              "gte": 20000,
              "lte": 30000
            }
          }
        }
      ]
    }
  }
}

# 地理查询 (geo_bounding_box,geo_distance)
## 某矩阵范围内的数据
GET /my_index/_search
{
  "query": {
    "geo_bounding_box": {
      "location": {
        "top_left": {
          "lat": 42,
          "lon": -72
        },
        "bottom_right": {
          "lat": 39,
          "lon": -71
        }
      }
    }
  }
}

## 指定中心到某个距离的圆规范围
GET /my_index/_search
{
  "query": {
    "geo_distance": {
      "distance": "15km",
      "FIELD": "31.21,121.5"
    }
  }
}

```

# 聚合查询

> 类似于group by

```json

> size: 0：指示 Elasticsearch 不返回匹配的文档，仅返回聚合结果。
> aggs（聚合）：指定了一个按 state.keyword 字段分组的聚合，称为 group_by_state。

GET /bank/_search
{
  "size": 0,
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "state.keyword",
        "order": {
          "average_balance": "desc"
        }
      },
      "aggs": {
        "average_balance": {
          "avg": {
            "field": "balance"
          }
        }
      }
    }
  }
}
```

# SpringBoot集成

<https://github.com/zljin/Spring-Boot-In-Action/tree/master/springboot_es>

<https://github.com/zljin/Spring-Boot-In-Action/tree/master/elasticsearch-client-spring-boot-starter>

# reference

<https://pdai.tech/md/db/nosql-es/elasticsearch.html>

<https://blog.csdn.net/qq_57216731/article/details/129915963>

<https://juejin.cn/post/7202441529151094842>

<https://juejin.cn/post/7074115690340286472>
