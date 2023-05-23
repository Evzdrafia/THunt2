---
title: "lab3"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r}
library(arrow)
library(dplyr)
library(duckdb)
library(stringr)
ds <- 
  arrow::read_csv_arrow("traffic_security.csv",schema = schema(timestamp=int64(),src=utf8(),dst=utf8(),port=uint32(),bytes=uint32()))
```
# Задание 3: Надите утечку данных 3 Еще один нарушитель собирает содержимое электронной почты и отправляет в Интернет используя порт, который обычно используется для другого типа трафика. Атакующий пересылает большое количество информации используя этот порт, которое нехарактерно для других хостов, использующих этот номер порта. Определите IP этой системы. Известно, что ее IP адрес отличается от нарушителей из предыдущих задач.
```{r,warning=FALSE, message=FALSE, error=FALSE}
ds %>%
  select(src, dst, bytes,port) %>%
  mutate(outside_traffic = (str_detect(src,"^((12|13|14)\\.)") & !str_detect(dst,"^((12|13|14)\\.)"))) %>%
  filter(outside_traffic == TRUE) %>%
  group_by(port) %>%
  summarise(total_data=sum(bytes)) %>%
  filter(total_data < 5*10^9) %>%
  select(port) %>%
  collect() -> ports

ports <- unlist(ports)
ports <- as.vector(ports,'numeric')
```


### Выбираем данные с нужными номерами портов
```{r,warning=FALSE, message=FALSE, error=FALSE}
ds %>%
  select(src, dst, bytes,port) %>%
  mutate(outside_traffic = (str_detect(src,"^((12|13|14)\\.)") & !str_detect(dst,"^((12|13|14)\\.)"))) %>%
  filter(outside_traffic == TRUE) %>%
  filter(port %in% ports) %>%
  group_by(src,port) %>%
  summarise(total_bytes=sum(bytes)) %>%
  arrange(desc(port)) %>%
  collect() -> df

```


### Порты с маскимальным кол-вом данных
```{r,warning=FALSE, message=FALSE, error=FALSE}
df %>%
  group_by(src, port) %>%
  summarise(total_data=sum(total_bytes)) %>%
  arrange(desc(total_data)) %>%
  head(10) %>%
  collect()
```


### Количество хостов к портам
```{r,warning=FALSE, message=FALSE, error=FALSE}
df %>%
  group_by(port) %>%
  summarise(hosts=n()) %>%
  arrange(hosts) %>%
  head(10) %>%
  collect()
```


### Из предыдущих шагов следует вывод, что ip-адрес злоумышленника 12.55.77.96, а порт 31, т.к. из таблицы в 5 пункте видно, что 31 порт использовал только 1 хост и в тоже время из таблицы в 4 пункте видно, что больше всего данных было передано именно по этому порту 
```{r,warning=FALSE, message=FALSE, error=FALSE}
df %>%
  filter(port == 31) %>%
  group_by(src) %>%
  summarise(total_data=sum(total_bytes)) %>%
  collect()
```