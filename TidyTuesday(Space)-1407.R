library(janitor)
library(tidyverse)
library(knitr)
library(data.table)

astronauts <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-07-14/astronauts.csv')

# Cleaning Data -----------------------------------------------------------------------

astronauts <- astronauts%>% 
  clean_names() %>% 
  filter(!is.na(number)) %>%  # remove last row (all values are NA)
  mutate(
    sex = if_else(sex == "male", "male", "female"),
    military_civilian = if_else(military_civilian == "military", "military", "civilian"))

astronauts %>% group_by(occupation) %>% summarise(c = n()) %>% arrange(desc(n))
astronauts_by_country = astronauts %>% 
  filter( occupation %in% c("commander", "flight engineer", "MSP", "pilot", "PSP")) %>% 
  group_by(nationality, occupation ) %>% 
  summarise(totalhrs = sum(total_hrs_sum)) %>% 
  data.frame() 

outliers = astronauts_by_country %>% group_by(nationality) %>% summarise(h = sum(totalhrs)) %>% arrange(h) %>% select(nationality) %>% head(10)

astronauts_by_country = astronauts_by_country %>% filter(!nationality %in% outliers$nationality)

data_plot = astronauts_by_country

# Adding Data Labels For Plot ---------------------------------------------


data_id = data_plot %>% select(nationality) %>% unique() %>% data.frame()
data_id = data_id %>% mutate(id = seq(1:nrow(data_id)))

data_plot = merge(data_plot, data_id, by.x = "nationality", by.y = "nationality")

# Assigning angles for circular plot --------------------------------------


labeldata = data_plot %>% 
  group_by(nationality, id) %>% 
  summarise(tot = sum(totalhrs)) %>% 
  data.frame()
no_of_bar <- nrow(labeldata)
angle <- 90 - 360 * (labeldata$id-0.5) /no_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
labeldata$hjust <- ifelse( angle < -90, 1, 0)
labeldata$angle <- ifelse(angle < -90, angle+180, angle)

# Plot --------------------------------------------------------------------

ggplot(data_plot)+
  geom_bar(aes(x=as.factor(id), y=log(totalhrs), fill=occupation), stat="identity", alpha=0.5)+
  scale_fill_manual(values = c("#dbdce1","#97bbc7","#fbc213","#2348a3","#fb9a99"))+
  theme_minimal()+
  coord_polar()+
  geom_text(data = labeldata,aes(x = as.factor(id), y = log(tot)+10, label = nationality, hjust = hjust),
            , color="gray", fontface="bold",alpha=0.6, size=2, 
            angle= labeldata$angle, inherit.aes = FALSE) +
  labs(title = "Time Spent In Space",
       caption = paste0("For: #TidyTuesday,
                        Source: Corlett, Stavnichuk, and Komarova 2020\n",
                        "Visualization: @ManasiM_10"))+ 
  theme(panel.background = element_rect(fill = "#202736", color = "#202736"),
      plot.background = element_rect(fill = "#202736", color = "#202736"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      #plot.margin = unit(rep(-1,4), "cm"),
      legend.text = element_text(colour="gray", size=8
                               ),
      legend.title = element_blank(),
      plot.title = element_text(color="#efcd00", size=15, face="bold.italic", hjust = 0.8))

  
