---
title: "lab2"
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
ds <- 
  arrow::read_csv_arrow("traffic_security.csv",schema = schema(timestamp=int64(),src=utf8(),dst=utf8(),port=uint32(),bytes=uint32()))
```

# Задание 2: Надите утечку данных 2
# Другой атакующий установил автоматическую задачу в системном планировщике cron для экспорта содержимого внутренней wiki системы. Эта система генерирует большое количество траффика в нерабочие часы, больше чем остальные хосты. Определите IP этой системы. Известно, что ее IP адрес отличается от нарушителя из предыдущей задачи.


```{r}
library(ggplot2)
library(lubridate)
stataH<-ds %>%
  mutate(hour = hour(as_datetime(timestamp/1000, tz = "UTC"))) %>%
  group_by(hour) %>%
  summarise(total_bytes = sum(bytes))
  ggplot2::ggplot(stataH)+
  geom_density(aes(x=hour,y=total_bytes), stat = "identity")
```
# вывод:предположительные рабочие часы: 16-24
```{r}

stata<-ds %>%
  mutate(hour = hour(as_datetime(timestamp/1000, tz = "UTC"))) %>%
  group_by(src,hour) %>%
  summarise(total_bytes = sum(bytes))

```
# трафик каждого хоста по часам
```{r}
stata %>%
  filter(hour <16)%>%
    group_by(src) %>%
    summarise(tb_nowork = sum(total_bytes))%>%
    arrange(desc(tb_nowork)) %>%
    head(10) %>%
    collect()
```
# вывод:больше всего трафика в нерабочее время исходит от хоста - нарушителя из предыдущей задачи:(
```{r}
stata %>%
  filter(src=="12.55.77.96"|src=="12.59.25.34"|src=="13.42.70.40"|src=="12.45.94.34"|src=="13.39.46.94")%>%
    ggplot2::ggplot()+
    geom_density(aes(x=hour,y=total_bytes, colour=src), stat = "identity")
```
# вывод:трафик некоторых хостов распределен по времени почти более или менее равномерно, трафик других имеют явные экстремумы
```{r}
s1<-stata %>%
  filter(hour >=16)%>%
    group_by(src) %>%
    summarise(tb_work = sum(total_bytes))

s2<-stata %>%
  filter(hour <16)%>%
    group_by(src) %>%
    summarise(tb_nework = sum(total_bytes))
merge(s1,s2)%>%
  mutate(tb_difference=tb_work-tb_nework)%>%
  arrange((tb_difference)) %>%
  head(10) 
```
# Вывод: нет такого хоста, который отправил за нерабочие часы больше траффика, чем за рабочие, но есть подозрительные хосты типа 12.55.77.96 и 13.42.70.40, сгенерировавшие в один конкретный час рабочего времени больше траффика, чем в любой рабочий час
## Вывод выводов: в результате анализа удалось получить больше вопросов, чем ответов...
