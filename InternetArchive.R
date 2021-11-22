library(rvest)
library(tidyverse)

get_pubdate <- function(book_link) {
  book_page <- read_html(book_link)
  pub_date <- book_page %>% 
    html_nodes(css = ".actions-ia+ .metadata-list .metadata-definition:nth-child(1) dd") %>%
    html_text() %>%
  return(pub_date)
}

get_topic <- function(book_link) {
  book_page <- read_html(book_link)
  topic <- book_page %>% 
    html_nodes(css = ".metadata-list .metadata-definition:nth-child(2) dd") %>%
    html_text() %>%
    return(topic)
}

get_lang <- function(book_link) {
  book_page <- read_html(book_link)
  book_lang <- book_page %>% 
    html_nodes(css = ".metadata-list .metadata-definition:nth-child(7) dd") %>%
    html_text() %>%
    return(book_lang)
}

get_publisher <- function(book_link) {
  book_page <- read_html(book_link)
  book_publisher <- book_page %>% 
    html_nodes(css = ".metadata-list .metadata-definition:nth-child(3) span") %>%
    html_text() %>%
    return(book_publisher)
}

books <- data.frame()

for (page_num in seq(from = 1, to = 5, by = 1)) {
  url <- paste0("https://archive.org/details/universityofglasgow?&sort=-week&page=", page_num)

  webpage <- read_html(url)

Title <- webpage %>%
  html_nodes(css = ".ttl") %>%
  html_text() %>%
  trimws()

Author <- webpage %>%
  html_nodes(css = ".byv") %>%
  html_text()

Views <- webpage %>%
  html_nodes(css = "nobr") %>%
  html_text()

Stars <- webpage %>%
  html_nodes(css = ".stat:nth-child(3)") %>%
  html_text() %>%
  trimws()

book_link <- webpage %>%
  html_nodes(css = 'a') %>%
  html_attr("href") %>%
  .[seq(from = 54, to = 202, by = 2)] %>%
  paste("https://www.archive.org", ., sep="")

 Publication_Date <- sapply(book_link, FUN = get_pubdate, USE.NAMES = FALSE) %>%
   trimws()
 Topics <- sapply(book_link, FUN = get_topic, USE.NAMES = FALSE) %>%
   trimws()
 Language <- sapply(book_link, FUN = get_lang, USE.NAMES = FALSE) %>%
   trimws()
 Publisher <- sapply(book_link, FUN = get_publisher, USE.NAMES = FALSE) %>%
   trimws()

books <- rbind(books, data.frame(Title, Author, 
                                 Publication_Date, Language, Publisher, Topics,
                                 Views, Stars, book_link, stringsAsFactors = FALSE))

print(paste("Page:", page_num)) 
}
View(books)
write.csv(books)