---
title: "attempt1"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## R Markdown
• Описание полей датасета: timestamp,src,dst,port,bytes
• IP адреса внутренней сети начинаются с 12-14
• Все остальные IP адреса относятся к внешним узлам


```{r}
library(arrow)
library(dplyr)
library(duckdb)
library(stringr)
```


```{r}
ds <- 
  arrow::read_csv_arrow("traffic_security.csv",schema = schema(timestamp=int64(),src=utf8(),dst=utf8(),port=uint32(),bytes=uint32()))  

#dsh<-head(ds,100000)
```

#Задание 1: Надите утечку данных из Вашей сети
#Важнейшие документы с результатми нашей исследовательской деятельности в области создания вакцин скачиваются в виде больших заархивированных дампов. Один из хостов в нашей сети используется для пересылки этой информации – он пересылает гораздо больше информации на внешние ресурсы в Интернете, чем остальные компьютеры нашей сети. Определите его IP-адрес.

```{r}
filter(ds,str_detect(src,"^((12|13|14)\\.)"),
         str_detect(dst,"^((12|13|14)\\.)",negate=TRUE)) %>% 
  select(src,bytes) %>%
  group_by(src)%>% 
  summarise(total_bytes = sum(bytes)) %>%
  filter(total_bytes==max(total_bytes))
```

